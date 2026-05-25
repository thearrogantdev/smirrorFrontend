import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smirror_wire/constants/widget_ids.dart';
import 'package:smirror_frontend/src/widget_system/compliments.dart';
import 'package:smirror_frontend/src/widget_system/widget_property_helper.dart';
import 'package:smirror_frontend/src/widgets/base_widget.dart';

class RandomComplimentWidget extends SmirrorStatefulWidget {
  const RandomComplimentWidget({super.key, required super.widgetData});

  @override
  State<RandomComplimentWidget> createState() => _RandomComplimentWidgetState();
}

class _RandomComplimentWidgetState extends SmirrorState<RandomComplimentWidget> {
  String? _compliment;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCompliment();
  }

  void _loadCompliment() {
    final lang = propString(widget.widgetData.properties, PropertyIdsGeneralTextDisplay.language) ?? 'en';
    final compliments = lang.startsWith('de') ? complimentsDe : complimentsEn;

    if (mounted) {
      setState(() {
        _compliment = compliments[Random().nextInt(compliments.length)];
        _loading = false;
      });
    }
  }

  @override
  Widget buildContent(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_compliment == null) return const SizedBox.shrink();

    final fontSize = (propInt(widget.widgetData.properties, PropertyIdsGeneralTextDisplay.fontSize) ?? 14).toDouble();
    final fontFamily = propString(widget.widgetData.properties, PropertyIdsGeneralTextDisplay.fontFamily) ?? 'Roboto';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          _compliment!,
          textAlign: TextAlign.center,
          style: GoogleFonts.getFont(
            fontFamily,
            fontSize: fontSize,
            color: Colors.white,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
