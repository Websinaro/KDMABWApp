import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weather_models.dart';
import '../theme/app_colors.dart';
import 'weather_icon.dart';

/// A Google-Weather-style hourly strip: a smooth temperature trend line
/// drawn with a lightweight CustomPainter (no chart package needed) with an
/// icon + hour + temperature underneath each point.
class HourlyForecastStrip extends StatelessWidget {
  final HourlyForecast hourly;
  final int hoursToShow;

  const HourlyForecastStrip({super.key, required this.hourly, this.hoursToShow = 24});

  @override
  Widget build(BuildContext context) {
    final count = hourly.length < hoursToShow ? hourly.length : hoursToShow;
    if (count == 0) return const SizedBox.shrink();

    final temps = hourly.temperature.sublist(0, count);
    final minT = temps.reduce((a, b) => a < b ? a : b);
    final maxT = temps.reduce((a, b) => a > b ? a : b);

    const itemWidth = 62.0;
    final chartWidth = count * itemWidth;

    return SizedBox(
      height: 148,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: chartWidth,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 54,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _TempTrendPainter(
                      temps: temps,
                      minT: minT,
                      maxT: maxT,
                      itemWidth: itemWidth,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: 54),
                  Row(
                    children: List.generate(count, (i) {
                      final time = DateTime.tryParse(hourly.time[i]);
                      final label = i == 0 ? 'Now' : (time != null ? DateFormat('ha').format(time) : '--');
                      final iconData = weatherIconFor(
                        _codeToIcon(hourly.weatherCode[i]),
                        isDay: time == null || (time.hour >= 6 && time.hour < 18),
                      );
                      final rain = hourly.rainProbability.length > i ? hourly.rainProbability[i] : null;

                      return SizedBox(
                        width: itemWidth,
                        child: Column(
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Icon(iconData.icon, color: iconData.color, size: 20),
                            const SizedBox(height: 6),
                            Text(
                              '${temps[i].round()}°',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 3),
                            if (rain != null && rain >= 10)
                              Text(
                                '${rain.round()}%',
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF3FA0E0)),
                              )
                            else
                              const SizedBox(height: 13),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Falls back to a generic icon key since hourly data only carries a
  // weather code, not the pre-resolved icon string the /current block has.
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
}

class _TempTrendPainter extends CustomPainter {
  final List<double> temps;
  final double minT;
  final double maxT;
  final double itemWidth;
  final Color color;

  _TempTrendPainter({
    required this.temps,
    required this.minT,
    required this.maxT,
    required this.itemWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (temps.length < 2) return;
    final range = (maxT - minT).abs() < 0.5 ? 1.0 : (maxT - minT);
    const topPad = 8.0;
    const bottomPad = 8.0;
    final usableHeight = size.height - topPad - bottomPad;

    Offset pointAt(int i) {
      final x = itemWidth * i + itemWidth / 2;
      final t = (temps[i] - minT) / range;
      final y = topPad + usableHeight - (t * usableHeight);
      return Offset(x, y);
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (int i = 1; i < temps.length; i++) {
      final p0 = pointAt(i - 1);
      final p1 = pointAt(i);
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = color;
    for (int i = 0; i < temps.length; i++) {
      canvas.drawCircle(pointAt(i), 2.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TempTrendPainter oldDelegate) {
    return oldDelegate.temps != temps || oldDelegate.minT != minT || oldDelegate.maxT != maxT;
  }
}
