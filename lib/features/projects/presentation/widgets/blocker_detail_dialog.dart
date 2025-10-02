import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/blocker.dart';
import '../../domain/entities/project.dart';
import '../providers/risks_tasks_provider.dart';
import '../../../queries/presentation/widgets/ask_ai_panel.dart';
import '../../../queries/presentation/providers/query_provider.dart';

class BlockerDetailDialog extends ConsumerStatefulWidget {
  final String projectId;
  final Blocker blocker;
  final Project? project;

  const BlockerDetailDialog({
    super.key,
    required this.projectId,
    required this.blocker,
    this.project,
  });

  @override
  ConsumerState<BlockerDetailDialog> createState() => _BlockerDetailDialogState();
}

class _BlockerDetailDialogState extends ConsumerState<BlockerDetailDialog> {
  late Blocker _editedBlocker;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _resolutionController;
  late TextEditingController _categoryController;
  late TextEditingController _ownerController;
  late TextEditingController _dependenciesController;
  late TextEditingController _assignedToController;
  late TextEditingController _assignedToEmailController;

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _editedBlocker = widget.blocker;
    _titleController = TextEditingController(text: _editedBlocker.title);
    _descriptionController = TextEditingController(text: _editedBlocker.description);
    _resolutionController = TextEditingController(text: _editedBlocker.resolution ?? '');
    _categoryController = TextEditingController(text: _editedBlocker.category ?? '');
    _ownerController = TextEditingController(text: _editedBlocker.owner ?? '');
    _dependenciesController = TextEditingController(text: _editedBlocker.dependencies ?? '');
    _assignedToController = TextEditingController(text: _editedBlocker.assignedTo ?? '');
    _assignedToEmailController = TextEditingController(text: _editedBlocker.assignedToEmail ?? '');
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
    return DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second, now.millisecond);
  }

  DateTime? _createTimezoneNaiveDate(DateTime? date) {
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _saveChanges() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedBlocker = _editedBlocker.copyWith(
        title: _titleController.text,
        description: _descriptionController.text,
        resolution: _resolutionController.text.isEmpty ? null : _resolutionController.text,
        category: _categoryController.text.isEmpty ? null : _categoryController.text,
        owner: _ownerController.text.isEmpty ? null : _ownerController.text,
        dependencies: _dependenciesController.text.isEmpty ? null : _dependenciesController.text,
        assignedTo: _assignedToController.text.isEmpty ? null : _assignedToController.text,
        assignedToEmail: _assignedToEmailController.text.isEmpty ? null : _assignedToEmailController.text,
        lastUpdated: _createTimezoneNaiveNow(),
        updatedBy: 'current_user', // TODO: Get from auth
        resolvedDate: _editedBlocker.status == BlockerStatus.resolved && widget.blocker.status != BlockerStatus.resolved
            ? _createTimezoneNaiveNow()
            : _editedBlocker.resolvedDate,
        escalationDate: _editedBlocker.status == BlockerStatus.escalated && widget.blocker.status != BlockerStatus.escalated
            ? _createTimezoneNaiveNow()
            : _editedBlocker.escalationDate,
      );

      final notifier = ref.read(blockersNotifierProvider(widget.projectId).notifier);
      await notifier.updateBlocker(updatedBlocker);

      if (mounted) {
        setState(() {
          _editedBlocker = updatedBlocker;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Blocker updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating blocker: $e')),
        );
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
      final notifier = ref.read(blockersNotifierProvider(widget.projectId).notifier);
      await notifier.deleteBlocker(_editedBlocker.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Blocker deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting blocker: $e')),
        );
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
      initialDate: _editedBlocker.targetDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null) {
      setState(() {
        _editedBlocker = _editedBlocker.copyWith(targetDate: _createTimezoneNaiveDate(date));
      });
    }
  }

  Future<void> _markAsResolved() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Show dialog to get resolution description
    final resolution = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String resolutionText = '';
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 450,
              minWidth: 350,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
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

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resolution Description *',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'How was this blocker resolved?',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
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
                                color: Colors.green.withValues(alpha: 0.5),
                              ),
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          ),
                          maxLines: 3,
                          onChanged: (value) => resolutionText = value,
                        ),
                      ],
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
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () => Navigator.of(dialogContext).pop(resolutionText),
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

    if (resolution == null || resolution.isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedBlocker = _editedBlocker.copyWith(
        status: BlockerStatus.resolved,
        resolution: resolution,
        resolvedDate: _createTimezoneNaiveNow(),
        lastUpdated: _createTimezoneNaiveNow(),
      );

      final notifier = ref.read(blockersNotifierProvider(widget.projectId).notifier);
      await notifier.updateBlocker(updatedBlocker);

      if (mounted) {
        setState(() {
          _editedBlocker = updatedBlocker;
          _resolutionController.text = resolution;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Blocker marked as resolved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating blocker: $e')),
        );
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
      buffer.writeln('- Target Date: ${blocker.targetDate!.toIso8601String().split('T')[0]}');
    }
    return buffer.toString();
  }

  void _openAIDialog() {
    final blockerContext = '''Context: Analyzing a blocker in the project.
Blocker Title: ${_editedBlocker.title}
${_buildBlockerContext(_editedBlocker)}''';

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
          conversationId: 'blocker_${_editedBlocker.id}',
          rightOffset: 0.0,
          onClose: () {
            Navigator.of(context).pop();
            ref.read(queryProvider.notifier).clearConversation();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: isMobile ? EdgeInsets.zero : const EdgeInsets.only(right: 100),
      child: Dialog(
      insetPadding: isMobile
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 24)
          : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 600,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          minWidth: isMobile ? 0 : 400,
        ),
        child: IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: isMobile
                  ? Row(
                      children: [
                        Icon(
                          Icons.block,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isEditing ? 'Edit Blocker' : 'Blocker Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!_isEditing) ...[
                          // Quick action buttons - mark resolved
                          if (_editedBlocker.status != BlockerStatus.resolved)
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                              ),
                              onPressed: _isSaving ? null : _markAsResolved,
                              tooltip: 'Mark as resolved',
                              iconSize: 20,
                            ),

                          // More actions menu
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            tooltip: 'More actions',
                            iconSize: 20,
                            offset: const Offset(0, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 8,
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  setState(() {
                                    _isEditing = true;
                                  });
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
                                    Icon(Icons.edit_outlined, size: 20, color: colorScheme.primary),
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

                          // AI Assistant button
                          IconButton(
                            onPressed: _openAIDialog,
                            icon: const Icon(Icons.auto_awesome),
                            tooltip: 'AI Assistant',
                            iconSize: 20,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.green.withValues(alpha: 0.1),
                              foregroundColor: Colors.green,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(
                          Icons.block,
                          color: colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isEditing ? 'Edit Blocker' : 'Blocker Details',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_editedBlocker.impactLabel} Impact • ${_editedBlocker.statusLabel}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_isEditing) ...[
                          // Quick Action Buttons
                          if (_editedBlocker.status != BlockerStatus.resolved)
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                              ),
                              onPressed: _isSaving ? null : _markAsResolved,
                              tooltip: 'Mark as resolved',
                            ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 24,
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: _isSaving
                                ? null
                                : () {
                                    setState(() {
                                      _isEditing = true;
                                    });
                                  },
                            tooltip: 'Edit blocker',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: _isSaving ? null : _deleteBlocker,
                            tooltip: 'Delete blocker',
                          ),
                          IconButton(
                            onPressed: _openAIDialog,
                            icon: const Icon(Icons.auto_awesome),
                            tooltip: 'AI Assistant',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.green.withValues(alpha: 0.1),
                              foregroundColor: Colors.green,
                            ),
                          ),
                        ],
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
                  padding: EdgeInsets.all(isMobile ? 12 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      if (_isEditing)
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Title',
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
                          style: theme.textTheme.titleMedium,
                        )
                      else
                        Text(
                          _editedBlocker.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      SizedBox(height: isMobile ? 16 : 20),

                      // Status and Impact Row
                      Flex(
                        direction: isMobile ? Axis.vertical : Axis.horizontal,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: isMobile ? 0 : 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status',
                                  style: theme.textTheme.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                if (_isEditing)
                                  DropdownButtonFormField<BlockerStatus>(
                                    initialValue: _editedBlocker.status,
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
                                        vertical: 8,
                                      ),
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
                                            Text(_editedBlocker.copyWith(status: status).statusLabel),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _editedBlocker = _editedBlocker.copyWith(
                                            status: value,
                                            resolvedDate: value == BlockerStatus.resolved
                                                ? _createTimezoneNaiveNow()
                                                : null,
                                            escalationDate: value == BlockerStatus.escalated
                                                ? _createTimezoneNaiveNow()
                                                : null,
                                          );
                                        });
                                      }
                                    },
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(_editedBlocker.status)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _getStatusColor(_editedBlocker.status),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(_editedBlocker.status),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _editedBlocker.statusLabel,
                                          style: TextStyle(
                                            color: _getStatusColor(_editedBlocker.status),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(width: isMobile ? 0 : 20, height: isMobile ? 12 : 0),
                          Expanded(
                            flex: isMobile ? 0 : 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Impact',
                                  style: theme.textTheme.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                if (_isEditing)
                                  DropdownButtonFormField<BlockerImpact>(
                                    initialValue: _editedBlocker.impact,
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
                                        vertical: 8,
                                      ),
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
                                            Text(_editedBlocker.copyWith(impact: impact).impactLabel),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _editedBlocker = _editedBlocker.copyWith(impact: value);
                                        });
                                      }
                                    },
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getImpactColor(_editedBlocker.impact)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.priority_high,
                                          size: 16,
                                          color: _getImpactColor(_editedBlocker.impact),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _editedBlocker.impactLabel,
                                          style: TextStyle(
                                            color: _getImpactColor(_editedBlocker.impact),
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

                      SizedBox(height: isMobile ? 16 : 20),

                      // Description
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          if (_isEditing)
                            TextField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                hintText: 'Enter blocker description...',
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
                              maxLines: 3,
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _editedBlocker.description,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                        ],
                      ),

                      // Resolution (if resolved)
                      if (_editedBlocker.status == BlockerStatus.resolved) ...[
                        SizedBox(height: isMobile ? 16 : 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resolution',
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            if (_isEditing)
                              TextField(
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
                                ),
                                maxLines: 2,
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _editedBlocker.resolution ?? 'No resolution provided',
                                  style: TextStyle(
                                    color: _editedBlocker.resolution == null
                                        ? colorScheme.onSurfaceVariant
                                        : null,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],

                      SizedBox(height: isMobile ? 16 : 20),

                      // Assignment Row (Assigned To and Category)
                      Flex(
                        direction: isMobile ? Axis.vertical : Axis.horizontal,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: isMobile ? 0 : 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assigned To',
                                  style: theme.textTheme.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                if (_isEditing)
                                  TextField(
                                    controller: _assignedToController,
                                    decoration: InputDecoration(
                                      hintText: 'Enter assignee name...',
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
                                        Icons.person,
                                        color: colorScheme.onSurfaceVariant,
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
                                          _editedBlocker.assignedTo ?? 'Unassigned',
                                          style: TextStyle(
                                            color: _editedBlocker.assignedTo == null
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
                          SizedBox(width: isMobile ? 0 : 20, height: isMobile ? 12 : 0),
                          Expanded(
                            flex: isMobile ? 0 : 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category',
                                  style: theme.textTheme.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                if (_isEditing)
                                  TextField(
                                    controller: _categoryController,
                                    decoration: InputDecoration(
                                      hintText: 'Enter category...',
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
                                        Icons.category,
                                        color: colorScheme.onSurfaceVariant,
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
                                          _editedBlocker.category ?? 'No category',
                                          style: TextStyle(
                                            color: _editedBlocker.category == null
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

                      SizedBox(height: isMobile ? 16 : 20),

                      // Target Date
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Date',
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          if (_isEditing)
                            InkWell(
                              onTap: _selectTargetDate,
                              child: InputDecorator(
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
                                  prefixIcon: Icon(
                                    Icons.calendar_today,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                child: Text(
                                  _editedBlocker.targetDate != null
                                      ? DateFormat('MMM d, y').format(_editedBlocker.targetDate!)
                                      : 'Select target date',
                                  style: TextStyle(
                                    color: _editedBlocker.targetDate == null
                                        ? colorScheme.onSurfaceVariant
                                        : null,
                                  ),
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
                                    Icons.calendar_today,
                                    size: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _editedBlocker.targetDate != null
                                        ? DateFormat('MMM d, y').format(_editedBlocker.targetDate!)
                                        : 'No target date',
                                    style: TextStyle(
                                      color: _editedBlocker.targetDate == null
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
                      if (_editedBlocker.dependencies != null && _editedBlocker.dependencies!.isNotEmpty || _isEditing) ...[
                        SizedBox(height: isMobile ? 16 : 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dependencies',
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            if (_isEditing)
                              TextField(
                                controller: _dependenciesController,
                                decoration: InputDecoration(
                                  hintText: 'List any dependencies...',
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
                                maxLines: 2,
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _editedBlocker.dependencies ?? 'No dependencies',
                                  style: TextStyle(
                                    color: _editedBlocker.dependencies == null
                                        ? colorScheme.onSurfaceVariant
                                        : null,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],

                      // Metadata
                      SizedBox(height: isMobile ? 16 : 20),
                      const Divider(),
                      SizedBox(height: isMobile ? 12 : 20),

                      Text(
                        'Metadata',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          if (_editedBlocker.identifiedDate != null)
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
                                  'Identified: ${DateFormat('MMM d, y').format(_editedBlocker.identifiedDate!)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          if (_editedBlocker.lastUpdated != null)
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
                                  'Updated: ${DateFormat('MMM d, y').format(_editedBlocker.lastUpdated!)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          if (_editedBlocker.resolvedDate != null)
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
                                  'Resolved: ${DateFormat('MMM d, y').format(_editedBlocker.resolvedDate!)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              if (_isEditing)
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
                        onPressed: _isSaving
                            ? null
                            : () {
                                setState(() {
                                  _isEditing = false;
                                  // Reset controllers
                                  _titleController.text = widget.blocker.title;
                                  _descriptionController.text = widget.blocker.description;
                                  _resolutionController.text = widget.blocker.resolution ?? '';
                                  _categoryController.text = widget.blocker.category ?? '';
                                  _ownerController.text = widget.blocker.owner ?? '';
                                  _dependenciesController.text = widget.blocker.dependencies ?? '';
                                  _assignedToController.text = widget.blocker.assignedTo ?? '';
                                  _assignedToEmailController.text = widget.blocker.assignedToEmail ?? '';
                                  _editedBlocker = widget.blocker;
                                });
                              },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Changes'),
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
}