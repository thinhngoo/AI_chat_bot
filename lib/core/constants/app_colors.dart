import 'package:flutter/material.dart';

/// Theme color palettes
abstract class AppColors {
  // Base colors
  Color get background;
  Color get foreground;

  // Active colors
  Color get primary;
  Color get primaryForeground;
  Color get secondary;
  Color get secondaryForeground;
  Color get accent;
  Color get accentForeground;
  Color get muted;

  // Component colors
  Color get card;
  Color get cardForeground;
  Color get button;
  Color get buttonForeground;
  Color get input;
  Color get inputForeground;

  // Border colors
  Color get border;
  Color get ring;

  // Additional colors
  Color get red;
  Color get redForeground;
  Color get green;
  Color get greenForeground;
  Color get yellow;
  Color get yellowForeground;

  /// Access theme colors
  static final DarkColors dark = DarkColors();
  static final LightColors light = LightColors();
}

/// Dark theme colors implementation
class DarkColors implements AppColors {
  // Singleton instance
  DarkColors._internal();
  static final DarkColors _instance = DarkColors._internal();
  factory DarkColors() => _instance;

  // Main colors
  @override
  final Color background = const Color(0xFF0A0A0A);
  @override
  final Color foreground = const Color(0xFFFFFFFF);

  // Active colors
  @override
  final Color primary = const Color(0xFF1A8CD8);
  @override
  final Color primaryForeground = const Color(0xFFFFFFFF);
  @override
  final Color secondary = const Color(0xFF1B1C20);
  @override
  final Color secondaryForeground = const Color(0xFFFFFFFF);
  @override
  final Color accent = const Color(0xFF1B1C20);
  @override
  final Color accentForeground = const Color(0xFFFFFFFF);
  @override
  final Color muted = const Color(0xFF7F868C);

  // Button colors
  @override
  final Color card = const Color(0xFF1B1C20);
  @override
  final Color cardForeground = const Color(0xFFFFFFFF);
  @override
  final Color button = const Color(0xFF1B1C20);
  @override
  final Color buttonForeground = const Color(0xFFFFFFFF);
  @override
  final Color input = const Color(0xFF131416);
  @override
  final Color inputForeground = const Color(0xFFD9D9D9);

  // Border colors
  @override
  final Color border = Colors.grey.shade800;
  @override
  final Color ring = const Color(0xFFD4C9C9);

  // Additional colors
  @override
  final Color red = Colors.redAccent;
  @override
  final Color redForeground = const Color(0xFFFFFFFF);
  @override
  final Color green = Colors.greenAccent;
  @override
  final Color greenForeground = const Color(0xFFFFFFFF);
  @override
  final Color yellow = Colors.orangeAccent;
  @override
  final Color yellowForeground = const Color(0xFFFFFFFF);
}

/// Light theme colors implementation
class LightColors implements AppColors {
  // Singleton instance
  LightColors._internal();
  static final LightColors _instance = LightColors._internal();
  factory LightColors() => _instance;

  // Main colors
  @override
  final Color background = const Color(0xFFF7F7F5);
  @override
  final Color foreground = const Color(0xFF0F1419);

  // Active colors
  @override
  final Color primary = const Color(0xFF1A8CD8);
  @override
  final Color primaryForeground = const Color(0xFFFFFFFF);
  @override
  final Color secondary = const Color(0xFFE9ECEF);
  @override
  final Color secondaryForeground = const Color(0xFF1B1C20);
  @override
  final Color accent = const Color(0xFFFFFFFF);
  @override
  final Color accentForeground = const Color(0xFF0F1419);
  @override
  final Color muted = const Color(0xFF9CA3AF);

  // Button colors
  @override
  final Color card = const Color(0xFFFFFFFF);
  @override
  final Color cardForeground = const Color(0xFF0A0A0A);
  @override
  final Color button = const Color(0xFFFFFFFF);
  @override
  final Color buttonForeground = const Color(0xFF0A0A0A);
  @override
  final Color input = const Color(0xFFFFFFFF);
  @override
  final Color inputForeground = const Color(0xFF0A0A0A);

  // Border colors
  @override
  final Color border = Colors.grey.shade400;
  @override
  final Color ring = Colors.grey;

  // Additional colors
  @override
  final Color red = Colors.red;
  @override
  final Color redForeground = const Color(0xFFFFFFFF);
  @override
  final Color green = Colors.green;
  @override
  final Color greenForeground = const Color(0xFFFFFFFF);
  @override
  final Color yellow = Colors.orange;
  @override
  final Color yellowForeground = const Color(0xFFFFFFFF);
}
