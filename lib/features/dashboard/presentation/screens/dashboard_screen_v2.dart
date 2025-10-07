import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/datetime_utils.dart';
import '../../../../app/router/routes.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../meetings/presentation/providers/meetings_provider.dart';
import '../../../summaries/presentation/providers/summary_provider.dart';
import '../../../summaries/presentation/widgets/summary_generation_dialog.dart';
import '../../../summaries/data/models/summary_model.dart';
import '../../../../shared/widgets/upload_content_dialog.dart';
import '../../../../shared/widgets/record_meeting_dialog.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../content/presentation/providers/processing_jobs_provider.dart';
import '../../../content/presentation/providers/new_items_provider.dart';
import '../../../content/presentation/widgets/processing_skeleton_loader.dart';
import '../../../organizations/presentation/providers/organization_provider.dart';
import '../../../queries/presentation/widgets/ask_ai_panel.dart';
import '../../../../core/services/firebase_analytics_service.dart';

class DashboardScreenV2 extends ConsumerStatefulWidget {
  const DashboardScreenV2({super.key});

  @override
  ConsumerState<DashboardScreenV2> createState() => _DashboardScreenV2State();
}

class _DashboardScreenV2State extends ConsumerState<DashboardScreenV2> {
  @override
  void initState() {
    super.initState();
    // Log dashboard viewed after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logDashboardViewed();
    });
  }

  void _logDashboardViewed() {
    try {
      final projectsAsync = ref.read(projectsListProvider);
      final projects = projectsAsync.valueOrNull ?? [];

      FirebaseAnalyticsService().logDashboardViewed(
        projectCount: projects.length,
      );
    } catch (e) {
      // Silently fail analytics
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsListProvider);
    final organizationAsync = ref.watch(currentOrganizationProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768;

    // Check if both data sources are ready
    final isLoading = projectsAsync.isLoading || organizationAsync.isLoading;
    final hasError = projectsAsync.hasError || organizationAsync.hasError;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(projectsListProvider);
            ref.invalidate(meetingsListProvider);
            ref.invalidate(currentOrganizationProvider);

            // Log dashboard refreshed
            try {
              await FirebaseAnalyticsService().logDashboardRefreshed(
                refreshMethod: 'pull_to_refresh',
              );
            } catch (e) {
              // Silently fail analytics
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 32 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : double.infinity),
                  child: isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : hasError
                      ? ErrorStateWidget(
                          error: projectsAsync.hasError
                            ? projectsAsync.error.toString()
                            : organizationAsync.error.toString(),
                          onRetry: () {
                            ref.invalidate(projectsListProvider);
                            ref.invalidate(currentOrganizationProvider);
                          },
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Section
                            _buildHeader(context),
                            const SizedBox(height: 32),

                            // Main Content - we already checked loading state above
                            Builder(
                              builder: (_) {
                                final projects = projectsAsync.valueOrNull ?? [];
                                final activeProjects = projects.where((p) => p.status == ProjectStatus.active).toList();
                                final recentProjects = projects.take(3).toList();

                                // Desktop layout with right panel
                                if (isDesktop || isTablet) {
                                  return IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Main Content Area (left side)
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // AI Insights Section
                                              _buildAIInsights(context, projects),
                                              const SizedBox(height: 32),

                                              // Projects Section
                                              _buildProjectsSection(context, recentProjects, activeProjects),
                                              const SizedBox(height: 32),

                                              // Recent Summaries Section
                                              _buildRecentSummaries(context, projects),
                                            ],
                                          ),
                                        ),

                                  // Visual Separator
                                  Container(
                                    width: 1,
                                    margin: const EdgeInsets.symmetric(horizontal: 24),
                                    color: colorScheme.outline.withValues(alpha: 0.2),
                                  ),

                                  // Right Panel
                                  SizedBox(
                                    width: 320,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Quick Actions
                                        _buildCompactQuickActions(context),
                                        const SizedBox(height: 24),

                                        // Timeline Activity
                                        Expanded(
                                          child: _buildTimelineActivity(context, projects),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            // Mobile layout
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Quick Actions
                                _buildQuickActions(context),
                                const SizedBox(height: 32),

                                // AI Insights Section
                                _buildAIInsights(context, projects),
                                const SizedBox(height: 32),

                                // Projects Section
                                _buildProjectsSection(context, recentProjects, activeProjects),
                                const SizedBox(height: 32),

                                // Recent Summaries Section
                                _buildRecentSummaries(context, projects),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButton: projectsAsync.maybeWhen(
        data: (projects) => _buildFloatingActionButton(context, projects, screenWidth, theme.colorScheme),
        orElse: () => null,
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context, List<Project> projects, double screenWidth, ColorScheme colorScheme) {
    final hasProjects = projects.isNotEmpty;

    // If no projects, show "New Project" FAB for both mobile and desktop
    if (!hasProjects) {
      return FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createProject),
        backgroundColor: colorScheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      );
    }

    // If there are projects, show "Ask AI" FAB
    return FloatingActionButton.extended(
      onPressed: () => _showAskAIDialog(context),
      backgroundColor: colorScheme.primary,
      icon: const Icon(Icons.psychology_outlined),
      label: const Text('Ask AI'),
      elevation: 4,
    );
  }

  void _showAskAIDialog(BuildContext context) {
    // Log analytics
    try {
      FirebaseAnalyticsService().logDashboardAiPanelOpened(
        source: 'fab_button',
      );
    } catch (e) {
      // Silently fail analytics
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AskAIPanel(
          projectId: 'organization',  // Organization-level queries
          projectName: 'Organization',
          entityType: 'organization',
          onClose: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final organizationAsync = ref.watch(currentOrganizationProvider);
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    // Get organization name, now data is guaranteed to be loaded
    final organizationName = organizationAsync.valueOrNull?.name ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              organizationName.isNotEmpty ? 'Welcome to $organizationName' : 'Welcome',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }



  Widget _buildAIInsights(BuildContext context, List<Project> projects) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    // Generate insights based on data
    final List<Map<String, dynamic>> insights = [];

    // Get meetings data
    final meetingsAsync = ref.watch(meetingsListProvider);
    final meetingsCount = meetingsAsync.valueOrNull?.length ?? 0;

    // Get active projects
    final activeProjects = projects.where((p) => p.status == ProjectStatus.active).toList();

    // Get summaries data
    int totalSummaries = 0;
    int recentSummaries = 0;
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));

    for (final project in projects) {
      final summariesAsync = ref.watch(projectSummariesProvider(project.id));
      if (summariesAsync.hasValue) {
        final summaries = summariesAsync.value ?? [];
        totalSummaries += summaries.length;
        recentSummaries += summaries.where((s) =>
          s.createdAt != null && s.createdAt!.isAfter(lastWeek)
        ).length;
      }
    }

    // Generate dynamic insights
    if (meetingsCount > 10 && totalSummaries < meetingsCount / 2) {
      insights.add({
        'type': 'suggestion',
        'icon': Icons.auto_awesome,
        'color': Colors.amber,
        'title': 'Optimize Summary Generation',
        'message': 'You have ${meetingsCount} documents but only $totalSummaries summaries. Consider generating summaries for better insights.',
        'action': 'Generate Summaries',
      });
    }

    if (activeProjects.length > 5) {
      insights.add({
        'type': 'alert',
        'icon': Icons.warning_amber_rounded,
        'color': Colors.orange,
        'title': 'Project Management',
        'message': 'You have ${activeProjects.length} active projects. Consider archiving completed ones to improve focus.',
        'action': 'Review Projects',
      });
    }

    if (recentSummaries > 5) {
      insights.add({
        'type': 'success',
        'icon': Icons.trending_up,
        'color': Colors.green,
        'title': 'Great Progress',
        'message': 'You generated $recentSummaries summaries this week. Your documentation is up to date!',
        'action': 'View Reports',
      });
    }

    // Add a productivity insight
    if (meetingsAsync.hasValue) {
      final meetings = meetingsAsync.value!;
      final recentMeetings = meetings.where((m) =>
        m.uploadedAt.isAfter(lastWeek)
      ).length;

      if (recentMeetings > 0) {
        insights.add({
          'type': 'info',
          'icon': Icons.insights,
          'color': Colors.blue,
          'title': 'Weekly Activity',
          'message': 'You documented $recentMeetings meetings this week. Keep up the consistent tracking!',
          'action': 'View Timeline',
        });
      }
    }

    // If no insights, show default
    if (insights.isEmpty) {
      insights.add({
        'type': 'info',
        'icon': Icons.lightbulb_outline,
        'color': Colors.purple,
        'title': 'Getting Started',
        'message': 'Start by uploading meeting transcripts or recordings to generate AI-powered insights.',
        'action': 'Upload Transcript',
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'AI Insights',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isDesktop)
          Row(
            children: insights.take(2).map((insight) =>
              Expanded(
                child: _buildInsightCard(context, insight),
              ),
            ).toList(),
          )
        else
          Column(
            children: insights.take(1).map((insight) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildInsightCard(context, insight),
              ),
            ).toList(),
          ),
      ],
    );
  }

  Widget _buildInsightCard(BuildContext context, Map<String, dynamic> insight) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 800;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: isMobile ? const EdgeInsets.all(12) : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surface.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (insight['color'] as Color).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: isMobile ? const EdgeInsets.all(6) : const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (insight['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  insight['icon'] as IconData,
                  color: insight['color'] as Color,
                  size: isMobile ? 18 : 20,
                ),
              ),
              SizedBox(width: isMobile ? 10 : 12),
              Expanded(
                child: Text(
                  insight['title'] as String,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 14 : null,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            insight['message'] as String,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
              fontSize: isMobile ? 12 : null,
            ),
            maxLines: isMobile ? 2 : null,
            overflow: isMobile ? TextOverflow.ellipsis : null,
          ),
        ],
      ),
    );
  }


  Widget _buildCompactQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final actions = [
      {
        'icon': Icons.add_circle_outline,
        'label': 'New Project',
        'color': theme.colorScheme.primary,
        'onTap': () {
          // Log analytics
          try {
            FirebaseAnalyticsService().logDashboardQuickActionClicked(
              action: 'new_project',
            );
          } catch (e) {
            // Silently fail analytics
          }
          // Navigate to hierarchy screen with a flag to open the create project dialog
          context.go('/hierarchy?action=create_project');
        },
      },
      {
        'icon': Icons.mic_outlined,
        'label': 'Record Meeting',
        'color': Colors.red,
        'onTap': () {
          // Log analytics
          try {
            FirebaseAnalyticsService().logDashboardQuickActionClicked(
              action: 'record_meeting',
            );
          } catch (e) {
            // Silently fail analytics
          }
          _showRecordingDialog(context);
        },
      },
      {
        'icon': Icons.upload_file_outlined,
        'label': 'Upload Transcript or Audio',
        'color': Colors.blue,
        'onTap': () {
          // Log analytics
          try {
            FirebaseAnalyticsService().logDashboardQuickActionClicked(
              action: 'upload_transcript',
            );
          } catch (e) {
            // Silently fail analytics
          }
          _showUploadDialog(context);
        },
      },
      {
        'icon': Icons.auto_awesome_outlined,
        'label': 'Generate Summary',
        'color': Colors.orange,
        'onTap': () {
          // Log analytics
          try {
            FirebaseAnalyticsService().logDashboardQuickActionClicked(
              action: 'generate_summary',
            );
          } catch (e) {
            // Silently fail analytics
          }
          _showGenerateSummaryDialog(context);
        },
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...actions.map((action) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: action['onTap'] as VoidCallback,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      action['icon'] as IconData,
                      color: action['color'] as Color,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        action['label'] as String,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )).toList(),
      ],
    );
  }



  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final actions = [
      {
        'icon': Icons.add_circle_outline,
        'label': 'New Project',
        'color': theme.colorScheme.primary,
        'onTap': () {
          // Navigate to hierarchy screen with a flag to open the create project dialog
          context.go('/hierarchy?action=create_project');
        },
      },
      {
        'icon': Icons.mic_outlined,
        'label': 'Record',
        'color': Colors.red,
        'onTap': () => _showRecordingDialog(context),
      },
      {
        'icon': Icons.upload_file_outlined,
        'label': 'Upload',
        'color': Colors.blue,
        'onTap': () => _showUploadDialog(context),
      },
      {
        'icon': Icons.auto_awesome_outlined,
        'label': 'Summary',
        'color': Colors.orange,
        'onTap': () => _showGenerateSummaryDialog(context),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: actions.map((action) => _buildActionCard(action)).toList(),
        ),
      ],
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action['onTap'] as VoidCallback,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                action['icon'] as IconData,
                color: action['color'] as Color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  action['label'] as String,
                  style: textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsSection(BuildContext context, List<Project> recentProjects, List<Project> activeProjects) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Projects',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.projects),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentProjects.isEmpty)
          _buildEmptyState()
        else
          Column(
            children: recentProjects.take(3).map((project) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildProjectCard(context, project),
              ),
            ).toList(),
          ),
      ],
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isActive = project.status == ProjectStatus.active;

    // Get document count for this project
    final documentsCount = ref.watch(meetingsListProvider).when(
      data: (meetings) => meetings.where((m) => m.projectId == project.id).length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    // Get summaries count for this project
    final summariesCount = ref.watch(projectSummariesProvider(project.id)).when(
      data: (summaries) => summaries.length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Log analytics
          try {
            FirebaseAnalyticsService().logDashboardProjectCardClicked(
              projectId: project.id,
              projectName: project.name,
            );
          } catch (e) {
            // Silently fail analytics
          }
          context.push(AppRoutes.projectDetailPath(project.id));
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              // Project Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    project.name[0].toUpperCase(),
                    style: textTheme.titleMedium?.copyWith(
                      color: isActive ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Project Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            project.name,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isActive
                                  ? Colors.green.withValues(alpha: 0.4)
                                  : Colors.orange.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isActive ? 'ACTIVE' : 'ARCHIVED',
                            style: TextStyle(
                              color: isActive ? Colors.green[700] : Colors.orange[700],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (project.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        project.description!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$documentsCount docs',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.summarize_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$summariesCount summaries',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateTimeUtils.formatTimeAgo(project.createdAt),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSummaries(BuildContext context, List<Project> projects) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Get all processing jobs
    final allProcessingJobs = ref.watch(processingJobsProvider);

    // Collect all summaries from all projects
    List<dynamic> allSummaries = [];

    for (final project in projects) {
      final summariesAsync = ref.watch(projectSummariesProvider(project.id));
      if (summariesAsync.hasValue) {
        final summaries = summariesAsync.value ?? [];
        for (final summary in summaries) {
          allSummaries.add({
            'summary': summary,
            'project': project,
          });
        }
      }
    }

    // Sort by creation date (most recent first) and take top 5
    allSummaries.sort((a, b) {
      final dateA = a['summary'].createdAt ?? DateTime.now();
      final dateB = b['summary'].createdAt ?? DateTime.now();
      return dateB.compareTo(dateA);
    });

    // Filter out summaries that are being processed (to avoid duplicates)
    final processingSummaryIds = allProcessingJobs
        .where((job) => job.summaryId != null && job.isProcessing)
        .map((job) => job.summaryId)
        .toSet();

    allSummaries = allSummaries.where((item) {
      final summaryId = item['summary'].id;
      return !processingSummaryIds.contains(summaryId);
    }).toList();

    final recentSummaries = allSummaries.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Summaries',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/summaries'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentSummaries.isEmpty && allProcessingJobs.isEmpty)
          _buildEmptySummariesState()
        else
          Column(
            children: [
              // Add skeleton loaders for processing jobs (transcriptions and uploads that will generate summaries)
              ...allProcessingJobs
                  .where((job) {
                    // Show skeleton for jobs that are either processing or don't have a model yet (just started)
                    return job.isProcessing || job.jobModel == null;
                  })
                  .take(3 - recentSummaries.length) // Limit total items to 3
                  .map((job) {
                    // Determine if this is a document or summary being processed
                    final jobType = job.jobModel?.jobType.toString() ?? '';
                    // Default to document type for new jobs without a model
                    final isDocument = jobType.isEmpty ||
                                     jobType.contains('transcription') ||
                                     jobType.contains('upload') ||
                                     jobType.contains('text_upload');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ProcessingSkeletonLoader(
                        isDocument: isDocument,
                        title: job.jobModel?.metadata != null ? job.jobModel!.metadata['title'] as String? : null,
                      ),
                    );
                  }),
              // Add actual summaries
              ...recentSummaries.map((item) {
                final summary = item['summary'];
                // Use watch to ensure we react to changes
                final newItemsNotifier = ref.watch(newItemsProvider.notifier);
                final isNew = newItemsNotifier.isNewItem(summary.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildSummaryCard(context, summary, item['project'], isNew: isNew),
                );
              }),
            ],
          ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, dynamic summary, Project project, {bool isNew = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 1200;

    // Determine summary type icon and color
    IconData iconData;
    Color iconColor;
    String typeLabel;

    if (summary.summaryType != null) {
      switch (summary.summaryType.toString().toLowerCase()) {
        case 'project':
        case 'weekly':
          iconData = Icons.folder_special_outlined;
          iconColor = Colors.purple;
          typeLabel = 'Project Summary';
          break;
        case 'meeting':
          iconData = Icons.groups_outlined;
          iconColor = Colors.blue;
          typeLabel = 'Meeting Summary';
          break;
        case 'executive':
          iconData = Icons.business_center_outlined;
          iconColor = Colors.orange;
          typeLabel = 'Executive Summary';
          break;
        case 'technical':
          iconData = Icons.code;
          iconColor = Colors.green;
          typeLabel = 'Technical Summary';
          break;
        default:
          iconData = Icons.summarize_outlined;
          iconColor = Colors.grey;
          typeLabel = 'Summary';
      }
    } else {
      iconData = Icons.summarize_outlined;
      iconColor = Colors.grey;
      typeLabel = 'Summary';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Navigate to summary detail
          context.push('/summaries/${summary.id}');
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mobile: Title + GENERAL badge on same line
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                summary.subject ?? typeLabel,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                summary.format?.toString().split('.').last.toUpperCase() ?? 'GENERAL',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Mobile: Project name + time on second line
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                project.name,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateTimeUtils.formatTimeAgo(summary.createdAt ?? DateTime.now()),
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Desktop: Keep original layout
                        Text(
                          summary.subject ?? typeLabel,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                project.name,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateTimeUtils.formatTimeAgo(summary.createdAt ?? DateTime.now()),
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
              ),
              // Badges row (NEW and Format) - Desktop only
              if (!isMobile)
                Row(
                  children: [
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    if (isNew && summary.format != null) const SizedBox(width: 4),
                    if (summary.format != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          summary.format.toString().split('.').last.toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySummariesState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.auto_awesome_outlined,
                size: 32,
                color: Colors.orange.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No summaries yet',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Generate AI-powered summaries from your documents',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: () => _showGenerateSummaryDialog(context),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Generate Summary'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: Colors.orange.withValues(alpha: 0.15),
                foregroundColor: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineActivity(BuildContext context, List<Project> projects) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Get recent meetings
    final meetingsAsync = ref.watch(meetingsListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Timeline',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: meetingsAsync.when(
            data: (meetings) {
              if (meetings.isEmpty) {
                return _buildEmptyTimelineState();
              }

              final recentMeetings = meetings.take(8).toList();
              return SingleChildScrollView(
                child: Column(
                  children: recentMeetings.asMap().entries.map((entry) {
                    final index = entry.key;
                    final meeting = entry.value;
                    final isLast = index == recentMeetings.length - 1;
                    return _buildTimelineItem(context, meeting, projects, isLast);
                  }).toList(),
                ),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => _buildEmptyTimelineState(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, dynamic meeting, List<Project> projects, bool isLast) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Find the project for this meeting
    Project? project;
    try {
      project = projects.firstWhere((p) => p.id == meeting.projectId);
    } catch (_) {
      project = projects.isNotEmpty ? projects.first : null;
    }

    // Determine icon and color based on content type
    IconData iconData;
    Color iconColor;

    if (meeting.title != null && meeting.title!.toLowerCase().contains('audio')) {
      iconData = Icons.mic_outlined;
      iconColor = Colors.purple;
    } else if (meeting.contentType?.toString().toLowerCase() == 'email') {
      iconData = Icons.email_outlined;
      iconColor = Colors.orange;
    } else {
      iconData = Icons.description_outlined;
      iconColor = Colors.blue;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line and dot
        Column(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 1,
                height: 50,
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time
                Text(
                  DateTimeUtils.formatTimeAgo(meeting.uploadedAt),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                // Title with icon
                Row(
                  children: [
                    Icon(
                      iconData,
                      size: 14,
                      color: iconColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        meeting.title ?? 'Untitled',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (project != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    project.name,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTimelineState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.timeline,
              size: 32,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'No activity yet',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Keep this for mobile layout
  Widget _buildRecentActivity(BuildContext context, List<Project> projects) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Get recent meetings
    final meetingsAsync = ref.watch(meetingsListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        meetingsAsync.when(
          data: (meetings) {
            if (meetings.isEmpty) {
              return _buildEmptyActivityState();
            }

            final recentMeetings = meetings.take(5).toList();
            return Column(
              children: recentMeetings.map((meeting) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildActivityItem(context, meeting, projects),
                ),
              ).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => _buildEmptyActivityState(),
        ),
      ],
    );
  }

  Widget _buildActivityItem(BuildContext context, dynamic meeting, List<Project> projects) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Find the project for this meeting
    final project = projects.firstWhere(
      (p) => p.id == meeting.projectId,
      orElse: () => projects.first,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Colors.blue,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meeting.title ?? 'Untitled Document',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      project.name,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateTimeUtils.formatTimeAgo(meeting.uploadedAt),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.folder_outlined,
                size: 32,
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No projects yet',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create your first project to get started',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: () => context.go('/hierarchy?action=create_project'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create First Project'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyActivityState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.history,
                size: 28,
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No activity yet',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Your timeline will appear here',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }




  void _showGenerateSummaryDialog(BuildContext context) {
    // Get list of active projects
    final projectsAsync = ref.read(projectsListProvider);

    projectsAsync.when(
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading projects...')),
        );
      },
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading projects: $error')),
        );
      },
      data: (projects) {
        final activeProjects = projects
            .where((p) => p.status == ProjectStatus.active)
            .toList();

        if (activeProjects.isEmpty) {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('No Active Projects'),
              content: const Text('Please create or activate a project first to generate summaries.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('OK'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    context.go('/hierarchy?action=create_project');
                  },
                  child: const Text('Create Project'),
                ),
              ],
            ),
          );
          return;
        }

        // If only one project, go directly to summary generation
        if (activeProjects.length == 1) {
          _openSummaryGenerationDialog(context, activeProjects.first);
          return;
        }

        // Show project selection dialog
        Project? selectedProject;
        showDialog(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (builderContext, setState) => AlertDialog(
              title: const Text('Select Project'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose a project to generate a summary for:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: SingleChildScrollView(
                        child: Column(
                          children: activeProjects.map((project) {
                            return RadioListTile<Project>(
                              value: project,
                              groupValue: selectedProject,
                              onChanged: (value) {
                                setState(() {
                                  selectedProject = value;
                                });
                              },
                              title: Text(project.name),
                              subtitle: project.description != null
                                  ? Text(
                                      project.description!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    )
                                  : null,
                              secondary: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    project.name[0].toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: selectedProject != null
                      ? () {
                          Navigator.pop(dialogContext);
                          _openSummaryGenerationDialog(context, selectedProject!);
                        }
                      : null,
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSummaryGenerationDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => SummaryGenerationDialog(
        entityType: 'project',
        entityId: project.id,
        entityName: project.name,
        onGenerate: ({
          required String format,
          required DateTime startDate,
          required DateTime endDate,
        }) async {
          try {
            await ref.read(summaryGenerationProvider.notifier).generateSummary(
              projectId: project.id,
              type: SummaryType.project,
              startDate: startDate,
              endDate: endDate,
              useJob: false,
              format: format,
            );

            final generatedSummary = ref.read(summaryGenerationProvider).generatedSummary;

            if (generatedSummary != null && context.mounted) {
              // Navigate to the summary detail page
              context.push('/summaries/${generatedSummary.id}');

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Summary generated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );

              // Refresh summaries list
              ref.invalidate(projectSummariesProvider(project.id));
            }

            return generatedSummary;
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to generate summary: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            rethrow;
          }
        },
        onUploadContent: () {
          Navigator.pop(dialogContext);
          _showUploadDialog(context);
        },
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: 700,
          ),
          child: UploadContentDialog(
            onUploadComplete: () {
              Navigator.of(dialogContext).pop();
              // Refresh data if needed
              ref.invalidate(projectsListProvider);
              ref.invalidate(meetingsListProvider);
            },
          ),
        ),
      ),
    );
  }

  void _showRecordingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: IntrinsicHeight(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 600,
            ),
            child: RecordMeetingDialog(
              onRecordingComplete: () {
                // Refresh data if needed
                ref.invalidate(projectsListProvider);
                ref.invalidate(meetingsListProvider);
              },
            ),
          ),
        ),
      ),
    );
  }

}