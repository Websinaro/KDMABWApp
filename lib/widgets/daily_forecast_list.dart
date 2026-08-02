import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weather_models.dart';
import '../theme/app_colors.dart';
import 'weather_icon.dart';

class DailyForecastList extends StatelessWidget {
  final DailyForecast daily;

  const DailyForecastList({super.key, required this.daily});

  String _codeToIcon(int code) {
    if (code == 0) return 'sunny';
    if (code == 1) return 'mostly_sunny';
    if (code == 2) return 'partly_cloudy';
    if (code == 3) return 'cloudy';
    if (code == 45 || code == 48) return 'fog';
    if ([51, 53, 55, 56, 57].contains(code)) return 'drizzle';
    if ([61, 63].contains(code)) return 'rain';
    if ([65, 67].contains(code)) return 'heavy_rain';
    if ([71, 73, 75, 77, 85, 86].contains(code)) return 'snow';
    if ([80, 81].contains(code)) return 'rain_showers';
    if (code == 82) return 'heavy_rain';
    if ([95, 96, 99].contains(code)) return 'thunderstorm';
    return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    final count = daily.length;
    if (count == 0) return const SizedBox.shrink();

    final globalMin = daily.tempMin.reduce((a, b) => a < b ? a : b);
    final globalMax = daily.tempMax.reduce((a, b) => a > b ? a : b);
    final globalRange = (globalMax - globalMin).abs() < 0.5 ? 1.0 : (globalMax - globalMin);

    return Column(
      children: List.generate(count, (i) {
        final date = DateTime.tryParse(daily.date[i]);
        final label = i == 0 ? 'Today' : (date != null ? DateFormat('EEE').format(date) : '--');
        final iconData = weatherIconFor(_codeToIcon(daily.weatherCode[i]));
        final rain = daily.rainProbabilityMax.length > i ? daily.rainProbabilityMax[i] : null;

        final startFrac = ((daily.tempMin[i] - globalMin) / globalRange).clamp(0.0, 1.0);
        final endFrac = ((daily.tempMax[i] - globalMin) / globalRange).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              ),
              SizedBox(
                width: 30,
                child: Icon(iconData.icon, color: iconData.color, size: 19),
              ),
              SizedBox(
                width: 34,
                child: rain != null && rain >= 10
                    ? Text('${rain.round()}%', style: const TextStyle(fontSize: 11, color: Color(0xFF3FA0E0)))
                    : const SizedBox.shrink(),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '${daily.tempMin[i].round()}°',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Positioned(
                          left: w * startFrac,
                          width: (w * (endFrac - startFrac)).clamp(4.0, w),
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.alertYellow, AppColors.alertOrange],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 34,
                child: Text(
                  '${daily.tempMax[i].round()}°',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
