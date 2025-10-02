import 'package:flutter/material.dart';
import '../../../../core/widgets/loading/skeleton_loader.dart';

class DocumentSkeletonLoader extends StatelessWidget {
  const DocumentSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (index) => _buildSkeletonItem(context)),
    );
  }

  Widget _buildSkeletonItem(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonLoader(
                width: 44,
                height: 44,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: screenWidth * 0.4,
                      height: 18,
                    ),
                    const SizedBox(height: 8),
                    SkeletonLoader(
                      width: screenWidth * 0.25,
                      height: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SkeletonLoader(
            width: screenWidth * 0.8,
            height: 14,
          ),
          const SizedBox(height: 4),
          SkeletonLoader(
            width: screenWidth * 0.6,
            height: 14,
          ),
        ],
      ),
    );
  }
}