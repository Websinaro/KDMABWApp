import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../services/connectivity_service.dart';
import '../services/local_cache.dart';

enum AuthStatus { unknown, authenticating, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus status = AuthStatus.unknown;
  AppUser? currentUser;
  String? errorMessage;
  bool isOfflineSession = false;

  final ApiService _api = ApiService.instance;

  /// Called at startup AND whenever the app needs to re-validate the
  /// session. Never trusts the cache unless the device is genuinely
  /// offline - a rejected/expired token while online always forces a
  /// fresh login instead of silently reusing a stale cached profile.
  Future<void> restoreSession() async {
    final token = await AuthStorage.instance.readToken();
    if (token == null || token.isEmpty) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    final online = await ConnectivityService.instance.hasConnection();

    if (!online) {
      // Truly offline - never contact the server, just use whatever we
      // last cached for this account.
      final cachedUser = await LocalCache.instance.readUser();
      if (cachedUser != null) {
        currentUser = cachedUser;
        isOfflineSession = true;
        status = AuthStatus.authenticated;
      } else {
        status = AuthStatus.unauthenticated;
      }
      notifyListeners();
      return;
    }

    // Online: always re-validate against the server.
    try {
      final user = await _api.fetchMe(token);
      currentUser = user;
      isOfflineSession = false;
      await LocalCache.instance.saveUser(user);
      status = AuthStatus.authenticated;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        // Token is genuinely invalid/expired - force a real login, do not
        // fall back to the cached profile.
        await AuthStorage.instance.clearToken();
        await LocalCache.instance.clearUser();
        currentUser = null;
        status = AuthStatus.unauthenticated;
      } else {
        // We're online per the OS, but this specific call still failed
        // (e.g. server waking up) - fall back to cache rather than
        // blocking a real user over a transient hiccup.
        final cachedUser = await LocalCache.instance.readUser();
        if (cachedUser != null) {
          currentUser = cachedUser;
          isOfflineSession = true;
          status = AuthStatus.authenticated;
        } else {
          status = AuthStatus.unauthenticated;
        }
      }
    } catch (_) {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String district,
    String? accessCode,
  }) async {
    errorMessage = null;
    status = AuthStatus.authenticating;
    notifyListeners();
    try {
      final user = await _api.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        district: district,
        accessCode: accessCode,
      );
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return user;
    } on ApiException catch (e) {
      errorMessage = e.message;
      status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
    errorMessage = null;
    status = AuthStatus.authenticating;
    notifyListeners();
    try {
      final token = await _api.login(email: email, password: password);
      await AuthStorage.instance.saveToken(token);

      try {
        final user = await _api.fetchMe(token);
        currentUser = user;
        isOfflineSession = false;
        await LocalCache.instance.saveUser(user);
      } on ApiException {
        currentUser = await LocalCache.instance.readUser();
        isOfflineSession = true;
      }

      status = AuthStatus.authenticated;
      notifyListeners();
    } on ApiException catch (e) {
      errorMessage = e.message;
      status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  /// Called whenever any authenticated API call comes back 401 mid-session
  /// (e.g. token expired while the app was open) - forces the user back
  /// to the login screen instead of leaving them stuck on broken data.
  Future<void> forceLogout({String? reason}) async {
    await AuthStorage.instance.clearToken();
    await LocalCache.instance.clearUser();
    currentUser = null;
    errorMessage = reason;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthStorage.instance.clearToken();
    await LocalCache.instance.clearUser();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
