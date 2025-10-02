import 'package:flutter/material.dart';

class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 840;
  static const double desktop = 1200;
  static const double large = 1600;

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < desktop;
  static bool isDesktop(double width) => width >= desktop && width < large;
  static bool isLargeScreen(double width) => width >= large;

  static String getBreakpoint(double width) {
    if (width < mobile) return 'mobile';
    if (width < desktop) return 'tablet';
    if (width < large) return 'desktop';
    return 'large';
  }

  static int getGridColumns(double width) {
    if (width < mobile) return 4;
    if (width < desktop) return 8;
    if (width < large) return 12;
    return 12;
  }

  static double getContentMaxWidth(double width) {
    if (width < mobile) return width;
    if (width < desktop) return width * 0.9;
    if (width < large) return 1200;
    return 1400;
  }
}

class ResponsiveBreakpoint {
  static String getBreakpoint(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Breakpoints.getBreakpoint(width);
  }

  static bool isMobile(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Breakpoints.isMobile(width);
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Breakpoints.isTablet(width);
  }

  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Breakpoints.isDesktop(width);
  }

  static bool isLargeScreen(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Breakpoints.isLargeScreen(width);
  }
}