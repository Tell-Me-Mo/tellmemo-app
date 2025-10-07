import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HierarchySearchBar extends ConsumerStatefulWidget {
  final Function(String) onSearchChanged;
  final VoidCallback? onFilterTap;
  
  const HierarchySearchBar({
    super.key,
    required this.onSearchChanged,
    this.onFilterTap,
  });

  @override
  ConsumerState<HierarchySearchBar> createState() => _HierarchySearchBarState();
}

class _HierarchySearchBarState extends ConsumerState<HierarchySearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            Icons.search,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onSearchChanged,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search portfolios, programs, and projects...',
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                _controller.clear();
                widget.onSearchChanged('');
              },
              color: theme.colorScheme.onSurfaceVariant,
            ),
          if (widget.onFilterTap != null)
            IconButton(
              icon: const Icon(Icons.tune, size: 20),
              onPressed: widget.onFilterTap,
              color: theme.colorScheme.primary,
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}