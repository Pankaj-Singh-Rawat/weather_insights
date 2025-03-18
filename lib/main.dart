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
  List<Map<String, dynamic>> hourlyTemps = [];
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
          const SnackBar(content: Text('Location permission permanently denied. Enable it from settings.')),
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

        List<dynamic> tempList = data['hourly']['temperature_2m'];
        List<dynamic> timeList = data['hourly']['time'];

        hourlyTemps = List.generate(tempList.length, (index) {
          return {
            'time': DateTime.parse(timeList[index]),
            'temp': tempList[index]
          };
        });
      });
    } catch (e) {
      setState(() {
        temperature = 'Error';
        weatherCode = -1;
      });
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

  Widget getWeatherIcon(int code) {
    switch (code) {
      case 0:
        return const BoxedIcon(WeatherIcons.day_sunny, size: 50);
      case 1:
      case 2:
      case 3:
        return const BoxedIcon(WeatherIcons.cloudy, size: 50);
      case 45:
      case 48:
        return const BoxedIcon(WeatherIcons.fog, size: 50);
      case 51:
      case 53:
      case 55:
        return const BoxedIcon(WeatherIcons.showers, size: 50);
      case 61:
      case 63:
      case 65:
        return const BoxedIcon(WeatherIcons.rain, size: 50);
      case 80:
      case 81:
      case 82:
        return const BoxedIcon(WeatherIcons.showers, size: 50);
      case 95:
      case 96:
      case 99:
        return const BoxedIcon(WeatherIcons.thunderstorm, size: 50);
      default:
        return const BoxedIcon(WeatherIcons.na, size: 50);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weather Insights')),
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
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  String city = _controller.text;
                  if (city.isNotEmpty) {
                    _fetchWeatherByCity(city);
                  }
                },
                child: const Text('Search'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchLocationWeather,
                child: const Text('Get My Location Weather'),
              ),
              const SizedBox(height: 20),
              Text('City: $cityName', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              Text('Temperature: $temperature', style: const TextStyle(fontSize: 24, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
