import 'package:flutter/material.dart';
import 'package:smirror_wire/constants/widget_ids.dart';
import 'package:smirror_frontend/src/systems/injection.dart';
import 'package:smirror_frontend/src/systems/weather_service.dart';
import 'package:smirror_frontend/src/widget_system/widget_property_helper.dart';
import 'package:smirror_frontend/src/widgets/base_widget.dart';

class WeatherForecastWidget extends SmirrorStatefulWidget {
  const WeatherForecastWidget({super.key, required super.widgetData});

  @override
  State<WeatherForecastWidget> createState() => _WeatherForecastWidgetState();
}

class _WeatherBundle {
  final WeatherData current;
  final List<DailyForecast> next3;
  _WeatherBundle(this.current, this.next3);
}

class _WeatherForecastWidgetState extends SmirrorState<WeatherForecastWidget> {
  late final Future<_WeatherBundle> _future;

  static const _radius = BorderRadius.all(Radius.circular(4));
  static const _unitList = ['metric', 'imperial', 'standard'];

  @override
  void initState() {
    super.initState();
    final weatherService = getIt<WeatherService>();
    final lat = propFloat(widget.widgetData.properties, PropertyIdsOpenWeatherWidget.lat) ?? 0.0;
    final lon = propFloat(widget.widgetData.properties, PropertyIdsOpenWeatherWidget.lon) ?? 0.0;
    final unitIdx = propInt(widget.widgetData.properties, PropertyIdsOpenWeatherWidget.units) ?? 0;
    final units = _unitList[unitIdx.clamp(0, _unitList.length - 1)];
    const lang = 'de';

    _future = _loadBundle(weatherService, lat, lon, units, lang);
  }

  Future<_WeatherBundle> _loadBundle(
      WeatherService svc, double lat, double lon, String units, String lang) async {
    final current = await svc.getCurrentWeather(lat: lat, lon: lon, units: units, lang: lang);
    final next3 = await svc.getDailyForecast(lat: lat, lon: lon, units: units, lang: lang);
    return _WeatherBundle(current, next3);
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
        child: FutureBuilder<_WeatherBundle>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 96,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (snap.hasError) {
              return SizedBox(
                height: 96,
                child: Center(
                  child: Text(
                    'Fehler beim Wetter: ${snap.error}',
                    style: TextStyle(color: cs.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final bundle = snap.data!;
            final data = bundle.current;
            final days = bundle.next3;

            final iconUrl = data.icon.isNotEmpty
                ? 'https://openweathermap.org/img/wn/${data.icon}@2x.png'
                : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Current conditions (your original row) ---
                Row(
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
                          Row(
                            children: [
                              Icon(
                                Icons.water_drop_outlined,
                                size: 14,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${data.humidity}%',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.air,
                                size: 14,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${data.windSpeed.toStringAsFixed(1)} m/s',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
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
                ),

                // --- Divider ---
                const SizedBox(height: 8),
                Divider(color: cs.outlineVariant, height: 16),
                const SizedBox(height: 4),

                // --- Next 3 days ---
                if (days.isEmpty)
                  Text(
                    'Keine Vorhersage verfügbar',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: days.map((d) => _DayTile(day: d)).toList(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day});
  final DailyForecast day;

  String _weekdayShort(DateTime dt) {
    // Simple local-ish short weekday; if you use intl, prefer DateFormat('E').
    const names = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    // In Dart, weekday: 1=Mon..7=Sun
    return names[(day.date.weekday - 1) % 7];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconUrl = day.icon.isNotEmpty
        ? 'https://openweathermap.org/img/wn/${day.icon}.png'
        : null;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_weekdayShort(day.date), style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            if (iconUrl != null)
              Image.network(iconUrl, width: 36, height: 36, filterQuality: FilterQuality.medium),
            const SizedBox(height: 4),
            Text(
              '${day.maxTemp.toStringAsFixed(0)}° / ${day.minTemp.toStringAsFixed(0)}°',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              day.description,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
