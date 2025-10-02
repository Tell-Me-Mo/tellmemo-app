import 'package:flutter/material.dart';
import '../../data/models/summary_model.dart';

class CommunicationInsightsWidget extends StatelessWidget {
  final CommunicationInsights? communicationInsights;

  const CommunicationInsightsWidget({
    super.key,
    required this.communicationInsights,
  });

  @override
  Widget build(BuildContext context) {
    if (communicationInsights == null || communicationInsights!.effectivenessScore == null) {
      return const SizedBox.shrink();
    }

    return _buildEffectivenessScore(context);
  }

  Widget _buildInsightColumn(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(
                  color: color.withValues(alpha: 0.5),
                  width: 3,
                ),
              ),
            ),
            child: Text(
              item,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEffectivenessScore(BuildContext context) {
    final theme = Theme.of(context);
    final score = communicationInsights!.effectivenessScore!;
    final color = _getScoreColor(score);
    final label = _getScoreLabel(score);
    final overallPercent = (score.overall * 100).toInt();

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
                    Icons.speed_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Communication Effectiveness',
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
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Score display
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$overallPercent',
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

          const SizedBox(height: 20),

          // Score breakdown bars
          Column(
            children: [
              _buildMetricRow(context, 'Clarity', score.clarityScore),
              const SizedBox(height: 12),
              _buildMetricRow(context, 'Efficiency', score.timeEfficiency),
              const SizedBox(height: 12),
              _buildMetricRow(context, 'Participation', score.participationBalance),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(BuildContext context, String label, double value) {
    final theme = Theme.of(context);
    final percent = (value * 100).toInt();

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: value.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: _getMetricColor(label),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '$percent%',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _getMetricColor(String metric) {
    switch (metric) {
      case 'Clarity':
        return Colors.blue.shade600;
      case 'Efficiency':
        return Colors.green.shade600;
      case 'Participation':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildScoreBar(BuildContext context, String label, double value, Color color) {
    final theme = Theme.of(context);
    final percent = (value * 100).toInt();

    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$percent%',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState(BuildContext context) {
    return const SizedBox.shrink();
  }

  Color _getScoreColor(EffectivenessScore score) {
    final overall = score.overall;
    if (overall >= 0.8) return Colors.green.shade600;
    if (overall >= 0.6) return Colors.blue.shade600;
    if (overall >= 0.4) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  String _getScoreLabel(EffectivenessScore score) {
    final overall = score.overall;
    if (overall >= 0.8) return 'Excellent';
    if (overall >= 0.6) return 'Good';
    if (overall >= 0.4) return 'Fair';
    return 'Needs Improvement';
  }

  IconData _getScoreIcon(EffectivenessScore score) {
    final overall = score.overall;
    if (overall >= 0.8) return Icons.check_circle_outline;
    if (overall >= 0.6) return Icons.thumb_up_outlined;
    if (overall >= 0.4) return Icons.warning_outlined;
    return Icons.error_outline;
  }
}