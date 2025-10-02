import 'package:flutter/material.dart';
import '../../data/services/content_availability_service.dart';

class ContentAvailabilityIndicator extends StatelessWidget {
  final ContentAvailability availability;
  final VoidCallback? onUploadContent;
  final bool showDetails;
  final bool compact;

  const ContentAvailabilityIndicator({
    super.key,
    required this.availability,
    this.onUploadContent,
    this.showDetails = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (compact) {
      return _buildCompactIndicator(context);
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSeverityIcon(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getSeverityTitle(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getSeverityColor(colorScheme),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        availability.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showDetails && availability.contentCount > 0) ...[
              const SizedBox(height: 16),
              _buildContentStats(context),
            ],
            if (availability.recommendedAction.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildRecommendedAction(context),
            ],
            if (!availability.hasContent && onUploadContent != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onUploadContent,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Content'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine color and icon based on severity
    final indicatorColor = _getSeverityColor(colorScheme);
    final backgroundColor = indicatorColor.withValues(alpha: 0.08);
    final borderColor = indicatorColor.withValues(alpha: 0.2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getSeverityIconData(),
            size: 18,
            color: indicatorColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getCompactMessage(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (availability.contentCount > 0 && showDetails) ...[
                  const SizedBox(height: 2),
                  Text(
                    _getContentSummary(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCompactMessage() {
    if (!availability.hasContent) {
      return 'No content available in selected range';
    }

    switch (availability.severity) {
      case ContentSeverity.sufficient:
        return 'Great! Sufficient content available';
      case ContentSeverity.moderate:
        return 'Good amount of content available';
      case ContentSeverity.limited:
        return 'Limited content available';
      case ContentSeverity.none:
        return 'No content found';
    }
  }

  String _getContentSummary() {
    final parts = <String>[];

    // Use contentBreakdown if available
    if (availability.contentBreakdown != null) {
      availability.contentBreakdown!.forEach((key, value) {
        if (value > 0) {
          final itemName = key.toLowerCase().replaceAll('_', ' ');
          parts.add('$value $itemName${value > 1 ? 's' : ''}');
        }
      });
    }

    if (parts.isEmpty && availability.contentCount > 0) {
      return '${availability.contentCount} content item${availability.contentCount > 1 ? 's' : ''}';
    }

    return parts.join(', ');
  }

  Widget _buildSeverityIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _getSeverityColor(colorScheme);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getSeverityIconData(),
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildContentStats(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final stats = <String, String>{};

    // Add basic stats
    stats['Total Content'] = '${availability.contentCount} items';

    // Add project stats if available
    if (availability.projectCount != null) {
      stats['Projects'] = '${availability.projectsWithContent}/${availability.projectCount}';
    }

    // Add program stats if available
    if (availability.programCount != null) {
      stats['Programs'] = '${availability.programCount}';
    }

    // Add recent summaries if available
    if (availability.recentSummariesCount != null) {
      stats['Recent Summaries'] = '${availability.recentSummariesCount}';
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: stats.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.key,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              entry.value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildRecommendedAction(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              availability.recommendedAction,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSeverityIconData() {
    switch (availability.severity) {
      case ContentSeverity.none:
        return Icons.folder_open;
      case ContentSeverity.limited:
        return Icons.warning_amber;
      case ContentSeverity.moderate:
        return Icons.folder;
      case ContentSeverity.sufficient:
        return Icons.check_circle;
    }
  }

  Color _getSeverityColor(ColorScheme colorScheme) {
    switch (availability.severity) {
      case ContentSeverity.none:
        return colorScheme.error;
      case ContentSeverity.limited:
        return Colors.orange;
      case ContentSeverity.moderate:
        return colorScheme.primary;
      case ContentSeverity.sufficient:
        return Colors.green;
    }
  }

  String _getSeverityTitle() {
    switch (availability.severity) {
      case ContentSeverity.none:
        return 'No Content Available';
      case ContentSeverity.limited:
        return 'Limited Content';
      case ContentSeverity.moderate:
        return 'Moderate Content';
      case ContentSeverity.sufficient:
        return 'Sufficient Content';
    }
  }
}

/// Widget for showing content availability in a list tile format
class ContentAvailabilityTile extends StatelessWidget {
  final ContentAvailability availability;
  final String entityName;
  final VoidCallback? onTap;

  const ContentAvailabilityTile({
    super.key,
    required this.availability,
    required this.entityName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getColor(colorScheme).withOpacity(0.1),
        child: Icon(
          _getIcon(),
          color: _getColor(colorScheme),
        ),
      ),
      title: Text(entityName),
      subtitle: Text(
        '${availability.contentCount} content items',
        style: theme.textTheme.bodySmall,
      ),
      trailing: availability.canGenerateSummary
          ? Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            )
          : Icon(
              Icons.block,
              color: colorScheme.error,
              size: 20,
            ),
      onTap: onTap,
    );
  }

  IconData _getIcon() {
    if (!availability.hasContent) return Icons.folder_open;
    if (availability.contentCount < 3) return Icons.warning_amber;
    return Icons.folder;
  }

  Color _getColor(ColorScheme colorScheme) {
    if (!availability.hasContent) return colorScheme.error;
    if (availability.contentCount < 3) return Colors.orange;
    return colorScheme.primary;
  }
}