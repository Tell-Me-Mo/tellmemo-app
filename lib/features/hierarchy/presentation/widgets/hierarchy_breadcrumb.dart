import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/hierarchy_item.dart';
import '../providers/hierarchy_providers.dart';

class HierarchyBreadcrumb extends ConsumerWidget {
  final List<HierarchyItem> path;
  final Function(HierarchyItem)? onItemTap;

  const HierarchyBreadcrumb({
    super.key,
    required this.path,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    if (path.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.home,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildBreadcrumbItems(context, theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBreadcrumbItems(BuildContext context, ThemeData theme) {
    final items = <Widget>[];
    
    for (int i = 0; i < path.length; i++) {
      final item = path[i];
      final isLast = i == path.length - 1;
      
      items.add(
        InkWell(
          onTap: !isLast && onItemTap != null ? () => onItemTap!(item) : null,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIconForType(item.type),
                  size: 16,
                  color: isLast 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  item.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isLast 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      
      if (!isLast) {
        items.add(
          Icon(
            Icons.chevron_right,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
        );
      }
    }
    
    return items;
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