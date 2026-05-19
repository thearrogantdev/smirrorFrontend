import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:smirror_frontend/src/bloc/dashboard_cubit.dart';
import 'package:smirror_frontend/src/systems/ha_data_service.dart';
import 'package:smirror_frontend/src/systems/home_assistant_repo.dart';
import 'package:smirror_widget_system/widget_ids.dart';
import 'package:smirror_frontend/src/widget_system/widget_property_helper.dart';
import 'package:smirror_frontend/src/widgets/haDashboards/dashboard_display_grid.dart' show DashboardDisplayGrid;
import 'package:smirror_frontend/src/widgets/base_widget.dart';

class HASingleDashboard extends SmirrorStatelessWidget {
  const HASingleDashboard({super.key, required super.widgetData});

  @override
  Widget buildContent(BuildContext context) {
    final dashboardID = propInt(widgetData.properties, PropertyIdsSingleHADashboard.dashboardID) ?? 0;

    if (dashboardID == 0) return const Center(child: Text("No Dashboard ID set"));

    return BlocProvider(
      create: (context) => HADashboardCubit(
        dashboardID,
        GetIt.I<HomeAssistantRepository>(),
        GetIt.I<HomeAssistantDataService>(),
      ),
      child: BlocBuilder<HADashboardCubit, HADashboardViewState?>(
        builder: (context, state) {
          // If null, we are still waiting for the backend to send the data
          if (state == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return DashboardDisplayGrid(state: state);
        },
      ),
    );
  }
}
