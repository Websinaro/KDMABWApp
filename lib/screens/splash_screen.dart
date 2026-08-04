import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/safety_provider.dart';
import '../services/api_service.dart';
import '../services/local_cache.dart';
import '../services/version_service.dart';
import '../theme/app_colors.dart';
import '../utils/page_transitions.dart';
import 'auth/welcome_screen.dart';
import 'home/home_shell.dart';
import 'onboarding/permission_screen.dart';
import 'onboarding/safety_setup_screen.dart';
import '../providers/sos_provider.dart';
import 'update_required_screen.dart';

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
    final minDelay = Future.delayed(const Duration(milliseconds: 400));
    final auth = context.read<AuthProvider>();
    final onboardingDone = await LocalCache.instance.isOnboardingDone();

    // Version gate check runs alongside the rest of bootstrap so it doesn't
    // add extra wait time on top of the session restore.
    final versionCheck = _checkForcedUpdate();

    // restoreSession() only needs to read the locally-stored token and
    // decide auth status - it should not be doing anything that depends on
    // a live network round trip to be "restored". Wait for it (it's local
    // and fast) but nothing beyond it.
    await Future.wait([auth.restoreSession(), minDelay]);
    final mustUpdate = await versionCheck;

    if (!mounted || _navigated) return;

    if (mustUpdate != null) {
      _navigated = true;
      Navigator.of(context).pushReplacement(fadeScaleRoute(UpdateRequiredScreen(message: mustUpdate)));
      return;
    }

    if (!onboardingDone) {
      _navigated = true;
      Navigator.of(context).pushReplacement(fadeScaleRoute(const PermissionScreen()));
      return;
    }

    if (auth.status != AuthStatus.authenticated) {
      _navigated = true;
      Navigator.of(context).pushReplacement(fadeScaleRoute(const WelcomeScreen()));
      return;
    }

    // Whether to route to "set up safety contacts" vs the home shell
    // genuinely depends on a network answer (there's no local cache of
    // contacts). Previously this ran as an *extra*, fully sequential
    // network round trip after auth had already finished restoring - two
    // network calls back-to-back before the user saw anything. It's
    // started here in parallel with auth/version instead, and capped with
    // a short timeout: if the backend is slow to answer, we don't hold an
    // emergency app's splash screen hostage waiting for it - fall through
    // to the home shell (where the SOS button and everything else works
    // regardless) and let the contacts refresh keep running in the
    // background so the setup prompt still appears next launch if needed.
    final safety = context.read<SafetyProvider>();
    final sosProvider = context.read<SosProvider>();
    bool safetyCheckFinished = false;
    final Future<void> safetyRefreshFuture = safety.refresh().then((_) {
      safetyCheckFinished = true;
    });
    unawaited(sosProvider.restoreActiveSos());

    await safetyRefreshFuture.timeout(
      const Duration(seconds: 6),
      onTimeout: () {},
    );

    if (!mounted || _navigated) return;
    _navigated = true;

    if (safetyCheckFinished && safety.loaded && !safety.hasContacts) {
      Navigator.of(context).pushReplacement(fadeScaleRoute(const SafetySetupScreen()));
    } else {
      Navigator.of(context).pushReplacement(fadeScaleRoute(const HomeShell()));
    }
  }

  /// Returns the force-update message if this build is below the server's
  /// minimum supported version, otherwise null. Never throws - any failure
  /// (offline, server waking up, malformed response) fails open so a real
  /// user is never stuck on a broken screen because of a network hiccup.
  Future<String?> _checkForcedUpdate() async {
    try {
      final info = await ApiService.instance.checkVersion();
      final myVersion = (await PackageInfo.fromPlatform()).version;
      final minSupported = info['min_supported_version']?.toString();

      if (minSupported != null && VersionService.instance.isOlderThan(myVersion, minSupported)) {
        return info['force_update_message']?.toString() ??
            'This version of WeBAlert is no longer supported. Please update to continue.';
      }
    } catch (_) {
      // fail open
    }
    return null;
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