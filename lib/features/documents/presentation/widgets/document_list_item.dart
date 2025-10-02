import 'package:flutter/material.dart';
import '../../../../core/utils/datetime_utils.dart';
import '../../../meetings/domain/entities/content.dart';

class DocumentListItem extends StatelessWidget {
  final Content document;
  final VoidCallback onTap;

  const DocumentListItem({
    super.key,
    required this.document,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final date = document.date ?? document.uploadedAt;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCompactTypeIcon(document.contentType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            document.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateTimeUtils.formatTimeAgo(date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildCompactMetadata(document, theme, colorScheme),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (document.isProcessing)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary.withValues(alpha: 0.6),
                  ),
                )
              else if (document.hasError)
                Icon(
                  Icons.error_outline,
                  color: colorScheme.error.withValues(alpha: 0.6),
                  size: 14,
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  size: 14,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTypeIcon(ContentType type) {
    Color iconColor;
    IconData icon;

    switch (type) {
      case ContentType.meeting:
        iconColor = Colors.blue.shade600;
        icon = Icons.videocam;
        break;
      case ContentType.email:
        iconColor = Colors.orange.shade600;
        icon = Icons.email;
        break;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        color: iconColor.withValues(alpha: 0.9),
        size: 18,
      ),
    );
  }

  Widget _buildCompactMetadata(Content doc, ThemeData theme, ColorScheme colorScheme) {
    final items = <Widget>[];

    // Add type badge
    items.add(_buildCompactBadge(
      doc.typeLabel,
      colorScheme.primary.withValues(alpha: 0.1),
      colorScheme.primary,
      theme,
    ));

    // Add processing status
    if (doc.isProcessed) {
      items.add(_buildCompactInfo(
        Icons.check_circle_outline,
        'Processed',
        theme,
        colorScheme,
        color: Colors.green,
      ));
    } else if (doc.isProcessing) {
      items.add(_buildCompactInfo(
        Icons.schedule,
        'Processing',
        theme,
        colorScheme,
        color: Colors.orange,
      ));
    } else if (doc.hasError) {
      items.add(_buildCompactInfo(
        Icons.error_outline,
        'Error',
        theme,
        colorScheme,
        color: colorScheme.error,
      ));
    }

    // Add chunk count if processed
    if (doc.chunkCount > 0) {
      items.add(_buildCompactInfo(
        Icons.segment,
        '${doc.chunkCount} chunks',
        theme,
        colorScheme,
      ));
    }

    // Add summary indicator
    if (doc.summaryGenerated) {
      items.add(_buildCompactInfo(
        Icons.summarize,
        'Summary',
        theme,
        colorScheme,
        color: Colors.purple,
      ));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: items,
    );
  }

  Widget _buildCompactBadge(String label, Color bgColor, Color textColor, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCompactInfo(
    IconData icon,
    String label,
    ThemeData theme,
    ColorScheme colorScheme, {
    Color? color,
  }) {
    final displayColor = color ?? colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: displayColor,
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: displayColor.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

}