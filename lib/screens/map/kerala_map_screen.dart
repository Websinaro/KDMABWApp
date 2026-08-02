import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/kerala_map_models.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/error_retry_view.dart';

class KeralaMapScreen extends StatefulWidget {
  const KeralaMapScreen({super.key});

  @override
  State<KeralaMapScreen> createState() => _KeralaMapScreenState();
}

class _KeralaMapScreenState extends State<KeralaMapScreen> {
  late Future<KeralaMapResponse> _future;

  static const LatLng _keralaCenter = LatLng(10.2, 76.3);

  @override
  void initState() {
    super.initState();
    _future = ApiService.instance.fetchKeralaMap();
  }

  void _reload() {
    setState(() {
      _future = ApiService.instance.fetchKeralaMap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Kerala Risk Map'),
      ),
      body: FutureBuilder<KeralaMapResponse>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorRetryView(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final districts = snapshot.data!.districts;

          return Stack(
            children: [
              FlutterMap(
                options: const MapOptions(
                  initialCenter: _keralaCenter,
                  initialZoom: 7.2,
                  minZoom: 6,
                  maxZoom: 12,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.websinaro.webalert',
                  ),
                  CircleLayer(
                    circles: districts.map((d) {
                      return CircleMarker(
                        point: LatLng(d.latitude, d.longitude),
                        radius: 26,
                        color: AppColors.alertColor(d.alertLevel).withOpacity(0.35),
                        borderColor: AppColors.alertColor(d.alertLevel),
                        borderStrokeWidth: 2,
                      );
                    }).toList(),
                  ),
                  MarkerLayer(
                    markers: districts.map((d) {
                      return Marker(
                        point: LatLng(d.latitude, d.longitude),
                        width: 60,
                        height: 60,
                        child: GestureDetector(
                          onTap: () => _showDistrictSheet(context, d),
                          child: _DistrictMarker(district: d),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              Positioned(bottom: 16, left: 16, right: 16, child: _Legend()),
            ],
          );
        },
      ),
    );
  }

  void _showDistrictSheet(BuildContext context, DistrictMapPoint d) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.alertColor(d.alertLevel),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  d.district[0].toUpperCase() + d.district.substring(1),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppColors.alertLabel(d.alertLevel),
              style: TextStyle(color: AppColors.alertColor(d.alertLevel), fontSize: 14),
            ),
            const SizedBox(height: 16),
            _statRow('Condition', d.weatherLabel),
            _statRow('Temperature', '${d.temperature.toStringAsFixed(1)}°C'),
            _statRow('Humidity', '${d.humidity.toStringAsFixed(0)}%'),
            _statRow('Rain Probability', '${d.rainProbability.toStringAsFixed(0)}%'),
            _statRow('Wind', '${d.windSpeed.toStringAsFixed(1)} km/h, gusts ${d.windGusts.toStringAsFixed(1)} km/h'),
            _statRow('Wind Direction', '${d.windDirection.toStringAsFixed(0)}° (${_compass(d.windDirection)})'),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _compass(double degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((degrees % 360) / 45).round() % 8;
    return directions[index];
  }
}

/// Colored dot + wind-direction arrow, rotated to point where the wind blows.
class _DistrictMarker extends StatelessWidget {
  final DistrictMapPoint district;
  const _DistrictMarker({required this.district});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.alertColor(district.alertLevel);
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8)],
          ),
        ),
        // Wind direction arrow: meteorological wind_direction is where the
        // wind blows FROM, so the arrow is rotated to point where it blows TO.
        Transform.rotate(
          angle: (district.windDirection + 180) * (math.pi / 180),
          child: const Icon(Icons.navigation_rounded, size: 34, color: Colors.white),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = const [
      ['dark_red', 'Very High'],
      ['light_red', 'High'],
      ['orange', 'Risk'],
      ['yellow', 'Low Risk'],
      ['green', 'Safe'],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: items.map((item) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.alertColor(item[0]),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(item[1], style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          );
        }).toList(),
      ),
    );
  }
}