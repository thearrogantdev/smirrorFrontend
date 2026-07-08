import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:smirror_frontend/l10n/app_localizations.dart';
import 'package:smirror_frontend/src/systems/injection.dart';
import 'package:smirror_frontend/src/systems/token_service.dart';
import 'package:smirror_frontend/src/widget_system/widget_property_helper.dart';
import 'package:smirror_frontend/src/widgets/base_widget.dart';
import 'package:smirror_wire/constants/widget_ids.dart';

/// Step interval between forecast frames, in minutes.
const _stepIntervalMinutes = 30;

class RainRadarWidget extends SmirrorStatefulWidget {
  const RainRadarWidget({super.key, required super.widgetData});

  @override
  State<RainRadarWidget> createState() => _RainRadarWidgetState();
}

class _RainRadarWidgetState extends SmirrorState<RainRadarWidget> {
  late final Future<Token> _tokenFuture;
  late final double _lat;
  late final double _lon;
  late final double _zoom;
  late final List<int> _forecastStepMinutes;

  int _stepIndex = 0;
  Timer? _timer;

  static const _radius = BorderRadius.all(Radius.circular(4));
  static final _timeFmt = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    final tokenService = getIt<TokenService>();
    _tokenFuture = tokenService.getToken(PropertyIdsRainRadar.tokenName);

    _lat = propFloat(widget.widgetData.properties, PropertyIdsRainRadar.lat) ?? 0.0;
    _lon = propFloat(widget.widgetData.properties, PropertyIdsRainRadar.lon) ?? 0.0;
    _zoom = (propInt(widget.widgetData.properties, PropertyIdsRainRadar.zoom) ?? 11).toDouble();
    final forecastHours =
        propInt(widget.widgetData.properties, PropertyIdsRainRadar.forecastHours) ?? 4;
    // Build step list: 0, 30, 60, ... up to forecastHours*60 minutes.
    final totalSteps = ((forecastHours * 60) ~/ _stepIntervalMinutes) + 1;
    _forecastStepMinutes =
        List<int>.generate(totalSteps, (i) => i * _stepIntervalMinutes);

    _timer = Timer.periodic(const Duration(milliseconds: 950), (_) {
      if (!mounted) return;
      setState(() {
        _stepIndex = (_stepIndex + 1) % _forecastStepMinutes.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Returns the forecast DateTime for the current step.
  DateTime get _forecastTime =>
      DateTime.now().add(Duration(minutes: _forecastStepMinutes[_stepIndex]));


  /// Human-readable label shown in the widget overlay.
  String _forecastLabel(BuildContext context) {
    final offsetMin = _forecastStepMinutes[_stepIndex];
    if (offsetMin == 0) return AppLocalizations.of(context)!.rainRadarNow;
    return _timeFmt.format(_forecastTime);
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
      child: ClipRRect(
        borderRadius: _radius,
        child: FutureBuilder<Token>(
          future: _tokenFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Fehler beim Laden des Tokens: ${snapshot.error}',
                  style: TextStyle(color: cs.error),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final token = snapshot.data!.accessToken.trim();
            if (token.isEmpty) {
              return const Center(child: Text('Token leer'));
            }

            // OpenWeatherMap 1.0 (tile.openweathermap.org) only supports current precipitation
            // and does not support the 'date' parameter, which causes 400 Bad Request/401 Unauthorized.
            final precipUrl = 'https://tile.openweathermap.org/map/precipitation_new/{z}/{x}/{y}.png?appid=$token';

            return SizedBox(
              width: widget.widgetData.width.toDouble(),
              height: widget.widgetData.height.toDouble(),
              child: Stack(
                children: [
                  RepaintBoundary(
                    child: ExcludeSemantics(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(_lat, _lon),
                          initialZoom: _zoom,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.smirror.app',
                          ),
                          TileLayer(
                            key: const ValueKey('precipitation'),
                            urlTemplate: precipUrl,
                            tileProvider: NetworkTileProvider(),
                            userAgentPackageName: 'com.smirror.app',
                            maxZoom: 18,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Forecast time label ──────────────────────────────────
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _ForecastBadge(
                      label: _forecastLabel(context),
                      isNow: _forecastStepMinutes[_stepIndex] == 0,
                    ),
                  ),

                  // ── Progress ticks ───────────────────────────────────────
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: _ForecastTickBar(
                      stepCount: _forecastStepMinutes.length,
                      currentStep: _stepIndex,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ForecastBadge extends StatelessWidget {
  const _ForecastBadge({required this.label, required this.isNow});

  final String label;
  final bool isNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isNow ? Colors.lightBlueAccent : Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ForecastTickBar extends StatelessWidget {
  const _ForecastTickBar({
    required this.stepCount,
    required this.currentStep,
  });

  final int stepCount;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(stepCount, (i) {
        final isActive = i == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: isActive ? 18 : 8,
          height: 5,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.lightBlueAccent
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
