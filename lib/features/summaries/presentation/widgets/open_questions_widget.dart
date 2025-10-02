import 'package:flutter/material.dart';
import '../../data/models/summary_model.dart';

class OpenQuestionsWidget extends StatelessWidget {
  final List<UnansweredQuestion> questions;

  const OpenQuestionsWidget({
    super.key,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (questions.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: questions.asMap().entries.map((entry) {
        final index = entry.key;
        final question = entry.value;
        return _buildQuestionCard(context, question, index == questions.length - 1);
      }).toList(),
    );
  }

  Widget _buildQuestionCard(BuildContext context, UnansweredQuestion question, bool isLast) {
    final theme = Theme.of(context);
    final urgencyColor = _getUrgencyColor(question.urgency);

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bullet point
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: urgencyColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question text
                Text(
                  question.question,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
                ),

                // Context (if available and concise)
                if (question.context.isNotEmpty && question.context.length < 150) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Context: ${question.context}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Urgency label (only for high urgency)
          if (question.urgency == 'high' || question.urgency == 'critical')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: urgencyColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                question.urgency.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: urgencyColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 24,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 12),
          Text(
            'No open questions',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return Colors.red.shade600;
      case 'medium':
        return Colors.orange.shade600;
      case 'low':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}