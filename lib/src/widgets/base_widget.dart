import 'package:flutter/material.dart';
import 'package:smirror_frontend/flatbufs/view_view_structure_generated.dart' as bfmsg;

/// Base class for all Smirror widgets that provides automatic scaling
/// to prevent overflows and ensures content fits within the allocated space.
abstract class SmirrorStatelessWidget extends StatelessWidget {
  final bfmsg.Widget widgetData;

  const SmirrorStatelessWidget({super.key, required this.widgetData});

  @override
  Widget build(BuildContext context) {
    return _ScaledWrapper(
      widgetData: widgetData,
      child: buildContent(context),
    );
  }

  /// Subclasses should implement this instead of [build].
  Widget buildContent(BuildContext context);
}

/// Base class for all stateful Smirror widgets that provides automatic scaling.
abstract class SmirrorStatefulWidget extends StatefulWidget {
  final bfmsg.Widget widgetData;

  const SmirrorStatefulWidget({super.key, required this.widgetData});
}

/// Base state class for [SmirrorStatefulWidget] that provides automatic scaling.
abstract class SmirrorState<T extends SmirrorStatefulWidget> extends State<T> {
  @override
  Widget build(BuildContext context) {
    return _ScaledWrapper(
      widgetData: widget.widgetData,
      child: buildContent(context),
    );
  }

  /// Subclasses should implement this instead of [build].
  Widget buildContent(BuildContext context);
}

/// A wrapper that uses [FittedBox] to scale its child to fit within the
/// specified dimensions of [widgetData].
class _ScaledWrapper extends StatelessWidget {
  final bfmsg.Widget widgetData;
  final Widget child;

  const _ScaledWrapper({required this.widgetData, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = widgetData.width.toDouble();
    final height = widgetData.height.toDouble();

    // Give children stable, finite constraints so flex layouts and semantics
    // stay valid even when content is temporarily empty or rebuilding.
    // FittedBox then scales the widget's logical size to the available space.
    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.center,
      child: SizedBox(
        width: width,
        height: height,
        child: child,
      ),
    );
  }
}
