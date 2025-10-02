import 'package:flutter/material.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/utils/responsive_utils.dart';

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double? spacing;
  final double? runSpacing;
  final EdgeInsetsGeometry? padding;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final int? largeColumns;
  final double childAspectRatio;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing,
    this.runSpacing,
    this.padding,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.largeColumns,
    this.childAspectRatio = 1.0,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
        final gridSpacing = spacing ?? ResponsiveUtils.getResponsiveGridSpacing(context);
        final gridRunSpacing = runSpacing ?? gridSpacing;
        final gridPadding = padding ?? ResponsiveUtils.getResponsivePadding(context);

        return Padding(
          padding: gridPadding,
          child: GridView.builder(
            shrinkWrap: shrinkWrap,
            physics: physics ?? (shrinkWrap ? const NeverScrollableScrollPhysics() : null),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: gridSpacing,
              mainAxisSpacing: gridRunSpacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
          ),
        );
      },
    );
  }

  int _getCrossAxisCount(double width) {
    if (Breakpoints.isLargeScreen(width)) {
      return largeColumns ?? desktopColumns ?? 4;
    } else if (Breakpoints.isDesktop(width)) {
      return desktopColumns ?? 3;
    } else if (Breakpoints.isTablet(width)) {
      return tabletColumns ?? 2;
    } else {
      return mobileColumns ?? 1;
    }
  }
}

class ResponsiveGridItem extends StatelessWidget {
  final Widget child;
  final int? columnSpan;
  final int? rowSpan;

  const ResponsiveGridItem({
    super.key,
    required this.child,
    this.columnSpan,
    this.rowSpan,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}