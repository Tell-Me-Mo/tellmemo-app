import 'package:flutter/material.dart';

class AppColorSchemes {
  // Private constructor
  AppColorSchemes._();

  // Primary brand color - Deep Purple (Meeting Intelligence theme)
  static const Color _primaryColor = Color(0xFF673AB7);
  static const Color _secondaryColor = Color(0xFF9C27B0);

  // Light theme color scheme
  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: _primaryColor,
    brightness: Brightness.light,
    secondary: _secondaryColor,
  );

  // Dark theme color scheme
  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: _primaryColor,
    brightness: Brightness.dark,
    secondary: _secondaryColor,
  );

  // Custom colors for meeting app
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  // Meeting status colors
  static const Color meetingActiveColor = Color(0xFF4CAF50);
  static const Color meetingPendingColor = Color(0xFFFF9800);
  static const Color meetingCompletedColor = Color(0xFF9E9E9E);

  // Project status colors
  static const Color projectActiveColor = Color(0xFF4CAF50);
  static const Color projectArchivedColor = Color(0xFF9E9E9E);
}