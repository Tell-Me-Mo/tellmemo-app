enum ItemUpdateType {
  comment,
  statusChange,
  assignment,
  edit,
  created,
}

/// Domain entity for item updates/comments
/// Represents a single update or comment on any item (risk, task, blocker, lesson)
class ItemUpdate {
  final String id;
  final String itemId;
  final String itemType; // 'risk', 'task', 'blocker', 'lesson'
  final String projectId;
  final String content;
  final String authorName;
  final String? authorEmail;
  final DateTime timestamp;
  final ItemUpdateType type;

  const ItemUpdate({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.projectId,
    required this.content,
    required this.authorName,
    this.authorEmail,
    required this.timestamp,
    required this.type,
  });

  ItemUpdate copyWith({
    String? id,
    String? itemId,
    String? itemType,
    String? projectId,
    String? content,
    String? authorName,
    String? authorEmail,
    DateTime? timestamp,
    ItemUpdateType? type,
  }) {
    return ItemUpdate(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      projectId: projectId ?? this.projectId,
      content: content ?? this.content,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemUpdate && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ItemUpdate{id: $id, itemId: $itemId, itemType: $itemType, type: $type, timestamp: $timestamp}';
  }

  // Helper methods
  bool get isComment => type == ItemUpdateType.comment;
  bool get isSystemGenerated => type != ItemUpdateType.comment;

  String get typeLabel {
    switch (type) {
      case ItemUpdateType.comment:
        return 'Comment';
      case ItemUpdateType.statusChange:
        return 'Status Change';
      case ItemUpdateType.assignment:
        return 'Assignment';
      case ItemUpdateType.edit:
        return 'Edit';
      case ItemUpdateType.created:
        return 'Created';
    }
  }
}
