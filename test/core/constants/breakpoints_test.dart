import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/core/constants/breakpoints.dart';

void main() {
  group('Breakpoints', () {
    group('constant values', () {
      test('mobile breakpoint is 600', () {
        expect(Breakpoints.mobile, 600);
      });

      test('tablet breakpoint is 840', () {
        expect(Breakpoints.tablet, 840);
      });

      test('desktop breakpoint is 1200', () {
        expect(Breakpoints.desktop, 1200);
      });

      test('large breakpoint is 1600', () {
        expect(Breakpoints.large, 1600);
      });
    });

    group('isMobile', () {
      test('returns true for width less than mobile breakpoint', () {
        expect(Breakpoints.isMobile(300), isTrue);
        expect(Breakpoints.isMobile(599), isTrue);
      });

      test('returns false for width equal to or greater than mobile breakpoint', () {
        expect(Breakpoints.isMobile(600), isFalse);
        expect(Breakpoints.isMobile(800), isFalse);
      });
    });

    group('isTablet', () {
      test('returns true for width between mobile and desktop breakpoints', () {
        expect(Breakpoints.isTablet(600), isTrue);
        expect(Breakpoints.isTablet(900), isTrue);
        expect(Breakpoints.isTablet(1199), isTrue);
      });

      test('returns false for width outside tablet range', () {
        expect(Breakpoints.isTablet(599), isFalse);
        expect(Breakpoints.isTablet(1200), isFalse);
      });
    });

    group('isDesktop', () {
      test('returns true for width between desktop and large breakpoints', () {
        expect(Breakpoints.isDesktop(1200), isTrue);
        expect(Breakpoints.isDesktop(1400), isTrue);
        expect(Breakpoints.isDesktop(1599), isTrue);
      });

      test('returns false for width outside desktop range', () {
        expect(Breakpoints.isDesktop(1199), isFalse);
        expect(Breakpoints.isDesktop(1600), isFalse);
      });
    });

    group('isLargeScreen', () {
      test('returns true for width equal to or greater than large breakpoint', () {
        expect(Breakpoints.isLargeScreen(1600), isTrue);
        expect(Breakpoints.isLargeScreen(2000), isTrue);
      });

      test('returns false for width less than large breakpoint', () {
        expect(Breakpoints.isLargeScreen(1599), isFalse);
      });
    });

    group('getBreakpoint', () {
      test('returns mobile for small widths', () {
        expect(Breakpoints.getBreakpoint(300), 'mobile');
        expect(Breakpoints.getBreakpoint(599), 'mobile');
      });

      test('returns tablet for medium widths', () {
        expect(Breakpoints.getBreakpoint(600), 'tablet');
        expect(Breakpoints.getBreakpoint(1199), 'tablet');
      });

      test('returns desktop for large widths', () {
        expect(Breakpoints.getBreakpoint(1200), 'desktop');
        expect(Breakpoints.getBreakpoint(1599), 'desktop');
      });

      test('returns large for very large widths', () {
        expect(Breakpoints.getBreakpoint(1600), 'large');
        expect(Breakpoints.getBreakpoint(2000), 'large');
      });
    });

    group('getGridColumns', () {
      test('returns 4 columns for mobile', () {
        expect(Breakpoints.getGridColumns(300), 4);
        expect(Breakpoints.getGridColumns(599), 4);
      });

      test('returns 8 columns for tablet', () {
        expect(Breakpoints.getGridColumns(600), 8);
        expect(Breakpoints.getGridColumns(1199), 8);
      });

      test('returns 12 columns for desktop and large', () {
        expect(Breakpoints.getGridColumns(1200), 12);
        expect(Breakpoints.getGridColumns(1600), 12);
      });
    });

    group('getContentMaxWidth', () {
      test('returns full width for mobile', () {
        expect(Breakpoints.getContentMaxWidth(400), 400);
        expect(Breakpoints.getContentMaxWidth(599), 599);
      });

      test('returns 90% of width for tablet', () {
        expect(Breakpoints.getContentMaxWidth(800), 720); // 800 * 0.9
        expect(Breakpoints.getContentMaxWidth(1000), 900); // 1000 * 0.9
      });

      test('returns 1200 for desktop', () {
        expect(Breakpoints.getContentMaxWidth(1200), 1200);
        expect(Breakpoints.getContentMaxWidth(1400), 1200);
      });

      test('returns 1400 for large screens', () {
        expect(Breakpoints.getContentMaxWidth(1600), 1400);
        expect(Breakpoints.getContentMaxWidth(2000), 1400);
      });
    });
  });

  group('ResponsiveBreakpoint', () {
    Widget buildTestWidget(double width, {required Widget Function(BuildContext) builder}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: Builder(builder: builder),
        ),
      );
    }

    testWidgets('getBreakpoint returns correct breakpoint', (tester) async {
      String? result;

      await tester.pumpWidget(
        buildTestWidget(400, builder: (context) {
          result = ResponsiveBreakpoint.getBreakpoint(context);
          return const SizedBox();
        }),
      );

      expect(result, 'mobile');

      await tester.pumpWidget(
        buildTestWidget(800, builder: (context) {
          result = ResponsiveBreakpoint.getBreakpoint(context);
          return const SizedBox();
        }),
      );

      expect(result, 'tablet');
    });

    testWidgets('isMobile returns true for small screens', (tester) async {
      bool? result;

      await tester.pumpWidget(
        buildTestWidget(400, builder: (context) {
          result = ResponsiveBreakpoint.isMobile(context);
          return const SizedBox();
        }),
      );

      expect(result, isTrue);
    });

    testWidgets('isTablet returns true for medium screens', (tester) async {
      bool? result;

      await tester.pumpWidget(
        buildTestWidget(800, builder: (context) {
          result = ResponsiveBreakpoint.isTablet(context);
          return const SizedBox();
        }),
      );

      expect(result, isTrue);
    });

    testWidgets('isDesktop returns true for large screens', (tester) async {
      bool? result;

      await tester.pumpWidget(
        buildTestWidget(1300, builder: (context) {
          result = ResponsiveBreakpoint.isDesktop(context);
          return const SizedBox();
        }),
      );

      expect(result, isTrue);
    });

    testWidgets('isLargeScreen returns true for very large screens', (tester) async {
      bool? result;

      await tester.pumpWidget(
        buildTestWidget(1700, builder: (context) {
          result = ResponsiveBreakpoint.isLargeScreen(context);
          return const SizedBox();
        }),
      );

      expect(result, isTrue);
    });
  });
}
