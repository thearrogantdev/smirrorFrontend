import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smirror_frontend/flatbufs/widget_internals_widget_internals_generated.dart' as bfint;
import 'package:smirror_frontend/src/systems/injection.dart';
import 'package:smirror_frontend/src/systems/google_calendar_service.dart';
import 'package:smirror_widget_system/widget_ids.dart';
import 'package:smirror_frontend/src/widget_system/widget_property_helper.dart';
import 'package:smirror_frontend/src/widgets/base_widget.dart';

class CalendarWidget extends SmirrorStatefulWidget {
  const CalendarWidget({super.key, required super.widgetData});

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends SmirrorState<CalendarWidget> {
  late Future<List<GCalEvent>> _future;

  // Properties
  late String _fontFamily;
  late double _fontSize;
  late List<String> _calendarIds;

  @override
  void initState() {
    super.initState();

    final rawIds = propRawBytes(widget.widgetData.properties, PropertyIdsGoogleCalendarWidget.calendarId);
    if (rawIds != null) {
      try {
        final gcalIds = bfint.GoogleCaledarIds(rawIds);
        _calendarIds = gcalIds.ids ?? ['primary'];
      } catch (e) {
        _calendarIds = ['primary'];
      }
    } else {
      // Fallback for legacy string property
      final legacyId = propString(widget.widgetData.properties, PropertyIdsGoogleCalendarWidget.calendarId);
      _calendarIds = [legacyId ?? 'primary'];
    }

    _fontSize = (propInt(widget.widgetData.properties, PropertyIdsGoogleCalendarWidget.fontSize) ?? 14).toDouble();
    _fontFamily = propString(widget.widgetData.properties, PropertyIdsGoogleCalendarWidget.fontFamily) ?? 'Roboto';

    // Dynamic Max Results calculation
    final widgetHeight = widget.widgetData.height.toDouble();

    // Header ~ 30px, each event row is roughly fontSize * 2.5
    final double rowHeight = _fontSize * 2.8;
    final int maxResults = math.max(1, (widgetHeight - 30) ~/ rowHeight);

    // Fetch
    final gcal = getIt<GoogleCalendarService>();
    _future = gcal.getNextEvents(
      calendarIds: _calendarIds,
      maxResults: maxResults,
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: FutureBuilder<List<GCalEvent>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
          }

          if (snap.hasError || !snap.hasData) {
            return const Center(child: Icon(Icons.event_busy, color: Colors.white24, size: 24));
          }

          final events = snap.data!;
          if (events.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.calendar_today, size: _fontSize, color: cs.primary.withValues(alpha: 0.8)),
              const SizedBox(height: 8),

              ...events.map((e) => _EventTile(
                  event: e,
                  fontSize: _fontSize,
                  fontFamily: _fontFamily
              )),
            ],
          );
        },
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final GCalEvent event;
  final double fontSize;
  final String fontFamily;

  const _EventTile({
    required this.event,
    required this.fontSize,
    required this.fontFamily
  });

  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  String _formatDayMonth(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.getFont(fontFamily, fontSize: fontSize, color: Colors.white);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time or Icon for all-day
          SizedBox(
            width: fontSize * 4.5,
            child: event.isAllDay
                ? Text(
              _formatDayMonth(event.start),
              style: textStyle.copyWith(color: Colors.white54, fontSize: fontSize * 0.9),
            )
                : Text(
              _formatTime(event.start),
              style: textStyle.copyWith(color: Colors.white54, fontSize: fontSize * 0.9),
            ),
          ),
          const SizedBox(width: 8),
          // Title
          Expanded(
            child: Text(
              event.title,
              style: textStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
