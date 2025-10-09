import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/utils/datetime_utils.dart';
import '../../../../app/router/routes.dart';
import '../../domain/entities/project.dart';
import '../providers/projects_provider.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../meetings/presentation/providers/meetings_provider.dart';
import '../../../meetings/domain/entities/content.dart';
import '../../../summaries/presentation/providers/summary_provider.dart';
import '../../../summaries/data/models/summary_model.dart';
import '../../../summaries/presentation/widgets/summary_generation_dialog.dart';
import '../../../summaries/data/services/content_availability_service.dart';
import '../../../audio_recording/presentation/providers/recording_provider.dart';
import '../../../audio_recording/domain/services/audio_recording_service.dart';
import '../../../audio_recording/presentation/widgets/recording_button.dart';
import '../../../content/presentation/providers/content_status_provider.dart';
import '../../../../core/network/api_service.dart';
import '../../../../shared/providers/api_client_provider.dart';
import '../widgets/edit_project_dialog.dart';
import '../../../activities/presentation/providers/activity_provider.dart';
import '../../../activities/domain/entities/activity.dart';
import '../../../meetings/presentation/providers/upload_provider.dart';
import '../../../hierarchy/presentation/providers/hierarchy_providers.dart';
import './content_processing_dialog.dart';
import '../../../content/presentation/providers/processing_jobs_provider.dart';
import '../../../../shared/widgets/upload_content_dialog.dart';
import '../../../../shared/widgets/record_meeting_dialog.dart';
import '../../../content/presentation/widgets/processing_skeleton_loader.dart';
import '../../../content/presentation/providers/new_items_provider.dart';
import '../../../jobs/presentation/providers/job_websocket_provider.dart';
import '../../../jobs/domain/models/job_model.dart';
import '../widgets/project_risks_widget.dart';
import '../widgets/project_tasks_widget.dart';
import '../widgets/project_lessons_learned_widget.dart';
import '../providers/lessons_learned_provider.dart';
import '../widgets/project_blockers_widget.dart';
import '../../../queries/presentation/widgets/ask_ai_panel.dart';
import '../../../queries/presentation/providers/query_provider.dart';
import '../../../documents/presentation/widgets/document_detail_dialog.dart';

class SimplifiedProjectDetailsScreen extends ConsumerStatefulWidget {
  final String projectId;

  const SimplifiedProjectDetailsScreen({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<SimplifiedProjectDetailsScreen> createState() => _SimplifiedProjectDetailsScreenState();
}

class _SimplifiedProjectDetailsScreenState extends ConsumerState<SimplifiedProjectDetailsScreen> {
  ContentAvailability? _contentAvailability;
  bool _isCheckingAvailability = false;
  final ScrollController _scrollController = ScrollController();
  bool _isDescriptionExpanded = false;
  bool _isActionMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _ensureProjectSelected();
    _checkContentAvailability();

    // Clean up expired NEW badges (older than 5 minutes)
    // But keep recent ones to maintain animations across navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(newItemsProvider.notifier).clearExpiredItems();
    });

    // Subscribe to WebSocket for this project to get active job updates
    // This ensures jobs are tracked even after page refresh
    Future.microtask(() async {
      try {
        final jobTracker = ref.read(webSocketActiveJobsTrackerProvider.notifier);
        await jobTracker.subscribeToProject(widget.projectId);
        debugPrint('[SimplifiedProjectDetailsScreen] Subscribed to project ${widget.projectId} for job updates');
      } catch (e) {
        debugPrint('[SimplifiedProjectDetailsScreen] Failed to subscribe to project: $e');
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _ensureProjectSelected() {
    if (mounted) {
      final project = ref.read(projectDetailProvider(widget.projectId)).value;
      if (project != null) {
        ref.read(selectedProjectProvider.notifier).state = project;
      }
    }
  }

  Future<void> _checkContentAvailability() async {
    setState(() {
      _isCheckingAvailability = true;
    });

    try {
      final availability = await contentAvailabilityService.checkAvailability(
        entityType: 'project',
        entityId: widget.projectId,
      );
      if (mounted) {
        setState(() {
          _contentAvailability = availability;
          _isCheckingAvailability = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingAvailability = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectDetailProvider(widget.projectId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return projectAsync.when(
      data: (project) {
        if (project == null) {
          return _buildErrorState(context, 'Project not found');
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(selectedProjectProvider.notifier).state = project;
          }
        });

        return _buildProjectDetails(context, project);
      },
      loading: () => Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: colorScheme.surface,
        body: _buildErrorState(
          context,
          'Error loading project: ${error.toString()}',
        ),
      ),
    );
  }

  Widget _buildProjectDetails(BuildContext context, Project project) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768;
    final meetingsAsync = ref.watch(meetingsListProvider);
    final summariesAsync = ref.watch(projectSummariesProvider(project.id));

    // Get counts for stats
    final documentsCount = ref.watch(meetingsStatisticsProvider).when(
      data: (stats) => stats['total'].toString(),
      loading: () => '...',
      error: (_, __) => '0',
    );

    final summariesCount = ref.watch(projectSummariesProvider(project.id)).when(
      data: (summaries) => summaries.length.toString(),
      loading: () => '...',
      error: (_, __) => '0',
    );

    return Scaffold(
          backgroundColor: colorScheme.surface,
          floatingActionButton: _buildFloatingActionButton(context, project, screenWidth, colorScheme),
          body: Stack(
            children: [
              SafeArea(
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 32 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : double.infinity),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Header - Mobile Optimized
                    if (!isDesktop && !isTablet) ...[
                      // Single row: Back button + Title + Metadata + Menu
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              size: 22,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.name,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.calendar_today_outlined, size: 12, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatFullDate(project.createdAt),
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.access_time, size: 12, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateTimeUtils.formatTimeAgo(project.createdAt),
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_horiz, color: colorScheme.onSurfaceVariant),
                            onSelected: (value) => _handleMenuAction(context, value, project),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'activities',
                                height: 40,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.timeline_outlined,
                                      size: 18,
                                      color: Colors.teal,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('View Activities'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'documents',
                                height: 40,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.folder_outlined,
                                      size: 18,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('View Documents'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'lessons',
                                height: 40,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      size: 18,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('View Lessons'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'edit',
                                height: 40,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Edit Project'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: project.status == ProjectStatus.active ? 'archive' : 'activate',
                                height: 40,
                                child: Row(
                                  children: [
                                    Icon(
                                      project.status == ProjectStatus.active ? Icons.archive_outlined : Icons.unarchive_outlined,
                                      size: 18,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(project.status == ProjectStatus.active ? 'Archive' : 'Activate'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'delete',
                                height: 40,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ] else ...[
                      // Desktop/Tablet Header (original layout)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Back button
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              size: 22,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),

                          const SizedBox(width: 8),

                          // PROJECT badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.purple.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.folder_outlined,
                                  size: 14,
                                  color: Colors.purple[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'PROJECT',
                                  style: TextStyle(
                                    color: Colors.purple[600],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Project title
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    project.name,
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Project status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: project.status == ProjectStatus.active
                                        ? Colors.green.withValues(alpha: 0.2)
                                        : Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: project.status == ProjectStatus.active
                                          ? Colors.green.withValues(alpha: 0.4)
                                          : Colors.orange.withValues(alpha: 0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    project.status == ProjectStatus.active ? 'ACTIVE' : 'ARCHIVED',
                                    style: TextStyle(
                                      color: project.status == ProjectStatus.active
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Menu button
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_horiz, color: colorScheme.onSurfaceVariant),
                            onSelected: (value) => _handleMenuAction(context, value, project),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'activities',
                                height: 40,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.timeline_outlined,
                                      size: 18,
                                      color: Colors.teal,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('View Activities'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'edit',
                                height: 40,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Edit Project'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: project.status == ProjectStatus.active ? 'archive' : 'activate',
                                height: 40,
                                child: Row(
                                  children: [
                                    Icon(
                                      project.status == ProjectStatus.active ? Icons.archive_outlined : Icons.unarchive_outlined,
                                      size: 18,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(project.status == ProjectStatus.active ? 'Archive' : 'Activate'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'delete',
                                height: 40,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Metadata row (date, time, user)
                      Padding(
                        padding: const EdgeInsets.only(left: 56),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 14, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                            const SizedBox(width: 4),
                            Text(
                              _formatFullDate(project.createdAt),
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.access_time, size: 14, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                            const SizedBox(width: 4),
                            Text(
                              DateTimeUtils.formatTimeAgo(project.createdAt),
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.person_outline, size: 14, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                            const SizedBox(width: 4),
                            Text(
                              'User',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Divider after header
                    const SizedBox(height: 20),
                    Divider(
                      color: colorScheme.outline.withValues(alpha: 0.08),
                      thickness: 1,
                      height: 1,
                    ),
                    const SizedBox(height: 24),

                    // Main content with right panel on desktop
                    if (isDesktop) ...[
                      Expanded(
                        child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main Content (left side) - Independently scrollable
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                // Description Section
                                if (project.description?.isNotEmpty == true) ...[
                                  _buildDescriptionSection(context, project),
                                  const SizedBox(height: 24),
                                ],

                                // Tasks Section
                                ProjectTasksWidget(
                                  projectId: project.id,
                                  limit: 5,
                                ),

                                const SizedBox(height: 24),

                                // Risks Section
                                ProjectRisksWidget(
                                  projectId: project.id,
                                  limit: 5,
                                ),

                                const SizedBox(height: 24),

                                // Blockers Section
                                ProjectBlockersWidget(
                                  projectId: project.id,
                                  limit: 5,
                                  project: project,
                                ),

                              ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 24),

                          // Vertical separator
                          Container(
                            width: 1,
                            height: 600,
                            color: colorScheme.outline.withValues(alpha: 0.08),
                          ),

                          const SizedBox(width: 24),

                          // Right Panel - Stats and Quick Actions
                          SizedBox(
                            width: 320,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                // Quick Actions section header
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                                  child: Text(
                                    'QUICK ACTIONS',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                // Quick Action Cards - Each on its own line
                                Column(
                                  children: [
                                    _buildCompactQuickActionCard(
                                      context,
                                      Icons.upload_file_outlined,
                                      'Upload Transcript or Audio',
                                      Colors.blue,
                                      () => _showUploadDialog(context, project),
                                      fullWidth: true,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildCompactQuickActionCard(
                                      context,
                                      Icons.mic_none_outlined,
                                      'Record Meeting',
                                      Colors.red,
                                      () => _showRecordingDialog(context, project),
                                      fullWidth: true,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildCompactQuickActionCard(
                                      context,
                                      Icons.auto_awesome_outlined,
                                      'Generate Summary',
                                      Colors.purple,
                                      () => _showGenerateSummaryDialog(context, project),
                                      fullWidth: true,
                                    ),
                                  ],
                                ),

                                // Summaries Section
                                const SizedBox(height: 24),
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'SUMMARIES',
                                            style: textTheme.labelSmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                              fontSize: 10,
                                            ),
                                          ),
                                          summariesAsync.when(
                                            data: (summaries) => summaries.isNotEmpty ? Container(
                                              margin: const EdgeInsets.only(left: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                summaries.length.toString(),
                                                style: textTheme.labelSmall?.copyWith(
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ) : const SizedBox.shrink(),
                                            loading: () => const SizedBox.shrink(),
                                            error: (_, __) => const SizedBox.shrink(),
                                          ),
                                        ],
                                      ),
                                      InkWell(
                                        onTap: () => _showSummariesDialog(context, project),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            'See all',
                                            style: textTheme.labelSmall?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                summariesAsync.when(
                                  data: (summaries) {
                                    // Take only the last 3 summaries
                                    final latestSummaries = summaries.take(3).toList();

                                    // Check if there are any processing jobs with summaries being generated
                                    final activeJobs = ref.watch(webSocketActiveJobsTrackerProvider).valueOrNull ?? [];
                                    final hasProcessingSummary = activeJobs.any((job) =>
                                      job.projectId == project.id &&
                                      (job.status == JobStatus.pending || job.status == JobStatus.processing) &&
                                      job.progress >= 90.0  // Summary generation starts at 90%
                                    );

                                    // Build list including skeleton loaders for processing summaries
                                    final widgets = <Widget>[];

                                    // Add skeleton loader if summary is being generated
                                    if (hasProcessingSummary) {
                                      widgets.add(
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: colorScheme.outline.withValues(alpha: 0.05),
                                              ),
                                            ),
                                            child: const ProcessingSkeletonLoader(
                                              isDocument: false,
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    // Add actual summaries (limited to 3 items)
                                    if (latestSummaries.isNotEmpty) {
                                      widgets.addAll(
                                        latestSummaries.map((summary) =>
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: _buildCompactSummaryCardForSidebar(context, summary),
                                          ),
                                        ),
                                      );
                                    } else if (!hasProcessingSummary) {
                                      widgets.add(
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: colorScheme.outline.withValues(alpha: 0.05),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'No summaries yet',
                                              style: textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: widgets,
                                    );
                                  },
                                  loading: () => const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: LinearProgressIndicator(),
                                  ),
                                  error: (_, __) => Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: colorScheme.errorContainer.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: colorScheme.error.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Error loading summaries',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.error,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Documents Section
                                const SizedBox(height: 24),
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'DOCUMENTS',
                                            style: textTheme.labelSmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                              fontSize: 10,
                                            ),
                                          ),
                                          meetingsAsync.when(
                                            data: (documents) => documents.isNotEmpty ? Container(
                                              margin: const EdgeInsets.only(left: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                documents.length.toString(),
                                                style: textTheme.labelSmall?.copyWith(
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ) : const SizedBox.shrink(),
                                            loading: () => const SizedBox.shrink(),
                                            error: (_, __) => const SizedBox.shrink(),
                                          ),
                                        ],
                                      ),
                                      InkWell(
                                        onTap: () => _showDocumentsDialog(context, project),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            'See all',
                                            style: textTheme.labelSmall?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                meetingsAsync.when(
                                  data: (documents) {
                                    // Take only the last 3 documents
                                    final latestDocuments = documents.take(3).toList();

                                    // Check if there are any processing jobs for this project
                                    final activeJobs = ref.watch(webSocketActiveJobsTrackerProvider).valueOrNull ?? [];
                                    final hasProcessing = activeJobs.any((job) =>
                                      job.projectId == project.id &&
                                      (job.status == JobStatus.pending || job.status == JobStatus.processing) &&
                                      job.progress < 90.0  // Only show during document processing, not summary generation
                                    );

                                    // Build list including skeleton loaders for processing content
                                    final widgets = <Widget>[];

                                    // Add skeleton loader if content is being processed
                                    if (hasProcessing) {
                                      widgets.add(
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: colorScheme.outline.withValues(alpha: 0.05),
                                              ),
                                            ),
                                            child: const ProcessingSkeletonLoader(
                                              isDocument: true,
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    // Add actual documents (limited to 3 items)
                                    if (latestDocuments.isNotEmpty) {
                                      widgets.addAll(
                                        latestDocuments.map((doc) =>
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: _buildCompactDocumentCard(context, doc),
                                          ),
                                        ),
                                      );
                                    } else if (!hasProcessing) {
                                      widgets.add(
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: colorScheme.outline.withValues(alpha: 0.05),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'No documents yet',
                                              style: textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: widgets,
                                    );
                                  },
                                  loading: () => const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: LinearProgressIndicator(),
                                  ),
                                  error: (_, __) => Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: colorScheme.errorContainer.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: colorScheme.error.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Error loading documents',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.error,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Lessons Learned Section
                                const SizedBox(height: 24),
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'LESSONS LEARNED',
                                            style: textTheme.labelSmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                              fontSize: 10,
                                            ),
                                          ),
                                          Consumer(
                                            builder: (context, ref, child) {
                                              final lessonsAsync = ref.watch(lessonsLearnedNotifierProvider(project.id));
                                              return lessonsAsync.when(
                                                data: (lessons) => lessons.isNotEmpty ? Container(
                                                  margin: const EdgeInsets.only(left: 6),
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.primary.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    lessons.length.toString(),
                                                    style: textTheme.labelSmall?.copyWith(
                                                      color: colorScheme.primary,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 9,
                                                    ),
                                                  ),
                                                ) : const SizedBox.shrink(),
                                                loading: () => const SizedBox.shrink(),
                                                error: (_, __) => const SizedBox.shrink(),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      InkWell(
                                        onTap: () => context.push('/lessons?project=${project.id}&from=project'),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            'See all',
                                            style: textTheme.labelSmall?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ProjectLessonsLearnedWidget(
                                  projectId: project.id,
                                  showHeader: false,
                                  limit: 3,
                                ),
                              ],
                            ),
                            ),
                          ),
                        ],
                        ),
                      ),
                    ] else ...[
                      // Mobile/Tablet Layout - Stack vertically
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Description Section
                              if (project.description?.isNotEmpty == true) ...[
                                const SizedBox(height: 16),
                                _buildDescriptionSection(context, project),
                              ],

                              const SizedBox(height: 16),

                              // Summaries Section
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Summaries',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _showSummariesDialog(context, project),
                                    child: const Text('See all'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              summariesAsync.when(
                                data: (summaries) {
                                  // Check if there are any processing jobs with summaries being generated
                                  // Use WebSocket active jobs which persist across navigation
                                  final activeJobs = ref.watch(webSocketActiveJobsTrackerProvider).valueOrNull ?? [];
                                  final hasProcessingSummary = activeJobs.any((job) =>
                                    job.projectId == project.id &&
                                    (job.status == JobStatus.pending || job.status == JobStatus.processing) &&
                                    job.progress >= 90.0  // Summary generation starts at 90%
                                  );

                                  // Build list including skeleton loaders for processing summaries
                                  final widgets = <Widget>[];

                                  // Add skeleton loader if summary is being generated
                                  if (hasProcessingSummary) {
                                    widgets.add(
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 6),
                                        child: ProcessingSkeletonLoader(
                                          isDocument: false,  // For summary
                                        ),
                                      ),
                                    );
                                  }

                                  // Add actual summaries (show last 3)
                                  if (summaries.isNotEmpty) {
                                    widgets.addAll(
                                      summaries.take(hasProcessingSummary ? 2 : 3).map((summary) =>
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: _buildSimpleSummaryCard(context, summary),
                                        ),
                                      ),
                                    );
                                  } else if (!hasProcessingSummary) {
                                    return _buildEmptyCard('No summaries yet');
                                  }

                                  return Column(children: widgets);
                                },
                                loading: () => const LinearProgressIndicator(),
                                error: (_, __) => _buildEmptyCard('Error loading'),
                              ),

                              const SizedBox(height: 16),

                              // Tasks Section
                              ProjectTasksWidget(
                                projectId: project.id,
                                limit: 5,
                              ),
                              const SizedBox(height: 16),
                              // Risks Section
                              ProjectRisksWidget(
                                projectId: project.id,
                                limit: 5,
                              ),
                              const SizedBox(height: 16),
                              // Blockers Section
                              ProjectBlockersWidget(
                                projectId: project.id,
                                limit: 5,
                                project: project,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
              // Speed dial overlay for mobile
              if (_isActionMenuOpen && screenWidth < 600)
                _buildSpeedDialOverlay(context, project),
            ],
          ),
      );
  }

  Widget _buildClickableStatCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    label,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 10,
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

  Widget _buildStatsPanelCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          label,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            fontSize: 11,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
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

  Widget _buildCompactQuickActionCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap, {
    bool fullWidth = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context, Project project) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final description = project.description!;
    final isLongDescription = description.length > 150;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notes,
                size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Description',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
              height: 1.5,
            ),
            maxLines: isMobile && isLongDescription && !_isDescriptionExpanded ? 3 : null,
            overflow: isMobile && isLongDescription && !_isDescriptionExpanded ? TextOverflow.ellipsis : null,
          ),
          if (isMobile && isLongDescription) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _isDescriptionExpanded ? 'View Less' : 'View More',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget? _buildFloatingActionButton(BuildContext context, Project project, double screenWidth, ColorScheme colorScheme) {
    final isMobile = screenWidth < 600;

    // Mobile: Show "+" FAB that toggles speed dial menu
    if (isMobile) {
      return FloatingActionButton(
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
      );
    }

    // Desktop/Tablet: Show "Ask AI" FAB
    return FloatingActionButton.extended(
      onPressed: () => _showQueryDialog(context, project),
      backgroundColor: colorScheme.primary,
      icon: const Icon(Icons.psychology_outlined),
      label: const Text('Ask AI'),
      elevation: 4,
    );
  }

  Widget _buildSpeedDialOverlay(BuildContext context, Project project) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final actions = [
      {
        'icon': Icons.psychology_outlined,
        'label': 'Ask AI',
        'color': colorScheme.primary,
        'onTap': () {
          setState(() => _isActionMenuOpen = false);
          _showQueryDialog(context, project);
        },
      },
      {
        'icon': Icons.upload_file_outlined,
        'label': 'Upload',
        'color': Colors.blue,
        'onTap': () {
          setState(() => _isActionMenuOpen = false);
          _showUploadDialog(context, project);
        },
      },
      {
        'icon': Icons.auto_awesome_outlined,
        'label': 'Generate',
        'color': Colors.purple,
        'onTap': () {
          setState(() => _isActionMenuOpen = false);
          _showGenerateSummaryDialog(context, project);
        },
      },
      {
        'icon': Icons.mic_outlined,
        'label': 'Record',
        'color': Colors.red,
        'onTap': () {
          setState(() => _isActionMenuOpen = false);
          _showRecordingDialog(context, project);
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

  Widget _buildQuickActions(BuildContext context, Project project) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final actions = [
      _QuickAction(
        icon: Icons.upload_file_outlined,
        label: 'Upload',
        color: Colors.blue,
        onTap: () => _showUploadDialog(context, project),
      ),
      _QuickAction(
        icon: Icons.mic_none_outlined,
        label: 'Record',
        color: Colors.red,
        onTap: () => _showRecordingDialog(context, project),
      ),
      _QuickAction(
        icon: Icons.auto_awesome_outlined,
        label: 'Generate',
        color: Colors.purple,
        onTap: () => _showGenerateSummaryDialog(context, project),
      ),
      // Only show Activities on desktop/tablet (available in 3-dot menu on mobile)
      if (!isMobile)
        _QuickAction(
          icon: Icons.timeline_outlined,
          label: 'Activities',
          color: Colors.teal,
          onTap: () => _showActivityDialog(context, project),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: actions.map((action) =>
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildActionButton(context, action),
            ),
          ),
        ).toList(),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, _QuickAction action) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                action.icon,
                color: action.color,
                size: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalStats(BuildContext context, WidgetRef ref, Project project) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final documentsCount = ref.watch(meetingsStatisticsProvider).when(
      data: (stats) => stats['total'].toString(),
      loading: () => '...',
      error: (_, __) => '0',
    );

    final summariesCount = ref.watch(projectSummariesProvider(project.id)).when(
      data: (summaries) => summaries.length.toString(),
      loading: () => '...',
      error: (_, __) => '0',
    );

    return Row(
      children: [
        _buildStatChip(
          context,
          Icons.folder_outlined,
          documentsCount,
          'documents',
        ),
        const SizedBox(width: 16),
        _buildStatChip(
          context,
          Icons.auto_awesome_outlined,
          summariesCount,
          'summaries',
        ),
        const SizedBox(width: 16),
        _buildStatChip(
          context,
          Icons.schedule,
          DateTimeUtils.formatTimeAgo(project.createdAt),
          'updated',
        ),
      ],
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String value, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCard(String message) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 20 : 24,
        horizontal: isMobile ? 16 : 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDocumentCard(BuildContext context, Content document) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Determine content source type
    IconData sourceIcon;
    Color sourceColor;

    if (document.title.toLowerCase().contains('audio') ||
        document.title.toLowerCase().contains('recording')) {
      sourceIcon = Icons.mic_outlined;
      sourceColor = Colors.red;
    } else if (document.title.contains('.json') ||
               document.title.contains('.txt') ||
               document.title.contains('.pdf') ||
               document.title.contains('.doc')) {
      sourceIcon = Icons.upload_file_outlined;
      sourceColor = Colors.blue;
    } else if (document.contentType == ContentType.email) {
      sourceIcon = Icons.email_outlined;
      sourceColor = Colors.orange;
    } else if (document.contentType == ContentType.meeting) {
      sourceIcon = Icons.groups_outlined;
      sourceColor = Colors.purple;
    } else {
      sourceIcon = Icons.text_fields_outlined;
      sourceColor = Colors.teal;
    }

    // Format time
    final timeString = DateTimeUtils.formatRelativeTime(document.uploadedAt);

    return InkWell(
      onTap: () => _showContentDetails(context, document),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            // Compact icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: sourceColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                sourceIcon,
                size: 14,
                color: sourceColor.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    document.title,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Time
                  Text(
                    timeString,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleDocumentCard(BuildContext context, Content document) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Check if this is a new item
    final newItems = ref.watch(newItemsProvider);
    final isNew = newItems.containsKey(document.id) && !newItems[document.id]!.isExpired;

    // Determine content source type based on title patterns
    IconData sourceIcon;
    String sourceType;
    Color sourceColor;

    if (document.title.toLowerCase().contains('audio') ||
        document.title.toLowerCase().contains('recording')) {
      sourceIcon = Icons.mic_outlined;
      sourceType = 'Audio';
      sourceColor = Colors.red;
    } else if (document.title.contains('.json') ||
               document.title.contains('.txt') ||
               document.title.contains('.pdf') ||
               document.title.contains('.doc')) {
      sourceIcon = Icons.upload_file_outlined;
      sourceType = 'File';
      sourceColor = Colors.blue;
    } else if (document.contentType == ContentType.email) {
      sourceIcon = Icons.email_outlined;
      sourceType = 'Email';
      sourceColor = Colors.orange;
    } else if (document.contentType == ContentType.meeting) {
      sourceIcon = Icons.groups_outlined;
      sourceType = 'Meeting';
      sourceColor = Colors.purple;
    } else {
      sourceIcon = Icons.text_fields_outlined;
      sourceType = 'Text';
      sourceColor = Colors.teal;
    }

    // Format time
    final timeString = DateTimeUtils.formatRelativeTime(document.uploadedAt);

    return InkWell(
      onTap: () => _showContentDetails(context, document),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Source type icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: sourceColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                sourceIcon,
                size: 18,
                color: sourceColor.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with NEW badge at the beginning
                  Row(
                    children: [
                      // NEW badge at the beginning
                      if (isNew) ...[
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
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          document.title,
                          style: textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Time and type info
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeString,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: sourceColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          sourceType,
                          style: TextStyle(
                            fontSize: 10,
                            color: sourceColor.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Summary indicator
            if (document.summaryGenerated)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSummaryCardForSidebar(BuildContext context, SummaryModel summary) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Check if this is a new item
    final newItems = ref.watch(newItemsProvider);
    final isNew = newItems.containsKey(summary.id) && !newItems[summary.id]!.isExpired;

    // Format time
    final timeString = DateTimeUtils.formatRelativeTime(summary.createdAt);

    // Determine summary type and get appropriate icon/color
    final summaryType = summary.summaryType.toString().split('.').last.toUpperCase();
    final isMeetingSummary = summaryType == 'MEETING';
    final summaryIcon = isMeetingSummary ? Icons.groups_outlined : Icons.auto_awesome_outlined;
    final summaryColor = isMeetingSummary ? Colors.blue : Colors.purple;

    // Format the format type properly (capitalize first letter)
    final formatType = summary.format;
    final formattedFormat = formatType[0].toUpperCase() + formatType.substring(1);

    // Format the subject with format type
    final displaySubject = summary.subject.contains('Project Summary')
        ? summary.subject.replaceFirst('Project Summary', '${formattedFormat} Summary')
        : summary.subject.contains('Meeting Summary')
            ? summary.subject.replaceFirst('Meeting Summary', '${formattedFormat} Meeting')
            : '${formattedFormat} - ${summary.subject}';

    return InkWell(
      onTap: () => context.push('/summaries/${summary.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            // Compact icon with appropriate color
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: summaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                summaryIcon,
                size: 14,
                color: summaryColor.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with NEW badge at the beginning
                  Row(
                    children: [
                      // NEW badge at the beginning
                      if (isNew) ...[
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
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          displaySubject,
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Time
                  Text(
                    timeString,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFormatColor(String format) {
    switch (format.toLowerCase()) {
      case 'executive':
        return Colors.deepPurple;
      case 'technical':
        return Colors.blue;
      case 'stakeholder':
        return Colors.green;
      case 'general':
      default:
        return Colors.grey;
    }
  }

  Widget _buildSimpleSummaryCard(BuildContext context, SummaryModel summary) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Check if this is a new item
    final newItems = ref.watch(newItemsProvider);
    final isNew = newItems.containsKey(summary.id) && !newItems[summary.id]!.isExpired;

    // Determine summary type and get appropriate icon/color
    final summaryType = summary.summaryType.toString().split('.').last.toUpperCase();
    final isMeetingSummary = summaryType == 'MEETING';
    final summaryIcon = isMeetingSummary ? Icons.groups_outlined : Icons.auto_awesome_outlined;
    final summaryColor = isMeetingSummary ? Colors.blue : Colors.purple;

    // Format the format type properly (capitalize first letter)
    final formatType = summary.format;
    final formattedFormat = formatType[0].toUpperCase() + formatType.substring(1);

    // Format the subject with format type
    final displaySubject = summary.subject.contains('Project Summary')
        ? summary.subject.replaceFirst('Project Summary', '${formattedFormat} Summary')
        : summary.subject.contains('Meeting Summary')
            ? summary.subject.replaceFirst('Meeting Summary', '${formattedFormat} Meeting')
            : '${formattedFormat} - ${summary.subject}';

    return InkWell(
      onTap: () => context.push('/summaries/${summary.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              summaryIcon,
              size: 18,
              color: summaryColor.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with NEW badge at the beginning
                  Row(
                    children: [
                      // NEW badge at the beginning
                      if (isNew) ...[
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
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          displaySubject,
                          style: textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        isMeetingSummary ? 'Meeting • ' : 'Project • ',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        DateTimeUtils.formatTimeAgo(summary.createdAt),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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
    );
  }

  Widget _buildStatisticsGrid(BuildContext context, WidgetRef ref, Project project) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final documentsCount = ref.watch(meetingsStatisticsProvider).when(
      data: (stats) => stats['total'].toString(),
      loading: () => '...',
      error: (_, __) => '0',
    );

    final summariesCount = ref.watch(projectSummariesProvider(project.id)).when(
      data: (summaries) => summaries.length.toString(),
      loading: () => '...',
      error: (_, __) => '0',
    );

    final stats = [
      _StatItem(label: 'Documents', value: documentsCount, icon: Icons.folder_outlined),
      _StatItem(label: 'Summaries', value: summariesCount, icon: Icons.summarize_outlined),
      _StatItem(label: 'Last Activity', value: DateTimeUtils.formatTimeAgo(project.createdAt), icon: Icons.access_time),
    ];

    return Row(
      children: stats.map((stat) =>
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    stat.icon,
                    color: colorScheme.primary.withValues(alpha: 0.8),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stat.value,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        stat.label,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text('View All'),
          ),
      ],
    );
  }

  Widget _buildMeetingsList(BuildContext context, List<Content> meetings) {
    if (meetings.isEmpty) {
      return _buildEmptyState(
        context,
        'No meetings yet',
        'Upload your first meeting transcript',
        Icons.groups_outlined,
      );
    }

    return Column(
      children: meetings.map((meeting) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMeetingCard(context, meeting),
        ),
      ).toList(),
    );
  }

  Widget _buildMeetingCard(BuildContext context, Content meeting) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _showContentDetails(context, meeting),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  meeting.contentType == ContentType.meeting ? Icons.groups : Icons.email,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meeting.title,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meeting.displayDate,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (meeting.summaryGenerated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Summarized',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummariesList(BuildContext context, List<dynamic> summaries) {
    if (summaries.isEmpty) {
      return _buildEmptyState(
        context,
        'No summaries yet',
        'Generate insights from your meetings',
        Icons.summarize_outlined,
      );
    }

    return Column(
      children: summaries.map((summary) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSummaryCard(context, summary),
        ),
      ).toList(),
    );
  }

  Widget _buildSummaryCard(BuildContext context, dynamic summary) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.push('/summaries/${summary.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.subject ?? 'Summary',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateTimeUtils.formatTimeAgo(summary.createdAt),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  summary.format ?? 'general',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactEmptyState(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSummaryCard(BuildContext context, dynamic summary) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.push('/summaries/${summary.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.purple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.subject ?? 'Summary',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateTimeUtils.formatTimeAgo(summary.createdAt),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  summary.format ?? 'general',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String subtitle, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/hierarchy'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Projects'),
            ),
          ],
        ),
      ),
    );
  }


  void _showProjectMenu(BuildContext context, Project project) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Project'),
                onTap: () {
                  Navigator.pop(context);
                  context.go(AppRoutes.editProjectPath(project.id));
                },
              ),
              ListTile(
                leading: Icon(
                  project.status == ProjectStatus.active
                      ? Icons.archive_outlined
                      : Icons.unarchive_outlined,
                ),
                title: Text(project.status == ProjectStatus.active ? 'Archive Project' : 'Activate Project'),
                onTap: () {
                  Navigator.pop(context);
                  _handleMenuAction(context, project.status == ProjectStatus.active ? 'archive' : 'activate', project);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Project', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, project);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, Project project) {
    switch (action) {
      case 'activities':
        _showActivityDialog(context, project);
        break;
      case 'documents':
        _showDocumentsDialog(context, project);
        break;
      case 'lessons':
        context.push('/lessons?project=${project.id}&from=project');
        break;
      case 'edit':
        _showEditProjectDialog(context, project);
        break;
      case 'archive':
        _showArchiveConfirmation(context, project);
        break;
      case 'activate':
        _showActivateConfirmation(context, project);
        break;
      case 'delete':
        _showDeleteConfirmation(context, project);
        break;
    }
  }

  void _showArchiveConfirmation(BuildContext context, Project project) {
    // Capture the outer context for snackbar after dialog is dismissed
    final outerContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive Project'),
        content: Text('Are you sure you want to archive "${project.name}"? The project will be moved to archived status.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(projectsListProvider.notifier).archiveProject(project.id);
              // Invalidate providers to refresh the UI
              ref.invalidate(projectDetailProvider(project.id));
              ref.invalidate(hierarchyStateProvider);
              if (outerContext.mounted) {
                ScaffoldMessenger.of(outerContext).showSnackBar(
                  const SnackBar(content: Text('Project archived')),
                );
              }
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _showActivateConfirmation(BuildContext context, Project project) {
    // Capture the outer context for snackbar after dialog is dismissed
    final outerContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Activate Project'),
        content: Text('Are you sure you want to activate "${project.name}"? The project will be moved to active status.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(projectsListProvider.notifier).restoreProject(project.id);
              // Invalidate providers to refresh the UI
              ref.invalidate(projectDetailProvider(project.id));
              ref.invalidate(hierarchyStateProvider);
              if (outerContext.mounted) {
                ScaffoldMessenger.of(outerContext).showSnackBar(
                  const SnackBar(content: Text('Project activated')),
                );
              }
            },
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Project project) {
    // Capture the outer context for navigation after dialog is dismissed
    final outerContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${project.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(projectsListProvider.notifier).deleteProject(project.id);
              // Invalidate all related providers to ensure fresh data
              ref.invalidate(projectDetailProvider(project.id));
              ref.invalidate(projectsListProvider);
              ref.invalidate(hierarchyStateProvider);
              if (outerContext.mounted) {
                outerContext.go('/hierarchy');
                ScaffoldMessenger.of(outerContext).showSnackBar(
                  const SnackBar(content: Text('Project deleted')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showContentDetails(BuildContext context, Content content) {
    // Use the consistent DocumentDetailDialog
    DocumentDetailDialog.show(context, content);
  }

  void _showGenerateSummaryDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
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
              Navigator.of(dialogContext).pop();
              context.push('/summaries/${generatedSummary.id}');

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Summary generated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }

            ref.invalidate(projectSummariesProvider(project.id));
            _checkContentAvailability();

            return generatedSummary!;
          } catch (e) {
            throw Exception('Failed to generate summary: $e');
          }
        },
        onUploadContent: () {
          Navigator.of(dialogContext).pop();
          _showUploadDialog(context, project);
        },
      ),
    );
  }

  void _showUploadDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.4,
          constraints: BoxConstraints(
            maxWidth: 500,
            minHeight: 400, // Minimum height for usability
            maxHeight: MediaQuery.of(context).size.height * 0.6, // Reduced from 0.8
          ),
          child: UploadContentDialog(
            project: project,
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

  void _showRecordingDialog(BuildContext context, Project project) {
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
              project: project,
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

  void _showEditProjectDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (context) => EditProjectDialog(project: project),
    );
  }

  void _showActivityDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _ActivityDialog(
        projectId: project.id,
        projectName: project.name,
        onClose: () {
          ref.read(activityProvider.notifier).stopPolling();
          Navigator.of(dialogContext).pop();
        },
      ),
    ).then((_) {
      // Stop polling when dialog is closed
      ref.read(activityProvider.notifier).stopPolling();
    });
  }

  void _showQueryDialog(BuildContext context, Project project) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AskAIPanel(
          projectId: project.id,
          projectName: project.name,
          onClose: () {
            Navigator.of(context).pop();
            ref.read(queryProvider.notifier).clearConversation();
          },
        );
      },
    );
  }

  void _showDocumentsDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _DocumentsDialog(
        projectId: project.id,
        projectName: project.name,
      ),
    );
  }

  void _showSummariesDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _SummariesDialog(
        projectId: project.id,
        projectName: project.name,
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, Activity activity) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    IconData icon;
    Color color;

    // The activity type is an enum from the Activity entity
    switch (activity.type) {
      case ActivityType.summaryGenerated:
        icon = Icons.auto_awesome;
        color = Colors.purple;
        break;
      case ActivityType.contentUploaded:
        icon = Icons.upload_file;
        color = Colors.blue;
        break;
      case ActivityType.projectUpdated:
        icon = Icons.edit;
        color = Colors.orange;
        break;
      case ActivityType.projectCreated:
        icon = Icons.add_circle;
        color = Colors.green;
        break;
      case ActivityType.querySubmitted:
        icon = Icons.search;
        color = Colors.teal;
        break;
      case ActivityType.reportGenerated:
        icon = Icons.description;
        color = Colors.indigo;
        break;
      case ActivityType.memberAdded:
        icon = Icons.person_add;
        color = Colors.cyan;
        break;
      case ActivityType.memberRemoved:
        icon = Icons.person_remove;
        color = Colors.red;
        break;
      case ActivityType.projectDeleted:
        icon = Icons.delete;
        color = Colors.red;
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                activity.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        Text(
          _formatActivityTime(activity.timestamp),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  String _formatActivityTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}

// Separate widget for the activity dialog to properly manage its state
class _ActivityDialog extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;
  final VoidCallback onClose;

  const _ActivityDialog({
    required this.projectId,
    required this.projectName,
    required this.onClose,
  });

  @override
  ConsumerState<_ActivityDialog> createState() => _ActivityDialogState();
}

class _ActivityDialogState extends ConsumerState<_ActivityDialog> {
  late final ActivityNotifier _activityNotifier;

  @override
  void initState() {
    super.initState();
    _activityNotifier = ref.read(activityProvider.notifier);
    // Load activities when the dialog is first shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _activityNotifier.loadActivities(widget.projectId);
      _activityNotifier.startPolling(widget.projectId);
    });
  }

  @override
  void dispose() {
    // Stop polling when dialog is disposed
    _activityNotifier.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activityState = ref.watch(activityProvider);
    final activities = activityState.activities;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Simplified Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.timeline_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Project Activities',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
            ),

            // Activity Feed
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Builder(
                  builder: (context) {
                    // Show loading indicator on first load
                    if (activityState.isLoading) {
                      return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                'Loading activities...',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (activities.isEmpty && !activityState.isLoading) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.timeline_outlined,
                                size: 48,
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No activities yet',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: activities.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final activity = activities[index];
                        return _buildActivityItem(context, activity);
                      },
                    );
                  },
                ),
              ),
            ),
            ],
          ),
        ),
      );
  }

  Widget _buildActivityItem(BuildContext context, Activity activity) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activities = ref.watch(activityProvider).activities;
    final index = activities.indexOf(activity);
    final isLast = index == activities.length - 1;

    IconData icon;
    Color color;

    // The activity type is an enum from the Activity entity
    switch (activity.type) {
      case ActivityType.summaryGenerated:
        icon = Icons.auto_awesome;
        color = Colors.purple;
        break;
      case ActivityType.contentUploaded:
        icon = Icons.upload_file;
        color = Colors.blue;
        break;
      case ActivityType.projectUpdated:
        icon = Icons.edit;
        color = Colors.orange;
        break;
      case ActivityType.projectCreated:
        icon = Icons.add_circle;
        color = Colors.green;
        break;
      case ActivityType.querySubmitted:
        icon = Icons.search;
        color = Colors.teal;
        break;
      case ActivityType.reportGenerated:
        icon = Icons.description;
        color = Colors.indigo;
        break;
      case ActivityType.memberAdded:
        icon = Icons.person_add;
        color = Colors.cyan;
        break;
      case ActivityType.memberRemoved:
        icon = Icons.person_remove;
        color = Colors.red;
        break;
      case ActivityType.projectDeleted:
        icon = Icons.delete;
        color = Colors.red;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline track
          SizedBox(
            width: 50,
            child: Column(
              children: [
                // Timeline dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                // Connecting line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colorScheme.onSurface.withValues(alpha: 0.15),
                            colorScheme.onSurface.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Activity content
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          size: 16,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          activity.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        _formatActivityTime(activity.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Description
                  Padding(
                    padding: const EdgeInsets.only(left: 44),
                    child: Text(
                      activity.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatActivityTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}

// Documents Dialog
class _DocumentsDialog extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;

  const _DocumentsDialog({
    required this.projectId,
    required this.projectName,
  });

  @override
  ConsumerState<_DocumentsDialog> createState() => _DocumentsDialogState();
}

class _DocumentsDialogState extends ConsumerState<_DocumentsDialog> {
  String _sortBy = 'date'; // 'date', 'name'
  String _filterBy = 'all'; // 'all', 'meeting', 'transcript', 'upload'
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) {
    final meetingsAsync = ref.watch(meetingsListProvider);
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 650,
        height: 600,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All Documents',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                  ),
                ],
              ),
            ),

            // Filters and Sorting Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.03),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Filter chip
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: _filterBy != 'all'
                          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _filterBy != 'all'
                            ? theme.colorScheme.primary.withValues(alpha: 0.2)
                            : theme.colorScheme.outline.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: DropdownButton<String>(
                        value: _filterBy,
                        underline: const SizedBox(),
                        icon: Icon(
                          Icons.expand_more,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        isDense: true,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Types')),
                          DropdownMenuItem(value: 'meeting', child: Text('Meeting')),
                          DropdownMenuItem(value: 'transcript', child: Text('Transcript')),
                          DropdownMenuItem(value: 'upload', child: Text('Upload')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _filterBy = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Sort chip
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        underline: const SizedBox(),
                        icon: Icon(
                          Icons.expand_more,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        isDense: true,
                        items: const [
                          DropdownMenuItem(value: 'date', child: Text('Date')),
                          DropdownMenuItem(value: 'name', child: Text('Name')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _sortBy = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  // Sort direction toggle chip
                  const SizedBox(width: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _sortAscending = !_sortAscending;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: Icon(
                            _sortAscending ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: meetingsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Text('Error loading documents: $error'),
                ),
                data: (meetings) {
                  if (meetings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No documents yet',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Apply filtering and sorting
                  var filteredDocuments = meetings.where((meeting) {
                    if (_filterBy == 'all') return true;
                    if (_filterBy == 'meeting') return meeting.contentType == ContentType.meeting;
                    if (_filterBy == 'transcript') return meeting.contentType == ContentType.email; // Using email as transcript for now
                    if (_filterBy == 'upload') return true; // All are uploads in a sense
                    return true;
                  }).toList();

                  filteredDocuments.sort((a, b) {
                    int comparison;
                    if (_sortBy == 'date') {
                      comparison = a.uploadedAt.compareTo(b.uploadedAt);
                    } else {
                      comparison = a.title.compareTo(b.title);
                    }
                    return _sortAscending ? comparison : -comparison;
                  });

                  // Show empty state if no documents match the filter
                  if (filteredDocuments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.filter_list_off,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No documents found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _filterBy == 'all'
                                ? 'Try adjusting your search criteria'
                                : 'No documents match the "${_getDocumentFilterDisplayName(_filterBy)}" filter',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          if (_filterBy != 'all')
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _filterBy = 'all';
                                });
                              },
                              icon: Icon(
                                Icons.clear,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              label: Text(
                                'Clear filter',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredDocuments.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final meeting = filteredDocuments[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // Use the consistent DocumentDetailDialog instead of navigating
                            DocumentDetailDialog.show(context, meeting);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.description_outlined,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              meeting.title,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              meeting.typeLabel.toLowerCase(),
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                fontSize: 10,
                                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDocumentDate(meeting.uploadedAt),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDocumentDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  String _getDocumentFilterDisplayName(String filterValue) {
    switch (filterValue) {
      case 'all':
        return 'All Types';
      case 'meeting':
        return 'Meeting';
      case 'transcript':
        return 'Transcript';
      case 'upload':
        return 'Upload';
      default:
        return filterValue;
    }
  }
}

// Summaries Dialog
class _SummariesDialog extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;

  const _SummariesDialog({
    required this.projectId,
    required this.projectName,
  });

  @override
  ConsumerState<_SummariesDialog> createState() => _SummariesDialogState();
}

class _SummariesDialogState extends ConsumerState<_SummariesDialog> {
  String _sortBy = 'date'; // 'date', 'name'
  String _filterBy = 'all'; // 'all', 'meeting', 'project', 'executive', 'technical', 'stakeholder', 'general'
  bool _sortAscending = false;

  Color _getFormatColor(String format) {
    switch (format.toLowerCase()) {
      case 'executive':
        return Colors.deepPurple;
      case 'technical':
        return Colors.blue;
      case 'stakeholder':
        return Colors.green;
      case 'general':
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final summariesAsync = ref.watch(projectSummariesProvider(widget.projectId));
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 650,
        height: 600,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All Summaries',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                  ),
                ],
              ),
            ),

            // Filters and Sorting Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.03),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Filter chip
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: _filterBy != 'all'
                          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _filterBy != 'all'
                            ? theme.colorScheme.primary.withValues(alpha: 0.2)
                            : theme.colorScheme.outline.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: DropdownButton<String>(
                        value: _filterBy,
                        underline: const SizedBox(),
                        icon: Icon(
                          Icons.expand_more,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        isDense: true,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Types')),
                          DropdownMenuItem(value: 'meeting', child: Text('Meeting Summaries')),
                          DropdownMenuItem(value: 'project', child: Text('Project Summaries')),
                          DropdownMenuItem(value: 'general', child: Text('General Format')),
                          DropdownMenuItem(value: 'executive', child: Text('Executive Format')),
                          DropdownMenuItem(value: 'technical', child: Text('Technical Format')),
                          DropdownMenuItem(value: 'stakeholder', child: Text('Stakeholder Format')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _filterBy = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Sort chip
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        underline: const SizedBox(),
                        icon: Icon(
                          Icons.expand_more,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        isDense: true,
                        items: const [
                          DropdownMenuItem(value: 'date', child: Text('Date')),
                          DropdownMenuItem(value: 'name', child: Text('Name')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _sortBy = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  // Sort direction toggle chip
                  const SizedBox(width: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _sortAscending = !_sortAscending;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: Icon(
                            _sortAscending ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: summariesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Text('Error loading summaries: $error'),
                ),
                data: (summaries) {
                  if (summaries.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No summaries yet',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Apply filtering and sorting
                  var filteredSummaries = summaries.where((summary) {
                    if (_filterBy == 'all') return true;
                    // Filter by summary type
                    if (_filterBy == 'meeting') return summary.summaryType == SummaryType.meeting;
                    if (_filterBy == 'project') return summary.summaryType == SummaryType.project;
                    // Filter by format type
                    if (_filterBy == 'general') return summary.format == 'general';
                    if (_filterBy == 'executive') return summary.format == 'executive';
                    if (_filterBy == 'technical') return summary.format == 'technical';
                    if (_filterBy == 'stakeholder') return summary.format == 'stakeholder';
                    return true;
                  }).toList();

                  filteredSummaries.sort((a, b) {
                    int comparison;
                    if (_sortBy == 'date') {
                      comparison = a.createdAt.compareTo(b.createdAt);
                    } else {
                      comparison = a.subject.compareTo(b.subject);
                    }
                    return _sortAscending ? comparison : -comparison;
                  });

                  // Show empty state if no summaries match the filter
                  if (filteredSummaries.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.filter_list_off,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No summaries found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _filterBy == 'all'
                                ? 'Try adjusting your search criteria'
                                : 'No summaries match the "${_getFilterDisplayName(_filterBy)}" filter',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          if (_filterBy != 'all')
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _filterBy = 'all';
                                });
                              },
                              icon: Icon(
                                Icons.clear,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              label: Text(
                                'Clear filter',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredSummaries.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final summary = filteredSummaries[index];

                      // Determine summary type and get appropriate icon/color
                      final isMeetingSummary = summary.summaryType == SummaryType.meeting;
                      final summaryIcon = isMeetingSummary ? Icons.groups_outlined : Icons.auto_awesome;
                      final summaryColor = isMeetingSummary ? Colors.blue : Colors.purple;

                      // Format the format type properly (capitalize first letter)
                      final formatType = summary.format;
                      final formattedFormat = formatType[0].toUpperCase() + formatType.substring(1);

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            context.push('/summaries/${summary.id}');
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: summaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    summaryIcon,
                                    size: 16,
                                    color: summaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              summary.subject,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          // Summary type badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: summaryColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: summaryColor.withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              isMeetingSummary ? 'Meeting' : 'Project',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: summaryColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          // Format badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getFormatColor(formatType).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: _getFormatColor(formatType).withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              formattedFormat,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: _getFormatColor(formatType),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatSummaryDate(summary.createdAt),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSummaryDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  String _getFilterDisplayName(String filterValue) {
    switch (filterValue) {
      case 'all':
        return 'All Types';
      case 'meeting':
        return 'Meeting Summaries';
      case 'project':
        return 'Project Summaries';
      case 'general':
        return 'General Format';
      case 'executive':
        return 'Executive Format';
      case 'technical':
        return 'Technical Format';
      case 'stakeholder':
        return 'Stakeholder Format';
      default:
        return filterValue;
    }
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}

// Upload Content Dialog Widget
