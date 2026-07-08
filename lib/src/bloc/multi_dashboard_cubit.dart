import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smirror_wire/generated/back_front_back_front_generated.dart' as bfmsg;
import 'package:smirror_wire/generated/dashboard_dashboard_structure_generated.dart' as b;
import 'package:smirror_frontend/src/bloc/dashboard_cubit.dart';
import 'package:smirror_frontend/src/systems/backend_socket.dart';
import 'package:smirror_frontend/src/systems/ha_data_service.dart';
import 'package:smirror_frontend/src/systems/home_assistant_repo.dart';

class MergedMultiDashboardCubit extends Cubit<HADashboardViewState?> {
  final List<int> dashboardIds;
  final HomeAssistantRepository _repo;
  final HomeAssistantDataService _haData;
  final BackendSocket _socket;

  int _currentIndex = 0;
  StreamSubscription? _layoutSub;
  StreamSubscription? _commandSub;
  Timer? _pollingTimer;

  MergedMultiDashboardCubit(
      this.dashboardIds,
      this._repo,
      this._haData,
      this._socket,
      ) : super(null) {
    _commandSub = _socket.simpleCommandStream.listen((cmd) {
      if (cmd.type == bfmsg.SimpleCommandType.UP) _switch(1);
      if (cmd.type == bfmsg.SimpleCommandType.DOWN) _switch(-1);
    });

    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) => _refreshData());
    _initCurrentDashboard();
  }

  b.DashboardData? _deserializeDashboardData(b.Dashboard dashboard) {
    final data = dashboard.dashboardData;
    if (data == null || data.isEmpty) return null;
    final buffer = data is Uint8List ? data : Uint8List.fromList(data);
    return b.DashboardData(buffer);
  }

  void _switch(int step) {
    if (dashboardIds.isEmpty) return;
    _currentIndex = (_currentIndex + step) % dashboardIds.length;
    if (_currentIndex < 0) _currentIndex = dashboardIds.length - 1;
    _initCurrentDashboard();
  }

  void _initCurrentDashboard() {
    final id = dashboardIds[_currentIndex];

    _layoutSub?.cancel();
    _layoutSub = _repo.watch(id).listen((layout) {
      _refreshData(layoutOverride: layout);
    });

    if (_repo.get(id) == null) _repo.requestDashboard(id);
    _refreshData();
  }

  Future<void> _refreshData({b.Dashboard? layoutOverride}) async {
    final id = dashboardIds[_currentIndex];
    final layout = layoutOverride ?? _repo.get(id);
    if (layout == null) return;

    final dashboardData = _deserializeDashboardData(layout);
    final items = dashboardData?.items ?? const [];

    // Immediately emit with cached state for fast UI response
    final Map<String, String> initialValues = {};
    final Map<String, String> initialUnits = {};
    for (final item in items) {
      final eId = item.entityId ?? '';
      initialValues[eId] = _haData.getCachedStateSync(eId);
      initialUnits[eId] = _haData.getCachedUnitSync(eId) ?? '';
    }
    
    if (!isClosed) emit(HADashboardViewState(layout, dashboardData, initialValues, initialUnits));

    // Then update values asynchronously
    _haData.refreshAllStates().then((_) {
      if (isClosed) return;
      final Map<String, String> updatedValues = {};
      final Map<String, String> updatedUnits = {};
      for (final item in items) {
        final eId = item.entityId ?? '';
        updatedValues[eId] = _haData.getCachedStateSync(eId);
        updatedUnits[eId] = _haData.getCachedUnitSync(eId) ?? '';
      }
      emit(HADashboardViewState(layout, dashboardData, updatedValues, updatedUnits));
    });
  }

  @override
  Future<void> close() {
    _layoutSub?.cancel();
    _commandSub?.cancel();
    _pollingTimer?.cancel();
    return super.close();
  }
}
