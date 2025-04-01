import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  static Future<Map<String, dynamic>> fetchWeatherByCoords(double lat, double lon) async {
    final Uri url = Uri.parse(
      '$_baseUrl?latitude=$lat&longitude=$lon&current_weather=true&hourly=temperature_2m'
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Error fetching weather: $e');
    }
  }
}