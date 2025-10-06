import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/app/theme/text_themes.dart';

void main() {
  group('AppTextThemes', () {
    group('Light Text Theme - Display Styles', () {
      test('displayLarge should have correct properties', () {
        final style = AppTextThemes.lightTextTheme.displayLarge!;
        expect(style.fontSize, 57);
        expect(style.fontWeight, FontWeight.w400);
        expect(style.letterSpacing, -0.25);
      });

      test('displayMedium should have correct properties', () {
        final style = AppTextThemes.lightTextTheme.displayMedium!;
        expect(style.fontSize, 45);
        expect(style.fontWeight, FontWeight.w400);
        expect(style.letterSpacing, 0);
      });

      test('displaySmall should have correct properties', () {
        final style = AppTextThemes.lightTextTheme.displaySmall!;
        expect(style.fontSize, 36);
        expect(style.fontWeight, FontWeight.w400);
        expect(style.letterSpacing, 0);
      });
    });

    group('Light Text Theme - Headline Styles', () {
      test('headlineLarge should have correct properties', () {
        final style = AppTextThemes.lightTextTheme.headlineLarge!;
        expect(style.fontSize, 32);
        expect(style.fontWeight, FontWeight.w400);
        expect(style.letterSpacing, 0);
      });

      test('headlineMedium should have correct properties', () {
        final style = AppTextThemes.lightTextTheme.headlineMedium!;
        expect(style.fontSize, 28);
        expect(style.fontWeight, FontWeight.w400);
        expect(style.letterSpacing, 0);
      });

      test('headlineSmall should have correct properties', () {
        final style = AppTextThemes.lightTextTheme.headlineSmall!;
        expect(style.fontSize, 24);
        expect(style.fontWeight, FontWeight.w400);
        expect(style.letterSpacing, 0);
      });
    });

    group('Light Text Theme - Title Styles', () {
      test('titleLarge should have correct properties', () {
        final style = AppTextThemes.lightTextTheme.titleLarge!;
        expect(style.fontSize, 22);
        expect(style.fontWeight, FontWeight.w500);
        expect(style.letterSpacing, 0);
      });

      test('titleMedium should have correct properties', () {
        final style = AppTextThemes.lightTextTheme.titleMedium!;
        expect(style.fontSize, 16);
        expect(style.fontWeight, FontWeight.w500);
        expect(style.letterSpacing, 0.15);
      });

      test('titleSmall should have correct properties', () {
        final style = AppTextThemes.lightTextTheme.titleSmall!;
        expect(style.fontSize, 14);
        expect(style.fontWeight, FontWeight.w500);
        expect(style.letterSpacing, 0.1);
      });
    });

    group('Light Text Theme - Body Styles', () {
      test('bodyLarge should have correct properties', () {
        final style = AppTextThemes.lightTextTheme.bodyLarge!;
        expect(style.fontSize, 16);
        expect(style.fontWeight, FontWeight.w400);
        expect(style.letterSpacing, 0.5);
      });

      test('bodyMedium should have correct properties', () {
        final style = AppTextThemes.lightTextTheme.bodyMedium!;
        expect(style.fontSize, 14);
        expect(style.fontWeight, FontWeight.w400);
        expect(style.letterSpacing, 0.25);
      });

      test('bodySmall should have correct properties', () {
        final style = AppTextThemes.lightTextTheme.bodySmall!;
        expect(style.fontSize, 12);
        expect(style.fontWeight, FontWeight.w400);
        expect(style.letterSpacing, 0.4);
      });
    });

    group('Light Text Theme - Label Styles', () {
      test('labelLarge should have correct properties', () {
        final style = AppTextThemes.lightTextTheme.labelLarge!;
        expect(style.fontSize, 14);
        expect(style.fontWeight, FontWeight.w500);
        expect(style.letterSpacing, 0.1);
      });

      test('labelMedium should have correct properties', () {
        final style = AppTextThemes.lightTextTheme.labelMedium!;
        expect(style.fontSize, 12);
        expect(style.fontWeight, FontWeight.w500);
        expect(style.letterSpacing, 0.5);
      });

      test('labelSmall should have correct properties', () {
        final style = AppTextThemes.lightTextTheme.labelSmall!;
        expect(style.fontSize, 11);
        expect(style.fontWeight, FontWeight.w500);
        expect(style.letterSpacing, 0.5);
      });
    });

    group('Dark Text Theme', () {
      test('should be identical to light text theme', () {
        expect(AppTextThemes.darkTextTheme, AppTextThemes.lightTextTheme);
      });

      test('should have all text styles defined', () {
        final theme = AppTextThemes.darkTextTheme;

        expect(theme.displayLarge, isNotNull);
        expect(theme.displayMedium, isNotNull);
        expect(theme.displaySmall, isNotNull);

        expect(theme.headlineLarge, isNotNull);
        expect(theme.headlineMedium, isNotNull);
        expect(theme.headlineSmall, isNotNull);

        expect(theme.titleLarge, isNotNull);
        expect(theme.titleMedium, isNotNull);
        expect(theme.titleSmall, isNotNull);

        expect(theme.bodyLarge, isNotNull);
        expect(theme.bodyMedium, isNotNull);
        expect(theme.bodySmall, isNotNull);

        expect(theme.labelLarge, isNotNull);
        expect(theme.labelMedium, isNotNull);
        expect(theme.labelSmall, isNotNull);
      });
    });

    group('Font Size Hierarchy', () {
      test('display styles should be in descending order', () {
        final large = AppTextThemes.lightTextTheme.displayLarge!.fontSize!;
        final medium = AppTextThemes.lightTextTheme.displayMedium!.fontSize!;
        final small = AppTextThemes.lightTextTheme.displaySmall!.fontSize!;

        expect(large, greaterThan(medium));
        expect(medium, greaterThan(small));
      });

      test('headline styles should be in descending order', () {
        final large = AppTextThemes.lightTextTheme.headlineLarge!.fontSize!;
        final medium = AppTextThemes.lightTextTheme.headlineMedium!.fontSize!;
        final small = AppTextThemes.lightTextTheme.headlineSmall!.fontSize!;

        expect(large, greaterThan(medium));
        expect(medium, greaterThan(small));
      });

      test('title styles should be in descending order', () {
        final large = AppTextThemes.lightTextTheme.titleLarge!.fontSize!;
        final medium = AppTextThemes.lightTextTheme.titleMedium!.fontSize!;
        final small = AppTextThemes.lightTextTheme.titleSmall!.fontSize!;

        expect(large, greaterThan(medium));
        expect(medium, greaterThan(small));
      });

      test('body styles should be in descending order', () {
        final large = AppTextThemes.lightTextTheme.bodyLarge!.fontSize!;
        final medium = AppTextThemes.lightTextTheme.bodyMedium!.fontSize!;
        final small = AppTextThemes.lightTextTheme.bodySmall!.fontSize!;

        expect(large, greaterThan(medium));
        expect(medium, greaterThan(small));
      });

      test('label styles should be in descending order', () {
        final large = AppTextThemes.lightTextTheme.labelLarge!.fontSize!;
        final medium = AppTextThemes.lightTextTheme.labelMedium!.fontSize!;
        final small = AppTextThemes.lightTextTheme.labelSmall!.fontSize!;

        expect(large, greaterThan(medium));
        expect(medium, greaterThan(small));
      });
    });

    group('Font Weights', () {
      test('display styles should use regular weight', () {
        expect(AppTextThemes.lightTextTheme.displayLarge!.fontWeight, FontWeight.w400);
        expect(AppTextThemes.lightTextTheme.displayMedium!.fontWeight, FontWeight.w400);
        expect(AppTextThemes.lightTextTheme.displaySmall!.fontWeight, FontWeight.w400);
      });

      test('headline styles should use regular weight', () {
        expect(AppTextThemes.lightTextTheme.headlineLarge!.fontWeight, FontWeight.w400);
        expect(AppTextThemes.lightTextTheme.headlineMedium!.fontWeight, FontWeight.w400);
        expect(AppTextThemes.lightTextTheme.headlineSmall!.fontWeight, FontWeight.w400);
      });

      test('title styles should use medium weight', () {
        expect(AppTextThemes.lightTextTheme.titleLarge!.fontWeight, FontWeight.w500);
        expect(AppTextThemes.lightTextTheme.titleMedium!.fontWeight, FontWeight.w500);
        expect(AppTextThemes.lightTextTheme.titleSmall!.fontWeight, FontWeight.w500);
      });

      test('body styles should use regular weight', () {
        expect(AppTextThemes.lightTextTheme.bodyLarge!.fontWeight, FontWeight.w400);
        expect(AppTextThemes.lightTextTheme.bodyMedium!.fontWeight, FontWeight.w400);
        expect(AppTextThemes.lightTextTheme.bodySmall!.fontWeight, FontWeight.w400);
      });

      test('label styles should use medium weight', () {
        expect(AppTextThemes.lightTextTheme.labelLarge!.fontWeight, FontWeight.w500);
        expect(AppTextThemes.lightTextTheme.labelMedium!.fontWeight, FontWeight.w500);
        expect(AppTextThemes.lightTextTheme.labelSmall!.fontWeight, FontWeight.w500);
      });
    });
  });
}
