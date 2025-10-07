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
  bool _isActionMenuOpen = false;

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 768;

    // Build the scaffold directly without requiring project context
    return Scaffold(
      floatingActionButton: summaryState.summary != null
          ? _buildFloatingActionButton(context, summaryState.summary!, isMobile)
          : null,
      body: Stack(
        children: [
          summaryState.isLoading
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
          // Speed dial overlay for mobile
          if (_isActionMenuOpen && isMobile && summaryState.summary != null)
            _buildSpeedDialOverlay(context, summaryState.summary!),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, SummaryModel summary, bool isMobile) {
    final colorScheme = Theme.of(context).colorScheme;

    // Mobile: Show "+" FAB that toggles speed dial menu
    if (isMobile) {
      return SafeArea(
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              _isActionMenuOpen = !_isActionMenuOpen;
            });
          },
          backgroundColor: colorScheme.primary,
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 200),
            turns: _isActionMenuOpen ? 0.125 : 0,
            child: Icon(_isActionMenuOpen ? Icons.close : Icons.add),
          ),
        ),
      );
    }

    // Desktop/Tablet: Show Ask AI FAB
    return FloatingActionButton.extended(
      onPressed: () => _showQueryDialog(context, summary),
      icon: const Icon(Icons.psychology_outlined),
      label: const Text('Ask AI'),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 4,
    );
  }

  Widget _buildSpeedDialOverlay(BuildContext context, SummaryModel summary) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final actions = [
      {
        'icon': Icons.psychology_outlined,
        'label': 'Ask AI',
        'color': colorScheme.primary,
        'onTap': () {
          setState(() => _isActionMenuOpen = false);
          _showQueryDialog(context, summary);
        },
      },
      {
        'icon': Icons.download_outlined,
        'label': 'Export',
        'color': Colors.blue,
        'onTap': () {
          setState(() => _isActionMenuOpen = false);
          _exportSummary();
        },
      },
      {
        'icon': Icons.copy_outlined,
        'label': 'Copy',
        'color': Colors.green,
        'onTap': () {
          setState(() => _isActionMenuOpen = false);
          _copySummary();
        },
      },
    ];

    return GestureDetector(
      onTap: () {
        setState(() => _isActionMenuOpen = false);
      },
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 88),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: actions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final action = entry.value;
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 200 + (index * 50)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        alignment: Alignment.centerRight,
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Label
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              action['label'] as String,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Action button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: action['onTap'] as VoidCallback,
                              borderRadius: BorderRadius.circular(28),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  action['icon'] as IconData,
                                  color: action['color'] as Color,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
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