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
  bool _isEditingOwner = false;
  bool _isEditingDeadline = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  final TextEditingController _ownerController = TextEditingController();

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
    _ownerController.text = widget.action.owner ?? '';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _ownerController.dispose();
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

  void _toggleEditOwner() {
    setState(() {
      _isEditingOwner = !_isEditingOwner;
      if (_isEditingOwner) {
        _ownerController.text = widget.action.owner ?? '';
      }
    });
  }

  void _saveOwner() {
    final newOwner = _ownerController.text.trim();
    if (newOwner.isNotEmpty && widget.onAssignOwner != null) {
      widget.onAssignOwner!(newOwner);
    }
    setState(() {
      _isEditingOwner = false;
    });
  }

  Future<void> _showDeadlinePicker() async {
    final now = DateTime.now();
    final initialDate = widget.action.deadline ?? now;
    final firstDate = now.subtract(const Duration(days: 1));
    final lastDate = now.add(const Duration(days: 365));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null && widget.onSetDeadline != null) {
      widget.onSetDeadline!(pickedDate);
    }
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
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap ?? _toggleExpand,
          child: Padding(
            padding: const EdgeInsets.all(LayoutConstants.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: LayoutConstants.spacingMd),
                _buildActionDescription(context),
                const SizedBox(height: LayoutConstants.spacingSm),
                _buildCompletenessProgressBar(context),
                if (_isExpanded) ...[
                  const SizedBox(height: LayoutConstants.spacingMd),
                  _buildMetadata(context),
                  const SizedBox(height: LayoutConstants.spacingMd),
                  _buildMissingInformationPrompt(context),
                  const SizedBox(height: LayoutConstants.spacingMd),
                  _buildActionButtons(context),
                ] else ...[
                  const SizedBox(height: LayoutConstants.spacingSm),
                  _buildCompactMetadata(context),
                ],
              ],
            ),
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
          size: 18,
          color: _getStatusBorderColor(colorScheme),
        ),
        const SizedBox(width: LayoutConstants.spacingSm),

        // Speaker
        Expanded(
          child: Text(
            widget.action.displaySpeaker,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Timestamp
        Text(
          DateTimeUtils.formatTimeAgo(widget.action.timestamp),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),

        const SizedBox(width: LayoutConstants.spacingSm),

        // Completeness badge
        _buildCompletenessBadge(context),

        const SizedBox(width: LayoutConstants.spacingSm),

        // Expand/collapse icon
        RotationTransition(
          turns: _rotationAnimation,
          child: Icon(
            Icons.chevron_right,
            size: 20,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
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
        if (widget.action.hasOwner) ...[
          Icon(
            Icons.person_outline,
            size: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Text(
            widget.action.owner!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: LayoutConstants.spacingMd),
        ],
        if (widget.action.hasDeadline) ...[
          Icon(
            Icons.schedule,
            size: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Text(
            widget.action.deadlineDisplay,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
        if (!widget.action.hasOwner && !widget.action.hasDeadline)
          Text(
            'No owner or deadline assigned',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildMetadata(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Owner field
        Row(
          children: [
            Icon(
              Icons.person_outline,
              size: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: LayoutConstants.spacingSm),
            Expanded(
              child: _isEditingOwner
                  ? TextField(
                      controller: _ownerController,
                      decoration: InputDecoration(
                        hintText: 'Enter owner name',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      style: theme.textTheme.bodyMedium,
                      autofocus: true,
                      onSubmitted: (_) => _saveOwner(),
                    )
                  : Text(
                      widget.action.owner ?? 'No owner assigned',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: widget.action.hasOwner
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withValues(alpha: 0.4),
                        fontStyle: widget.action.hasOwner
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
            ),
            const SizedBox(width: LayoutConstants.spacingSm),
            if (_isEditingOwner)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, size: 18),
                    onPressed: _saveOwner,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _isEditingOwner = false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: Colors.red.shade600,
                  ),
                ],
              )
            else
              IconButton(
                icon: const Icon(Icons.edit, size: 16),
                onPressed: _toggleEditOwner,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: colorScheme.primary,
              ),
          ],
        ),

        const SizedBox(height: LayoutConstants.spacingSm),

        // Deadline field
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: LayoutConstants.spacingSm),
            Expanded(
              child: Text(
                widget.action.deadlineDisplay,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: widget.action.hasDeadline
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.4),
                  fontStyle: widget.action.hasDeadline
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(width: LayoutConstants.spacingSm),
            IconButton(
              icon: const Icon(Icons.calendar_today, size: 16),
              onPressed: _showDeadlinePicker,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: colorScheme.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMissingInformationPrompt(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final missing = widget.action.missingInformation;

    if (missing.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(LayoutConstants.spacingSm),
      decoration: BoxDecoration(
        color: Colors.orange.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.shade300.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.orange.shade700,
          ),
          const SizedBox(width: LayoutConstants.spacingSm),
          Expanded(
            child: Text(
              'Missing: ${missing.join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange.shade900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        // Assign button
        if (!widget.action.hasOwner && widget.onAssignOwner != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _toggleEditOwner,
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('Assign'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue.shade600,
                side: BorderSide(color: Colors.blue.shade600),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),

        // Set Deadline button
        if (!widget.action.hasDeadline && widget.onSetDeadline != null) ...[
          if (!widget.action.hasOwner) const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showDeadlinePicker,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: const Text('Deadline'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple.shade600,
                side: BorderSide(color: Colors.purple.shade600),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],

        // Mark Complete button
        if (!widget.action.isComplete && widget.onMarkComplete != null) ...[
          if (widget.action.hasOwner || widget.action.hasDeadline)
            const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onMarkComplete,
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('Complete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade600,
                side: BorderSide(color: Colors.green.shade600),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],

        // Dismiss button
        if (widget.onDismiss != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: widget.onDismiss,
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ],
      ],
    );
  }
}
