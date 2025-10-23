import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/models/live_insight_model.dart';

/// Debug overlay showing processing decision metadata
///
/// Only visible in debug mode or for admin users.
/// Provides transparency into why and how insights were processed.
class ProcessingMetadataOverlay extends StatelessWidget {
  final ProcessingMetadata metadata;
  final bool isAdmin;

  const ProcessingMetadataOverlay({
    super.key,
    required this.metadata,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode or for admin users
    if (!kDebugMode && !isAdmin) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.black.withValues(alpha: 0.85),
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        leading: const Icon(
          Icons.bug_report,
          color: Colors.amber,
          size: 20,
        ),
        title: const Text(
          'Processing Metadata',
          style: TextStyle(
            color: Colors.amber,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Trigger: ${metadata.trigger ?? "unknown"}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  'Insight Processing Decision',
                  [
                    _buildRow('Trigger', metadata.trigger ?? 'N/A'),
                    _buildRow('Priority', metadata.priority ?? 'N/A'),
                    _buildRow(
                      'Semantic Score',
                      metadata.semanticScore != null
                          ? metadata.semanticScore!.toStringAsFixed(3)
                          : 'N/A',
                    ),
                    _buildRow(
                      'Signals Detected',
                      metadata.signalsDetected.isEmpty
                          ? 'None'
                          : metadata.signalsDetected.join(', '),
                    ),
                    _buildRow(
                      'Chunks Accumulated',
                      metadata.chunksAccumulated.toString(),
                    ),
                    if (metadata.decisionReason != null)
                      _buildRow('Decision Reason', metadata.decisionReason!),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSection(
                  'Proactive Assistance Processing',
                  [
                    _buildRow(
                      'Active Phases',
                      metadata.activePhases.isEmpty
                          ? 'None'
                          : metadata.activePhases.join(', '),
                    ),
                    _buildRow(
                      'Skipped Phases',
                      metadata.skippedPhases.isEmpty
                          ? 'None'
                          : metadata.skippedPhases.join(', '),
                    ),
                    if (metadata.phaseExecutionTimesMs.isNotEmpty)
                      ..._buildPhaseTimings(metadata.phaseExecutionTimesMs),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        ...children,
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPhaseTimings(Map<String, double> timings) {
    return [
      const Text(
        'Phase Execution Times:',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 4),
      ...timings.entries.map((entry) {
        final phase = entry.key;
        final timeMs = entry.value.toStringAsFixed(1);
        return Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 2),
          child: Text(
            '• $phase: ${timeMs}ms',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
        );
      }),
    ];
  }
}
