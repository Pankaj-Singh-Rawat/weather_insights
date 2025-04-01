import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather_insights/services/weather_service.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  runApp(const WeatherInsightsApp());
}

class WeatherInsightsApp extends StatelessWidget {
  const WeatherInsightsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather Insights',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  String temperature = 'N/A';
  String cityName = 'Fetching...';
  String weatherCondition = 'Unknown';
  int weatherCode = -1;

  @override
  void initState() {
    super.initState();
    _fetchLocationWeather();
  }

  Future<void> _fetchLocationWeather() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Location permission permanently denied. Enable it from settings.')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      _getCityName(position.latitude, position.longitude);
      _getWeather(position.latitude, position.longitude);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location: $e')),
      );
    }
  }

  Future<void> _fetchWeatherByCity(String city) async {
    try {
      List<Location> locations = await locationFromAddress(city);
      if (locations.isNotEmpty) {
        double lat = locations.first.latitude;
        double lon = locations.first.longitude;
        _getWeather(lat, lon);
        setState(() {
          cityName = city;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('City not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching city coordinates')),
      );
    }
  }

  Future<void> _getCityName(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        setState(() {
          cityName = placemarks.first.locality ?? 'Unknown City';
        });
      }
    } catch (e) {
      setState(() {
        cityName = 'Unknown City';
      });
    }
  }

  Future<void> _getWeather(double lat, double lon) async {
    try {
      final data = await WeatherService.fetchWeatherByCoords(lat, lon);
      setState(() {
        temperature = '${data['current_weather']['temperature']}°C';
        weatherCode = data['current_weather']['weathercode'];
        weatherCondition = _getWeatherCondition(weatherCode);
      });
    } catch (e) {
      setState(() {
        temperature = 'Error';
        weatherCondition = 'Unknown';
        weatherCode = -1;
      });
    }
  }

  String _getWeatherCondition(int code) {
    switch (code) {
      case 0:
        return 'Sunny';
      case 1:
      case 2:
      case 3:
        return 'Cloudy';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Showers';
      case 61:
      case 63:
      case 65:
        return 'Rainy';
      case 80:
      case 81:
      case 82:
        return 'Showers';
      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/logo.png',
                height: 40, // Adjust size as needed
                width:
                    40, // Ensure width and height are the same for a perfect circle
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Weather Insights',
              style: TextStyle(color: Colors.amber),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _controller,
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _fetchWeatherByCity(value);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Enter city name',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              Text('City: $cityName',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text('Temperature: $temperature',
                  style: const TextStyle(fontSize: 24, color: Colors.white)),
              Text('Condition: $weatherCondition',
                  style: const TextStyle(fontSize: 20, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}