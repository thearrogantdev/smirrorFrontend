import 'package:flutter/material.dart';
import 'package:smirror_widget_system/widget_ids.dart';
import 'package:smirror_frontend/src/systems/injection.dart';
import 'package:smirror_frontend/src/systems/weather_service.dart';
import 'package:smirror_frontend/src/widget_system/widget_property_helper.dart';
import 'package:smirror_frontend/src/widgets/base_widget.dart';

class WeatherSmallWidget extends SmirrorStatefulWidget {
  const WeatherSmallWidget({super.key, required super.widgetData});

  @override
  State<WeatherSmallWidget> createState() => _WeatherSmallWidgetState();
}

class _WeatherSmallWidgetState extends SmirrorState<WeatherSmallWidget> {
  late final Future<WeatherData> _future;

  static const _radius = BorderRadius.all(Radius.circular(4));

  static const _unitList = ['metric', 'imperial', 'standard'];

  @override
  void initState() {
    super.initState();
    final weatherService = getIt<WeatherService>();
    final lat = propFloat(widget.widgetData.properties, PropertyIdsOpenWeatherWidget.lat) ?? 0.0;
    final lon = propFloat(widget.widgetData.properties, PropertyIdsOpenWeatherWidget.lon) ?? 0.0;
    final unit = propInt(widget.widgetData.properties, PropertyIdsOpenWeatherWidget.units) ?? 0;

    _future = weatherService.getCurrentWeather(
      lat: lat,
      lon: lon,
      units: _unitList[unit],
      lang: "de",
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: _radius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: FutureBuilder<WeatherData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 72,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (snap.hasError) {
              return SizedBox(
                height: 72,
                child: Center(
                  child: Text('Fehler beim Wetter: ${snap.error}',
                      style: TextStyle(color: cs.error), textAlign: TextAlign.center),
                ),
              );
            }
            final data = snap.data!;
            // OpenWeather icon URL
            final iconUrl = data.icon.isNotEmpty
                ? 'https://openweathermap.org/img/wn/${data.icon}@2x.png'
                : null;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // left: city + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.cityName.isEmpty ? 'Wetter' : data.cityName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '💧 ${data.humidity}%   🌬 ${data.windSpeed.toStringAsFixed(1)} m/s',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // right: temperature + icon
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${data.temperature.toStringAsFixed(1)}°',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(width: 8),
                    if (iconUrl != null)
                      Image.network(iconUrl, width: 48, height: 48, filterQuality: FilterQuality.medium),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
