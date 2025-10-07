import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/core/utils/responsive_utils.dart';
import 'package:pm_master_v2/core/constants/layout_constants.dart';

void main() {
  group('ResponsiveUtils', () {
    Widget buildTestWidget({
      required double width,
      required double height,
      required Widget Function(BuildContext) builder,
    }) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, height),
          ),
          child: Builder(builder: builder),
        ),
      );
    }

    group('getScreenSize', () {
      testWidgets('returns screen size from MediaQuery', (tester) async {
        Size? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            builder: (context) {
              result = ResponsiveUtils.getScreenSize(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, const Size(400, 800));
      });
    });

    group('getScreenWidth', () {
      testWidgets('returns screen width from MediaQuery', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            builder: (context) {
              result = ResponsiveUtils.getScreenWidth(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, 400);
      });
    });

    group('getScreenHeight', () {
      testWidgets('returns screen height from MediaQuery', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            builder: (context) {
              result = ResponsiveUtils.getScreenHeight(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, 800);
      });
    });

    group('getResponsiveValue', () {
      testWidgets('returns mobile value for mobile screen', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            builder: (context) {
              result = ResponsiveUtils.getResponsiveValue(
                context: context,
                mobile: 10,
                tablet: 20,
                desktop: 30,
              );
              return const SizedBox();
            },
          ),
        );

        expect(result, 10);
      });

      testWidgets('returns tablet value for tablet screen', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 700,
            height: 1000,
            builder: (context) {
              result = ResponsiveUtils.getResponsiveValue(
                context: context,
                mobile: 10,
                tablet: 20,
                desktop: 30,
              );
              return const SizedBox();
            },
          ),
        );

        expect(result, 20);
      });

      testWidgets('returns desktop value for desktop screen', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 1300,
            height: 900,
            builder: (context) {
              result = ResponsiveUtils.getResponsiveValue(
                context: context,
                mobile: 10,
                tablet: 20,
                desktop: 30,
              );
              return const SizedBox();
            },
          ),
        );

        expect(result, 30);
      });

      testWidgets('returns large value for large screen', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 1700,
            height: 1000,
            builder: (context) {
              result = ResponsiveUtils.getResponsiveValue(
                context: context,
                mobile: 10,
                tablet: 20,
                desktop: 30,
                large: 40,
              );
              return const SizedBox();
            },
          ),
        );

        expect(result, 40);
      });

      testWidgets('falls back to mobile when tablet not provided', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 700,
            height: 1000,
            builder: (context) {
              result = ResponsiveUtils.getResponsiveValue(
                context: context,
                mobile: 10,
                desktop: 30,
              );
              return const SizedBox();
            },
          ),
        );

        expect(result, 10);
      });
    });

    group('getResponsivePadding', () {
      testWidgets('returns mobile padding for mobile screen', (tester) async {
        EdgeInsets? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            builder: (context) {
              result = ResponsiveUtils.getResponsivePadding(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, const EdgeInsets.all(LayoutConstants.mobilePadding));
      });

      testWidgets('returns tablet padding for tablet screen', (tester) async {
        EdgeInsets? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 700,
            height: 1000,
            builder: (context) {
              result = ResponsiveUtils.getResponsivePadding(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, const EdgeInsets.all(LayoutConstants.tabletPadding));
      });

      testWidgets('returns desktop padding for desktop screen', (tester) async {
        EdgeInsets? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 1300,
            height: 900,
            builder: (context) {
              result = ResponsiveUtils.getResponsivePadding(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, const EdgeInsets.all(LayoutConstants.desktopPadding));
      });
    });

    group('getResponsiveMargin', () {
      testWidgets('returns mobile margin for mobile screen', (tester) async {
        EdgeInsets? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            builder: (context) {
              result = ResponsiveUtils.getResponsiveMargin(context);
              return const SizedBox();
            },
          ),
        );

        expect(
          result,
          const EdgeInsets.symmetric(
            horizontal: LayoutConstants.spacingMd,
            vertical: LayoutConstants.spacingSm,
          ),
        );
      });

      testWidgets('returns tablet margin for tablet screen', (tester) async {
        EdgeInsets? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 700,
            height: 1000,
            builder: (context) {
              result = ResponsiveUtils.getResponsiveMargin(context);
              return const SizedBox();
            },
          ),
        );

        expect(
          result,
          const EdgeInsets.symmetric(
            horizontal: LayoutConstants.spacingLg,
            vertical: LayoutConstants.spacingMd,
          ),
        );
      });

      testWidgets('returns desktop margin for desktop screen', (tester) async {
        EdgeInsets? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 1300,
            height: 900,
            builder: (context) {
              result = ResponsiveUtils.getResponsiveMargin(context);
              return const SizedBox();
            },
          ),
        );

        expect(
          result,
          const EdgeInsets.symmetric(
            horizontal: LayoutConstants.spacingXl,
            vertical: LayoutConstants.spacingLg,
          ),
        );
      });
    });

    group('getResponsiveText', () {
      testWidgets('returns base size for mobile', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            builder: (context) {
              result = ResponsiveUtils.getResponsiveText(context, 16.0);
              return const SizedBox();
            },
          ),
        );

        expect(result, 16.0);
      });

      testWidgets('returns 1.05x size for tablet', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 700,
            height: 1000,
            builder: (context) {
              result = ResponsiveUtils.getResponsiveText(context, 16.0);
              return const SizedBox();
            },
          ),
        );

        expect(result, 16.0 * 1.05);
      });

      testWidgets('returns 1.1x size for desktop', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 1300,
            height: 900,
            builder: (context) {
              result = ResponsiveUtils.getResponsiveText(context, 16.0);
              return const SizedBox();
            },
          ),
        );

        expect(result, 16.0 * 1.1);
      });

      testWidgets('returns 1.2x size for large screen', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 1700,
            height: 1000,
            builder: (context) {
              result = ResponsiveUtils.getResponsiveText(context, 16.0);
              return const SizedBox();
            },
          ),
        );

        expect(result, 16.0 * 1.2);
      });
    });

    group('getResponsiveGridSpacing', () {
      testWidgets('returns mobile grid spacing for mobile', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            builder: (context) {
              result = ResponsiveUtils.getResponsiveGridSpacing(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, LayoutConstants.mobileGridSpacing);
      });

      testWidgets('returns tablet grid spacing for tablet', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 700,
            height: 1000,
            builder: (context) {
              result = ResponsiveUtils.getResponsiveGridSpacing(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, LayoutConstants.tabletGridSpacing);
      });

      testWidgets('returns desktop grid spacing for desktop', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 1300,
            height: 900,
            builder: (context) {
              result = ResponsiveUtils.getResponsiveGridSpacing(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, LayoutConstants.desktopGridSpacing);
      });
    });

    group('getResponsiveGridColumns', () {
      testWidgets('returns 4 columns for mobile', (tester) async {
        int? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            builder: (context) {
              result = ResponsiveUtils.getResponsiveGridColumns(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, 4);
      });

      testWidgets('returns 8 columns for tablet', (tester) async {
        int? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 700,
            height: 1000,
            builder: (context) {
              result = ResponsiveUtils.getResponsiveGridColumns(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, 8);
      });

      testWidgets('returns 12 columns for desktop', (tester) async {
        int? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 1300,
            height: 900,
            builder: (context) {
              result = ResponsiveUtils.getResponsiveGridColumns(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, 12);
      });
    });

    group('getResponsiveContentWidth', () {
      testWidgets('returns full width for mobile', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            builder: (context) {
              result = ResponsiveUtils.getResponsiveContentWidth(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, 400);
      });

      testWidgets('returns constrained width for desktop', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 1300,
            height: 900,
            builder: (context) {
              result = ResponsiveUtils.getResponsiveContentWidth(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, 1200);
      });
    });

    group('getSafeAreaPadding', () {
      testWidgets('returns safe area padding from MediaQuery', (tester) async {
        EdgeInsets? result;

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(400, 800),
                padding: EdgeInsets.only(top: 44, bottom: 34),
              ),
              child: Builder(
                builder: (context) {
                  result = ResponsiveUtils.getSafeAreaPadding(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );

        expect(result, const EdgeInsets.only(top: 44, bottom: 34));
      });
    });

    group('getOrientation', () {
      testWidgets('returns portrait orientation', (tester) async {
        Orientation? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            builder: (context) {
              result = ResponsiveUtils.getOrientation(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, Orientation.portrait);
      });

      testWidgets('returns landscape orientation', (tester) async {
        Orientation? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 800,
            height: 400,
            builder: (context) {
              result = ResponsiveUtils.getOrientation(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, Orientation.landscape);
      });
    });

    group('isLandscape', () {
      testWidgets('returns true for landscape orientation', (tester) async {
        bool? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 800,
            height: 400,
            builder: (context) {
              result = ResponsiveUtils.isLandscape(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, isTrue);
      });

      testWidgets('returns false for portrait orientation', (tester) async {
        bool? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            builder: (context) {
              result = ResponsiveUtils.isLandscape(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, isFalse);
      });
    });

    group('isPortrait', () {
      testWidgets('returns true for portrait orientation', (tester) async {
        bool? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            builder: (context) {
              result = ResponsiveUtils.isPortrait(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, isTrue);
      });

      testWidgets('returns false for landscape orientation', (tester) async {
        bool? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 800,
            height: 400,
            builder: (context) {
              result = ResponsiveUtils.isPortrait(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, isFalse);
      });
    });

    group('isDesktop', () {
      testWidgets('returns true for desktop width', (tester) async {
        bool? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 1300,
            height: 900,
            builder: (context) {
              result = ResponsiveUtils.isDesktop(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, isTrue);
      });

      testWidgets('returns false for tablet width', (tester) async {
        bool? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 700,
            height: 1000,
            builder: (context) {
              result = ResponsiveUtils.isDesktop(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, isFalse);
      });
    });

    group('isTablet', () {
      testWidgets('returns true for tablet width', (tester) async {
        bool? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 700,
            height: 1000,
            builder: (context) {
              result = ResponsiveUtils.isTablet(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, isTrue);
      });

      testWidgets('returns false for mobile width', (tester) async {
        bool? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            builder: (context) {
              result = ResponsiveUtils.isTablet(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, isFalse);
      });
    });

    group('isMobile', () {
      testWidgets('returns true for mobile width', (tester) async {
        bool? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            builder: (context) {
              result = ResponsiveUtils.isMobile(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, isTrue);
      });

      testWidgets('returns false for tablet width', (tester) async {
        bool? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 700,
            height: 1000,
            builder: (context) {
              result = ResponsiveUtils.isMobile(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, isFalse);
      });
    });

    group('getAspectRatio', () {
      testWidgets('returns correct aspect ratio', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            builder: (context) {
              result = ResponsiveUtils.getAspectRatio(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, 0.5);
      });

      testWidgets('returns correct aspect ratio for landscape', (tester) async {
        double? result;

        await tester.pumpWidget(
          buildTestWidget(
            width: 800,
            height: 400,
            builder: (context) {
              result = ResponsiveUtils.getAspectRatio(context);
              return const SizedBox();
            },
          ),
        );

        expect(result, 2.0);
      });
    });
  });
}
