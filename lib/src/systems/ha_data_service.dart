import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:smirror_frontend/src/systems/token_service.dart';

class HAState {
  final String state;
  final DateTime lastUpdated;
  HAState(this.state, this.lastUpdated);
}

@LazySingleton()
class HomeAssistantDataService {
  final TokenService _tokenService;

  // Cache: EntityID -> State Object
  final Map<String, HAState> _cache = {};

  // To avoid multiple concurrent HTTP calls to HA
  Completer<void>? _syncInFlight;

  // The URL should probably come from your backend config
  String _haUrl = '';

  HomeAssistantDataService(this._tokenService);

  void setUrl(String url) => _haUrl = url;

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
      // 1. Get the token from our TokenService
      final token = await _tokenService.getToken('HomeAssistant');
      _haUrl = token.url ?? ""; 
      if(_haUrl.isEmpty) return;
      // 2. Fetch all states from HA
      final response = await http.get(
        Uri.parse('${_haUrl.endsWith('/') ? _haUrl : '$_haUrl/'}api/states'),
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
          _cache[id] = HAState(stateVal, now);
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
}