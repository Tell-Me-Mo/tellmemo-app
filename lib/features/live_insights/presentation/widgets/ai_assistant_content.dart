import 'package:flutter/material.dart';
import '../../data/models/live_insight_model.dart';
import 'live_question_card.dart';
import 'live_action_card.dart';
import '../../../../core/constants/layout_constants.dart';

/// AI Assistant content section that displays questions and actions cards
/// within the recording panel
class AIAssistantContentSection extends StatefulWidget {
  /// List of questions to display
  final List<LiveQuestion> questions;

  /// List of actions to display
  final List<LiveAction> actions;

  /// Callback when a question is marked as answered
  final Function(String questionId)? onQuestionMarkAnswered;

  /// Callback when a question needs follow-up
  final Function(String questionId)? onQuestionNeedsFollowUp;

  /// Callback when a question is dismissed
  final Function(String questionId)? onQuestionDismiss;

  /// Callback when an action owner is assigned
  final Function(String actionId, String owner)? onActionAssignOwner;

  /// Callback when an action deadline is set
  final Function(String actionId, DateTime deadline)? onActionSetDeadline;

  /// Callback when an action is marked complete
  final Function(String actionId)? onActionMarkComplete;

  /// Callback when an action is dismissed
  final Function(String actionId)? onActionDismiss;

  /// Callback when dismiss all is triggered
  final VoidCallback? onDismissAll;

  const AIAssistantContentSection({
    super.key,
    required this.questions,
    required this.actions,
    this.onQuestionMarkAnswered,
    this.onQuestionNeedsFollowUp,
    this.onQuestionDismiss,
    this.onActionAssignOwner,
    this.onActionSetDeadline,
    this.onActionMarkComplete,
    this.onActionDismiss,
    this.onDismissAll,
  });

  @override
  State<AIAssistantContentSection> createState() =>
      _AIAssistantContentSectionState();
}

class _AIAssistantContentSectionState
    extends State<AIAssistantContentSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasQuestions = widget.questions.isNotEmpty;
    final hasActions = widget.actions.isNotEmpty;
    final hasAnyItems = hasQuestions || hasActions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with dismiss all button
        if (hasAnyItems)
          Padding(
            padding: const EdgeInsets.only(
              left: LayoutConstants.spacingSm,
              right: LayoutConstants.spacingSm,
              bottom: LayoutConstants.spacingSm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Live Insights',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (widget.onDismissAll != null)
                  TextButton.icon(
                    onPressed: widget.onDismissAll,
                    icon: Icon(
                      Icons.clear_all,
                      size: 16,
                      color: colorScheme.error,
                    ),
                    label: Text(
                      'Dismiss All',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // Scrollable content
        Flexible(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Questions section
                _buildQuestionsSection(context),

                // Spacing between sections
                if (hasQuestions && hasActions)
                  const SizedBox(height: LayoutConstants.spacingMd),

                // Actions section
                _buildActionsSection(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LayoutConstants.spacingSm,
            vertical: LayoutConstants.spacingXs,
          ),
          child: Row(
            children: [
              Icon(
                Icons.help_outline,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: LayoutConstants.spacingXs),
              Text(
                'Questions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: LayoutConstants.spacingXs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.questions.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: LayoutConstants.spacingSm),

        // Questions list or empty state
        if (widget.questions.isEmpty)
          _buildEmptyState(
            context,
            icon: Icons.question_answer_outlined,
            message: 'Listening for questions...',
            subMessage: 'Questions detected in the conversation will appear here',
          )
        else
          ...widget.questions.map((question) => LiveQuestionCard(
                question: question,
                onMarkAnswered: widget.onQuestionMarkAnswered != null
                    ? () => widget.onQuestionMarkAnswered!(question.id)
                    : null,
                onNeedsFollowUp: widget.onQuestionNeedsFollowUp != null
                    ? () => widget.onQuestionNeedsFollowUp!(question.id)
                    : null,
                onDismiss: widget.onQuestionDismiss != null
                    ? () => widget.onQuestionDismiss!(question.id)
                    : null,
              )),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LayoutConstants.spacingSm,
            vertical: LayoutConstants.spacingXs,
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 18,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: LayoutConstants.spacingXs),
              Text(
                'Actions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(width: LayoutConstants.spacingXs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.actions.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: LayoutConstants.spacingSm),

        // Actions list or empty state
        if (widget.actions.isEmpty)
          _buildEmptyState(
            context,
            icon: Icons.task_alt,
            message: 'Tracking actions...',
            subMessage: 'Action items mentioned will appear here',
          )
        else
          ...widget.actions.map((action) => LiveActionCard(
                action: action,
                onAssignOwner: widget.onActionAssignOwner != null
                    ? (owner) => widget.onActionAssignOwner!(action.id, owner)
                    : null,
                onSetDeadline: widget.onActionSetDeadline != null
                    ? (deadline) =>
                        widget.onActionSetDeadline!(action.id, deadline)
                    : null,
                onMarkComplete: widget.onActionMarkComplete != null
                    ? () => widget.onActionMarkComplete!(action.id)
                    : null,
                onDismiss: widget.onActionDismiss != null
                    ? () => widget.onActionDismiss!(action.id)
                    : null,
              )),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String message,
    required String subMessage,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(LayoutConstants.spacingLg),
      margin: const EdgeInsets.symmetric(
        horizontal: LayoutConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: LayoutConstants.spacingSm),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LayoutConstants.spacingXs),
          Text(
            subMessage,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
