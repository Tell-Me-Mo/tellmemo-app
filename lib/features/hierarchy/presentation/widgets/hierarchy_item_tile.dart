import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/hierarchy_item.dart';
import '../../../../core/constants/ui_constants.dart';

class HierarchyItemTile extends ConsumerWidget {
  final HierarchyItem item;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onExpand;
  final Function(bool?)? onSelectionChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onMove;
  final VoidCallback? onDelete;
  final int indentLevel;

  const HierarchyItemTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.isExpanded,
    this.onTap,
    this.onExpand,
    this.onSelectionChanged,
    this.onEdit,
    this.onMove,
    this.onDelete,
    this.indentLevel = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasChildren = item.hasChildren;
    
    return AnimatedContainer(
      duration: UIConstants.shortAnimation,
      decoration: isSelected
        ? BoxDecoration(
            color: SelectionColors.getSelectionColor(context),
            border: Border(
              left: BorderSide(
                color: SelectionColors.getSelectionBorderColor(context),
                width: UIConstants.selectionBorderWidth,
              ),
            ),
          )
        : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.only(
            left: 16.0 + (indentLevel * 32.0),
            right: 16.0,
            top: 8.0,
            bottom: 8.0,
          ),
          child: Row(
            children: [
              // Indentation indicator for hierarchy
              if (indentLevel > 0)
                Container(
                  margin: EdgeInsets.only(right: 8),
                  child: Row(
                    children: List.generate(
                      indentLevel,
                      (index) => Container(
                        width: 2,
                        height: 20,
                        margin: EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
              if (onSelectionChanged != null)
                Checkbox(
                  value: isSelected,
                  onChanged: onSelectionChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              if (onSelectionChanged != null)
                const SizedBox(width: 8),
              if (hasChildren)
                InkWell(
                  onTap: onExpand,
                  borderRadius: BorderRadius.circular(4),
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: isExpanded ? 0.25 : 0,
                    child: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                const SizedBox(width: 20),
              const SizedBox(width: 8),
              Icon(
                _getIconForType(item.type),
                size: 20,
                color: SelectionColors.getItemTypeColor(context, item.type.name),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.description != null && item.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              if (item.metadata != null && item.metadata!['count'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.metadata!['count'].toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) => _handleMenuAction(context, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'move',
                    child: Row(
                      children: [
                        Icon(Icons.drive_file_move_outline, size: 20),
                        SizedBox(width: 12),
                        Text('Move'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20),
                        SizedBox(width: 12),
                        Text('Delete'),
                      ],
                    ),
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
  
  
  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        onEdit?.call();
        break;
      case 'move':
        onMove?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}