import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/breakpoints.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../projects/domain/entities/lesson_learned.dart';
import '../providers/aggregated_lessons_learned_provider.dart';
import '../providers/lessons_learned_filter_provider.dart';
import '../widgets/lesson_learned_list_tile.dart';
import '../widgets/lesson_learned_list_tile_compact.dart';
import '../widgets/lessons_filter_dialog.dart';
import '../widgets/lesson_learned_detail_dialog.dart';
import '../widgets/lesson_group_dialog.dart';
import '../widgets/lesson_grouping_view.dart';
import '../../../projects/presentation/widgets/lesson_learned_dialog.dart';
import '../../../projects/presentation/providers/projects_provider.dart';

class LessonsLearnedScreenV2 extends ConsumerStatefulWidget {
  final String? projectId;
  final String? fromRoute;

  const LessonsLearnedScreenV2({
    super.key,
    this.projectId,
    this.fromRoute,
  });

  @override
  ConsumerState<LessonsLearnedScreenV2> createState() => _LessonsLearnedScreenV2State();
}

class _LessonsLearnedScreenV2State extends ConsumerState<LessonsLearnedScreenV2>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isRefreshing = false;
  bool _hasInitiallyLoaded = false;
  List<AggregatedLessonLearned>? _cachedLessons;

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

    _tabController = TabController(
      length: 7, // All, Technical, Process, Communication, Planning, Quality, Other
      vsync: this,
    );
    _tabController.addListener(() {
      setState(() {}); // Update UI when tab changes
    });

    // Initialize project filter if coming from a project
    if (widget.projectId != null) {
      // Set filter immediately (synchronously) for first render
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(lessonsLearnedFilterProvider.notifier).clearAllFilters();
        ref.read(lessonsLearnedFilterProvider.notifier).toggleProject(widget.projectId!);
      });

      // Also set immediately as backup using microtask
      Future.microtask(() {
        if (mounted) {
          ref.read(lessonsLearnedFilterProvider.notifier).clearAllFilters();
          ref.read(lessonsLearnedFilterProvider.notifier).toggleProject(widget.projectId!);
        }
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _animationController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => const LessonsFilterDialog(),
    );
  }

  void _showGroupDialog() {
    final currentGrouping = ref.read(lessonGroupingModeProvider);
    showDialog(
      context: context,
      builder: (context) => LessonGroupDialog(
        currentGrouping: currentGrouping,
        onGroupingChanged: (grouping) {
          ref.read(lessonGroupingModeProvider.notifier).setGroupingMode(grouping);
        },
      ),
    );
  }

  Future<void> _handleRefresh() async {
    developer.log('🔄 [LessonsScreen] Starting refresh', name: 'LessonsRefresh');

    setState(() {
      _isRefreshing = true;
    });
    developer.log('🔄 [LessonsScreen] Set _isRefreshing = true', name: 'LessonsRefresh');

    try {
      developer.log('🔄 [LessonsScreen] Calling lessonsRefreshProvider', name: 'LessonsRefresh');
      ref.read(lessonsRefreshProvider)();

      developer.log('🔄 [LessonsScreen] Waiting for aggregatedLessonsLearnedProvider.future', name: 'LessonsRefresh');
      await ref.read(aggregatedLessonsLearnedProvider.future);

      developer.log('✅ [LessonsScreen] Refresh completed successfully', name: 'LessonsRefresh');
    } catch (e) {
      developer.log('❌ [LessonsScreen] Refresh failed: $e', name: 'LessonsRefresh');
      // Handle refresh error silently - we'll show the error via SnackBar
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        developer.log('🔄 [LessonsScreen] Set _isRefreshing = false', name: 'LessonsRefresh');
      }
    }
  }

  void _showCreateLessonDialog() {
    showDialog(
      context: context,
      builder: (context) => const LessonLearnedDialog(),
    );
  }

  Widget _buildSimpleStatCard({
    required String value,
    required String label,
    required ThemeData theme,
    Color? valueColor,
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
              color: valueColor ?? theme.colorScheme.onSurface,
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

  Widget _buildMobileStatBadge({
    required String label,
    required String value,
    required Color? color,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color ?? theme.colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label.toLowerCase(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }


  Widget _buildCategoryTab({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    Color? color,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (color != null && count > 0)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '($count)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final lessonsAsync = ref.watch(aggregatedLessonsLearnedProvider);
    // Cache successful data and mark as initially loaded
    lessonsAsync.whenData((data) {
      developer.log('💾 [LessonsScreen] Caching ${data.length} lessons', name: 'LessonsCache');
      _cachedLessons = data;
      if (!_hasInitiallyLoaded) {
        _hasInitiallyLoaded = true;
        developer.log('🎯 [LessonsScreen] Initial load completed', name: 'LessonsCache');
      }
    });

    developer.log('🏗️ [LessonsScreen] Building with state: async=${lessonsAsync.runtimeType}, cached=${_cachedLessons?.length ?? 0}, refreshing=$_isRefreshing', name: 'LessonsBuild');

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateLessonDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Lesson'),
        backgroundColor: colorScheme.primary,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _buildContent(lessonsAsync, theme, colorScheme),
      ),
    );
  }

  Widget _buildContent(AsyncValue<List<AggregatedLessonLearned>> lessonsAsync, ThemeData theme, ColorScheme colorScheme) {
    return lessonsAsync.when(
      loading: () {
        developer.log('⏳ [LessonsScreen] In loading state - cached: ${_cachedLessons?.length ?? 0}, refreshing: $_isRefreshing', name: 'LessonsState');

        // If we have cached data and are refreshing, show cached data with loading indicator
        if (_cachedLessons != null && _isRefreshing) {
          developer.log('📱 [LessonsScreen] Showing cached data with loading indicator', name: 'LessonsState');
          return Stack(
            children: [
              _buildMainContent(),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ],
          );
        }
        developer.log('🔄 [LessonsScreen] Showing full loading spinner', name: 'LessonsState');
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, stack) {
        developer.log('❌ [LessonsScreen] In error state - error: $error, cached: ${_cachedLessons?.length ?? 0}, refreshing: $_isRefreshing, initiallyLoaded: $_hasInitiallyLoaded', name: 'LessonsState');

        // Always show cached data if available, regardless of error
        if (_cachedLessons != null) {
          developer.log('📱 [LessonsScreen] Showing cached data despite error', name: 'LessonsState');

          // Show error snackbar for non-initial loads (only after initial load has completed)
          if (!_isRefreshing && _hasInitiallyLoaded) {
            developer.log('🍞 [LessonsScreen] Showing error snackbar', name: 'LessonsState');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Failed to refresh lessons'),
                    backgroundColor: Colors.orange,
                    action: SnackBarAction(
                      label: 'Retry',
                      onPressed: _handleRefresh,
                    ),
                  ),
                );
              }
            });
          }
          return _buildMainContent();
        }

        // For browser refresh scenarios: Show loading instead of error on first load attempts
        if (!_hasInitiallyLoaded) {
          developer.log('🌐 [LessonsScreen] Browser refresh detected - showing loading instead of error', name: 'LessonsState');
          return const Center(child: CircularProgressIndicator());
        }

        developer.log('💥 [LessonsScreen] Showing full error screen', name: 'LessonsState');
        // Only show full error screen after initial load attempts have truly failed
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to load lessons', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _handleRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        );
      },
      data: (data) {
        developer.log('✅ [LessonsScreen] In data state with ${data.length} lessons', name: 'LessonsState');
        return _buildMainContent();
      },
    );
  }

  Widget _buildMainContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktop;
    final isTablet = screenWidth >= Breakpoints.tablet && screenWidth < Breakpoints.desktop;
    final isMobile = screenWidth < Breakpoints.tablet;

    final filteredLessons = ref.watch(filteredLessonsLearnedProvider);
    final filter = ref.watch(lessonsLearnedFilterProvider);
    final loadErrors = ref.watch(lessonLoadErrorsProvider);

    // Calculate statistics
    final statistics = {
      'total': filteredLessons.length,
      'highImpact': filteredLessons.where((l) => l.lesson.impact == LessonImpact.high).length,
      'bestPractices': filteredLessons.where((l) => l.lesson.lessonType == LessonType.bestPractice).length,
      'successes': filteredLessons.where((l) => l.lesson.lessonType == LessonType.success).length,
      'challenges': filteredLessons.where((l) => l.lesson.lessonType == LessonType.challenge).length,
    };

    // Group lessons by category for tabs
    final allLessons = filteredLessons;
    final technicalLessons = filteredLessons.where((l) => l.lesson.category == LessonCategory.technical).toList();
    final processLessons = filteredLessons.where((l) => l.lesson.category == LessonCategory.process).toList();
    final communicationLessons = filteredLessons.where((l) => l.lesson.category == LessonCategory.communication).toList();
    final planningLessons = filteredLessons.where((l) => l.lesson.category == LessonCategory.planning).toList();
    final qualityLessons = filteredLessons.where((l) => l.lesson.category == LessonCategory.quality).toList();
    final otherLessons = filteredLessons.where((l) => l.lesson.category == LessonCategory.other).toList();

    // Show errors if any projects failed to load
    if (loadErrors.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to load lessons from ${loadErrors.length} project(s)',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    }

    return Column(
              children: [
                // Fixed App Bar
                Container(
                  decoration: BoxDecoration(
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
                                        // Back button if coming from project
                                        if (widget.fromRoute == 'project') ...[
                                          IconButton(
                                            icon: const Icon(Icons.arrow_back),
                                            onPressed: () => context.pop(),
                                            tooltip: 'Back to Project',
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        // Title Section
                                        Icon(
                                          Icons.lightbulb,
                                          color: colorScheme.primary,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  'Lessons Learned',
                                                  style: theme.textTheme.headlineSmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (filter.hasActiveFilters) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: colorScheme.primary.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Text(
                                                      '${filter.activeFilterCount} filters',
                                                      style: theme.textTheme.labelSmall?.copyWith(
                                                        color: colorScheme.primary,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            Text(
                                              'Knowledge from all projects',
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
                                                  value: statistics['total'].toString(),
                                                  label: 'Total lessons',
                                                  theme: theme,
                                                ),
                                                Container(
                                                  height: 30,
                                                  width: 1,
                                                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                                ),
                                                _buildSimpleStatCard(
                                                  value: statistics['highImpact'].toString(),
                                                  label: 'High impact',
                                                  theme: theme,
                                                  valueColor: Colors.red,
                                                ),
                                                Container(
                                                  height: 30,
                                                  width: 1,
                                                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                                ),
                                                _buildSimpleStatCard(
                                                  value: statistics['bestPractices'].toString(),
                                                  label: 'Best practices',
                                                  theme: theme,
                                                  valueColor: Colors.amber,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                      ],
                                    ),
                                  ),
                                )
                              : Row(
                                  children: [
                                    // Back button if coming from project
                                    if (widget.fromRoute == 'project') ...[
                                      IconButton(
                                        icon: const Icon(Icons.arrow_back, size: 20),
                                        onPressed: () => context.pop(),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Back to Project',
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Icon(
                                      Icons.lightbulb,
                                      color: colorScheme.primary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Lessons',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        Text(
                                          'All projects',
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
                                          Icon(Icons.lightbulb, size: 14, color: Colors.amber),
                                          const SizedBox(width: 4),
                                          Text(statistics['total'].toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 8),
                                          Icon(Icons.priority_high, size: 14, color: Colors.red),
                                          const SizedBox(width: 4),
                                          Text(statistics['highImpact'].toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 8),
                                          Icon(Icons.verified, size: 14, color: Colors.green),
                                          const SizedBox(width: 4),
                                          Text(statistics['bestPractices'].toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                                    child: ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: _searchController,
                                      builder: (context, value, child) {
                                        return TextField(
                                          controller: _searchController,
                                          onChanged: (value) {
                                            _debounceTimer?.cancel();
                                            _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                                              if (mounted) {
                                                ref.read(lessonsLearnedFilterProvider.notifier).updateSearchQuery(value);
                                              }
                                            });
                                          },
                                          style: theme.textTheme.bodyMedium,
                                          decoration: InputDecoration(
                                            hintText: 'Search lessons...',
                                            hintStyle: TextStyle(
                                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                            ),
                                            prefixIcon: Icon(
                                              Icons.search,
                                              color: colorScheme.onSurfaceVariant,
                                              size: 20,
                                            ),
                                            suffixIcon: value.text.isNotEmpty
                                                ? IconButton(
                                                    icon: Icon(Icons.clear,
                                                      size: 18,
                                                      color: colorScheme.onSurfaceVariant,
                                                    ),
                                                    onPressed: () {
                                                      _searchController.clear();
                                                      _debounceTimer?.cancel();
                                                      ref.read(lessonsLearnedFilterProvider.notifier).updateSearchQuery('');
                                                    },
                                                  )
                                                : null,
                                            filled: true,
                                            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: colorScheme.outline.withValues(alpha: 0.2),
                                                width: 1,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: colorScheme.outline.withValues(alpha: 0.2),
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: colorScheme.primary.withValues(alpha: 0.5),
                                                width: 2,
                                              ),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Compact View Toggle
                                  IconButton(
                                    onPressed: () {
                                      ref.read(lessonCompactViewProvider.notifier).toggle();
                                    },
                                    icon: Icon(
                                      ref.watch(lessonCompactViewProvider)
                                          ? Icons.view_agenda
                                          : Icons.view_stream,
                                      color: colorScheme.onSurfaceVariant,
                                      size: 22,
                                    ),
                                    tooltip: ref.watch(lessonCompactViewProvider)
                                        ? 'Regular View'
                                        : 'Compact View',
                                    style: IconButton.styleFrom(
                                      backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Group Button
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final groupingMode = ref.watch(lessonGroupingModeProvider);
                                      return IconButton(
                                        onPressed: _showGroupDialog,
                                        icon: Badge(
                                          isLabelVisible: groupingMode != LessonGroupingMode.none,
                                          child: Icon(
                                            Icons.group_work_outlined,
                                            color: groupingMode != LessonGroupingMode.none
                                                ? colorScheme.primary
                                                : colorScheme.onSurfaceVariant,
                                            size: 22,
                                          ),
                                        ),
                                        tooltip: 'Group Lessons',
                                        style: IconButton.styleFrom(
                                          backgroundColor: groupingMode != LessonGroupingMode.none
                                              ? colorScheme.primary.withValues(alpha: 0.1)
                                              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),

                                  // Filter Button
                                  IconButton(
                                    onPressed: _showFilterDialog,
                                    icon: Badge(
                                      isLabelVisible: filter.hasActiveFilters,
                                      label: Text(filter.activeFilterCount.toString()),
                                      child: Icon(
                                        Icons.filter_list,
                                        color: filter.hasActiveFilters
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant,
                                        size: 22,
                                      ),
                                    ),
                                    tooltip: 'Filters',
                                    style: IconButton.styleFrom(
                                      backgroundColor: filter.hasActiveFilters
                                          ? colorScheme.primary.withValues(alpha: 0.1)
                                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ],
                              ),

                              // Category Filter Tabs
                              ...[
                                const SizedBox(height: 12),
                                Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.all(3),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Row(
                                        children: [
                                          _buildCategoryTab(
                                            label: 'All',
                                            count: allLessons.length,
                                            isSelected: _tabController.index == 0,
                                            onTap: () => _tabController.animateTo(0),
                                            colorScheme: colorScheme,
                                          ),
                                          if (!isMobile || _tabController.index == 1)
                                            _buildCategoryTab(
                                              label: 'Technical',
                                              count: technicalLessons.length,
                                              isSelected: _tabController.index == 1,
                                              onTap: () => _tabController.animateTo(1),
                                              colorScheme: colorScheme,
                                            ),
                                          if (!isMobile || _tabController.index == 2)
                                            _buildCategoryTab(
                                              label: 'Process',
                                              count: processLessons.length,
                                              isSelected: _tabController.index == 2,
                                              onTap: () => _tabController.animateTo(2),
                                              colorScheme: colorScheme,
                                            ),
                                          if (!isMobile || _tabController.index == 3)
                                            _buildCategoryTab(
                                              label: 'Communication',
                                              count: communicationLessons.length,
                                              isSelected: _tabController.index == 3,
                                              onTap: () => _tabController.animateTo(3),
                                              colorScheme: colorScheme,
                                            ),
                                          if (!isMobile || _tabController.index == 4)
                                            _buildCategoryTab(
                                              label: 'Planning',
                                              count: planningLessons.length,
                                              isSelected: _tabController.index == 4,
                                              onTap: () => _tabController.animateTo(4),
                                              colorScheme: colorScheme,
                                            ),
                                          if (!isMobile || _tabController.index == 5)
                                            _buildCategoryTab(
                                              label: 'Quality',
                                              count: qualityLessons.length,
                                              isSelected: _tabController.index == 5,
                                              onTap: () => _tabController.animateTo(5),
                                              colorScheme: colorScheme,
                                            ),
                                          if (!isMobile || _tabController.index == 6)
                                            _buildCategoryTab(
                                              label: 'Other',
                                              count: otherLessons.length,
                                              isSelected: _tabController.index == 6,
                                              onTap: () => _tabController.animateTo(6),
                                              colorScheme: colorScheme,
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],

                              // Quick Filters
                              if (filter.hasActiveFilters) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 32,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      if (filter.showOnlyAiGenerated)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: FilterChip(
                                            label: const Text('AI Generated', style: TextStyle(fontSize: 12)),
                                            selected: true,
                                            onSelected: (_) {
                                              ref.read(lessonsLearnedFilterProvider.notifier).toggleAiGenerated();
                                            },
                                            selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                                            checkmarkColor: colorScheme.primary,
                                            labelStyle: TextStyle(color: colorScheme.primary),
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                      ActionChip(
                                        label: const Text('Clear filters', style: TextStyle(fontSize: 12)),
                                        onPressed: () {
                                          ref.read(lessonsLearnedFilterProvider.notifier).clearAllFilters();
                                          _searchController.clear();
                                        },
                                        avatar: Icon(Icons.clear, size: 14, color: colorScheme.onSurfaceVariant),
                                        backgroundColor: colorScheme.surface,
                                        side: BorderSide(
                                          color: colorScheme.outline.withValues(alpha: 0.3),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                        child: TabBarView(
                          controller: _tabController,
                          physics: const NeverScrollableScrollPhysics(), // Disable swiping
                          children: [
                            _buildLessonsView(allLessons, theme, isDesktop, isTablet),
                            _buildLessonsView(technicalLessons, theme, isDesktop, isTablet),
                            _buildLessonsView(processLessons, theme, isDesktop, isTablet),
                            _buildLessonsView(communicationLessons, theme, isDesktop, isTablet),
                            _buildLessonsView(planningLessons, theme, isDesktop, isTablet),
                            _buildLessonsView(qualityLessons, theme, isDesktop, isTablet),
                            _buildLessonsView(otherLessons, theme, isDesktop, isTablet),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
  }

  Widget _buildLessonsView(
    List<AggregatedLessonLearned> lessons,
    ThemeData theme,
    bool isDesktop,
    bool isTablet,
  ) {
    if (lessons.isEmpty) {
      // Check if there are any projects
      final projectsAsync = ref.watch(projectsListProvider);
      final hasProjects = projectsAsync.whenOrNull(
        data: (projects) => projects.isNotEmpty,
      ) ?? false;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No lessons found',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasProjects
                  ? 'Upload meeting transcripts or emails to generate lessons learned'
                  : 'Create your first project and upload content to start tracking lessons',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.go('/hierarchy');
              },
              icon: const Icon(Icons.folder),
              label: Text(hasProjects ? 'Go to Projects' : 'Create First Project'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    final isCompact = ref.watch(lessonCompactViewProvider);
    final groupingMode = ref.watch(lessonGroupingModeProvider);

    // Apply grouping if enabled
    if (groupingMode == LessonGroupingMode.none) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: lessons.length,
        itemBuilder: (context, index) {
          final item = lessons[index];
          return Padding(
            padding: EdgeInsets.only(bottom: isCompact ? 2 : 4),
            child: isCompact
                ? LessonLearnedListTileCompact(
                    lesson: item.lesson,
                    project: item.project,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => LessonLearnedDetailDialog(
                          lesson: item.lesson,
                          project: item.project,
                        ),
                      );
                    },
                  )
                : LessonLearnedListTile(
                    lesson: item.lesson,
                    project: item.project,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => LessonLearnedDetailDialog(
                          lesson: item.lesson,
                          project: item.project,
                        ),
                      );
                    },
                  ),
          );
        },
      );
    }

    // Grouped view
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: LessonGroupingView(
        lessons: lessons,
        groupingMode: groupingMode,
        isCompact: isCompact,
      ),
    );
  }
}