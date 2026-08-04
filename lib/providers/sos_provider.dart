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

  Future<bool> sendSos() async {
    status = SosStatus.sending;
    errorMessage = null;
    notifyListeners();

    try {
      // getFastPosition() prefers the device's cached last-known location
      // and only waits a bounded few seconds for a fresh GPS fix, instead
      // of potentially waiting 10-30+ seconds for a cold fix before the
      // SOS is even sent. If it's a bit off, updateSosLocation() below
      // corrects it moments later.
      final position = await LocationService.instance.getFastPosition();
      final alert = await _api.createSos(
        lat: position.latitude,
        lon: position.longitude,
        message: 'Emergency SOS triggered from the WeBAlert app.',
      );

      activeAlert = alert;
      status = SosStatus.active;
      notifyListeners();

      _startLocationUpdates();
      _refineInitialLocation(alert.id);
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

  /// Fired right after a successful SOS send. If the initial position came
  /// from a cached last-known fix, this grabs one accurate GPS reading in
  /// the background and pushes it up, so protectors quickly see a precise
  /// pin without the sender having waited for it before help was alerted.
  Future<void> _refineInitialLocation(int sosId) async {
    try {
      final accurate = await LocationService.instance.getCurrentPosition();
      final alert = activeAlert;
      if (alert == null || alert.id != sosId || !alert.isActive) return;
      await _api.updateSosLocation(sosId: sosId, lat: accurate.latitude, lon: accurate.longitude);
    } catch (_) {
      // The periodic 15s updates in _startLocationUpdates will catch up.
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
      // Non-fatal - if this check fails (offline, etc.), just leave the
      // button in its default state rather than blocking startup.
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