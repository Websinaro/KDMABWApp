import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weather_models.dart';
import '../theme/app_colors.dart';

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  const _DetailItem({required this.icon, required this.label, required this.value, this.sub});
}

class DetailGrid extends StatelessWidget {
  final CurrentWeather current;
  final AirQuality? airQuality;
  final DailyForecast daily;

  const DetailGrid({super.key, required this.current, required this.airQuality, required this.daily});

  String _fmtTime(String? iso) {
    if (iso == null) return '--';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '--';
    return DateFormat('h:mm a').format(dt);
  }

  String _windDirLabel(double deg) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final idx = ((deg % 360) / 45).round() % 8;
    return dirs[idx];
  }

  String _uvCategory(double uv) {
    if (uv < 3) return 'Low';
    if (uv < 6) return 'Moderate';
    if (uv < 8) return 'High';
    if (uv < 11) return 'Very High';
    return 'Extreme';
  }

  @override
  Widget build(BuildContext context) {
    final items = <_DetailItem>[
      _DetailItem(
        icon: Icons.water_drop_outlined,
        label: 'Humidity',
        value: '${current.humidity.round()}%',
      ),
      _DetailItem(
        icon: Icons.air_rounded,
        label: 'Wind',
        value: '${current.windSpeed.round()} km/h',
        sub: _windDirLabel(current.windDirection),
      ),
      if (current.uvIndex != null)
        _DetailItem(
          icon: Icons.wb_sunny_outlined,
          label: 'UV Index',
          value: current.uvIndex!.round().toString(),
          sub: _uvCategory(current.uvIndex!),
        ),
      _DetailItem(
        icon: Icons.speed_rounded,
        label: 'Pressure',
        value: '${current.pressure.round()} hPa',
      ),
      _DetailItem(
        icon: Icons.brightness_5_rounded,
        label: 'Sunrise',
        value: _fmtTime(daily.sunrise.isNotEmpty ? daily.sunrise.first : null),
      ),
      _DetailItem(
        icon: Icons.nights_stay_outlined,
        label: 'Sunset',
        value: _fmtTime(daily.sunset.isNotEmpty ? daily.sunset.first : null),
      ),
      if (airQuality?.aqi != null)
        _DetailItem(
          icon: Icons.eco_outlined,
          label: 'Air Quality',
          value: airQuality!.aqi!.round().toString(),
          sub: 'US AQI',
        ),
      _DetailItem(
        icon: Icons.cloud_outlined,
        label: 'Cloud Cover',
        value: '${current.cloudCover.round()}%',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(item.icon, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    item.label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(item.value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                  if (item.sub != null) ...[
                    const SizedBox(width: 6),
                    Text(item.sub!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
