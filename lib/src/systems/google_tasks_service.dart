import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';
import 'package:smirror_frontend/src/systems/backend_socket.dart';
import 'token_service.dart';

@immutable
class GTask {
  final String id;
  final String title;
  final DateTime? due;
  final String status;
  final String? notes;

  const GTask({
    required this.id,
    required this.title,
    this.due,
    required this.status,
    this.notes,
  });
}

@injectable
class GoogleTasksService {
  final TokenService _tokenService;
  final http.Client _http;
  final Duration _defaultTimeout;

  GoogleTasksService._(this._tokenService, this._http, this._defaultTimeout);

  @factoryMethod
  factory GoogleTasksService(TokenService tokenService) =>
      GoogleTasksService._(tokenService, http.Client(), const Duration(seconds: 8));

  Future<List<GTask>> getTodayTasks({
    String taskListId = '@default',
  }) async {
    if (GetIt.I<BackendSocket>().isStandby) {
      return const <GTask>[];
    }
    final token = await _tokenService.getToken('google');
    if (token.accessToken.isEmpty) {
      throw Exception('Google access token not available.');
    }

    final uri = Uri.https(
      'tasks.googleapis.com',
      '/tasks/v1/lists/$taskListId/tasks',
      {
        'showCompleted': 'false',
      },
    );

    final res = await _http
        .get(uri, headers: {'Authorization': 'Bearer ${token.accessToken}'})
        .timeout(_defaultTimeout);

    if (res.statusCode == 401) {
      debugPrint('Unauthorized fetching tasks for list $taskListId');
      return <GTask>[];
    }
    if (res.statusCode != 200) {
      debugPrint(
          'Failed to fetch Google Tasks for list $taskListId: ${res.statusCode} ${res.body}');
      return <GTask>[];
    }

    final Map<String, dynamic> body =
        jsonDecode(res.body) as Map<String, dynamic>;
    final List items = (body['items'] as List?) ?? const [];

    final tasks = <GTask>[];
    final now = DateTime.now();
    final todayDay = DateTime(now.year, now.month, now.day);

    for (final raw in items) {
      final m = raw as Map<String, dynamic>;

      final id = (m['id'] as String?) ?? '';
      if (id.isEmpty) continue;

      final title = (m['title'] as String?) ?? '';
      final status = (m['status'] as String?) ?? 'needsAction';
      final notes = m['notes'] as String?;

      DateTime? due;
      final dueStr = m['due'] as String?;
      if (dueStr != null && dueStr.isNotEmpty) {
        try {
          due = DateTime.parse(dueStr).toLocal();
        } catch (e) {
          debugPrint('Error parsing due date: $e');
        }
      }

      if (due != null) {
        final dueDay = DateTime(due.year, due.month, due.day);
        if (dueDay.isAfter(todayDay)) {
          // Future task, skip
          continue;
        }
      }

      tasks.add(GTask(
        id: id,
        title: title,
        due: due,
        status: status,
        notes: notes,
      ));
    }

    return tasks;
  }
}
