import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/sos_models.dart';
import '../../services/api_service.dart';
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
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _alert = null;
    _fetch();
    _poller = Timer.periodic(const Duration(seconds: 5), (_) => _fetch());
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

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lat = _alert?.latitude ?? widget.initialLat;
    final lon = _alert?.longitude ?? widget.initialLon;
    final isActive = _alert?.isActive ?? true;

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
                ],
              ),
            ],
          ),
          if (!isActive)
            Positioned(
              top: 16,
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