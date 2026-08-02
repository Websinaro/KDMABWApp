import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/local_cache.dart';
import '../theme/app_colors.dart';
import '../utils/page_transitions.dart';
import 'auth/welcome_screen.dart';
import 'home/home_shell.dart';
import 'onboarding/permission_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Entrance: logo pops in with a soft overshoot, text/spinner fade up after.
  late final AnimationController _entrance;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  // Continuous ambient pulse ring behind the logo - purely decorative, kept
  // cheap (a single opacity+scale tween) so it doesn't cost battery.
  late final AnimationController _pulse;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _entrance, curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack)),
    );
    _logoFade = CurvedAnimation(parent: _entrance, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _textFade = CurvedAnimation(parent: _entrance, curve: const Interval(0.35, 1.0, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _entrance, curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic)),
    );

    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

    _entrance.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Short minimum splash time so the app *feels* fast to open while still
    // giving the entrance animation a moment to play out.
    final minDelay = Future.delayed(const Duration(milliseconds: 550));
    final auth = context.read<AuthProvider>();
    final onboardingDone = await LocalCache.instance.isOnboardingDone();
    await Future.wait([auth.restoreSession(), minDelay]);

    if (!mounted || _navigated) return;
    _navigated = true;

    if (!onboardingDone) {
      Navigator.of(context).pushReplacement(fadeScaleRoute(const PermissionScreen()));
      return;
    }

    if (auth.status == AuthStatus.authenticated) {
      Navigator.of(context).pushReplacement(fadeScaleRoute(const HomeShell()));
    } else {
      Navigator.of(context).pushReplacement(fadeScaleRoute(const WelcomeScreen()));
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) {
                    final pulseValue = _pulse.value; // 0..1 loop
                    final ringScale = 1.0 + pulseValue * 0.45;
                    final ringOpacity = (1.0 - pulseValue).clamp(0.0, 1.0) * 0.35;
                    return SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            scale: ringScale,
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: ringOpacity),
                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),
                          child!,
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          blurRadius: 24,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 42),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _textFade,
              child: SlideTransition(
                position: _textSlide,
                child: Column(
                  children: [
                    const Text(
                      'WeBAlert',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Kerala Disaster Management',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 28),
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
