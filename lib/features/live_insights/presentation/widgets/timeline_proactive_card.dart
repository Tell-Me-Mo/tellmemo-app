import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/proactive_assistance_model.dart';

typedef FeedbackCallback = void Function(bool isHelpful);

/// Redesigned Proactive Assistance Card for Timeline View
///
/// Hero treatment with:
/// - Clean, modern design following Material Design 3
/// - Generous padding and spacing
/// - Prominent visual hierarchy
/// - Reduced cognitive load
/// - Elegant, minimal chrome
class TimelineProactiveCard extends StatefulWidget {
  final ProactiveAssistanceModel assistance;
  final VoidCallback? onDismiss;
  final FeedbackCallback? onFeedback;

  const TimelineProactiveCard({
    super.key,
    required this.assistance,
    this.onDismiss,
    this.onFeedback,
  });

  @override
  State<TimelineProactiveCard> createState() => _TimelineProactiveCardState();
}

class _TimelineProactiveCardState extends State<TimelineProactiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;  // Start collapsed by default
  bool? _feedbackGiven;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
              : _getBackgroundColor(theme),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getTypeColor().withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            if (_isExpanded) ...[
              Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
              _buildContent(theme),
              _buildFooter(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final type = widget.assistance.type;
    final preview = _getPreviewText();

    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon - smaller and simpler
            Icon(
              _getIconForType(type),
              color: _getTypeColor(),
              size: 18,
            ),
            const SizedBox(width: 10),

            // Title and preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTitleForType(type),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (preview != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Confidence badge - smaller
            _buildConfidenceBadge(theme),
            const SizedBox(width: 8),

            // Expand/collapse icon - smaller
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(ThemeData theme) {
    final confidence = _getConfidence();
    if (confidence == null) return const SizedBox.shrink();

    final percentage = (confidence * 100).toInt();
    final color = confidence >= 0.8
        ? Colors.green
        : confidence >= 0.6
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    switch (widget.assistance.type) {
      case ProactiveAssistanceType.autoAnswer:
        return _buildAutoAnswerContent(theme);
      case ProactiveAssistanceType.clarificationNeeded:
        return _buildClarificationContent(theme);
      case ProactiveAssistanceType.conflictDetected:
        return _buildConflictContent(theme);
      case ProactiveAssistanceType.incompleteActionItem:
        return _buildActionItemContent(theme);
      case ProactiveAssistanceType.followUpSuggestion:
        return _buildFollowUpContent(theme);
    }
  }

  Widget _buildAutoAnswerContent(ThemeData theme) {
    final autoAnswer = widget.assistance.autoAnswer;
    if (autoAnswer == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          _buildContentSection(
            theme,
            icon: Icons.help_outline,
            iconColor: Colors.blue,
            backgroundColor: Colors.blue.shade50,
            label: 'Question',
            content: autoAnswer.question,
          ),
          const SizedBox(height: 10),

          // Answer
          _buildContentSection(
            theme,
            icon: Icons.lightbulb_outline,
            iconColor: Colors.green,
            backgroundColor: Colors.green.shade50,
            label: 'Answer',
            content: autoAnswer.answer,
          ),

          // Sources
          if (autoAnswer.sources.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Sources',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            ...autoAnswer.sources.map((source) => _buildSourceChip(theme, source)),
          ],
        ],
      ),
    );
  }

  Widget _buildClarificationContent(ThemeData theme) {
    final clarification = widget.assistance.clarification;
    if (clarification == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vague statement
          _buildContentSection(
            theme,
            icon: Icons.chat_bubble_outline,
            iconColor: Colors.orange,
            backgroundColor: Colors.orange.shade50,
            label: 'Statement needs clarification',
            content: clarification.statement,
          ),
          const SizedBox(height: 12),

          // Suggested questions
          Text(
            'Consider asking',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          ...clarification.suggestedQuestions
              .map((q) => _buildQuestionChip(theme, q)),
        ],
      ),
    );
  }

  Widget _buildConflictContent(ThemeData theme) {
    final conflict = widget.assistance.conflict;
    if (conflict == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current decision
          _buildContentSection(
            theme,
            icon: Icons.warning_amber,
            iconColor: Colors.red,
            backgroundColor: Colors.red.shade50,
            label: 'Current Decision',
            content: conflict.currentStatement,
          ),
          const SizedBox(height: 12),

          // Conflicting past decision
          Text(
            'Conflicts with',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conflict.conflictingTitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  conflict.conflictingSnippet,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItemContent(ThemeData theme) {
    final quality = widget.assistance.actionItemQuality;
    if (quality == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original action item
          _buildContentSection(
            theme,
            icon: Icons.assignment_outlined,
            iconColor: Colors.amber,
            backgroundColor: Colors.amber.shade50,
            label: 'Original Action Item',
            content: quality.actionItem,
          ),
          const SizedBox(height: 12),

          // Completeness score
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: quality.completenessScore,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getCompletenessColor(quality.completenessScore),
                  ),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(quality.completenessScore * 100).toInt()}%',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getCompletenessColor(quality.completenessScore),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Issues
          if (quality.issues.isNotEmpty) ...[
            Text(
              'Issues Found',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            ...quality.issues.map((issue) => _buildIssueChip(theme, issue)),
          ],

          // Improved version
          if (quality.improvedVersion != null) ...[
            const SizedBox(height: 12),
            _buildContentSection(
              theme,
              icon: Icons.check_circle_outline,
              iconColor: Colors.green,
              backgroundColor: Colors.green.shade50,
              label: 'Suggested Improvement',
              content: quality.improvedVersion!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFollowUpContent(ThemeData theme) {
    final followUp = widget.assistance.followUpSuggestion;
    if (followUp == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic
          _buildContentSection(
            theme,
            icon: Icons.tips_and_updates_outlined,
            iconColor: Colors.purple,
            backgroundColor: Colors.purple.shade50,
            label: 'Suggested Topic',
            content: followUp.topic,
          ),
          const SizedBox(height: 10),

          // Reason
          _buildContentSection(
            theme,
            icon: Icons.info_outline,
            iconColor: Colors.blue,
            backgroundColor: Colors.blue.shade50,
            label: 'Why now?',
            content: followUp.reason,
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(
    ThemeData theme, {
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String label,
    required String content,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                  letterSpacing: 0.3,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.4,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceChip(ThemeData theme, AnswerSource source) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description_outlined,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  source.snippet,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionChip(ThemeData theme, String question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () {
          Clipboard.setData(ClipboardData(text: question));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied: $question'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.chat_outlined,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  question,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                  ),
                ),
              ),
              Icon(
                Icons.content_copy,
                size: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIssueChip(ThemeData theme, QualityIssue issue) {
    final isDark = theme.brightness == Brightness.dark;
    final color = issue.severity.toLowerCase() == 'critical'
        ? Colors.red
        : issue.severity.toLowerCase() == 'important'
            ? Colors.orange
            : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            issue.severity.toLowerCase() == 'critical'
                ? Icons.error_outline
                : issue.severity.toLowerCase() == 'important'
                    ? Icons.warning_amber
                    : Icons.info_outline,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              issue.message,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        children: [
          // Feedback buttons
          Text(
            'Helpful?',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          _buildFeedbackButton(
            theme,
            icon: Icons.thumb_up_outlined,
            selectedIcon: Icons.thumb_up,
            isSelected: _feedbackGiven == true,
            onTap: _feedbackGiven == null ? () => _handleFeedback(true) : null,
          ),
          const SizedBox(width: 6),
          _buildFeedbackButton(
            theme,
            icon: Icons.thumb_down_outlined,
            selectedIcon: Icons.thumb_down,
            isSelected: _feedbackGiven == false,
            onTap: _feedbackGiven == null ? () => _handleFeedback(false) : null,
          ),
          const Spacer(),

          // Dismiss button
          if (widget.onDismiss != null)
            IconButton(
              onPressed: widget.onDismiss,
              icon: const Icon(Icons.close),
              iconSize: 16,
              tooltip: 'Dismiss',
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildFeedbackButton(
    ThemeData theme, {
    required IconData icon,
    required IconData selectedIcon,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isSelected ? selectedIcon : icon,
          size: 18,
          color: color,
        ),
      ),
    );
  }

  void _handleFeedback(bool isHelpful) {
    setState(() {
      _feedbackGiven = isHelpful;
    });
    widget.onFeedback?.call(isHelpful);
  }

  // Helper methods
  double? _getConfidence() {
    switch (widget.assistance.type) {
      case ProactiveAssistanceType.autoAnswer:
        return widget.assistance.autoAnswer?.confidence;
      case ProactiveAssistanceType.clarificationNeeded:
        return widget.assistance.clarification?.confidence;
      case ProactiveAssistanceType.conflictDetected:
        return widget.assistance.conflict?.confidence;
      case ProactiveAssistanceType.followUpSuggestion:
        return widget.assistance.followUpSuggestion?.confidence;
      default:
        return null;
    }
  }

  String? _getPreviewText() {
    switch (widget.assistance.type) {
      case ProactiveAssistanceType.autoAnswer:
        return widget.assistance.autoAnswer?.question;
      case ProactiveAssistanceType.clarificationNeeded:
        return widget.assistance.clarification?.statement;
      case ProactiveAssistanceType.conflictDetected:
        return widget.assistance.conflict?.currentStatement;
      case ProactiveAssistanceType.incompleteActionItem:
        final quality = widget.assistance.actionItemQuality;
        if (quality != null) {
          return '${(quality.completenessScore * 100).toInt()}% complete: ${quality.actionItem}';
        }
        return null;
      case ProactiveAssistanceType.followUpSuggestion:
        return widget.assistance.followUpSuggestion?.topic;
    }
  }

  IconData _getIconForType(ProactiveAssistanceType type) {
    switch (type) {
      case ProactiveAssistanceType.autoAnswer:
        return Icons.auto_awesome;
      case ProactiveAssistanceType.clarificationNeeded:
        return Icons.help_outline;
      case ProactiveAssistanceType.conflictDetected:
        return Icons.warning_amber_rounded;
      case ProactiveAssistanceType.incompleteActionItem:
        return Icons.assignment_outlined;
      case ProactiveAssistanceType.followUpSuggestion:
        return Icons.tips_and_updates_outlined;
    }
  }

  String _getTitleForType(ProactiveAssistanceType type) {
    switch (type) {
      case ProactiveAssistanceType.autoAnswer:
        return 'AI Auto-Answered';
      case ProactiveAssistanceType.clarificationNeeded:
        return 'Clarification Needed';
      case ProactiveAssistanceType.conflictDetected:
        return 'Potential Conflict';
      case ProactiveAssistanceType.incompleteActionItem:
        return 'Incomplete Action Item';
      case ProactiveAssistanceType.followUpSuggestion:
        return 'Follow-up Suggestion';
    }
  }

  Color _getBackgroundColor(ThemeData theme) {
    switch (widget.assistance.type) {
      case ProactiveAssistanceType.autoAnswer:
        return Colors.blue.shade50;
      case ProactiveAssistanceType.clarificationNeeded:
        return Colors.orange.shade50;
      case ProactiveAssistanceType.conflictDetected:
        return Colors.red.shade50;
      case ProactiveAssistanceType.incompleteActionItem:
        return Colors.amber.shade50;
      case ProactiveAssistanceType.followUpSuggestion:
        return Colors.purple.shade50;
    }
  }

  Color _getTypeColor() {
    switch (widget.assistance.type) {
      case ProactiveAssistanceType.autoAnswer:
        return Colors.blue;
      case ProactiveAssistanceType.clarificationNeeded:
        return Colors.orange;
      case ProactiveAssistanceType.conflictDetected:
        return Colors.red;
      case ProactiveAssistanceType.incompleteActionItem:
        return Colors.amber;
      case ProactiveAssistanceType.followUpSuggestion:
        return Colors.purple;
    }
  }

  Color _getCompletenessColor(double score) {
    if (score >= 0.7) return Colors.green;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }
}
