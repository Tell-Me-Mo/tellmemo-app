import 'package:flutter/material.dart';
import 'color_schemes.dart';
import 'text_themes.dart';

class AppTheme {
  // Private constructor
  AppTheme._();

  // Light theme
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColorSchemes.lightColorScheme,
      textTheme: AppTextThemes.lightTextTheme,
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: AppColorSchemes.lightColorScheme.surface,
        foregroundColor: AppColorSchemes.lightColorScheme.onSurface,
        titleTextStyle: AppTextThemes.lightTextTheme.titleLarge?.copyWith(
          color: AppColorSchemes.lightColorScheme.onSurface,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 1,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // FloatingActionButton theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        backgroundColor: AppColorSchemes.lightColorScheme.primary,
        foregroundColor: AppColorSchemes.lightColorScheme.onPrimary,
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Navigation bar theme (for bottom navigation)
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.all(
          AppTextThemes.lightTextTheme.labelMedium,
        ),
        backgroundColor: AppColorSchemes.lightColorScheme.surface,
        indicatorColor: AppColorSchemes.lightColorScheme.secondaryContainer,
      ),

      // Navigation drawer theme
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColorSchemes.lightColorScheme.surface,
      ),
    );
  }

  // Dark theme
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColorSchemes.darkColorScheme,
      textTheme: AppTextThemes.darkTextTheme,
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: AppColorSchemes.darkColorScheme.surface,
        foregroundColor: AppColorSchemes.darkColorScheme.onSurface,
        titleTextStyle: AppTextThemes.darkTextTheme.titleLarge?.copyWith(
          color: AppColorSchemes.darkColorScheme.onSurface,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 1,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // FloatingActionButton theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        backgroundColor: AppColorSchemes.darkColorScheme.primary,
        foregroundColor: AppColorSchemes.darkColorScheme.onPrimary,
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Navigation bar theme (for bottom navigation)
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.all(
          AppTextThemes.darkTextTheme.labelMedium,
        ),
        backgroundColor: AppColorSchemes.darkColorScheme.surface,
        indicatorColor: AppColorSchemes.darkColorScheme.secondaryContainer,
      ),

      // Navigation drawer theme
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColorSchemes.darkColorScheme.surface,
      ),
    );
  }
}