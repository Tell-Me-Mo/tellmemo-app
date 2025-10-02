import 'package:flutter/material.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/constants/layout_constants.dart';
import '../../../core/utils/responsive_utils.dart';

class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? mobilePadding;
  final EdgeInsetsGeometry? tabletPadding;
  final EdgeInsetsGeometry? desktopPadding;
  final EdgeInsetsGeometry? largePadding;
  final BoxConstraints? constraints;
  final BoxDecoration? decoration;
  final AlignmentGeometry? alignment;
  final double? width;
  final double? height;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const AdaptiveContainer({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.largePadding,
    this.constraints,
    this.decoration,
    this.alignment,
    this.width,
    this.height,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, layoutConstraints) {
        final width = layoutConstraints.maxWidth;
        final padding = _getResponsivePadding(width);

        return Container(
          width: this.width,
          height: height,
          constraints: constraints,
          decoration: decoration,
          color: color,
          alignment: alignment,
          margin: margin,
          padding: padding,
          child: child,
        );
      },
    );
  }

  EdgeInsetsGeometry _getResponsivePadding(double width) {
    if (Breakpoints.isLargeScreen(width)) {
      return largePadding ?? 
             desktopPadding ?? 
             const EdgeInsets.all(LayoutConstants.desktopPadding);
    } else if (Breakpoints.isDesktop(width)) {
      return desktopPadding ?? 
             const EdgeInsets.all(LayoutConstants.desktopPadding);
    } else if (Breakpoints.isTablet(width)) {
      return tabletPadding ?? 
             const EdgeInsets.all(LayoutConstants.tabletPadding);
    } else {
      return mobilePadding ?? 
             const EdgeInsets.all(LayoutConstants.mobilePadding);
    }
  }
}

class AdaptivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? mobilePadding;
  final EdgeInsetsGeometry? tabletPadding;
  final EdgeInsetsGeometry? desktopPadding;
  final EdgeInsetsGeometry? largePadding;

  const AdaptivePadding({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.largePadding,
  });

  factory AdaptivePadding.all({
    Key? key,
    required Widget child,
    double mobile = LayoutConstants.mobilePadding,
    double? tablet,
    double? desktop,
    double? large,
  }) {
    return AdaptivePadding(
      key: key,
      mobilePadding: EdgeInsets.all(mobile),
      tabletPadding: tablet != null ? EdgeInsets.all(tablet) : null,
      desktopPadding: desktop != null ? EdgeInsets.all(desktop) : null,
      largePadding: large != null ? EdgeInsets.all(large) : null,
      child: child,
    );
  }

  factory AdaptivePadding.symmetric({
    Key? key,
    required Widget child,
    double mobileHorizontal = LayoutConstants.mobilePadding,
    double mobileVertical = LayoutConstants.mobilePadding,
    double? tabletHorizontal,
    double? tabletVertical,
    double? desktopHorizontal,
    double? desktopVertical,
    double? largeHorizontal,
    double? largeVertical,
  }) {
    return AdaptivePadding(
      key: key,
      mobilePadding: EdgeInsets.symmetric(
        horizontal: mobileHorizontal,
        vertical: mobileVertical,
      ),
      tabletPadding: tabletHorizontal != null || tabletVertical != null
          ? EdgeInsets.symmetric(
              horizontal: tabletHorizontal ?? mobileHorizontal,
              vertical: tabletVertical ?? mobileVertical,
            )
          : null,
      desktopPadding: desktopHorizontal != null || desktopVertical != null
          ? EdgeInsets.symmetric(
              horizontal: desktopHorizontal ?? tabletHorizontal ?? mobileHorizontal,
              vertical: desktopVertical ?? tabletVertical ?? mobileVertical,
            )
          : null,
      largePadding: largeHorizontal != null || largeVertical != null
          ? EdgeInsets.symmetric(
              horizontal: largeHorizontal ?? desktopHorizontal ?? tabletHorizontal ?? mobileHorizontal,
              vertical: largeVertical ?? desktopVertical ?? tabletVertical ?? mobileVertical,
            )
          : null,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = ResponsiveUtils.getScreenWidth(context);
    final padding = _getResponsivePadding(width);

    return Padding(
      padding: padding,
      child: child,
    );
  }

  EdgeInsetsGeometry _getResponsivePadding(double width) {
    if (Breakpoints.isLargeScreen(width)) {
      return largePadding ?? 
             desktopPadding ?? 
             tabletPadding ?? 
             mobilePadding ?? 
             const EdgeInsets.all(LayoutConstants.desktopPadding);
    } else if (Breakpoints.isDesktop(width)) {
      return desktopPadding ?? 
             tabletPadding ?? 
             mobilePadding ?? 
             const EdgeInsets.all(LayoutConstants.desktopPadding);
    } else if (Breakpoints.isTablet(width)) {
      return tabletPadding ?? 
             mobilePadding ?? 
             const EdgeInsets.all(LayoutConstants.tabletPadding);
    } else {
      return mobilePadding ?? 
             const EdgeInsets.all(LayoutConstants.mobilePadding);
    }
  }
}