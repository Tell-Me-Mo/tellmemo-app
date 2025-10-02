import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BreadcrumbItem {
  final String label;
  final String? route;
  final IconData? icon;

  BreadcrumbItem({
    required this.label,
    this.route,
    this.icon,
  });
}

class BreadcrumbNavigation extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final bool showOnMobile;

  const BreadcrumbNavigation({
    super.key,
    required this.items,
    this.showOnMobile = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile && !showOnMobile) {
      return const SizedBox.shrink();
    }

    // On mobile, show collapsed version
    if (isMobile && items.length > 2) {
      return _buildCollapsedBreadcrumbs(context);
    }

    return SizedBox(
      height: 32,
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildBreadcrumbItem(
              context,
              items[i],
              isLast: i == items.length - 1,
            ),
            if (i < items.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollapsedBreadcrumbs(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 32,
      child: Row(
        children: [
          // Home/First item
          _buildBreadcrumbItem(context, items.first, isLast: false),

          // Ellipsis dropdown
          if (items.length > 2) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'More navigation options',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              itemBuilder: (context) {
                return items
                    .skip(1)
                    .take(items.length - 2)
                    .map((item) => PopupMenuItem(
                          value: item.route,
                          child: Row(
                            children: [
                              if (item.icon != null) ...[
                                Icon(item.icon, size: 16),
                                const SizedBox(width: 8),
                              ],
                              Text(item.label),
                            ],
                          ),
                        ))
                    .toList();
              },
              onSelected: (route) {
                if (route != null && route.isNotEmpty) {
                  context.go(route);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.more_horiz,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Separator and current page
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              Icons.chevron_right,
              size: 16,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          _buildBreadcrumbItem(context, items.last, isLast: true),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbItem(
    BuildContext context,
    BreadcrumbItem item,
    {required bool isLast}
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.icon != null) ...[
          Icon(
            item.icon,
            size: 14,
            color: isLast
                ? colorScheme.onSurface
                : colorScheme.primary,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          item.label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isLast
                ? colorScheme.onSurface
                : colorScheme.primary,
            fontWeight: isLast ? FontWeight.w600 : FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );

    if (isLast || item.route == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isLast
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: content,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(item.route!),
        borderRadius: BorderRadius.circular(4),
        hoverColor: colorScheme.primary.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: content,
        ),
      ),
    );
  }
}