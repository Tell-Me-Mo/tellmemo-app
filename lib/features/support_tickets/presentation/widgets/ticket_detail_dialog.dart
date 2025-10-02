import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pm_master_v2/features/support_tickets/models/support_ticket.dart';
import 'package:pm_master_v2/features/support_tickets/providers/support_ticket_provider.dart';
import 'package:file_picker/file_picker.dart';

class TicketDetailDialog extends ConsumerStatefulWidget {
  final SupportTicket ticket;

  const TicketDetailDialog({
    super.key,
    required this.ticket,
  });

  @override
  ConsumerState<TicketDetailDialog> createState() =>
      _TicketDetailDialogState();
}

class _TicketDetailDialogState extends ConsumerState<TicketDetailDialog> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSubmittingComment = false;
  late SupportTicket _ticket;
  final List<PlatformFile> _attachments = [];

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    setState(() => _isSubmittingComment = true);

    try {
      final service = ref.read(supportTicketServiceProvider);
      final newComment = await service.addComment(_ticket.id, comment: comment);

      // Upload attachments if any
      if (_attachments.isNotEmpty) {
        for (final file in _attachments) {
          try {
            // Use bytes if available (web), otherwise use path (native)
            if (file.bytes != null) {
              await service.uploadAttachment(
                _ticket.id,
                fileBytes: file.bytes!,
                fileName: file.name,
                commentId: newComment.id,
              );
            } else if (file.path != null) {
              await service.uploadAttachment(
                _ticket.id,
                filePath: file.path!,
                fileName: file.name,
                commentId: newComment.id,
              );
            }
          } catch (e) {
            debugPrint('Failed to upload attachment ${file.name}: $e');
          }
        }
      }

      _commentController.clear();
      _attachments.clear();

      ref.invalidate(ticketCommentsProvider(_ticket.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding comment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingComment = false);
      }
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg', 'gif', 'txt', 'csv', 'xlsx', 'xls'],
        withData: true, // Load file bytes for web compatibility
        withReadStream: false,
      );

      if (result != null) {
        final validFiles = <PlatformFile>[];
        for (final file in result.files) {
          if (file.size > 10 * 1024 * 1024) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File "${file.name}" exceeds 10MB limit'),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            validFiles.add(file);
          }
        }

        if (validFiles.isNotEmpty) {
          setState(() {
            _attachments.addAll(validFiles);
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking files: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final commentsAsync = ref.watch(ticketCommentsProvider(_ticket.id));

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 700,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            // Clean Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.08),
                    colorScheme.secondary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with badges and close button
                  Row(
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTypeColor(_ticket.type).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getTypeIcon(_ticket.type),
                              size: 14,
                              color: _getTypeColor(_ticket.type),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _ticket.type.label,
                              style: TextStyle(
                                color: _getTypeColor(_ticket.type),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_ticket.status).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _ticket.status.label,
                          style: TextStyle(
                            color: _getStatusColor(_ticket.status),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Priority badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(_ticket.priority).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _ticket.priority.label,
                          style: TextStyle(
                            color: _getPriorityColor(_ticket.priority),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    _ticket.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Meta info
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        _ticket.creatorName ?? _ticket.creatorEmail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy h:mm a').format(_ticket.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_ticket.attachmentCount > 0) ...[
                        const SizedBox(width: 16),
                        Icon(Icons.attach_file, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${_ticket.attachmentCount} file${_ticket.attachmentCount > 1 ? 's' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Content area
            Expanded(
              child: commentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading comments',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        error.toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                data: (comments) {
                  final allMessages = [
                    {
                      'type': 'original',
                      'content': _ticket.description,
                      'author': _ticket.creatorName ?? _ticket.creatorEmail,
                      'date': _ticket.createdAt,
                      'isInternal': false,
                    },
                    ...comments.map((c) => {
                      'type': 'comment',
                      'content': c.comment,
                      'author': c.userName ?? 'Unknown',
                      'date': c.createdAt,
                      'isInternal': c.isInternal,
                      'attachments': c.attachments,
                    }),
                  ];

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: allMessages.length,
                    itemBuilder: (context, index) {
                      final message = allMessages[index];
                      final isOriginal = message['type'] == 'original';
                      final isInternal = message['isInternal'] as bool? ?? false;

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < allMessages.length - 1 ? 16 : 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Message header
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isOriginal
                                    ? colorScheme.primary
                                    : colorScheme.secondary,
                                  child: Text(
                                    (message['author'] as String).substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            message['author'] as String,
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (isOriginal) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Original',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                          if (isInternal) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'Internal',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(
                                        DateFormat('MMM d, h:mm a').format(message['date'] as DateTime),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Message content
                            Container(
                              margin: const EdgeInsets.only(left: 44),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['content'] as String,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  // Attachments
                                  if (message['attachments'] != null &&
                                      (message['attachments'] as List).isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: (message['attachments'] as List).map((attachment) {
                                        final fileName = attachment['file_name'] ?? 'Unknown';
                                        return Chip(
                                          avatar: Icon(
                                            _getFileIcon(fileName),
                                            size: 16,
                                            color: colorScheme.primary,
                                          ),
                                          label: Text(
                                            fileName,
                                            style: theme.textTheme.bodySmall,
                                          ),
                                          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                                          side: BorderSide(
                                            color: colorScheme.primary.withValues(alpha: 0.3),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Comment input area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Attachment chips
                  if (_attachments.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _attachments.map((file) {
                        return Chip(
                          avatar: Icon(
                            _getFileIcon(file.name),
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          label: Text(
                            file.name,
                            style: theme.textTheme.bodySmall,
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: _isSubmittingComment ? null : () {
                            setState(() {
                              _attachments.remove(file);
                            });
                          },
                          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                          side: BorderSide(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Input row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          enabled: !_isSubmittingComment,
                          maxLines: 3,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: 'Type your comment...',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            filled: true,
                            fillColor: colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.primary.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isSubmittingComment ? null : _pickFiles,
                        icon: const Icon(Icons.attach_file),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                        tooltip: 'Attach files',
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isSubmittingComment ? null : _submitComment,
                        icon: _isSubmittingComment
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(_isSubmittingComment ? 'Sending...' : 'Send'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(TicketType type) {
    switch (type) {
      case TicketType.bugReport:
        return Icons.bug_report;
      case TicketType.featureRequest:
        return Icons.lightbulb_outline;
      case TicketType.generalSupport:
        return Icons.help_outline;
      case TicketType.documentation:
        return Icons.article_outlined;
    }
  }

  Color _getTypeColor(TicketType type) {
    switch (type) {
      case TicketType.bugReport:
        return Colors.red;
      case TicketType.featureRequest:
        return Colors.blue;
      case TicketType.generalSupport:
        return Colors.green;
      case TicketType.documentation:
        return Colors.orange;
    }
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return Colors.blue;
      case TicketStatus.inProgress:
        return Colors.orange;
      case TicketStatus.waitingForUser:
        return Colors.yellow.shade700;
      case TicketStatus.resolved:
        return Colors.green;
      case TicketStatus.closed:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return Colors.grey;
      case TicketPriority.medium:
        return Colors.blue;
      case TicketPriority.high:
        return Colors.orange;
      case TicketPriority.critical:
        return Colors.red;
    }
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return Icons.image;
      case 'txt':
      case 'csv':
        return Icons.text_snippet;
      case 'xlsx':
      case 'xls':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }
}