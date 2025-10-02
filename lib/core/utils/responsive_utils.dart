import 'package:flutter/material.dart';
import '../constants/breakpoints.dart';
import '../constants/layout_constants.dart';

class ResponsiveUtils {
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.sizeOf(context);
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  static double getResponsiveValue({
    required BuildContext context,
    required double mobile,
    double? tablet,
    double? desktop,
    double? large,
  }) {
    final width = getScreenWidth(context);
    
    if (Breakpoints.isLargeScreen(width)) {
      return large ?? desktop ?? tablet ?? mobile;
    } else if (Breakpoints.isDesktop(width)) {
      return desktop ?? tablet ?? mobile;
    } else if (Breakpoints.isTablet(width)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = getScreenWidth(context);
    
    if (Breakpoints.isDesktop(width)) {
      return const EdgeInsets.all(LayoutConstants.desktopPadding);
    } else if (Breakpoints.isTablet(width)) {
      return const EdgeInsets.all(LayoutConstants.tabletPadding);
    } else {
      return const EdgeInsets.all(LayoutConstants.mobilePadding);
    }
  }

  static EdgeInsets getResponsiveMargin(BuildContext context) {
    final width = getScreenWidth(context);
    
    if (Breakpoints.isDesktop(width)) {
      return const EdgeInsets.symmetric(
        horizontal: LayoutConstants.spacingXl,
        vertical: LayoutConstants.spacingLg,
      );
    } else if (Breakpoints.isTablet(width)) {
      return const EdgeInsets.symmetric(
        horizontal: LayoutConstants.spacingLg,
        vertical: LayoutConstants.spacingMd,
      );
    } else {
      return const EdgeInsets.symmetric(
        horizontal: LayoutConstants.spacingMd,
        vertical: LayoutConstants.spacingSm,
      );
    }
  }

  static double getResponsiveText(BuildContext context, double baseSize) {
    final width = getScreenWidth(context);
    
    if (Breakpoints.isLargeScreen(width)) {
      return baseSize * 1.2;
    } else if (Breakpoints.isDesktop(width)) {
      return baseSize * 1.1;
    } else if (Breakpoints.isTablet(width)) {
      return baseSize * 1.05;
    } else {
      return baseSize;
    }
  }

  static double getResponsiveGridSpacing(BuildContext context) {
    final width = getScreenWidth(context);
    
    if (Breakpoints.isDesktop(width)) {
      return LayoutConstants.desktopGridSpacing;
    } else if (Breakpoints.isTablet(width)) {
      return LayoutConstants.tabletGridSpacing;
    } else {
      return LayoutConstants.mobileGridSpacing;
    }
  }

  static int getResponsiveGridColumns(BuildContext context) {
    final width = getScreenWidth(context);
    return Breakpoints.getGridColumns(width);
  }

  static double getResponsiveContentWidth(BuildContext context) {
    final width = getScreenWidth(context);
    return Breakpoints.getContentMaxWidth(width);
  }

  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.paddingOf(context);
  }

  static Orientation getOrientation(BuildContext context) {
    return MediaQuery.orientationOf(context);
  }

  static bool isLandscape(BuildContext context) {
    return getOrientation(context) == Orientation.landscape;
  }

  static bool isPortrait(BuildContext context) {
    return getOrientation(context) == Orientation.portrait;
  }
  
  static bool isDesktop(BuildContext context) {
    final width = getScreenWidth(context);
    return Breakpoints.isDesktop(width);
  }
  
  static bool isTablet(BuildContext context) {
    final width = getScreenWidth(context);
    return Breakpoints.isTablet(width);
  }
  
  static bool isMobile(BuildContext context) {
    final width = getScreenWidth(context);
    return Breakpoints.isMobile(width);
  }

  static double getAspectRatio(BuildContext context) {
    final size = getScreenSize(context);
    return size.width / size.height;
  }
}