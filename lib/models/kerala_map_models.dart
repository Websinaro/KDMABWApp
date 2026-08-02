class DistrictMapPoint {
  final String district;
  final double latitude;
  final double longitude;
  final double temperature;
  final double humidity;
  final double rainProbability;
  final int weatherCode;
  final String weatherLabel;
  final double windSpeed;
  final double windDirection;
  final double windGusts;
  final String alertLevel;

  DistrictMapPoint({
    required this.district,
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.humidity,
    required this.rainProbability,
    required this.weatherCode,
    required this.weatherLabel,
    required this.windSpeed,
    required this.windDirection,
    required this.windGusts,
    required this.alertLevel,
  });

  factory DistrictMapPoint.fromJson(Map<String, dynamic> j) {
    double n(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
    return DistrictMapPoint(
      district: (j['district'] ?? '').toString(),
      latitude: n(j['latitude']),
      longitude: n(j['longitude']),
      temperature: n(j['temperature']),
      humidity: n(j['humidity']),
      rainProbability: n(j['rain_probability']),
      weatherCode: (j['weather_code'] as num?)?.toInt() ?? 0,
      weatherLabel: (j['weather_label'] ?? '').toString(),
      windSpeed: n(j['wind_speed']),
      windDirection: n(j['wind_direction']),
      windGusts: n(j['wind_gusts']),
      alertLevel: (j['alert_level'] ?? 'green').toString(),
    );
  }
}

class KeralaMapResponse {
  final List<DistrictMapPoint> districts;
  KeralaMapResponse({required this.districts});

  factory KeralaMapResponse.fromJson(Map<String, dynamic> j) {
    final list = (j['districts'] as List<dynamic>? ?? [])
        .map((e) => DistrictMapPoint.fromJson(e as Map<String, dynamic>))
        .toList();
    return KeralaMapResponse(districts: list);
  }
}