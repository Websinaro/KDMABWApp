import 'package:flutter/foundation.dart';

import '../models/weather_models.dart';
import '../services/api_service.dart';
import '../services/local_cache.dart';
import '../services/location_service.dart';
import '../utils/districts.dart';

enum WeatherLoadState { idle, loading, loaded, error }

/// Drives the "home" weather dashboard: resolves the device's GPS location
/// (or a manually chosen district), fetches live weather, and keeps a local
/// cache so the screen still shows something useful when offline.
class WeatherProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  WeatherLoadState state = WeatherLoadState.idle;
  WeatherResponse? weather;
  String? errorMessage;
  bool usingCache = false;
  String? activeLocationLabel;
  String? activeCacheKey;

  /// All 14 districts' weather, used by the President overview grid.
  final Map<String, WeatherResponse> districtWeather = {};
  bool loadingOverview = false;

  Future<void> loadFromDeviceLocation() async {
    state = WeatherLoadState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final position = await LocationService.instance.getCurrentPosition();
      await _fetchAndStore(
        lat: position.latitude,
        lon: position.longitude,
        cacheKey: 'gps',
        fallbackLabel: 'Your Location',
      );
      await LocalCache.instance.setLastLocationKey('gps');
    } catch (e) {
      await _handleFailure('gps', e);
    }
  }

  Future<void> loadForDistrict(String districtKey) async {
    final district = findDistrict(districtKey);
    if (district == null) {
      errorMessage = 'Unknown district';
      state = WeatherLoadState.error;
      notifyListeners();
      return;
    }

    state = WeatherLoadState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      await _fetchAndStore(
        lat: district.lat,
        lon: district.lon,
        cacheKey: district.key,
        fallbackLabel: district.label,
      );
      await LocalCache.instance.setLastLocationKey(district.key);
    } catch (e) {
      await _handleFailure(district.key, e);
    }
  }

  Future<void> _fetchAndStore({
    required double lat,
    required double lon,
    required String cacheKey,
    required String fallbackLabel,
  }) async {
    final result = await _api.fetchWeather(lat: lat, lon: lon);
    weather = result;
    usingCache = false;
    activeLocationLabel = result.locationName ?? fallbackLabel;
    activeCacheKey = cacheKey;
    state = WeatherLoadState.loaded;
    await LocalCache.instance.saveWeather(cacheKey, result);
    notifyListeners();
  }

  Future<void> _handleFailure(String cacheKey, Object e) async {
    final cached = await LocalCache.instance.readWeather(cacheKey);
    if (cached != null) {
      weather = cached;
      usingCache = true;
      activeCacheKey = cacheKey;
      activeLocationLabel = cached.locationName ?? districtLabel(cacheKey);
      state = WeatherLoadState.loaded;
      errorMessage = e.toString();
    } else {
      state = WeatherLoadState.error;
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Loads weather for every Kerala district in parallel (used by the
  /// President's state-wide overview). Cached values are shown immediately
  /// while a background refresh brings them up to date.
  Future<void> loadStateOverview({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await LocalCache.instance.readAllDistrictWeather(
        kKeralaDistricts.map((d) => d.key).toList(),
      );
      districtWeather
        ..clear()
        ..addAll(cached);
      notifyListeners();
    }

    loadingOverview = true;
    notifyListeners();

    await Future.wait(kKeralaDistricts.map((d) async {
      try {
        final result = await _api.fetchWeather(lat: d.lat, lon: d.lon);
        districtWeather[d.key] = result;
        await LocalCache.instance.saveWeather(d.key, result);
      } catch (_) {
        // Keep whatever cached value exists for this district; skip on error.
      }
    }));

    loadingOverview = false;
    notifyListeners();
  }
}
