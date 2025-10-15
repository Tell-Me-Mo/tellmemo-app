import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a single update/comment on an item
class ItemUpdate {
  final String id;
  final String content;
  final String authorName;
  final String? authorEmail;
  final DateTime timestamp;
  final ItemUpdateType type;

  const ItemUpdate({
    required this.id,
    required this.content,
    required this.authorName,
    this.authorEmail,
    required this.timestamp,
    required this.type,
  });
}

enum ItemUpdateType {
  comment,
  statusChange,
  assignment,
  edit,
  created,
}

/// Widget for displaying and adding updates/comments on an item
class ItemUpdatesTab extends StatefulWidget {
  final List<ItemUpdate> updates;
  final Function(String content) onAddComment;
  final bool isLoading;
  final String itemType; // e.g., 'risk', 'task', 'blocker', 'lesson'

  const ItemUpdatesTab({
    super.key,
    required this.updates,
    required this.onAddComment,
    this.isLoading = false,
    required this.itemType,
  });

  @override
  State<ItemUpdatesTab> createState() => _ItemUpdatesTabState();
}

class _ItemUpdatesTabState extends State<ItemUpdatesTab> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;
  Set<ItemUpdateType> _selectedTypes = {};
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadFilterPreferences();
  }

  Future<void> _loadFilterPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTypes = _prefs.getStringList('updates_filter_types') ?? [];

    if (savedTypes.isEmpty) {
      // If no saved preferences, show all types by default
      setState(() {
        _selectedTypes = ItemUpdateType.values.toSet();
      });
    } else {
      setState(() {
        _selectedTypes = savedTypes
            .map((type) => ItemUpdateType.values.firstWhere(
                  (t) => t.name == type,
                  orElse: () => ItemUpdateType.comment,
                ))
            .toSet();
      });
    }
  }

  Future<void> _saveFilterPreferences() async {
    await _prefs.setStringList(
      'updates_filter_types',
      _selectedTypes.map((t) => t.name).toList(),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onAddComment(_commentController.text.trim());
      _commentController.clear();
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filter updates based on selected types
    final filteredUpdates = widget.updates
        .where((update) => _selectedTypes.contains(update.type))
        .toList();

    return Column(
      children: [
        // Updates List
        Expanded(
          child: filteredUpdates.isEmpty
              ? _buildEmptyState(theme, colorScheme)
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredUpdates.length,
                  itemBuilder: (context, index) {
                    final update = filteredUpdates[index];
                    return _buildUpdateItem(theme, colorScheme, update);
                  },
                ),
        ),
        // Comment Input
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add a comment',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Filter Button
                  _buildFilterButton(theme, colorScheme),
                  const SizedBox(width: 12),
                  // Comment Input Field
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      focusNode: _focusNode,
                      enabled: !_isSubmitting && !widget.isLoading,
                      maxLines: null,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitComment(),
                      decoration: InputDecoration(
                        hintText: 'Write your comment...',
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Send Button with updated color
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF8B5CF6), // Purple
                          const Color(0xFF7C3AED), // Darker purple
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _isSubmitting || widget.isLoading
                            ? null
                            : _submitComment,
                        child: Center(
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.comment_outlined,
                size: 48,
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No updates yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to add a comment or update',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateItem(
      ThemeData theme, ColorScheme colorScheme, ItemUpdate update) {
    final dateFormat = DateFormat('MMM d, y • HH:mm');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar or Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getUpdateTypeColor(update.type).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getUpdateTypeIcon(update.type),
              size: 18,
              color: _getUpdateTypeColor(update.type),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      update.authorName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getUpdateTypeColor(update.type)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getUpdateTypeLabel(update.type),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _getUpdateTypeColor(update.type),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(update.timestamp),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: _ExpandableText(
                    text: update.content,
                    style: theme.textTheme.bodyMedium,
                    maxLength: 300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getUpdateTypeIcon(ItemUpdateType type) {
    switch (type) {
      case ItemUpdateType.comment:
        return Icons.comment;
      case ItemUpdateType.statusChange:
        return Icons.swap_horiz;
      case ItemUpdateType.assignment:
        return Icons.person_add;
      case ItemUpdateType.edit:
        return Icons.edit;
      case ItemUpdateType.created:
        return Icons.add_circle;
    }
  }

  Color _getUpdateTypeColor(ItemUpdateType type) {
    switch (type) {
      case ItemUpdateType.comment:
        return Colors.blue;
      case ItemUpdateType.statusChange:
        return Colors.orange;
      case ItemUpdateType.assignment:
        return Colors.purple;
      case ItemUpdateType.edit:
        return Colors.teal;
      case ItemUpdateType.created:
        return Colors.green;
    }
  }

  String _getUpdateTypeLabel(ItemUpdateType type) {
    switch (type) {
      case ItemUpdateType.comment:
        return 'COMMENT';
      case ItemUpdateType.statusChange:
        return 'STATUS';
      case ItemUpdateType.assignment:
        return 'ASSIGNED';
      case ItemUpdateType.edit:
        return 'EDITED';
      case ItemUpdateType.created:
        return 'CREATED';
    }
  }

  Widget _buildFilterButton(ThemeData theme, ColorScheme colorScheme) {
    final hasActiveFilters = _selectedTypes.length < ItemUpdateType.values.length;

    return StatefulBuilder(
      builder: (context, setButtonState) {
        return PopupMenuButton<String>(
          onSelected: (String value) {
            if (value == 'clear') {
              setState(() {
                _selectedTypes = ItemUpdateType.values.toSet();
                _saveFilterPreferences();
              });
              Navigator.of(context).pop();
            }
            // Don't close for individual selections
          },
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem<String>(
                enabled: false,
                child: StatefulBuilder(
                  builder: (context, setMenuState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Filter Updates',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (hasActiveFilters)
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedTypes = ItemUpdateType.values.toSet();
                                      _saveFilterPreferences();
                                    });
                                    Navigator.of(context).pop();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      'Clear',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Divider(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          height: 1,
                        ),
                        const SizedBox(height: 8),
                        // Filter options
                        ...ItemUpdateType.values.map((type) {
                          final isSelected = _selectedTypes.contains(type);
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (_selectedTypes.contains(type)) {
                                  // Don't allow deselecting if it's the last selected
                                  if (_selectedTypes.length > 1) {
                                    _selectedTypes.remove(type);
                                  }
                                } else {
                                  _selectedTypes.add(type);
                                }
                                _saveFilterPreferences();
                              });
                              setMenuState(() {}); // Update menu state
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  // Simple checkbox without borders
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: isSelected
                                          ? _getUpdateTypeColor(type)
                                          : colorScheme.surfaceContainerHighest,
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  // Remove the icon, just show the label
                                  Expanded(
                                    child: Text(
                                      _getUpdateTypeLabel(type),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: isSelected
                                            ? colorScheme.onSurface
                                            : colorScheme.onSurfaceVariant,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ];
          },
          position: PopupMenuPosition.over,
          constraints: const BoxConstraints(
            minWidth: 240,
            maxWidth: 240,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tooltip: 'Filter updates',
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: hasActiveFilters
                  ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasActiveFilters
                    ? colorScheme.primary.withValues(alpha: 0.5)
                    : colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  color: hasActiveFilters
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  size: 22,
                ),
                if (hasActiveFilters)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A widget that displays text with "Read more" functionality for long content
class _ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int maxLength;

  const _ExpandableText({
    required this.text,
    this.style,
    this.maxLength = 300,
  });

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // If text is short enough, just display it
    if (widget.text.length <= widget.maxLength) {
      return SelectableText(
        widget.text,
        style: widget.style,
      );
    }

    // Truncate at word boundary for cleaner look
    String truncatedText = widget.text;
    if (!_isExpanded) {
      // Find a good break point near maxLength
      truncatedText = widget.text.substring(0, widget.maxLength);

      // Try to break at last space before maxLength
      final lastSpace = truncatedText.lastIndexOf(' ');
      if (lastSpace > widget.maxLength * 0.8) { // Only if we're not losing too much text
        truncatedText = truncatedText.substring(0, lastSpace);
      }

      truncatedText = '$truncatedText...';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          _isExpanded ? widget.text : truncatedText,
          style: widget.style,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isExpanded ? 'Show less' : 'Read more',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
