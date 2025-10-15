import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/blocker.dart';
import '../../domain/entities/project.dart';
import '../providers/risks_tasks_provider.dart';
import '../providers/item_updates_provider.dart';
import '../../../queries/presentation/widgets/ask_ai_panel.dart';
import '../../../queries/presentation/providers/query_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/item_detail_panel.dart';
import '../../../../shared/widgets/item_updates_tab.dart';
import '../../domain/entities/item_update.dart' as domain;

class BlockerDetailPanel extends ConsumerStatefulWidget {
  final String projectId;
  final String? projectName;
  final Blocker? blocker; // null for creating new blocker
  final Project? project;
  final bool initiallyInEditMode;

  const BlockerDetailPanel({
    super.key,
    required this.projectId,
    this.projectName,
    this.blocker,
    this.project,
    this.initiallyInEditMode = false,
  });

  @override
  ConsumerState<BlockerDetailPanel> createState() => _BlockerDetailPanelState();
}

class _BlockerDetailPanelState extends ConsumerState<BlockerDetailPanel> {
  late Blocker? _editedBlocker;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _resolutionController;
  late TextEditingController _categoryController;
  late TextEditingController _ownerController;
  late TextEditingController _dependenciesController;
  late TextEditingController _assignedToController;
  late TextEditingController _assignedToEmailController;
  late BlockerImpact _selectedImpact;
  late BlockerStatus _selectedStatus;
  DateTime? _selectedTargetDate;

  bool _isEditing = false;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _editedBlocker = widget.blocker;
    _isEditing = widget.initiallyInEditMode || widget.blocker == null;

    _titleController = TextEditingController(text: _editedBlocker?.title ?? '');
    _descriptionController = TextEditingController(
      text: _editedBlocker?.description ?? '',
    );
    _resolutionController = TextEditingController(
      text: _editedBlocker?.resolution ?? '',
    );
    _categoryController = TextEditingController(
      text: _editedBlocker?.category ?? '',
    );
    _ownerController = TextEditingController(text: _editedBlocker?.owner ?? '');
    _dependenciesController = TextEditingController(
      text: _editedBlocker?.dependencies ?? '',
    );
    _assignedToController = TextEditingController(
      text: _editedBlocker?.assignedTo ?? '',
    );
    _assignedToEmailController = TextEditingController(
      text: _editedBlocker?.assignedToEmail ?? '',
    );
    _selectedImpact = _editedBlocker?.impact ?? BlockerImpact.high;
    _selectedStatus = _editedBlocker?.status ?? BlockerStatus.active;
    _selectedTargetDate = _editedBlocker?.targetDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _resolutionController.dispose();
    _categoryController.dispose();
    _ownerController.dispose();
    _dependenciesController.dispose();
    _assignedToController.dispose();
    _assignedToEmailController.dispose();
    super.dispose();
  }

  DateTime _createTimezoneNaiveNow() {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
    );
  }

  DateTime? _createTimezoneNaiveDate(DateTime? date) {
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day);
  }

  void _cancelEdit() {
    if (_editedBlocker == null) {
      // If creating new, close the panel
      Navigator.of(context).pop();
    } else {
      // If editing existing, just exit edit mode and reset values
      setState(() {
        _isEditing = false;
        _titleController.text = _editedBlocker!.title;
        _descriptionController.text = _editedBlocker!.description;
        _resolutionController.text = _editedBlocker!.resolution ?? '';
        _categoryController.text = _editedBlocker!.category ?? '';
        _ownerController.text = _editedBlocker!.owner ?? '';
        _dependenciesController.text = _editedBlocker!.dependencies ?? '';
        _assignedToController.text = _editedBlocker!.assignedTo ?? '';
        _assignedToEmailController.text = _editedBlocker!.assignedToEmail ?? '';
        _selectedImpact = _editedBlocker!.impact;
        _selectedStatus = _editedBlocker!.status;
        _selectedTargetDate = _editedBlocker!.targetDate;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (_titleController.text.trim().isEmpty) {
      ref
          .read(notificationServiceProvider.notifier)
          .showWarning('Title cannot be empty');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final blockerToSave = Blocker(
        id: _editedBlocker?.id ?? '',
        projectId: widget.projectId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        impact: _selectedImpact,
        status: _selectedStatus,
        resolution: _resolutionController.text.trim().isEmpty
            ? null
            : _resolutionController.text.trim(),
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        owner: _ownerController.text.trim().isEmpty
            ? null
            : _ownerController.text.trim(),
        dependencies: _dependenciesController.text.trim().isEmpty
            ? null
            : _dependenciesController.text.trim(),
        assignedTo: _assignedToController.text.trim().isEmpty
            ? null
            : _assignedToController.text.trim(),
        assignedToEmail: _assignedToEmailController.text.trim().isEmpty
            ? null
            : _assignedToEmailController.text.trim(),
        targetDate: _selectedTargetDate,
        resolvedDate: _selectedStatus == BlockerStatus.resolved
            ? (_editedBlocker?.resolvedDate ?? _createTimezoneNaiveNow())
            : null,
        escalationDate: _selectedStatus == BlockerStatus.escalated
            ? (_editedBlocker?.escalationDate ?? _createTimezoneNaiveNow())
            : null,
        identifiedDate:
            _editedBlocker?.identifiedDate ?? _createTimezoneNaiveNow(),
        lastUpdated: _createTimezoneNaiveNow(),
        updatedBy: 'current_user',
      );

      final notifier = ref.read(
        blockersNotifierProvider(widget.projectId).notifier,
      );

      if (_editedBlocker == null) {
        // Creating new blocker
        await notifier.addBlocker(blockerToSave);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Updating existing blocker
        await notifier.updateBlocker(blockerToSave);
        if (mounted) {
          // Refresh the updates provider to get the new updates
          final params = ItemUpdatesParams(
            projectId: widget.projectId,
            itemId: _editedBlocker!.id,
            itemType: 'blockers',
          );
          ref.invalidate(itemUpdatesNotifierProvider(params));

          setState(() {
            _editedBlocker = blockerToSave;
            _isEditing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ref
            .read(notificationServiceProvider.notifier)
            .showError('Error saving blocker: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteBlocker() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Blocker'),
        content: const Text('Are you sure you want to delete this blocker?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final notifier = ref.read(
        blockersNotifierProvider(widget.projectId).notifier,
      );
      await notifier.deleteBlocker(_editedBlocker!.id);

      if (mounted) {
        Navigator.of(context).pop();
        ref
            .read(notificationServiceProvider.notifier)
            .showSuccess('Blocker deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        ref
            .read(notificationServiceProvider.notifier)
            .showError('Error deleting blocker: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectTargetDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedTargetDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null) {
      setState(() {
        _selectedTargetDate = _createTimezoneNaiveDate(date);
      });
    }
  }

  Future<void> _markAsResolved() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final resolution = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String resolutionText = '';
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450, minWidth: 350),
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Mark as Resolved',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resolution Description *',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'How was this blocker resolved?',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: 3,
                          onChanged: (value) => resolutionText = value,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(resolutionText),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Mark as Resolved'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (resolution == null || resolution.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedBlocker = _editedBlocker!.copyWith(
        status: BlockerStatus.resolved,
        resolution: resolution,
        resolvedDate: _createTimezoneNaiveNow(),
        lastUpdated: _createTimezoneNaiveNow(),
      );

      final notifier = ref.read(
        blockersNotifierProvider(widget.projectId).notifier,
      );
      await notifier.updateBlocker(updatedBlocker);

      if (mounted) {
        // Refresh the updates provider to get the new updates
        final params = ItemUpdatesParams(
          projectId: widget.projectId,
          itemId: _editedBlocker!.id,
          itemType: 'blockers',
        );
        ref.invalidate(itemUpdatesNotifierProvider(params));

        setState(() {
          _editedBlocker = updatedBlocker;
          _resolutionController.text = resolution;
        });
      }
    } catch (e) {
      if (mounted) {
        ref
            .read(notificationServiceProvider.notifier)
            .showError('Error updating blocker: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _buildBlockerContext(Blocker blocker) {
    final buffer = StringBuffer();
    buffer.writeln('- Status: ${blocker.statusLabel}');
    buffer.writeln('- Impact: ${blocker.impactLabel}');
    buffer.writeln('- Description: ${blocker.description}');
    if (blocker.resolution != null && blocker.resolution!.isNotEmpty) {
      buffer.writeln('- Resolution: ${blocker.resolution}');
    }
    if (blocker.category != null && blocker.category!.isNotEmpty) {
      buffer.writeln('- Category: ${blocker.category}');
    }
    if (blocker.dependencies != null && blocker.dependencies!.isNotEmpty) {
      buffer.writeln('- Dependencies: ${blocker.dependencies}');
    }
    if (blocker.assignedTo != null && blocker.assignedTo!.isNotEmpty) {
      buffer.writeln('- Assigned to: ${blocker.assignedTo}');
    }
    if (blocker.targetDate != null) {
      buffer.writeln(
        '- Target Date: ${blocker.targetDate!.toIso8601String().split('T')[0]}',
      );
    }
    return buffer.toString();
  }

  void _openAIDialog() {
    final blockerContext =
        '''Context: Analyzing a blocker in the project.
Blocker Title: ${_editedBlocker!.title}
${_buildBlockerContext(_editedBlocker!)}''';

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AskAIPanel(
          projectId: widget.projectId,
          projectName: widget.project?.name ?? 'Project',
          contextInfo: blockerContext,
          conversationId: 'blocker_${_editedBlocker!.id}',
          rightOffset: 0.0,
          onClose: () {
            Navigator.of(context).pop();
            ref.read(queryProvider.notifier).clearConversation();
          },
        );
      },
    );
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

  Color _getStatusColor(BlockerStatus status) {
    switch (status) {
      case BlockerStatus.active:
        return Colors.orange;
      case BlockerStatus.resolved:
        return Colors.green;
      case BlockerStatus.pending:
        return Colors.grey;
      case BlockerStatus.escalated:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreating = _editedBlocker == null;

    return ItemDetailPanel(
      title: isCreating ? 'Create New Blocker' : (_editedBlocker?.title ?? 'Blocker'),
      subtitle: widget.projectName ?? widget.project?.name ?? 'Project',
      headerIcon: Icons.block,
      headerIconColor: _editedBlocker != null
          ? _getImpactColor(_editedBlocker!.impact)
          : Colors.red,
      onClose: () => Navigator.of(context).pop(),
      headerActions: _isEditing
          ? [
              // Edit mode actions
              TextButton(
                onPressed: _isSaving ? null : _cancelEdit,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveChanges,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save, size: 18),
                label: Text(
                  _isSaving ? 'Saving...' : (isCreating ? 'Create' : 'Save'),
                ),
              ),
            ]
          : [
              // View mode actions
              if (_editedBlocker != null &&
                  _editedBlocker!.status != BlockerStatus.resolved)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: _isSaving ? null : _markAsResolved,
                  tooltip: 'Mark as resolved',
                ),

              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'More actions',
                offset: const Offset(0, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      setState(() => _isEditing = true);
                      break;
                    case 'delete':
                      _deleteBlocker();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        const Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),

              if (_editedBlocker != null) ...[
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 24,
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 8),

                IconButton(
                  onPressed: _openAIDialog,
                  icon: const Icon(Icons.auto_awesome),
                  tooltip: 'AI Assistant',
                ),
              ],
            ],
      mainViewContent: _buildMainView(context),
      updatesContent: _buildUpdatesTab(),
    );
  }

  Widget _buildMainView(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title (only show in edit mode)
            if (_isEditing) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Title *',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Enter blocker title',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      prefixIcon: Icon(
                        Icons.label_outline,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Status and Impact Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isEditing)
                        DropdownButtonFormField<BlockerStatus>(
                          isExpanded: true,
                          initialValue: _selectedStatus,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          items: BlockerStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      status.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedStatus = value;
                              });
                            }
                          },
                        )
                      else if (_editedBlocker != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              _editedBlocker!.status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    _editedBlocker!.status,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _editedBlocker!.statusLabel,
                                style: TextStyle(
                                  color: _getStatusColor(
                                    _editedBlocker!.status,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                        'Impact',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isEditing)
                        DropdownButtonFormField<BlockerImpact>(
                          isExpanded: true,
                          initialValue: _selectedImpact,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          items: BlockerImpact.values.map((impact) {
                            return DropdownMenuItem(
                              value: impact,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.priority_high,
                                    size: 16,
                                    color: _getImpactColor(impact),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      impact.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
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
                        )
                      else if (_editedBlocker != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getImpactColor(
                              _editedBlocker!.impact,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.priority_high,
                                size: 16,
                                color: _getImpactColor(_editedBlocker!.impact),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _editedBlocker!.impactLabel,
                                style: TextStyle(
                                  color: _getImpactColor(
                                    _editedBlocker!.impact,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Description
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 12),
                if (_isEditing)
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Enter blocker description...',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                      contentPadding: const EdgeInsets.all(16),
                      prefixIcon: Icon(
                        Icons.description,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                    maxLines: 3,
                  )
                else if (_editedBlocker != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _editedBlocker!.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),

            // Resolution (if resolved)
            if (_editedBlocker != null &&
                _editedBlocker!.status == BlockerStatus.resolved) ...[
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resolution',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isEditing)
                    TextField(
                      controller: _resolutionController,
                      decoration: InputDecoration(
                        hintText: 'How was this blocker resolved?',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                        contentPadding: const EdgeInsets.all(16),
                        prefixIcon: Icon(
                          Icons.check_circle_outline,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          size: 20,
                        ),
                      ),
                      maxLines: 3,
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _editedBlocker!.resolution ?? 'No resolution provided',
                        style: TextStyle(
                          color: _editedBlocker!.resolution == null
                              ? colorScheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Assignment Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned To',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isEditing)
                        TextField(
                          controller: _assignedToController,
                          decoration: InputDecoration(
                            hintText: 'Enter assignee name...',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                            contentPadding: const EdgeInsets.all(16),
                            prefixIcon: Icon(
                              Icons.person,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              size: 20,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _editedBlocker!.assignedTo ?? 'Unassigned',
                                style: TextStyle(
                                  color: _editedBlocker!.assignedTo == null
                                      ? colorScheme.onSurfaceVariant
                                      : null,
                                ),
                              ),
                            ],
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
                        'Category',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isEditing)
                        TextField(
                          controller: _categoryController,
                          decoration: InputDecoration(
                            hintText: 'Enter category...',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                            contentPadding: const EdgeInsets.all(16),
                            prefixIcon: Icon(
                              Icons.category,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              size: 20,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.category,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _editedBlocker!.category ?? 'No category',
                                style: TextStyle(
                                  color: _editedBlocker!.category == null
                                      ? colorScheme.onSurfaceVariant
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Target Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target Date',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 12),
                if (_isEditing)
                  InkWell(
                    onTap: _selectTargetDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                        contentPadding: const EdgeInsets.all(16),
                        prefixIcon: Icon(
                          Icons.calendar_today,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          size: 20,
                        ),
                      ),
                      child: Text(
                        _selectedTargetDate != null
                            ? DateFormat('MMM d, y').format(_selectedTargetDate!)
                            : 'Select target date',
                        style: TextStyle(
                          color: _selectedTargetDate == null
                              ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                              : null,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _editedBlocker!.targetDate != null
                              ? DateFormat(
                                  'MMM d, y',
                                ).format(_editedBlocker!.targetDate!)
                              : 'No target date',
                          style: TextStyle(
                            color: _editedBlocker!.targetDate == null
                                ? colorScheme.onSurfaceVariant
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Dependencies (if exists)
            if ((_editedBlocker != null &&
                    _editedBlocker!.dependencies != null &&
                    _editedBlocker!.dependencies!.isNotEmpty) ||
                _isEditing) ...[
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dependencies',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isEditing)
                    TextField(
                      controller: _dependenciesController,
                      decoration: InputDecoration(
                        hintText: 'List any dependencies...',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                        contentPadding: const EdgeInsets.all(16),
                        prefixIcon: Icon(
                          Icons.link,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          size: 20,
                        ),
                      ),
                      maxLines: 2,
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _editedBlocker!.dependencies ?? 'No dependencies',
                        style: TextStyle(
                          color: _editedBlocker!.dependencies == null
                              ? colorScheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ],

            // Metadata (only show in view mode)
            if (!_isEditing && _editedBlocker != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              Text('Metadata', style: theme.textTheme.labelLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (_editedBlocker!.identifiedDate != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.create,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Identified: ${DateFormat('MMM d, y').format(_editedBlocker!.identifiedDate!)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  if (_editedBlocker!.lastUpdated != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.update,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Updated: ${DateFormat('MMM d, y').format(_editedBlocker!.lastUpdated!)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  if (_editedBlocker!.resolvedDate != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Resolved: ${DateFormat('MMM d, y').format(_editedBlocker!.resolvedDate!)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUpdatesTab() {
    if (_editedBlocker == null) {
      return _buildCreateModeEmptyState();
    }

    final params = ItemUpdatesParams(
      projectId: widget.projectId,
      itemId: _editedBlocker!.id,
      itemType: 'blockers',
    );

    final updatesAsync = ref.watch(itemUpdatesNotifierProvider(params));

    return updatesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading updates: $error'),
      ),
      data: (domainUpdates) {
        // Convert domain ItemUpdate to widget ItemUpdate
        final widgetUpdates = domainUpdates.map((domainUpdate) {
          return ItemUpdate(
            id: domainUpdate.id,
            content: domainUpdate.content,
            authorName: domainUpdate.authorName,
            timestamp: domainUpdate.timestamp,
            type: _convertDomainUpdateTypeToWidget(domainUpdate.type),
          );
        }).toList();

        return ItemUpdatesTab(
          updates: widgetUpdates,
          itemType: 'blocker',
          onAddComment: (content) async {
            try {
              await ref
                  .read(itemUpdatesNotifierProvider(params).notifier)
                  .addComment(content);
              // Success notification disabled per user request
            } catch (e) {
              if (mounted) {
                ref
                    .read(notificationServiceProvider.notifier)
                    .showError('Failed to add comment: $e');
              }
            }
          },
        );
      },
    );
  }

  // Helper method to convert domain ItemUpdateType to widget ItemUpdateType
  ItemUpdateType _convertDomainUpdateTypeToWidget(domain.ItemUpdateType type) {
    switch (type) {
      case domain.ItemUpdateType.comment:
        return ItemUpdateType.comment;
      case domain.ItemUpdateType.statusChange:
        return ItemUpdateType.statusChange;
      case domain.ItemUpdateType.assignment:
        return ItemUpdateType.assignment;
      case domain.ItemUpdateType.edit:
        return ItemUpdateType.edit;
      case domain.ItemUpdateType.created:
        return ItemUpdateType.created;
    }
  }

  Widget _buildCreateModeEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.4),
                    colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 32,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surface,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 48,
                    color: colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Create Blocker First',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Save this blocker to start tracking updates,\ncomments, and activity history',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFeatureHint(theme, colorScheme, Icons.comment_rounded, 'Comments', Colors.blue),
                const SizedBox(width: 24),
                _buildFeatureHint(theme, colorScheme, Icons.history_rounded, 'Activity', Colors.purple),
                const SizedBox(width: 24),
                _buildFeatureHint(theme, colorScheme, Icons.notifications_outlined, 'Updates', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureHint(ThemeData theme, ColorScheme colorScheme, IconData icon, String label, Color accentColor) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24, color: accentColor),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
