import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/app_user.dart';
import '../models/weather_models.dart';
import 'crypto_service.dart';
import '../models/kerala_map_models.dart';

class ApiException implements Exception {
  final String message;
  final bool isTimeout;
  ApiException(this.message, {this.isTimeout = false});

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
class ApiService {
  ApiService._internal();
  static final ApiService instance = ApiService._internal();

  static const String baseUrl = 'https://kdmabw.onrender.com';
  static const Duration _timeout = Duration(seconds: 50);

  final http.Client _client = http.Client();

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

    final res = await _send(() => _client.post(
          Uri.parse('$baseUrl/register'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'data': encrypted}),
        ));

    if (res.statusCode == 200 || res.statusCode == 201) {
      final decrypted = await _decryptResponse(res);
      return AppUser.fromJson(decrypted);
    }
    throw ApiException(_extractError(res));
  }

  Future<String> login({required String email, required String password}) async {
    final res = await _send(() => _client.post(
          Uri.parse('$baseUrl/login'),
          headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'email': email.trim(), 'password': password},
        ));

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
    final res = await _send(() => _client.get(
          Uri.parse('$baseUrl/me'),
          headers: {'Authorization': 'Bearer $token'},
        ));

    if (res.statusCode == 200) {
      final decrypted = await _decryptResponse(res);
      return AppUser.fromJson(decrypted);
    }
    throw ApiException(_extractError(res));
  }
  
  Future<KeralaMapResponse> fetchKeralaMap() async {
    final res = await _send(() => _client.get(Uri.parse('$baseUrl/weather/kerala-map')));

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
    final res = await _send(() => _client.get(uri));

    if (res.statusCode == 200) {
      final decrypted = await _decryptResponse(res);
      return WeatherResponse.fromJson(decrypted);
    }
    throw ApiException(_extractError(res));
  }

  Future<Map<String, dynamic>> _decryptResponse(http.Response res) async {
    final wrapper = jsonDecode(res.body) as Map<String, dynamic>;
    final token = wrapper['data'] as String?;
    if (token == null) {
      throw ApiException('Unexpected response format from server.');
    }
    return CryptoService.instance.decryptPayload(token);
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
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
    // Error responses (4xx/5xx) are left unencrypted by the backend middleware
    // on purpose, so they can be parsed directly here.
    try {
      final body = jsonDecode(res.body);
      if (body is Map) {
        final detail = body['detail'];
        if (detail is String) return detail;
        if (detail != null) return detail.toString();
        final error = body['error'];
        if (error is String) return error;
      }
    } catch (_) {
      // fall through
    }
    if (res.statusCode == 401) return 'Incorrect email or password.';
    if (res.statusCode == 400) return 'That request could not be completed.';
    if (res.statusCode >= 500) return 'The server hit an error. Please try again shortly.';
    return 'Request failed (${res.statusCode}).';
  }
}
