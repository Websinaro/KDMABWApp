import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/safety_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/page_transitions.dart';
import '../../utils/districts.dart';
import '../auth/welcome_screen.dart';
import 'backup_screen.dart';
import '../profile/safety_contacts_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Log out?'),
        content: const Text('You can log back in anytime with your email and password.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out', style: TextStyle(color: AppColors.alertRed)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        context.read<SafetyProvider>().reset();
      }
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          fadeScaleRoute(const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }

  // ...rest of the file unchanged

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isPresident = user?.isPresident ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (auth.isOfflineSession)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud_off_rounded, size: 16, color: AppColors.textMuted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing your saved profile - offline.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          Center(
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isPresident ? AppColors.presidentGold : AppColors.primary).withValues(alpha: 0.15),
                    border: Border.all(color: (isPresident ? AppColors.presidentGold : AppColors.primary).withValues(alpha: 0.5)),
                  ),
                  child: Icon(
                    isPresident ? Icons.workspace_premium_rounded : Icons.person_rounded,
                    size: 40,
                    color: isPresident ? AppColors.presidentGold : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(user?.name ?? '—', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(user?.email ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isPresident ? AppColors.presidentGold : AppColors.primary).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isPresident ? 'PRESIDENT / STATE COORDINATOR' : 'CITIZEN',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: isPresident ? AppColors.presidentGold : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _InfoCard(
            children: [
              _InfoRow(icon: Icons.map_outlined, label: 'District', value: user != null ? districtLabel(user.district) : '—'),
              const Divider(height: 22),
              _InfoRow(icon: Icons.badge_outlined, label: 'Role', value: isPresident ? 'President' : 'Citizen'),
            ],
          ),
          const SizedBox(height: 16),
          _ActionTile(
            icon: Icons.shield_outlined,
            title: 'Safety Circle',
            subtitle: 'People notified with your live location during an SOS',
            onTap: () => Navigator.of(context).push(
              fadeScaleRoute(const SafetyContactsScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.save_alt_rounded,
            title: 'Backup & Restore',
            subtitle: 'Save your data to device storage, on or off the app',
            onTap: () => Navigator.of(context).push(
              fadeScaleRoute(const BackupScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.info_outline_rounded,
            title: 'About WeBAlert',
            subtitle: 'Kerala Disaster Management Authority',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'WeBAlert',
              applicationVersion: '1.0.0',
              applicationIcon: const Icon(Icons.shield_rounded, color: AppColors.primary),
              children: const [
                Text(
                  'Live weather and disaster alerts for every district in Kerala, built for the Kerala Disaster Management Authority.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded, color: AppColors.alertRed, size: 18),
              label: const Text('Log Out', style: TextStyle(color: AppColors.alertRed)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.alertRed)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
