import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smirror_frontend/src/widget_system/widget_property_helper.dart';
import 'package:smirror_frontend/src/widgets/base_widget.dart';
import 'package:smirror_wire/constants/widget_ids.dart';

class DigitalClockWidget extends SmirrorStatefulWidget {
  const DigitalClockWidget({super.key, required super.widgetData});

  @override
  State<DigitalClockWidget> createState() => _DigitalClockWidgetState();
}

class _DigitalClockWidgetState extends SmirrorState<DigitalClockWidget> {
  late Timer _timer;
  late DateTime _currentTime;
  bool _colonVisible = true;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    // Tick every 500ms so the colon flashes smoothly every second and seconds are updated instantly.
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return;
      setState(() {
        _currentTime = DateTime.now();
        _colonVisible = !_colonVisible;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget buildContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final show24Hours = propBool(widget.widgetData.properties, PropertyIdsDigitalClock.show24Hours) ?? true;

    // Format hours, minutes, seconds
    final hourFmt = show24Hours ? 'HH' : 'hh';
    final hours = DateFormat(hourFmt).format(_currentTime);
    final minutes = DateFormat('mm').format(_currentTime);
    final seconds = DateFormat('ss').format(_currentTime);
    final amPm = show24Hours ? '' : DateFormat('a').format(_currentTime);

    // Flashing colon character
    final colon = _colonVisible ? ':' : ' ';

    // Let's use adaptive font sizing so it scales with widget size
    final widgetHeight = widget.widgetData.height.toDouble();
    final widgetWidth = widget.widgetData.width.toDouble();
    
    // Scale font size based on the height
    final double timeFontSize = (widgetHeight * 0.55).clamp(24.0, 96.0);
    final double subFontSize = (timeFontSize * 0.35).clamp(10.0, 36.0);

    return Container(
      width: widgetWidth,
      height: widgetHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // Time (Hours and Minutes)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hours,
                  style: GoogleFonts.robotoMono(
                    textStyle: TextStyle(
                      fontSize: timeFontSize,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Text(
                  colon,
                  style: GoogleFonts.robotoMono(
                    textStyle: TextStyle(
                      fontSize: timeFontSize,
                      fontWeight: FontWeight.bold,
                      color: cs.primary, // highlighted flashing colon
                    ),
                  ),
                ),
                Text(
                  minutes,
                  style: GoogleFonts.robotoMono(
                    textStyle: TextStyle(
                      fontSize: timeFontSize,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            // Seconds (smaller)
            Text(
              seconds,
              style: GoogleFonts.robotoMono(
                textStyle: TextStyle(
                  fontSize: subFontSize,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ),
            if (!show24Hours) ...[
              const SizedBox(width: 8),
              // AM/PM marker (smaller, styled beautifully)
              Text(
                amPm,
                style: GoogleFonts.robotoMono(
                  textStyle: TextStyle(
                    fontSize: subFontSize,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
