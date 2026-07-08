import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:smirror_wire/generated/view_view_structure_generated.dart' as bfmsg;
import 'package:smirror_wire/generated/widget_internals_widget_internals_generated.dart' as internals;
import 'package:smirror_frontend/src/bloc/dashboard_cubit.dart';
import 'package:smirror_frontend/src/bloc/multi_dashboard_cubit.dart';
import 'package:smirror_frontend/src/systems/backend_socket.dart';
import 'package:smirror_frontend/src/systems/ha_data_service.dart';
import 'package:smirror_frontend/src/systems/home_assistant_repo.dart';
import 'package:smirror_wire/constants/widget_ids.dart';
import 'package:smirror_frontend/src/widgets/haDashboards/dashboard_display_grid.dart';

class MultiHADashboardWidget extends StatelessWidget {
  final bfmsg.Widget widgetData;

  const MultiHADashboardWidget({super.key, required this.widgetData});

  List<int> _extractIds() {
    // Get the RawBytesValue payload from FlatBuffer
    final prop = widgetData.properties!.firstWhere(
            (p) => p.keyId == PropertyIdsMultiHADashboard.dashboardIds
    );

    if (prop.valueType != bfmsg.WidgetPropertyValueTypeId.RawBytes) return [];

    final rawBytesWrapper = prop.value as bfmsg.RawBytes;

    // FlatBuffers returns an optimized internal list (_FbUint8List)
    // List<int> is like a "shared interface"
    final List<int>? data = rawBytesWrapper.data;

    if (data == null || data.isEmpty) return [];

    // Pass the List<int> directly to your factory this is zero-copy
    final internalList = internals.DashboardList(data);

    return internalList.ids ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final ids = _extractIds();

    if (ids.isEmpty) return const SizedBox.shrink();

    return BlocProvider(
      create: (context) => MergedMultiDashboardCubit(
        ids,
        GetIt.I<HomeAssistantRepository>(),
        GetIt.I<HomeAssistantDataService>(),
        GetIt.I<BackendSocket>(),
      ),
      child: BlocBuilder<MergedMultiDashboardCubit, HADashboardViewState?>(
        builder: (context, state) {
          if (state == null) return const Center(child: CircularProgressIndicator());

          return Stack(
            children: [
              DashboardDisplayGrid(state: state, widgetData: widgetData),
            ],
          );
        },
      ),
    );
  }
}
