import 'package:flutter/material.dart';
import 'package:smirror_wire/generated/dashboard_dashboard_structure_generated.dart' as b;

class DashboardItemWidget extends StatelessWidget {
  final b.DashboardItem item;
  final String liveValue;

  const DashboardItemWidget({
    super.key,
    required this.item,
    required this.liveValue,
  });

  /// 1. Parse the string value from Home Assistant into a double
  double _parseValue(String raw) {
    if (item.type == b.DashboardItemType.Boolean) {
      final s = raw.toLowerCase();
      return (s == 'on' || s == 'true' || s == 'home' || s == 'open' || s == 'locked')
          ? 1.0
          : 0.0;
    }
    return double.tryParse(raw) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    int activeIcon = item.standardIconCodePoint;
    int activeColor = item.standardColorValue;

    if (item.type != b.DashboardItemType.String) {
      final double numericValue = _parseValue(liveValue);
      double highestTriggerMet = -double.infinity;

      for (int i = 0; i < (item.thresholds?.length ?? 0); i++) {
        final t = item.thresholds![i];
        if (numericValue >= t.triggerValue && t.triggerValue >= highestTriggerMet) {
          highestTriggerMet = t.triggerValue;
          activeIcon = t.iconCodePoint;
          activeColor = t.colorValue;
        }
      }
    }
    final Color mainColor = Color(activeColor);
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (activeIcon != 0)
            Icon(
              IconData(activeIcon, fontFamily: 'MaterialIcons'),
              color: mainColor,
              size: 32,
            )
          else
            Icon(
              Icons.block,
              color: mainColor.withValues(alpha: 0.5),
              size: 32,
            ),
          const SizedBox(height: 4),
          Text(
            item.displayName ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            liveValue + (item.unitOverride ?? ''),
            style: TextStyle(
              color: mainColor.withValues(alpha: 0.7),
              fontSize: 9,
            ),
          ),
        ],
    );
  }
}
