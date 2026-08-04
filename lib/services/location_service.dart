import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  final String message;
  final bool permanentlyDenied;
  LocationException(this.message, {this.permanentlyDenied = false});

  @override
  String toString() => message;
}

class LocationService {
  LocationService._internal();
  static final LocationService instance = LocationService._internal();

  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  Future<LocationPermission> requestPermission() => Geolocator.requestPermission();

  /// Requests permission and returns the current device position.
  /// Throws [LocationException] with a user-friendly message on failure.
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Location services are turned off. Please enable GPS to see local weather.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Location permission was denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permission is permanently denied. Enable it from the app settings.',
        permanentlyDenied: true,
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 100,
      ),
    );
  }

  /// Returns a position as fast as possible for time-critical use (SOS).
  ///
  /// A cold GPS fix (`getCurrentPosition`) can genuinely take 10-30+
  /// seconds on a real device, especially indoors or with a weak signal -
  /// completely unacceptable as the thing standing between someone
  /// pressing SOS and the alert actually being sent. This instead:
  ///   1. Checks permissions/service (fast, local).
  ///   2. Tries the device's last-known position first - usually
  ///      available instantly since the OS caches it.
  ///   3. If that's missing or looks stale (>2 min old), races it against
  ///      a fresh fix capped at [freshFixTimeout] so we never wait longer
  ///      than that for a first location.
  ///
  /// The caller is expected to send the SOS with whatever this returns,
  /// then continue refining the location via `updateSosLocation` once a
  /// more accurate fix comes in - accuracy improves after the alert is
  /// already out, instead of delaying the alert itself.
  Future<Position> getFastPosition({
    Duration freshFixTimeout = const Duration(seconds: 6),
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Location services are turned off. Please enable GPS to send an accurate SOS.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Location permission was denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permission is permanently denied. Enable it from the app settings.',
        permanentlyDenied: true,
      );
    }

    Position? lastKnown;
    try {
      lastKnown = await Geolocator.getLastKnownPosition();
    } catch (_) {
      lastKnown = null;
    }

    final isFreshEnough = lastKnown != null &&
        DateTime.now().difference(lastKnown.timestamp).abs() < const Duration(minutes: 2);
    if (isFreshEnough) {
      return lastKnown!;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      ).timeout(freshFixTimeout);
    } catch (_) {
      // Fresh fix took too long or failed - fall back to whatever
      // last-known position we have, even if it's stale. A slightly old
      // location sent immediately is far more useful for an SOS than no
      // location at all while still "getting a better fix".
      if (lastKnown != null) return lastKnown;
      rethrow;
    }
  }
}
