import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../models/sos_models.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_colors.dart';

class SosLiveMapScreen extends StatefulWidget {
  final int sosId;
  final String senderName;
  final double initialLat;
  final double initialLon;

  const SosLiveMapScreen({
    super.key,
    required this.sosId,
    required this.senderName,
    required this.initialLat,
    required this.initialLon,
  });

  @override
  State<SosLiveMapScreen> createState() => _SosLiveMapScreenState();
}

class _SosLiveMapScreenState extends State<SosLiveMapScreen> {
  late SosAlert? _alert;
  Timer? _poller;
  StreamSubscription<Position>? _positionSub;
  Position? _myPosition;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _alert = null;
    _fetch();
    _poller = Timer.periodic(const Duration(seconds: 5), (_) => _fetch());
    _watchMyPosition();
  }

  Future<void> _fetch() async {
    try {
      final alert = await ApiService.instance.fetchSos(widget.sosId);
      if (!mounted) return;
      setState(() => _alert = alert);
      _mapController.move(LatLng(alert.latitude, alert.longitude), _mapController.camera.zoom);
      if (!alert.isActive) {
        _poller?.cancel();
      }
    } catch (_) {
      // Skip this tick - keep showing the last known position.
    }
  }

  /// Streams the protector's own live location so the "distance away"
  /// readout updates as they move toward the person in trouble, not just
  /// when the sender's pin moves.
  Future<void> _watchMyPosition() async {
    try {
      final quick = await LocationService.instance.getFastPosition();
      if (mounted) setState(() => _myPosition = quick);
    } catch (_) {
      // No initial fix available yet - the stream below may still catch up.
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 15),
    ).listen(
      (position) {
        if (mounted) setState(() => _myPosition = position);
      },
      onError: (_) {},
    );
  }

  /// Haversine great-circle distance in kilometers between two lat/lon
  /// points. Accurate enough for a "how far away" readout without pulling
  /// in a dependency for it.
  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    double toRad(double deg) => deg * math.pi / 180.0;

    final dLat = toRad(lat2 - lat1);
    final dLon = toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRad(lat1)) * math.cos(toRad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m away';
    if (km < 10) return '${km.toStringAsFixed(1)} km away';
    return '${km.round()} km away';
  }

  @override
  void dispose() {
    _poller?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lat = _alert?.latitude ?? widget.initialLat;
    final lon = _alert?.longitude ?? widget.initialLon;
    final isActive = _alert?.isActive ?? true;

    final myPos = _myPosition;
    final distanceKm = myPos != null ? _distanceKm(myPos.latitude, myPos.longitude, lat, lon) : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.alertDarkRed,
        title: Text('${widget.senderName} - ${isActive ? "SOS ACTIVE" : "Resolved"}'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: LatLng(lat, lon), initialZoom: 15),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.websinaro.webalert',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(lat, lon),
                    width: 60,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.alertDarkRed,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: AppColors.alertDarkRed.withValues(alpha: 0.6), blurRadius: 12)],
                      ),
                      child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 34),
                    ),
                  ),
                  if (myPos != null)
                    Marker(
                      point: LatLng(myPos.latitude, myPos.longitude),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 10)],
                        ),
                        child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (distanceKm != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _DistanceBadge(text: _formatDistance(distanceKm)),
            ),
          if (!isActive)
            Positioned(
              top: distanceKm != null ? 76 : 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.alertGreen, borderRadius: BorderRadius.circular(12)),
                child: const Text(
                  'This person has marked themselves safe.',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DistanceBadge extends StatelessWidget {
  final String text;
  const _DistanceBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.social_distance_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
