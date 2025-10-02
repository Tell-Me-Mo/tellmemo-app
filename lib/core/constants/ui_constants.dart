import 'package:flutter/material.dart';

class UIConstants {
  UIConstants._();
  
  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  
  // Dialog sizes
  static const double dialogMinWidth = 320;
  static const double dialogMaxWidth = 560;
  static const double dialogMobileWidthFactor = 0.9;
  static const double dialogTabletWidthFactor = 0.7;
  static const double dialogDesktopWidthFactor = 0.5;
  
  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Animation curves
  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve fadeCurve = Curves.easeIn;
  
  // Selection visual
  static const double selectionOpacity = 0.12;
  static const double selectionHoverOpacity = 0.08;
  static const double selectionBorderWidth = 2.0;
  
  // Loading states
  static const int skeletonShimmerDuration = 1500; // milliseconds
  static const double skeletonOpacity = 0.1;
  
  // Search
  static const int searchDebounceMilliseconds = 300;
  static const int maxSearchSuggestions = 5;
  static const int minSearchLength = 2;
}

class ResponsiveUtils {
  ResponsiveUtils._();
  
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < UIConstants.mobileBreakpoint;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= UIConstants.mobileBreakpoint && 
           width < UIConstants.tabletBreakpoint;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= UIConstants.tabletBreakpoint;
  }
  
  static double getDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (isMobile(context)) {
      return (screenWidth * UIConstants.dialogMobileWidthFactor)
          .clamp(UIConstants.dialogMinWidth, UIConstants.dialogMaxWidth);
    } else if (isTablet(context)) {
      return (screenWidth * UIConstants.dialogTabletWidthFactor)
          .clamp(UIConstants.dialogMinWidth, UIConstants.dialogMaxWidth);
    } else {
      return UIConstants.dialogMaxWidth;
    }
  }
  
  static EdgeInsets getDialogPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(20);
    } else {
      return const EdgeInsets.all(24);
    }
  }
  
  static double getIconSize(BuildContext context) {
    if (isMobile(context)) {
      return 20;
    } else if (isTablet(context)) {
      return 22;
    } else {
      return 24;
    }
  }
}

class SelectionColors {
  SelectionColors._();
  
  static Color getSelectionColor(BuildContext context, {bool isHovered = false}) {
    final theme = Theme.of(context);
    final opacity = isHovered 
        ? UIConstants.selectionHoverOpacity 
        : UIConstants.selectionOpacity;
    return theme.colorScheme.primary.withValues(alpha: opacity);
  }
  
  static Color getSelectionBorderColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }
  
  static Color getItemTypeColor(BuildContext context, String itemType) {
    final theme = Theme.of(context);
    switch (itemType.toLowerCase()) {
      case 'portfolio':
        return theme.colorScheme.primary;
      case 'program':
        return theme.colorScheme.tertiary;
      case 'project':
        return theme.colorScheme.secondary;
      default:
        return theme.colorScheme.onSurface;
    }
  }
}