import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/hierarchy_item.dart';

class HierarchyActionBar extends ConsumerWidget {
  final int selectedCount;
  final List<HierarchyItem> selectedItems;
  final VoidCallback onClearSelection;
  final Function(List<HierarchyItem>) onMoveItems;
  final Function(List<HierarchyItem>) onDeleteItems;
  
  const HierarchyActionBar({
    super.key,
    required this.selectedCount,
    required this.selectedItems,
    required this.onClearSelection,
    required this.onMoveItems,
    required this.onDeleteItems,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    if (selectedCount == 0) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClearSelection,
            iconSize: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '$selectedCount selected',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _showMoveDialog(context),
            icon: const Icon(Icons.drive_file_move_outline, size: 20),
            label: const Text('Move'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => _showDeleteDialog(context),
            icon: const Icon(Icons.delete_outline, size: 20),
            label: const Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showMoveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move Items'),
        content: Text('Move ${selectedCount} item(s) to a different location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onMoveItems(selectedItems);
            },
            child: const Text('Move'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Items'),
        content: Text('Are you sure you want to delete ${selectedCount} item(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDeleteItems(selectedItems);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}