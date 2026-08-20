import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';
import 'package:smirror_frontend/src/systems/backend_socket.dart';
import 'token_service.dart';

@immutable
class GCalEvent {
  final String id;
  final String title;
  final DateTime start;   // Local time (normalized for all-day)
  final DateTime end;     // Local time (normalized for all-day)
  final bool isAllDay;    // True if event uses 'date' (no time component)
  final String? location;
  final String? htmlLink;

  const GCalEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.isAllDay,
    this.location,
    this.htmlLink,
  });
}

@injectable
class GoogleCalendarService {
  final TokenService _tokenService;
  final http.Client _http;
  final Duration _defaultTimeout;

  GoogleCalendarService._(this._tokenService, this._http, this._defaultTimeout);

  @factoryMethod
  factory GoogleCalendarService(TokenService tokenService) =>
      GoogleCalendarService._(tokenService, http.Client(), const Duration(seconds: 8));

  List<String> _uniqueCalendarIds(List<String> calendarIds) {
    final seen = <String>{};
    final uniqueIds = <String>[];

    for (final calendarId in calendarIds) {
      if (seen.add(calendarId)) {
        uniqueIds.add(calendarId);
      }
    }

    return uniqueIds.isEmpty ? const ['primary'] : uniqueIds;
  }

  List<GCalEvent> _deduplicateEvents(List<GCalEvent> events) {
    final deduplicated = <String, GCalEvent>{};

    for (final event in events) {
      deduplicated.putIfAbsent(event.id, () => event);
    }

    return deduplicated.values.toList();
  }

  Future<List<GCalEvent>> getNextEvents({
    List<String> calendarIds = const ['primary'],
    int maxResults = 5,
    String? timeZone, // e.g. 'Europe/Berlin'
  }) async {
    if (GetIt.I<BackendSocket>().isStandby) {
      return const <GCalEvent>[];
    }
    final token = await _tokenService.getToken('google');
    if (token.accessToken.isEmpty) {
      throw Exception('Google access token not available.');
    }

    final nowUtcIso = DateTime.now().toUtc().toIso8601String();
    final uniqueCalendarIds = _uniqueCalendarIds(calendarIds);

    final allEvents = <GCalEvent>[];

    final futures = uniqueCalendarIds.map((calendarId) async {
      final params = <String, String>{
        'singleEvents': 'true', // expand recurring instances
        'orderBy': 'startTime',
        'timeMin': nowUtcIso,
        'maxResults': '$maxResults',
        'fields':
            'items(id,summary,location,htmlLink,start(date,dateTime,timeZone),end(date,dateTime,timeZone)),timeZone',
      };
      if (timeZone != null && timeZone.isNotEmpty) {
        params['timeZone'] = timeZone;
      }

      final uri = Uri.https(
        'www.googleapis.com',
        '/calendar/v3/calendars/$calendarId/events',
        params,
      );

      final res = await _http
          .get(uri, headers: {'Authorization': 'Bearer ${token.accessToken}'})
          .timeout(_defaultTimeout);

      if (res.statusCode == 401) {
        // log the token and scopes to debug
        debugPrint('Unauthorized fetching $calendarId');
        return <GCalEvent>[];
      }
      if (res.statusCode != 200) {
        // If one calendar fails, we might still want to show others, 
        // but for now we follow the existing pattern of throwing.
        debugPrint(
            'Failed to fetch Google Calendar events for $calendarId: ${res.statusCode} ${res.body}');
        return <GCalEvent>[];
      }

      final Map<String, dynamic> body =
          jsonDecode(res.body) as Map<String, dynamic>;
      final List items = (body['items'] as List?) ?? const [];

      final events = <GCalEvent>[];
      for (final raw in items) {
        final m = raw as Map<String, dynamic>;

        final id = (m['id'] as String?) ?? '';
        if (id.isEmpty) continue;

        final title = (m['summary'] as String?) ?? '(Ohne Titel)';
        final location = m['location'] as String?;
        final htmlLink = m['htmlLink'] as String?;

        final startObj = m['start'] as Map<String, dynamic>?;
        final endObj = m['end'] as Map<String, dynamic>?;
        if (startObj == null || endObj == null) continue;

        final bool isAllDay = startObj.containsKey('date');

        DateTime start;
        DateTime end;

        if (isAllDay) {
          final s = DateTime.parse('${startObj['date']}T00:00:00');
          final e = DateTime.parse('${endObj['date']}T00:00:00');
          start = s; 
          end = e;
        } else {
          final s = DateTime.parse(startObj['dateTime'] as String);
          final e = DateTime.parse(endObj['dateTime'] as String);
          start = s.toLocal();
          end = e.toLocal();
        }

        events.add(GCalEvent(
          id: id,
          title: title,
          start: start,
          end: end,
          isAllDay: isAllDay,
          location: location,
          htmlLink: htmlLink,
        ));
      }
      return events;
    });

    final results = await Future.wait(futures);
    for (final res in results) {
      allEvents.addAll(res);
    }

    final deduplicatedEvents = _deduplicateEvents(allEvents);

    // Sort combined events by start time
    deduplicatedEvents.sort((a, b) => a.start.compareTo(b.start));

    // Return only the requested number of events
    if (deduplicatedEvents.length > maxResults) {
      return deduplicatedEvents.sublist(0, maxResults);
    }
    return deduplicatedEvents;
  }

  Future<List<GCalEvent>> getEventsInRange({
    List<String> calendarIds = const ['primary'],
    required DateTime from, // UTC
    required DateTime to,   // UTC, exclusive upper bound
    int maxResults = 50,
    String? timeZone,
  }) async {
    if (GetIt.I<BackendSocket>().isStandby) {
      return const <GCalEvent>[];
    }
    final token = await _tokenService.getToken('google');
    if (token.accessToken.isEmpty) {
      throw Exception('Google access token not available.');
    }

    final allEvents = <GCalEvent>[];
    final uniqueCalendarIds = _uniqueCalendarIds(calendarIds);

    final futures = uniqueCalendarIds.map((calendarId) async {
      final params = <String, String>{
        'singleEvents': 'true',
        'orderBy': 'startTime',
        'timeMin': from.toUtc().toIso8601String(),
        'timeMax': to.toUtc().toIso8601String(),
        'maxResults': '$maxResults',
        'fields':
            'items(id,summary,location,htmlLink,start(date,dateTime,timeZone),end(date,dateTime,timeZone)),timeZone',
      };
      if (timeZone != null && timeZone.isNotEmpty) {
        params['timeZone'] = timeZone;
      }

      final uri = Uri.https(
        'www.googleapis.com',
        '/calendar/v3/calendars/$calendarId/events',
        params,
      );

      final res = await _http
          .get(uri, headers: {'Authorization': 'Bearer ${token.accessToken}'})
          .timeout(_defaultTimeout);

      if (res.statusCode == 401) {
        throw Exception('Unauthorized (401) fetching Google Calendar events.');
      }
      if (res.statusCode != 200) {
        throw Exception(
            'Failed to fetch Google Calendar events for $calendarId: ${res.statusCode} ${res.body}');
      }

      final Map<String, dynamic> body =
          jsonDecode(res.body) as Map<String, dynamic>;
      final List items = (body['items'] as List?) ?? const [];

      final events = <GCalEvent>[];
      for (final raw in items) {
        final m = raw as Map<String, dynamic>;

        final id = (m['id'] as String?) ?? '';
        if (id.isEmpty) continue;

        final title = (m['summary'] as String?) ?? '(Ohne Titel)';
        final location = m['location'] as String?;
        final htmlLink = m['htmlLink'] as String?;

        final startObj = m['start'] as Map<String, dynamic>?;
        final endObj   = m['end']   as Map<String, dynamic>?;
        if (startObj == null || endObj == null) continue;

        final bool isAllDay = startObj.containsKey('date');

        final DateTime start;
        final DateTime end;

        if (isAllDay) {
          start = DateTime.parse('${startObj['date']}T00:00:00');
          end   = DateTime.parse('${endObj['date']}T00:00:00');
        } else {
          start = DateTime.parse(startObj['dateTime'] as String).toLocal();
          end   = DateTime.parse(endObj['dateTime']   as String).toLocal();
        }

        events.add(GCalEvent(
          id:       id,
          title:    title,
          start:    start,
          end:      end,
          isAllDay: isAllDay,
          location: location,
          htmlLink: htmlLink,
        ));
      }
      return events;
    });

    final results = await Future.wait(futures);
    for (final res in results) {
      allEvents.addAll(res);
    }

    final deduplicatedEvents = _deduplicateEvents(allEvents);

    // Sort combined events by start time
    deduplicatedEvents.sort((a, b) => a.start.compareTo(b.start));

    // Return only the requested number of events
    if (deduplicatedEvents.length > maxResults) {
      return deduplicatedEvents.sublist(0, maxResults);
    }
    return deduplicatedEvents;
  }

}
