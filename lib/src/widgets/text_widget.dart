import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smirror_widget_system/widget_ids.dart';
import 'package:smirror_frontend/src/widget_system/widget_property_helper.dart';
import 'package:smirror_frontend/src/widgets/base_widget.dart';

class TextWidget extends SmirrorStatelessWidget {
  const TextWidget({super.key, required super.widgetData});

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(4));

  @override
  Widget buildContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final text = propString(widgetData.properties, PropertyIdsTextWidget.text) ?? '';
    final fontSize = (propInt(widgetData.properties, PropertyIdsTextWidget.fontSize) ?? 16).toDouble();
    final fontFamily = propString(widgetData.properties, PropertyIdsTextWidget.fontFamily) ?? 'Roboto';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: _radius,
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          textScaler: TextScaler.noScaling,
          style: GoogleFonts.getFont(
            fontFamily,
            textStyle: TextStyle(
              fontSize: fontSize,
              color: cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
