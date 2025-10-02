import 'package:flutter/material.dart';
import '../constants/ui_constants.dart';

class AnimationUtils {
  AnimationUtils._();
  
  // Dialog animations
  static Route<T> slideUpDialogRoute<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      barrierLabel: barrierLabel,
      transitionDuration: UIConstants.normalAnimation,
      reverseTransitionDuration: UIConstants.shortAnimation,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.1);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(
          tween.chain(CurveTween(curve: UIConstants.defaultCurve)),
        );
        
        final fadeAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(
            CurveTween(curve: UIConstants.fadeCurve),
          ),
        );
        
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }
  
  static Route<T> fadeScaleDialogRoute<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      barrierLabel: barrierLabel,
      transitionDuration: UIConstants.normalAnimation,
      reverseTransitionDuration: UIConstants.shortAnimation,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = animation.drive(
          Tween(begin: 0.8, end: 1.0).chain(
            CurveTween(curve: UIConstants.defaultCurve),
          ),
        );
        
        final fadeAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(
            CurveTween(curve: UIConstants.fadeCurve),
          ),
        );
        
        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }
  
  // List item animations
  static Widget buildAnimatedListItem({
    required Widget child,
    required Animation<double> animation,
    bool slideFromRight = false,
  }) {
    final slideAnimation = animation.drive(
      Tween(
        begin: Offset(slideFromRight ? 1.0 : -1.0, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: UIConstants.defaultCurve)),
    );
    
    final fadeAnimation = animation.drive(
      Tween(begin: 0.0, end: 1.0).chain(
        CurveTween(curve: UIConstants.fadeCurve),
      ),
    );
    
    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }
  
  // Staggered animations for lists
  static List<Animation<double>> createStaggeredAnimations({
    required AnimationController controller,
    required int itemCount,
    Duration totalDuration = const Duration(milliseconds: 500),
  }) {
    final animations = <Animation<double>>[];
    final interval = 1.0 / itemCount;
    
    for (int i = 0; i < itemCount; i++) {
      final start = i * interval * 0.5;
      final end = start + interval;
      
      animations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(
              start.clamp(0.0, 1.0),
              end.clamp(0.0, 1.0),
              curve: UIConstants.defaultCurve,
            ),
          ),
        ),
      );
    }
    
    return animations;
  }
}

// Animated expansion widget for tree items
class AnimatedExpansion extends StatefulWidget {
  final bool isExpanded;
  final Widget child;
  final Duration? duration;
  final Curve? curve;
  
  const AnimatedExpansion({
    super.key,
    required this.isExpanded,
    required this.child,
    this.duration,
    this.curve,
  });
  
  @override
  State<AnimatedExpansion> createState() => _AnimatedExpansionState();
}

class _AnimatedExpansionState extends State<AnimatedExpansion>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? UIConstants.normalAnimation,
      vsync: this,
      value: widget.isExpanded ? 1.0 : 0.0,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve ?? UIConstants.defaultCurve,
    );
  }
  
  @override
  void didUpdateWidget(AnimatedExpansion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _expandAnimation,
      axisAlignment: -1.0,
      child: widget.child,
    );
  }
}

// Animated state transition widget
class AnimatedStateTransition extends StatelessWidget {
  final bool showLoading;
  final bool showError;
  final bool showEmpty;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final Widget child;
  final Duration duration;
  
  const AnimatedStateTransition({
    super.key,
    this.showLoading = false,
    this.showError = false,
    this.showEmpty = false,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });
  
  @override
  Widget build(BuildContext context) {
    Widget content = child;
    
    if (showLoading && loadingWidget != null) {
      content = loadingWidget!;
    } else if (showError && errorWidget != null) {
      content = errorWidget!;
    } else if (showEmpty && emptyWidget != null) {
      content = emptyWidget!;
    }
    
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: UIConstants.defaultCurve,
      switchOutCurve: UIConstants.defaultCurve.flipped,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation.drive(
              Tween(begin: 0.95, end: 1.0),
            ),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(content.runtimeType),
        child: content,
      ),
    );
  }
}

// Shimmer loading animation
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Duration? duration;
  
  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
    this.duration,
  });
  
  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? Duration(milliseconds: UIConstants.skeletonShimmerDuration),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));
    
    if (widget.isLoading) {
      _controller.repeat();
    }
  }
  
  @override
  void didUpdateWidget(ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }
    
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                theme.colorScheme.surfaceContainerHighest,
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainerHighest,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}