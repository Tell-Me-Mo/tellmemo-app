import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/proactive_assistance_model.dart';

/// Callback for user feedback on proactive assistance
typedef FeedbackCallback = void Function(bool isHelpful);

/// Card widget for displaying proactive AI assistance
/// Phase 1: Auto-answered questions
/// Phase 2: Clarification suggestions
/// Features: User feedback collection (thumbs up/down)
class ProactiveAssistanceCard extends StatefulWidget {
  final ProactiveAssistanceModel assistance;
  final VoidCallback? onAccept;
  final VoidCallback? onDismiss;
  final VoidCallback? onViewSource;
  final FeedbackCallback? onFeedback;

  const ProactiveAssistanceCard({
    Key? key,
    required this.assistance,
    this.onAccept,
    this.onDismiss,
    this.onViewSource,
    this.onFeedback,
  }) : super(key: key);

  @override
  State<ProactiveAssistanceCard> createState() =>
      _ProactiveAssistanceCardState();
}

class _ProactiveAssistanceCardState extends State<ProactiveAssistanceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late bool _isExpanded;
  bool _dismissed = false;
  bool? _feedbackGiven;  // null = no feedback, true = helpful, false = not helpful

  @override
  void initState() {
    super.initState();
    // Determine initial expanded state based on display mode
    final displayMode = widget.assistance.displayMode;
    _isExpanded = displayMode == DisplayMode.immediate;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
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
    if (_dismissed) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 4,
        color: _getBackgroundColor(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _getBorderColor(), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (_isExpanded) ...[
              const Divider(height: 1),
              _buildContent(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final type = widget.assistance.type;
    final icon = _getIconForType(type);
    final iconColor = _getIconColorForType(type);
    final title = _getTitleForType(type);
    final subtitle = _getSubtitleForType();
    final displayMode = widget.assistance.displayMode;

    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Show display mode indicator for collapsed items
                      if (displayMode == DisplayMode.collapsed && !_isExpanded) ...[
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Medium confidence - tap to expand',
                          child: Icon(
                            Icons.visibility_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            _buildConfidenceBadge(),
            const SizedBox(width: 8),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge() {
    double? confidence;
    if (widget.assistance.type == ProactiveAssistanceType.autoAnswer) {
      confidence = widget.assistance.autoAnswer?.confidence;
    } else if (widget.assistance.type == ProactiveAssistanceType.clarificationNeeded) {
      confidence = widget.assistance.clarification?.confidence;
    } else if (widget.assistance.type == ProactiveAssistanceType.conflictDetected) {
      confidence = widget.assistance.conflict?.confidence;
    } else if (widget.assistance.type == ProactiveAssistanceType.followUpSuggestion) {
      confidence = widget.assistance.followUpSuggestion?.confidence;
    } else if (widget.assistance.type == ProactiveAssistanceType.repetitionDetected) {
      confidence = widget.assistance.repetitionDetection?.confidence;
    }

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
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        '$percentage%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.assistance.type) {
      case ProactiveAssistanceType.autoAnswer:
        return _buildAutoAnswerContent();
      case ProactiveAssistanceType.clarificationNeeded:
        return _buildClarificationContent();
      case ProactiveAssistanceType.conflictDetected:
        return _buildConflictContent();
      case ProactiveAssistanceType.incompleteActionItem:
        return _buildActionItemQualityContent();
      case ProactiveAssistanceType.followUpSuggestion:
        return _buildFollowUpSuggestionContent();
      case ProactiveAssistanceType.repetitionDetected:
        return _buildRepetitionDetectionContent();
    }
  }

  Widget _buildAutoAnswerContent() {
    final autoAnswer = widget.assistance.autoAnswer;
    if (autoAnswer == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.help_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    autoAnswer.question,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Answer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    autoAnswer.answer,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Sources
          if (autoAnswer.sources.isNotEmpty) ...[
            Text(
              'Sources:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            ...autoAnswer.sources.map((source) => _buildSourceChip(source)),
          ],

          // Reasoning (collapsible)
          if (autoAnswer.reasoning.isNotEmpty) ...[
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                dense: true,
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'How was this answer derived?',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      autoAnswer.reasoning,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Feedback section
          const SizedBox(height: 16),
          _buildFeedbackSection(),
        ],
      ),
    );
  }

  Widget _buildSourceChip(AnswerSource source) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          widget.onViewSource?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening: ${source.title}'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.description, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      source.snippet,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new, size: 16, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAccept() {
    widget.onAccept?.call();
    _animateDismiss();
  }

  void _handleDismiss() {
    widget.onDismiss?.call();
    _animateDismiss();
  }

  void _animateDismiss() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() => _dismissed = true);
      }
    });
  }

  /// Handle user feedback (thumbs up/down)
  void _handleFeedback(bool isHelpful) {
    setState(() {
      _feedbackGiven = isHelpful;
    });

    // Call the feedback callback if provided
    widget.onFeedback?.call(isHelpful);

    // Show confirmation snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isHelpful ? Icons.thumb_up : Icons.thumb_down,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(isHelpful
                ? 'Thank you! This helps improve our AI.'
                : 'Feedback noted. We\'ll work to improve this.'),
            ],
          ),
          backgroundColor: isHelpful ? Colors.green[700] : Colors.orange[700],
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Build feedback section with thumbs up/down buttons
  Widget _buildFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Was this helpful?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Thumbs up button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _feedbackGiven != null
                    ? null
                    : () => _handleFeedback(true),
                  icon: Icon(
                    _feedbackGiven == true ? Icons.thumb_up : Icons.thumb_up_outlined,
                    size: 20,
                  ),
                  label: const Text('Helpful'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _feedbackGiven == true
                      ? Colors.green[700]
                      : Colors.grey[700],
                    backgroundColor: _feedbackGiven == true
                      ? Colors.green[50]
                      : null,
                    side: BorderSide(
                      color: _feedbackGiven == true
                        ? Colors.green[700]!
                        : Colors.grey[400]!,
                      width: _feedbackGiven == true ? 2 : 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Thumbs down button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _feedbackGiven != null
                    ? null
                    : () => _handleFeedback(false),
                  icon: Icon(
                    _feedbackGiven == false ? Icons.thumb_down : Icons.thumb_down_outlined,
                    size: 20,
                  ),
                  label: const Text('Not Helpful'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _feedbackGiven == false
                      ? Colors.orange[700]
                      : Colors.grey[700],
                    backgroundColor: _feedbackGiven == false
                      ? Colors.orange[50]
                      : null,
                    side: BorderSide(
                      color: _feedbackGiven == false
                        ? Colors.orange[700]!
                        : Colors.grey[400]!,
                      width: _feedbackGiven == false ? 2 : 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Show thank you message after feedback
          if (_feedbackGiven != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: _feedbackGiven == true ? Colors.green[700] : Colors.orange[700],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _feedbackGiven == true
                      ? 'Feedback recorded - this helps improve accuracy!'
                      : 'Feedback recorded - we\'ll work on improving this.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClarificationContent() {
    final clarification = widget.assistance.clarification;
    if (clarification == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original vague statement
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    clarification.statement,
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Vagueness type badge
          Chip(
            label: Text(
              _getVaguenessLabel(clarification.vaguenessType),
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: Colors.orange[100],
            avatar: Icon(
              _getVaguenessIcon(clarification.vaguenessType),
              size: 16,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(height: 12),

          // Suggested questions
          Text(
            'Consider asking:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          ...clarification.suggestedQuestions.map((q) => _buildQuestionChip(q)),
        ],
      ),
    );
  }

  Widget _buildQuestionChip(String question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Clipboard.setData(ClipboardData(text: question));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied: $question'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.chat, size: 16, color: Colors.orange[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Icon(Icons.content_copy, size: 16, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConflictContent() {
    final conflict = widget.assistance.conflict;
    if (conflict == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current statement
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!, width: 2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Decision:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conflict.currentStatement,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Conflict severity badge
          Row(
            children: [
              _buildSeverityBadge(conflict.conflictSeverity),
              const SizedBox(width: 8),
              _buildConfidenceBadge(),
            ],
          ),
          const SizedBox(height: 16),

          // Conflicting past decision
          Text(
            'Conflicts with past decision:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        conflict.conflictingTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(conflict.conflictingDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  conflict.conflictingSnippet,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Reasoning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    conflict.reasoning,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Resolution suggestions
          if (conflict.resolutionSuggestions.isNotEmpty) ...[
            Text(
              'Suggested resolutions:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            ...conflict.resolutionSuggestions.map((suggestion) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionItemQualityContent() {
    final quality = widget.assistance.actionItemQuality;
    if (quality == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original action item
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[300]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.assignment, color: Colors.amber[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Original Action Item',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quality.actionItem,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.amber[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Completeness score
          Text(
            'Completeness Score',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: quality.completenessScore,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getCompletenessColor(quality.completenessScore),
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(quality.completenessScore * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getCompletenessColor(quality.completenessScore),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _getCompletenessLabel(quality.completenessScore),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Issues found
          if (quality.issues.isNotEmpty) ...[
            Text(
              'Issues Found',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            ...quality.issues.map((issue) => _buildQualityIssueChip(issue)),
          ],

          // Improved version
          if (quality.improvedVersion != null) ...[
            const SizedBox(height: 16),
            Text(
              'Suggested Improvement',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      quality.improvedVersion!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFollowUpSuggestionContent() {
    final followUp = widget.assistance.followUpSuggestion;
    if (followUp == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates, color: Colors.purple[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suggested Topic',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        followUp.topic,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.purple[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Urgency badge
          _buildUrgencyBadge(followUp.urgency),
          const SizedBox(height: 16),

          // Reason
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why now?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        followUp.reason,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Related content
          if (followUp.relatedTitle.isNotEmpty) ...[
            Text(
              'Related Content',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, size: 18, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          followUp.relatedTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(followUp.relatedDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (followUp.contextSnippet.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      followUp.contextSnippet,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Action buttons
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _handleDismiss,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Dismiss'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _handleAccept,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Discuss'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRepetitionDetectionContent() {
    final repetition = widget.assistance.repetitionDetection;
    if (repetition == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepOrange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.deepOrange[300]!, width: 2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.loop, color: Colors.deepOrange[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Repeated Topic',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        repetition.topic,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Occurrences and time span
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.deepOrange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.deepOrange[700], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Discussed ${repetition.occurrences} times over ${repetition.timeSpanMinutes.toStringAsFixed(1)} minutes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Reasoning
          Text(
            'Why this matters:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    repetition.reasoning,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Suggestions
          if (repetition.suggestions.isNotEmpty) ...[
            Text(
              'Suggestions to move forward:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            ...repetition.suggestions.take(4).map((suggestion) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.deepOrange[700],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )
            ),
          ],

          // Action buttons
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _handleDismiss,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Dismiss'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  // Handle continue action
                  widget.onDismiss?.call();
                  _animateDismiss();
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Continue'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _handleAccept,
                icon: const Icon(Icons.pause_circle_outline, size: 18),
                label: const Text('Table Discussion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyBadge(String urgency) {
    Color color;
    IconData icon;
    String label;

    switch (urgency.toLowerCase()) {
      case 'high':
        color = Colors.red;
        icon = Icons.priority_high;
        label = 'High Urgency';
        break;
      case 'medium':
        color = Colors.orange;
        icon = Icons.remove;
        label = 'Medium Urgency';
        break;
      default: // low
        color = Colors.blue;
        icon = Icons.low_priority;
        label = 'Low Urgency';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityIssueChip(QualityIssue issue) {
    IconData icon;
    Color color;

    switch (issue.severity.toLowerCase()) {
      case 'critical':
        icon = Icons.error;
        color = Colors.red;
        break;
      case 'important':
        icon = Icons.warning;
        color = Colors.orange;
        break;
      default: // suggestion
        icon = Icons.info;
        color = Colors.blue;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_getFieldLabel(issue.field)}: ${issue.message}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
            if (issue.suggestedFix != null) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      issue.suggestedFix!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getCompletenessColor(double score) {
    if (score >= 0.7) return Colors.green;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  String _getCompletenessLabel(double score) {
    if (score >= 0.7) return 'Good';
    if (score >= 0.4) return 'Fair';
    return 'Poor';
  }

  String _getFieldLabel(String field) {
    switch (field.toLowerCase()) {
      case 'owner':
        return 'Missing Owner';
      case 'deadline':
        return 'Missing Deadline';
      case 'description':
        return 'Vague Description';
      case 'success_criteria':
        return 'Success Criteria';
      default:
        return field;
    }
  }

  Widget _buildSeverityBadge(String severity) {
    Color color;
    IconData icon;
    String label;

    switch (severity.toLowerCase()) {
      case 'high':
        color = Colors.red;
        icon = Icons.error;
        label = 'High Severity';
        break;
      case 'medium':
        color = Colors.orange;
        icon = Icons.warning;
        label = 'Medium Severity';
        break;
      case 'low':
        color = Colors.yellow[700]!;
        icon = Icons.info;
        label = 'Low Severity';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
        label = 'Unknown Severity';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? "week" : "weeks"} ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  String _getVaguenessLabel(String type) {
    switch (type) {
      case 'time':
        return 'Missing Timeline';
      case 'assignment':
        return 'Missing Owner';
      case 'detail':
        return 'Missing Details';
      case 'scope':
        return 'Unclear Scope';
      default:
        return 'Needs Clarification';
    }
  }

  IconData _getVaguenessIcon(String type) {
    switch (type) {
      case 'time':
        return Icons.schedule;
      case 'assignment':
        return Icons.person_outline;
      case 'detail':
        return Icons.info_outline;
      case 'scope':
        return Icons.question_mark;
      default:
        return Icons.help_outline;
    }
  }

  IconData _getIconForType(ProactiveAssistanceType type) {
    switch (type) {
      case ProactiveAssistanceType.autoAnswer:
        return Icons.auto_awesome;
      case ProactiveAssistanceType.clarificationNeeded:
        return Icons.help_outline;
      case ProactiveAssistanceType.conflictDetected:
        return Icons.warning_amber;
      case ProactiveAssistanceType.incompleteActionItem:
        return Icons.error_outline;
      case ProactiveAssistanceType.followUpSuggestion:
        return Icons.tips_and_updates;
      case ProactiveAssistanceType.repetitionDetected:
        return Icons.loop;
    }
  }

  Color _getIconColorForType(ProactiveAssistanceType type) {
    switch (type) {
      case ProactiveAssistanceType.autoAnswer:
        return Colors.blue[700]!;
      case ProactiveAssistanceType.clarificationNeeded:
        return Colors.orange[700]!;
      case ProactiveAssistanceType.conflictDetected:
        return Colors.red[700]!;
      case ProactiveAssistanceType.incompleteActionItem:
        return Colors.amber[700]!;
      case ProactiveAssistanceType.followUpSuggestion:
        return Colors.purple[700]!;
      case ProactiveAssistanceType.repetitionDetected:
        return Colors.deepOrange[700]!;
    }
  }

  String _getTitleForType(ProactiveAssistanceType type) {
    switch (type) {
      case ProactiveAssistanceType.autoAnswer:
        return '💡 AI Auto-Answered';
      case ProactiveAssistanceType.clarificationNeeded:
        return '❓ Clarification Needed';
      case ProactiveAssistanceType.conflictDetected:
        return '⚠️ Potential Conflict';
      case ProactiveAssistanceType.incompleteActionItem:
        return '📝 Incomplete Action Item';
      case ProactiveAssistanceType.followUpSuggestion:
        return '💭 Follow-up Suggestion';
      case ProactiveAssistanceType.repetitionDetected:
        return 'Repetitive Discussion Detected';
    }
  }

  String? _getSubtitleForType() {
    switch (widget.assistance.type) {
      case ProactiveAssistanceType.autoAnswer:
        return widget.assistance.autoAnswer?.question;
      case ProactiveAssistanceType.clarificationNeeded:
        return widget.assistance.clarification?.statement;
      case ProactiveAssistanceType.conflictDetected:
        return widget.assistance.conflict?.currentStatement;
      case ProactiveAssistanceType.followUpSuggestion:
        return widget.assistance.followUpSuggestion?.topic;
      case ProactiveAssistanceType.repetitionDetected:
        return widget.assistance.repetitionDetection?.topic;
      default:
        return null;
    }
  }

  Color _getBackgroundColor() {
    switch (widget.assistance.type) {
      case ProactiveAssistanceType.autoAnswer:
        return Colors.blue[50]!;
      case ProactiveAssistanceType.clarificationNeeded:
        return Colors.orange[50]!;
      case ProactiveAssistanceType.conflictDetected:
        return Colors.red[50]!;
      case ProactiveAssistanceType.incompleteActionItem:
        return Colors.amber[50]!;
      case ProactiveAssistanceType.followUpSuggestion:
        return Colors.purple[50]!;
      case ProactiveAssistanceType.repetitionDetected:
        return Colors.deepOrange[50]!;
    }
  }

  Color _getBorderColor() {
    switch (widget.assistance.type) {
      case ProactiveAssistanceType.autoAnswer:
        return Colors.blue[300]!;
      case ProactiveAssistanceType.clarificationNeeded:
        return Colors.orange[300]!;
      case ProactiveAssistanceType.conflictDetected:
        return Colors.red[300]!;
      case ProactiveAssistanceType.incompleteActionItem:
        return Colors.amber[300]!;
      case ProactiveAssistanceType.followUpSuggestion:
        return Colors.purple[300]!;
      case ProactiveAssistanceType.repetitionDetected:
        return Colors.deepOrange[300]!;
    }
  }
}
