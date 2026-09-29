import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherSnapshot {
  const WeatherSnapshot({required this.temperature, required this.weatherCode});

  final double temperature;
  final int weatherCode;

  bool get isRainy => weatherCode >= 51 && weatherCode <= 82;
  bool get isCold => temperature < 12;

  String get label {
    if (isRainy) return 'Ploaie';
    if (weatherCode <= 1) return 'Senin';
    if (weatherCode <= 3) return 'Înnorat';
    return 'Vreme schimbătoare';
  }
}

/// Obţine vremea curentă doar după ce utilizatorul cere explicit activarea.
class WeatherService {
  static Future<WeatherSnapshot> loadCurrentWeather() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Serviciile de locație sunt oprite.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Permisiunea pentru locație nu a fost acordată.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 12),
      ),
    );
    final response = await http.get(
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'current': 'temperature_2m,weather_code',
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Vremea nu poate fi încărcată acum.');
    }

    final current =
        jsonDecode(response.body)['current'] as Map<String, dynamic>;
    return WeatherSnapshot(
      temperature: (current['temperature_2m'] as num).toDouble(),
      weatherCode: current['weather_code'] as int,
    );
  }
}
