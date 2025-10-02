import 'package:flutter/material.dart';
import '../../../../core/constants/layout_constants.dart';

class UploadProgressCard extends StatelessWidget {
  final double progress;
  final VoidCallback onCancel;
  final String fileName;

  const UploadProgressCard({
    super.key,
    required this.progress,
    required this.onCancel,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (progress * 100).toInt();

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(LayoutConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.upload_file, size: 20),
                const SizedBox(width: LayoutConstants.spacingSm),
                Expanded(
                  child: Text(
                    'Uploading $fileName',
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onCancel,
                  tooltip: 'Cancel upload',
                ),
              ],
            ),
            const SizedBox(height: LayoutConstants.spacingMd),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: LayoutConstants.spacingSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$percentage%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  _getStatusText(percentage),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(int percentage) {
    if (percentage < 30) return 'Preparing...';
    if (percentage < 60) return 'Uploading...';
    if (percentage < 90) return 'Processing...';
    if (percentage < 100) return 'Almost done...';
    return 'Complete!';
  }
}