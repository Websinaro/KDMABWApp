import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/weather_models.dart';

/// Wraps SharedPreferences for everything WeBAlert keeps on-device:
/// the signed-in user's profile, the last-known weather for quick offline
/// viewing, remembered login email, and onboarding/permission flags.
///
/// This is the "device storage" half of the backup requirement - it always
/// happens automatically in the background. [BackupService] handles the
/// separate, user-triggered export to a folder outside the app's sandbox.
class LocalCache {
  LocalCache._internal();
  static final LocalCache instance = LocalCache._internal();

  static const _kUser = 'cache_user_profile';
  static const _kWeatherPrefix = 'cache_weather_';
  static const _kRememberedEmail = 'cache_remembered_email';
  static const _kOnboardingDone = 'cache_onboarding_done';
  static const _kLastLocationKey = 'cache_last_location_key';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  // --- User profile -------------------------------------------------------

  Future<void> saveUser(AppUser user) async {
    final prefs = await _prefs;
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
  }

  Future<AppUser?> readUser() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_kUser);
    if (raw == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUser() async {
    final prefs = await _prefs;
    await prefs.remove(_kUser);
  }

  // --- Weather cache -------------------------------------------------------
  // Keyed so a citizen's GPS weather and a president's per-district lookups
  // don't overwrite each other.

  String _weatherKey(String cacheKey) => '$_kWeatherPrefix$cacheKey';

  Future<void> saveWeather(String cacheKey, WeatherResponse weather) async {
    final prefs = await _prefs;
    await prefs.setString(_weatherKey(cacheKey), jsonEncode(weather.toJson()));
  }

  Future<WeatherResponse?> readWeather(String cacheKey) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_weatherKey(cacheKey));
    if (raw == null) return null;
    try {
      return WeatherResponse.fromCacheJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Returns all cached district weather entries keyed by district key,
  /// used to draw the President's overview grid instantly before the
  /// network refresh completes.
  Future<Map<String, WeatherResponse>> readAllDistrictWeather(List<String> districtKeys) async {
    final result = <String, WeatherResponse>{};
    for (final key in districtKeys) {
      final w = await readWeather(key);
      if (w != null) result[key] = w;
    }
    return result;
  }

  // --- Misc preferences ------------------------------------------------

  Future<void> setRememberedEmail(String? email) async {
    final prefs = await _prefs;
    if (email == null || email.isEmpty) {
      await prefs.remove(_kRememberedEmail);
    } else {
      await prefs.setString(_kRememberedEmail, email);
    }
  }

  Future<String?> getRememberedEmail() async {
    final prefs = await _prefs;
    return prefs.getString(_kRememberedEmail);
  }

  Future<void> setOnboardingDone() async {
    final prefs = await _prefs;
    await prefs.setBool(_kOnboardingDone, true);
  }

  Future<bool> isOnboardingDone() async {
    final prefs = await _prefs;
    return prefs.getBool(_kOnboardingDone) ?? false;
  }

  Future<void> setLastLocationKey(String key) async {
    final prefs = await _prefs;
    await prefs.setString(_kLastLocationKey, key);
  }

  Future<String?> getLastLocationKey() async {
    final prefs = await _prefs;
    return prefs.getString(_kLastLocationKey);
  }

  /// Dumps everything cached locally into a single JSON-serializable map -
  /// used by [BackupService] to write a portable backup file.
  Future<Map<String, dynamic>> exportAll() async {
    final prefs = await _prefs;
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_'));
    final map = <String, dynamic>{};
    for (final k in keys) {
      map[k] = prefs.get(k);
    }
    return map;
  }

  /// Restores a previously exported map back into SharedPreferences.
  Future<void> importAll(Map<String, dynamic> data) async {
    final prefs = await _prefs;
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is String) {
        await prefs.setString(entry.key, value);
      } else if (value is bool) {
        await prefs.setBool(entry.key, value);
      } else if (value is int) {
        await prefs.setInt(entry.key, value);
      } else if (value is double) {
        await prefs.setDouble(entry.key, value);
      } else if (value is List) {
        await prefs.setStringList(entry.key, value.map((e) => e.toString()).toList());
      }
    }
  }
}
