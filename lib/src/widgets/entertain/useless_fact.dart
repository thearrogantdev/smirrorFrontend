import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:smirror_wire/constants/widget_ids.dart';
import 'package:smirror_frontend/src/widget_system/widget_property_helper.dart';
import 'package:smirror_frontend/src/widgets/base_widget.dart';

class RandomUselessFact extends SmirrorStatefulWidget {
  const RandomUselessFact({super.key, required super.widgetData});

  @override
  State<RandomUselessFact> createState() => _RandomUselessFactState();
}

class _RandomUselessFactState extends SmirrorState<RandomUselessFact> {
  String? _fact;
  String? _source;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchFact();
  }

  Future<void> _fetchFact() async {
    final lang = propString(widget.widgetData.properties, PropertyIdsGeneralTextDisplay.language) ?? 'en';
    try {
      final response = await http.get(
        Uri.parse('https://uselessfacts.jsph.pl/api/v2/facts/random?language=$lang'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _fact = data['text'];
            _source = data['source'];
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget buildContent(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_fact == null) return const SizedBox.shrink();

    final fontSize = (propInt(widget.widgetData.properties, PropertyIdsGeneralTextDisplay.fontSize) ?? 14).toDouble();
    final fontFamily = propString(widget.widgetData.properties, PropertyIdsGeneralTextDisplay.fontFamily) ?? 'Roboto';
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Text(
                _fact!,
                textAlign: TextAlign.center,
                style: GoogleFonts.getFont(fontFamily, fontSize: fontSize, color: Colors.white),
              ),
            ),
          ),
          if (_source != null)
            Text(
              "Source: $_source",
              style: TextStyle(
                  fontSize: fontSize * 0.7,
                  color: Colors.white.withValues(alpha: 0.4),
                  fontStyle: FontStyle.italic
              ),
            ),
        ],
      ),
    );
  }
}
