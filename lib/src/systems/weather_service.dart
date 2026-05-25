import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:smirror_wire/constants/widget_ids.dart';
import 'token_service.dart';

@immutable
class WeatherData {
  final String cityName;
  final double temperature;   // already in chosen units (default: metric °C)
  final int humidity;         // %
  final double windSpeed;     // m/s (OWM default; unit depends on 'units')
  final String description;   // localized if you pass 'lang'
  final String icon;          // OWM icon code (e.g., "10d")
  final DateTime timestamp;

  const WeatherData({
    required this.cityName,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.icon,
    required this.timestamp,
  });
}

class DailyForecast {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final String description;
  final String icon; // OpenWeather icon id (e.g., "10d")

  DailyForecast({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.description,
    required this.icon,
  });
}

@LazySingleton()
class WeatherService {
  final TokenService _tokenService;
  final http.Client _http;
  final Duration _defaultTimeout;

  WeatherService._(this._tokenService, this._http, this._defaultTimeout);

  @factoryMethod
  factory WeatherService(TokenService tokenService) =>
      WeatherService._(tokenService, http.Client(), const Duration(seconds: 8));

  Future<WeatherData> getCurrentWeather({
    required double lat,
    required double lon,
    String units = 'metric',
    String lang = 'en',
    Duration? timeout,
  }) async {
    // 1) Get token from your backend (provider name fixed as requested)
    final token = await _tokenService.getToken(PropertyIdsOpenWeatherWidget.tokenName);
    if (token.accessToken.isEmpty) {
      throw Exception('Google access token not available.');
    }

    // 2) Build request
    final uri = Uri.https(
      'api.openweathermap.org',
      '/data/2.5/weather',
      {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'appid': token.accessToken,
        'units': units,
        'lang': lang,
      },
    );

    // 3) Call API
    final tmo = timeout ?? _defaultTimeout;
    final res = await _http.get(uri).timeout(tmo);

    if (res.statusCode != 200) {
      // Helpful error with body snippet
      final body = res.body;
      throw HttpException(
        'OpenWeather error ${res.statusCode}: ${body.length > 200 ? "${body.substring(0, 200)}..." : body}',
        uri: uri,
      );
    }

    // 4) Parse JSON
    final Map<String, dynamic> json = jsonDecode(res.body) as Map<String, dynamic>;

    final List weatherList = (json['weather'] as List?) ?? const [];
    final Map<String, dynamic> weather0 =
    weatherList.isNotEmpty ? (weatherList.first as Map<String, dynamic>) : const {};

    final main = (json['main'] as Map?) ?? const {};
    final wind = (json['wind'] as Map?) ?? const {};

    final cityName = (json['name'] as String?) ?? '';
    final temp = (main['temp'] as num?)?.toDouble() ?? double.nan;
    final humidity = (main['humidity'] as num?)?.toInt() ?? 0;
    final windSpeed = (wind['speed'] as num?)?.toDouble() ?? 0.0;
    final description = (weather0['description'] as String?) ?? '';
    final icon = (weather0['icon'] as String?) ?? '';
    final dt = (json['dt'] as num?)?.toInt() ?? 0;

    return WeatherData(
      cityName: cityName,
      temperature: temp,
      humidity: humidity,
      windSpeed: windSpeed,
      description: description,
      icon: icon,
      timestamp: DateTime.fromMillisecondsSinceEpoch(dt * 1000, isUtc: true).toLocal(),
    );
  }

  Future<List<DailyForecast>> getDailyForecast({
    required double lat,
    required double lon,
    required String units, // "metric" | "imperial" | "standard"
    String lang = 'en',
  }) async {
    final token = await _tokenService.getToken(PropertyIdsOpenWeatherWidget.tokenName);

    final uri = Uri.https(
      'api.openweathermap.org',
      '/data/2.5/forecast',
      {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'appid': token.accessToken,
        'units': units,
        'lang': lang,
      },
    );

    final res = await _http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('OpenWeather forecast failed: ${res.statusCode} ${res.body}');
    }

    final Map<String, dynamic> j = jsonDecode(res.body);
    final List list = (j['list'] as List? ?? const []);
    final city = j['city'] as Map<String, dynamic>? ?? const {};
    final tzOffsetSec = (city['timezone'] as num?)?.toInt() ?? 0;

    if (list.isEmpty) return const [];

    // Helper to convert UTC timestamp to the city's local date (midnight).
    DateTime localDateFromUtcSeconds(int dt) {
      final local = DateTime.fromMillisecondsSinceEpoch(dt * 1000, isUtc: true)
          .add(Duration(seconds: tzOffsetSec));
      return DateTime(local.year, local.month, local.day);
    }

    // Today in the city's local time
    final nowLocal = DateTime.now().toUtc().add(Duration(seconds: tzOffsetSec));
    final todayLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);

    // Group 3-hour entries by local date
    final Map<DateTime, List<Map<String, dynamic>>> byDay = {};
    for (final e in list.cast<Map<String, dynamic>>()) {
      final dt = (e['dt'] as num).toInt();
      final dayKey = localDateFromUtcSeconds(dt);
      (byDay[dayKey] ??= []).add(e);
    }

    // Collect days after today, sorted
    final sortedKeys = byDay.keys
        .where((d) => d.isAfter(todayLocal)) // exclude today
        .toList()
      ..sort();

    final result = <DailyForecast>[];

    for (final day in sortedKeys) {
      final entries = byDay[day]!;
      double minT = double.infinity;
      double maxT = -double.infinity;

      // Tally icons/descriptions to pick a representative one
      final Map<String, int> iconCounts = {};
      final Map<String, int> descCounts = {};

      for (final e in entries) {
        final main = e['main'] as Map<String, dynamic>? ?? const {};
        final tempMin = (main['temp_min'] as num?)?.toDouble();
        final tempMax = (main['temp_max'] as num?)?.toDouble();
        if (tempMin != null) minT = tempMin < minT ? tempMin : minT;
        if (tempMax != null) maxT = tempMax > maxT ? tempMax : maxT;

        final weather = (e['weather'] as List?) ?? const [];
        if (weather.isNotEmpty) {
          final w0 = weather[0] as Map<String, dynamic>;
          final icon = (w0['icon'] as String?) ?? '';
          final desc = (w0['description'] as String?) ?? '';
          if (icon.isNotEmpty) iconCounts[icon] = (iconCounts[icon] ?? 0) + 1;
          if (desc.isNotEmpty) descCounts[desc] = (descCounts[desc] ?? 0) + 1;
        }
      }

      if (minT == double.infinity || maxT == -double.infinity) {
        // Skip if no temps were found (unlikely)
        continue;
      }

      String pickMode(Map<String, int> counts) {
        String best = '';
        int bestC = -1;
        counts.forEach((k, v) {
          if (v > bestC) {
            best = k;
            bestC = v;
          }
        });
        return best;
      }

      final icon = pickMode(iconCounts);
      final description = pickMode(descCounts);

      result.add(DailyForecast(
        date: day, // already the city's local midnight
        minTemp: minT,
        maxTemp: maxT,
        description: description,
        icon: icon,
      ));

      if (result.length == 3) break; // only next 3 days
    }

    return result;
  }

  @disposeMethod
  void dispose() {
    _http.close();
  }
}
