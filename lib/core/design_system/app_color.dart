// lib\core\design_system\app_color.dart
import 'package:flutter/material.dart';

class AppTheme {
  static final Color primaryColor = const Color(0xFF215E61);
  static final Color secondaryColor = const Color(0xFFFE7F2D);
  static final Color backgroundColor = const Color(0xFFF5FBE6);
  static final Color surfaceColor = const Color(0xFF233D4D);
  static final Color onBackgroundColor = Colors.black87; // atau sesuaikan
  static final Color onPrimaryColor = Colors.white;
  static final Color onSecondaryColor = Colors.white;

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Warna utama
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      onPrimary: onPrimaryColor,
      secondary: secondaryColor,
      onSecondary: onSecondaryColor,
      background: backgroundColor,
      onBackground: onBackgroundColor,
      surface: surfaceColor,
      onSurface: Colors.white70,
      error: Colors.red,
      onError: Colors.white,
    ),

    // Scaffold & Card background
    scaffoldBackgroundColor: backgroundColor,
    cardColor: Colors.white,

    // Text theme
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: surfaceColor),
      bodyMedium: TextStyle(color: surfaceColor.withOpacity(0.9)),
      bodySmall: TextStyle(color: surfaceColor.withOpacity(0.7)),
    ),

    // ElevatedButton style
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(primaryColor),
        foregroundColor: MaterialStateProperty.all<Color>(onPrimaryColor),
      ),
    ),

    // OutlinedButton style
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        side: MaterialStateProperty.all<BorderSide>(
          BorderSide(color: primaryColor),
        ),
        foregroundColor: MaterialStateProperty.all<Color>(primaryColor),
      ),
    ),

    // Input decoration (TextField)
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: TextStyle(color: primaryColor),
      hintStyle: TextStyle(color: primaryColor.withOpacity(0.6)),
    ),
  );
}