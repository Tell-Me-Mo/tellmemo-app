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
    with SingleTickerProviderStateMixin {
  TicketStatus? _filterStatus;
  TicketPriority? _filterPriority;
  TicketType? _filterType;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
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
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _animationController.dispose();
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
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 24 : 16,
                      vertical: 16,
                    ),
                    itemCount: filteredTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = filteredTickets[index];
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1400),
                          child: _buildTicketCard(context, theme, colorScheme, ticket),
                        ),
                      );
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
                // Search Bar Row
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
                  ],
                ),

                // Dropdown Filters Row
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: ButtonTheme(
                            alignedDropdown: true,
                            child: DropdownButton<TicketStatus>(
                              value: _filterStatus,
                              hint: Text(
                                'All Status',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                              ),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                              isExpanded: true,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                              items: [
                                DropdownMenuItem<TicketStatus>(
                                  value: null,
                                  child: Text('All Status'),
                                ),
                                ...TicketStatus.values.map((item) => DropdownMenuItem<TicketStatus>(
                                  value: item,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(item),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Text(item.label),
                                    ],
                                  ),
                                )),
                              ],
                              onChanged: (value) {
                                setState(() => _filterStatus = value);
                                _refreshTickets();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: ButtonTheme(
                            alignedDropdown: true,
                            child: DropdownButton<TicketPriority>(
                              value: _filterPriority,
                              hint: Text(
                                'All Priority',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                              ),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                              isExpanded: true,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                              items: [
                                DropdownMenuItem<TicketPriority>(
                                  value: null,
                                  child: Text('All Priority'),
                                ),
                                ...TicketPriority.values.map((item) => DropdownMenuItem<TicketPriority>(
                                  value: item,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: _getPriorityColor(item),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Text(item.label),
                                    ],
                                  ),
                                )),
                              ],
                              onChanged: (value) {
                                setState(() => _filterPriority = value);
                                _refreshTickets();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: ButtonTheme(
                            alignedDropdown: true,
                            child: DropdownButton<TicketType>(
                              value: _filterType,
                              hint: Text(
                                'All Types',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                              ),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                              isExpanded: true,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                              items: [
                                DropdownMenuItem<TicketType>(
                                  value: null,
                                  child: Text('All Types'),
                                ),
                                ...TicketType.values.map((item) => DropdownMenuItem<TicketType>(
                                  value: item,
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getTypeIcon(item),
                                        size: 16,
                                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(item.label),
                                    ],
                                  ),
                                )),
                              ],
                              onChanged: (value) {
                                setState(() => _filterType = value);
                                _refreshTickets();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
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

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return Colors.blue;
      case TicketStatus.inProgress:
        return Colors.orange;
      case TicketStatus.waitingForUser:
        return Colors.yellow.shade700;
      case TicketStatus.resolved:
        return Colors.green;
      case TicketStatus.closed:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return Colors.grey;
      case TicketPriority.medium:
        return Colors.blue;
      case TicketPriority.high:
        return Colors.orange;
      case TicketPriority.critical:
        return Colors.red;
    }
  }

  Color _getTypeColor(TicketType type) {
    switch (type) {
      case TicketType.bugReport:
        return Colors.red;
      case TicketType.featureRequest:
        return Colors.blue;
      case TicketType.generalSupport:
        return Colors.green;
      case TicketType.documentation:
        return Colors.orange;
    }
  }

  Widget _buildTicketCard(
      BuildContext context, ThemeData theme, ColorScheme colorScheme, SupportTicket ticket) {
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: InkWell(
        onTap: () => _showTicketDetail(context, ticket),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and status
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Status indicator dot
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStatusColor(ticket.status),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Title
                  Expanded(
                    child: Text(
                      ticket.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ticket.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ticket.status.label,
                      style: TextStyle(
                        color: _getStatusColor(ticket.status),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Priority indicator
                  if (ticket.priority == TicketPriority.high || ticket.priority == TicketPriority.critical) ...[
                    const SizedBox(width: 6),
                    Icon(
                      ticket.priority == TicketPriority.critical
                        ? Icons.priority_high_rounded
                        : Icons.arrow_upward_rounded,
                      size: 16,
                      color: _getPriorityColor(ticket.priority),
                    ),
                  ],
                ],
              ),

              // Description
              const SizedBox(height: 8),
              Text(
                ticket.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),

              // Footer with metadata
              const SizedBox(height: 10),
              Row(
                children: [
                  // Type icon and label
                  Icon(
                    _getTypeIcon(ticket.type),
                    size: 14,
                    color: _getTypeColor(ticket.type),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ticket.type.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // User
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ticket.creatorName ?? ticket.creatorEmail.split('@')[0],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 12),
                  // Time
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(ticket.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  // Comments and attachments
                  if (ticket.commentCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.comment_outlined,
                            size: 12,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            ticket.commentCount.toString(),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (ticket.attachmentCount > 0) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.attach_file,
                      size: 14,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      ticket.attachmentCount.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
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
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.confirmation_number_outlined,
                size: 40,
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _hasActiveFilters()
                  ? 'No tickets found'
                  : 'No tickets yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _hasActiveFilters()
                  ? 'Try adjusting your filters to find what you\'re looking for'
                  : 'Submit a ticket to get help with your issues',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_hasActiveFilters())
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Clear Filters'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => _showNewTicketDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Submit First Ticket'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
          ],
        ),
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
    if (_searchQuery.isNotEmpty) count++;
    return count;
  }

  bool _hasActiveFilters() {
    return _filterStatus != null ||
        _filterPriority != null ||
        _filterType != null;
  }

  void _clearFilters() {
    setState(() {
      _filterStatus = null;
      _filterPriority = null;
      _filterType = null;
    });
    _refreshTickets();
  }

  void _refreshTickets() {
    ref.read(ticketsProvider.notifier).loadTickets(
          status: _filterStatus,
          priority: _filterPriority,
          type: _filterType,
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