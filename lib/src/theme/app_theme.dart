import 'package:flutter/material.dart';

class AppTheme {
  static final List<ThemeData> _themes = [
    _lightTheme,
    _darkTheme,
    _blueTheme,
    _neonTheme,
  ];

  static int get themeCount => _themes.length;

  static ThemeData getTheme(int themeId) {
    if (themeId >= 0 && themeId < _themes.length) {
      return _themes[themeId];
    }
    return _themes[0];
  }

  static final ThemeData _lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    extensions: const [
      WidgetTileTheme(
        background: Color(0xFFF5F5F5), // light grey
        border: Color(0x33000000),     // black with alpha
        text: Colors.black,
        radius: 4,
      ),
    ],
  );

  static final ThemeData _darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    extensions: const [
      WidgetTileTheme(
        background: Color(0xFF1E1E1E), // dark surface
        border: Color(0x55FFFFFF),     // white with alpha
        text: Colors.white,
        radius: 4,
      ),
    ],
  );

  static final ThemeData _blueTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blueAccent,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    extensions: const [
      WidgetTileTheme(
        background: Color(0xFFE3F2FD), // light blue
        border: Color(0x331565C0),     // blue with alpha
        text: Color(0xFF0D47A1),
        radius: 4,
      ),
    ],
  );

  static final ThemeData _neonTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.purpleAccent,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    extensions: const [
      WidgetTileTheme(
        background: Color(0xFF2A003D), // deep purple
        border: Color(0x55E040FB),     // neon purple with alpha
        text: Color(0xFFF3E5F5),
        radius: 4,
      ),
    ],
  );
}

@immutable
class WidgetTileTheme extends ThemeExtension<WidgetTileTheme> {
  final Color background;
  final Color border;
  final Color text;
  final double radius;
  const WidgetTileTheme({
    required this.background,
    required this.border,
    required this.text,
    required this.radius,
  });

  @override
  WidgetTileTheme copyWith({Color? background, Color? border, Color? text, double? radius}) =>
      WidgetTileTheme(
        background: background ?? this.background,
        border: border ?? this.border,
        text: text ?? this.text,
        radius: radius ?? this.radius,
      );

  @override
  WidgetTileTheme lerp(ThemeExtension<WidgetTileTheme>? other, double t) {
    if (other is! WidgetTileTheme) return this;
    final o = other;
    return WidgetTileTheme(
      background: Color.lerp(background, o.background, t)!,
      border: Color.lerp(border, o.border, t)!,
      text: Color.lerp(text, o.text, t)!,
      radius: radius + (o.radius - radius) * t,
    );
  }
}
