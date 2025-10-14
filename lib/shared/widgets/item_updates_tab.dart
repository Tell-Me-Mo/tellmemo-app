import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

    return Column(
      children: [
        // Updates List
        Expanded(
          child: widget.updates.isEmpty
              ? _buildEmptyState(theme, colorScheme)
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: widget.updates.length,
                  itemBuilder: (context, index) {
                    final update = widget.updates[index];
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
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed:
                          _isSubmitting || widget.isLoading ? null : _submitComment,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
                      tooltip: 'Send comment',
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
                  child: Text(
                    update.content,
                    style: theme.textTheme.bodyMedium,
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
}
