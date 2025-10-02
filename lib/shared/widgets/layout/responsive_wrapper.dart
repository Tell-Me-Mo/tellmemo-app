import 'package:flutter/material.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/utils/screen_info.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double? maxContentWidth;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxContentWidth,
    this.alignment = Alignment.topCenter,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenInfo = ScreenInfo.fromContext(context);
    final contentMaxWidth = maxContentWidth ?? 
        Breakpoints.getContentMaxWidth(screenInfo.width);

    return Container(
      color: backgroundColor,
      alignment: alignment,
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth),
        child: child,
      ),
    );
  }
}