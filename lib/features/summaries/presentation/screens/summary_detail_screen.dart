import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../core/widgets/breadcrumb_navigation.dart';
import '../../data/models/summary_model.dart';
import '../providers/summary_provider.dart';
import '../widgets/format_aware_summary_viewer.dart';
import '../widgets/summary_export_dialog.dart';
import '../../../queries/presentation/widgets/ask_ai_panel.dart';

class SummaryDetailScreen extends ConsumerStatefulWidget {
  final String summaryId;
  final String? fromRoute;  // Track where we came from
  final String? parentEntityName;  // Optional parent entity name

  const SummaryDetailScreen({
    super.key,
    required this.summaryId,
    this.fromRoute,
    this.parentEntityName,
  });

  @override
  ConsumerState<SummaryDetailScreen> createState() => _SummaryDetailScreenState();
}

class _SummaryDetailScreenState extends ConsumerState<SummaryDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load summary when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSummary();
    });
  }

  void _loadSummary() {
    // Load summary without requiring a selected project
    // The backend will determine the entity type from the summary itself
    ref.read(summaryDetailProvider.notifier).loadSummary(
      null,  // No project ID needed with new endpoint
      widget.summaryId,
    ).then((_) {
      // Summary loaded successfully
    });
  }

  @override
  Widget build(BuildContext context) {
    final summaryState = ref.watch(summaryDetailProvider);

    // Build the scaffold directly without requiring project context
    return Scaffold(
      floatingActionButton: summaryState.summary != null
          ? FloatingActionButton.extended(
              onPressed: () => _showQueryDialog(context, summaryState.summary!),
              icon: const Icon(Icons.psychology_outlined),
              label: const Text('Ask AI'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 4,
            )
          : null,
      body: summaryState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : summaryState.error != null
              ? _buildErrorContent(summaryState.error!)
              : summaryState.summary != null
                  ? FormatAwareSummaryViewer(
                      summary: summaryState.summary!,
                      format: summaryState.summary!.format,
                      breadcrumbs: _buildBreadcrumbs(summaryState.summary!),
                      onExport: () => _exportSummary(),
                      onCopy: () => _copySummary(),
                      onBack: () {
                        // Clear the summary state when going back
                        ref.read(summaryDetailProvider.notifier).clearSummary();
                        context.pop();
                      },
                    )
                  : _buildNotFoundContent(),
    );
  }

Widget _buildErrorContent(String error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LayoutConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: colorScheme.error,
            ),
            const SizedBox(height: LayoutConstants.paddingMedium),
            Text(
              'Failed to Load Summary',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LayoutConstants.paddingSmall),
            Text(
              error,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LayoutConstants.paddingLarge),
            FilledButton.icon(
              onPressed: _loadSummary,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            const SizedBox(height: LayoutConstants.paddingSmall),
            TextButton(
              onPressed: () {
                ref.read(summaryDetailProvider.notifier).clearSummary();
                context.pop();
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LayoutConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: LayoutConstants.paddingMedium),
            Text(
              'Summary Not Found',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: LayoutConstants.paddingSmall),
            Text(
              'The requested summary could not be found.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LayoutConstants.paddingLarge),
            FilledButton.icon(
              onPressed: () {
                ref.read(summaryDetailProvider.notifier).clearSummary();
                context.go('/summaries');
              },
              icon: const Icon(Icons.list),
              label: const Text('Back to Summaries'),
            ),
          ],
        ),
      ),
    );
  }

  void _exportSummary() {
    final summary = ref.read(summaryDetailProvider).summary;
    if (summary == null) return;

    showDialog(
      context: context,
      builder: (context) => SummaryExportDialog(summary: summary),
    );
  }

  void _copySummary() {
    final summary = ref.read(summaryDetailProvider).summary;
    if (summary == null) return;

    // Copy summary to clipboard logic would go here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Summary copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showQueryDialog(BuildContext context, SummaryModel summary) {
    // Use projectId if available, otherwise use the summary ID as fallback
    final entityId = summary.projectId ?? summary.id;
    final entityName = summary.subject;

    // Map SummaryType to entityType string
    final entityType = switch (summary.summaryType) {
      SummaryType.project => 'project',
      SummaryType.program => 'program',
      SummaryType.portfolio => 'portfolio',
      SummaryType.meeting => 'project', // meetings are project-level
    };

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AskAIPanel(
          projectId: entityId,
          projectName: entityName,
          entityType: entityType,
          onClose: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  List<BreadcrumbItem> _buildBreadcrumbs(SummaryModel summary) {
    final items = <BreadcrumbItem>[];

    // Add home
    items.add(BreadcrumbItem(
      label: 'Home',
      route: '/',
      icon: Icons.home_outlined,
    ));

    // Build path based on where we came from and the summary type
    if (widget.fromRoute != null && widget.fromRoute!.contains('/projects/')) {
      // Coming from a project page
      items.add(BreadcrumbItem(
        label: 'Projects',
        route: '/projects',
        icon: Icons.folder_outlined,
      ));

      if (summary.projectId != null) {
        items.add(BreadcrumbItem(
          label: widget.parentEntityName ?? 'Project',
          route: '/projects/${summary.projectId}',
        ));
      }
    } else if (widget.fromRoute != null && widget.fromRoute!.contains('/programs/')) {
      // Coming from a program page
      items.add(BreadcrumbItem(
        label: 'Programs',
        route: '/programs',
        icon: Icons.dashboard_outlined,
      ));

      items.add(BreadcrumbItem(
        label: widget.parentEntityName ?? 'Program',
        route: widget.fromRoute,
      ));
    } else if (widget.fromRoute != null && widget.fromRoute!.contains('/portfolios/')) {
      // Coming from a portfolio page
      items.add(BreadcrumbItem(
        label: 'Portfolios',
        route: '/portfolios',
        icon: Icons.business_center_outlined,
      ));

      items.add(BreadcrumbItem(
        label: widget.parentEntityName ?? 'Portfolio',
        route: widget.fromRoute,
      ));
    } else {
      // Default path: coming from summaries list or direct link
      items.add(BreadcrumbItem(
        label: 'Summaries',
        route: '/summaries',
        icon: Icons.summarize_outlined,
      ));
    }

    // Add current summary with appropriate icon based on type
    final summaryTitle = summary.subject.length > 40
        ? '${summary.subject.substring(0, 37)}...'
        : summary.subject;

    IconData summaryIcon;
    switch (summary.summaryType) {
      case SummaryType.meeting:
        summaryIcon = Icons.groups_outlined;
        break;
      case SummaryType.project:
        summaryIcon = Icons.folder_outlined;
        break;
      case SummaryType.program:
        summaryIcon = Icons.dashboard_outlined;
        break;
      case SummaryType.portfolio:
        summaryIcon = Icons.business_center_outlined;
        break;
    }

    items.add(BreadcrumbItem(
      label: summaryTitle,
      route: null,
      icon: summaryIcon,
    ));

    return items;
  }

  @override
  void dispose() {
    super.dispose();
  }
}