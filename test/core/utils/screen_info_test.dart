import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/core/utils/screen_info.dart';

void main() {
  group('ScreenType enum', () {
    test('has all expected values', () {
      expect(ScreenType.values, [
        ScreenType.mobile,
        ScreenType.tablet,
        ScreenType.desktop,
        ScreenType.large,
      ]);
    });
  });

  group('OrientationType enum', () {
    test('has all expected values', () {
      expect(OrientationType.values, [
        OrientationType.portrait,
        OrientationType.landscape,
      ]);
    });
  });

  group('ScreenInfo', () {
    Widget buildTestWidget({
      required double width,
      required double height,
      Orientation orientation = Orientation.portrait,
      EdgeInsets padding = EdgeInsets.zero,
      double pixelRatio = 1.0,
      double textScaleFactor = 1.0,
      required Widget Function(BuildContext) builder,
    }) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, height),
            devicePixelRatio: pixelRatio,
            textScaler: TextScaler.linear(textScaleFactor),
            padding: padding,
          ).copyWith(
            // Set orientation explicitly
            size: orientation == Orientation.portrait
                ? Size(width, height)
                : Size(height, width),
          ),
          child: Builder(builder: builder),
        ),
      );
    }

    group('fromContext factory', () {
      testWidgets('creates ScreenInfo with correct mobile screen type', (tester) async {
        ScreenInfo? info;

        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            builder: (context) {
              info = ScreenInfo.fromContext(context);
              return const SizedBox();
            },
          ),
        );

        expect(info?.screenType, ScreenType.mobile);
        expect(info?.screenSize, const Size(400, 800));
      });

      testWidgets('creates ScreenInfo with correct tablet screen type', (tester) async {
        ScreenInfo? info;

        await tester.pumpWidget(
          buildTestWidget(
            width: 700,
            height: 1000,
            builder: (context) {
              info = ScreenInfo.fromContext(context);
              return const SizedBox();
            },
          ),
        );

        expect(info?.screenType, ScreenType.tablet);
      });

      testWidgets('creates ScreenInfo with correct desktop screen type', (tester) async {
        ScreenInfo? info;

        await tester.pumpWidget(
          buildTestWidget(
            width: 1300,
            height: 900,
            builder: (context) {
              info = ScreenInfo.fromContext(context);
              return const SizedBox();
            },
          ),
        );

        expect(info?.screenType, ScreenType.desktop);
      });

      testWidgets('creates ScreenInfo with correct large screen type', (tester) async {
        ScreenInfo? info;

        await tester.pumpWidget(
          buildTestWidget(
            width: 1700,
            height: 1000,
            builder: (context) {
              info = ScreenInfo.fromContext(context);
              return const SizedBox();
            },
          ),
        );

        expect(info?.screenType, ScreenType.large);
      });

      testWidgets('captures orientation correctly for portrait', (tester) async {
        ScreenInfo? info;

        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            orientation: Orientation.portrait,
            builder: (context) {
              info = ScreenInfo.fromContext(context);
              return const SizedBox();
            },
          ),
        );

        expect(info?.orientation, OrientationType.portrait);
      });

      testWidgets('captures safe area padding', (tester) async {
        ScreenInfo? info;

        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            padding: const EdgeInsets.only(top: 44, bottom: 34),
            builder: (context) {
              info = ScreenInfo.fromContext(context);
              return const SizedBox();
            },
          ),
        );

        expect(info?.safeAreaPadding, const EdgeInsets.only(top: 44, bottom: 34));
      });

      testWidgets('captures pixel ratio', (tester) async {
        ScreenInfo? info;

        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            pixelRatio: 2.0,
            builder: (context) {
              info = ScreenInfo.fromContext(context);
              return const SizedBox();
            },
          ),
        );

        expect(info?.pixelRatio, 2.0);
      });

      testWidgets('captures text scaler', (tester) async {
        ScreenInfo? info;

        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            textScaleFactor: 1.5,
            builder: (context) {
              info = ScreenInfo.fromContext(context);
              return const SizedBox();
            },
          ),
        );

        expect(info?.textScaler.scale(10), 15.0);
      });
    });

    group('boolean getters for screen type', () {
      test('isMobile returns true for mobile screen type', () {
        final info = ScreenInfo(
          screenSize: const Size(400, 800),
          screenType: ScreenType.mobile,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.isMobile, isTrue);
        expect(info.isTablet, isFalse);
        expect(info.isDesktop, isFalse);
        expect(info.isLarge, isFalse);
      });

      test('isTablet returns true for tablet screen type', () {
        final info = ScreenInfo(
          screenSize: const Size(700, 1000),
          screenType: ScreenType.tablet,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.isTablet, isTrue);
        expect(info.isMobile, isFalse);
      });

      test('isDesktop returns true for desktop screen type', () {
        final info = ScreenInfo(
          screenSize: const Size(1300, 900),
          screenType: ScreenType.desktop,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.isDesktop, isTrue);
        expect(info.isMobile, isFalse);
      });

      test('isLarge returns true for large screen type', () {
        final info = ScreenInfo(
          screenSize: const Size(1700, 1000),
          screenType: ScreenType.large,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.isLarge, isTrue);
        expect(info.isMobile, isFalse);
      });
    });

    group('boolean getters for orientation', () {
      test('isPortrait returns true for portrait orientation', () {
        final info = ScreenInfo(
          screenSize: const Size(400, 800),
          screenType: ScreenType.mobile,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.isPortrait, isTrue);
        expect(info.isLandscape, isFalse);
      });

      test('isLandscape returns true for landscape orientation', () {
        final info = ScreenInfo(
          screenSize: const Size(800, 400),
          screenType: ScreenType.mobile,
          orientation: OrientationType.landscape,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.isLandscape, isTrue);
        expect(info.isPortrait, isFalse);
      });
    });

    group('screen size helpers', () {
      test('isSmallScreen returns true for mobile', () {
        final info = ScreenInfo(
          screenSize: const Size(400, 800),
          screenType: ScreenType.mobile,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.isSmallScreen, isTrue);
        expect(info.isLargeScreen, isFalse);
      });

      test('isSmallScreen returns true for tablet in portrait', () {
        final info = ScreenInfo(
          screenSize: const Size(700, 1000),
          screenType: ScreenType.tablet,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.isSmallScreen, isTrue);
      });

      test('isSmallScreen returns false for tablet in landscape', () {
        final info = ScreenInfo(
          screenSize: const Size(1000, 700),
          screenType: ScreenType.tablet,
          orientation: OrientationType.landscape,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.isSmallScreen, isFalse);
      });

      test('isLargeScreen returns true for desktop and large screens', () {
        final desktopInfo = ScreenInfo(
          screenSize: const Size(1300, 900),
          screenType: ScreenType.desktop,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        final largeInfo = ScreenInfo(
          screenSize: const Size(1700, 1000),
          screenType: ScreenType.large,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(desktopInfo.isLargeScreen, isTrue);
        expect(largeInfo.isLargeScreen, isTrue);
      });
    });

    group('size getters', () {
      test('width returns screen width', () {
        final info = ScreenInfo(
          screenSize: const Size(400, 800),
          screenType: ScreenType.mobile,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.width, 400);
      });

      test('height returns screen height', () {
        final info = ScreenInfo(
          screenSize: const Size(400, 800),
          screenType: ScreenType.mobile,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.height, 800);
      });

      test('aspectRatio returns width/height ratio', () {
        final info = ScreenInfo(
          screenSize: const Size(400, 800),
          screenType: ScreenType.mobile,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.aspectRatio, 0.5);
      });
    });

    group('safe area detection', () {
      test('hasNotch returns true when top padding > 20', () {
        final info = ScreenInfo(
          screenSize: const Size(400, 800),
          screenType: ScreenType.mobile,
          orientation: OrientationType.portrait,
          safeAreaPadding: const EdgeInsets.only(top: 44),
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.hasNotch, isTrue);
      });

      test('hasNotch returns false when top padding <= 20', () {
        final info = ScreenInfo(
          screenSize: const Size(400, 800),
          screenType: ScreenType.mobile,
          orientation: OrientationType.portrait,
          safeAreaPadding: const EdgeInsets.only(top: 20),
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.hasNotch, isFalse);
      });

      test('hasBottomSafeArea returns true when bottom padding > 0', () {
        final info = ScreenInfo(
          screenSize: const Size(400, 800),
          screenType: ScreenType.mobile,
          orientation: OrientationType.portrait,
          safeAreaPadding: const EdgeInsets.only(bottom: 34),
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.hasBottomSafeArea, isTrue);
      });

      test('hasBottomSafeArea returns false when bottom padding is 0', () {
        final info = ScreenInfo(
          screenSize: const Size(400, 800),
          screenType: ScreenType.mobile,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.hasBottomSafeArea, isFalse);
      });
    });

    group('getResponsiveValue', () {
      test('returns mobile value for mobile screen', () {
        final info = ScreenInfo(
          screenSize: const Size(400, 800),
          screenType: ScreenType.mobile,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.getResponsiveValue(mobile: 10, tablet: 20, desktop: 30), 10);
      });

      test('returns tablet value for tablet screen', () {
        final info = ScreenInfo(
          screenSize: const Size(700, 1000),
          screenType: ScreenType.tablet,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.getResponsiveValue(mobile: 10, tablet: 20, desktop: 30), 20);
      });

      test('returns desktop value for desktop screen', () {
        final info = ScreenInfo(
          screenSize: const Size(1300, 900),
          screenType: ScreenType.desktop,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.getResponsiveValue(mobile: 10, tablet: 20, desktop: 30), 30);
      });

      test('returns large value for large screen', () {
        final info = ScreenInfo(
          screenSize: const Size(1700, 1000),
          screenType: ScreenType.large,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.getResponsiveValue(mobile: 10, tablet: 20, desktop: 30, large: 40), 40);
      });

      test('falls back to mobile when tablet not provided', () {
        final info = ScreenInfo(
          screenSize: const Size(700, 1000),
          screenType: ScreenType.tablet,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.getResponsiveValue(mobile: 10, desktop: 30), 10);
      });

      test('falls back to desktop when large not provided', () {
        final info = ScreenInfo(
          screenSize: const Size(1700, 1000),
          screenType: ScreenType.large,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        expect(info.getResponsiveValue(mobile: 10, tablet: 20, desktop: 30), 30);
      });
    });

    group('getResponsiveWidget', () {
      test('returns mobile widget for mobile screen', () {
        final info = ScreenInfo(
          screenSize: const Size(400, 800),
          screenType: ScreenType.mobile,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        final mobileWidget = Container(key: const Key('mobile'));
        final tabletWidget = Container(key: const Key('tablet'));

        final result = info.getResponsiveWidget(
          mobile: mobileWidget,
          tablet: tabletWidget,
        );

        expect(result, mobileWidget);
      });

      test('returns tablet widget for tablet screen', () {
        final info = ScreenInfo(
          screenSize: const Size(700, 1000),
          screenType: ScreenType.tablet,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        final mobileWidget = Container(key: const Key('mobile'));
        final tabletWidget = Container(key: const Key('tablet'));

        final result = info.getResponsiveWidget(
          mobile: mobileWidget,
          tablet: tabletWidget,
        );

        expect(result, tabletWidget);
      });

      test('falls back to mobile when tablet widget not provided', () {
        final info = ScreenInfo(
          screenSize: const Size(700, 1000),
          screenType: ScreenType.tablet,
          orientation: OrientationType.portrait,
          safeAreaPadding: EdgeInsets.zero,
          pixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
        );

        final mobileWidget = Container(key: const Key('mobile'));

        final result = info.getResponsiveWidget(mobile: mobileWidget);

        expect(result, mobileWidget);
      });
    });
  });
}
