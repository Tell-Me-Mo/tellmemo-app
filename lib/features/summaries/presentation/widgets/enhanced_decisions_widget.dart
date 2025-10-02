import 'package:flutter/material.dart';
import '../../data/models/summary_model.dart';

class EnhancedDecisionsWidget extends StatelessWidget {
  final List<Decision> decisions;

  const EnhancedDecisionsWidget({
    super.key,
    required this.decisions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: decisions.asMap().entries.map((entry) {
        final index = entry.key;
        final decision = entry.value;
        return _buildDecisionCard(context, decision, index);
      }).toList(),
    );
  }

  Widget _buildDecisionCard(BuildContext context, Decision decision, int index) {
    final theme = Theme.of(context);
    final importanceColor = _getImportanceColor(decision.importanceScore);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority indicator
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: importanceColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Decision text
                Text(
                  decision.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
                ),

                // Show rationale only if it's short and adds value
                if (decision.rationale != null &&
                    decision.rationale!.isNotEmpty &&
                    decision.rationale!.length < 100) ...[
                  const SizedBox(height: 4),
                  Text(
                    decision.rationale!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Priority label (only for high priority)
          if (_isHighPriority(decision.importanceScore))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: importanceColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatImportance(decision.importanceScore).toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: importanceColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isHighPriority(String importance) {
    final numericScore = int.tryParse(importance);
    if (numericScore != null) {
      return numericScore >= 7; // High/Critical
    }

    switch (importance.toLowerCase()) {
      case 'critical':
      case 'major':
      case 'high':
        return true;
      default:
        return false;
    }
  }

  Color _getImportanceColor(String importance) {
    final numericScore = int.tryParse(importance);
    if (numericScore != null) {
      if (numericScore >= 8) return Colors.red.shade600;
      if (numericScore >= 6) return Colors.orange.shade600;
      if (numericScore >= 4) return Colors.blue.shade600;
      return Colors.green.shade600;
    }

    switch (importance.toLowerCase()) {
      case 'critical':
        return Colors.red.shade600;
      case 'major':
        return Colors.orange.shade600;
      case 'minor':
        return Colors.green.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  String _formatImportance(String importance) {
    final numericScore = int.tryParse(importance);
    if (numericScore != null) {
      if (numericScore >= 8) return 'Critical';
      if (numericScore >= 6) return 'High';
      if (numericScore >= 4) return 'Medium';
      return 'Low';
    }

    return importance.split(' ').map((word) {
      return word.isNotEmpty
        ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
        : '';
    }).join(' ');
  }
}