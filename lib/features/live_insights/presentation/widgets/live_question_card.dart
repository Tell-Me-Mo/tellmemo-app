import 'package:flutter/material.dart';
import '../../data/models/live_insight_model.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../core/utils/datetime_utils.dart';

/// Card widget for displaying live questions with four-tier answer discovery
class LiveQuestionCard extends StatefulWidget {
  final LiveQuestion question;
  final VoidCallback? onMarkAnswered;
  final VoidCallback? onNeedsFollowUp;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const LiveQuestionCard({
    super.key,
    required this.question,
    this.onMarkAnswered,
    this.onNeedsFollowUp,
    this.onDismiss,
    this.onTap,
  });

  @override
  State<LiveQuestionCard> createState() => _LiveQuestionCardState();
}

class _LiveQuestionCardState extends State<LiveQuestionCard>
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

  @override
  void didUpdateWidget(LiveQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Auto-expand when answer is found (tier results become available)
    final hadNoResults = oldWidget.question.tierResults.isEmpty;
    final nowHasResults = widget.question.tierResults.isNotEmpty;

    if (hadNoResults && nowHasResults && !_isExpanded) {
      // Automatically expand to show the answer
      setState(() {
        _isExpanded = true;
        _animationController.forward();
      });
    }
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
            color: _getStatusColor(colorScheme).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap ?? _toggleExpand,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(LayoutConstants.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: LayoutConstants.spacingMd),
                _buildQuestionText(context),
                if (_isExpanded) ...[
                  const SizedBox(height: LayoutConstants.spacingMd),
                  _buildTierResults(context),
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
          _getStatusIcon(),
          size: LayoutConstants.iconSizeSm,
          color: _getStatusColor(colorScheme),
        ),
        const SizedBox(width: LayoutConstants.spacingSm),

        // Speaker and timestamp
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.question.displaySpeaker,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                DateTimeUtils.formatTimeAgo(widget.question.timestamp),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Status badge
        _buildStatusBadge(context),

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

        const SizedBox(width: LayoutConstants.spacingSm),

        // Expand/collapse chevron
        AnimatedRotation(
          turns: _rotationAnimation.value,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            Icons.chevron_right,
            size: LayoutConstants.iconSizeMd,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(colorScheme);

    // Get display label and icon based on answer source (for answered/found questions)
    String displayLabel;
    String displayIcon;

    // Show answer source for questions that have been answered or found
    if (widget.question.answerSource != null &&
        widget.question.answerSource != AnswerSource.unanswered) {
      // Show specific answer source instead of generic status
      switch (widget.question.answerSource!) {
        case AnswerSource.rag:
          displayLabel = 'FROM DOCS';
          displayIcon = '📄';
          break;
        case AnswerSource.meetingContext:
          displayLabel = 'FROM MEETING';
          displayIcon = '💬';
          break;
        case AnswerSource.liveConversation:
          displayLabel = 'ANSWERED LIVE';
          displayIcon = '👂';
          break;
        case AnswerSource.gptGenerated:
          displayLabel = 'AI ANSWER';
          displayIcon = '🤖';
          break;
        case AnswerSource.userProvided:
          displayLabel = 'ANSWERED';
          displayIcon = '✓';
          break;
        case AnswerSource.unanswered:
          // Shouldn't reach here due to the condition above, but handle it
          displayLabel = 'UNANSWERED';
          displayIcon = '❓';
          break;
      }
    } else {
      // Use default status label for non-answered states (searching, monitoring, unanswered)
      displayLabel = widget.question.status.displayLabel.toUpperCase();
      displayIcon = widget.question.status.icon;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayIcon,
            style: const TextStyle(fontSize: 10),
          ),
          const SizedBox(width: 4),
          Text(
            displayLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: statusColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionText(BuildContext context) {
    final theme = Theme.of(context);

    return SelectableText(
      widget.question.text,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
    );
  }

  Widget _buildTierResults(BuildContext context) {
    // Show search state only if still searching and no results yet
    final isStillSearching = widget.question.status == InsightStatus.searching ||
        widget.question.status == InsightStatus.monitoring;

    if (widget.question.tierResults.isEmpty && isStillSearching) {
      return _buildSearchingState(context);
    }

    // If unanswered and no results, show unanswered message
    if (widget.question.tierResults.isEmpty && widget.question.status == InsightStatus.unanswered) {
      return _buildUnansweredState(context);
    }

    // If status is answered/found but no tier results, show placeholder
    if (widget.question.tierResults.isEmpty) {
      return _buildNoDetailsState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTierSection(
          context,
          TierType.rag,
          widget.question.ragResults,
        ),
        _buildTierSection(
          context,
          TierType.meetingContext,
          widget.question.meetingContextResults,
        ),
        _buildTierSection(
          context,
          TierType.liveConversation,
          widget.question.liveConversationResults,
        ),
        _buildTierSection(
          context,
          TierType.gptGenerated,
          widget.question.gptGeneratedResults,
        ),
      ],
    );
  }

  Widget _buildSearchingState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(LayoutConstants.spacingMd),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: LayoutConstants.spacingMd),
          Text(
            'Searching for answers...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnansweredState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(LayoutConstants.spacingSm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.help_outline,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: LayoutConstants.spacingSm),
          Expanded(
            child: Text(
              'No answer found',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDetailsState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(LayoutConstants.spacingSm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: LayoutConstants.spacingSm),
          Expanded(
            child: Text(
              'Answer details loading...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierSection(
    BuildContext context,
    TierType tierType,
    List<TierResult> results,
  ) {
    if (results.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tierColor = _getTierColor(tierType, colorScheme);

    return Container(
      margin: const EdgeInsets.only(bottom: LayoutConstants.spacingSm),
      padding: const EdgeInsets.all(LayoutConstants.spacingSm),
      decoration: BoxDecoration(
        color: tierColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tierColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Results only, no header
          ...results.map((result) => _buildTierResultItem(
                context,
                result,
                tierType,
              )),
        ],
      ),
    );
  }

  Widget _buildTierResultItem(
    BuildContext context,
    TierResult result,
    TierType tierType,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: LayoutConstants.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content
          SelectableText(
            result.content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),

          const SizedBox(height: LayoutConstants.spacingSm),

          // Metadata row
          Row(
            children: [
              // Source
              if (result.source != null) ...[
                Icon(
                  _getSourceIcon(tierType),
                  size: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    result.source!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              // Confidence badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(result.confidence, colorScheme)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(result.confidence * 100).round()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getConfidenceColor(result.confidence, colorScheme),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (widget.question.status) {
      case InsightStatus.searching:
        return Icons.search;
      case InsightStatus.found:
        return Icons.check_circle_outline;
      case InsightStatus.monitoring:
        return Icons.visibility_outlined;
      case InsightStatus.answered:
        return Icons.check_circle;
      case InsightStatus.unanswered:
        return Icons.help_outline;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(ColorScheme colorScheme) {
    switch (widget.question.status) {
      case InsightStatus.searching:
        return Colors.blue.shade600;
      case InsightStatus.found:
        return Colors.green.shade600;
      case InsightStatus.monitoring:
        return Colors.orange.shade600;
      case InsightStatus.answered:
        return Colors.green.shade700;
      case InsightStatus.unanswered:
        return Colors.grey.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getTierColor(TierType tierType, ColorScheme colorScheme) {
    switch (tierType) {
      case TierType.rag:
        return Colors.blue.shade600;
      case TierType.meetingContext:
        return Colors.purple.shade600;
      case TierType.liveConversation:
        return Colors.green.shade600;
      case TierType.gptGenerated:
        return Colors.orange.shade600;
    }
  }

  IconData _getSourceIcon(TierType tierType) {
    switch (tierType) {
      case TierType.rag:
        return Icons.description_outlined;
      case TierType.meetingContext:
        return Icons.access_time;
      case TierType.liveConversation:
        return Icons.mic_outlined;
      case TierType.gptGenerated:
        return Icons.auto_awesome;
    }
  }

  Color _getConfidenceColor(double confidence, ColorScheme colorScheme) {
    if (confidence >= 0.8) {
      return Colors.green.shade600;
    } else if (confidence >= 0.6) {
      return Colors.orange.shade600;
    } else {
      return Colors.grey.shade600;
    }
  }
}
