import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../meetings/domain/entities/content.dart' as meetings;
import '../providers/documents_provider.dart';
import '../widgets/document_table_view.dart';
import '../widgets/empty_documents_widget.dart';
import '../widgets/document_skeleton_loader.dart';
import '../widgets/document_detail_panel.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDocumentDetailPanel(BuildContext context, meetings.Content document) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Document Detail',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return DocumentDetailPanel(
          document: document,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isMobile = screenWidth < 768;

    // Watch real data providers
    final documentsAsync = ref.watch(documentsListProvider);
    final statsAsync = ref.watch(documentsStatisticsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // Fixed Hero Header Section
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
                        child: Row(
                          children: [
                            // Title Section
                            Icon(
                              Icons.description,
                              color: colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Documents',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Upload documents or emails to get started',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 32),

                            // Clean Statistics Section
                            Expanded(
                              child: statsAsync.when(
                                data: (stats) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Row(
                                    children: [
                                      _buildSimpleStatCard(
                                        value: stats['total'].toString(),
                                        label: 'Total',
                                        theme: theme,
                                      ),
                                      Container(
                                        height: 30,
                                        width: 1,
                                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                      ),
                                      _buildSimpleStatCard(
                                        value: stats['meetings'].toString(),
                                        label: 'Meetings',
                                        theme: theme,
                                      ),
                                      Container(
                                        height: 30,
                                        width: 1,
                                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                      ),
                                      _buildSimpleStatCard(
                                        value: stats['emails'].toString(),
                                        label: 'Emails',
                                        theme: theme,
                                      ),
                                      Container(
                                        height: 30,
                                        width: 1,
                                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                      ),
                                      _buildSimpleStatCard(
                                        value: stats['thisWeek'].toString(),
                                        label: 'This Week',
                                        theme: theme,
                                      ),
                                    ],
                                  ),
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          Icon(
                            Icons.description,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Documents',
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
                          statsAsync.when(
                            data: (stats) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.description, size: 14, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Text(stats['total'].toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Icon(Icons.groups, size: 14, color: Colors.purple),
                                  const SizedBox(width: 4),
                                  Text(stats['meetings'].toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Icon(Icons.email, size: 14, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text(stats['emails'].toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          // Search Bar Section
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16,
              vertical: 16,
            ),
            color: colorScheme.surface,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      // Search Field - Same style as Tasks
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _searchController.text.isNotEmpty
                                  ? colorScheme.primary.withValues(alpha: 0.3)
                                  : colorScheme.outline.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {});
                            },
                            style: theme.textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Search documents...',
                              hintStyle: TextStyle(
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear,
                                        size: 18,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
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
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Scrollable Content
          Expanded(
            child: CustomScrollView(
              slivers: [
                documentsAsync.when(
                  data: (documents) {
                    // Filter by search query
                    var filtered = documents;
                    final isSearching = _searchController.text.isNotEmpty;
                    if (isSearching) {
                      final query = _searchController.text.toLowerCase();
                      filtered = filtered.where((d) =>
                        d.title.toLowerCase().contains(query)
                      ).toList();
                    }
                    return _buildDocumentsList(
                      context,
                      filtered,
                      isSearching: isSearching,
                      searchQuery: _searchController.text,
                      totalDocuments: documents.length,
                    );
                  },
                  loading: () => SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 24 : 16,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1400),
                          child: const DocumentSkeletonLoader(),
                        ),
                      ),
                    ),
                  ),
                  error: (error, _) => SliverToBoxAdapter(
                    child: _buildErrorState(context, error),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildMobileStatBadge({
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
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

  Widget _buildDocumentsList(
    BuildContext context,
    List<meetings.Content> documents, {
    bool isSearching = false,
    String searchQuery = '',
    int totalDocuments = 0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;

    if (documents.isEmpty) {
      return SliverFillRemaining(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: isSearching
                  ? _buildSearchEmptyState(context, searchQuery, totalDocuments)
                  : const EmptyDocumentsWidget(),
            ),
          ),
        ),
      );
    }

    // Always use table view
    return _buildTableView(context, documents, isDesktop, isTablet);
  }


  Widget _buildTableView(
    BuildContext context,
    List<meetings.Content> documents,
    bool isDesktop,
    bool isTablet,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: DocumentTableView(
              documents: documents,
              onDocumentTap: (document) {
                _showDocumentDetailPanel(context, document);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchEmptyState(BuildContext context, String searchQuery, int totalDocuments) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.search_off,
          size: 64,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 16),
        Text(
          'No results found',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'No documents match "$searchQuery"',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (totalDocuments > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search terms',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: () {
            _searchController.clear();
            setState(() {});
          },
          icon: const Icon(Icons.clear),
          label: const Text('Clear search'),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load documents',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

}