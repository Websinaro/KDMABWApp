import 'package:flutter/material.dart';

import '../../services/local_cache.dart';
import '../../services/location_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/page_transitions.dart';
import '../../widgets/primary_button.dart';
import '../auth/welcome_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _requesting = false;
  bool _locationGranted = false;

  Future<void> _requestLocation() async {
    setState(() => _requesting = true);
    try {
      await LocationService.instance.getCurrentPosition();
      setState(() => _locationGranted = true);
    } catch (_) {
      setState(() => _locationGranted = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location access is needed for local weather alerts. You can enable it later from Settings.')),
        );
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  Future<void> _continue() async {
    await LocalCache.instance.setOnboardingDone();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      fadeScaleRoute(const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text('Before we begin', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                'WeBAlert needs a couple of permissions to keep you informed during weather events across Kerala.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14.5, height: 1.4),
              ),
              const SizedBox(height: 32),
              _PermissionTile(
                icon: Icons.my_location_rounded,
                title: 'Location Access',
                description: 'Used to fetch live weather and disaster alerts for exactly where you are.',
                granted: _locationGranted,
                trailing: _locationGranted
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.alertGreen)
                    : TextButton(
                        onPressed: _requesting ? null : _requestLocation,
                        child: _requesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              )
                            : const Text('Allow'),
                      ),
              ),
              const SizedBox(height: 14),
              const _PermissionTile(
                icon: Icons.wifi_rounded,
                title: 'Internet Access',
                description: 'Required to load live weather data and sync your account. Granted automatically.',
                granted: true,
                trailing: Icon(Icons.check_circle_rounded, color: AppColors.alertGreen),
              ),
              const Spacer(),
              const Text(
                'You can change these anytime from your phone\'s Settings.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              PrimaryButton(label: 'Continue', onPressed: _continue),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool granted;
  final Widget trailing;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.granted,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}
