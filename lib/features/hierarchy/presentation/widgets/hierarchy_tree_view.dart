import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/hierarchy_item.dart';
import '../providers/hierarchy_providers.dart';
import 'hierarchy_item_tile.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../core/utils/animation_utils.dart';
import '../../../../core/constants/ui_constants.dart';

class HierarchyTreeView extends ConsumerStatefulWidget {
  final List<HierarchyItem> hierarchy;
  final String searchQuery;
  final bool isMultiSelectMode;
  final Function(String itemId, String itemType)? onItemTap;
  final Function(String itemId, String itemType)? onItemLongPress;
  final Function(String parentId, String parentType)? onCreateChild;
  final Function(String itemId, String itemType)? onEditItem;
  final Function(String itemId, String itemType)? onMoveItem;
  final Function(String itemId, String itemType)? onDeleteItem;

  const HierarchyTreeView({
    super.key,
    required this.hierarchy,
    this.searchQuery = '',
    this.isMultiSelectMode = false,
    this.onItemTap,
    this.onItemLongPress,
    this.onCreateChild,
    this.onEditItem,
    this.onMoveItem,
    this.onDeleteItem,
  });

  @override
  ConsumerState<HierarchyTreeView> createState() => _HierarchyTreeViewState();
}

class _HierarchyTreeViewState extends ConsumerState<HierarchyTreeView> {
  final Set<String> _expandedItems = <String>{};
  final Set<String> _collapsedItems = <String>{}; // Track manually collapsed items

  @override
  void initState() {
    super.initState();
    // Initialize all items as expanded
    _expandAllItems();
  }

  void _expandAllItems() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _expandedItems.clear();
          _collapsedItems.clear();
          _collectAllExpandableItems(widget.hierarchy);
        });
      }
    });
  }

  void _collectAllExpandableItems(List<HierarchyItem> items) {
    for (final item in items) {
      if (item.children.isNotEmpty && !_collapsedItems.contains(item.id)) {
        _expandedItems.add(item.id);
      }
      _collectAllExpandableItems(item.children);
    }
  }

  @override
  void didUpdateWidget(HierarchyTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When hierarchy changes, expand new items
    if (oldWidget.hierarchy != widget.hierarchy) {
      _collectAllExpandableItems(widget.hierarchy);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(hierarchySelectionProvider);
    final filteredHierarchy = widget.searchQuery.isEmpty
        ? widget.hierarchy
        : _filterHierarchy(widget.hierarchy, widget.searchQuery);

    if (filteredHierarchy.isEmpty) {
      return _buildEmptySearchState();
    }

    return ListView.builder(
      itemCount: filteredHierarchy.length,
      itemBuilder: (context, index) {
        return _buildHierarchyNode(
          filteredHierarchy[index],
          depth: 0,
          selection: selection,
        );
      },
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: LayoutConstants.spacingM),
          Text(
            'No matches found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: LayoutConstants.spacingS),
          Text(
            'Try adjusting your search terms',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildHierarchyNode(
    HierarchyItem item,
    {
    required int depth,
    required Set<String> selection,
  }) {
    final isExpanded = _expandedItems.contains(item.id);
    final hasChildren = item.children.isNotEmpty;
    final isSelected = selection.contains(item.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HierarchyItemTile(
          item: item,
          isSelected: isSelected,
          isExpanded: isExpanded,
          indentLevel: depth,
          onTap: () => widget.onItemTap?.call(item.id, item.type.name),
          onExpand: hasChildren
            ? () => _toggleExpansion(item.id)
            : null,
          onSelectionChanged: widget.isMultiSelectMode
            ? (bool? value) {
                ref.read(hierarchySelectionProvider.notifier)
                    .toggleSelection(item.id);
              }
            : null,
          onEdit: () => widget.onEditItem?.call(item.id, item.type.name),
          onMove: () => widget.onMoveItem?.call(item.id, item.type.name),
          onDelete: () => widget.onDeleteItem?.call(item.id, item.type.name),
        ),

        // Children with animated expansion
        AnimatedExpansion(
          isExpanded: hasChildren && isExpanded,
          duration: UIConstants.normalAnimation,
          child: Column(
            children: item.children.map((child) => _buildHierarchyNode(
              child,
              depth: depth + 1,
              selection: selection,
            )).toList(),
          ),
        ),
      ],
    );
  }

  void _toggleExpansion(String itemId) {
    setState(() {
      if (_expandedItems.contains(itemId)) {
        _expandedItems.remove(itemId);
        _collapsedItems.add(itemId); // Remember that user manually collapsed this
      } else {
        _expandedItems.add(itemId);
        _collapsedItems.remove(itemId); // User manually expanded, remove from collapsed list
      }
    });
  }

  List<HierarchyItem> _filterHierarchy(List<HierarchyItem> hierarchy, String query) {
    if (query.isEmpty) return hierarchy;
    
    final lowercaseQuery = query.toLowerCase();
    
    return hierarchy
        .where((item) => _itemMatchesQuery(item, lowercaseQuery))
        .map((item) => _filterHierarchyItem(item, lowercaseQuery))
        .toList();
  }

  bool _itemMatchesQuery(HierarchyItem item, String query) {
    // Check if this item matches
    if (item.name.toLowerCase().contains(query) ||
        (item.description?.toLowerCase().contains(query) ?? false)) {
      return true;
    }
    
    // Check if any children match
    return item.children.any((child) => _itemMatchesQuery(child, query));
  }

  HierarchyItem _filterHierarchyItem(HierarchyItem item, String query) {
    final filteredChildren = item.children
        .where((child) => _itemMatchesQuery(child, query))
        .map((child) => _filterHierarchyItem(child, query))
        .toList();

    return item.copyWith(children: filteredChildren);
  }
}