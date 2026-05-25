import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smirror_wire/generated/widget_internals_widget_internals_generated.dart' as bfint;
import 'package:smirror_frontend/l10n/app_localizations.dart';
import 'package:smirror_frontend/src/systems/injection.dart';
import 'package:smirror_frontend/src/systems/google_calendar_service.dart';
import 'package:smirror_wire/constants/widget_ids.dart';
import 'package:smirror_frontend/src/widget_system/widget_property_helper.dart';
import 'package:smirror_frontend/src/widgets/base_widget.dart';

class CalendarTwoDaysWidget extends SmirrorStatefulWidget {
  const CalendarTwoDaysWidget({super.key, required super.widgetData});

  @override
  State<CalendarTwoDaysWidget> createState() => _CalendarTwoDaysWidgetState();
}

class _CalendarTwoDaysWidgetState extends SmirrorState<CalendarTwoDaysWidget> {
  late final Future<_TwoDayBuckets> _future;

  late final String _fontFamily;
  late final double _fontSize;
  late final int _maxPerDay;

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
      final legacyId = propString(widget.widgetData.properties, PropertyIdsGoogleCalendarWidget.calendarId);
      _calendarIds = [legacyId ?? 'primary'];
    }

    _fontSize   = (propInt(widget.widgetData.properties, PropertyIdsGoogleCalendarWidget.fontSize) ?? 14).toDouble();
    _fontFamily = propString(widget.widgetData.properties, PropertyIdsGoogleCalendarWidget.fontFamily) ?? 'Roboto';

    // Each day section gets half the widget height minus its header (~28 px).
    final double halfHeight = widget.widgetData.height / 2.0;
    final double rowHeight  = _fontSize * 2.8;
    _maxPerDay = math.max(1, ((halfHeight - 28) / rowHeight).floor());

    _future = _fetchBuckets();
  }

  // Keep field accessible in initState before _future is set.
  late final List<String> _calendarIds;

  Future<_TwoDayBuckets> _fetchBuckets() async {
    final now      = DateTime.now();
    final todayStart    = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final tomorrowEnd   = todayStart.add(const Duration(days: 2));

    final gcal  = getIt<GoogleCalendarService>();
    final events = await gcal.getEventsInRange(
      calendarIds: _calendarIds,
      from:       todayStart.toUtc(),
      to:         tomorrowEnd.toUtc(),
      maxResults: _maxPerDay * 2, // ceiling; we trim per-bucket below
    );

    final today    = <GCalEvent>[];
    final tomorrow = <GCalEvent>[];

    for (final e in events) {
      final startLocal = e.start.toLocal();
      if (!startLocal.isBefore(tomorrowStart)) {
        if (tomorrow.length < _maxPerDay) tomorrow.add(e);
      } else {
        if (today.length    < _maxPerDay)    today.add(e);
      }
    }

    return _TwoDayBuckets(today: today, tomorrow: tomorrow);
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
      child: FutureBuilder<_TwoDayBuckets>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          if (snap.hasError || !snap.hasData) {
            return const Center(
              child: Icon(Icons.event_busy, color: Colors.white24, size: 24),
            );
          }

          final buckets = snap.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DaySection(
                  label:      'Today',
                  events:     buckets.today,
                  fontSize:   _fontSize,
                  fontFamily: _fontFamily,
                ),
              ),
              Divider(color: Colors.white12, height: 1, thickness: 1),
              Expanded(
                child: _DaySection(
                  label:      'Tomorrow',
                  events:     buckets.tomorrow,
                  fontSize:   _fontSize,
                  fontFamily: _fontFamily,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _TwoDayBuckets {
  final List<GCalEvent> today;
  final List<GCalEvent> tomorrow;
  const _TwoDayBuckets({required this.today, required this.tomorrow});
}

// ---------------------------------------------------------------------------

class _DaySection extends StatelessWidget {
  final String label;
  final List<GCalEvent> events;
  final double fontSize;
  final String fontFamily;

  const _DaySection({
    required this.label,
    required this.events,
    required this.fontSize,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final cs          = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final headerStyle = GoogleFonts.getFont(
      fontFamily,
      fontSize:   fontSize * 0.85,
      fontWeight: FontWeight.w600,
      color:      cs.primary.withValues(alpha: 0.9),
      letterSpacing: 0.8,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: headerStyle),
          const SizedBox(height: 4),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
               child: Text(
                 l10n.noEvents,
                 style: GoogleFonts.getFont(
                   fontFamily,
                   fontSize: fontSize * 0.85,
                  color:    Colors.white24,
                ),
              ),
            )
          else
            ...events.map(
                  (e) => _EventTile(
                event:      e,
                fontSize:   fontSize,
                fontFamily: fontFamily,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _EventTile extends StatelessWidget {
  final GCalEvent event;
  final double    fontSize;
  final String    fontFamily;

  const _EventTile({
    required this.event,
    required this.fontSize,
    required this.fontFamily,
  });

  String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.getFont(fontFamily, fontSize: fontSize, color: Colors.white);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!event.isAllDay) ...[
            SizedBox(
              width: fontSize * 3.5,
              child: Text(
                _hhmm(event.start.toLocal()),
                style: baseStyle.copyWith(
                  color: Colors.white54,
                  fontSize: fontSize * 0.9,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              event.title,
              style:    baseStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
