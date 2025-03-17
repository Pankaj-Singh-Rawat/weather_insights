import 'package:flutter/material.dart';
import 'package:weather_insights/services/weather_service.dart';


void main() {
  runApp(const WeatherInsightsApp()); // This must exist
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
  String weatherCondition = 'N/A';

  Future<void> getWeather() async {
    String city = _controller.text;
    if (city.isEmpty) return;

    try {
      final data = await WeatherService.fetchWeather(city);
      setState(() {
        temperature = '${data['main']['temp']}°C';
        weatherCondition = data['weather'][0]['description'];
      });
    } catch (e) {
      setState(() {
        temperature = 'Error';
        weatherCondition = 'Could not fetch data';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weather Insights')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter city name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: getWeather,
              child: const Text('Get Weather'),
            ),
            const SizedBox(height: 20),
            Text('Temperature: $temperature', style: const TextStyle(fontSize: 24)),
            Text('Condition: $weatherCondition', style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
