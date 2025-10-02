import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../domain/entities/hierarchy_item.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/constants/layout_constants.dart';

class SearchFilter {
  final Set<HierarchyItemType> itemTypes;
  final bool includeArchived;
  final bool searchInDescription;
  
  const SearchFilter({
    this.itemTypes = const {},
    this.includeArchived = false,
    this.searchInDescription = true,
  });
  
  SearchFilter copyWith({
    Set<HierarchyItemType>? itemTypes,
    bool? includeArchived,
    bool? searchInDescription,
  }) {
    return SearchFilter(
      itemTypes: itemTypes ?? this.itemTypes,
      includeArchived: includeArchived ?? this.includeArchived,
      searchInDescription: searchInDescription ?? this.searchInDescription,
    );
  }
}

class EnhancedSearchBar extends ConsumerStatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<SearchFilter> onFilterChanged;
  final List<String> recentSearches;
  final List<HierarchyItem>? searchableItems;
  
  const EnhancedSearchBar({
    super.key,
    required this.onSearchChanged,
    required this.onFilterChanged,
    this.recentSearches = const [],
    this.searchableItems,
  });
  
  @override
  ConsumerState<EnhancedSearchBar> createState() => _EnhancedSearchBarState();
}

class _EnhancedSearchBarState extends ConsumerState<EnhancedSearchBar> 
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  
  Timer? _debounceTimer;
  OverlayEntry? _suggestionsOverlay;
  
  bool _showFilters = false;
  bool _hasFocus = false;
  SearchFilter _currentFilter = const SearchFilter();
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: UIConstants.normalAnimation,
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: UIConstants.defaultCurve,
    );
    
    _focusNode.addListener(_onFocusChange);
    _searchController.addListener(_onSearchTextChanged);
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _searchController.removeListener(_onSearchTextChanged);
    _focusNode.dispose();
    _searchController.dispose();
    _animationController.dispose();
    _removeSuggestionsOverlay();
    super.dispose();
  }
  
  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
    
    if (_focusNode.hasFocus && _searchController.text.isEmpty && widget.recentSearches.isNotEmpty) {
      _showSuggestionsOverlay(widget.recentSearches.take(UIConstants.maxSearchSuggestions).toList());
    } else if (!_focusNode.hasFocus) {
      _removeSuggestionsOverlay();
    }
  }
  
  void _onSearchTextChanged() {
    _debounceTimer?.cancel();
    
    if (_searchController.text.length < UIConstants.minSearchLength) {
      _removeSuggestionsOverlay();
      if (_searchController.text.isEmpty) {
        widget.onSearchChanged('');
      }
      return;
    }
    
    _debounceTimer = Timer(
      Duration(milliseconds: UIConstants.searchDebounceMilliseconds),
      () {
        widget.onSearchChanged(_searchController.text);
        _updateSuggestions();
      },
    );
  }
  
  void _updateSuggestions() {
    if (widget.searchableItems == null || _searchController.text.isEmpty) {
      _removeSuggestionsOverlay();
      return;
    }
    
    final query = _searchController.text.toLowerCase();
    final suggestions = <String>[];
    
    for (final item in widget.searchableItems!) {
      if (suggestions.length >= UIConstants.maxSearchSuggestions) break;
      
      if (item.name.toLowerCase().contains(query)) {
        suggestions.add(item.name);
      } else if (_currentFilter.searchInDescription && 
                 item.description != null && 
                 item.description!.toLowerCase().contains(query)) {
        suggestions.add(item.name);
      }
    }
    
    if (suggestions.isNotEmpty) {
      _showSuggestionsOverlay(suggestions);
    } else {
      _removeSuggestionsOverlay();
    }
  }
  
  void _showSuggestionsOverlay(List<String> suggestions) {
    _removeSuggestionsOverlay();
    
    _suggestionsOverlay = OverlayEntry(
      builder: (context) => Positioned(
        width: context.findRenderObject() != null 
            ? (context.findRenderObject() as RenderBox).size.width 
            : 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 48),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(LayoutConstants.borderRadiusMd),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(LayoutConstants.borderRadiusMd),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  final isRecent = widget.recentSearches.contains(suggestion);
                  
                  return InkWell(
                    onTap: () {
                      _searchController.text = suggestion;
                      widget.onSearchChanged(suggestion);
                      _removeSuggestionsOverlay();
                      _focusNode.unfocus();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isRecent ? Icons.history : Icons.search,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_suggestionsOverlay!);
  }
  
  void _removeSuggestionsOverlay() {
    _suggestionsOverlay?.remove();
    _suggestionsOverlay = null;
  }
  
  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
    
    if (_showFilters) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
  
  void _updateFilter(SearchFilter filter) {
    setState(() {
      _currentFilter = filter;
    });
    widget.onFilterChanged(filter);
    
    // Rerun search with new filters
    if (_searchController.text.isNotEmpty) {
      widget.onSearchChanged(_searchController.text);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(LayoutConstants.borderRadiusMd),
              border: Border.all(
                color: _hasFocus 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
                width: _hasFocus ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  Icons.search,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Search by name${_currentFilter.searchInDescription ? ' or description' : ''}...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      widget.onSearchChanged('');
                      _removeSuggestionsOverlay();
                    },
                    tooltip: 'Clear search',
                  ),
                IconButton(
                  icon: AnimatedRotation(
                    turns: _showFilters ? 0.5 : 0,
                    duration: UIConstants.shortAnimation,
                    child: Icon(
                      Icons.filter_list,
                      size: 20,
                      color: _currentFilter.itemTypes.isNotEmpty || 
                             _currentFilter.includeArchived
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onPressed: _toggleFilters,
                  tooltip: 'Toggle filters',
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(LayoutConstants.borderRadiusMd),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by type:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: HierarchyItemType.values.map((type) {
                    final isSelected = _currentFilter.itemTypes.contains(type);
                    return FilterChip(
                      label: Text(type.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        final newTypes = Set<HierarchyItemType>.from(_currentFilter.itemTypes);
                        if (selected) {
                          newTypes.add(type);
                        } else {
                          newTypes.remove(type);
                        }
                        _updateFilter(_currentFilter.copyWith(itemTypes: newTypes));
                      },
                      avatar: Icon(
                        _getIconForType(type),
                        size: 16,
                      ),
                      selectedColor: SelectionColors.getItemTypeColor(context, type.name)
                          .withValues(alpha: 0.2),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Search in descriptions'),
                        value: _currentFilter.searchInDescription,
                        onChanged: (value) {
                          _updateFilter(_currentFilter.copyWith(
                            searchInDescription: value ?? true,
                          ));
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Include archived'),
                        value: _currentFilter.includeArchived,
                        onChanged: (value) {
                          _updateFilter(_currentFilter.copyWith(
                            includeArchived: value ?? false,
                          ));
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                if (_currentFilter.itemTypes.isNotEmpty || _currentFilter.includeArchived)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: () {
                        _updateFilter(const SearchFilter());
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear filters'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  IconData _getIconForType(HierarchyItemType type) {
    switch (type) {
      case HierarchyItemType.portfolio:
        return Icons.business_center;
      case HierarchyItemType.program:
        return Icons.category;
      case HierarchyItemType.project:
        return Icons.folder;
    }
  }
}