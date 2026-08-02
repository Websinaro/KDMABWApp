import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/weather_models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/local_cache.dart';
import '../../theme/app_colors.dart';
import '../../utils/page_transitions.dart';
import '../../utils/districts.dart';
import '../../widgets/district_alert_card.dart';
import 'weather_detail_screen.dart';

class DistrictsScreen extends StatefulWidget {
  const DistrictsScreen({super.key});

  @override
  State<DistrictsScreen> createState() => _DistrictsScreenState();
}

class _DistrictsScreenState extends State<DistrictsScreen> {
  final Map<String, WeatherResponse> _weatherByDistrict = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);

    // Show cached values immediately.
    final cached = await LocalCache.instance.readAllDistrictWeather(
      kKeralaDistricts.map((d) => d.key).toList(),
    );
    if (mounted) setState(() => _weatherByDistrict..addAll(cached));

    final api = ApiService.instance;
    await Future.wait(kKeralaDistricts.map((d) async {
      try {
        final w = await api.fetchWeather(lat: d.lat, lon: d.lon);
        _weatherByDistrict[d.key] = w;
        await LocalCache.instance.saveWeather(d.key, w);
      } catch (_) {
        // keep cached value if present
      }
    }));

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final myDistrict = auth.currentUser?.district;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kerala Districts'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadAll,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceElevated,
        onRefresh: _loadAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (_loading && _weatherByDistrict.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
                  return DistrictAlertCard(
                    label: d.label,
                    weather: _weatherByDistrict[d.key],
                    isHome: d.key == myDistrict,
                    onTap: () => Navigator.of(context).push(
                      fadeScaleRoute(WeatherDetailScreen(districtKey: d.key)),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
