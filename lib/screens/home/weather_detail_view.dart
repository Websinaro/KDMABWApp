import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/weather_models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/alert_banner.dart';
import '../../widgets/daily_forecast_list.dart';
import '../../widgets/detail_grid.dart';
import '../../widgets/hourly_forecast_strip.dart';
import '../../widgets/weather_animation.dart';

/// The Google-Weather-style presentation of a [WeatherResponse]: a large
/// gradient header with current conditions, an hourly trend strip, a 7-day
/// outlook and a details grid. Reused for the citizen's own GPS location,
/// for browsing any district, and for the President's per-district drill-down.
class WeatherDetailView extends StatelessWidget {
  final WeatherResponse weather;
  final String locationLabel;
  final String? subLabel;
  final bool usingCache;
  final bool locationDisabled;
  final String? cacheMessage;
  final Future<void> Function() onRefresh;

  const WeatherDetailView({
    super.key,
    required this.weather,
    required this.locationLabel,
    required this.onRefresh,
    this.subLabel,
    this.usingCache = false,
    this.locationDisabled = false,
    this.cacheMessage,
  });

  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    final gradient = AppColors.weatherGradient(icon: current.weatherIcon, isDay: current.isDaytime);
    final updated = DateFormat('h:mm a').format(weather.fetchedAt);

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        locationLabel,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (subLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(subLabel!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${current.temperature.round()}°',
                      style: const TextStyle(fontSize: 68, fontWeight: FontWeight.w300, height: 1),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        WeatherAnimatedIcon(
                          key: ValueKey('${current.weatherIcon}-${current.isDaytime}'),
                          iconKey: current.weatherIcon,
                          isDay: current.isDaytime,
                          size: 76,
                        ),
                        const SizedBox(height: 2),
                        Text(current.weatherLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Feels like ${current.feelsLike.round()}°  ·  Updated $updated${usingCache ? ' (offline)' : ''}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (usingCache)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    locationDisabled ? Icons.location_off_rounded : Icons.cloud_off_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cacheMessage ?? "You're offline - showing the last saved update.",
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          AlertBanner(level: weather.alertLevel),
          const _SectionLabel('Hourly Forecast'),
          const SizedBox(height: 8),
          HourlyForecastStrip(hourly: weather.hourly),
          const SizedBox(height: 22),
          const _SectionLabel('7-Day Forecast'),
          const SizedBox(height: 6),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: DailyForecastList(daily: weather.daily),
          ),
          const SizedBox(height: 22),
          const _SectionLabel('Details'),
          const SizedBox(height: 8),
          DetailGrid(current: current, airQuality: weather.airQuality, daily: weather.daily),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}
