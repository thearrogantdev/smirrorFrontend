import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smirror_wire/constants/widget_ids.dart';
import 'package:smirror_frontend/src/widget_system/insults.dart';
import 'package:smirror_frontend/src/widget_system/insults_18plus.dart';
import 'package:smirror_frontend/src/widget_system/widget_property_helper.dart';
import 'package:smirror_frontend/src/widgets/base_widget.dart';

class RandomInsultWidget extends SmirrorStatefulWidget {
  const RandomInsultWidget({super.key, required super.widgetData});

  @override
  State<RandomInsultWidget> createState() => _RandomInsultWidgetState();
}

class _RandomInsultWidgetState extends SmirrorState<RandomInsultWidget> {
  String? _insult;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInsult();
  }

  void _loadInsult() {
    final lang =
        propString(
          widget.widgetData.properties,
          PropertyIdsGeneralTextDisplay.language,
        ) ??
        'en';
    final allow18Plus =
        propBool(
          widget.widgetData.properties,
          PropertyIdsRandomInsult.allow18Plus,
        ) ??
        false;
    final insults = [
      ...(lang.startsWith('de') ? insultsDe : insultsEn),
      if (allow18Plus) ...(lang.startsWith('de') ? insults18De : insults18En),
    ];

    if (mounted) {
      setState(() {
        _insult = insults[Random().nextInt(insults.length)];
        _loading = false;
      });
    }
  }

  @override
  Widget buildContent(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_insult == null) return const SizedBox.shrink();

    final fontSize =
        (propInt(
          widget.widgetData.properties,
          PropertyIdsGeneralTextDisplay.fontSize,
        ) ??
        14).toDouble();
    final fontFamily =
        propString(
          widget.widgetData.properties,
          PropertyIdsGeneralTextDisplay.fontFamily,
        ) ??
        'Roboto';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          _insult!,
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
