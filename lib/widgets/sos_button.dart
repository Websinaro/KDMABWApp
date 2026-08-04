import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/sos_provider.dart';
import '../theme/app_colors.dart';

/// The emergency SOS trigger.
///
/// Fixes vs the previous version:
/// - The pulse animation used to run continuously (`..repeat()` in
///   initState) even while idle, forcing this whole subtree to rebuild
///   every frame all the time it was on screen for no visual benefit -
///   pure wasted CPU/battery contributing to overall app jank. It now
///   only animates while a real SOS is active.
/// - No tactile/visual confirmation on press - a button this critical
///   needs unmistakable feedback that the tap registered. Added haptic
///   feedback and a press-down scale so it reads as solid and responsive
///   rather than "did that even work?".
/// - Wrapped in RepaintBoundary so its (now occasional) animation doesn't
///   force sibling widgets in the same frame to repaint.
/// - Proper Semantics label for screen readers - non-negotiable for an
///   accessibility-critical control like this.
class SosButton extends StatefulWidget {
  final VoidCallback onPressed;

  const SosButton({super.key, required this.onPressed});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _pressed = false;
  bool _wasActive = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  }

  void _syncPulse(bool isActive) {
    if (isActive == _wasActive) return;
    _wasActive = isActive;
    if (isActive) {
      _pulse.repeat();
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sos = context.watch<SosProvider>();
    final isActive = sos.status == SosStatus.active;
    final isSending = sos.status == SosStatus.sending;
    _syncPulse(isActive);

    return Semantics(
      button: true,
      label: isActive
          ? 'Emergency SOS active. Tap to view or resolve.'
          : 'Send emergency SOS. Alerts your safety contacts with your location.',
      child: RepaintBoundary(
        child: GestureDetector(
          onTapDown: isSending ? null : (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: isSending
              ? null
              : () {
                  HapticFeedback.heavyImpact();
                  widget.onPressed();
                },
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final ringScale = isActive ? 1.0 + (_pulse.value * 0.5) : 1.0;
                final ringOpacity = isActive ? (1.0 - _pulse.value) * 0.5 : 0.0;

                return SizedBox(
                  width: 84,
                  height: 84,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isActive)
                        Transform.scale(
                          scale: ringScale,
                          child: Container(
                            width: 68,
                            height: 68,
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppColors.alertDarkRed : AppColors.alertRed,
                  border: Border.all(color: AppColors.background, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: (isActive ? AppColors.alertDarkRed : AppColors.alertRed).withValues(alpha: 0.5),
                      blurRadius: _pressed ? 8 : 18,
                      spreadRadius: _pressed ? 0 : 1,
                    ),
                  ],
                ),
                child: Center(
                  child: isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : Text(
                          isActive ? 'ACTIVE' : 'SOS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
