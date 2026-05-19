import 'package:flutter/material.dart';
import 'package:smirror_frontend/src/widgets/base_widget.dart';

class CataasImageWidget extends SmirrorStatelessWidget {
  const CataasImageWidget({super.key, required super.widgetData});

  @override
  Widget buildContent(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        'https://cataas.com/cat',
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
        progress == null ? child : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
