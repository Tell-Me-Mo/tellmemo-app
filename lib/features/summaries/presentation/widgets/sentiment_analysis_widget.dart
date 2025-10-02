import 'package:flutter/material.dart';

class SentimentAnalysisWidget extends StatelessWidget {
  final Map<String, dynamic>? sentimentData;

  const SentimentAnalysisWidget({
    super.key,
    required this.sentimentData,
  });

  @override
  Widget build(BuildContext context) {
    if (sentimentData == null || sentimentData!.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final overallScore = sentimentData!['overall_score'] as double? ?? 0.0;
    final sentiment = _getSentimentLabel(overallScore);
    final color = _getSentimentColor(overallScore);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.mood_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Meeting Sentiment',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sentiment,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Score and icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getSentimentIcon(overallScore),
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(overallScore * 100).toInt()}',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 2),
                        child: Text(
                          '%',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _getSentimentDescription(overallScore),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Progress bar
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: overallScore.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),

          // Key insights (if available)
          if (sentimentData!['key_insights'] != null) ...[
            const SizedBox(height: 20),
            ..._buildKeyInsights(context),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildKeyInsights(BuildContext context) {
    final theme = Theme.of(context);
    final insights = sentimentData!['key_insights'] as List<dynamic>? ?? [];

    return insights.take(3).map((insight) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              insight.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }

  Widget _buildNoDataState(BuildContext context) {
    return const SizedBox.shrink();
  }

  String _getSentimentLabel(double score) {
    if (score >= 0.6) return 'Positive';
    if (score >= 0.4) return 'Neutral';
    if (score >= 0.2) return 'Mixed';
    return 'Negative';
  }

  Color _getSentimentColor(double score) {
    if (score >= 0.6) return Colors.green.shade600;
    if (score >= 0.4) return Colors.blue.shade600;
    if (score >= 0.2) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  IconData _getSentimentIcon(double score) {
    if (score >= 0.6) return Icons.sentiment_very_satisfied_outlined;
    if (score >= 0.4) return Icons.sentiment_neutral_outlined;
    if (score >= 0.2) return Icons.sentiment_dissatisfied_outlined;
    return Icons.sentiment_very_dissatisfied_outlined;
  }

  String _getSentimentDescription(double score) {
    if (score >= 0.6) return 'Overall positive engagement and collaborative tone';
    if (score >= 0.4) return 'Balanced discussion with neutral sentiment';
    if (score >= 0.2) return 'Mixed reactions with some concerns raised';
    return 'Challenges or conflicts detected in discussion';
  }
}