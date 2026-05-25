import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smirror_wire/generated/widget_internals_widget_internals_generated.dart' as internals;
import 'package:smirror_wire/constants/widget_ids.dart';
import 'package:smirror_frontend/src/widget_system/widget_property_helper.dart';
import 'package:smirror_frontend/src/widgets/base_widget.dart';

class BusStopDisplayWidget extends SmirrorStatefulWidget {
  const BusStopDisplayWidget({super.key, required super.widgetData});

  @override
  State<BusStopDisplayWidget> createState() => _BusStopDisplayWidgetState();
}

class _BusStopDisplayWidgetState extends SmirrorState<BusStopDisplayWidget> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Refresh the UI every minute to update the "minutes remaining"
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // --- LOGIC: Calculate upcoming departures ---
  List<({String line, int minutesRemaining})> _getNextDepartures(List<int> rawData) {
    final schedule = internals.BusSchedule(rawData);
    final now = DateTime.now();
    final currentTotalMinutes = now.hour * 60 + now.minute;
    final weekday = now.weekday; // 1 = Mon, 7 = Sun

    List<({String line, int minutesRemaining})> upcoming = [];

    for (int i = 0; i < (schedule.lines?.length ?? 0); i++) {
      final line = schedule.lines![i];
      final String lineName = line.number ?? '?';

      // 1. Select the correct list based on the day
      List<internals.BusDeparture>? departures;
      if (weekday <= 5) {
        departures = line.monFri;
      } else if (weekday == 6) {
        departures = line.sat;
      } else {
        departures = line.sun;
      }

      if (departures == null) continue;

      // 2. Find departures that are in the future (today)
      for (int dIdx = 0; dIdx < departures.length; dIdx++) {
        final d = departures[dIdx];
        final depTotalMinutes = d.hour * 60 + d.minute;

        if (depTotalMinutes > currentTotalMinutes) {
          upcoming.add((
          line: lineName,
          minutesRemaining: depTotalMinutes - currentTotalMinutes,
          ));
        }
      }
    }

    // 3. Sort by time (closest first)
    upcoming.sort((a, b) => a.minutesRemaining.compareTo(b.minutesRemaining));
    return upcoming;
  }

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);

    // Properties
    final fontSize = (propInt(widget.widgetData.properties, PropertyIdsBusStop.fontSize) ?? 14).toDouble();
    final fontFamily = propString(widget.widgetData.properties, PropertyIdsBusStop.fontFamily) ?? 'Roboto';
    final data = propRawBytes(widget.widgetData.properties, PropertyIdsBusStop.schedule);

    if (data ==  null || data.isEmpty) {
      return const SizedBox.shrink();
    }

    final departures = _getNextDepartures(data);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate how many items fit
          // Header ~ fontSize * 2, Divider ~ 12, Item ~ fontSize * 1.8
          const double headerReserved = 40.0;
          final double itemHeight = fontSize * 2.0;
          final int maxVisibleItems = math.max(0, (constraints.maxHeight - headerReserved) ~/ itemHeight);

          final displayList = departures.take(maxVisibleItems).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_bus, size: fontSize, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    "Bus",
                    style: GoogleFonts.getFont(fontFamily, fontSize: fontSize, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 16, thickness: 0.5),

              // DATA ROWS
              if (displayList.isEmpty)
                Text("---", style: TextStyle(fontSize: fontSize, color: Colors.white24))
              else
                ...displayList.map((dep) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: SizedBox(
                    height: itemHeight - 4, // Keep height strictly defined
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            dep.line,
                            style: GoogleFonts.getFont(fontFamily, fontSize: fontSize * 0.85, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          "${dep.minutesRemaining} min",
                          style: GoogleFonts.getFont(fontFamily, fontSize: fontSize * 0.85, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                )),
            ],
          );
        },
      ),
    );
  }
}
