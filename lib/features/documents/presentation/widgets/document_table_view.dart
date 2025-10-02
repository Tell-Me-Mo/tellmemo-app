import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/datetime_utils.dart';
import '../../../meetings/domain/entities/content.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import 'document_detail_dialog.dart';

enum SortColumn { type, title, project, date, status, summary }
enum SortDirection { asc, desc }

class DocumentTableView extends ConsumerStatefulWidget {
  final List<Content> documents;
  final Function(Content) onDocumentTap;

  const DocumentTableView({
    super.key,
    required this.documents,
    required this.onDocumentTap,
  });

  @override
  ConsumerState<DocumentTableView> createState() => _DocumentTableViewState();
}

class _DocumentTableViewState extends ConsumerState<DocumentTableView> {
  int? hoveredIndex;
  SortColumn? sortColumn;
  SortDirection sortDirection = SortDirection.desc;
  ContentType? typeFilter;
  String? projectFilter;
  bool? statusFilter; // null = all, true = processed, false = not processed
  bool? summaryFilter; // null = all, true = has summary, false = no summary

  List<Content> get filteredAndSortedDocuments {
    var docs = widget.documents.toList();

    // Apply filters
    if (typeFilter != null) {
      docs = docs.where((d) => d.contentType == typeFilter).toList();
    }
    if (projectFilter != null && projectFilter!.isNotEmpty) {
      docs = docs.where((d) => d.projectId == projectFilter).toList();
    }
    if (statusFilter != null) {
      docs = docs.where((d) => d.isProcessed == statusFilter).toList();
    }
    if (summaryFilter != null) {
      docs = docs.where((d) => d.summaryGenerated == summaryFilter).toList();
    }

    // Apply sorting
    if (sortColumn != null) {
      docs.sort((a, b) {
        int comparison = 0;
        switch (sortColumn!) {
          case SortColumn.type:
            comparison = a.contentType.index.compareTo(b.contentType.index);
            break;
          case SortColumn.title:
            comparison = a.title.compareTo(b.title);
            break;
          case SortColumn.project:
            comparison = a.projectId.compareTo(b.projectId);
            break;
          case SortColumn.date:
            final dateA = a.date ?? a.uploadedAt;
            final dateB = b.date ?? b.uploadedAt;
            comparison = dateA.compareTo(dateB);
            break;
          case SortColumn.status:
            comparison = (a.isProcessed ? 1 : 0).compareTo(b.isProcessed ? 1 : 0);
            break;
          case SortColumn.summary:
            comparison = (a.summaryGenerated ? 1 : 0).compareTo(b.summaryGenerated ? 1 : 0);
            break;
        }
        return sortDirection == SortDirection.asc ? comparison : -comparison;
      });
    }

    return docs;
  }

  void _toggleSort(SortColumn column) {
    setState(() {
      if (sortColumn == column) {
        sortDirection = sortDirection == SortDirection.asc
            ? SortDirection.desc
            : SortDirection.asc;
      } else {
        sortColumn = column;
        sortDirection = SortDirection.desc;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final projects = ref.watch(projectsListProvider).valueOrNull ?? [];
    final sortedDocuments = filteredAndSortedDocuments;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildTableHeader(context, isDesktop, projects),
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.08),
          ),
          // Body
          ...sortedDocuments.asMap().entries.map((entry) => _buildTableRow(
            context,
            entry.value,
            entry.key,
            isDesktop,
            projects,
          )),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context, bool isDesktop, List projects) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      height: 44, // Same height as search input field
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          // Type column with filter (hidden on mobile)
          if (!isMobile) ...[
            _buildHeaderCell(
              context,
              'TYPE',
              80,
              SortColumn.type,
              filterWidget: PopupMenuButton<ContentType?>(
                icon: Icon(
                  Icons.filter_list,
                  size: 14,
                  color: typeFilter != null
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                onSelected: (value) {
                  setState(() {
                    typeFilter = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: null,
                    child: Text('All Types'),
                  ),
                  const PopupMenuItem(
                    value: ContentType.meeting,
                    child: Text('Meetings'),
                  ),
                  const PopupMenuItem(
                    value: ContentType.email,
                    child: Text('Emails'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          // Title column
          Expanded(
            flex: 2,
            child: _buildHeaderCell(
              context,
              isMobile ? '' : 'TITLE',
              null,
              SortColumn.title,
            ),
          ),
          // Project column
          if (isDesktop) ...[
            const SizedBox(width: 16),
            SizedBox(
              width: 180,
              child: _buildHeaderCell(
                context,
                'PROJECT',
                180,
                SortColumn.project,
                filterWidget: PopupMenuButton<String?>(
                  icon: Icon(
                    Icons.filter_list,
                    size: 14,
                    color: projectFilter != null
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  onSelected: (value) {
                    setState(() {
                      projectFilter = value;
                    });
                  },
                  itemBuilder: (context) {
                    final uniqueProjectIds = widget.documents
                        .map((d) => d.projectId)
                        .toSet()
                        .toList();

                    return [
                      const PopupMenuItem(
                        value: null,
                        child: Text('All Projects'),
                      ),
                      ...uniqueProjectIds.map((projectId) {
                        final project = projects.cast<dynamic>().firstWhere(
                          (p) => p.id == projectId,
                          orElse: () => null,
                        );
                        return PopupMenuItem(
                          value: projectId,
                          child: Text(project?.name ?? 'Unknown'),
                        );
                      }),
                    ];
                  },
                ),
              ),
            ),
          ],
          // Date column
          if (isDesktop) ...[
            const SizedBox(width: 16),
            SizedBox(
              width: 120,
              child: _buildHeaderCell(
                context,
                'DATE',
                120,
                SortColumn.date,
              ),
            ),
          ],
          // Status column with filter
          const SizedBox(width: 12),
          SizedBox(
            width: isMobile ? 100 : 120,
            child: _buildHeaderCell(
              context,
              'STATUS',
              isMobile ? 100 : 120,
              SortColumn.status,
              filterWidget: !isMobile ? PopupMenuButton<bool?>(
                icon: Icon(
                  Icons.filter_list,
                  size: 14,
                  color: statusFilter != null
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                onSelected: (value) {
                  setState(() {
                    statusFilter = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: null,
                    child: Text('All'),
                  ),
                  const PopupMenuItem(
                    value: true,
                    child: Text('Processed'),
                  ),
                  const PopupMenuItem(
                    value: false,
                    child: Text('Not Processed'),
                  ),
                ],
              ) : null,
            ),
          ),
          // Summary column with filter
          const SizedBox(width: 12),
          SizedBox(
            width: isMobile ? 90 : 120,
            child: _buildHeaderCell(
              context,
              'SUMMARY',
              isMobile ? 90 : 120,
              SortColumn.summary,
              filterWidget: !isMobile ? PopupMenuButton<bool?>(
                icon: Icon(
                  Icons.filter_list,
                  size: 14,
                  color: summaryFilter != null
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                onSelected: (value) {
                  setState(() {
                    summaryFilter = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: null,
                    child: Text('All'),
                  ),
                  const PopupMenuItem(
                    value: true,
                    child: Text('Has Summary'),
                  ),
                  const PopupMenuItem(
                    value: false,
                    child: Text('No Summary'),
                  ),
                ],
              ) : null,
            ),
          ),
          // Actions
          SizedBox(width: isMobile ? 16 : 32),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    BuildContext context,
    String label,
    double? width,
    SortColumn column, {
    Widget? filterWidget,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = sortColumn == column;

    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      color: isActive
          ? colorScheme.primary
          : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );

    Widget content = InkWell(
      onTap: () => _toggleSort(column),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisSize: width != null ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Flexible(
              fit: width != null ? FlexFit.loose : FlexFit.loose,
              child: Text(label, style: headerStyle, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 4),
            if (isActive)
              Icon(
                sortDirection == SortDirection.asc
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 14,
                color: colorScheme.primary,
              )
            else
              Icon(
                Icons.unfold_more,
                size: 14,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            if (filterWidget != null) ...[
              const SizedBox(width: 4),
              filterWidget,
            ],
          ],
        ),
      ),
    );

    return width != null
        ? SizedBox(width: width, child: content)
        : content;
  }

  Widget _buildTableRow(
    BuildContext context,
    Content document,
    int index,
    bool isDesktop,
    List projects,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    // Use uploadedAt for display since it has the actual upload timestamp
    // document.date might just be a date without time
    final date = document.uploadedAt;
    final isHovered = hoveredIndex == index;

    final project = projects.cast<dynamic>().firstWhere(
      (p) => p.id == document.projectId,
      orElse: () => null,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => hoveredIndex = index),
      onExit: (_) => setState(() => hoveredIndex = null),
      child: Material(
        color: isHovered
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.05)
          : Colors.transparent,
        child: InkWell(
          onTap: () => widget.onDocumentTap(document),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: isMobile ? 12 : 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: Row(
              children: [
                // Type icon (hidden on mobile)
                if (!isMobile) ...[
                  SizedBox(
                    width: 80,
                    child: _buildTypeIcon(document.contentType, colorScheme),
                  ),
                  const SizedBox(width: 12),
                ],
                // Title with type icon inline on mobile
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      if (isMobile) ...[
                        _buildTypeIcon(document.contentType, colorScheme),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          document.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: isMobile ? 13 : null,
                          ),
                          maxLines: isMobile ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Project
                if (isDesktop) ...[
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 180,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        project?.name ?? 'Unknown',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                // Date
                if (isDesktop) ...[
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 120,
                    child: Text(
                      DateTimeUtils.formatRelativeTime(date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
                // Status
                SizedBox(width: isMobile ? 8 : 16),
                SizedBox(
                  width: isMobile ? 100 : 120,
                  child: _buildStatusBadge(document, theme, colorScheme, isMobile: isMobile),
                ),
                // Summary
                SizedBox(width: isMobile ? 8 : 16),
                SizedBox(
                  width: isMobile ? 90 : 120,
                  child: _buildSummaryIndicator(document, theme, colorScheme, isMobile: isMobile),
                ),
                // Actions
                SizedBox(width: isMobile ? 8 : 16),
                if (!isMobile)
                  SizedBox(
                    width: 16,
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(ContentType type, ColorScheme colorScheme) {
    Color iconColor;
    IconData icon;

    switch (type) {
      case ContentType.meeting:
        iconColor = Colors.blue.shade600;
        icon = Icons.videocam;
        break;
      case ContentType.email:
        iconColor = Colors.orange.shade600;
        icon = Icons.email;
        break;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 14,
      ),
    );
  }

  Widget _buildStatusBadge(Content doc, ThemeData theme, ColorScheme colorScheme, {bool isMobile = false}) {
    String label;
    Color color;
    IconData icon;

    if (doc.isProcessed) {
      label = 'Processed';
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (doc.isProcessing) {
      label = 'Processing';
      color = Colors.orange;
      icon = Icons.schedule;
    } else if (doc.hasError) {
      label = 'Error';
      color = colorScheme.error;
      icon = Icons.error;
    } else {
      label = 'Pending';
      color = Colors.grey;
      icon = Icons.hourglass_empty;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isMobile ? 10 : 12,
            color: color,
          ),
          SizedBox(width: isMobile ? 2 : 4),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: isMobile ? 10 : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryIndicator(Content doc, ThemeData theme, ColorScheme colorScheme, {bool isMobile = false}) {
    if (doc.summaryGenerated) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.summarize,
              size: isMobile ? 10 : 12,
              color: Colors.purple,
            ),
            SizedBox(width: isMobile ? 2 : 4),
            Flexible(
              child: Text(
                'Available',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.purple,
                  fontWeight: FontWeight.w500,
                  fontSize: isMobile ? 10 : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    } else {
      return Text(
        '-',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          fontSize: isMobile ? 10 : null,
        ),
      );
    }
  }

}