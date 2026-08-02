import 'package:flutter/material.dart';

/// Central color palette for WeBAlert.
///
/// The whole app uses a single dark / AMOLED theme (true black background)
/// on purpose: it looks "cool" on modern OLED phones and also measurably
/// saves battery, since black pixels draw ~0 power on OLED panels.
class AppColors {
  AppColors._();

  // Base surfaces
  static const Color background = Color(0xFF000000); // true black - OLED
  static const Color surface = Color(0xFF0A0D12);
  static const Color surfaceElevated = Color(0xFF12161D);
  static const Color card = Color(0xFF151A22);
  static const Color cardBorder = Color(0xFF212832);
  static const Color divider = Color(0xFF1B212B);

  // Brand accents
  static const Color primary = Color(0xFF2FD9EA); // cyan - "weather" feel
  static const Color primaryDim = Color(0xFF12838F);
  static const Color secondary = Color(0xFFFF8A3D); // warm orange accent
  static const Color presidentGold = Color(0xFFE9C46A); // President accent

  // Text
  static const Color textPrimary = Color(0xFFF3F6F8);
  static const Color textSecondary = Color(0xFF98A2AF);
  static const Color textMuted = Color(0xFF5C6572);

 // Semantic disaster alert levels (mirrors backend data/severity.py)
  static const Color alertGreen = Color(0xFF34D399);
  static const Color alertYellow = Color(0xFFF4CD46);
  static const Color alertOrange = Color(0xFFFF9F45);
  static const Color alertLightRed = Color(0xFFF1554C);
  static const Color alertDarkRed = Color(0xFF8B1A1A);
  static const Color alertRed = alertLightRed;

  static Color alertColor(String level) {
    switch (level.toLowerCase()) {
      case 'dark_red':
        return alertDarkRed;
      case 'light_red':
      case 'red': // backward-compat for old 4-tier responses
        return alertLightRed;
      case 'orange':
        return alertOrange;
      case 'yellow':
        return alertYellow;
      case 'green':
      default:
        return alertGreen;
    }
  }

  static String alertLabel(String level) {
    switch (level.toLowerCase()) {
      case 'dark_red':
        return 'Very High Risk';
      case 'light_red':
      case 'red':
        return 'High Risk';
      case 'orange':
        return 'Risk';
      case 'yellow':
        return 'Low Risk';
      case 'green':
      default:
        return 'Safe';
    }
  }
  
  /// A subtle gradient behind the current-conditions header, derived from
  /// the weather condition + whether it's day or night. Kept dark/desaturated
  /// on purpose so it stays battery-friendly and consistent with the
  /// AMOLED theme rather than turning into a bright "postcard" gradient.
  static List<Color> weatherGradient({required String icon, required bool isDay}) {
    if (!isDay) {
      return const [Color(0xFF04070C), Color(0xFF0B1420), Color(0xFF000000)];
    }
    switch (icon) {
      case 'sunny':
      case 'mostly_sunny':
        return const [Color(0xFF0E2A33), Color(0xFF0A1A22), Color(0xFF000000)];
      case 'partly_cloudy':
      case 'cloudy':
      case 'fog':
        return const [Color(0xFF10161F), Color(0xFF0B0F16), Color(0xFF000000)];
      case 'drizzle':
      case 'rain':
      case 'rain_showers':
      case 'heavy_rain':
        return const [Color(0xFF0A1A2C), Color(0xFF081220), Color(0xFF000000)];
      case 'thunderstorm':
      case 'thunderstorm_hail':
        return const [Color(0xFF17101F), Color(0xFF0C0A14), Color(0xFF000000)];
      case 'snow':
        return const [Color(0xFF101A22), Color(0xFF0A121A), Color(0xFF000000)];
      default:
        return const [Color(0xFF0E1319), Color(0xFF0A0D12), Color(0xFF000000)];
    }
  }
}
