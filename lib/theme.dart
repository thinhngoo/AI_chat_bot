import 'package:flutter/material.dart';

extension CustomTextTheme on TextTheme {
  TextStyle get accentSmall => const TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  TextStyle get mutedSmall => const TextStyle(
    color: Color(0xFFAAAAAA),
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
}

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF2D2D2D),
  scaffoldBackgroundColor: const Color(0xFF262624),

  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFCE7D5F),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFE18D75),

    outline: Color(0xFF3D3E38),
    surface: Color(0xFF262624),
    surfaceDim: Color(0xFF2D2D2D),
    onSurface: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xFFAAAAAA),
    error: Color(0xFFD32F2F),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF262624),
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  useMaterial3: true,
);
