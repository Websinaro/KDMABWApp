import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated, hand-drawn-style weather illustration matching the backend's
/// `weather_icon` key (see `weather_icon.dart` for the string values).
///
/// Deliberately implemented with a single lightweight [CustomPainter]
/// instead of downloaded image/lottie assets:
///  * no network / asset bundle needed -> instantly available, smaller app
///  * cheap to paint (a handful of shapes) -> stays smooth on low-end phones
///  * wrapped in [RepaintBoundary] so repaints never bleed into the rest of
///    the screen
///  * the animation ticker is stopped whenever the app is backgrounded, so
///    it doesn't burn battery while the phone is in someone's pocket.
class WeatherAnimatedIcon extends StatefulWidget {
  final String iconKey;
  final bool isDay;
  final double size;

  const WeatherAnimatedIcon({
    super.key,
    required this.iconKey,
    required this.isDay,
    this.size = 96,
  });

  @override
  State<WeatherAnimatedIcon> createState() => _WeatherAnimatedIconState();
}

class _WeatherAnimatedIconState extends State<WeatherAnimatedIcon>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 7))
      ..repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Battery saving: don't keep animating off-screen / backgrounded.
    if (state == AppLifecycleState.resumed) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = _categoryFor(widget.iconKey, widget.isDay);
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _WeatherPainter(t: _controller.value, category: category),
            );
          },
        ),
      ),
    );
  }
}

enum _Category { sun, moon, cloud, rain, thunder, snow, fog }

_Category _categoryFor(String iconKey, bool isDay) {
  switch (iconKey) {
    case 'sunny':
    case 'mostly_sunny':
      return isDay ? _Category.sun : _Category.moon;
    case 'partly_cloudy':
    case 'cloudy':
      return _Category.cloud;
    case 'fog':
      return _Category.fog;
    case 'drizzle':
    case 'rain':
    case 'rain_showers':
    case 'heavy_rain':
      return _Category.rain;
    case 'thunderstorm':
    case 'thunderstorm_hail':
      return _Category.thunder;
    case 'snow':
      return _Category.snow;
    default:
      return isDay ? _Category.cloud : _Category.moon;
  }
}

class _WeatherPainter extends CustomPainter {
  final double t; // 0..1, loops forever
  final _Category category;

  _WeatherPainter({required this.t, required this.category});

  static const _sunColor = Color(0xFFFFC24B);
  static const _sunCore = Color(0xFFFFE29A);
  static const _cloudLight = Color(0xFFC9D4E0);
  static const _cloudDark = Color(0xFF8FA0B3);
  static const _rainColor = Color(0xFF4FB3E8);
  static const _moonColor = Color(0xFFE7EEFC);
  static const _boltColor = Color(0xFFFFD24B);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    switch (category) {
      case _Category.sun:
        _paintSun(canvas, size, center);
        break;
      case _Category.moon:
        _paintMoon(canvas, size, center);
        break;
      case _Category.cloud:
        _paintCloud(canvas, size, center);
        break;
      case _Category.fog:
        _paintCloud(canvas, size, Offset(center.dx, center.dy - size.height * 0.06), muted: true);
        _paintFog(canvas, size);
        break;
      case _Category.rain:
        _paintCloud(canvas, size, Offset(center.dx, center.dy - size.height * 0.14));
        _paintRain(canvas, size, count: 6);
        break;
      case _Category.thunder:
        _paintCloud(canvas, size, Offset(center.dx, center.dy - size.height * 0.14));
        _paintRain(canvas, size, count: 4);
        _paintLightning(canvas, size);
        break;
      case _Category.snow:
        _paintCloud(canvas, size, Offset(center.dx, center.dy - size.height * 0.14));
        _paintSnow(canvas, size);
        break;
    }
  }

  void _paintSun(Canvas canvas, Size size, Offset center) {
    final pulse = 1 + 0.06 * math.sin(2 * math.pi * t);
    final coreRadius = size.width * 0.20 * pulse;

    // Soft outer glow.
    final glowPaint = Paint()
      ..color = _sunColor.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center, coreRadius * 1.9, glowPaint);

    // Rotating rays.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(t * 2 * math.pi * 0.35);
    final rayPaint = Paint()
      ..color = _sunColor.withValues(alpha: 0.85)
      ..strokeWidth = size.width * 0.028
      ..strokeCap = StrokeCap.round;
    const rayCount = 8;
    for (int i = 0; i < rayCount; i++) {
      final angle = (2 * math.pi / rayCount) * i;
      final r1 = coreRadius * 1.35;
      final r2 = coreRadius * (1.75 + 0.08 * math.sin(2 * math.pi * t + i));
      final p1 = Offset(math.cos(angle) * r1, math.sin(angle) * r1);
      final p2 = Offset(math.cos(angle) * r2, math.sin(angle) * r2);
      canvas.drawLine(p1, p2, rayPaint);
    }
    canvas.restore();

    // Core.
    final corePaint = Paint()
      ..shader = RadialGradient(colors: [_sunCore, _sunColor]).createShader(
        Rect.fromCircle(center: center, radius: coreRadius),
      );
    canvas.drawCircle(center, coreRadius, corePaint);
  }

  void _paintMoon(Canvas canvas, Size size, Offset center) {
    final radius = size.width * 0.22;

    // Twinkling stars scattered around the moon.
    final starPositions = <Offset>[
      Offset(size.width * 0.20, size.height * 0.28),
      Offset(size.width * 0.78, size.height * 0.22),
      Offset(size.width * 0.82, size.height * 0.62),
      Offset(size.width * 0.18, size.height * 0.68),
      Offset(size.width * 0.50, size.height * 0.14),
    ];
    for (int i = 0; i < starPositions.length; i++) {
      final phase = (t * 2 * math.pi) + i * 1.3;
      final twinkle = (math.sin(phase) + 1) / 2; // 0..1
      final starPaint = Paint()..color = _moonColor.withValues(alpha: 0.25 + twinkle * 0.6);
      canvas.drawCircle(starPositions[i], 1.6 + twinkle * 1.2, starPaint);
    }

    // Crescent: full circle minus an offset circle.
    final fullMoon = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    final bite = Path()
      ..addOval(Rect.fromCircle(center: Offset(center.dx + radius * 0.55, center.dy - radius * 0.15), radius: radius * 0.92));
    final crescent = Path.combine(PathOperation.difference, fullMoon, bite);

    final glowPaint = Paint()
      ..color = _moonColor.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, radius * 1.3, glowPaint);

    canvas.drawPath(crescent, Paint()..color = _moonColor);
  }

  void _paintCloud(Canvas canvas, Size size, Offset center, {bool muted = false}) {
    final drift = math.sin(2 * math.pi * t) * size.width * 0.025;
    final bob = math.sin(2 * math.pi * t * 1.3) * size.height * 0.01;
    final origin = Offset(center.dx + drift, center.dy + bob);

    final w = size.width;
    final base = origin.dy + w * 0.10;

    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(origin.dx - w * 0.16, base), radius: w * 0.16))
      ..addOval(Rect.fromCircle(center: Offset(origin.dx + w * 0.10, base - w * 0.06), radius: w * 0.20))
      ..addOval(Rect.fromCircle(center: Offset(origin.dx + w * 0.30, base + w * 0.02), radius: w * 0.14))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx - w * 0.30, base - w * 0.02, w * 0.56, w * 0.16),
        Radius.circular(w * 0.10),
      ));

    final fillColor = muted ? _cloudDark.withValues(alpha: 0.6) : _cloudLight;
    canvas.drawPath(path, Paint()..color = fillColor);

    // Subtle top highlight for depth.
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Rect.fromLTWH(0, base - w * 0.20, size.width, w * 0.14),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
    canvas.restore();
  }

  void _paintFog(Canvas canvas, Size size) {
    final bandY = [0.62, 0.74, 0.86];
    for (int i = 0; i < bandY.length; i++) {
      final progress = (t + i * 0.33) % 1.0;
      // Slide from -0.2..1.2 of width for a seamless in/out loop.
      final dx = (progress * 1.4 - 0.2) * size.width;
      final rect = Rect.fromLTWH(dx, size.height * bandY[i], size.width * 0.5, size.height * 0.045);
      final opacity = (math.sin(progress * math.pi)).clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
        Paint()..color = Colors.white.withValues(alpha: 0.28 * opacity),
      );
    }
  }

  void _paintRain(Canvas canvas, Size size, {int count = 6}) {
    final dropPaint = Paint()
      ..color = _rainColor
      ..strokeWidth = size.width * 0.02
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < count; i++) {
      final seed = i / count;
      final x = size.width * (0.14 + seed * 0.72) + math.sin(seed * 12) * 3;
      final fall = (t * 1.6 + seed) % 1.0;
      final y = size.height * (0.52 + fall * 0.42);
      final len = size.height * 0.09;
      final alpha = (1 - fall) * 0.9 + 0.1;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 2, y + len),
        dropPaint..color = _rainColor.withValues(alpha: alpha.clamp(0.0, 1.0)),
      );
    }
  }

  void _paintSnow(Canvas canvas, Size size) {
    const count = 8;
    final flakePaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    for (int i = 0; i < count; i++) {
      final seed = i / count;
      final fall = (t * 0.9 + seed) % 1.0;
      final sway = math.sin(2 * math.pi * t * 1.4 + i) * size.width * 0.05;
      final x = size.width * (0.12 + seed * 0.76) + sway;
      final y = size.height * (0.50 + fall * 0.46);
      final radius = 1.4 + 1.0 * math.sin(seed * 8);
      canvas.drawCircle(Offset(x, y), radius.abs() + 0.6, flakePaint..color = Colors.white.withValues(alpha: 0.85 - fall * 0.3));
    }
  }

  void _paintLightning(Canvas canvas, Size size) {
    // A brief periodic flash, roughly twice per loop.
    final raw = math.sin(2 * math.pi * t * 2);
    final flash = raw > 0 ? math.pow(raw, 16).toDouble() : 0.0;
    if (flash < 0.02) return;

    final bolt = Path()
      ..moveTo(size.width * 0.54, size.height * 0.40)
      ..lineTo(size.width * 0.44, size.height * 0.60)
      ..lineTo(size.width * 0.52, size.height * 0.60)
      ..lineTo(size.width * 0.42, size.height * 0.82)
      ..lineTo(size.width * 0.58, size.height * 0.56)
      ..lineTo(size.width * 0.50, size.height * 0.56)
      ..close();

    final boltPaint = Paint()
      ..color = _boltColor.withValues(alpha: flash.clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawPath(bolt, boltPaint);
  }

  @override
  bool shouldRepaint(covariant _WeatherPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.category != category;
  }
}
