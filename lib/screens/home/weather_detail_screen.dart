import 'package:flutter/material.dart';

import '../../models/weather_models.dart';
import '../../providers/weather_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/districts.dart';
import '../../widgets/error_retry_view.dart';
import 'weather_detail_view.dart';

class WeatherDetailScreen extends StatefulWidget {
  final String districtKey;
  const WeatherDetailScreen({super.key, required this.districtKey});

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  final WeatherProvider _provider = WeatherProvider();

  @override
  void initState() {
    super.initState();
    _provider.addListener(_onChange);
    _provider.loadForDistrict(widget.districtKey);
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _provider.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = districtLabel(widget.districtKey);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(label)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final weather = _provider.weather;

    if (_provider.state == WeatherLoadState.loading && weather == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_provider.state == WeatherLoadState.error && weather == null) {
      return ErrorRetryView(
        message: _provider.errorMessage ?? 'Could not load weather.',
        onRetry: () => _provider.loadForDistrict(widget.districtKey),
      );
    }

    final WeatherResponse w = weather!;
    return WeatherDetailView(
      weather: w,
      locationLabel: w.locationName ?? districtLabel(widget.districtKey),
      usingCache: _provider.usingCache,
      onRefresh: () => _provider.loadForDistrict(widget.districtKey),
    );
  }
}

