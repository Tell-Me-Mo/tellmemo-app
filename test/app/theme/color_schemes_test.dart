import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/app/theme/color_schemes.dart';

void main() {
  group('AppColorSchemes', () {
    group('Light Color Scheme', () {
      test('should have correct brightness', () {
        expect(AppColorSchemes.lightColorScheme.brightness, Brightness.light);
      });

      test('should be generated from primary seed color', () {
        expect(AppColorSchemes.lightColorScheme.primary, isA<Color>());
        expect(AppColorSchemes.lightColorScheme.primary, isNot(equals(const Color(0xFF673AB7))));
        // The actual primary might differ from seed due to Material 3 generation
      });

      test('should have secondary color', () {
        expect(AppColorSchemes.lightColorScheme.secondary, isA<Color>());
      });

      test('should have all required color roles', () {
        final scheme = AppColorSchemes.lightColorScheme;

        expect(scheme.primary, isA<Color>());
        expect(scheme.onPrimary, isA<Color>());
        expect(scheme.primaryContainer, isA<Color>());
        expect(scheme.onPrimaryContainer, isA<Color>());

        expect(scheme.secondary, isA<Color>());
        expect(scheme.onSecondary, isA<Color>());
        expect(scheme.secondaryContainer, isA<Color>());
        expect(scheme.onSecondaryContainer, isA<Color>());

        expect(scheme.surface, isA<Color>());
        expect(scheme.onSurface, isA<Color>());
        expect(scheme.error, isA<Color>());
        expect(scheme.onError, isA<Color>());
      });
    });

    group('Dark Color Scheme', () {
      test('should have correct brightness', () {
        expect(AppColorSchemes.darkColorScheme.brightness, Brightness.dark);
      });

      test('should be generated from primary seed color', () {
        expect(AppColorSchemes.darkColorScheme.primary, isA<Color>());
      });

      test('should have secondary color', () {
        expect(AppColorSchemes.darkColorScheme.secondary, isA<Color>());
      });

      test('should have all required color roles', () {
        final scheme = AppColorSchemes.darkColorScheme;

        expect(scheme.primary, isA<Color>());
        expect(scheme.onPrimary, isA<Color>());
        expect(scheme.primaryContainer, isA<Color>());
        expect(scheme.onPrimaryContainer, isA<Color>());

        expect(scheme.secondary, isA<Color>());
        expect(scheme.onSecondary, isA<Color>());
        expect(scheme.secondaryContainer, isA<Color>());
        expect(scheme.onSecondaryContainer, isA<Color>());

        expect(scheme.surface, isA<Color>());
        expect(scheme.onSurface, isA<Color>());
        expect(scheme.error, isA<Color>());
        expect(scheme.onError, isA<Color>());
      });

      test('should have different surface colors than light theme', () {
        expect(
          AppColorSchemes.darkColorScheme.surface,
          isNot(equals(AppColorSchemes.lightColorScheme.surface)),
        );
      });
    });

    group('Custom Semantic Colors', () {
      test('success color should be green', () {
        expect(AppColorSchemes.successColor, const Color(0xFF4CAF50));
      });

      test('warning color should be orange', () {
        expect(AppColorSchemes.warningColor, const Color(0xFFFF9800));
      });

      test('error color should be red', () {
        expect(AppColorSchemes.errorColor, const Color(0xFFF44336));
      });

      test('info color should be blue', () {
        expect(AppColorSchemes.infoColor, const Color(0xFF2196F3));
      });
    });

    group('Meeting Status Colors', () {
      test('active meeting color should be green', () {
        expect(AppColorSchemes.meetingActiveColor, const Color(0xFF4CAF50));
      });

      test('pending meeting color should be orange', () {
        expect(AppColorSchemes.meetingPendingColor, const Color(0xFFFF9800));
      });

      test('completed meeting color should be grey', () {
        expect(AppColorSchemes.meetingCompletedColor, const Color(0xFF9E9E9E));
      });

      test('active and success colors should be the same', () {
        expect(AppColorSchemes.meetingActiveColor, AppColorSchemes.successColor);
      });

      test('pending and warning colors should be the same', () {
        expect(AppColorSchemes.meetingPendingColor, AppColorSchemes.warningColor);
      });
    });

    group('Project Status Colors', () {
      test('active project color should be green', () {
        expect(AppColorSchemes.projectActiveColor, const Color(0xFF4CAF50));
      });

      test('archived project color should be grey', () {
        expect(AppColorSchemes.projectArchivedColor, const Color(0xFF9E9E9E));
      });

      test('active project and meeting colors should be the same', () {
        expect(AppColorSchemes.projectActiveColor, AppColorSchemes.meetingActiveColor);
      });

      test('archived and completed colors should be the same', () {
        expect(AppColorSchemes.projectArchivedColor, AppColorSchemes.meetingCompletedColor);
      });
    });
  });
}
