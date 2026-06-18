import 'package:flutter/material.dart';

class AppTheme {
  static const Color _seedColor = Color(0xFF0F766E);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ),
    );
  }
}
