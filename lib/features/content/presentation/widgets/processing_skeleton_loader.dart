import 'package:flutter/material.dart';

class ProcessingSkeletonLoader extends StatefulWidget {
  final bool isDocument;
  final String? title;

  const ProcessingSkeletonLoader({
    super.key,
    this.isDocument = true,
    this.title,
  });

  @override
  State<ProcessingSkeletonLoader> createState() => _ProcessingSkeletonLoaderState();
}

class _ProcessingSkeletonLoaderState extends State<ProcessingSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (widget.isDocument) {
      return _buildDocumentSkeleton(colorScheme, textTheme);
    } else {
      return _buildSummarySkeleton(colorScheme, textTheme);
    }
  }

  Widget _buildDocumentSkeleton(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Icon with animation - matching document card style
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                width: 34,
                height: 34,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withValues(alpha: 0.1),
                      Colors.blue.withValues(alpha: 0.2),
                      Colors.blue.withValues(alpha: 0.1),
                    ],
                    stops: [
                      0.0,
                      (_animation.value + 1) / 3,
                      1.0,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 18,
                  color: Colors.blue.withValues(alpha: 0.5),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Container(
                      height: 14,
                      width: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            colorScheme.surfaceContainerHighest,
                            colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          ],
                          stops: [
                            0.0,
                            (_animation.value + 1) / 3,
                            1.0,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                // Processing status text
                Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Processing document...',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.blue.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySkeleton(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Icon with animation
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Icon(
                Icons.auto_awesome_outlined,
                size: 18,
                color: Colors.purple.withValues(alpha: 0.5),
              );
            },
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Container(
                      height: 14,
                      width: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            colorScheme.surfaceContainerHighest,
                            colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          ],
                          stops: [
                            0.0,
                            (_animation.value + 1) / 3,
                            1.0,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                // Status text
                Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.purple.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Generating summary...',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.purple.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Format badge skeleton
          Container(
            width: 50,
            height: 18,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}