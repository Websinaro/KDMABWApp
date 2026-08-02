import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the JWT access token in the Android Keystore-backed secure
/// storage, so it is not readable in plain text like a normal preference.
class AuthStorage {
  AuthStorage._internal();
  static final AuthStorage instance = AuthStorage._internal();

  static const _tokenKey = 'webalert_access_token';

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveToken(String token) => _secure.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _secure.read(key: _tokenKey);

  Future<void> clearToken() => _secure.delete(key: _tokenKey);
}
