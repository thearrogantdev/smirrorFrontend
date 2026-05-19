import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:smirror_frontend/src/systems/images.dart';
import 'package:smirror_widget_system/widget_ids.dart';
import 'package:smirror_frontend/src/widget_system/widget_property_helper.dart';
import 'package:smirror_frontend/src/widgets/base_widget.dart';

class ImageWidget extends SmirrorStatelessWidget {
  const ImageWidget({super.key, required super.widgetData});

  @override
  Widget buildContent(BuildContext context) {
    final binaryId = propInt(widgetData.properties, GeneralIds.binary) ?? 0;
    final svc = GetIt.I<ImageService>();
    final binaryPath = propString(widgetData.properties, GeneralIds.binaryPath) ?? "";

    return Center(
        child: FutureBuilder<ImageProvider>(
          future: svc.imageProvider(binaryId, binaryPath, targetWidth: widgetData.width.toInt(), targetHeight: widgetData.height.toInt()),
          builder: (c, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            return Image(image: snap.data!);
          },
        ),
    );
  }
}
