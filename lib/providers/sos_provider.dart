import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/sos_models.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

enum SosStatus { idle, sending, active, error }

class SosProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  SosStatus status = SosStatus.idle;
  SosAlert? activeAlert;
  String? errorMessage;
  Timer? _locationTimer;

  /// Checks the server for an SOS the user already has active - e.g. the
  /// app was closed and reopened mid-emergency. Called once at startup so
  /// the button never wrongly resets to idle while a real SOS is still live.
  Future<void> restoreActiveSos() async {
    try {
      final alert = await _api.fetchMyActiveSos();
      if (alert != null && alert.isActive) {
        activeAlert = alert;
        status = SosStatus.active;
        notifyListeners();
        _startLocationUpdates();
      }
    } catch (_) {
      // Non-fatal - if this check fails (offline, server waking up), just
      // leave the button in its default state rather than blocking startup.
    }
  }

  Future<bool> sendSos() async {
    status = SosStatus.sending;
    errorMessage = null;
    notifyListeners();

    try {
      final position = await LocationService.instance.getCurrentPosition();
      final alert = await _api.createSos(
        lat: position.latitude,
        lon: position.longitude,
        message: 'Emergency SOS triggered from the WeBAlert app.',
      );

      activeAlert = alert;
      status = SosStatus.active;
      notifyListeners();

      _startLocationUpdates();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      status = SosStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Could not get your location. Please enable location and try again.';
      status = SosStatus.error;
      notifyListeners();
      return false;
    }
  }

  void _startLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      final alert = activeAlert;
      if (alert == null || !alert.isActive) {
        _locationTimer?.cancel();
        return;
      }
      try {
        final position = await LocationService.instance.getCurrentPosition();
        await _api.updateSosLocation(sosId: alert.id, lat: position.latitude, lon: position.longitude);
      } catch (_) {
        // Skip this tick silently - a single missed update isn't worth
        // interrupting an active emergency with an error dialog.
      }
    });
  }

  Future<bool> markSafe() async {
    final alert = activeAlert;
    if (alert == null) return true;

    try {
      await _api.resolveSos(alert.id);
      _locationTimer?.cancel();
      status = SosStatus.idle;
      activeAlert = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  void resetError() {
    if (status == SosStatus.error) {
      status = SosStatus.idle;
      errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }
}