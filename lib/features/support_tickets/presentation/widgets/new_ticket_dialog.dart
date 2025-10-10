import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pm_master_v2/features/support_tickets/models/support_ticket.dart';
import 'package:pm_master_v2/features/support_tickets/providers/support_ticket_provider.dart';
import '../../../../core/services/notification_service.dart';

class NewTicketDialog extends ConsumerStatefulWidget {
  const NewTicketDialog({super.key});

  @override
  ConsumerState<NewTicketDialog> createState() => _NewTicketDialogState();
}

class _NewTicketDialogState extends ConsumerState<NewTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stepsToReproduceController = TextEditingController();
  final _expectedBehaviorController = TextEditingController();

  TicketType _selectedType = TicketType.generalSupport;
  TicketPriority _selectedPriority = TicketPriority.medium;
  bool _isSubmitting = false;
  String? _errorMessage;
  final List<PlatformFile> _attachments = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _stepsToReproduceController.dispose();
    _expectedBehaviorController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(supportTicketServiceProvider);

      // Combine additional fields into description if they're filled
      String fullDescription = _descriptionController.text.trim();

      if (_selectedType == TicketType.bugReport) {
        if (_stepsToReproduceController.text.trim().isNotEmpty) {
          fullDescription += '\n\n**Steps to Reproduce:**\n${_stepsToReproduceController.text.trim()}';
        }
        if (_expectedBehaviorController.text.trim().isNotEmpty) {
          fullDescription += '\n\n**Expected Behavior:**\n${_expectedBehaviorController.text.trim()}';
        }
      }

      final newTicket = await service.createTicket(
        title: _titleController.text.trim(),
        description: fullDescription,
        type: _selectedType,
        priority: _selectedPriority,
      );

      // Upload attachments if any
      if (_attachments.isNotEmpty) {
        for (final file in _attachments) {
          try {
            // Use bytes if available (web), otherwise use path (native)
            if (file.bytes != null) {
              await service.uploadAttachment(
                newTicket.id,
                fileBytes: file.bytes!,
                fileName: file.name,
              );
            } else if (file.path != null) {
              await service.uploadAttachment(
                newTicket.id,
                filePath: file.path!,
                fileName: file.name,
              );
            }
          } catch (e) {
            // Log attachment upload error but don't fail the whole ticket
            debugPrint('Failed to upload attachment ${file.name}: $e');
          }
        }
      }

      ref.read(ticketsProvider.notifier).addTicket(newTicket);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit ticket: ${e.toString()}';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          minWidth: 400,
        ),
        child: IntrinsicHeight(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.support_agent,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Submit Support Ticket',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    color: Colors.red.withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        TextFormField(
                          controller: _titleController,
                          enabled: !_isSubmitting,
                          decoration: InputDecoration(
                            labelText: 'Title *',
                            hintText: 'Brief summary of your issue',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colorScheme.primary.withValues(alpha: 0.5),
                              ),
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            prefixIcon: Icon(
                              Icons.title,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            if (value.trim().length < 5) {
                              return 'Title must be at least 5 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Type and Priority Row
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<TicketType>(
                                initialValue: _selectedType,
                                onChanged: _isSubmitting ? null : (value) {
                                  if (value != null) {
                                    setState(() => _selectedType = value);
                                  }
                                },
                                decoration: InputDecoration(
                                  labelText: 'Type',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: colorScheme.outline.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: colorScheme.outline.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: colorScheme.primary.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                ),
                                items: TicketType.values.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getTypeIcon(type),
                                          size: 20,
                                          color: _getTypeColor(type),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(type.label),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: DropdownButtonFormField<TicketPriority>(
                                initialValue: _selectedPriority,
                                onChanged: _isSubmitting ? null : (value) {
                                  if (value != null) {
                                    setState(() => _selectedPriority = value);
                                  }
                                },
                                decoration: InputDecoration(
                                  labelText: 'Priority',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: colorScheme.outline.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: colorScheme.outline.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: colorScheme.primary.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                ),
                                items: TicketPriority.values.map((priority) {
                                  return DropdownMenuItem(
                                    value: priority,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _getPriorityColor(priority),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(priority.label),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          enabled: !_isSubmitting,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: 'Description *',
                            hintText: 'Please describe your issue in detail',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colorScheme.primary.withValues(alpha: 0.5),
                              ),
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            prefixIcon: Icon(
                              Icons.description,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a description';
                            }
                            if (value.trim().length < 20) {
                              return 'Description must be at least 20 characters';
                            }
                            return null;
                          },
                        ),

                        // Additional fields for bug reports
                        if (_selectedType == TicketType.bugReport) ...[
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _stepsToReproduceController,
                            enabled: !_isSubmitting,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Steps to Reproduce',
                              hintText: 'List the steps to reproduce this bug',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colorScheme.outline.withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colorScheme.outline.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colorScheme.primary.withValues(alpha: 0.5),
                                ),
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              prefixIcon: Icon(
                                Icons.format_list_numbered,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _expectedBehaviorController,
                            enabled: !_isSubmitting,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Expected Behavior',
                              hintText: 'What should happen instead?',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colorScheme.outline.withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colorScheme.outline.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colorScheme.primary.withValues(alpha: 0.5),
                                ),
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              prefixIcon: Icon(
                                Icons.check_circle_outline,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],

                        // Additional info for feature requests
                        if (_selectedType == TicketType.featureRequest) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Please describe the feature you\'d like to see and how it would help you.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Attachments Section
                        const SizedBox(height: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.attach_file,
                                  size: 20,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Attachments',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(Optional)',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Attachment chips
                            if (_attachments.isNotEmpty) ...[
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _attachments.map((file) {
                                  return Chip(
                                    avatar: Icon(
                                      _getFileIcon(file.name),
                                      size: 18,
                                      color: colorScheme.primary,
                                    ),
                                    label: Text(
                                      file.name,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    deleteIcon: const Icon(Icons.close, size: 18),
                                    onDeleted: _isSubmitting ? null : () {
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

                            // Add attachment button
                            OutlinedButton.icon(
                              onPressed: _isSubmitting ? null : _pickFiles,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Files'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.primary,
                                side: BorderSide(
                                  color: colorScheme.outline.withValues(alpha: 0.3),
                                ),
                              ),
                            ),

                            // File size hint
                            const SizedBox(height: 8),
                            Text(
                              'Max file size: 10MB. Supported: PDF, DOC, Images, Text files',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitTicket,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: Text(_isSubmitting ? 'Submitting...' : 'Submit Ticket'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
        // Check file sizes
        final validFiles = <PlatformFile>[];
        for (final file in result.files) {
          if (file.size > 10 * 1024 * 1024) { // 10MB limit
            if (!mounted) return;
            ref.read(notificationServiceProvider.notifier).showWarning('File "${file.name}" exceeds 10MB limit');
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
      ref.read(notificationServiceProvider.notifier).showError('Error picking files: $e');
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