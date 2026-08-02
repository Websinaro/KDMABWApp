import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AlertPill extends StatelessWidget {
  final String level;
  final bool compact;

  const AlertPill({super.key, required this.level, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.alertColor(level);
    final label = AppColors.alertLabel(level);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 4 : 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 8,
            height: compact ? 6 : 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: compact ? 5 : 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width banner shown at the top of the weather dashboard when the
/// alert level is above "green", explaining what it means in plain terms.
class AlertBanner extends StatelessWidget {
  final String level;

  const AlertBanner({super.key, required this.level});

  String _description(String level) {
    switch (level.toLowerCase()) {
      case 'dark_red':
        return 'Extreme conditions expected. This is a severe, potentially life-threatening situation — follow official Kerala Disaster Management advisories immediately and avoid all non-essential travel.';
      case 'light_red':
      case 'red': // backward-compat for any old 4-tier data still cached
        return 'Severe conditions expected. Follow official Kerala Disaster Management advisories and avoid unnecessary travel.';
      case 'orange':
        return 'Heightened risk of heavy rain / strong winds. Stay alert and keep emergency contacts handy.';
      case 'yellow':
        return 'Weather may turn unfavourable. Keep an eye on updates through the day.';
      default:
        return 'Conditions are normal in this area right now.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (level.toLowerCase() == 'green') return const SizedBox.shrink();
    final color = AppColors.alertColor(level);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppColors.alertLabel(level),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  _description(level),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
