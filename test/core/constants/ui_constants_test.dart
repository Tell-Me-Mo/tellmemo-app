import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/core/constants/ui_constants.dart';

void main() {
  group('UIConstants', () {
    group('breakpoint values', () {
      test('breakpoint constants are correct', () {
        expect(UIConstants.mobileBreakpoint, 600);
        expect(UIConstants.tabletBreakpoint, 900);
        expect(UIConstants.desktopBreakpoint, 1200);
      });
    });

    group('dialog sizes', () {
      test('dialog size constants are correct', () {
        expect(UIConstants.dialogMinWidth, 320);
        expect(UIConstants.dialogMaxWidth, 560);
        expect(UIConstants.dialogMobileWidthFactor, 0.9);
        expect(UIConstants.dialogTabletWidthFactor, 0.7);
        expect(UIConstants.dialogDesktopWidthFactor, 0.5);
      });
    });

    group('animation durations', () {
      test('animation duration constants are correct', () {
        expect(UIConstants.shortAnimation, const Duration(milliseconds: 200));
        expect(UIConstants.normalAnimation, const Duration(milliseconds: 300));
        expect(UIConstants.longAnimation, const Duration(milliseconds: 500));
      });
    });

    group('animation curves', () {
      test('animation curve constants are correct', () {
        expect(UIConstants.defaultCurve, Curves.easeInOutCubic);
        expect(UIConstants.bounceCurve, Curves.elasticOut);
        expect(UIConstants.fadeCurve, Curves.easeIn);
      });
    });

    group('selection visual', () {
      test('selection visual constants are correct', () {
        expect(UIConstants.selectionOpacity, 0.12);
        expect(UIConstants.selectionHoverOpacity, 0.08);
        expect(UIConstants.selectionBorderWidth, 2.0);
      });
    });

    group('loading states', () {
      test('loading state constants are correct', () {
        expect(UIConstants.skeletonShimmerDuration, 1500);
        expect(UIConstants.skeletonOpacity, 0.1);
      });
    });

    group('search', () {
      test('search constants are correct', () {
        expect(UIConstants.searchDebounceMilliseconds, 300);
        expect(UIConstants.maxSearchSuggestions, 5);
        expect(UIConstants.minSearchLength, 2);
      });
    });
  });

  group('ResponsiveUtils (from ui_constants)', () {
    Widget buildTestWidget(double width, {required Widget Function(BuildContext) builder}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: Builder(builder: builder),
        ),
      );
    }

    group('isMobile', () {
      testWidgets('returns true for width less than mobile breakpoint', (tester) async {
        bool? result;

        await tester.pumpWidget(
          buildTestWidget(400, builder: (context) {
            result = ResponsiveUtils.isMobile(context);
            return const SizedBox();
          }),
        );

        expect(result, isTrue);
      });

      testWidgets('returns false for width at or above mobile breakpoint', (tester) async {
        bool? result;

        await tester.pumpWidget(
          buildTestWidget(600, builder: (context) {
            result = ResponsiveUtils.isMobile(context);
            return const SizedBox();
          }),
        );

        expect(result, isFalse);
      });
    });

    group('isTablet', () {
      testWidgets('returns true for width between mobile and tablet breakpoints', (tester) async {
        bool? result;

        await tester.pumpWidget(
          buildTestWidget(700, builder: (context) {
            result = ResponsiveUtils.isTablet(context);
            return const SizedBox();
          }),
        );

        expect(result, isTrue);
      });

      testWidgets('returns false for mobile width', (tester) async {
        bool? result;

        await tester.pumpWidget(
          buildTestWidget(400, builder: (context) {
            result = ResponsiveUtils.isTablet(context);
            return const SizedBox();
          }),
        );

        expect(result, isFalse);
      });

      testWidgets('returns false for desktop width', (tester) async {
        bool? result;

        await tester.pumpWidget(
          buildTestWidget(1000, builder: (context) {
            result = ResponsiveUtils.isTablet(context);
            return const SizedBox();
          }),
        );

        expect(result, isFalse);
      });
    });

    group('isDesktop', () {
      testWidgets('returns true for width at or above tablet breakpoint', (tester) async {
        bool? result;

        await tester.pumpWidget(
          buildTestWidget(1000, builder: (context) {
            result = ResponsiveUtils.isDesktop(context);
            return const SizedBox();
          }),
        );

        expect(result, isTrue);
      });

      testWidgets('returns false for tablet width', (tester) async {
        bool? result;

        await tester.pumpWidget(
          buildTestWidget(700, builder: (context) {
            result = ResponsiveUtils.isDesktop(context);
            return const SizedBox();
          }),
        );

        expect(result, isFalse);
      });
    });

    group('getDialogWidth', () {
      testWidgets('returns clamped mobile width factor for mobile', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(400, builder: (context) {
            result = ResponsiveUtils.getDialogWidth(context);
            return const SizedBox();
          }),
        );

        // 400 * 0.9 = 360, clamped to [320, 560]
        expect(result, 360);
      });

      testWidgets('returns clamped tablet width factor for tablet', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(700, builder: (context) {
            result = ResponsiveUtils.getDialogWidth(context);
            return const SizedBox();
          }),
        );

        // 700 * 0.7 = 490, clamped to [320, 560]
        expect(result, closeTo(490, 0.01));
      });

      testWidgets('returns max dialog width for desktop', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(1200, builder: (context) {
            result = ResponsiveUtils.getDialogWidth(context);
            return const SizedBox();
          }),
        );

        expect(result, UIConstants.dialogMaxWidth);
      });

      testWidgets('clamps to minimum width for very small screens', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(300, builder: (context) {
            result = ResponsiveUtils.getDialogWidth(context);
            return const SizedBox();
          }),
        );

        // 300 * 0.9 = 270, clamped to minimum 320
        expect(result, UIConstants.dialogMinWidth);
      });
    });

    group('getDialogPadding', () {
      testWidgets('returns 16 padding for mobile', (tester) async {
        EdgeInsets? result;

        await tester.pumpWidget(
          buildTestWidget(400, builder: (context) {
            result = ResponsiveUtils.getDialogPadding(context);
            return const SizedBox();
          }),
        );

        expect(result, const EdgeInsets.all(16));
      });

      testWidgets('returns 20 padding for tablet', (tester) async {
        EdgeInsets? result;

        await tester.pumpWidget(
          buildTestWidget(700, builder: (context) {
            result = ResponsiveUtils.getDialogPadding(context);
            return const SizedBox();
          }),
        );

        expect(result, const EdgeInsets.all(20));
      });

      testWidgets('returns 24 padding for desktop', (tester) async {
        EdgeInsets? result;

        await tester.pumpWidget(
          buildTestWidget(1000, builder: (context) {
            result = ResponsiveUtils.getDialogPadding(context);
            return const SizedBox();
          }),
        );

        expect(result, const EdgeInsets.all(24));
      });
    });

    group('getIconSize', () {
      testWidgets('returns 20 for mobile', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(400, builder: (context) {
            result = ResponsiveUtils.getIconSize(context);
            return const SizedBox();
          }),
        );

        expect(result, 20);
      });

      testWidgets('returns 22 for tablet', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(700, builder: (context) {
            result = ResponsiveUtils.getIconSize(context);
            return const SizedBox();
          }),
        );

        expect(result, 22);
      });

      testWidgets('returns 24 for desktop', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(1000, builder: (context) {
            result = ResponsiveUtils.getIconSize(context);
            return const SizedBox();
          }),
        );

        expect(result, 24);
      });
    });
  });

  group('SelectionColors', () {
    Widget buildTestWidget({required Widget Function(BuildContext) builder}) {
      return MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Builder(builder: builder),
      );
    }

    testWidgets('getSelectionColor returns primary with selection opacity', (tester) async {
      Color? result;

      await tester.pumpWidget(
        buildTestWidget(builder: (context) {
          result = SelectionColors.getSelectionColor(context);
          return const SizedBox();
        }),
      );

      expect((result!.a * 255.0).round() & 0xff, (UIConstants.selectionOpacity * 255).round());
    });

    testWidgets('getSelectionColor returns primary with hover opacity when hovered', (tester) async {
      Color? result;

      await tester.pumpWidget(
        buildTestWidget(builder: (context) {
          result = SelectionColors.getSelectionColor(context, isHovered: true);
          return const SizedBox();
        }),
      );

      expect((result!.a * 255.0).round() & 0xff, (UIConstants.selectionHoverOpacity * 255).round());
    });

    testWidgets('getSelectionBorderColor returns primary color', (tester) async {
      Color? result;
      Color? expectedPrimary;

      await tester.pumpWidget(
        buildTestWidget(builder: (context) {
          expectedPrimary = Theme.of(context).colorScheme.primary;
          result = SelectionColors.getSelectionBorderColor(context);
          return const SizedBox();
        }),
      );

      expect(result, expectedPrimary);
    });

    group('getItemTypeColor', () {
      testWidgets('returns primary for portfolio', (tester) async {
        Color? result;
        Color? expectedPrimary;

        await tester.pumpWidget(
          buildTestWidget(builder: (context) {
            expectedPrimary = Theme.of(context).colorScheme.primary;
            result = SelectionColors.getItemTypeColor(context, 'portfolio');
            return const SizedBox();
          }),
        );

        expect(result, expectedPrimary);
      });

      testWidgets('returns tertiary for program', (tester) async {
        Color? result;
        Color? expectedTertiary;

        await tester.pumpWidget(
          buildTestWidget(builder: (context) {
            expectedTertiary = Theme.of(context).colorScheme.tertiary;
            result = SelectionColors.getItemTypeColor(context, 'program');
            return const SizedBox();
          }),
        );

        expect(result, expectedTertiary);
      });

      testWidgets('returns secondary for project', (tester) async {
        Color? result;
        Color? expectedSecondary;

        await tester.pumpWidget(
          buildTestWidget(builder: (context) {
            expectedSecondary = Theme.of(context).colorScheme.secondary;
            result = SelectionColors.getItemTypeColor(context, 'project');
            return const SizedBox();
          }),
        );

        expect(result, expectedSecondary);
      });

      testWidgets('returns onSurface for unknown type', (tester) async {
        Color? result;
        Color? expectedOnSurface;

        await tester.pumpWidget(
          buildTestWidget(builder: (context) {
            expectedOnSurface = Theme.of(context).colorScheme.onSurface;
            result = SelectionColors.getItemTypeColor(context, 'unknown');
            return const SizedBox();
          }),
        );

        expect(result, expectedOnSurface);
      });

      testWidgets('handles case-insensitive item type', (tester) async {
        Color? result;
        Color? expectedPrimary;

        await tester.pumpWidget(
          buildTestWidget(builder: (context) {
            expectedPrimary = Theme.of(context).colorScheme.primary;
            result = SelectionColors.getItemTypeColor(context, 'PORTFOLIO');
            return const SizedBox();
          }),
        );

        expect(result, expectedPrimary);
      });
    });
  });
}
