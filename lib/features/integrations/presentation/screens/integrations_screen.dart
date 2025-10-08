import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/integration_card.dart';
import '../widgets/integration_config_dialog.dart';
import '../providers/integrations_provider.dart';
import '../../domain/models/integration.dart';

class IntegrationsScreen extends ConsumerStatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  ConsumerState<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends ConsumerState<IntegrationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  final Map<String, List<String>> _categories = {
    'All': [],
    'Communication': ['Slack', 'Teams', 'Email', 'Discord'],
    'Development': ['GitHub', 'GitLab', 'Bitbucket', 'Jira'],
    'Storage': ['Google Drive', 'Dropbox', 'OneDrive', 'Box'],
    'Analytics': ['Google Analytics', 'Mixpanel', 'Amplitude'],
    'Productivity': ['Notion', 'Confluence', 'Asana', 'Trello'],
    'AI & ML': ['OpenAI', 'Anthropic', 'Hugging Face'],
  };

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768;
    final isMobile = screenWidth <= 768;

    final integrationsAsync = ref.watch(integrationsProvider);
    final integrations = integrationsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <Integration>[],
    );
    final statistics = _calculateStatistics(integrations);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // Fixed Hero Section with Statistics (Lessons style)
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
                    ? Row(
                        children: [
                          // Title Section
                          Icon(
                            Icons.extension_rounded,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Integrations',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Connect your tools and services',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 32),

                          // Statistics Section
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                children: [
                                  _buildSimpleStatCard(
                                    value: statistics['available'].toString(),
                                    label: 'Available',
                                    theme: theme,
                                  ),
                                  Container(
                                    height: 30,
                                    width: 1,
                                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                  ),
                                  _buildSimpleStatCard(
                                    value: statistics['connected'].toString(),
                                    label: 'Connected',
                                    theme: theme,
                                    valueColor: Colors.green,
                                  ),
                                  Container(
                                    height: 30,
                                    width: 1,
                                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                  ),
                                  _buildSimpleStatCard(
                                    value: statistics['pending'].toString(),
                                    label: 'Pending',
                                    theme: theme,
                                    valueColor: Colors.orange,
                                  ),
                                  Container(
                                    height: 30,
                                    width: 1,
                                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                  ),
                                  _buildSimpleStatCard(
                                    value: statistics['errors'].toString(),
                                    label: 'Errors',
                                    theme: theme,
                                    valueColor: Colors.red,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Icon(
                            Icons.extension_rounded,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Integrations',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'Connect tools',
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
                                Icon(Icons.extension, size: 14, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(statistics['available'].toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Icon(Icons.check_circle, size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(statistics['connected'].toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Icon(Icons.error, size: 14, color: Colors.red),
                                const SizedBox(width: 4),
                                Text(statistics['errors'].toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          // Main Content Area
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.only(
                left: isDesktop ? 24 : 16,
                right: isDesktop ? 24 : 16,
                top: isMobile ? 0 : 16,
                bottom: isMobile ? 8 : 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search and Filters
                      _buildSearchAndFilters(theme, isDesktop),
                      SizedBox(height: isMobile ? 8 : 24),

                      // Integrations Grid
                      _buildIntegrationsList(theme, isDesktop, isTablet),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateStatistics(List<Integration> integrations) {
    return {
      'available': integrations.length,
      'connected': integrations.where((i) => i.status == IntegrationStatus.connected).length,
      'pending': integrations.where((i) => i.status == IntegrationStatus.connecting).length,
      'errors': integrations.where((i) => i.status == IntegrationStatus.error).length,
    };
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


  Widget _buildSearchAndFilters(ThemeData theme, bool isDesktop) {
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 768;

    return Container(
      padding: EdgeInsets.only(
        top: isMobile ? 8 : 16,
        bottom: isMobile ? 8 : 16,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar with Controls
          Row(
            children: [
              // Search Field (Lessons style)
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
                              _searchQuery = value;
                            });
                          }
                        });
                      },
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Search integrations...',
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
                                icon: Icon(
                                  Icons.clear,
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
          SizedBox(height: isMobile ? 12 : 16),

          // Category Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.keys.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : 'All';
                      });
                    },
                    backgroundColor: colorScheme.surface,
                    selectedColor: colorScheme.primary.withValues(alpha: 0.15),
                    checkmarkColor: colorScheme.primary,
                    side: BorderSide(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationsList(ThemeData theme, bool isDesktop, bool isTablet) {
    final integrations = ref.watch(integrationsProvider);
    
    return integrations.when(
      data: (data) {
        final filteredIntegrations = _filterIntegrations(data);
        
        if (filteredIntegrations.isEmpty) {
          return _buildEmptyState(theme);
        }
        
        final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isDesktop ? 2.2 : 2.0,
          ),
          itemCount: filteredIntegrations.length,
          itemBuilder: (context, index) {
            final integration = filteredIntegrations[index];
            return IntegrationCard(
              integration: integration,
              onTap: () => _handleIntegrationTap(integration),
            );
          },
        );
      },
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: theme.colorScheme.primary,
                strokeWidth: 2,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading integrations...',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load integrations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.refresh(integrationsProvider),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(48),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No integrations found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  List<Integration> _filterIntegrations(List<Integration> integrations) {
    return integrations.where((integration) {
      final matchesSearch = _searchQuery.isEmpty ||
          integration.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          integration.description.toLowerCase().contains(_searchQuery.toLowerCase());

      if (_selectedCategory == 'All') {
        return matchesSearch;
      }

      final categoryIntegrations = _categories[_selectedCategory] ?? [];
      return matchesSearch && categoryIntegrations.contains(integration.name);
    }).toList();
  }

  void _handleIntegrationTap(Integration integration) {
    // Show the modern popup dialog instead of navigating
    IntegrationConfigDialog.show(context, integration);
  }

}