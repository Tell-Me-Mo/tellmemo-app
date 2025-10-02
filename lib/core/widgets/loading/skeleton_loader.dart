import 'package:flutter/material.dart';
import '../../constants/ui_constants.dart';

class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;
  final bool isCircle;
  
  const SkeletonLoader({
    super.key,
    this.width,
    this.height = 20,
    this.borderRadius,
    this.margin,
    this.isCircle = false,
  });
  
  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: UIConstants.skeletonShimmerDuration),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest;
    final highlightColor = theme.colorScheme.surface;
    
    return Container(
      margin: widget.margin,
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.isCircle ? null : (widget.borderRadius ?? BorderRadius.circular(4)),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: widget.isCircle ? null : (widget.borderRadius ?? BorderRadius.circular(4)),
              gradient: LinearGradient(
                begin: Alignment(_animation.value - 1, 0),
                end: Alignment(_animation.value + 1, 0),
                colors: [
                  baseColor,
                  highlightColor,
                  baseColor,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  final bool hasLeading;
  final bool hasTrailing;
  final bool hasSubtitle;
  final EdgeInsetsGeometry? padding;
  
  const SkeletonListTile({
    super.key,
    this.hasLeading = true,
    this.hasTrailing = false,
    this.hasSubtitle = true,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (hasLeading) ...[
            const SkeletonLoader(
              width: 40,
              height: 40,
              isCircle: true,
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: 16,
                ),
                if (hasSubtitle) ...[
                  const SizedBox(height: 4),
                  SkeletonLoader(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 14,
                  ),
                ],
              ],
            ),
          ),
          if (hasTrailing) ...[
            const SizedBox(width: 16),
            const SkeletonLoader(
              width: 24,
              height: 24,
            ),
          ],
        ],
      ),
    );
  }
}

class SkeletonTreeItem extends StatelessWidget {
  final int indentLevel;
  final bool hasChildren;
  
  const SkeletonTreeItem({
    super.key,
    this.indentLevel = 0,
    this.hasChildren = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.0 + (indentLevel * 24.0),
        right: 16.0,
        top: 4.0,
        bottom: 4.0,
      ),
      child: Row(
        children: [
          if (hasChildren) ...[
            const SkeletonLoader(
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
          ],
          const SkeletonLoader(
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SkeletonLoader(
              width: MediaQuery.of(context).size.width * 0.3,
              height: 16,
            ),
          ),
          const SizedBox(width: 16),
          const SkeletonLoader(
            width: 60,
            height: 14,
          ),
        ],
      ),
    );
  }
}