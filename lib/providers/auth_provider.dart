import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../services/local_cache.dart';

enum AuthStatus { unknown, authenticating, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus status = AuthStatus.unknown;
  AppUser? currentUser;
  String? errorMessage;
  bool isOfflineSession = false;

  final ApiService _api = ApiService.instance;

  /// Called once at app startup: checks for a stored token and tries to
  /// validate it against the backend. Falls back to the last cached
  /// profile if the device is offline, so a returning user with no
  /// signal isn't logged out unnecessarily.
  Future<void> restoreSession() async {
    final token = await AuthStorage.instance.readToken();
    if (token == null || token.isEmpty) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final user = await _api.fetchMe(token);
      currentUser = user;
      isOfflineSession = false;
      await LocalCache.instance.saveUser(user);
      status = AuthStatus.authenticated;
    } on ApiException catch (e) {
      // Network / timeout issues -> try to continue offline with cached
      // profile instead of forcing a logout.
      final cachedUser = await LocalCache.instance.readUser();
      if (cachedUser != null && !e.message.toLowerCase().contains('incorrect')) {
        currentUser = cachedUser;
        isOfflineSession = true;
        status = AuthStatus.authenticated;
      } else {
        await AuthStorage.instance.clearToken();
        status = AuthStatus.unauthenticated;
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
      status = AuthStatus.unauthenticated; // still needs to log in
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
        // Logged in but couldn't fetch profile right now - keep going with
        // whatever we have cached rather than blocking the user out.
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

  Future<void> logout() async {
    await AuthStorage.instance.clearToken();
    await LocalCache.instance.clearUser();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
