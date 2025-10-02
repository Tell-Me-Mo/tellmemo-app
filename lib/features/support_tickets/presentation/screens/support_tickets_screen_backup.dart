import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pm_master_v2/core/constants/breakpoints.dart';
import 'package:pm_master_v2/core/constants/layout_constants.dart';
import 'package:pm_master_v2/features/support_tickets/models/support_ticket.dart';
import 'package:pm_master_v2/features/support_tickets/providers/support_ticket_provider.dart';
import 'package:pm_master_v2/features/support_tickets/presentation/widgets/new_ticket_dialog.dart';
import 'package:pm_master_v2/features/support_tickets/presentation/widgets/ticket_detail_dialog.dart';

class SupportTicketsScreen extends ConsumerStatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  ConsumerState<SupportTicketsScreen> createState() =>
      _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends ConsumerState<SupportTicketsScreen>
    with TickerProviderStateMixin {
  TicketStatus? _filterStatus;
  TicketPriority? _filterPriority;
  TicketType? _filterType;
  bool _showMyTickets = false;
  bool _showAssignedToMe = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';

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
      length: 2, // My Tickets, Assigned to Me
      vsync: this,
    );
    _tabController.addListener(() {
      setState(() {
        _showMyTickets = _tabController.index == 0;
        _showAssignedToMe = _tabController.index == 1;
      });
      _refreshTickets();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _animationController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktop;
    final isTablet = screenWidth >= Breakpoints.tablet && screenWidth < Breakpoints.desktop;
    final isMobile = screenWidth < Breakpoints.tablet;
    final ticketsAsync = ref.watch(ticketsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewTicketDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Ticket'),
        backgroundColor: colorScheme.primary,
      ),
      body: Column(
        children: [
          _buildHeroSection(context, theme, colorScheme, isDesktop, isTablet, isMobile),
          _buildFiltersSection(context, theme, colorScheme, isDesktop, isTablet, isMobile),
          Expanded(
            child: ticketsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: colorScheme.error),
                    const SizedBox(height: 16),
                    Text('Error loading tickets: ${error.toString()}'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          ref.refresh(ticketsProvider.notifier).loadTickets(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (tickets) {
                final filteredTickets = _filterTickets(tickets);

                if (filteredTickets.isEmpty) {
                  return _buildEmptyState(context, theme, colorScheme);
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(ticketsProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = filteredTickets[index];
                      return _buildTicketCard(context, theme, colorScheme, ticket);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(
      BuildContext context,
      ThemeData theme,
      ColorScheme colorScheme,
      bool isDesktop,
      bool isTablet,
      bool isMobile) {
    final ticketsAsync = ref.watch(ticketsProvider);
    final tickets = ticketsAsync.valueOrNull ?? [];
    final filteredTickets = _filterTickets(tickets);

    // Calculate statistics
    final statistics = {
      'total': filteredTickets.length,
      'open': filteredTickets.where((t) => t.status == TicketStatus.open).length,
      'inProgress': filteredTickets.where((t) => t.status == TicketStatus.inProgress).length,
      'resolved': filteredTickets.where((t) => t.status == TicketStatus.resolved).length,
    };

    return SizedBox(
      height: isDesktop ? 80 : (isMobile ? 110 : 90),
      child: Container(
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
              vertical: 8,
            ),
            child: !isMobile
                ? Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Row(
                        children: [
                          // Title Section
                          Icon(
                            Icons.support_agent,
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
                                    'Support Tickets',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_hasActiveFilters()) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${_getActiveFilterCount()} filters',
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
                                'Submit and track support requests',
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
                                    label: 'Total tickets',
                                    theme: theme,
                                  ),
                                  Container(
                                    height: 30,
                                    width: 1,
                                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                  ),
                                  _buildSimpleStatCard(
                                    value: statistics['open'].toString(),
                                    label: 'Open',
                                    theme: theme,
                                    valueColor: Colors.blue,
                                  ),
                                  Container(
                                    height: 30,
                                    width: 1,
                                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                  ),
                                  _buildSimpleStatCard(
                                    value: statistics['inProgress'].toString(),
                                    label: 'In Progress',
                                    theme: theme,
                                    valueColor: Colors.orange,
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
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.support_agent,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Support',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Track requests',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            onPressed: () => ref.refresh(ticketsProvider),
                            tooltip: 'Refresh',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildMobileStatBadge(
                              label: 'total',
                              value: statistics['total'].toString(),
                              color: null,
                              theme: theme,
                            ),
                            Container(
                              width: 1,
                              height: 12,
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                            _buildMobileStatBadge(
                              label: 'open',
                              value: statistics['open'].toString(),
                              color: Colors.blue,
                              theme: theme,
                            ),
                            Container(
                              width: 1,
                              height: 12,
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                            _buildMobileStatBadge(
                              label: 'active',
                              value: statistics['inProgress'].toString(),
                              color: Colors.orange,
                              theme: theme,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
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

  Widget _buildFiltersSection(
      BuildContext context,
      ThemeData theme,
      ColorScheme colorScheme,
      bool isDesktop,
      bool isTablet,
      bool isMobile) {
    return Container(
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
                                  setState(() {
                                    _searchQuery = value.toLowerCase();
                                  });
                                }
                              });
                            },
                            style: theme.textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Search tickets...',
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
                                        setState(() {
                                          _searchQuery = '';
                                        });
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

                    // Filter Button
                    IconButton(
                      onPressed: () => _showFilterDialog(context),
                      icon: Badge(
                        isLabelVisible: _hasActiveFilters(),
                        label: Text(_getActiveFilterCount().toString()),
                        child: Icon(
                          Icons.filter_list,
                          color: _hasActiveFilters()
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
                      ),
                      tooltip: 'Filters',
                      style: IconButton.styleFrom(
                        backgroundColor: _hasActiveFilters()
                            ? colorScheme.primary.withValues(alpha: 0.1)
                            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),

                // Tab and Dropdown Filters
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Tab Selector for My Tickets / Assigned to Me
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTabButton(
                            label: 'My Tickets',
                            isSelected: _showMyTickets,
                            onTap: () {
                              setState(() {
                                _showMyTickets = true;
                                _showAssignedToMe = false;
                              });
                              _refreshTickets();
                            },
                            colorScheme: colorScheme,
                          ),
                          _buildTabButton(
                            label: 'Assigned to Me',
                            isSelected: _showAssignedToMe,
                            onTap: () {
                              setState(() {
                                _showAssignedToMe = true;
                                _showMyTickets = false;
                              });
                              _refreshTickets();
                            },
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: 16),
                      // Dropdown Filters
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180, minWidth: 120),
                        child: DropdownButtonFormField<TicketStatus>(
                          initialValue: _filterStatus,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                          style: theme.textTheme.bodySmall,
                          items: [
                            DropdownMenuItem<TicketStatus>(
                              value: null,
                              child: Text('All Status', style: theme.textTheme.bodySmall),
                            ),
                            ...TicketStatus.values.map((item) => DropdownMenuItem<TicketStatus>(
                              value: item,
                              child: Text(item.label, style: theme.textTheme.bodySmall),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() => _filterStatus = value);
                            _refreshTickets();
                          },
                        ),
                      ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180, minWidth: 120),
                        child: DropdownButtonFormField<TicketPriority>(
                          initialValue: _filterPriority,
                          decoration: InputDecoration(
                            labelText: 'Priority',
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                          style: theme.textTheme.bodySmall,
                          items: [
                            DropdownMenuItem<TicketPriority>(
                              value: null,
                              child: Text('All Priority', style: theme.textTheme.bodySmall),
                            ),
                            ...TicketPriority.values.map((item) => DropdownMenuItem<TicketPriority>(
                              value: item,
                              child: Text(item.label, style: theme.textTheme.bodySmall),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() => _filterPriority = value);
                            _refreshTickets();
                          },
                        ),
                      ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180, minWidth: 120),
                        child: DropdownButtonFormField<TicketType>(
                          initialValue: _filterType,
                          decoration: InputDecoration(
                            labelText: 'Type',
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                          style: theme.textTheme.bodySmall,
                          items: [
                            DropdownMenuItem<TicketType>(
                              value: null,
                              child: Text('All Type', style: theme.textTheme.bodySmall),
                            ),
                            ...TicketType.values.map((item) => DropdownMenuItem<TicketType>(
                              value: item,
                              child: Text(item.label, style: theme.textTheme.bodySmall),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() => _filterType = value);
                            _refreshTickets();
                          },
                        ),
                      ),
                      ),
                    ],
                  ],
                ),

                // Quick Filters
                if (_hasActiveFilters()) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        if (_filterStatus != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text('Status: ${_filterStatus!.label}', style: const TextStyle(fontSize: 12)),
                              selected: true,
                              onSelected: (_) {
                                setState(() => _filterStatus = null);
                                _refreshTickets();
                              },
                              selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                              checkmarkColor: colorScheme.primary,
                              labelStyle: TextStyle(color: colorScheme.primary),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        if (_filterPriority != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text('Priority: ${_filterPriority!.label}', style: const TextStyle(fontSize: 12)),
                              selected: true,
                              onSelected: (_) {
                                setState(() => _filterPriority = null);
                                _refreshTickets();
                              },
                              selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                              checkmarkColor: colorScheme.primary,
                              labelStyle: TextStyle(color: colorScheme.primary),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        if (_filterType != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text('Type: ${_filterType!.label}', style: const TextStyle(fontSize: 12)),
                              selected: true,
                              onSelected: (_) {
                                setState(() => _filterType = null);
                                _refreshTickets();
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
                          onPressed: _clearFilters,
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
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.surface : Colors.transparent,
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Tickets'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<TicketStatus>(
              initialValue: _filterStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...TicketStatus.values.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.label),
                    )),
              ],
              onChanged: (value) {
                setState(() => _filterStatus = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TicketPriority>(
              initialValue: _filterPriority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...TicketPriority.values.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.label),
                    )),
              ],
              onChanged: (value) {
                setState(() => _filterPriority = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TicketType>(
              initialValue: _filterType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...TicketType.values.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.label),
                    )),
              ],
              onChanged: (value) {
                setState(() => _filterType = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearFilters();
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () {
              _refreshTickets();
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }


  Widget _buildTicketCard(
      BuildContext context, ThemeData theme, ColorScheme colorScheme, SupportTicket ticket) {
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 2 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showTicketDetail(context, ticket),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ticket.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusChip(ticket.status),
                      const SizedBox(height: 8),
                      _buildPriorityChip(ticket.priority),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _getTypeIcon(ticket.type),
                    size: 16,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ticket.type.label,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ticket.creatorName ?? ticket.creatorEmail,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(ticket.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (ticket.commentCount > 0) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.comment_outlined,
                      size: 16,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ticket.commentCount.toString(),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
              if (ticket.lastComment != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey.shade800.withValues(alpha: 0.5)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.reply,
                        size: 16,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${ticket.lastComment!['user_name'] ?? 'Unknown'}: ${ticket.lastComment!['comment']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(TicketStatus status) {
    Color color;
    Color textColor;

    switch (status) {
      case TicketStatus.open:
        color = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
        break;
      case TicketStatus.inProgress:
        color = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        break;
      case TicketStatus.waitingForUser:
        color = Colors.yellow.shade100;
        textColor = Colors.yellow.shade900;
        break;
      case TicketStatus.resolved:
        color = Colors.green.shade100;
        textColor = Colors.green.shade900;
        break;
      case TicketStatus.closed:
        color = Colors.grey.shade300;
        textColor = Colors.grey.shade900;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(TicketPriority priority) {
    Color color;
    switch (priority) {
      case TicketPriority.low:
        color = Colors.grey;
        break;
      case TicketPriority.medium:
        color = Colors.blue;
        break;
      case TicketPriority.high:
        color = Colors.orange;
        break;
      case TicketPriority.critical:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            priority.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 64,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 16),
          Text(
            _hasActiveFilters()
                ? 'No tickets match your filters'
                : 'No tickets yet',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _hasActiveFilters()
                ? 'Try adjusting your filters'
                : 'Submit a ticket to get help',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),
          if (_hasActiveFilters())
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            )
          else
            FilledButton.icon(
              onPressed: () => _showNewTicketDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Submit First Ticket'),
            ),
        ],
      ),
    );
  }

  List<SupportTicket> _filterTickets(List<SupportTicket> tickets) {
    return tickets.where((ticket) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final matchesSearch = ticket.title.toLowerCase().contains(searchLower) ||
            ticket.description.toLowerCase().contains(searchLower) ||
            ticket.creatorEmail.toLowerCase().contains(searchLower) ||
            (ticket.creatorName?.toLowerCase().contains(searchLower) ?? false);
        if (!matchesSearch) return false;
      }

      // Status filter
      if (_filterStatus != null && ticket.status != _filterStatus) {
        return false;
      }

      // Priority filter
      if (_filterPriority != null && ticket.priority != _filterPriority) {
        return false;
      }

      // Type filter
      if (_filterType != null && ticket.type != _filterType) {
        return false;
      }

      return true;
    }).toList();
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_filterStatus != null) count++;
    if (_filterPriority != null) count++;
    if (_filterType != null) count++;
    if (_showMyTickets) count++;
    if (_showAssignedToMe) count++;
    if (_searchQuery.isNotEmpty) count++;
    return count;
  }

  bool _hasActiveFilters() {
    return _filterStatus != null ||
        _filterPriority != null ||
        _filterType != null ||
        _showMyTickets ||
        _showAssignedToMe;
  }

  void _clearFilters() {
    setState(() {
      _filterStatus = null;
      _filterPriority = null;
      _filterType = null;
      _showMyTickets = false;
      _showAssignedToMe = false;
    });
    _refreshTickets();
  }

  void _refreshTickets() {
    ref.read(ticketsProvider.notifier).loadTickets(
          status: _filterStatus,
          priority: _filterPriority,
          type: _filterType,
          createdByMe: _showMyTickets,
          assignedToMe: _showAssignedToMe,
        );
  }

  void _showNewTicketDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const NewTicketDialog(),
    );

    if (result == true) {
      _refreshTickets();
    }
  }

  void _showTicketDetail(BuildContext context, SupportTicket ticket) {
    showDialog(
      context: context,
      builder: (context) => TicketDetailDialog(ticket: ticket),
    );
  }

  IconData _getTypeIcon(TicketType type) {
    switch (type) {
      case TicketType.bugReport:
        return Icons.bug_report;
      case TicketType.featureRequest:
        return Icons.lightbulb_outline;
      case TicketType.generalSupport:
        return Icons.help_outline;
      case TicketType.documentation:
        return Icons.article_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}