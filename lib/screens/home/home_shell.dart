import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/page_transitions.dart';
import '../auth/welcome_screen.dart';
import '../map/kerala_map_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/safety_contacts_screen.dart';
import 'districts_screen.dart';
import 'sos_sheet.dart';
import 'weather_dashboard_screen.dart';
import '../../widgets/sos_button.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.status == AuthStatus.unauthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              fadeScaleRoute(const WelcomeScreen()),
              (route) => false,
            );
          });
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final isPresident = auth.currentUser?.isPresident ?? false;

        final pages = [
          const WeatherDashboardScreen(),
          const DistrictsScreen(),
          const KeralaMapScreen(),
          const ProfileScreen(),
        ];

        return Scaffold(
          backgroundColor: AppColors.background,
          body: IndexedStack(index: _index, children: pages),
          floatingActionButton: SosButton(onPressed: () => showSosFlow(context)),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomAppBar(
            color: AppColors.surface,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _NavItem(
                      icon: Icons.cloud_outlined,
                      activeIcon: Icons.cloud_rounded,
                      label: isPresident ? 'Command' : 'Weather',
                      isSelected: _index == 0,
                      color: isPresident ? AppColors.presidentGold : AppColors.primary,
                      onTap: () => setState(() => _index = 0),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.map_outlined,
                      activeIcon: Icons.map_rounded,
                      label: 'Districts',
                      isSelected: _index == 1,
                      color: isPresident ? AppColors.presidentGold : AppColors.primary,
                      onTap: () => setState(() => _index = 1),
                    ),
                  ),
                  const SizedBox(width: 64), // gap for the notch/SOS button
                  Expanded(
                    child: _NavItem(
                      icon: Icons.public_outlined,
                      activeIcon: Icons.public_rounded,
                      label: 'Map',
                      isSelected: _index == 2,
                      color: isPresident ? AppColors.presidentGold : AppColors.primary,
                      onTap: () => setState(() => _index = 2),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'Profile',
                      isSelected: _index == 3,
                      color: isPresident ? AppColors.presidentGold : AppColors.primary,
                      onTap: () => setState(() => _index = 3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSelected ? activeIcon : icon, color: isSelected ? color : AppColors.textMuted, size: 24),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isSelected ? color : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}