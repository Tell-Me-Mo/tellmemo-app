import 'package:flutter/material.dart';
import '../constants/breakpoints.dart';

enum ScreenType { mobile, tablet, desktop, large }

enum OrientationType { portrait, landscape }

class ScreenInfo {
  final Size screenSize;
  final ScreenType screenType;
  final OrientationType orientation;
  final EdgeInsets safeAreaPadding;
  final double pixelRatio;
  final TextScaler textScaler;

  const ScreenInfo({
    required this.screenSize,
    required this.screenType,
    required this.orientation,
    required this.safeAreaPadding,
    required this.pixelRatio,
    required this.textScaler,
  });

  factory ScreenInfo.fromContext(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    
    return ScreenInfo(
      screenSize: mediaQuery.size,
      screenType: _getScreenType(width),
      orientation: mediaQuery.orientation == Orientation.portrait
          ? OrientationType.portrait
          : OrientationType.landscape,
      safeAreaPadding: mediaQuery.padding,
      pixelRatio: mediaQuery.devicePixelRatio,
      textScaler: mediaQuery.textScaler,
    );
  }

  static ScreenType _getScreenType(double width) {
    if (width < Breakpoints.mobile) return ScreenType.mobile;
    if (width < Breakpoints.desktop) return ScreenType.tablet;
    if (width < Breakpoints.large) return ScreenType.desktop;
    return ScreenType.large;
  }

  bool get isMobile => screenType == ScreenType.mobile;
  bool get isTablet => screenType == ScreenType.tablet;
  bool get isDesktop => screenType == ScreenType.desktop;
  bool get isLarge => screenType == ScreenType.large;
  
  bool get isPortrait => orientation == OrientationType.portrait;
  bool get isLandscape => orientation == OrientationType.landscape;
  
  bool get isSmallScreen => isMobile || (isTablet && isPortrait);
  bool get isLargeScreen => isDesktop || isLarge;
  
  double get width => screenSize.width;
  double get height => screenSize.height;
  double get aspectRatio => width / height;
  
  bool get hasNotch => safeAreaPadding.top > 20;
  bool get hasBottomSafeArea => safeAreaPadding.bottom > 0;
  
  double getResponsiveValue({
    required double mobile,
    double? tablet,
    double? desktop,
    double? large,
  }) {
    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenType.large:
        return large ?? desktop ?? tablet ?? mobile;
    }
  }

  T getResponsiveWidget<T extends Widget>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? large,
  }) {
    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenType.large:
        return large ?? desktop ?? tablet ?? mobile;
    }
  }
}