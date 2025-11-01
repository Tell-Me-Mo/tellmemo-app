import 'package:flutter/material.dart';
import '../../data/models/live_insight_model.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../core/utils/datetime_utils.dart';

/// Card widget for displaying live action items with completeness tracking
class LiveActionCard extends StatefulWidget {
  final LiveAction action;
  final Function(String owner)? onAssignOwner;
  final Function(DateTime deadline)? onSetDeadline;
  final VoidCallback? onMarkComplete;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const LiveActionCard({
    super.key,
    required this.action,
    this.onAssignOwner,
    this.onSetDeadline,
    this.onMarkComplete,
    this.onDismiss,
    this.onTap,
  });

  @override
  State<LiveActionCard> createState() => _LiveActionCardState();
}

class _LiveActionCardState extends State<LiveActionCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.25, // 90 degrees (quarter turn)
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Color _getCompletenessColor(ColorScheme colorScheme) {
    switch (widget.action.completenessLevel) {
      case ActionCompleteness.complete:
        return Colors.green.shade600;
      case ActionCompleteness.partial:
        return Colors.orange.shade600;
      case ActionCompleteness.descriptionOnly:
        return Colors.grey.shade600;
    }
  }

  Color _getStatusBorderColor(ColorScheme colorScheme) {
    if (widget.action.isComplete) {
      return Colors.green.shade600;
    } else if (widget.action.deadline != null &&
        widget.action.deadline!.isBefore(DateTime.now())) {
      return Colors.red.shade600;
    } else {
      return _getCompletenessColor(colorScheme);
    }
  }

  Color _getDeadlineColor(ColorScheme colorScheme) {
    if (!widget.action.hasDeadline) {
      // Missing deadline - more visible orange/amber to indicate it needs attention
      return Colors.orange.shade400;
    }

    final deadline = widget.action.deadline!;
    final now = DateTime.now();
    final daysUntil = deadline.difference(now).inDays;

    if (deadline.isBefore(now)) {
      // Overdue - bright red
      return Colors.red.shade600;
    } else if (daysUntil <= 3) {
      // Due soon - orange
      return Colors.orange.shade600;
    } else {
      // Future deadline - normal color
      return colorScheme.onSurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: LayoutConstants.spacingSm),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _getStatusBorderColor(colorScheme).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(LayoutConstants.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: LayoutConstants.spacingMd),
              _buildActionDescription(context),
              const SizedBox(height: LayoutConstants.spacingSm),
              _buildCompactMetadata(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        // Status icon
        Icon(
          widget.action.isComplete ? Icons.check_circle : Icons.track_changes,
          size: LayoutConstants.iconSizeSm,
          color: _getStatusBorderColor(colorScheme),
        ),
        const SizedBox(width: LayoutConstants.spacingSm),

        // Timestamp only (speaker diarization not supported in streaming API)
        Expanded(
          child: Text(
            DateTimeUtils.formatTimeAgo(widget.action.timestamp),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),

        // Completeness badge
        _buildCompletenessBadge(context),

        const SizedBox(width: LayoutConstants.spacingSm),

        // Dismiss button
        if (widget.onDismiss != null)
          IconButton(
            onPressed: widget.onDismiss,
            icon: const Icon(Icons.close),
            iconSize: 18,
            color: colorScheme.onSurfaceVariant,
            tooltip: 'Dismiss',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
      ],
    );
  }

  Widget _buildCompletenessBadge(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = _getCompletenessColor(colorScheme);

    String label;
    IconData icon;

    switch (widget.action.completenessLevel) {
      case ActionCompleteness.complete:
        label = 'Complete';
        icon = Icons.check_circle_outline;
        break;
      case ActionCompleteness.partial:
        label = 'Partial';
        icon = Icons.incomplete_circle;
        break;
      case ActionCompleteness.descriptionOnly:
        label = 'Tracking';
        icon = Icons.radio_button_unchecked;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionDescription(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SelectableText(
      widget.action.description,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildCompletenessProgressBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percentage = widget.action.completenessPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Completeness',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
            Text(
              '$percentage%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _getCompletenessColor(colorScheme),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 4,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getCompletenessColor(colorScheme),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactMetadata(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        // Owner
        Icon(
          Icons.person_outline,
          size: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          widget.action.owner ?? 'No owner',
          style: theme.textTheme.labelSmall?.copyWith(
            color: widget.action.hasOwner
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontWeight: widget.action.hasOwner ? FontWeight.w500 : FontWeight.w400,
          ),
        ),

        const SizedBox(width: LayoutConstants.spacingMd),

        // Deadline with color coding
        Icon(
          widget.action.deadline != null && widget.action.deadline!.isBefore(DateTime.now())
              ? Icons.warning_amber_rounded
              : Icons.schedule,
          size: 14,
          color: _getDeadlineColor(colorScheme),
        ),
        const SizedBox(width: 4),
        Text(
          widget.action.deadlineDisplay,
          style: theme.textTheme.labelSmall?.copyWith(
            color: _getDeadlineColor(colorScheme),
            fontWeight: widget.action.hasDeadline ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedMetadata(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(LayoutConstants.spacingMd),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Owner
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: LayoutConstants.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Owner',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.action.owner ?? 'No owner',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: widget.action.hasOwner
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: LayoutConstants.spacingLg),

          // Deadline
          Expanded(
            child: Row(
              children: [
                Icon(
                  widget.action.deadline != null && widget.action.deadline!.isBefore(DateTime.now())
                      ? Icons.warning_amber_rounded
                      : Icons.schedule,
                  size: 16,
                  color: _getDeadlineColor(colorScheme),
                ),
                const SizedBox(width: LayoutConstants.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deadline',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.action.deadlineDisplay,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _getDeadlineColor(colorScheme),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
