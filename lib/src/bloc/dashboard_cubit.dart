import 'dart:async' show StreamSubscription, Timer;
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smirror_wire/generated/dashboard_dashboard_structure_generated.dart' as b;
import 'package:smirror_frontend/src/systems/ha_data_service.dart';
import 'package:smirror_frontend/src/systems/home_assistant_repo.dart';

class HADashboardViewState {
  final b.Dashboard dashboard;
  final b.DashboardData? dashboardData;
  final Map<String, String> values;

  HADashboardViewState(this.dashboard, this.dashboardData, this.values);

  List<b.DashboardItem> get items => dashboardData?.items ?? const [];
}

class HADashboardCubit extends Cubit<HADashboardViewState?> {
  final int id;
  final HomeAssistantRepository _repo;
  final HomeAssistantDataService _haData;

  StreamSubscription? _dashboardSub;
  Timer? _pollingTimer;

  HADashboardCubit(this.id, this._repo, this._haData) : super(null) {
    _dashboardSub = _repo.watch(id).listen((newLayout) {
      _refresh(layoutOverride: newLayout);
    });

    if (_repo.get(id) == null) _repo.requestDashboard(id);

    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
    _refresh();
  }

  b.DashboardData? _deserializeDashboardData(b.Dashboard dashboard) {
    final data = dashboard.dashboardData;
    if (data == null || data.isEmpty) return null;

    final buffer = data is Uint8List ? data : Uint8List.fromList(data);
    return b.DashboardData(buffer);
  }

  Future<void> _refresh({b.Dashboard? layoutOverride}) async {
    final currentLayout = layoutOverride ?? _repo.get(id);
    if (currentLayout == null) return;

    final dashboardData = _deserializeDashboardData(currentLayout);
    final items = dashboardData?.items ?? const [];

    // Immediately emit with cached state for fast UI response
    final Map<String, String> initialValues = {};
    for (final item in items) {
      final entityId = item.entityId ?? '';
      initialValues[entityId] = _haData.getCachedStateSync(entityId);
    }

    if (!isClosed) {
      emit(HADashboardViewState(currentLayout, dashboardData, initialValues));
    }

    // Then update values asynchronously
    _haData.refreshAllStates().then((_) {
      if (isClosed) return;
      final Map<String, String> updatedValues = {};
      for (final item in items) {
        final entityId = item.entityId ?? '';
        updatedValues[entityId] = _haData.getCachedStateSync(entityId);
      }
      emit(HADashboardViewState(currentLayout, dashboardData, updatedValues));
    });
  }

  @override
  Future<void> close() {
    _dashboardSub?.cancel();
    _pollingTimer?.cancel();
    return super.close();
  }
}
