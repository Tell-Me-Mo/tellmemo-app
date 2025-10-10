import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../providers/query_provider.dart';
import '../../../../core/services/notification_service.dart';

class QueryResponseCard extends ConsumerWidget {
  final ConversationItem response;
  final String query;

  const QueryResponseCard({
    super.key,
    required this.response,
    required this.query,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with query
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.question_answer,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    query,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                // Copy button
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: 'Copy response',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: response.answer));
                    ref.read(notificationServiceProvider.notifier).showInfo('Response copied to clipboard');
                  },
                ),
              ],
            ),
          ),
          
          // Response body with markdown
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Confidence indicator
                _buildConfidenceIndicator(theme, response.confidence),
                const SizedBox(height: 16),
                
                // Markdown response
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: Markdown(
                    data: response.answer,
                    shrinkWrap: true,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodyLarge,
                      h1: theme.textTheme.headlineMedium,
                      h2: theme.textTheme.headlineSmall,
                      h3: theme.textTheme.titleLarge,
                      h4: theme.textTheme.titleMedium,
                      h5: theme.textTheme.titleSmall,
                      blockquote: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      code: TextStyle(
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      listBullet: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
                
                // Sources section
                if (response.sources.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSourcesSection(theme, response.sources),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(ThemeData theme, double confidence) {
    final colorScheme = theme.colorScheme;
    final confidencePercent = (confidence * 100).toInt();
    final confidenceColor = confidence > 0.7
        ? Colors.green
        : confidence > 0.4
            ? Colors.orange
            : Colors.red;

    return Row(
      children: [
        Icon(
          Icons.insights,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          'Confidence: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: confidenceColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$confidencePercent%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: confidenceColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSourcesSection(ThemeData theme, List<String> sources) {
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.source,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'Sources',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sources.map((source) {
            return Chip(
              label: Text(
                source,
                style: theme.textTheme.bodySmall,
              ),
              backgroundColor: colorScheme.secondaryContainer.withOpacity(0.5),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
      ],
    );
  }
}