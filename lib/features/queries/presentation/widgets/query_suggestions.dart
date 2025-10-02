import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/query_provider.dart';

class QuerySuggestions extends ConsumerWidget {
  final String query;
  final Function(String) onSuggestionSelected;
  final List<String>? customSuggestions;

  const QuerySuggestions({
    super.key,
    required this.query,
    required this.onSuggestionSelected,
    this.customSuggestions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use custom suggestions if provided, otherwise use default provider suggestions
    final allSuggestions = customSuggestions ?? ref.watch(querySuggestionsProvider) ?? [];

    // Filter suggestions based on current query
    final filteredSuggestions = allSuggestions
        .where((s) => s.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();
    
    if (filteredSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: colorScheme.surface,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filteredSuggestions.length,
          itemBuilder: (context, index) {
            final suggestion = filteredSuggestions[index];
            final isLast = index == filteredSuggestions.length - 1;
            
            return Column(
              children: [
                InkWell(
                  onTap: () => onSuggestionSelected(suggestion),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 48,
                    endIndent: 16,
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}