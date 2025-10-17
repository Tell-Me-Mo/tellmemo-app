import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animated_tree_view/animated_tree_view.dart';
import '../../../../core/utils/datetime_utils.dart';
import '../providers/hierarchy_providers.dart';
import '../providers/favorites_provider.dart';
import '../../domain/entities/hierarchy_item.dart';
import '../widgets/create_portfolio_dialog.dart';
import '../widgets/create_program_dialog.dart';
import '../widgets/create_project_from_hierarchy_dialog.dart';
import '../widgets/edit_portfolio_dialog.dart';
import '../widgets/edit_program_dialog.dart';
import '../widgets/edit_project_from_hierarchy_dialog.dart';
import '../widgets/move_program_dialog.dart';
import '../widgets/move_project_dialog.dart';
import '../widgets/enhanced_delete_dialog.dart';
import '../../../queries/presentation/widgets/ask_ai_panel.dart';

class HierarchyScreen extends ConsumerStatefulWidget {
  const HierarchyScreen({super.key});

  @override
  ConsumerState<HierarchyScreen> createState() => _HierarchyScreenState();
}

class _HierarchyScreenState extends ConsumerState<HierarchyScreen> {
  final bool _includeArchived = false;
  String _searchQuery = '';
  HierarchyItemType? _typeFilter;
  HierarchyViewMode _viewMode = HierarchyViewMode.tree;
  bool _showFavoritesOnly = false;
  bool _isActionMenuOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = Uri.parse(GoRouterState.of(context).uri.toString());
      if (uri.queryParameters['action'] == 'create_project') {
        _showCreateProjectDialog();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hierarchyAsync = ref.watch(hierarchyStateProvider(includeArchived: _includeArchived));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
          children: [
            // Fixed Header with Gradient Background - Reduced height for mobile
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
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 16,
                  vertical: isMobile ? 12 : 16,
                ),
                child: _buildHeader(context, isDesktop, isMobile),
              ),
            ),

            // Search and Filter Controls - Reduced padding for mobile
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 12 : 16,
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
                    child: _buildSearchSection(context),
                  ),
                ),
              ),
            ),

            // Main Content - Adjusted padding for mobile
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(hierarchyStateProvider(includeArchived: _includeArchived));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: isDesktop ? 24 : 16,
                      right: isDesktop ? 24 : 16,
                      top: isDesktop ? 24 : 12,
                      bottom: isMobile ? 100 : (isDesktop ? 24 : 20),
                    ),
                  child: hierarchyAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : double.infinity),
                        child: _buildErrorState(error.toString()),
                      ),
                    ),
                    data: (hierarchy) {
                      if (isDesktop) {
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1400),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Main Content Area
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Projects Section
                                      _buildProjectsSection(context, hierarchy),
                                    ],
                                  ),
                                ),

                                // Visual Separator
                                Container(
                                  width: 1,
                                  height: 600,
                                  margin: const EdgeInsets.symmetric(horizontal: 24),
                                  color: colorScheme.outline.withValues(alpha: 0.15),
                                ),

                                // Right Panel
                                SizedBox(
                                  width: 300,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Quick Actions
                                      _buildCompactQuickActions(context),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: isTablet ? 900 : double.infinity),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Projects Section
                                _buildProjectsSection(context, hierarchy),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  ),  // Padding
                ),    // SingleChildScrollView
              ),            // RefreshIndicator
            ),              // Expanded
            ],
          ),
        ),
        // Speed dial overlay for mobile
        if (_isActionMenuOpen && isMobile)
          _buildSpeedDialOverlay(context),
      ],
      ),
      floatingActionButton: hierarchyAsync.maybeWhen(
        data: (hierarchy) => _buildFloatingActionButtons(context, hierarchy, screenWidth),
        orElse: () => null,
      ),
    );
  }

  Widget? _buildFloatingActionButtons(BuildContext context, List<HierarchyItem> hierarchy, double screenWidth) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = screenWidth <= 768;

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

    // Desktop/Tablet: Show "Ask AI" FAB
    return SafeArea(
      child: FloatingActionButton.extended(
        onPressed: () => _showAskAIDialog(context),
        backgroundColor: colorScheme.primary,
        icon: const Icon(Icons.psychology_outlined),
        label: const Text('Ask AI'),
        elevation: 4,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop, bool isMobile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hierarchyAsync = ref.watch(hierarchyStateProvider(includeArchived: _includeArchived));

    // Calculate statistics for display
    int portfolioCount = 0;
    int programCount = 0;
    int projectCount = 0;

    hierarchyAsync.whenData((hierarchy) {
      void countItems(List<HierarchyItem> items) {
        for (final item in items) {
          switch (item.type) {
            case HierarchyItemType.portfolio:
              portfolioCount++;
              break;
            case HierarchyItemType.program:
              programCount++;
              break;
            case HierarchyItemType.project:
              projectCount++;
              break;
          }
          countItems(item.children);
        }
      }
      countItems(hierarchy);
    });

    if (!isMobile) {
      return Center(
        child: Row(
          children: [
            // Title Section
            Icon(
              Icons.folder_open,
              color: colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Projects',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Organize and manage hierarchy',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 32),

            // Statistics Section
            if (isDesktop) ...[
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _buildSimpleStatCard(
                        value: portfolioCount.toString(),
                        label: 'Portfolios',
                        theme: theme,
                        valueColor: Colors.purple,
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                      _buildSimpleStatCard(
                        value: programCount.toString(),
                        label: 'Programs',
                        theme: theme,
                        valueColor: Colors.blue,
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                      _buildSimpleStatCard(
                        value: projectCount.toString(),
                        label: 'Projects',
                        theme: theme,
                        valueColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ],
        ),
      );
    } else {
      // Mobile Layout - Compact design
      return Row(
        children: [
          Icon(
            Icons.folder_open,
            color: colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Projects',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                'Hierarchy',
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
                Icon(Icons.folder_special, size: 14, color: Colors.purple),
                const SizedBox(width: 4),
                Text(portfolioCount.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Icon(Icons.folder, size: 14, color: Colors.blue),
                const SizedBox(width: 4),
                Text(programCount.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Icon(Icons.work, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text(projectCount.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      );
    }
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

  Widget _buildTypeTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    Color? color,
    bool isMobile = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: isMobile ? 1 : 2),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
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
                if (color != null)
                  Container(
                    width: isMobile ? 5 : 6,
                    height: isMobile ? 5 : 6,
                    margin: EdgeInsets.only(right: isMobile ? 3 : 4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildSearchSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 768;

    return Column(
      children: [
        // Search and Controls Row - Compact for mobile
        Row(
          children: [
            // Search Field
            Expanded(
              child: SizedBox(
                height: isMobile ? 40 : null,
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: isMobile ? 14 : null,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search hierarchy...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: isMobile ? 14 : null,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: colorScheme.onSurfaceVariant,
                      size: isMobile ? 18 : 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                              size: isMobile ? 16 : 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                      borderSide: BorderSide(
                        color: colorScheme.primary.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 8 : 12,
                    ),
                    isDense: isMobile,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // View Mode Toggle
            SizedBox(
              width: isMobile ? 36 : null,
              height: isMobile ? 36 : null,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _viewMode = _viewMode == HierarchyViewMode.cards
                        ? HierarchyViewMode.tree
                        : HierarchyViewMode.cards;
                  });
                },
                icon: Icon(
                  _viewMode == HierarchyViewMode.cards
                      ? Icons.account_tree
                      : Icons.dashboard,
                  color: colorScheme.onSurfaceVariant,
                  size: isMobile ? 20 : 22,
                ),
                tooltip: _viewMode == HierarchyViewMode.cards
                    ? 'Tree View'
                    : 'Card View',
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Filter Button
            SizedBox(
              width: isMobile ? 36 : null,
              height: isMobile ? 36 : null,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _showFavoritesOnly = !_showFavoritesOnly;
                  });
                },
                icon: Badge(
                  isLabelVisible: _showFavoritesOnly,
                  child: Icon(
                    _showFavoritesOnly ? Icons.star : Icons.star_border,
                    color: _showFavoritesOnly
                        ? Colors.amber
                        : colorScheme.onSurfaceVariant,
                    size: isMobile ? 20 : 22,
                  ),
                ),
                tooltip: 'Favorites',
                style: IconButton.styleFrom(
                  backgroundColor: _showFavoritesOnly
                      ? Colors.amber.withValues(alpha: 0.1)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: isMobile ? 8 : 12),

        // Type Filter Tabs - Compact for mobile
        Container(
          height: isMobile ? 32 : 38,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          ),
          padding: EdgeInsets.all(isMobile ? 2 : 3),
          child: Row(
            children: [
              _buildTypeTab(
                label: 'All',
                isSelected: _typeFilter == null,
                onTap: () {
                  setState(() => _typeFilter = null);
                  ref.invalidate(hierarchyStateProvider(includeArchived: _includeArchived));
                },
                colorScheme: colorScheme,
                isMobile: isMobile,
              ),
              _buildTypeTab(
                label: 'Portfolios',
                isSelected: _typeFilter == HierarchyItemType.portfolio,
                onTap: () => setState(() =>
                  _typeFilter = _typeFilter == HierarchyItemType.portfolio ? null : HierarchyItemType.portfolio),
                colorScheme: colorScheme,
                color: Colors.purple,
                isMobile: isMobile,
              ),
              _buildTypeTab(
                label: 'Programs',
                isSelected: _typeFilter == HierarchyItemType.program,
                onTap: () => setState(() =>
                  _typeFilter = _typeFilter == HierarchyItemType.program ? null : HierarchyItemType.program),
                colorScheme: colorScheme,
                color: Colors.blue,
                isMobile: isMobile,
              ),
              _buildTypeTab(
                label: 'Projects',
                isSelected: _typeFilter == HierarchyItemType.project,
                onTap: () => setState(() =>
                  _typeFilter = _typeFilter == HierarchyItemType.project ? null : HierarchyItemType.project),
                colorScheme: colorScheme,
                color: Colors.green,
                isMobile: isMobile,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final actions = [
      {
        'icon': Icons.business_center,
        'label': 'New Portfolio',
        'color': Colors.purple,
        'onTap': () => _showCreatePortfolioDialog(),
      },
      {
        'icon': Icons.folder,
        'label': 'New Program',
        'color': Colors.blue,
        'onTap': () => _showCreateProgramDialog(null),
      },
      {
        'icon': Icons.work,
        'label': 'New Project',
        'color': Colors.green,
        'onTap': () => _showCreateProjectDialog(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'ACTIONS',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              fontSize: 10,
            ),
          ),
        ),
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
        )),
      ],
    );
  }


  Widget _buildProjectsSection(BuildContext context, List<HierarchyItem> hierarchy) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Apply filters
    final filteredHierarchy = _filterHierarchy(hierarchy);

    if (filteredHierarchy.isEmpty && hierarchy.isNotEmpty) {
      return _buildEmptyFilterState();
    }

    if (hierarchy.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _viewMode == HierarchyViewMode.tree ? 'Project Hierarchy' : 'All Projects',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${filteredHierarchy.length} items',
              style: textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_viewMode == HierarchyViewMode.cards)
          _buildCardsView(context, filteredHierarchy)
        else
          _buildTreeView(context, filteredHierarchy),
      ],
    );
  }

  Widget _buildCardsView(BuildContext context, List<HierarchyItem> items) {
    // If we're filtering by type or favorites, items are already flat
    final allItems = (_showFavoritesOnly || _typeFilter != null) ? items : _flattenHierarchy(items);

    return Column(
      children: allItems.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildHierarchyCard(context, item),
      )).toList(),
    );
  }

  Widget _buildHierarchyCard(BuildContext context, HierarchyItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    IconData iconData;
    Color iconColor;
    String typeLabel;

    switch (item.type) {
      case HierarchyItemType.portfolio:
        iconData = Icons.business_center;
        iconColor = Colors.purple;
        typeLabel = 'Portfolio';
        break;
      case HierarchyItemType.program:
        iconData = Icons.folder;
        iconColor = Colors.blue;
        typeLabel = 'Program';
        break;
      case HierarchyItemType.project:
        iconData = Icons.work;
        iconColor = Colors.green;
        typeLabel = 'Project';
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleItemTap(item.id, item.type.name),
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
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Type Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            typeLabel.toUpperCase(),
                            style: TextStyle(
                              color: iconColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description!,
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
                        if (item.children.isNotEmpty) ...[
                          Icon(
                            Icons.subdirectory_arrow_right,
                            size: 14,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.children.length} children',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateTimeUtils.formatTimeAgo(item.createdAt),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Favorite Button
              IconButton(
                icon: Icon(
                  ref.watch(isFavoriteProvider(item.id)) ? Icons.star : Icons.star_border,
                  color: ref.watch(isFavoriteProvider(item.id)) ? Colors.amber : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: () {
                  ref.read(favoritesProvider.notifier).toggleFavorite(item.id);
                },
                tooltip: ref.watch(isFavoriteProvider(item.id)) ? 'Remove from favorites' : 'Add to favorites',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              // Actions Menu
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: colorScheme.onSurfaceVariant),
                onSelected: (value) => _handleItemAction(context, value, item),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  if (item.type == HierarchyItemType.portfolio) ...[
                    const PopupMenuItem(
                      value: 'create_program',
                      child: Row(
                        children: [
                          Icon(Icons.folder, size: 18),
                          SizedBox(width: 8),
                          Text('Create Program'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'create_project',
                      child: Row(
                        children: [
                          Icon(Icons.work, size: 18),
                          SizedBox(width: 8),
                          Text('Create Project'),
                        ],
                      ),
                    ),
                  ] else if (item.type == HierarchyItemType.program) ...[
                    const PopupMenuItem(
                      value: 'add_child',
                      child: Row(
                        children: [
                          Icon(Icons.work, size: 18),
                          SizedBox(width: 8),
                          Text('Create Project'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'move',
                      child: Row(
                        children: [
                          Icon(Icons.drive_file_move, size: 18),
                          SizedBox(width: 8),
                          Text('Move'),
                        ],
                      ),
                    ),
                  ] else if (item.type == HierarchyItemType.project)
                    const PopupMenuItem(
                      value: 'move',
                      child: Row(
                        children: [
                          Icon(Icons.drive_file_move, size: 18),
                          SizedBox(width: 8),
                          Text('Move'),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
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

  Widget _buildTreeView(BuildContext context, List<HierarchyItem> items) {
    // Convert HierarchyItem to TreeNode structure
    final TreeNode root = TreeNode.root();

    for (final item in items) {
      _addItemToTree(root, item);
    }

    return TreeView.simple(
      tree: root,
      showRootNode: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      builder: (context, node) => _buildTreeNode(context, node),
      indentation: Indentation(
        style: IndentStyle.roundJoint,
        thickness: 1,
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        width: 40,
      ),
      expansionIndicatorBuilder: (context, node) {
        return NoExpansionIndicator(tree: node);
      },
      onTreeReady: (controller) {
        // Expand portfolios and programs by default, but keep projects collapsed
        _expandPortfoliosAndPrograms(controller, root);
        // Store controller for later use if needed
        _treeController = controller;
      },
    );
  }

  TreeViewController? _treeController;

  void _expandPortfoliosAndPrograms(TreeViewController controller, TreeNode root) {
    // Recursively expand only portfolios and programs, not projects
    void expandNode(TreeNode node) {
      if (node.data is HierarchyItem) {
        final item = node.data as HierarchyItem;
        // Expand portfolios and programs, but not projects
        if (item.type == HierarchyItemType.portfolio || item.type == HierarchyItemType.program) {
          controller.expandNode(node);
        }
      }

      // Recursively process children
      for (final child in node.children.values) {
        expandNode(child as TreeNode);
      }
    }

    // Start from root's children
    for (final child in root.children.values) {
      expandNode(child as TreeNode);
    }
  }

  void _addItemToTree(TreeNode parent, HierarchyItem item) {
    final node = TreeNode(key: item.id, data: item);
    parent.add(node);

    for (final child in item.children) {
      _addItemToTree(node, child);
    }
  }

  Widget _buildTreeNode(BuildContext context, TreeNode node) {
    if (!node.isRoot) {
      final item = node.data as HierarchyItem;
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final textTheme = theme.textTheme;
      final screenWidth = MediaQuery.of(context).size.width;
      final isMobile = screenWidth <= 768;

      IconData iconData;
      Color iconColor;
      String typeLabel;

      switch (item.type) {
        case HierarchyItemType.portfolio:
          iconData = Icons.business_center;
          iconColor = Colors.purple;
          typeLabel = 'PORTFOLIO';
          break;
        case HierarchyItemType.program:
          iconData = Icons.folder;
          iconColor = Colors.blue;
          typeLabel = 'PROGRAM';
          break;
        case HierarchyItemType.project:
          iconData = Icons.work;
          iconColor = Colors.green;
          typeLabel = 'PROJECT';
          break;
      }

      return Container(
        margin: EdgeInsets.only(
          bottom: 8,
          right: isMobile ? 4 : 8,
          left: isMobile ? 2 : 4,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleItemTap(item.id, item.type.name),
            borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 10 : 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        iconData,
                        color: iconColor,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: isMobile
                            ? textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              )
                            : textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: isMobile ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.description?.isNotEmpty == true && !isMobile) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.description!,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (node.children.isNotEmpty && isMobile) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${node.children.length} ${_getCountLabel(item.type)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Type Badge and Actions
                  Row(
                    children: [
                      // Desktop: Show count badge
                      if (node.children.isNotEmpty && !isMobile) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.folder_open, size: 14, color: colorScheme.onPrimaryContainer),
                              const SizedBox(width: 4),
                              Text(
                                '${node.children.length}',
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Type Badge - compact for mobile
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 6 : 8,
                          vertical: isMobile ? 3 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: isMobile ? 0.15 : 0.1),
                          borderRadius: BorderRadius.circular(isMobile ? 4 : 8),
                          border: isMobile ? Border.all(
                            color: iconColor.withValues(alpha: 0.3),
                            width: 1,
                          ) : null,
                        ),
                        child: Text(
                          typeLabel,
                          style: textTheme.labelSmall?.copyWith(
                            color: iconColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: isMobile ? 0.5 : 0,
                          ),
                        ),
                      ),

                      SizedBox(width: isMobile ? 6 : 8),

                      // Favorite Button - hide on mobile
                      if (!isMobile)
                        IconButton(
                          icon: Icon(
                            ref.watch(isFavoriteProvider(item.id)) ? Icons.star : Icons.star_border,
                            color: ref.watch(isFavoriteProvider(item.id)) ? Colors.amber : colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                          onPressed: () {
                            ref.read(favoritesProvider.notifier).toggleFavorite(item.id);
                          },
                          tooltip: ref.watch(isFavoriteProvider(item.id)) ? 'Remove from favorites' : 'Add to favorites',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),

                      // Actions Menu - more compact on mobile
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.more_vert,
                          size: isMobile ? 18 : 18,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: isMobile ? 0.5 : 1.0),
                        ),
                        onSelected: (value) => _handleItemAction(context, value, item),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          if (item.type == HierarchyItemType.portfolio) ...[
                            const PopupMenuItem(
                              value: 'create_program',
                              child: Row(
                                children: [
                                  Icon(Icons.folder, size: 16),
                                  SizedBox(width: 8),
                                  Text('Create Program'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'create_project',
                              child: Row(
                                children: [
                                  Icon(Icons.work, size: 16),
                                  SizedBox(width: 8),
                                  Text('Create Project'),
                                ],
                              ),
                            ),
                          ] else if (item.type == HierarchyItemType.program) ...[
                            const PopupMenuItem(
                              value: 'add_child',
                              child: Row(
                                children: [
                                  Icon(Icons.work, size: 16),
                                  SizedBox(width: 8),
                                  Text('Create Project'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'move',
                              child: Row(
                                children: [
                                  Icon(Icons.drive_file_move, size: 16),
                                  SizedBox(width: 8),
                                  Text('Move'),
                                ],
                              ),
                            ),
                          ] else if (item.type == HierarchyItemType.project)
                            const PopupMenuItem(
                              value: 'move',
                              child: Row(
                                children: [
                                  Icon(Icons.drive_file_move, size: 16),
                                  SizedBox(width: 8),
                                  Text('Move'),
                                ],
                              ),
                            ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: Theme.of(context).colorScheme.error),
                                const SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Expand/Collapse button (only if node has children)
                      if (node.children.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            node.isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: isMobile ? 18 : 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            if (node.isExpanded) {
                              _treeController?.collapseNode(node);
                            } else {
                              _treeController?.expandNode(node);
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
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
    return const SizedBox.shrink();
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
              'Start by creating your first project',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: () => _showCreateProjectDialog(),
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

  Widget _buildEmptyFilterState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No items match your filters',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _typeFilter = null;
                });
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(hierarchyStateProvider(includeArchived: _includeArchived)),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  List<HierarchyItem> _filterHierarchy(List<HierarchyItem> items) {
    final favorites = ref.watch(favoritesProvider);

    // For card view with type filter or favorites, flatten and filter
    if (_viewMode == HierarchyViewMode.cards && (_typeFilter != null || _showFavoritesOnly)) {
      final allItems = _flattenHierarchy(items);
      return allItems.where((item) {
        final matchesType = _typeFilter == null || item.type == _typeFilter;
        final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        final matchesFavorites = !_showFavoritesOnly || favorites.contains(item.id);

        return matchesType && matchesSearch && matchesFavorites;
      }).toList();
    }

    // For tree view with type filter, show only items of that type as flat list
    if (_viewMode == HierarchyViewMode.tree && _typeFilter != null) {
      final allItems = _flattenHierarchy(items);
      final filtered = allItems.where((item) {
        final matchesType = item.type == _typeFilter;
        final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        final matchesFavorites = !_showFavoritesOnly || favorites.contains(item.id);

        return matchesType && matchesSearch && matchesFavorites;
      }).map((item) => HierarchyItem(
        id: item.id,
        name: item.name,
        description: item.description,
        type: item.type,
        children: [], // No children when filtering by type
        metadata: item.metadata,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
        portfolioId: item.portfolioId,
        programId: item.programId,
      )).toList();

      return filtered;
    }

    // For tree view without type filter, maintain hierarchy
    return _filterRecursive(items, favorites);
  }

  List<HierarchyItem> _filterRecursive(List<HierarchyItem> items, Set<String> favorites) {
    final result = <HierarchyItem>[];

    for (final item in items) {
      // Filter children recursively
      final filteredChildren = _filterRecursive(item.children, favorites);

      // Check if this item matches filters
      final matchesSearch = _searchQuery.isEmpty ||
        item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (item.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesFavorites = !_showFavoritesOnly || favorites.contains(item.id);

      // Include item if it matches search and favorites
      if (matchesSearch && matchesFavorites) {
        result.add(HierarchyItem(
          id: item.id,
          name: item.name,
          description: item.description,
          type: item.type,
          children: filteredChildren,
          metadata: item.metadata,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
          portfolioId: item.portfolioId,
          programId: item.programId,
        ));
      } else if (filteredChildren.isNotEmpty) {
        // Include parent if it has matching children
        result.add(HierarchyItem(
          id: item.id,
          name: item.name,
          description: item.description,
          type: item.type,
          children: filteredChildren,
          metadata: item.metadata,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
          portfolioId: item.portfolioId,
          programId: item.programId,
        ));
      }
    }

    return result;
  }

  List<HierarchyItem> _flattenHierarchy(List<HierarchyItem> items) {
    final result = <HierarchyItem>[];
    for (final item in items) {
      result.add(item);
      result.addAll(_flattenHierarchy(item.children));
    }
    return result;
  }


  void _handleItemTap(String itemId, String itemType) {
    switch (itemType) {
      case 'portfolio':
        context.go('/hierarchy/portfolio/$itemId');
        break;
      case 'program':
        context.go('/hierarchy/program/$itemId');
        break;
      case 'project':
        context.go('/hierarchy/project/$itemId');
        break;
    }
  }

  void _handleItemAction(BuildContext context, String action, HierarchyItem item) {
    switch (action) {
      case 'edit':
        _showEditDialog(item);
        break;
      case 'add_child':
        _showAddChildDialog(item);
        break;
      case 'create_program':
        _showCreateProgramDialog(item.id);
        break;
      case 'create_project':
        _showCreateProjectDialogForPortfolio(item.id);
        break;
      case 'move':
        _showMoveDialog(item);
        break;
      case 'delete':
        _showDeleteConfirmation(item);
        break;
    }
  }

  void _showEditDialog(HierarchyItem item) {
    switch (item.type) {
      case HierarchyItemType.portfolio:
        showDialog(
          context: context,
          builder: (context) => EditPortfolioDialog(portfolioId: item.id),
        );
        break;
      case HierarchyItemType.program:
        showDialog(
          context: context,
          builder: (context) => EditProgramDialog(programId: item.id),
        );
        break;
      case HierarchyItemType.project:
        showDialog(
          context: context,
          builder: (context) => EditProjectFromHierarchyDialog(projectId: item.id),
        );
        break;
    }
  }

  void _showAddChildDialog(HierarchyItem item) {
    switch (item.type) {
      case HierarchyItemType.portfolio:
        _showCreateProgramDialog(item.id);
        break;
      case HierarchyItemType.program:
        _showCreateProjectDialog(programId: item.id, portfolioId: item.portfolioId);
        break;
      case HierarchyItemType.project:
        break;
    }
  }

  void _showMoveDialog(HierarchyItem item) {
    switch (item.type) {
      case HierarchyItemType.portfolio:
        // Portfolios can't be moved
        break;
      case HierarchyItemType.program:
        showDialog(
          context: context,
          builder: (context) => MoveProgramDialog(programId: item.id),
        );
        break;
      case HierarchyItemType.project:
        showDialog(
          context: context,
          builder: (context) => MoveProjectDialog(projectId: item.id),
        );
        break;
    }
  }

  void _showDeleteConfirmation(HierarchyItem item) {
    showDialog(
      context: context,
      builder: (context) => EnhancedDeleteDialog(
        itemId: item.id,
        itemName: item.name,
        itemType: item.type,
      ),
    );
  }

  void _showCreatePortfolioDialog() {
    showDialog(
      context: context,
      builder: (context) => CreatePortfolioDialog(
        onPortfolioCreated: (portfolio) {
          ref.invalidate(hierarchyStateProvider(includeArchived: _includeArchived));
        },
      ),
    );
  }

  void _showCreateProgramDialog(String? portfolioId) {
    showDialog(
      context: context,
      builder: (context) => CreateProgramDialog(
        portfolioId: portfolioId,
        portfolioName: portfolioId != null ? 'Portfolio' : null,
      ),
    );
  }

  void _showCreateProjectDialog({String? programId, String? portfolioId}) {
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
            preselectedProgramId: programId,
            preselectedPortfolioId: portfolioId,
          ),
        ),
      ),
    ).then((_) {
      // Refresh the hierarchy after dialog closes
      ref.invalidate(hierarchyStateProvider(includeArchived: _includeArchived));
    });
  }

  void _showCreateProjectDialogForPortfolio(String portfolioId) {
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
            preselectedPortfolioId: portfolioId,
          ),
        ),
      ),
    ).then((_) {
      // Refresh the hierarchy after dialog closes
      ref.invalidate(hierarchyStateProvider(includeArchived: _includeArchived));
    });
  }

  void _showAskAIDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AskAIPanel(
          projectId: 'organization',  // Special identifier for organization-level queries
          projectName: 'Organization',
          entityType: 'organization',
          onClose: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Widget _buildSpeedDialOverlay(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final actions = [
      {
        'icon': Icons.psychology_outlined,
        'label': 'Ask AI',
        'color': colorScheme.primary,
        'onTap': () {
          setState(() => _isActionMenuOpen = false);
          _showAskAIDialog(context);
        },
      },
      {
        'icon': Icons.business_center,
        'label': 'Add Portfolio',
        'color': Colors.purple,
        'onTap': () {
          setState(() => _isActionMenuOpen = false);
          _showCreatePortfolioDialog();
        },
      },
      {
        'icon': Icons.folder,
        'label': 'Add Program',
        'color': Colors.blue,
        'onTap': () {
          setState(() => _isActionMenuOpen = false);
          _showCreateProgramDialog(null);
        },
      },
      {
        'icon': Icons.work,
        'label': 'Add Project',
        'color': Colors.green,
        'onTap': () {
          setState(() => _isActionMenuOpen = false);
          _showCreateProjectDialog();
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

  String _getCountLabel(HierarchyItemType type) {
    switch (type) {
      case HierarchyItemType.portfolio:
        return 'programs';
      case HierarchyItemType.program:
        return 'projects';
      case HierarchyItemType.project:
        return 'items';
    }
  }
}

enum HierarchyViewMode { cards, tree }