import 'package:flutter/material.dart';
import '../../../core/constants/breakpoints.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  final Widget? large;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.large,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        if (Breakpoints.isLargeScreen(width)) {
          return large ?? desktop;
        } else if (Breakpoints.isDesktop(width)) {
          return desktop;
        } else if (Breakpoints.isTablet(width)) {
          return tablet ?? desktop;
        } else {
          return mobile;
        }
      },
    );
  }
}