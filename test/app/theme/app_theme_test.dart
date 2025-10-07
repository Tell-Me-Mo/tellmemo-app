import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/app/theme/app_theme.dart';
import 'package:pm_master_v2/app/theme/color_schemes.dart';
import 'package:pm_master_v2/app/theme/text_themes.dart';

void main() {
  group('AppTheme', () {
    group('Light Theme', () {
      test('should use Material 3', () {
        final theme = AppTheme.light;
        expect(theme.useMaterial3, isTrue);
      });

      test('should use light color scheme', () {
        final theme = AppTheme.light;
        expect(theme.colorScheme, AppColorSchemes.lightColorScheme);
        expect(theme.colorScheme.brightness, Brightness.light);
      });

      test('should use light text theme', () {
        final theme = AppTheme.light;
        // Flutter enriches text theme with colors, so compare key properties instead
        expect(theme.textTheme.displayLarge?.fontSize, AppTextThemes.lightTextTheme.displayLarge?.fontSize);
        expect(theme.textTheme.titleLarge?.fontWeight, AppTextThemes.lightTextTheme.titleLarge?.fontWeight);
        expect(theme.textTheme.bodyMedium?.letterSpacing, AppTextThemes.lightTextTheme.bodyMedium?.letterSpacing);
      });

      group('AppBar Theme', () {
        test('should have correct configuration', () {
          final appBarTheme = AppTheme.light.appBarTheme;

          expect(appBarTheme.centerTitle, isTrue);
          expect(appBarTheme.elevation, 0);
          expect(appBarTheme.scrolledUnderElevation, 1);
          expect(appBarTheme.backgroundColor, AppColorSchemes.lightColorScheme.surface);
          expect(appBarTheme.foregroundColor, AppColorSchemes.lightColorScheme.onSurface);
        });

        test('should have title text style with correct color', () {
          final appBarTheme = AppTheme.light.appBarTheme;
          final titleStyle = appBarTheme.titleTextStyle;

          expect(titleStyle, isNotNull);
          expect(titleStyle!.fontSize, 22); // titleLarge
          expect(titleStyle.fontWeight, FontWeight.w500);
          expect(titleStyle.color, AppColorSchemes.lightColorScheme.onSurface);
        });
      });

      group('Card Theme', () {
        test('should have correct configuration', () {
          final cardTheme = AppTheme.light.cardTheme;

          expect(cardTheme.elevation, 1);
          expect(cardTheme.margin, const EdgeInsets.all(8));
        });

        test('should have rounded corners', () {
          final cardTheme = AppTheme.light.cardTheme;
          final shape = cardTheme.shape as RoundedRectangleBorder;
          final borderRadius = shape.borderRadius as BorderRadius;

          expect(borderRadius.topLeft.x, 12);
          expect(borderRadius.topRight.x, 12);
          expect(borderRadius.bottomLeft.x, 12);
          expect(borderRadius.bottomRight.x, 12);
        });
      });

      group('FloatingActionButton Theme', () {
        test('should have correct configuration', () {
          final fabTheme = AppTheme.light.floatingActionButtonTheme;

          expect(fabTheme.elevation, 3);
          expect(fabTheme.backgroundColor, AppColorSchemes.lightColorScheme.primary);
          expect(fabTheme.foregroundColor, AppColorSchemes.lightColorScheme.onPrimary);
        });
      });

      group('ElevatedButton Theme', () {
        test('should have correct configuration', () {
          final buttonTheme = AppTheme.light.elevatedButtonTheme;
          final style = buttonTheme.style!;

          expect(style.elevation?.resolve({}), 1);
          expect(style.padding?.resolve({}), const EdgeInsets.symmetric(horizontal: 24, vertical: 12));
        });

        test('should have rounded corners', () {
          final buttonTheme = AppTheme.light.elevatedButtonTheme;
          final style = buttonTheme.style!;
          final shape = style.shape?.resolve({}) as RoundedRectangleBorder;
          final borderRadius = shape.borderRadius as BorderRadius;

          expect(borderRadius.topLeft.x, 8);
          expect(borderRadius.topRight.x, 8);
          expect(borderRadius.bottomLeft.x, 8);
          expect(borderRadius.bottomRight.x, 8);
        });
      });

      group('InputDecoration Theme', () {
        test('should have correct configuration', () {
          final inputTheme = AppTheme.light.inputDecorationTheme;

          expect(inputTheme.filled, isTrue);
          expect(inputTheme.contentPadding, const EdgeInsets.symmetric(horizontal: 16, vertical: 12));
        });

        test('should have rounded border with no border side', () {
          final inputTheme = AppTheme.light.inputDecorationTheme;
          final border = inputTheme.border as OutlineInputBorder;

          expect(border.borderSide, BorderSide.none);
          expect(border.borderRadius, BorderRadius.circular(8));
        });
      });

      group('NavigationBar Theme', () {
        test('should have correct configuration', () {
          final navBarTheme = AppTheme.light.navigationBarTheme;

          expect(navBarTheme.backgroundColor, AppColorSchemes.lightColorScheme.surface);
          expect(navBarTheme.indicatorColor, AppColorSchemes.lightColorScheme.secondaryContainer);
        });

        test('should have label text style', () {
          final navBarTheme = AppTheme.light.navigationBarTheme;
          final labelStyle = navBarTheme.labelTextStyle?.resolve({});

          expect(labelStyle, AppTextThemes.lightTextTheme.labelMedium);
        });
      });

      group('Drawer Theme', () {
        test('should have correct background color', () {
          final drawerTheme = AppTheme.light.drawerTheme;

          expect(drawerTheme.backgroundColor, AppColorSchemes.lightColorScheme.surface);
        });
      });
    });

    group('Dark Theme', () {
      test('should use Material 3', () {
        final theme = AppTheme.dark;
        expect(theme.useMaterial3, isTrue);
      });

      test('should use dark color scheme', () {
        final theme = AppTheme.dark;
        expect(theme.colorScheme, AppColorSchemes.darkColorScheme);
        expect(theme.colorScheme.brightness, Brightness.dark);
      });

      test('should use dark text theme', () {
        final theme = AppTheme.dark;
        // Flutter enriches text theme with colors, so compare key properties instead
        expect(theme.textTheme.displayLarge?.fontSize, AppTextThemes.darkTextTheme.displayLarge?.fontSize);
        expect(theme.textTheme.titleLarge?.fontWeight, AppTextThemes.darkTextTheme.titleLarge?.fontWeight);
        expect(theme.textTheme.bodyMedium?.letterSpacing, AppTextThemes.darkTextTheme.bodyMedium?.letterSpacing);
      });

      group('AppBar Theme', () {
        test('should have correct configuration', () {
          final appBarTheme = AppTheme.dark.appBarTheme;

          expect(appBarTheme.centerTitle, isTrue);
          expect(appBarTheme.elevation, 0);
          expect(appBarTheme.scrolledUnderElevation, 1);
          expect(appBarTheme.backgroundColor, AppColorSchemes.darkColorScheme.surface);
          expect(appBarTheme.foregroundColor, AppColorSchemes.darkColorScheme.onSurface);
        });

        test('should have title text style with correct color', () {
          final appBarTheme = AppTheme.dark.appBarTheme;
          final titleStyle = appBarTheme.titleTextStyle;

          expect(titleStyle, isNotNull);
          expect(titleStyle!.fontSize, 22); // titleLarge
          expect(titleStyle.fontWeight, FontWeight.w500);
          expect(titleStyle.color, AppColorSchemes.darkColorScheme.onSurface);
        });
      });

      group('Card Theme', () {
        test('should have correct configuration', () {
          final cardTheme = AppTheme.dark.cardTheme;

          expect(cardTheme.elevation, 1);
          expect(cardTheme.margin, const EdgeInsets.all(8));
        });

        test('should have rounded corners', () {
          final cardTheme = AppTheme.dark.cardTheme;
          final shape = cardTheme.shape as RoundedRectangleBorder;
          final borderRadius = shape.borderRadius as BorderRadius;

          expect(borderRadius.topLeft.x, 12);
          expect(borderRadius.topRight.x, 12);
          expect(borderRadius.bottomLeft.x, 12);
          expect(borderRadius.bottomRight.x, 12);
        });
      });

      group('FloatingActionButton Theme', () {
        test('should have correct configuration', () {
          final fabTheme = AppTheme.dark.floatingActionButtonTheme;

          expect(fabTheme.elevation, 3);
          expect(fabTheme.backgroundColor, AppColorSchemes.darkColorScheme.primary);
          expect(fabTheme.foregroundColor, AppColorSchemes.darkColorScheme.onPrimary);
        });
      });

      group('ElevatedButton Theme', () {
        test('should have correct configuration', () {
          final buttonTheme = AppTheme.dark.elevatedButtonTheme;
          final style = buttonTheme.style!;

          expect(style.elevation?.resolve({}), 1);
          expect(style.padding?.resolve({}), const EdgeInsets.symmetric(horizontal: 24, vertical: 12));
        });

        test('should have rounded corners', () {
          final buttonTheme = AppTheme.dark.elevatedButtonTheme;
          final style = buttonTheme.style!;
          final shape = style.shape?.resolve({}) as RoundedRectangleBorder;
          final borderRadius = shape.borderRadius as BorderRadius;

          expect(borderRadius.topLeft.x, 8);
          expect(borderRadius.topRight.x, 8);
          expect(borderRadius.bottomLeft.x, 8);
          expect(borderRadius.bottomRight.x, 8);
        });
      });

      group('InputDecoration Theme', () {
        test('should have correct configuration', () {
          final inputTheme = AppTheme.dark.inputDecorationTheme;

          expect(inputTheme.filled, isTrue);
          expect(inputTheme.contentPadding, const EdgeInsets.symmetric(horizontal: 16, vertical: 12));
        });

        test('should have rounded border with no border side', () {
          final inputTheme = AppTheme.dark.inputDecorationTheme;
          final border = inputTheme.border as OutlineInputBorder;

          expect(border.borderSide, BorderSide.none);
          expect(border.borderRadius, BorderRadius.circular(8));
        });
      });

      group('NavigationBar Theme', () {
        test('should have correct configuration', () {
          final navBarTheme = AppTheme.dark.navigationBarTheme;

          expect(navBarTheme.backgroundColor, AppColorSchemes.darkColorScheme.surface);
          expect(navBarTheme.indicatorColor, AppColorSchemes.darkColorScheme.secondaryContainer);
        });

        test('should have label text style', () {
          final navBarTheme = AppTheme.dark.navigationBarTheme;
          final labelStyle = navBarTheme.labelTextStyle?.resolve({});

          expect(labelStyle, AppTextThemes.darkTextTheme.labelMedium);
        });
      });

      group('Drawer Theme', () {
        test('should have correct background color', () {
          final drawerTheme = AppTheme.dark.drawerTheme;

          expect(drawerTheme.backgroundColor, AppColorSchemes.darkColorScheme.surface);
        });
      });
    });

    group('Light vs Dark Theme Comparison', () {
      test('should have different color schemes', () {
        expect(
          AppTheme.light.colorScheme.surface,
          isNot(equals(AppTheme.dark.colorScheme.surface)),
        );
        expect(
          AppTheme.light.colorScheme.onSurface,
          isNot(equals(AppTheme.dark.colorScheme.onSurface)),
        );
      });

      test('should have same component theme configurations', () {
        // Card elevation should be same
        expect(AppTheme.light.cardTheme.elevation, AppTheme.dark.cardTheme.elevation);

        // Card margin should be same
        expect(AppTheme.light.cardTheme.margin, AppTheme.dark.cardTheme.margin);

        // FAB elevation should be same
        expect(AppTheme.light.floatingActionButtonTheme.elevation,
               AppTheme.dark.floatingActionButtonTheme.elevation);

        // AppBar centerTitle should be same
        expect(AppTheme.light.appBarTheme.centerTitle,
               AppTheme.dark.appBarTheme.centerTitle);
      });

      test('should both use Material 3', () {
        expect(AppTheme.light.useMaterial3, AppTheme.dark.useMaterial3);
        expect(AppTheme.light.useMaterial3, isTrue);
      });
    });
  });
}
