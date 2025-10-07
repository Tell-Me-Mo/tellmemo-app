import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/core/constants/layout_constants.dart';

void main() {
  group('LayoutConstants', () {
    group('spacing values', () {
      test('spacingXs is 4.0', () {
        expect(LayoutConstants.spacingXs, 4.0);
      });

      test('spacingSm is 8.0', () {
        expect(LayoutConstants.spacingSm, 8.0);
      });

      test('spacingMd is 16.0', () {
        expect(LayoutConstants.spacingMd, 16.0);
      });

      test('spacingLg is 24.0', () {
        expect(LayoutConstants.spacingLg, 24.0);
      });

      test('spacingXl is 32.0', () {
        expect(LayoutConstants.spacingXl, 32.0);
      });

      test('spacingXxl is 48.0', () {
        expect(LayoutConstants.spacingXxl, 48.0);
      });
    });

    group('spacing aliases', () {
      test('spacingS matches spacingSm', () {
        expect(LayoutConstants.spacingS, LayoutConstants.spacingSm);
      });

      test('spacingM matches spacingMd', () {
        expect(LayoutConstants.spacingM, LayoutConstants.spacingMd);
      });

      test('spacingL matches spacingLg', () {
        expect(LayoutConstants.spacingL, LayoutConstants.spacingLg);
      });
    });

    group('padding values', () {
      test('paddingSmall is 8.0', () {
        expect(LayoutConstants.paddingSmall, 8.0);
      });

      test('paddingMedium is 16.0', () {
        expect(LayoutConstants.paddingMedium, 16.0);
      });

      test('paddingLarge is 24.0', () {
        expect(LayoutConstants.paddingLarge, 24.0);
      });
    });

    group('padding aliases', () {
      test('paddingS matches paddingSmall', () {
        expect(LayoutConstants.paddingS, LayoutConstants.paddingSmall);
      });

      test('paddingM matches paddingMedium', () {
        expect(LayoutConstants.paddingM, LayoutConstants.paddingMedium);
      });

      test('paddingL matches paddingLarge', () {
        expect(LayoutConstants.paddingL, LayoutConstants.paddingLarge);
      });
    });

    group('responsive padding', () {
      test('mobilePadding is 16.0', () {
        expect(LayoutConstants.mobilePadding, 16.0);
      });

      test('tabletPadding is 24.0', () {
        expect(LayoutConstants.tabletPadding, 24.0);
      });

      test('desktopPadding is 32.0', () {
        expect(LayoutConstants.desktopPadding, 32.0);
      });

      test('responsive padding aliases match', () {
        expect(LayoutConstants.paddingMobile, LayoutConstants.mobilePadding);
        expect(LayoutConstants.paddingTablet, LayoutConstants.tabletPadding);
        expect(LayoutConstants.paddingDesktop, LayoutConstants.desktopPadding);
      });
    });

    group('card elevation', () {
      test('card elevation values are correct', () {
        expect(LayoutConstants.mobileCardElevation, 1.0);
        expect(LayoutConstants.tabletCardElevation, 2.0);
        expect(LayoutConstants.desktopCardElevation, 3.0);
      });
    });

    group('border radius', () {
      test('border radius values are correct', () {
        expect(LayoutConstants.borderRadiusSm, 4.0);
        expect(LayoutConstants.borderRadiusMd, 8.0);
        expect(LayoutConstants.borderRadiusLg, 16.0);
      });

      test('radius aliases match border radius', () {
        expect(LayoutConstants.radiusSmall, LayoutConstants.borderRadiusSm);
        expect(LayoutConstants.radiusMedium, LayoutConstants.borderRadiusMd);
        expect(LayoutConstants.radiusLarge, LayoutConstants.borderRadiusLg);
      });
    });

    group('icon sizes', () {
      test('icon size values are correct', () {
        expect(LayoutConstants.iconSizeSm, 18.0);
        expect(LayoutConstants.iconSizeMd, 24.0);
        expect(LayoutConstants.iconSizeLg, 32.0);
      });
    });

    group('grid spacing', () {
      test('grid spacing values are correct', () {
        expect(LayoutConstants.mobileGridSpacing, 16.0);
        expect(LayoutConstants.tabletGridSpacing, 20.0);
        expect(LayoutConstants.desktopGridSpacing, 24.0);
      });
    });

    group('navigation and sidebar', () {
      test('navigation rail widths are correct', () {
        expect(LayoutConstants.navigationRailWidth, 72.0);
        expect(LayoutConstants.navigationRailExtendedWidth, 256.0);
      });

      test('sidebar width is 300.0', () {
        expect(LayoutConstants.sidebarWidth, 300.0);
      });
    });

    group('app bar heights', () {
      test('app bar height values are correct', () {
        expect(LayoutConstants.appBarHeightMobile, 56.0);
        expect(LayoutConstants.appBarHeightDesktop, 64.0);
      });
    });

    group('interaction dimensions', () {
      test('minimum interactive dimension is 48.0', () {
        expect(LayoutConstants.minInteractiveDimension, 48.0);
      });
    });
  });
}
