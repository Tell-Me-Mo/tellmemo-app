import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../data/models/summary_model.dart';

class SummaryCard extends StatelessWidget {
  final SummaryModel summary;
  final VoidCallback? onTap;
  final VoidCallback? onExport;

  const SummaryCard({
    super.key,
    required this.summary,
    this.onTap,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(
        horizontal: LayoutConstants.paddingMedium,
        vertical: LayoutConstants.paddingSmall,
      ),
      child: InkWell(
        onTap: onTap ?? () {
          context.push('/summaries/${summary.id}');
        },
        borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 150,
            maxHeight: 400,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(LayoutConstants.paddingMedium),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header with type badge and date
              Row(
                children: [
                  _buildTypeBadge(context),
                  const SizedBox(width: 6),
                  _buildFormatBadge(context),
                  const SizedBox(width: LayoutConstants.paddingSmall),
                  Expanded(
                    child: Text(
                      summary.subject,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (value) {
                      if (value == 'export') {
                        onExport?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'export',
                        child: ListTile(
                          leading: Icon(Icons.download, size: 20),
                          title: Text('Export as PDF'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: LayoutConstants.paddingSmall),
              
              // Date information
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    (summary.summaryType == SummaryType.project ||
                     summary.summaryType == SummaryType.program ||
                     summary.summaryType == SummaryType.portfolio)
                        ? '${dateFormat.format(summary.dateRangeStart ?? summary.createdAt)} - ${dateFormat.format(summary.dateRangeEnd ?? summary.createdAt)}'
                        : dateFormat.format(summary.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: LayoutConstants.paddingSmall),
              
              // Key points section
              if (summary.keyPoints != null && summary.keyPoints!.isNotEmpty) ...[
                _buildSection(
                  context,
                  title: 'Key Points',
                  icon: Icons.lightbulb_outline,
                  items: summary.keyPoints!,
                  maxItems: 2,
                ),
              ],
              
              // Decisions section
              if (summary.decisions != null && summary.decisions!.isNotEmpty) ...[
                _buildSection(
                  context,
                  title: 'Decisions',
                  icon: Icons.check_circle_outline,
                  items: summary.decisions!.map((d) => d.description).toList(),
                  maxItems: 1,
                ),
                const SizedBox(height: 4),
              ],
              
              // Action items section
              if (summary.actionItems != null && summary.actionItems!.isNotEmpty) ...[
                _buildSection(
                  context,
                  title: 'Action Items',
                  icon: Icons.assignment_outlined,
                  items: summary.actionItems!.map((a) => a.description).toList(),
                  maxItems: 1,
                ),
              ],
              
              // Next Meeting Agenda section (only for meeting summaries)
              if (summary.summaryType == SummaryType.meeting &&
                  summary.nextMeetingAgenda != null && 
                  summary.nextMeetingAgenda!.isNotEmpty) ...[
                _buildSection(
                  context,
                  title: 'Next Meeting Agenda',
                  icon: Icons.event_note,
                  items: summary.nextMeetingAgenda!.map((a) => a.title).toList(),
                  maxItems: 2,
                ),
              ],
              
              // Footer with metadata
              const SizedBox(height: 4),
              Row(
                children: [
                  if (summary.tokenCount != null) ...[
                    Icon(
                      Icons.token,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${summary.tokenCount} tokens',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: LayoutConstants.paddingMedium),
                  ],
                  if (summary.llmCost != null) ...[
                    Icon(
                      Icons.attach_money,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '\$${summary.llmCost!.toStringAsFixed(4)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: LayoutConstants.paddingMedium),
                  ],
                  if (summary.generationTimeMs != null) ...[
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(summary.generationTimeMs! / 1000).toStringAsFixed(1)}s',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onTap ?? () {
                      context.push('/summaries/${summary.id}');
                    },
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('View Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildFormatBadge(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final format = summary.format.toLowerCase();
    IconData icon;
    Color color;
    String label;

    switch (format) {
      case 'executive':
        icon = Icons.business_center;
        color = Colors.purple;
        label = 'Executive';
        break;
      case 'technical':
        icon = Icons.code;
        color = Colors.blue;
        label = 'Technical';
        break;
      case 'stakeholder':
        icon = Icons.groups;
        color = Colors.green;
        label = 'Stakeholder';
        break;
      case 'general':
      default:
        icon = Icons.dashboard;
        color = colorScheme.tertiary;
        label = 'General';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color color;
    IconData icon;
    String label;

    switch (summary.summaryType) {
      case SummaryType.project:
        color = colorScheme.primary;
        icon = Icons.calendar_view_week;
        label = 'Project Summary';
        break;
      case SummaryType.meeting:
        color = colorScheme.secondary;
        icon = Icons.meeting_room;
        label = 'Meeting Summary';
        break;
      case SummaryType.program:
        color = colorScheme.tertiary;
        icon = Icons.folder;
        label = 'Program Summary';
        break;
      case SummaryType.portfolio:
        color = Colors.deepPurple;
        icon = Icons.business_center;
        label = 'Portfolio Summary';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LayoutConstants.paddingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> items,
    int maxItems = 3,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayItems = items.take(maxItems).toList();
    final hasMore = items.length > maxItems;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...displayItems.map((item) => Padding(
          padding: const EdgeInsets.only(
            left: 20,
            top: 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        )),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              top: 4,
            ),
            child: Text(
              '+ ${items.length - maxItems} more',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

}