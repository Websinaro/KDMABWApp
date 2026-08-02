/// Models mirroring the FastAPI backend's `scheme/weather_scheme.py`
/// (`GET /weather?lat=&lon=`).

double _numToDouble(dynamic v, [double fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

double? _numToDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int _numToInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

List<double> _doubleList(dynamic v) {
  if (v is! List) return const [];
  return v.map((e) => _numToDouble(e)).toList();
}

List<double?> _nullableDoubleList(dynamic v) {
  if (v is! List) return const [];
  return v.map((e) => _numToDoubleOrNull(e)).toList();
}

List<int> _intList(dynamic v) {
  if (v is! List) return const [];
  return v.map((e) => _numToInt(e)).toList();
}

List<String> _stringList(dynamic v) {
  if (v is! List) return const [];
  return v.map((e) => e.toString()).toList();
}

class CurrentWeather {
  final double temperature;
  final double feelsLike;
  final double humidity;
  final double precipitation;
  final double rain;
  final int weatherCode;
  final double cloudCover;
  final double pressure;
  final double windSpeed;
  final double windDirection;
  final double windGusts;
  final double? uvIndex;
  final int isDay;
  final String weatherLabel;
  final String weatherIcon;

  const CurrentWeather({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.precipitation,
    required this.rain,
    required this.weatherCode,
    required this.cloudCover,
    required this.pressure,
    required this.windSpeed,
    required this.windDirection,
    required this.windGusts,
    required this.uvIndex,
    required this.isDay,
    required this.weatherLabel,
    required this.weatherIcon,
  });

  bool get isDaytime => isDay == 1;

  factory CurrentWeather.fromJson(Map<String, dynamic> j) => CurrentWeather(
        temperature: _numToDouble(j['temperature']),
        feelsLike: _numToDouble(j['feels_like']),
        humidity: _numToDouble(j['humidity']),
        precipitation: _numToDouble(j['precipitation']),
        rain: _numToDouble(j['rain']),
        weatherCode: _numToInt(j['weather_code']),
        cloudCover: _numToDouble(j['cloud_cover']),
        pressure: _numToDouble(j['pressure']),
        windSpeed: _numToDouble(j['wind_speed']),
        windDirection: _numToDouble(j['wind_direction']),
        windGusts: _numToDouble(j['wind_gusts']),
        uvIndex: _numToDoubleOrNull(j['uv_index']),
        isDay: _numToInt(j['is_day'], 1),
        weatherLabel: (j['weather_label'] ?? 'Unknown').toString(),
        weatherIcon: (j['weather_icon'] ?? 'unknown').toString(),
      );
}

class AirQuality {
  final double? aqi;
  final double? pm25;
  final double? pm10;
  final double? ozone;
  final double? carbonMonoxide;

  const AirQuality({this.aqi, this.pm25, this.pm10, this.ozone, this.carbonMonoxide});

  factory AirQuality.fromJson(Map<String, dynamic> j) => AirQuality(
        aqi: _numToDoubleOrNull(j['aqi']),
        pm25: _numToDoubleOrNull(j['pm2_5']),
        pm10: _numToDoubleOrNull(j['pm10']),
        ozone: _numToDoubleOrNull(j['ozone']),
        carbonMonoxide: _numToDoubleOrNull(j['carbon_monoxide']),
      );
}

class HourlyForecast {
  final List<String> time;
  final List<double> temperature;
  final List<double> feelsLike;
  final List<double> humidity;
  final List<double?> rainProbability;
  final List<double> precipitation;
  final List<double> windSpeed;
  final List<double> windGusts;
  final List<double?> uvIndex;
  final List<double> dewPoint;
  final List<double?> visibility;
  final List<int> weatherCode;

  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.rainProbability,
    required this.precipitation,
    required this.windSpeed,
    required this.windGusts,
    required this.uvIndex,
    required this.dewPoint,
    required this.visibility,
    required this.weatherCode,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> j) => HourlyForecast(
        time: _stringList(j['time']),
        temperature: _doubleList(j['temperature']),
        feelsLike: _doubleList(j['feels_like']),
        humidity: _doubleList(j['humidity']),
        rainProbability: _nullableDoubleList(j['rain_probability']),
        precipitation: _doubleList(j['precipitation']),
        windSpeed: _doubleList(j['wind_speed']),
        windGusts: _doubleList(j['wind_gusts']),
        uvIndex: _nullableDoubleList(j['uv_index']),
        dewPoint: _doubleList(j['dew_point']),
        visibility: _nullableDoubleList(j['visibility']),
        weatherCode: _intList(j['weather_code']),
      );

  int get length => time.length;
}

class DailyForecast {
  final List<String> date;
  final List<double> tempMax;
  final List<double> tempMin;
  final List<double> feelsLikeMax;
  final List<double> feelsLikeMin;
  final List<String> sunrise;
  final List<String> sunset;
  final List<double?> uvIndexMax;
  final List<double?> rainProbabilityMax;
  final List<double> precipitationSum;
  final List<double> windSpeedMax;
  final List<double> windGustsMax;
  final List<int> weatherCode;

  const DailyForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.feelsLikeMax,
    required this.feelsLikeMin,
    required this.sunrise,
    required this.sunset,
    required this.uvIndexMax,
    required this.rainProbabilityMax,
    required this.precipitationSum,
    required this.windSpeedMax,
    required this.windGustsMax,
    required this.weatherCode,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> j) => DailyForecast(
        date: _stringList(j['date']),
        tempMax: _doubleList(j['temp_max']),
        tempMin: _doubleList(j['temp_min']),
        feelsLikeMax: _doubleList(j['feels_like_max']),
        feelsLikeMin: _doubleList(j['feels_like_min']),
        sunrise: _stringList(j['sunrise']),
        sunset: _stringList(j['sunset']),
        uvIndexMax: _nullableDoubleList(j['uv_index_max']),
        rainProbabilityMax: _nullableDoubleList(j['rain_probability_max']),
        precipitationSum: _doubleList(j['precipitation_sum']),
        windSpeedMax: _doubleList(j['wind_speed_max']),
        windGustsMax: _doubleList(j['wind_gusts_max']),
        weatherCode: _intList(j['weather_code']),
      );

  int get length => date.length;
}

class WeatherResponse {
  final String? locationName;
  final double latitude;
  final double longitude;
  final String alertLevel;
  final CurrentWeather current;
  final AirQuality? airQuality;
  final HourlyForecast hourly;
  final DailyForecast daily;

  /// Not sent by the backend - stamped locally when the response is cached,
  /// so the UI can show "Updated 4 min ago" / offline banners.
  final DateTime fetchedAt;

  const WeatherResponse({
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.alertLevel,
    required this.current,
    required this.airQuality,
    required this.hourly,
    required this.daily,
    required this.fetchedAt,
  });

  factory WeatherResponse.fromJson(Map<String, dynamic> j) => WeatherResponse(
        locationName: j['location_name']?.toString(),
        latitude: _numToDouble(j['latitude']),
        longitude: _numToDouble(j['longitude']),
        alertLevel: (j['alert_level'] ?? 'green').toString(),
        current: CurrentWeather.fromJson(Map<String, dynamic>.from(j['current'] ?? {})),
        airQuality: j['air_quality'] == null
            ? null
            : AirQuality.fromJson(Map<String, dynamic>.from(j['air_quality'])),
        hourly: HourlyForecast.fromJson(Map<String, dynamic>.from(j['hourly'] ?? {})),
        daily: DailyForecast.fromJson(Map<String, dynamic>.from(j['daily'] ?? {})),
        fetchedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'location_name': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'alert_level': alertLevel,
        'current': {
          'temperature': current.temperature,
          'feels_like': current.feelsLike,
          'humidity': current.humidity,
          'precipitation': current.precipitation,
          'rain': current.rain,
          'weather_code': current.weatherCode,
          'cloud_cover': current.cloudCover,
          'pressure': current.pressure,
          'wind_speed': current.windSpeed,
          'wind_direction': current.windDirection,
          'wind_gusts': current.windGusts,
          'uv_index': current.uvIndex,
          'is_day': current.isDay,
          'weather_label': current.weatherLabel,
          'weather_icon': current.weatherIcon,
        },
        'air_quality': airQuality == null
            ? null
            : {
                'aqi': airQuality!.aqi,
                'pm2_5': airQuality!.pm25,
                'pm10': airQuality!.pm10,
                'ozone': airQuality!.ozone,
                'carbon_monoxide': airQuality!.carbonMonoxide,
              },
        'hourly': {
          'time': hourly.time,
          'temperature': hourly.temperature,
          'feels_like': hourly.feelsLike,
          'humidity': hourly.humidity,
          'rain_probability': hourly.rainProbability,
          'precipitation': hourly.precipitation,
          'wind_speed': hourly.windSpeed,
          'wind_gusts': hourly.windGusts,
          'uv_index': hourly.uvIndex,
          'dew_point': hourly.dewPoint,
          'visibility': hourly.visibility,
          'weather_code': hourly.weatherCode,
        },
        'daily': {
          'date': daily.date,
          'temp_max': daily.tempMax,
          'temp_min': daily.tempMin,
          'feels_like_max': daily.feelsLikeMax,
          'feels_like_min': daily.feelsLikeMin,
          'sunrise': daily.sunrise,
          'sunset': daily.sunset,
          'uv_index_max': daily.uvIndexMax,
          'rain_probability_max': daily.rainProbabilityMax,
          'precipitation_sum': daily.precipitationSum,
          'wind_speed_max': daily.windSpeedMax,
          'wind_gusts_max': daily.windGustsMax,
          'weather_code': daily.weatherCode,
        },
        '_fetched_at': fetchedAt.toIso8601String(),
      };

  factory WeatherResponse.fromCacheJson(Map<String, dynamic> j) {
    final base = WeatherResponse.fromJson(j);
    final cachedAt = j['_fetched_at'] != null ? DateTime.tryParse(j['_fetched_at']) : null;
    if (cachedAt == null) return base;
    return WeatherResponse(
      locationName: base.locationName,
      latitude: base.latitude,
      longitude: base.longitude,
      alertLevel: base.alertLevel,
      current: base.current,
      airQuality: base.airQuality,
      hourly: base.hourly,
      daily: base.daily,
      fetchedAt: cachedAt,
    );
  }
}
