import 'package:flutter/material.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/utils/screen_info.dart';

class BreakpointBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenInfo screenInfo) builder;

  const BreakpointBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenInfo = ScreenInfo.fromContext(context);
        return builder(context, screenInfo);
      },
    );
  }
}

class ConditionalBreakpoint extends StatelessWidget {
  final Widget child;
  final bool showOnMobile;
  final bool showOnTablet;
  final bool showOnDesktop;
  final bool showOnLarge;
  final Widget? fallback;

  const ConditionalBreakpoint({
    super.key,
    required this.child,
    this.showOnMobile = true,
    this.showOnTablet = true,
    this.showOnDesktop = true,
    this.showOnLarge = true,
    this.fallback,
  });

  factory ConditionalBreakpoint.mobileOnly({
    Key? key,
    required Widget child,
    Widget? fallback,
  }) {
    return ConditionalBreakpoint(
      key: key,
      showOnMobile: true,
      showOnTablet: false,
      showOnDesktop: false,
      showOnLarge: false,
      fallback: fallback,
      child: child,
    );
  }

  factory ConditionalBreakpoint.desktopOnly({
    Key? key,
    required Widget child,
    Widget? fallback,
  }) {
    return ConditionalBreakpoint(
      key: key,
      showOnMobile: false,
      showOnTablet: false,
      showOnDesktop: true,
      showOnLarge: true,
      fallback: fallback,
      child: child,
    );
  }

  factory ConditionalBreakpoint.tabletAndUp({
    Key? key,
    required Widget child,
    Widget? fallback,
  }) {
    return ConditionalBreakpoint(
      key: key,
      showOnMobile: false,
      showOnTablet: true,
      showOnDesktop: true,
      showOnLarge: true,
      fallback: fallback,
      child: child,
    );
  }

  factory ConditionalBreakpoint.mobileAndTablet({
    Key? key,
    required Widget child,
    Widget? fallback,
  }) {
    return ConditionalBreakpoint(
      key: key,
      showOnMobile: true,
      showOnTablet: true,
      showOnDesktop: false,
      showOnLarge: false,
      fallback: fallback,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        bool shouldShow = false;

        if (Breakpoints.isMobile(width) && showOnMobile) {
          shouldShow = true;
        } else if (Breakpoints.isTablet(width) && showOnTablet) {
          shouldShow = true;
        } else if (Breakpoints.isDesktop(width) && showOnDesktop) {
          shouldShow = true;
        } else if (Breakpoints.isLargeScreen(width) && showOnLarge) {
          shouldShow = true;
        }

        if (shouldShow) {
          return child;
        } else if (fallback != null) {
          return fallback!;
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}