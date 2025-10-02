enum ContentType { meeting, email }

class Content {
  final String id;
  final String projectId;
  final ContentType contentType;
  final String title;
  final DateTime? date;
  final DateTime uploadedAt;
  final String? uploadedBy;
  final int chunkCount;
  final bool summaryGenerated;
  final DateTime? processedAt;
  final String? processingError;

  const Content({
    required this.id,
    required this.projectId,
    required this.contentType,
    required this.title,
    this.date,
    required this.uploadedAt,
    this.uploadedBy,
    required this.chunkCount,
    required this.summaryGenerated,
    this.processedAt,
    this.processingError,
  });

  String get displayDate {
    final targetDate = date ?? uploadedAt;
    final now = DateTime.now();
    final difference = now.difference(targetDate);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${targetDate.day}/${targetDate.month}/${targetDate.year}';
    }
  }

  String get typeLabel {
    switch (contentType) {
      case ContentType.meeting:
        return 'Meeting';
      case ContentType.email:
        return 'Email';
    }
  }

  bool get isProcessed => processedAt != null && processingError == null;
  bool get hasError => processingError != null;
  bool get isProcessing => !isProcessed && !hasError;
}