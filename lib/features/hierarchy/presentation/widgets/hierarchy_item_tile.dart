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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 768;

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
          child: isMobile ? _buildMobileLayout(context, theme, hasChildren) : _buildDesktopLayout(context, theme, hasChildren),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, ThemeData theme, bool hasChildren) {
    return Container(
      padding: EdgeInsets.only(
        left: 12.0 + (indentLevel * 16.0), // Reduced indent spacing
        right: 12.0,
        top: 12.0,
        bottom: 12.0,
      ),
      child: Row(
        children: [
          // Chevron for expandable items (more compact)
          if (hasChildren)
            InkWell(
              onTap: onExpand,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: isExpanded ? 0.25 : 0,
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 4),

          // Icon with type color
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SelectionColors.getItemTypeColor(context, item.type.name).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconForType(item.type),
              size: 18,
              color: SelectionColors.getItemTypeColor(context, item.type.name),
            ),
          ),

          const SizedBox(width: 12),

          // Name and count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.metadata != null && item.metadata!['count'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${item.metadata!['count']} ${_getCountLabel(item.type)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: SelectionColors.getItemTypeColor(context, item.type.name).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: SelectionColors.getItemTypeColor(context, item.type.name).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              _getTypeLabel(item.type),
              style: TextStyle(
                color: SelectionColors.getItemTypeColor(context, item.type.name),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Compact menu button
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.more_vert,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 12),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'move',
                child: Row(
                  children: [
                    Icon(Icons.drive_file_move_outline, size: 18),
                    SizedBox(width: 12),
                    Text('Move'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18),
                    SizedBox(width: 12),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ThemeData theme, bool hasChildren) {
    return Container(
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
              margin: const EdgeInsets.only(right: 8),
              child: Row(
                children: List.generate(
                  indentLevel,
                  (index) => Container(
                    width: 2,
                    height: 20,
                    margin: const EdgeInsets.only(right: 6),
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

  String _getTypeLabel(HierarchyItemType type) {
    switch (type) {
      case HierarchyItemType.portfolio:
        return 'PORTFOLIO';
      case HierarchyItemType.program:
        return 'PROGRAM';
      case HierarchyItemType.project:
        return 'PROJECT';
    }
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