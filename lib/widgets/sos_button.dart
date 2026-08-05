import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/sos_provider.dart';
import '../theme/app_colors.dart';

class SosButton extends StatefulWidget {
  final VoidCallback onPressed;

  const SosButton({super.key, required this.onPressed});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _handleTap(bool isSending) {
    if (isSending) return;
    // Sharp, distinct haptic on every tap - both as an emergency-app tactile
    // cue and as immediate confirmation the press registered, since a
    // panicked tap needs faster feedback than waiting for a sheet to render.
    HapticFeedback.heavyImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final sos = context.watch<SosProvider>();
    final isActive = sos.status == SosStatus.active;
    final isSending = sos.status == SosStatus.sending;
    final color = isActive ? AppColors.alertDarkRed : AppColors.alertRed;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => _handleTap(isSending),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final ringScale = isActive ? 1.0 + (_pulse.value * 0.55) : 1.0;
          final ringOpacity = isActive ? (1.0 - _pulse.value) * 0.55 : 0.0;

          return SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isActive)
                  Transform.scale(
                    scale: ringScale,
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.alertDarkRed.withValues(alpha: ringOpacity),
                      ),
                    ),
                  ),
                child!,
              ],
            ),
          );
        },
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color, Color.lerp(color, Colors.black, 0.25)!],
                center: const Alignment(-0.3, -0.3),
                radius: 1.1,
              ),
              border: Border.all(color: AppColors.background, width: 4),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.55),
                  blurRadius: isActive ? 26 : 18,
                  spreadRadius: isActive ? 2 : 1,
                ),
              ],
            ),
            child: Center(
              child: isSending
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? Icons.sensors_rounded : Icons.emergency_share_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          isActive ? 'ACTIVE' : 'SOS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
