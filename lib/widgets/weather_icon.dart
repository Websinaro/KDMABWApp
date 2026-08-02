import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Maps the `weather_icon` string returned by the backend
/// (`data/weather_codes.py`) to a Material icon + tint color.
/// Deliberately uses only long-standing, stable Icons (no icon-font
/// assets to download) so the app stays fast and lightweight.
class WeatherIconData {
  final IconData icon;
  final Color color;
  const WeatherIconData(this.icon, this.color);
}

WeatherIconData weatherIconFor(String iconKey, {bool isDay = true}) {
  switch (iconKey) {
    case 'sunny':
      return isDay
          ? const WeatherIconData(Icons.wb_sunny_rounded, Color(0xFFFFC24B))
          : const WeatherIconData(Icons.nights_stay_rounded, Color(0xFF9AB4E0));
    case 'mostly_sunny':
      return isDay
          ? const WeatherIconData(Icons.wb_sunny_rounded, Color(0xFFFFC24B))
          : const WeatherIconData(Icons.nights_stay_rounded, Color(0xFF9AB4E0));
    case 'partly_cloudy':
      return isDay
          ? const WeatherIconData(Icons.wb_cloudy_rounded, Color(0xFFB9C6D6))
          : const WeatherIconData(Icons.cloud_rounded, Color(0xFF8493A6));
    case 'cloudy':
      return const WeatherIconData(Icons.cloud_rounded, Color(0xFF8FA0B3));
    case 'fog':
      return const WeatherIconData(Icons.blur_on_rounded, Color(0xFF9AA7B5));
    case 'drizzle':
      return const WeatherIconData(Icons.grain_rounded, Color(0xFF57B7E0));
    case 'rain':
      return const WeatherIconData(Icons.water_drop_rounded, Color(0xFF3FA0E0));
    case 'heavy_rain':
      return const WeatherIconData(Icons.water_drop_rounded, AppColors.alertOrange);
    case 'rain_showers':
      return const WeatherIconData(Icons.water_drop_rounded, Color(0xFF3FA0E0));
    case 'snow':
      return const WeatherIconData(Icons.ac_unit_rounded, Color(0xFFBFE3FF));
    case 'thunderstorm':
      return const WeatherIconData(Icons.flash_on_rounded, AppColors.alertRed);
    case 'thunderstorm_hail':
      return const WeatherIconData(Icons.flash_on_rounded, AppColors.alertRed);
    default:
      return const WeatherIconData(Icons.help_outline_rounded, AppColors.textMuted);
  }
}
