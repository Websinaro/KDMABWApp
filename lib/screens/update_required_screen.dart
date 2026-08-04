import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';

class UpdateRequiredScreen extends StatelessWidget {
  final String message;

  const UpdateRequiredScreen({super.key, required this.message});

  static const String _playStoreUrl =
      'https://github.com/Websinaro/WebAlert-App/releases/';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // blocks the back button - update is mandatory
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.system_update_rounded, color: AppColors.primary, size: 64),
                const SizedBox(height: 20),
                const Text(
                  'Update Required',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => launchUrl(Uri.parse(_playStoreUrl), mode: LaunchMode.externalApplication),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Update Now', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}