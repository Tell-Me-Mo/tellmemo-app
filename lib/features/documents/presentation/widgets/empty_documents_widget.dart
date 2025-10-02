import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/layout_constants.dart';

class EmptyDocumentsWidget extends StatelessWidget {
  const EmptyDocumentsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open,
                size: 64,
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: LayoutConstants.spacingLg),
            Text(
              'No Documents Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: LayoutConstants.spacingSm),
            Text(
              'Upload documents or emails to get started',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LayoutConstants.spacingXl),
            FilledButton.icon(
              onPressed: () {
                context.go('/upload');
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Your First Document'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}