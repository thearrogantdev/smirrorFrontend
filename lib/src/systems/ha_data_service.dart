import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:smirror_frontend/src/systems/token_service.dart';

class HAState {
  final String state;
  final String? unit;
  final DateTime lastUpdated;
  HAState(this.state, this.lastUpdated, {this.unit});
}

@LazySingleton()
class HomeAssistantDataService {
  final TokenService _tokenService;

  // Cache: EntityID -> State Object
  final Map<String, HAState> _cache = {};

  // To avoid multiple concurrent HTTP calls to HA
  Completer<void>? _syncInFlight;

  HomeAssistantDataService(this._tokenService);

  /// Returns the state of a single entity.
  /// If missing or older than 30 seconds, triggers a background sync.
  Future<String> getEntityState(String entityId) async {
    final cached = _cache[entityId];
    final isStale = cached == null ||
        DateTime.now().difference(cached.lastUpdated).inSeconds > 30;

    if (isStale) {
      // Trigger sync but don't necessarily wait for it if we have 'some' data
      // unless it's null.
      if (cached == null) {
        await refreshAllStates();
      } else {
        unawaited(refreshAllStates());
      }
    }

    return _cache[entityId]?.state ?? 'unavailable';
  }

  /// Fetches all states from HA in a single request.
  /// This is the most efficient way to populate the cache for the whole dashboard.
  Future<void> refreshAllStates() async {
    if (_syncInFlight != null) return _syncInFlight!.future;

    _syncInFlight = Completer<void>();
    try {
      final token = await _tokenService.getToken('HomeAssistant');
      final haUrl = token.url ?? "";
      if(haUrl.isEmpty) return;
      // Fetch all states from HA
      final response = await http.get(
        Uri.parse('${haUrl.endsWith('/') ? haUrl : '$haUrl/'}api/states'),
        headers: {
          'Authorization': 'Bearer ${token.accessToken}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final now = DateTime.now();

        for (var item in data) {
          final id = item['entity_id'] as String;
          final stateVal = item['state'] as String;
          final attribs = item['attributes'] as Map<String, dynamic>?;
          final unit = attribs?['unit_of_measurement'] as String?;
          _cache[id] = HAState(stateVal, now, unit: unit);
        }
      }
    } catch (e) {
      debugPrint("HA Sync Error: $e");
    } finally {
      _syncInFlight?.complete();
      _syncInFlight = null;
    }
  }

  String getCachedStateSync(String entityId) {
    return _cache[entityId]?.state ?? 'unavailable';
  }

  String? getCachedUnitSync(String entityId) {
    return _cache[entityId]?.unit;
  }
}