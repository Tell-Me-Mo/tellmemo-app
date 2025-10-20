import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/proactive_assistance_model.dart';

/// Card widget for displaying proactive AI assistance
/// Phase 1: Auto-answered questions
/// Phase 2: Clarification suggestions
class ProactiveAssistanceCard extends StatefulWidget {
  final ProactiveAssistanceModel assistance;
  final VoidCallback? onAccept;
  final VoidCallback? onDismiss;
  final VoidCallback? onViewSource;

  const ProactiveAssistanceCard({
    Key? key,
    required this.assistance,
    this.onAccept,
    this.onDismiss,
    this.onViewSource,
  }) : super(key: key);

  @override
  State<ProactiveAssistanceCard> createState() =>
      _ProactiveAssistanceCardState();
}

class _ProactiveAssistanceCardState extends State<ProactiveAssistanceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = true;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
      default:
        return const SizedBox.shrink();
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
                label: const Text('Helpful'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
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
    }
  }

  String? _getSubtitleForType() {
    switch (widget.assistance.type) {
      case ProactiveAssistanceType.autoAnswer:
        return widget.assistance.autoAnswer?.question;
      case ProactiveAssistanceType.clarificationNeeded:
        return widget.assistance.clarification?.statement;
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
      default:
        return Colors.grey[100]!;
    }
  }

  Color _getBorderColor() {
    switch (widget.assistance.type) {
      case ProactiveAssistanceType.autoAnswer:
        return Colors.blue[300]!;
      case ProactiveAssistanceType.clarificationNeeded:
        return Colors.orange[300]!;
      default:
        return Colors.grey[300]!;
    }
  }
}
