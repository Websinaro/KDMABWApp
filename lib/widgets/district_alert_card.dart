import 'package:flutter/material.dart';

import '../models/weather_models.dart';
import '../theme/app_colors.dart';
import 'alert_banner.dart';
import 'weather_icon.dart';

class DistrictAlertCard extends StatefulWidget {
  final String label;
  final WeatherResponse? weather;
  final VoidCallback onTap;
  final bool isHome;

  const DistrictAlertCard({
    super.key,
    required this.label,
    required this.weather,
    required this.onTap,
    this.isHome = false,
  });

  @override
  State<DistrictAlertCard> createState() => _DistrictAlertCardState();
}

class _DistrictAlertCardState extends State<DistrictAlertCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    final weather = widget.weather;
    final onTap = widget.onTap;
    final isHome = widget.isHome;

    final level = weather?.alertLevel ?? 'green';
    final color = AppColors.alertColor(level);
    final iconData = weather != null
        ? weatherIconFor(weather.current.weatherIcon, isDay: weather.current.isDaytime)
        : const WeatherIconData(Icons.hourglass_empty_rounded, AppColors.textMuted);

    // RepaintBoundary keeps the tap-scale animation's repaints isolated from
    // the rest of the grid; AnimatedScale gives a light, tactile "press" so
    // the UI feels responsive even before the navigation transition starts.
    return RepaintBoundary(
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: InkWell(
          onTap: onTap,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: level == 'green' ? AppColors.cardBorder : color.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isHome)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.my_location_rounded, size: 13, color: AppColors.primary),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(iconData.icon, color: iconData.color, size: 26),
                    const SizedBox(width: 8),
                    if (weather != null)
                      Text(
                        '${weather.current.temperature.round()}°',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      )
                    else
                      const Text('--°', style: TextStyle(fontSize: 22, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 10),
                AlertPill(level: level, compact: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
