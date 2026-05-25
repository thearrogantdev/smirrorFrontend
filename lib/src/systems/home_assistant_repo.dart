import 'dart:async';
import 'package:flat_buffers/flat_buffers.dart' as fb;
import 'package:injectable/injectable.dart';
import 'package:smirror_wire/generated/dashboard_dashboard_structure_generated.dart' as b;
import 'package:smirror_wire/generated/front_back_front_back_generated.dart' as f;
import 'package:smirror_frontend/src/systems/backend_socket.dart';

@LazySingleton()
class HomeAssistantRepository {
  final BackendSocket _socket;

  // The actual global state (Map of all dashboards)
  final _dashboards = <int, b.Dashboard>{};

  // Stream controllers to notify listeners of specific IDs
  final _idControllers = <int, StreamController<b.Dashboard>>{};

  HomeAssistantRepository(this._socket) {
    _socket.dashboardStream.listen((dashboard) {
      _dashboards[dashboard.backendId] = dashboard;
      _idControllers[dashboard.backendId]?.add(dashboard);
    });
  }

  b.Dashboard? get(int id) => _dashboards[id];

  Stream<b.Dashboard> watch(int id) {
    return _idControllers.putIfAbsent(id, () => StreamController<b.Dashboard>.broadcast()).stream;
  }


  /// Send a request to the backend to send us the dashboard data
  void requestDashboard(int id) {
    final bld = fb.Builder(initialSize: 128);

    // 1. Build the GetDashboard table
    final gdBuilder = f.GetDashboardBuilder(bld);
    gdBuilder.begin();
    gdBuilder.addId(id);
    final getDashboardOffset = gdBuilder.finish();

    // 2. Build the Root Message (FrontBackMessage)
    final fbmBuilder = f.FrontBackMessageBuilder(bld);
    fbmBuilder.begin();

    // Set the union type
    fbmBuilder.addPayloadType(f.FrontBackPayloadTypeId.GetDashboard);
    // Set the offset to the table we just built
    fbmBuilder.addPayloadOffset(getDashboardOffset);

    final root = fbmBuilder.finish();

    // 3. Finalize the buffer
    bld.finish(root);

    _socket.send(bld.buffer);
  }
}
