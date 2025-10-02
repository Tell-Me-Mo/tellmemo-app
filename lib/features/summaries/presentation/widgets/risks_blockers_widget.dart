import 'package:flutter/material.dart';

class RisksBlockersWidget extends StatelessWidget {
  final List<Map<String, dynamic>>? risks;
  final List<Map<String, dynamic>>? blockers;

  const RisksBlockersWidget({
    super.key,
    this.risks,
    this.blockers,
  });

  @override
  Widget build(BuildContext context) {
    final hasRisks = risks?.isNotEmpty ?? false;
    final hasBlockers = blockers?.isNotEmpty ?? false;

    if (!hasRisks && !hasBlockers) {
      return _buildEmptyState(context);
    }

    final risksData = risks ?? [];
    final blockersData = blockers ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Risks
        if (risksData.isNotEmpty) ...[
          ...risksData.map((risk) => _buildRiskItem(context, risk, true)),
        ],

        // Blockers
        if (blockersData.isNotEmpty) ...[
          if (risksData.isNotEmpty) const SizedBox(height: 8),
          ...blockersData.map((blocker) => _buildRiskItem(context, blocker, false)),
        ],
      ],
    );
  }

  Widget _buildRiskItem(BuildContext context, Map<String, dynamic> item, bool isRisk) {
    final theme = Theme.of(context);
    final severity = item['severity'] ?? item['priority'] ?? 'medium';
    final severityColor = _getSeverityColor(severity);
    final description = item['description'] ?? item['title'] ?? 'Unknown ${isRisk ? 'risk' : 'blocker'}';
    final mitigation = item['mitigation'] ?? item['resolution'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity indicator
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: severityColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
                ),

                // Show mitigation if available and concise
                if (mitigation != null && mitigation.toString().length < 150) ...[
                  const SizedBox(height: 4),
                  Text(
                    mitigation.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Type and severity indicator
          if (_isHighSeverity(severity))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${isRisk ? 'RISK' : 'BLOCKER'} • ${_formatSeverity(severity).toUpperCase()}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: severityColor,
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'No risks or blockers identified',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  bool _isHighSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'high':
      case 'urgent':
        return true;
      default:
        return false;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red.shade600;
      case 'high':
        return Colors.orange.shade600;
      case 'medium':
        return Colors.blue.shade600;
      case 'low':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatSeverity(String severity) {
    return severity.split(' ').map((word) {
      return word.isNotEmpty
        ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
        : '';
    }).join(' ');
  }
}