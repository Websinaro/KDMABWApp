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
}
