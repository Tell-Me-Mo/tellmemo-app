import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/blocker.dart';
import '../providers/risks_tasks_provider.dart';
import '../../../../core/services/notification_service.dart';

class BlockerDialog extends ConsumerStatefulWidget {
  final String projectId;
  final Blocker? blocker; // null for add, existing blocker for edit

  const BlockerDialog({
    super.key,
    required this.projectId,
    this.blocker,
  });

  @override
  ConsumerState<BlockerDialog> createState() => _BlockerDialogState();
}

class _BlockerDialogState extends ConsumerState<BlockerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _resolutionController = TextEditingController();
  final _ownerController = TextEditingController();
  final _assignedToController = TextEditingController();
  final _categoryController = TextEditingController();
  final _dependenciesController = TextEditingController();

  BlockerImpact _selectedImpact = BlockerImpact.high;
  BlockerStatus _selectedStatus = BlockerStatus.active;
  DateTime? _selectedTargetDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.blocker != null) {
      _titleController.text = widget.blocker!.title;
      _descriptionController.text = widget.blocker!.description;
      _resolutionController.text = widget.blocker!.resolution ?? '';
      _ownerController.text = widget.blocker!.owner ?? '';
      _assignedToController.text = widget.blocker!.assignedTo ?? '';
      _categoryController.text = widget.blocker!.category ?? '';
      _dependenciesController.text = widget.blocker!.dependencies ?? '';
      _selectedImpact = widget.blocker!.impact;
      _selectedStatus = widget.blocker!.status;
      _selectedTargetDate = _createTimezoneNaiveDate(widget.blocker!.targetDate);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _resolutionController.dispose();
    _ownerController.dispose();
    _assignedToController.dispose();
    _categoryController.dispose();
    _dependenciesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.blocker != null;
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
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.block,
                        color: Colors.red,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Blocker' : 'Create New Blocker',
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
                          decoration: InputDecoration(
                            labelText: 'Blocker Title *',
                            hintText: 'Brief description of the blocker',
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
                              return 'Title is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description *',
                            hintText: 'Detailed description of the blocker',
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
                            alignLabelWithHint: true,
                            prefixIcon: Icon(
                              Icons.description,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Description is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Impact and Status
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Impact',
                                    style: theme.textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<BlockerImpact>(
                                    initialValue: _selectedImpact,
                                    decoration: InputDecoration(
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
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                    items: BlockerImpact.values.map((impact) {
                                      return DropdownMenuItem(
                                        value: impact,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: _getImpactColor(impact),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(_getImpactLabel(impact)),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedImpact = value;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status',
                                    style: theme.textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<BlockerStatus>(
                                    initialValue: _selectedStatus,
                                    decoration: InputDecoration(
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
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                    items: BlockerStatus.values.map((status) {
                                      return DropdownMenuItem(
                                        value: status,
                                        child: Text(_getStatusLabel(status)),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedStatus = value;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Owner and Assigned To
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Owner',
                                    style: theme.textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _ownerController,
                                    decoration: InputDecoration(
                                      hintText: 'Who owns this blocker',
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
                                        Icons.person_outline,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Assigned To',
                                    style: theme.textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _assignedToController,
                                    decoration: InputDecoration(
                                      hintText: 'Who is resolving this',
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
                                        Icons.assignment_ind_outlined,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Target Date
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target Resolution Date',
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _selectTargetDate(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: colorScheme.outline.withValues(alpha: 0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _selectedTargetDate != null
                                          ? _formatDate(_selectedTargetDate!)
                                          : 'Select target date',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: _selectedTargetDate != null
                                            ? colorScheme.onSurface
                                            : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (_selectedTargetDate != null)
                                      IconButton(
                                        icon: const Icon(Icons.clear, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            _selectedTargetDate = null;
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Category
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category',
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _categoryController,
                              decoration: InputDecoration(
                                hintText: 'e.g., Technical, Process, External',
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
                                  Icons.category_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Dependencies
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dependencies',
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _dependenciesController,
                              decoration: InputDecoration(
                                hintText: 'What this blocker depends on or blocks',
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
                                alignLabelWithHint: true,
                                prefixIcon: Icon(
                                  Icons.link,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),

                        // Resolution (only show if status is resolved)
                        if (_selectedStatus == BlockerStatus.resolved) ...[
                          const SizedBox(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Resolution',
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _resolutionController,
                                decoration: InputDecoration(
                                  hintText: 'How was this blocker resolved?',
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
                                  alignLabelWithHint: true,
                                  prefixIcon: Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green,
                                  ),
                                ),
                                maxLines: 3,
                                validator: (value) {
                                  if (_selectedStatus == BlockerStatus.resolved &&
                                      (value == null || value.trim().isEmpty)) {
                                    return 'Resolution is required when status is resolved';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ],
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
                      if (isEditing) ...[
                        TextButton.icon(
                          onPressed: _isLoading ? null : _showDeleteConfirmation,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                        ),
                        const Spacer(),
                      ],
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveBlocker,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(isEditing ? Icons.save : Icons.add),
                        label: Text(_isLoading
                            ? (isEditing ? 'Updating...' : 'Creating...')
                            : (isEditing ? 'Update Blocker' : 'Create Blocker')),
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

  Future<void> _selectTargetDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedTargetDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        _selectedTargetDate = _createTimezoneNaiveDate(picked);
      });
    }
  }

  Future<void> _saveBlocker() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final blocker = Blocker(
        id: widget.blocker?.id ?? '',
        projectId: widget.projectId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        impact: _selectedImpact,
        status: _selectedStatus,
        resolution: _resolutionController.text.trim().isEmpty
            ? null
            : _resolutionController.text.trim(),
        owner: _ownerController.text.trim().isEmpty
            ? null
            : _ownerController.text.trim(),
        assignedTo: _assignedToController.text.trim().isEmpty
            ? null
            : _assignedToController.text.trim(),
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        dependencies: _dependenciesController.text.trim().isEmpty
            ? null
            : _dependenciesController.text.trim(),
        targetDate: _createTimezoneNaiveDate(_selectedTargetDate),
        resolvedDate: _selectedStatus == BlockerStatus.resolved
            ? (widget.blocker?.resolvedDate ?? _createTimezoneNaiveNow())
            : null,
        escalationDate: _selectedStatus == BlockerStatus.escalated
            ? (widget.blocker?.escalationDate ?? _createTimezoneNaiveNow())
            : null,
        identifiedDate: widget.blocker?.identifiedDate ?? _createTimezoneNaiveNow(),
        lastUpdated: _createTimezoneNaiveNow(),
      );

      final notifier = ref.read(blockersNotifierProvider(widget.projectId).notifier);

      if (widget.blocker == null) {
        await notifier.addBlocker(blocker);
      } else {
        await notifier.updateBlocker(blocker);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Blocker'),
        content: const Text('Are you sure you want to delete this blocker? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.blocker != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final notifier = ref.read(blockersNotifierProvider(widget.projectId).notifier);
        await notifier.deleteBlocker(widget.blocker!.id);

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ref.read(notificationServiceProvider.notifier).showError('Error deleting blocker: $e');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Color _getImpactColor(BlockerImpact impact) {
    switch (impact) {
      case BlockerImpact.low:
        return Colors.blue;
      case BlockerImpact.medium:
        return Colors.orange;
      case BlockerImpact.high:
        return Colors.deepOrange;
      case BlockerImpact.critical:
        return Colors.red;
    }
  }

  String _getImpactLabel(BlockerImpact impact) {
    switch (impact) {
      case BlockerImpact.low:
        return 'Low';
      case BlockerImpact.medium:
        return 'Medium';
      case BlockerImpact.high:
        return 'High';
      case BlockerImpact.critical:
        return 'Critical';
    }
  }

  String _getStatusLabel(BlockerStatus status) {
    switch (status) {
      case BlockerStatus.active:
        return 'Active';
      case BlockerStatus.resolved:
        return 'Resolved';
      case BlockerStatus.pending:
        return 'Pending';
      case BlockerStatus.escalated:
        return 'Escalated';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  DateTime _createTimezoneNaiveNow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second, now.millisecond);
  }

  DateTime? _createTimezoneNaiveDate(DateTime? date) {
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day);
  }
}