import 'package:http/http.dart' as http;
import 'dart:convert';

/// Weather Service - Fetches weather data for outfit recommendations
class WeatherService {
  // Using OpenWeatherMap API (free tier available)
  // You can also use other services like WeatherAPI, AccuWeather, etc.
  static const String _apiKey = '16b972dc691795c663e49852ef1c835e'; // TODO: Move to config
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  /// Get current weather for a location
  Future<WeatherData?> getCurrentWeather({
    double? latitude,
    double? longitude,
    String? cityName,
  }) async {
    try {
      String url;
      if (latitude != null && longitude != null) {
        url =
            '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric';
      } else if (cityName != null) {
        url = '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric';
      } else {
        // Default to a common location or use device location
        return _getDefaultWeather();
      }

      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 5),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return WeatherData.fromJson(data);
      }

      // Fallback to default weather
      return _getDefaultWeather();
    } catch (e) {
      print('Weather API error: $e');
      // Return default weather on error
      return _getDefaultWeather();
    }
  }

  /// Get default weather (fallback)
  WeatherData? _getDefaultWeather() {
    // Return moderate weather as default
    return WeatherData(
      temperature: 20.0,
      condition: 'clear',
      humidity: 60.0,
      windSpeed: 10.0,
      description: 'Clear sky',
    );
  }

  /// Get weather forecast for next few days
  Future<List<WeatherData>> getForecast({
    double? latitude,
    double? longitude,
    String? cityName,
    int days = 5,
  }) async {
    try {
      String url;
      if (latitude != null && longitude != null) {
        url =
            '$_baseUrl/forecast?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric&cnt=${days * 8}';
      } else if (cityName != null) {
        url =
            '$_baseUrl/forecast?q=$cityName&appid=$_apiKey&units=metric&cnt=${days * 8}';
      } else {
        return List.generate(days, (_) => _getDefaultWeather()!);
      }

      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 5),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['list'] as List<dynamic>;
        
        // Group by day and take first forecast of each day
        final Map<String, dynamic> dailyForecasts = {};
        for (var item in list) {
          final date = DateTime.parse(item['dt_txt'] as String);
          final dateKey = '${date.year}-${date.month}-${date.day}';
          if (!dailyForecasts.containsKey(dateKey)) {
            dailyForecasts[dateKey] = item;
          }
        }

        return dailyForecasts.values
            .map((item) => WeatherData.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return List.generate(days, (_) => _getDefaultWeather()!);
    } catch (e) {
      print('Weather forecast error: $e');
      return List.generate(days, (_) => _getDefaultWeather()!);
    }
  }
}

/// Weather Data Model
class WeatherData {
  final double temperature;
  final String condition; // 'clear', 'rain', 'clouds', 'snow', etc.
  final double humidity;
  final double windSpeed;
  final String description;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.description,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List<dynamic>).first as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>?;

    return WeatherData(
      temperature: (main['temp'] as num).toDouble(),
      condition: weather['main'] as String? ?? 'clear',
      humidity: (main['humidity'] as num?)?.toDouble() ?? 60.0,
      windSpeed: (wind?['speed'] as num?)?.toDouble() ?? 10.0,
      description: weather['description'] as String? ?? 'Clear sky',
    );
  }

  bool get isCold => temperature < 15;
  bool get isWarm => temperature >= 15 && temperature < 25;
  bool get isHot => temperature >= 25;
  bool get isRaining => condition.toLowerCase().contains('rain');
  bool get isSnowing => condition.toLowerCase().contains('snow');

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'condition': condition,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'description': description,
      'isCold': isCold,
      'isWarm': isWarm,
      'isHot': isHot,
      'isRaining': isRaining,
      'isSnowing': isSnowing,
    };
  }
}
