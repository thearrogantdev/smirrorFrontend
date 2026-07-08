import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:smirror_frontend/src/bloc/dashboard_cubit.dart';
import 'package:smirror_frontend/src/systems/images.dart';
import 'package:smirror_frontend/src/widgets/haDashboards/dashboard_item_widget.dart';
import 'package:smirror_wire/generated/view_view_structure_generated.dart' as bfmsg;
import 'package:smirror_wire/constants/widget_ids.dart';

class DashboardDisplayGrid extends StatelessWidget {
  final HADashboardViewState state;
  final bfmsg.Widget widgetData;

  const DashboardDisplayGrid({
    super.key,
    required this.state,
    required this.widgetData,
  });

  @override
  Widget build(BuildContext context) {

    final dashboardData = state.dashboardData;
    // Extract Background ID from FlatBuffer
    final int bgId = dashboardData?.backgroundImageId ?? 0;
    final String bgPath = dashboardData?.backgroundImagePath ?? "";

    final int itemsCount = state.items.length;
    final double dashboardWidth = widgetData.width > 0
        ? widgetData.width.toDouble()
        : ((dashboardData?.width ?? 0) > 0 ? dashboardData!.width : 1920.0);
    final double dashboardHeight = widgetData.height > 0
        ? widgetData.height.toDouble()
        : ((dashboardData?.height ?? 0) > 0 ? dashboardData!.height : 1080.0);

    return SizedBox(
      width: dashboardWidth,
      height: dashboardHeight,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          //BACKGROUND IMAGE LAYER
          if (bgId != 0)
            Positioned.fill(
              child: FutureBuilder<ImageProvider>(
                // Pass ID to ImageService. Path is empty because it's remote.
                future: GetIt.I<ImageService>().imageProvider(
                  bgId,
                  bgPath,
                ),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  return Image(
                    image: snap.data!,
                    fit: BoxFit.fill,
                    errorBuilder: (ctx, err, stack) =>
                        const SizedBox.shrink(),
                  );
                },
              ),
            ),

          //ICONS LAYER
          ...List.generate(itemsCount, (index) {
            final item = state.items[index];
            final liveValue = state.values[item.entityId] ?? '...';
            final defaultUnit = state.units[item.entityId] ?? '';

            return Positioned(
              left: item.xPos.toDouble(),
              top: item.yPos.toDouble(),
              width: WidgetIds.dashboardItemSize,
              height: WidgetIds.dashboardItemSize,
              child: DashboardItemWidget(
                item: item,
                liveValue: liveValue,
                defaultUnit: defaultUnit,
              ),
            );
          }),
        ],
      ),
    );
  }
}
