import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/weather_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/weather_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/page_transitions.dart';
import '../../utils/districts.dart';
import '../../widgets/district_alert_card.dart';
import '../../widgets/error_retry_view.dart';
import 'weather_detail_screen.dart';
import 'weather_detail_view.dart';

class WeatherDashboardScreen extends StatefulWidget {
  const WeatherDashboardScreen({super.key});

  @override
  State<WeatherDashboardScreen> createState() => _WeatherDashboardScreenState();
}

class _WeatherDashboardScreenState extends State<WeatherDashboardScreen> {
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;

    final auth = context.read<AuthProvider>();
    final weatherProvider = context.read<WeatherProvider>();
    final isPresident = auth.currentUser?.isPresident ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isPresident) {
        weatherProvider.loadStateOverview();
      } else {
        weatherProvider.loadFromDeviceLocation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isPresident = auth.currentUser?.isPresident ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isPresident ? 'State Command Center' : 'WeBAlert'),
        actions: [
          if (isPresident)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: Icon(Icons.workspace_premium_rounded, color: AppColors.presidentGold, size: 20),
              ),
            ),
        ],
      ),
      body: isPresident ? const _PresidentOverviewBody() : const _CitizenWeatherBody(),
    );
  }
}

// ---------------------------------------------------------------------------
// Citizen: GPS-based Google-Weather-style dashboard.
// ---------------------------------------------------------------------------

class _CitizenWeatherBody extends StatelessWidget {
  const _CitizenWeatherBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeatherProvider>();
    final weather = provider.weather;

    Widget child;
    String stateKey;

    if (provider.state == WeatherLoadState.loading && weather == null) {
      child = const _LoadingBody();
      stateKey = 'loading';
    } else if (provider.state == WeatherLoadState.error && weather == null) {
      final isPermission = (provider.errorMessage ?? '').toLowerCase().contains('permission');
      child = ErrorRetryView(
        icon: isPermission ? Icons.location_off_rounded : Icons.cloud_off_rounded,
        message: provider.errorMessage ?? 'Could not load weather. Pull down to retry.',
        onRetry: () => provider.loadFromDeviceLocation(),
      );
      stateKey = 'error';
    } else if (weather == null) {
      child = const _LoadingBody();
      stateKey = 'loading';
    } else {
      child = WeatherDetailView(
        weather: weather,
        locationLabel: provider.activeLocationLabel ?? weather.locationName ?? 'Your Location',
        subLabel: 'Live GPS location',
        usingCache: provider.usingCache,
        locationDisabled: provider.locationDisabled,
        cacheMessage: provider.errorMessage,
        onRefresh: () => provider.loadFromDeviceLocation(),
      );
      stateKey = 'data';
    }

    // A quick cross-fade between loading / error / data states feels far
    // smoother than the previous instant swap.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(key: ValueKey(stateKey), child: child),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Fetching live weather…',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          SizedBox(height: 6),
          Text(
            'First request may take a moment while the server wakes up.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// President: all-district state overview grid.
// ---------------------------------------------------------------------------

class _PresidentOverviewBody extends StatelessWidget {
  const _PresidentOverviewBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeatherProvider>();

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      onRefresh: () => provider.loadStateOverview(forceRefresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Live status across all 14 districts',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
              if (provider.loadingOverview)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.presidentGold),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _SeverityLegend(districtWeather: provider.districtWeather),
          const SizedBox(height: 16),
          if (provider.districtWeather.isEmpty && provider.loadingOverview)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(child: CircularProgressIndicator(color: AppColors.presidentGold)),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: kKeralaDistricts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) {
                final d = kKeralaDistricts[index];
                final w = provider.districtWeather[d.key];
                return DistrictAlertCard(
                  label: d.label,
                  weather: w,
                  onTap: () => Navigator.of(context).push(
                    fadeScaleRoute(WeatherDetailScreen(districtKey: d.key)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SeverityLegend extends StatelessWidget {
  final Map<String, WeatherResponse> districtWeather;
  const _SeverityLegend({required this.districtWeather});

  @override
  Widget build(BuildContext context) {
    int countLevel(String level) {
      return districtWeather.values.where((w) => w.alertLevel.toLowerCase() == level).length;
    }

    Widget chip(String level, String label) {
      final count = countLevel(level);
      final color = AppColors.alertColor(level);
      return Expanded(
        child: Column(
          children: [
            Text('$count', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          chip('green', 'Clear'),
          chip('yellow', 'Watch'),
          chip('orange', 'Warning'),
          chip('red', 'Severe'),
        ],
      ),
    );
  }
}
