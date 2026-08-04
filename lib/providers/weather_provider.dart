import 'package:flutter/foundation.dart';

import '../models/weather_models.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/local_cache.dart';
import '../services/location_service.dart';
import '../utils/districts.dart';

enum WeatherLoadState { idle, loading, loaded, error }

class WeatherProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  WeatherLoadState state = WeatherLoadState.idle;
  WeatherResponse? weather;
  String? errorMessage;
  bool usingCache = false;
  bool isOffline = false;
  bool locationDisabled = false;
  String? activeLocationLabel;
  String? activeCacheKey;

  final Map<String, WeatherResponse> districtWeather = {};
  bool loadingOverview = false;

  Future<void> loadFromDeviceLocation() async {
    state = WeatherLoadState.loading;
    errorMessage = null;
    isOffline = false;
    locationDisabled = false;
    notifyListeners();

    final online = await ConnectivityService.instance.hasConnection();
    if (!online) {
      await _fallbackOffline('gps');
      return;
    }

    try {
      final position = await LocationService.instance.getCurrentPosition();
      await _fetchAndStore(
        lat: position.latitude,
        lon: position.longitude,
        cacheKey: 'gps',
        fallbackLabel: 'Your Location',
      );
      await LocalCache.instance.setLastLocationKey('gps');
    } on LocationException catch (e) {
      locationDisabled = true;
      await _fallbackWithMessage('gps', e.message);
    } catch (e) {
      await _fallbackWithMessage('gps', e.toString());
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
    isOffline = false;
    locationDisabled = false;
    notifyListeners();

    final online = await ConnectivityService.instance.hasConnection();
    if (!online) {
      await _fallbackOffline(district.key);
      return;
    }

    try {
      await _fetchAndStore(
        lat: district.lat,
        lon: district.lon,
        cacheKey: district.key,
        fallbackLabel: district.label,
      );
      await LocalCache.instance.setLastLocationKey(district.key);
    } catch (e) {
      await _fallbackWithMessage(district.key, e.toString());
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
    isOffline = false;
    locationDisabled = false;
    activeLocationLabel = result.locationName ?? fallbackLabel;
    activeCacheKey = cacheKey;
    state = WeatherLoadState.loaded;
    await LocalCache.instance.saveWeather(cacheKey, result);
    notifyListeners();
  }

  /// No internet at all - go straight to cache, don't touch the network.
  Future<void> _fallbackOffline(String cacheKey) async {
    isOffline = true;
    final cached = await LocalCache.instance.readWeather(cacheKey);
    if (cached != null) {
      weather = cached;
      usingCache = true;
      activeCacheKey = cacheKey;
      activeLocationLabel = cached.locationName ?? districtLabel(cacheKey);
      state = WeatherLoadState.loaded;
      errorMessage = 'You are offline. Showing the last saved weather data.';
    } else {
      state = WeatherLoadState.error;
      errorMessage = 'You are offline and no saved weather data is available yet.';
    }
    notifyListeners();
  }

  /// Online, but something else failed - GPS off/denied, or a server error.
  Future<void> _fallbackWithMessage(String cacheKey, String message) async {
    final cached = await LocalCache.instance.readWeather(cacheKey);
    if (cached != null) {
      weather = cached;
      usingCache = true;
      activeCacheKey = cacheKey;
      activeLocationLabel = cached.locationName ?? districtLabel(cacheKey);
      state = WeatherLoadState.loaded;
      errorMessage = message;
    } else {
      state = WeatherLoadState.error;
      errorMessage = message;
    }
    notifyListeners();
  }

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

    final online = await ConnectivityService.instance.hasConnection();
    if (!online) return; // keep whatever cache was already loaded above

    loadingOverview = true;
    notifyListeners();

    await Future.wait(kKeralaDistricts.map((d) async {
      try {
        final result = await _api.fetchWeather(lat: d.lat, lon: d.lon);
        districtWeather[d.key] = result;
        await LocalCache.instance.saveWeather(d.key, result);
      } catch (_) {}
    }));

    loadingOverview = false;
    notifyListeners();
  }
}
