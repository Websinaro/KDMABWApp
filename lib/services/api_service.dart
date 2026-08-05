import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;

import '../models/app_user.dart';
import '../models/weather_models.dart';
import 'crypto_service.dart';
import 'auth_storage.dart';
import '../models/safety_contact.dart';
import '../models/kerala_map_models.dart';
import '../models/sos_models.dart';

class ApiException implements Exception {
  final String message;
  final bool isTimeout;
  final bool isUpdateRequired;
  final bool isUnauthorized;
  ApiException(
    this.message, {
    this.isTimeout = false,
    this.isUpdateRequired = false,
    this.isUnauthorized = false,
  });

  @override
  String toString() => message;
}

/// Thin wrapper around the WeBAlert FastAPI backend.
///
/// Base URL points at the Render deployment. Render's free tier spins the
/// service down when idle, so the first request after a while can take
/// 20-50s to "wake up" - timeouts are generous on purpose and callers should
/// show a friendly "waking up the server" message instead of failing fast.
///
/// All JSON responses from the backend are wrapped as {"data": "<encrypted>"}
/// by the server's EncryptionMiddleware, so every JSON-returning call here
/// decrypts via CryptoService before parsing. /login uses form-urlencoded
/// on the way in (OAuth2 spec requirement) but its JSON response is still
/// encrypted, so it gets decrypted too.
///
/// Every request also sends X-App-Version so the backend's
/// VersionCheckMiddleware can reject unsupported old builds with a 426,
/// which _send() turns into an ApiException(isUpdateRequired: true).
class ApiService {
  ApiService._internal();
  static final ApiService instance = ApiService._internal();

  static const String baseUrl = 'https://kdmabw.onrender.com';
  static const Duration _timeout = Duration(seconds: 50);

  String? _cachedVersion;
  final http.Client _client = http.Client();

  /// Set once from app.dart at startup. Called whenever any authenticated
  /// request comes back 401 mid-session, so AuthProvider can force a real
  /// logout (clear token, clear cache, route to Welcome) instead of the
  /// error just surfacing silently on whichever screen happened to be open.
  void Function()? onUnauthorized;

  Future<Map<String, String>> _headers([Map<String, String>? extra]) async {
    _cachedVersion ??= (await PackageInfo.fromPlatform()).version;
    return {
      'X-App-Version': _cachedVersion!,
      ...?extra,
    };
  }

  /// Unencrypted, exempt from the version gate on the backend - safe to call
  /// before knowing whether this build is even allowed to talk to the API.
  Future<Map<String, dynamic>> checkVersion() async {
    final res = await _send(
      () => _client.get(Uri.parse('$baseUrl/app/version')),
      isAuthenticatedRequest: false,
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw ApiException(_extractError(res));
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String district,
    String? accessCode,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
      'district': district,
    };
    if (accessCode != null && accessCode.trim().isNotEmpty) {
      body['access_code'] = accessCode.trim();
    }

    final encrypted = await CryptoService.instance.encryptPayload(body);

    final res = await _send(
      () async => _client.post(
        Uri.parse('$baseUrl/register'),
        headers: await _headers({'Content-Type': 'application/json'}),
        body: jsonEncode({'data': encrypted}),
      ),
      isAuthenticatedRequest: false,
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final decrypted = await _decryptResponse(res);
      return AppUser.fromJson(decrypted);
    }
    throw ApiException(_extractError(res));
  }

  Future<String> login({required String email, required String password}) async {
    final res = await _send(
      () async => _client.post(
        Uri.parse('$baseUrl/login'),
        headers: await _headers({'Content-Type': 'application/x-www-form-urlencoded'}),
        body: {'email': email.trim(), 'password': password},
      ),
      isAuthenticatedRequest: false,
    );

    if (res.statusCode == 200) {
      final decrypted = await _decryptResponse(res);
      final token = decrypted['access_token']?.toString();
      if (token == null || token.isEmpty) {
        throw ApiException('Login succeeded but no session token was returned.');
      }
      return token;
    }
    throw ApiException(_extractError(res));
  }

  Future<AppUser> fetchMe(String token) async {
    final res = await _send(() async => _client.get(
          Uri.parse('$baseUrl/me'),
          headers: await _headers({'Authorization': 'Bearer $token'}),
        ));

    if (res.statusCode == 200) {
      final decrypted = await _decryptResponse(res);
      return AppUser.fromJson(decrypted);
    }
    throw ApiException(_extractError(res));
  }

  Future<KeralaMapResponse> fetchKeralaMap() async {
    final res = await _send(() async => _client.get(
          Uri.parse('$baseUrl/weather/kerala-map'),
          headers: await _headers(),
        ));

    if (res.statusCode == 200) {
      final decrypted = await _decryptResponse(res);
      return KeralaMapResponse.fromJson(decrypted);
    }
    throw ApiException(_extractError(res));
  }

  Future<WeatherResponse> fetchWeather({
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.parse('$baseUrl/weather').replace(queryParameters: {
      'lat': lat.toString(),
      'lon': lon.toString(),
    });
    final res = await _send(() async => _client.get(uri, headers: await _headers()));

    if (res.statusCode == 200) {
      final decrypted = await _decryptResponse(res);
      return WeatherResponse.fromJson(decrypted);
    }
    throw ApiException(_extractError(res));
  }
  
  Future<List<SafetyContact>> fetchSafetyContacts() async {
    final res = await _send(() async => _client.get(
          Uri.parse('$baseUrl/safety-contacts'),
          headers: await _headers({'Authorization': 'Bearer ${await _requireToken()}'}),
        ));

    if (res.statusCode == 200) {
      final wrapper = jsonDecode(res.body) as Map<String, dynamic>;
      final token = wrapper['data'] as String?;
      if (token == null) throw ApiException('Unexpected response format from server.');
      final decryptedList = await CryptoService.instance.decryptPayloadList(token);
      return decryptedList.map((e) => SafetyContact.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw ApiException(_extractError(res));
  }

  Future<SafetyContact> addSafetyContact({
    required String name,
    String? relationship,
    required String phone,
    String? email,
    String? address,
  }) async {
    final body = {
      'name': name.trim(),
      'relationship': relationship?.trim(),
      'phone': phone.trim(),
      'email': email?.trim(),
      'address': address?.trim(),
    };
    final encrypted = await CryptoService.instance.encryptPayload(body);

    final res = await _send(() async => _client.post(
          Uri.parse('$baseUrl/safety-contacts'),
          headers: await _headers({
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${await _requireToken()}',
          }),
          body: jsonEncode({'data': encrypted}),
        ));

    if (res.statusCode == 200 || res.statusCode == 201) {
      final decrypted = await _decryptResponse(res);
      return SafetyContact.fromJson(decrypted);
    }
    throw ApiException(_extractError(res));
  }

  Future<SafetyContact> updateSafetyContact({
    required int id,
    required String name,
    String? relationship,
    required String phone,
    String? email,
    String? address,
  }) async {
    final body = {
      'name': name.trim(),
      'relationship': relationship?.trim(),
      'phone': phone.trim(),
      'email': email?.trim(),
      'address': address?.trim(),
    };
    final encrypted = await CryptoService.instance.encryptPayload(body);

    final res = await _send(() async => _client.put(
          Uri.parse('$baseUrl/safety-contacts/$id'),
          headers: await _headers({
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${await _requireToken()}',
          }),
          body: jsonEncode({'data': encrypted}),
        ));

    if (res.statusCode == 200) {
      final decrypted = await _decryptResponse(res);
      return SafetyContact.fromJson(decrypted);
    }
    throw ApiException(_extractError(res));
  }

  Future<void> deleteSafetyContact(int id) async {
    final res = await _send(() async => _client.delete(
          Uri.parse('$baseUrl/safety-contacts/$id'),
          headers: await _headers({'Authorization': 'Bearer ${await _requireToken()}'}),
        ));

    if (res.statusCode == 200) return;
    throw ApiException(_extractError(res));
  }

  Future<String> _requireToken() async {
    final token = await AuthStorage.instance.readToken();
    if (token == null || token.isEmpty) {
      throw ApiException('You need to be logged in for this.', isUnauthorized: true);
    }
    return token;
  }

  Future<Map<String, dynamic>> _decryptResponse(http.Response res) async {
    final wrapper = jsonDecode(res.body) as Map<String, dynamic>;
    final token = wrapper['data'] as String?;
    if (token == null) {
      throw ApiException('Unexpected response format from server.');
    }
    return CryptoService.instance.decryptPayload(token);
  }
  
  Future<SosAlert> createSos({
    required double lat,
    required double lon,
    String? message,
  }) async {
    final body = {'latitude': lat, 'longitude': lon, 'message': message};
    final encrypted = await CryptoService.instance.encryptPayload(body);

    final res = await _send(() async => _client.post(
          Uri.parse('$baseUrl/sos'),
          headers: await _headers({
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${await _requireToken()}',
          }),
          body: jsonEncode({'data': encrypted}),
        ));

    if (res.statusCode == 200 || res.statusCode == 201) {
      final decrypted = await _decryptResponse(res);
      return SosAlert.fromJson(decrypted);
    }
    throw ApiException(_extractError(res));
  }
  
  Future<void> registerDeviceToken({required String token, required String platform}) async {
    final body = {'fcm_token': token, 'platform': platform};
    final encrypted = await CryptoService.instance.encryptPayload(body);

    final res = await _send(() async => _client.post(
          Uri.parse('$baseUrl/device-token'),
          headers: await _headers({
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${await _requireToken()}',
          }),
          body: jsonEncode({'data': encrypted}),
        ));

    if (res.statusCode != 200) throw ApiException(_extractError(res));
  }

  Future<SosAlert> updateSosLocation({
    required int sosId,
    required double lat,
    required double lon,
  }) async {
    final body = {'latitude': lat, 'longitude': lon};
    final encrypted = await CryptoService.instance.encryptPayload(body);

    final res = await _send(() async => _client.patch(
          Uri.parse('$baseUrl/sos/$sosId/location'),
          headers: await _headers({
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${await _requireToken()}',
          }),
          body: jsonEncode({'data': encrypted}),
        ));

    if (res.statusCode == 200) {
      final decrypted = await _decryptResponse(res);
      return SosAlert.fromJson(decrypted);
    }
    throw ApiException(_extractError(res));
  }

  Future<SosAlert> resolveSos(int sosId) async {
    final res = await _send(() async => _client.post(
          Uri.parse('$baseUrl/sos/$sosId/resolve'),
          headers: await _headers({'Authorization': 'Bearer ${await _requireToken()}'}),
        ));

    if (res.statusCode == 200) {
      final decrypted = await _decryptResponse(res);
      return SosAlert.fromJson(decrypted);
    }
    throw ApiException(_extractError(res));
  }

  Future<SosAlert?> fetchMyActiveSos() async {
    final res = await _send(() async => _client.get(
          Uri.parse('$baseUrl/sos/mine/active'),
          headers: await _headers({'Authorization': 'Bearer ${await _requireToken()}'}),
        ));

    if (res.statusCode == 200) {
      final decrypted = await _decryptResponse(res);
      if (decrypted.isEmpty) return null;
      return SosAlert.fromJson(decrypted);
    }
    throw ApiException(_extractError(res));
  }

  Future<SosAlert> fetchSos(int sosId) async {
    final res = await _send(() async => _client.get(
          Uri.parse('$baseUrl/sos/$sosId'),
          headers: await _headers({'Authorization': 'Bearer ${await _requireToken()}'}),
        ));

    if (res.statusCode == 200) {
      final decrypted = await _decryptResponse(res);
      return SosAlert.fromJson(decrypted);
    }
    throw ApiException(_extractError(res));
  }

Future<http.Response> _send(
  Future<http.Response> Function() call, {
  bool isAuthenticatedRequest = true,
  }) async {
    try {
      final res = await call().timeout(_timeout);

      if (res.statusCode == 426) {
        String message = 'Please update the app to continue.';
        try {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          message = body['message']?.toString() ?? message;
        } catch (_) {}
        throw ApiException(message, isUpdateRequired: true);
      }

      if (isAuthenticatedRequest && res.statusCode == 401) {
        // Notify the app layer immediately so AuthProvider can force a real
        // logout - throwing alone only tells the calling widget, it doesn't
        // clear the stored token or route back to login on its own.
        onUnauthorized?.call();
        throw ApiException('Your session has expired. Please log in again.', isUnauthorized: true);
      }

      return res;
    } on TimeoutException {
      throw ApiException(
        'The WeBAlert server is taking a while to respond (it may be waking up). '
        'Please try again in a few seconds.',
        isTimeout: true,
      );
    } on SocketException {
      throw ApiException('No internet connection. Check your network and try again.');
    } on HandshakeException {
      throw ApiException('Secure connection to the server failed. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Something went wrong. Please try again.');
    }
  }

  String _extractError(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map) {
        final detail = body['detail'];
        if (detail is String) return detail;
        if (detail is bool) return 'That request could not be completed.';
        if (detail != null) return detail.toString();
        final error = body['error'];
        if (error is String) return error;
      }
    } catch (_) {}
    if (res.statusCode == 401) return 'Incorrect email or password.';
    if (res.statusCode == 400) return 'That request could not be completed.';
    if (res.statusCode >= 500) return 'The server hit an error. Please try again shortly.';
    return 'Request failed (${res.statusCode}).';
  }
}
