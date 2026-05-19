import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:smirror_frontend/src/bloc/dashboard_cubit.dart';
import 'package:smirror_frontend/src/systems/images.dart';
import 'package:smirror_frontend/src/widgets/haDashboards/dashboard_item_widget.dart';

class DashboardDisplayGrid extends StatelessWidget {
  final HADashboardViewState state;

  const DashboardDisplayGrid({super.key, required this.state});

  @override
  Widget build(BuildContext context) {

    final dashboardData = state.dashboardData;
    // Extract Background ID from FlatBuffer
    final int bgId = dashboardData?.backgroundImageId ?? 0;
    final String bgPath = dashboardData?.backgroundImagePath ?? "";

    return LayoutBuilder(
        builder: (context, constraints) {
          final int itemsCount = state.items.length;
          final double dashboardWidth = (dashboardData?.width ?? 0) > 0 ? dashboardData!.width : 1920.0;
          final double dashboardHeight = (dashboardData?.height ?? 0) > 0 ? dashboardData!.height : 1080.0;

          return FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.center,
            child: SizedBox(
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
                          targetWidth: dashboardWidth.toInt(),
                          targetHeight: dashboardHeight.toInt(),
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

                      return Positioned(
                        left: item.xPos.toDouble(),
                        top: item.yPos.toDouble(),
                        child: DashboardItemWidget(
                          item: item,
                          liveValue: liveValue,
                        ),
                      );
                    }),
                ]
              ),
            ),
          );
        },
    );
  }
}
