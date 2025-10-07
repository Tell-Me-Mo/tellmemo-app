import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/hierarchy_providers.dart';
import '../../domain/entities/portfolio.dart';
import '../../domain/entities/program.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../../core/utils/datetime_utils.dart';
import '../widgets/create_program_dialog.dart';
import '../widgets/edit_portfolio_dialog.dart';
import '../widgets/create_project_from_hierarchy_dialog.dart';
import '../widgets/enhanced_delete_dialog.dart';
import '../../domain/entities/hierarchy_item.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_client.dart';
import '../../../summaries/data/models/summary_model.dart';
import '../../../summaries/presentation/widgets/summary_generation_dialog.dart';
import '../../../activities/domain/entities/activity.dart';
import '../../../activities/data/models/activity_model.dart';
import '../../../queries/presentation/widgets/ask_ai_panel.dart';

class PortfolioDetailScreen extends ConsumerStatefulWidget {
  final String portfolioId;

  const PortfolioDetailScreen({
    super.key,
    required this.portfolioId,
  });

  @override
  ConsumerState<PortfolioDetailScreen> createState() => _PortfolioDetailScreenState();
}

class _PortfolioDetailScreenState extends ConsumerState<PortfolioDetailScreen> {
  int _summaryRefreshCounter = 0;
  final ScrollController _scrollController = ScrollController();
  List<Activity> _recentActivities = [];
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  void _refreshSummaries() {
    setState(() {
      _summaryRefreshCounter++;
    });
  }

  Future<void> _loadPortfolioActivities(Portfolio portfolio) async {
    try {
      final allActivities = <Activity>[];

      // Fetch activities for each project across all programs
      // Note: portfolio.programs.projects is empty because list endpoint doesn't populate it
      // We need to fetch each program's projects individually
      for (final program in portfolio.programs) {
        try {
          // Fetch full program details to get its projects
          final programResponse = await DioClient.instance.get(
            '/api/v1/programs/${program.id}',
          );

          if (programResponse.data != null && programResponse.data['projects'] != null) {
            final projects = programResponse.data['projects'] as List;

            for (final projectData in projects) {
              try {
                final projectId = projectData['id'];
                final response = await DioClient.instance.get(
                  '/api/projects/$projectId/activities',
                );

                if (response.data != null && response.data is List) {
                  final List<Map<String, dynamic>> activitiesData =
                      List<Map<String, dynamic>>.from(response.data);

                  for (final activityJson in activitiesData) {
                    try {
                      final activity = ActivityModel.fromJson(activityJson).toEntity();
                      allActivities.add(activity);
                    } catch (e) {
                      // Silently skip malformed activities
                    }
                  }
                }
              } catch (e) {
                // Skip if project activities cannot be fetched
              }
            }
          }
        } catch (e) {
          // Skip if program cannot be fetched
        }
      }

      // Also fetch activities for direct projects
      for (final project in portfolio.directProjects) {
        try {
          final response = await DioClient.instance.get(
            '/api/projects/${project.id}/activities',
          );

          if (response.data != null && response.data is List) {
            final List<Map<String, dynamic>> activitiesData =
                List<Map<String, dynamic>>.from(response.data);

            for (final activityJson in activitiesData) {
              try {
                final activity = ActivityModel.fromJson(activityJson).toEntity();
                allActivities.add(activity);
              } catch (e) {
                // Silently skip malformed activities
              }
            }
          }
        } catch (e) {
          // Skip if project activities cannot be fetched
        }
      }

      // Sort activities by timestamp (newest first)
      allActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Keep only the most recent 10 activities
      final recentActivities = allActivities.take(10).toList();

      if (mounted) {
        setState(() {
          _recentActivities = recentActivities;
        });
      }
    } catch (e) {
      // Handle error silently or show a message
    }
  }

  @override
  Widget build(BuildContext context) {
    final portfolioAsync = ref.watch(portfolioProvider(widget.portfolioId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return portfolioAsync.when(
      data: (portfolio) {
        if (portfolio == null) {
          return _buildErrorState(context, 'Portfolio not found');
        }
        // Load activities only once when portfolio first becomes available
        if (!_hasInitialized) {
          _hasInitialized = true;
          // Use post-frame callback to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadPortfolioActivities(portfolio);
          });
        }
        return _buildPortfolioDetails(context, portfolio);
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
          'Error loading portfolio: ${error.toString()}',
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(portfolioProvider(widget.portfolioId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioDetails(BuildContext context, Portfolio portfolio) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 32 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : double.infinity),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Portfolio Header
                    _buildPortfolioHeader(context, portfolio),

                    // Divider
                    const SizedBox(height: 20),
                    Divider(
                      color: colorScheme.outline.withValues(alpha: 0.08),
                      thickness: 1,
                      height: 1,
                    ),
                    const SizedBox(height: 24),

                    // Main content layout
                    if (isDesktop) ...[
                      _buildMainContent(context, portfolio),
                    ] else ...[
                      // Mobile/Tablet Layout - Stack vertically with Quick Actions first
                      _buildSidebar(context, portfolio),
                      const SizedBox(height: 24),
                      _buildMainContent(context, portfolio),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context, portfolio),
    );
  }


  Widget _buildPortfolioHeader(BuildContext context, Portfolio portfolio) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile) ...[
          // Mobile Header - Single row
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
                      portfolio.name,
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
                            Icon(Icons.person_outline, size: 12, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                            const SizedBox(width: 4),
                            Text(
                              portfolio.owner?.isNotEmpty == true ? portfolio.owner! : 'Unassigned',
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
                            Icon(Icons.calendar_today_outlined, size: 12, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                            const SizedBox(width: 4),
                            Text(
                              _formatFullDate(DateTime.now()),
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
                onSelected: (value) => _handleMenuAction(context, value, portfolio),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'recent_activity',
                    child: Row(
                      children: [
                        Icon(Icons.timeline, size: 20),
                        SizedBox(width: 12),
                        Text('Recent Activity'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'generate_summary',
                    child: Row(
                      children: [
                        Icon(Icons.summarize, size: 20),
                        SizedBox(width: 12),
                        Text('Generate Summary'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('Edit Portfolio'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: Colors.red)),
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

              // PORTFOLIO badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.indigo.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.business_center_outlined,
                      size: 14,
                      color: Colors.indigo[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PORTFOLIO',
                      style: TextStyle(
                        color: Colors.indigo[600],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Portfolio title
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        portfolio.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Health status badge
                    _buildHealthStatusBadge(portfolio.healthStatus),
                  ],
                ),
              ),

              // Menu button
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, color: colorScheme.onSurfaceVariant),
                onSelected: (value) => _handleMenuAction(context, value, portfolio),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'generate_summary',
                    child: Row(
                      children: [
                        Icon(Icons.summarize, size: 20),
                        SizedBox(width: 12),
                        Text('Generate Summary'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('Edit Portfolio'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Metadata row
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(
                  portfolio.owner?.isNotEmpty == true ? portfolio.owner! : 'Unassigned',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today_outlined, size: 14, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(
                  _formatFullDate(DateTime.now()), // Using current date as createdAt is not available
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHealthStatusBadge(HealthStatus status) {
    Color color;
    String label;

    switch (status) {
      case HealthStatus.green:
        color = Colors.green;
        label = 'HEALTHY';
        break;
      case HealthStatus.amber:
        color = Colors.amber;
        label = 'AT RISK';
        break;
      case HealthStatus.red:
        color = Colors.red;
        label = 'CRITICAL';
        break;
      case HealthStatus.notSet:
        color = Colors.grey;
        label = 'NOT SET';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color == Colors.green ? Colors.green[700]
              : color == Colors.amber ? Colors.amber[700]
              : color == Colors.red ? Colors.red[700]
              : Colors.grey[700],
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, Portfolio portfolio) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;

    // For desktop, wrap entire content in Row with sidebar
    if (isDesktop) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Main content
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description Section
                  if (portfolio.description != null && portfolio.description!.isNotEmpty) ...[
                    _buildDescriptionCard(context, portfolio),
                    const SizedBox(height: 24),
                  ],

                  // Risk Summary Section
                  if (portfolio.riskSummary != null && portfolio.riskSummary!.isNotEmpty) ...[
                    _buildRiskSummaryCard(context, portfolio),
                    const SizedBox(height: 24),
                  ],

                  // Portfolio Summaries Section
                  _buildSummariesSection(context, portfolio),
                  const SizedBox(height: 24),

                  // Programs Section
                  _buildProgramsSection(context, portfolio),
                  const SizedBox(height: 24),

                  // Direct Projects Section
                  _buildDirectProjectsSection(context, portfolio),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Divider
            Container(
              width: 1,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
            ),
            const SizedBox(width: 24),
            // Right Sidebar
            SizedBox(
              width: 320,
              child: _buildSidebar(context, portfolio),
            ),
          ],
        ),
      );
    } else {
      // Mobile/Tablet layout
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description Section
          if (portfolio.description != null && portfolio.description!.isNotEmpty) ...[
            _buildDescriptionCard(context, portfolio),
            const SizedBox(height: 24),
          ],

          // Risk Summary Section
          if (portfolio.riskSummary != null && portfolio.riskSummary!.isNotEmpty) ...[
            _buildRiskSummaryCard(context, portfolio),
            const SizedBox(height: 24),
          ],

          // Portfolio Summaries Section
          _buildSummariesSection(context, portfolio),
          const SizedBox(height: 24),

          // Programs Section
          _buildProgramsSection(context, portfolio),
          const SizedBox(height: 24),

          // Direct Projects Section
          _buildDirectProjectsSection(context, portfolio),
        ],
      );
    }
  }

  Widget _buildDescriptionCard(BuildContext context, Portfolio portfolio) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Description',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            portfolio.description!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskSummaryCard(BuildContext context, Portfolio portfolio) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: Colors.orange[700],
              ),
              const SizedBox(width: 8),
              Text(
                'Risk Summary',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            portfolio.riskSummary!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSummariesSection(BuildContext context, Portfolio portfolio) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.summarize,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Portfolio Summaries',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => _showPortfolioSummaryDialog(context, portfolio),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Generate'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildPortfolioSummariesList(portfolio.id),
      ],
    );
  }

  Widget _buildProgramsSection(BuildContext context, Portfolio portfolio) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dashboard_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Programs (${portfolio.programs.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => _showCreateProgramDialog(portfolio),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Program'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (portfolio.programs.isEmpty)
          _buildEmptyProgramsState(context)
        else
          ...portfolio.programs.map((program) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildProgramCard(context, program),
          )),
      ],
    );
  }

  Widget _buildDirectProjectsSection(BuildContext context, Portfolio portfolio) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.work_outline,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Direct Projects (${portfolio.directProjects.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => _showCreateProjectDialog(portfolio),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Project'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (portfolio.directProjects.isEmpty)
          _buildEmptyDirectProjectsState(context, portfolio)
        else
          ...portfolio.directProjects.map((project) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildProjectCard(context, project),
          )),
      ],
    );
  }


  Widget _buildSidebar(BuildContext context, Portfolio portfolio) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 768;

    return Column(
      children: [
        // Quick Actions Card
        _buildQuickActionsCard(context, portfolio),
        // Activities Section - Only show on desktop
        if (!isMobile) ...[
          const SizedBox(height: 16),
          _buildActivitiesCard(context, portfolio),
        ],
      ],
    );
  }

  Widget _buildActivitiesCard(BuildContext context, Portfolio portfolio) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header (matching program style)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'RECENT ACTIVITY',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              fontSize: 10,
            ),
          ),
        ),
        // Activity content container
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_recentActivities.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.timeline,
                        size: 48,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _hasInitialized ? 'No recent activity' : 'Loading activities...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...List.generate(
                  _recentActivities.length,
                  (index) => _buildActivityItem(
                    context,
                    _recentActivities[index],
                    index == _recentActivities.length - 1,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(BuildContext context, Activity activity, bool isLast) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _getActivityColor(activity.type),
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Activity content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activity.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      activity.formattedTime,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  activity.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.projectCreated:
        return Colors.green;
      case ActivityType.projectUpdated:
        return Colors.blue;
      case ActivityType.projectDeleted:
        return Colors.red;
      case ActivityType.contentUploaded:
        return Colors.purple;
      case ActivityType.summaryGenerated:
        return Colors.orange;
      case ActivityType.querySubmitted:
        return Colors.teal;
      case ActivityType.reportGenerated:
        return Colors.indigo;
      case ActivityType.memberAdded:
        return Colors.cyan;
      case ActivityType.memberRemoved:
        return Colors.pink;
    }
  }



  Widget _buildQuickActionsCard(BuildContext context, Portfolio portfolio) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
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
        // Quick Action Cards
        Column(
          children: [
            _buildQuickActionItem(
              context,
              Icons.add,
              'Add Program',
              Colors.blue,
              () => _showCreateProgramDialog(portfolio),
            ),
            const SizedBox(height: 8),
            _buildQuickActionItem(
              context,
              Icons.work_outline,
              'Add Project',
              Colors.green,
              () => _showCreateProjectDialog(portfolio),
            ),
            const SizedBox(height: 8),
            _buildQuickActionItem(
              context,
              Icons.summarize_outlined,
              'Generate Summary',
              Colors.purple,
              () => _showPortfolioSummaryDialog(context, portfolio),
            ),
            const SizedBox(height: 8),
            _buildQuickActionItem(
              context,
              Icons.edit_outlined,
              'Edit Portfolio',
              Colors.orange,
              () => _showEditDialog(portfolio),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
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


  Widget _buildProgramCard(BuildContext context, Program program) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => context.go('/hierarchy/program/${program.id}'),
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
            // Program icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.dashboard,
                  color: Colors.deepPurple[700],
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Program details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (program.description != null && program.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      program.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${program.projectCount} projects',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = project.status == ProjectStatus.active;

    return InkWell(
      onTap: () => context.go('/hierarchy/project/${project.id}'),
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
            // Project icon
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
                  project.name.isNotEmpty ? project.name[0].toUpperCase() : 'P',
                  style: TextStyle(
                    color: isActive ? Colors.green[700] : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Project details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isActive
                                ? Colors.green.withValues(alpha: 0.4)
                                : Colors.grey.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isActive ? 'ACTIVE' : 'ARCHIVED',
                          style: TextStyle(
                            color: isActive ? Colors.green[700] : Colors.grey[700],
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (project.description != null && project.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      project.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
    );
  }

  Widget _buildEmptyProgramsState(BuildContext context) {
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
              'No programs yet',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create programs to organize projects,\nor add projects directly to this portfolio',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDirectProjectsState(BuildContext context, Portfolio portfolio) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                Icons.work_outline,
                size: 32,
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No direct projects yet',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Projects can be added directly to the portfolio\nor organized within programs',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioSummariesList(String portfolioId) {
    return FutureBuilder<List<dynamic>>(
      key: ValueKey('portfolio_summaries_$_summaryRefreshCounter'),
      future: ApiClient(DioClient.instance).getPortfolioSummaries(portfolioId),
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 100,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Text(
                'Failed to load summaries',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red[700],
                ),
              ),
            ),
          );
        }

        final summaries = snapshot.data ?? [];

        if (summaries.isEmpty) {
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
                      Icons.description_outlined,
                      size: 32,
                      color: colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No portfolio summaries yet',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add at least one project to start generating\nportfolio summaries and track progress',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: summaries.map((summaryJson) {
            final summary = SummaryModel.fromJson(summaryJson);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSummaryCard(context, summary),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, SummaryModel summary) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => context.push('/summaries/${summary.id}'),
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
            // Summary icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.description,
                  size: 20,
                  color: Colors.blue[700],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Summary details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.subject.isNotEmpty ? summary.subject : 'Portfolio Summary',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateTimeUtils.formatTimeAgo(summary.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.format_align_left,
                        size: 12,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        summary.format.isNotEmpty ? summary.format : 'Default',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context, Portfolio portfolio) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Always show Ask AI FAB
    return FloatingActionButton.extended(
      onPressed: () => _showQueryDialog(context, portfolio),
      icon: const Icon(Icons.psychology_outlined),
      label: const Text('Ask AI'),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 4,
    );
  }



  void _handleMenuAction(BuildContext context, String action, Portfolio portfolio) {
    switch (action) {
      case 'recent_activity':
        _showRecentActivityDialog(context, portfolio);
        break;
      case 'generate_summary':
        _showPortfolioSummaryDialog(context, portfolio);
        break;
      case 'edit':
        _showEditDialog(portfolio);
        break;
      case 'delete':
        _showDeleteConfirmation(portfolio);
        break;
    }
  }

  void _showRecentActivityDialog(BuildContext context, Portfolio portfolio) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timeline, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Recent Activity',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _recentActivities.isEmpty
                      ? Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              Icon(
                                Icons.timeline,
                                size: 64,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _hasInitialized ? 'No recent activity' : 'Loading activities...',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        )
                      : Column(
                          children: List.generate(
                            _recentActivities.length,
                            (index) => _buildActivityItem(
                              context,
                              _recentActivities[index],
                              index == _recentActivities.length - 1,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(Portfolio portfolio) {
    showDialog(
      context: context,
      builder: (context) => EditPortfolioDialog(
        portfolioId: portfolio.id,
      ),
    );
  }

  void _showDeleteConfirmation(Portfolio portfolio) {
    showDialog(
      context: context,
      builder: (context) => EnhancedDeleteDialog(
        itemId: portfolio.id,
        itemName: portfolio.name,
        itemType: HierarchyItemType.portfolio,
      ),
    ).then((_) {
      // Navigate to hierarchy after dialog closes
      if (context.mounted) {
        context.go('/hierarchy');
      }
    });
  }

  void _showCreateProgramDialog(Portfolio portfolio) {
    showDialog(
      context: context,
      builder: (context) => CreateProgramDialog(
        portfolioId: portfolio.id,
        portfolioName: portfolio.name,
      ),
    ).then((_) {
      // Refresh the portfolio to show new program
      ref.invalidate(portfolioProvider(widget.portfolioId));
      ref.invalidate(hierarchyStateProvider());
      // Refresh activities after program creation
      final portfolioAsync = ref.read(portfolioProvider(widget.portfolioId));
      if (portfolioAsync.hasValue && portfolioAsync.value != null) {
        _loadPortfolioActivities(portfolioAsync.value!);
      }
    });
  }

  void _showCreateProjectDialog(Portfolio portfolio) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 500,
            maxHeight: 600,
          ),
          child: CreateProjectDialogFromHierarchy(
            preselectedPortfolioId: portfolio.id,
            // No preselected program - project will be directly under portfolio
          ),
        ),
      ),
    ).then((_) {
      // Refresh the portfolio data after dialog closes
      ref.invalidate(portfolioProvider(widget.portfolioId));
      ref.invalidate(hierarchyStateProvider);
      // Refresh activities after project creation
      final portfolioAsync = ref.read(portfolioProvider(widget.portfolioId));
      if (portfolioAsync.hasValue && portfolioAsync.value != null) {
        _loadPortfolioActivities(portfolioAsync.value!);
      }
    });
  }

  void _showQueryDialog(BuildContext context, Portfolio portfolio) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AskAIPanel(
          projectId: portfolio.id,
          projectName: portfolio.name,
          entityType: 'portfolio',
          onClose: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void _showPortfolioSummaryDialog(BuildContext context, Portfolio portfolio) async {
    final result = await showDialog<SummaryModel>(
      context: context,
      builder: (dialogContext) => SummaryGenerationDialog(
        entityType: 'portfolio',
        entityId: portfolio.id,
        entityName: portfolio.name,
        onGenerate: ({
          required String format,
          required DateTime startDate,
          required DateTime endDate,
        }) async {
          try {
            final response = await DioClient.instance.post(
              '/api/summaries/generate',
              data: {
                'entity_type': 'portfolio',
                'entity_id': portfolio.id,
                'summary_type': 'portfolio',
                'date_range_start': startDate.toIso8601String(),
                'date_range_end': endDate.toIso8601String(),
                'format': format,
                'created_by': 'User',
                'use_job': false,
              },
            );

            // Parse the response to a SummaryModel if successful
            if (response.data != null) {
              _refreshSummaries();
              return SummaryModel.fromJson(response.data);
            }
            return null;
          } catch (e) {
            throw Exception('Failed to generate summary: $e');
          }
        },
        onUploadContent: null, // Can be implemented if needed
      ),
    );

    if (result != null && mounted) {
      // Refresh the summaries list first
      _refreshSummaries();

      // Wait a moment for the UI to update
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to the summary detail screen
      if (mounted) {
        context.push('/summaries/${result.id}');
      }
    }
  }

  String _formatFullDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
}