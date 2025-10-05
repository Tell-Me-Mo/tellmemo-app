import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/breakpoints.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../core/network/api_service.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../projects/domain/entities/project.dart';
import '../../data/models/summary_model.dart';
import '../providers/summary_provider.dart';
import '../providers/all_summaries_provider.dart';
import '../widgets/summary_generation_dialog.dart';
import '../widgets/summary_export_dialog.dart';

enum SummaryViewMode {
  list,
  compact,
  grid,
}

class SummariesScreen extends ConsumerStatefulWidget {
  const SummariesScreen({super.key});

  @override
  ConsumerState<SummariesScreen> createState() => _SummariesScreenState();
}

class _SummariesScreenState extends ConsumerState<SummariesScreen>
    with SingleTickerProviderStateMixin {
  SummaryType? _filterType;
  String? _filterProjectId;
  String _searchQuery = '';
  SummaryViewMode _viewMode = SummaryViewMode.compact;  // Default to compact view
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // No need to manually load summaries - the provider will handle it
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshSummaries() async {
    // Load summaries from all projects
    final projectsAsync = ref.read(projectsListProvider);

    projectsAsync.whenData((projects) async {
      if (projects.isEmpty) return;

      // Show loading state
      final notifier = ref.read(summaryListProvider.notifier);
      notifier.clearSummaries();

      List<SummaryModel> allSummaries = [];

      try {
        // Load summaries from all projects
        for (final project in projects) {
          try {
            final apiService = ref.read(apiServiceProvider);
            final client = apiService.client;

            final response = await client.listSummaries(
              entityType: 'project',
              entityId: project.id,
              summaryType: _filterType?.name.toLowerCase(),
            );

            final summaries = response
                .map((json) => SummaryModel.fromJson(json))
                .toList();

            allSummaries.addAll(summaries);
          } catch (e) {
            // Continue loading from other projects even if one fails
            // Continue loading from other projects even if one fails
          }
        }

        // Sort by created date (newest first)
        allSummaries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Refresh the provider to show new data
        ref.invalidate(allSummariesProvider);
      } catch (e) {
        // Handle error
        ref.invalidate(allSummariesProvider);
      }
    });
  }

  bool get _isAllProjectsSelected => _filterProjectId == null || (_filterProjectId != null && _filterProjectId!.isEmpty);

  List<SummaryModel> _getFilteredSummaries(List<SummaryModel> summaries) {
    var filtered = summaries;

    // Filter by type first
    if (_filterType != null) {
      filtered = filtered.where((s) => s.summaryType == _filterType).toList();
    }

    // Filter by project if selected
    if (_filterProjectId != null && _filterProjectId!.isNotEmpty) {
      filtered = filtered.where((s) => s.projectId == _filterProjectId).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((summary) {
        return summary.subject.toLowerCase().contains(query) ||
               summary.format.toLowerCase().contains(query) ||
               (summary.body.toLowerCase().contains(query));
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktop;
    final isTablet = screenWidth >= Breakpoints.tablet && screenWidth < Breakpoints.desktop;
    final isMobile = screenWidth < Breakpoints.tablet;

    final allSummariesAsync = ref.watch(allSummariesProvider);
    final projectsAsync = ref.watch(projectsListProvider);

    return projectsAsync.when(
      loading: () => _buildLoadingScreen(theme),
      error: (error, stack) => _buildErrorScreen(theme, error),
      data: (projects) {
        if (projects.isEmpty) {
          return _buildNoProjectsScreen(theme, colorScheme);
        }

        final allSummaries = allSummariesAsync.value ?? [];
        final filteredSummaries = _getFilteredSummaries(allSummaries);

        return Scaffold(
          backgroundColor: colorScheme.surface,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showGenerateSummaryDialog(context),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate'),
            backgroundColor: colorScheme.primary,
          ),
          body: Column(
            children: [
              // Fixed Header - Same as tasks tab
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.02),
                      colorScheme.secondary.withValues(alpha: 0.01),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 24 : 16,
                      vertical: isMobile ? 12 : 16,
                    ),
                    child: !isMobile
                        ? Center(
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Row(
                                children: [
                                  // Title Section
                                  Icon(
                                    Icons.summarize,
                                    color: colorScheme.primary,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Summaries',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'AI-generated insights',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 32),

                                  // Clean Statistics Section
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 24),
                                      child: Row(
                                        children: [
                                          _buildSimpleStatCard(
                                            value: filteredSummaries.length.toString(),
                                            label: 'Total summaries',
                                            theme: theme,
                                          ),
                                          Container(
                                            height: 30,
                                            width: 1,
                                            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                          ),
                                          _buildSimpleStatCard(
                                            value: filteredSummaries
                                                .where((s) => s.summaryType == SummaryType.meeting)
                                                .length.toString(),
                                            label: 'Meetings',
                                            theme: theme,
                                          ),
                                          Container(
                                            height: 30,
                                            width: 1,
                                            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                          ),
                                          _buildSimpleStatCard(
                                            value: filteredSummaries
                                                .where((s) => s.summaryType == SummaryType.project)
                                                .length.toString(),
                                            label: 'Reports',
                                            theme: theme,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              Icon(
                                Icons.summarize,
                                color: colorScheme.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Summaries',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    'AI insights',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              // Compact stats inline
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.summarize, size: 14, color: Colors.purple),
                                    const SizedBox(width: 4),
                                    Text(filteredSummaries.length.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Icon(Icons.groups, size: 14, color: Colors.blue),
                                    const SizedBox(width: 4),
                                    Text(filteredSummaries.where((s) => s.summaryType == SummaryType.meeting).length.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Icon(Icons.description, size: 14, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text(filteredSummaries.where((s) => s.summaryType == SummaryType.project).length.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              // Filter and View Controls
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 16,
                ),
                color: colorScheme.surface,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: LayoutConstants.spacingMd,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Search and Controls Row
                          Row(
                            children: [
                              // Search Field
                              Expanded(
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _searchQuery.isNotEmpty
                                          ? colorScheme.primary.withValues(alpha: 0.3)
                                          : colorScheme.outline.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value;
                                      });
                                    },
                                    style: theme.textTheme.bodyMedium,
                                    decoration: InputDecoration(
                                      hintText: 'Search summaries...',
                                      hintStyle: TextStyle(
                                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: colorScheme.onSurfaceVariant,
                                        size: 20,
                                      ),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(Icons.clear,
                                                size: 18,
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() {
                                                  _searchQuery = '';
                                                });
                                              },
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                      filled: false,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Filter Button
                              PopupMenuButton<String?>(
                                tooltip: 'Select Project',
                                constraints: const BoxConstraints(
                                  minWidth: 200,
                                  maxWidth: 300,
                                ),
                                position: PopupMenuPosition.under,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                offset: const Offset(0, 8),
                                elevation: 8,
                                shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
                                surfaceTintColor: colorScheme.surface,
                                color: colorScheme.surface,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !_isAllProjectsSelected
                                        ? colorScheme.primary.withValues(alpha: 0.1)
                                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: !_isAllProjectsSelected
                                          ? colorScheme.primary.withValues(alpha: 0.3)
                                          : colorScheme.outline.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.folder_outlined,
                                        size: 18,
                                        color: !_isAllProjectsSelected
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 6),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 150),
                                        child: Text(
                                          !_isAllProjectsSelected
                                              ? projects.firstWhere((p) => p.id == _filterProjectId, orElse: () => projects.first).name
                                              : 'All Projects',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: !_isAllProjectsSelected
                                                ? colorScheme.primary
                                                : colorScheme.onSurfaceVariant,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        size: 18,
                                        color: !_isAllProjectsSelected
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                ),
                                onSelected: (value) {
                                  setState(() {
                                    _filterProjectId = (value == null || value.isEmpty) ? null : value;
                                  });
                                },
                                itemBuilder: (context) => [
                                    PopupMenuItem<String?>(
                                      value: '',
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.folder_open,
                                            size: 18,
                                            color: _isAllProjectsSelected
                                                ? colorScheme.primary
                                                : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'All Projects',
                                            style: TextStyle(
                                              fontWeight: _isAllProjectsSelected ? FontWeight.w600 : FontWeight.normal,
                                              color: _isAllProjectsSelected
                                                  ? colorScheme.primary
                                                  : colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(height: 1),
                                    ...projects.map<PopupMenuItem<String?>>((project) {
                                      final isSelected = _filterProjectId == project.id;
                                      return PopupMenuItem<String?>(
                                        value: project.id,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.folder,
                                              size: 18,
                                              color: isSelected
                                                  ? colorScheme.primary
                                                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                project.name,
                                                style: TextStyle(
                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                  color: isSelected
                                                      ? colorScheme.primary
                                                      : colorScheme.onSurface,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isSelected) ...[
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.check,
                                                size: 16,
                                                color: colorScheme.primary,
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    }),
                                ],
                              ),
                              const SizedBox(width: 8),

                              // View Mode Toggle
                              Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.outline.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.all(2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildViewModeButton(
                                      icon: Icons.view_list,
                                      mode: SummaryViewMode.list,
                                      currentMode: _viewMode,
                                      tooltip: 'List',
                                      onTap: () => setState(() => _viewMode = SummaryViewMode.list),
                                    ),
                                    _buildViewModeButton(
                                      icon: Icons.view_compact,
                                      mode: SummaryViewMode.compact,
                                      currentMode: _viewMode,
                                      tooltip: 'Compact',
                                      onTap: () => setState(() => _viewMode = SummaryViewMode.compact),
                                    ),
                                    _buildViewModeButton(
                                      icon: Icons.grid_view,
                                      mode: SummaryViewMode.grid,
                                      currentMode: _viewMode,
                                      tooltip: 'Grid',
                                      onTap: () => setState(() => _viewMode = SummaryViewMode.grid),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Type Filter Chips
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              FilterChip(
                                label: const Text('All', style: TextStyle(fontSize: 13)),
                                selected: _filterType == null,
                                onSelected: (selected) {
                                  setState(() => _filterType = null);
                                },
                                selectedColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
                                checkmarkColor: colorScheme.primary,
                                side: BorderSide(
                                  color: _filterType == null
                                      ? colorScheme.primary.withValues(alpha: 0.5)
                                      : colorScheme.outline.withValues(alpha: 0.3),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('Meetings', style: TextStyle(fontSize: 13)),
                                selected: _filterType == SummaryType.meeting,
                                onSelected: (selected) {
                                  setState(() => _filterType = selected ? SummaryType.meeting : null);
                                },
                                selectedColor: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                                checkmarkColor: colorScheme.secondary,
                                side: BorderSide(
                                  color: _filterType == SummaryType.meeting
                                      ? colorScheme.secondary.withValues(alpha: 0.5)
                                      : colorScheme.outline.withValues(alpha: 0.3),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('Reports', style: TextStyle(fontSize: 13)),
                                selected: _filterType == SummaryType.project,
                                onSelected: (selected) {
                                  setState(() => _filterType = selected ? SummaryType.project : null);
                                },
                                selectedColor: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                                checkmarkColor: colorScheme.tertiary,
                                side: BorderSide(
                                  color: _filterType == SummaryType.project
                                      ? colorScheme.tertiary.withValues(alpha: 0.5)
                                      : colorScheme.outline.withValues(alpha: 0.3),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Spacer(),
                              Text(
                                '${filteredSummaries.length} result${filteredSummaries.length != 1 ? 's' : ''}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Scrollable Content
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 16,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: allSummariesAsync.isLoading
                          ? _buildLoadingContent(theme, colorScheme)
                          : allSummariesAsync.hasError
                              ? _buildErrorContent(theme, colorScheme, allSummariesAsync.error.toString())
                              : filteredSummaries.isEmpty
                                  ? _buildEmptyContent(theme, colorScheme, _searchQuery.isNotEmpty)
                                  : _viewMode == SummaryViewMode.list
                                      ? _buildListViewContent(filteredSummaries, isDesktop, theme, colorScheme)
                                      : _viewMode == SummaryViewMode.compact
                                          ? _buildCompactViewContent(filteredSummaries, isDesktop, theme, colorScheme)
                                          : _buildGridViewContent(filteredSummaries, isDesktop, isTablet, theme, colorScheme),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleStatCard({
    required String value,
    required String label,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              fontSize: 24,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required SummaryViewMode mode,
    required SummaryViewMode currentMode,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isSelected = mode == currentMode;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildGridViewContent(
    List<SummaryModel> summaries,
    bool isDesktop,
    bool isTablet,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return GridView.builder(
      padding: EdgeInsets.only(
        top: LayoutConstants.spacingSm,
        bottom: LayoutConstants.spacingMd,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: LayoutConstants.spacingSm,
        mainAxisSpacing: LayoutConstants.spacingSm,
        childAspectRatio: 1.3,
      ),
      itemCount: summaries.length,
      itemBuilder: (context, index) {
        final summary = summaries[index];
        return _buildSummaryCard(summary, theme, colorScheme);
      },
    );
  }

  Widget _buildCompactViewContent(
    List<SummaryModel> summaries,
    bool isDesktop,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      padding: EdgeInsets.only(
        top: LayoutConstants.spacingSm,
        bottom: LayoutConstants.spacingMd,
      ),
      itemCount: summaries.length,
      itemBuilder: (context, index) {
        final summary = summaries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _buildSummaryCompactTile(summary, theme, colorScheme),
        );
      },
    );
  }

  Widget _buildListViewContent(
    List<SummaryModel> summaries,
    bool isDesktop,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      padding: EdgeInsets.only(
        top: LayoutConstants.spacingSm,
        bottom: LayoutConstants.spacingMd,
      ),
      itemCount: summaries.length,
      itemBuilder: (context, index) {
        final summary = summaries[index];
        return Padding(
          padding: EdgeInsets.only(bottom: LayoutConstants.spacingXs),
          child: _buildSummaryListTile(summary, theme, colorScheme),
        );
      },
    );
  }

  Widget _buildSummaryCompactTile(SummaryModel summary, ThemeData theme, ColorScheme colorScheme) {
    final typeColor = summary.summaryType == SummaryType.meeting
        ? colorScheme.secondary
        : colorScheme.tertiary;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => context.push('/summaries/${summary.id}'),
        child: Container(
          padding: const EdgeInsets.only(left: 12, top: 10, bottom: 10, right: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Type indicator icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  summary.summaryType == SummaryType.meeting
                      ? Icons.meeting_room
                      : Icons.calendar_view_week,
                  size: 18,
                  color: typeColor,
                ),
              ),
              const SizedBox(width: 12),

              // Content - flexible to take available space
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      summary.subject,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Metadata row
                    Row(
                      children: [
                        // Type label
                        Text(
                          summary.summaryType == SummaryType.meeting ? 'Meeting' : 'Report',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: typeColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.circle,
                          size: 4,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 8),
                        // Date
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 11,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  DateFormat('MMM dd, yyyy • h:mm a').format(summary.createdAt),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Format badge - centered vertically, shrinks if needed
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  summary.format.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),

              // More actions menu
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onSelected: (value) {
                  if (value == 'export') {
                    _exportSummary(summary);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'export', child: Text('Export PDF')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(SummaryModel summary, ThemeData theme, ColorScheme colorScheme) {
    final typeColor = summary.summaryType == SummaryType.meeting
        ? colorScheme.secondary
        : colorScheme.tertiary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/summaries/${summary.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      summary.summaryType == SummaryType.meeting
                          ? Icons.meeting_room
                          : Icons.calendar_view_week,
                      size: 20,
                      color: typeColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.summaryType == SummaryType.meeting ? 'Meeting' : 'Report',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy').format(summary.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (value) {
                      if (value == 'export') {
                        _exportSummary(summary);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'export', child: Text('Export PDF')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                summary.subject,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Content Preview
              Text(
                  summary.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              const Spacer(),
              // Footer
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      summary.format.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('h:mm a').format(summary.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

  Widget _buildSummaryListTile(SummaryModel summary, ThemeData theme, ColorScheme colorScheme) {
    final typeColor = summary.summaryType == SummaryType.meeting
        ? colorScheme.secondary
        : colorScheme.tertiary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/summaries/${summary.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  summary.summaryType == SummaryType.meeting
                      ? Icons.meeting_room
                      : Icons.calendar_view_week,
                  size: 24,
                  color: typeColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.subject,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        summary.body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, yyyy • h:mm a').format(summary.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            summary.format.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) {
                  if (value == 'export') {
                    _exportSummary(summary);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'export', child: Text('Export PDF')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingContent(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading summaries...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(ThemeData theme, ColorScheme colorScheme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Unable to load summaries',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _refreshSummaries,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContent(ThemeData theme, ColorScheme colorScheme, bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.1),
                  colorScheme.secondary.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearching ? Icons.search_off : Icons.article_outlined,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isSearching ? 'No results found' : 'No summaries yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(
              isSearching
                  ? 'Try adjusting your search or filters'
                  : 'Create your first summary to get insights from your meetings and projects',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (!isSearching) ...[
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showGenerateSummaryDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Generate Summary'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingScreen(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(title: const Text('Summaries')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorScreen(ThemeData theme, Object error) {
    return Scaffold(
      appBar: AppBar(title: const Text('Summaries')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => ref.refresh(projectsListProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoProjectsScreen(ThemeData theme, ColorScheme colorScheme) {
    return Scaffold(
      appBar: AppBar(title: const Text('Summaries')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_off,
              size: 80,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text('No Projects Yet', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Create your first project to start generating summaries'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/hierarchy'),
              icon: const Icon(Icons.add),
              label: const Text('Create Project'),
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
              ref.invalidate(allSummariesProvider);
              _refreshSummaries();
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
          // TODO: Implement upload content dialog
        },
      ),
    );
  }

  void _exportSummary(SummaryModel summary) {
    showDialog(
      context: context,
      builder: (context) => SummaryExportDialog(summary: summary),
    );
  }

}

