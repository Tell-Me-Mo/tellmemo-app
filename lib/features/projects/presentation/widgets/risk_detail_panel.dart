import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/risk.dart';
import '../../domain/entities/project.dart';
import '../providers/risks_tasks_provider.dart';
import '../providers/projects_provider.dart';
import '../../../queries/presentation/widgets/ask_ai_panel.dart';
import '../../../queries/presentation/providers/query_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/item_detail_panel.dart';
import '../../../../shared/widgets/item_updates_tab.dart';

class RiskDetailPanel extends ConsumerStatefulWidget {
  final String? projectId; // Make optional for when creating from global screen
  final Risk? risk; // null for creating new risk
  final Project? project;
  final bool initiallyInEditMode;

  const RiskDetailPanel({
    super.key,
    this.projectId,
    this.risk,
    this.project,
    this.initiallyInEditMode = false,
  });

  @override
  ConsumerState<RiskDetailPanel> createState() => _RiskDetailPanelState();
}

class _RiskDetailPanelState extends ConsumerState<RiskDetailPanel> {
  late Risk? _risk;
  bool _isEditing = false;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _mitigationController;
  late TextEditingController _impactController;
  late TextEditingController _probabilityController;
  late RiskSeverity _selectedSeverity;
  late RiskStatus _selectedStatus;
  late String? _selectedProjectId; // Track selected project

  @override
  void initState() {
    super.initState();
    _risk = widget.risk;
    _isEditing = widget.initiallyInEditMode || widget.risk == null;

    // Initialize form controllers
    _titleController = TextEditingController(text: widget.risk?.title ?? '');
    _descriptionController = TextEditingController(text: widget.risk?.description ?? '');
    _mitigationController = TextEditingController(text: widget.risk?.mitigation ?? '');
    _impactController = TextEditingController(text: widget.risk?.impact ?? '');
    _probabilityController = TextEditingController(text: widget.risk?.probability?.toString() ?? '0.5');
    _selectedSeverity = widget.risk?.severity ?? RiskSeverity.medium;
    _selectedStatus = widget.risk?.status ?? RiskStatus.identified;

    // Initialize selected project ID (only from existing risk, not from widget param)
    _selectedProjectId = widget.risk?.projectId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _mitigationController.dispose();
    _impactController.dispose();
    _probabilityController.dispose();
    super.dispose();
  }

  DateTime _createTimezoneNaiveNow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour, now.minute,
        now.second, now.millisecond);
  }

  Future<void> _markAsResolved() async {
    if (_risk == null || _selectedProjectId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedRisk = _risk!.copyWith(
        status: RiskStatus.resolved,
        lastUpdated: _createTimezoneNaiveNow(),
        updatedBy: 'current_user',
      );

      await ref
          .read(risksNotifierProvider(_selectedProjectId!).notifier)
          .updateRisk(updatedRisk);

      if (mounted) {
        setState(() {
          _risk = updatedRisk;
        });
      }
    } catch (e) {
      if (mounted) {
        ref
            .read(notificationServiceProvider.notifier)
            .showError('Failed to update risk: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _markAsMitigating() async {
    if (_risk == null || _selectedProjectId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedRisk = _risk!.copyWith(
        status: RiskStatus.mitigating,
        lastUpdated: _createTimezoneNaiveNow(),
        updatedBy: 'current_user',
      );

      await ref
          .read(risksNotifierProvider(_selectedProjectId!).notifier)
          .updateRisk(updatedRisk);

      if (mounted) {
        setState(() {
          _risk = updatedRisk;
        });
      }
    } catch (e) {
      if (mounted) {
        ref
            .read(notificationServiceProvider.notifier)
            .showError('Failed to update risk: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _markAsIdentified() async {
    if (_risk == null || _selectedProjectId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedRisk = _risk!.copyWith(
        status: RiskStatus.identified,
        lastUpdated: _createTimezoneNaiveNow(),
        updatedBy: 'current_user',
      );

      await ref
          .read(risksNotifierProvider(_selectedProjectId!).notifier)
          .updateRisk(updatedRisk);

      if (mounted) {
        setState(() {
          _risk = updatedRisk;
        });
      }
    } catch (e) {
      if (mounted) {
        ref
            .read(notificationServiceProvider.notifier)
            .showError('Failed to update risk: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteRisk() async {
    if (_risk == null || _selectedProjectId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Risk'),
        content: const Text(
            'Are you sure you want to delete this risk? This action cannot be undone.'),
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
      await ref
          .read(risksNotifierProvider(_selectedProjectId!).notifier)
          .deleteRisk(_risk!.id);

      if (mounted) {
        Navigator.of(context).pop();
        ref
            .read(notificationServiceProvider.notifier)
            .showSuccess('Risk deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        ref
            .read(notificationServiceProvider.notifier)
            .showError('Failed to delete risk: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing && _risk != null) {
        // Reset form to current risk values when entering edit mode
        _titleController.text = _risk!.title;
        _descriptionController.text = _risk!.description;
        _mitigationController.text = _risk!.mitigation ?? '';
        _impactController.text = _risk!.impact ?? '';
        _probabilityController.text = _risk!.probability?.toString() ?? '0.5';
        _selectedSeverity = _risk!.severity;
        _selectedStatus = _risk!.status;
      }
    });
  }

  void _cancelEdit() {
    if (_risk == null) {
      // If creating new, close the panel
      Navigator.of(context).pop();
    } else {
      // If editing existing, just exit edit mode
      setState(() {
        _isEditing = false;
      });
    }
  }

  Future<void> _saveRisk() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProjectId == null || _selectedProjectId!.isEmpty) {
      ref.read(notificationServiceProvider.notifier).showWarning('Please select a project');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final probability = double.tryParse(_probabilityController.text.trim()) ?? 0.5;

      final riskToSave = Risk(
        id: _risk?.id ?? '',
        projectId: _selectedProjectId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        severity: _selectedSeverity,
        status: _selectedStatus,
        probability: probability,
        impact: _impactController.text.trim().isEmpty ? null : _impactController.text.trim(),
        mitigation: _mitigationController.text.trim().isEmpty ? null : _mitigationController.text.trim(),
        identifiedDate: _risk?.identifiedDate ?? _createTimezoneNaiveNow(),
        lastUpdated: _createTimezoneNaiveNow(),
        updatedBy: 'current_user',
      );

      final notifier = ref.read(risksNotifierProvider(_selectedProjectId!).notifier);

      if (_risk == null) {
        // Creating new risk
        await notifier.addRisk(riskToSave);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Updating existing risk
        await notifier.updateRisk(riskToSave);
        if (mounted) {
          setState(() {
            _risk = riskToSave;
            _isEditing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Failed to save risk: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _buildRiskContext(Risk risk) {
    final buffer = StringBuffer();
    buffer.writeln('- Status: ${risk.statusLabel}');
    buffer.writeln('- Severity: ${risk.severityLabel}');
    buffer.writeln('- Description: ${risk.description}');
    if (risk.mitigation != null && risk.mitigation!.isNotEmpty) {
      buffer.writeln('- Mitigation: ${risk.mitigation}');
    }
    if (risk.impact != null && risk.impact!.isNotEmpty) {
      buffer.writeln('- Impact: ${risk.impact}');
    }
    if (risk.probability != null) {
      buffer.writeln(
          '- Probability: ${(risk.probability! * 100).toStringAsFixed(0)}%');
    }
    if (risk.assignedTo != null && risk.assignedTo!.isNotEmpty) {
      buffer.writeln('- Assigned to: ${risk.assignedTo}');
    }
    return buffer.toString();
  }

  void _openAIDialog() {
    if (_risk == null) return;

    final risk = _risk!;
    final riskContext = '''Context: Analyzing a risk in the project.
Risk Title: ${risk.title}
${_buildRiskContext(risk)}''';

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AskAIPanel(
          projectId: _selectedProjectId!,
          projectName: widget.project?.name ?? 'Project',
          contextInfo: riskContext,
          conversationId: 'risk_${risk.id}',
          rightOffset: 0.0,
          onClose: () {
            Navigator.of(context).pop();
            ref.read(queryProvider.notifier).clearConversation();
          },
        );
      },
    );
  }

  Color _getStatusColor(RiskStatus status) {
    switch (status) {
      case RiskStatus.identified:
        return Colors.orange;
      case RiskStatus.mitigating:
        return Colors.blue;
      case RiskStatus.resolved:
        return Colors.green;
      case RiskStatus.accepted:
        return Colors.grey;
      case RiskStatus.escalated:
        return Colors.red;
    }
  }

  Color _getSeverityColor(RiskSeverity severity) {
    switch (severity) {
      case RiskSeverity.low:
        return Colors.green;
      case RiskSeverity.medium:
        return Colors.orange;
      case RiskSeverity.high:
        return Colors.red;
      case RiskSeverity.critical:
        return Colors.red.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreating = _risk == null;

    // Get project name from either widget.project or fetch using projectId
    final effectiveProjectId = _selectedProjectId ?? widget.projectId ?? _risk?.projectId;
    String projectName = widget.project?.name ?? 'Project';

    if (widget.project == null && effectiveProjectId != null) {
      final projectsAsync = ref.watch(projectsListProvider);
      projectsAsync.whenData((projects) {
        final project = projects.firstWhere(
          (p) => p.id == effectiveProjectId,
          orElse: () => projects.first,
        );
        projectName = project.name;
      });
    }

    return ItemDetailPanel(
      title: isCreating ? 'Create New Risk' : (_isEditing ? 'Edit Risk' : 'Risk Details'),
      subtitle: projectName,
      headerIcon: Icons.warning,
      headerIconColor: _isEditing ? Colors.orange : (_risk != null ? _getSeverityColor(_risk!.severity) : Colors.orange),
      onClose: () => Navigator.of(context).pop(),
      headerActions: _isEditing ? [
        // Edit mode actions
        TextButton(
          onPressed: _isSaving ? null : _cancelEdit,
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveRisk,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save, size: 18),
          label: Text(_isSaving ? 'Saving...' : (isCreating ? 'Create' : 'Save')),
        ),
      ] : [
        // View mode actions
        // Quick Status Buttons
        if (_risk!.status == RiskStatus.identified)
          IconButton(
            icon: const Icon(Icons.engineering),
            onPressed: _isSaving ? null : _markAsMitigating,
            tooltip: 'Start mitigating',
          ),
        if (_risk!.status == RiskStatus.mitigating)
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: _isSaving ? null : _markAsResolved,
            tooltip: 'Mark as resolved',
          ),
        if (_risk!.status == RiskStatus.resolved)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isSaving ? null : _markAsIdentified,
            tooltip: 'Reactivate risk',
          ),

        // More actions menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'More actions',
          offset: const Offset(0, 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _toggleEditMode();
                break;
              case 'delete':
                _deleteRisk();
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined,
                      size: 20, color: Theme.of(context).colorScheme.primary),
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

        const SizedBox(width: 8),
        Container(
          width: 1,
          height: 24,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        const SizedBox(width: 8),

        // AI Assistant button
        IconButton(
          onPressed: _openAIDialog,
          icon: const Icon(Icons.auto_awesome),
          tooltip: 'AI Assistant',
        ),
      ],
      mainViewContent: _isEditing ? _buildEditView(context) : _buildMainView(context),
      updatesContent: _buildUpdatesTab(),
    );
  }

  Widget _buildEditView(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Selection (only show when creating NEW risk)
            if (_risk == null) ...[
              Consumer(
                builder: (context, ref, child) {
                  final projectsAsync = ref.watch(projectsListProvider);
                  return projectsAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stack) => Text('Error loading projects: $error'),
                    data: (projects) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Project *',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedProjectId,
                          decoration: InputDecoration(
                            hintText: 'Select a project',
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
                              Icons.folder_outlined,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              size: 20,
                            ),
                          ),
                          items: projects.map((project) {
                            return DropdownMenuItem(
                              value: project.id,
                              child: Text(project.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedProjectId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a project';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],

            // Title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Risk Title *',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Brief description of the risk',
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

            // Description
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description *',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Detailed description of the risk',
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
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Severity and Status Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Severity',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<RiskSeverity>(
                        initialValue: _selectedSeverity,
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                    items: RiskSeverity.values.map((severity) {
                      return DropdownMenuItem(
                        value: severity,
                        child: Row(
                          children: [
                            Icon(Icons.flag, size: 16, color: _getSeverityColor(severity)),
                            const SizedBox(width: 8),
                            Text(severity.toString().split('.').last),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSeverity = value;
                        });
                      }
                    },
                  ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
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
                      DropdownButtonFormField<RiskStatus>(
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                    items: RiskStatus.values.map((status) {
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
                            Text(status.toString().split('.').last),
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
                  ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Probability
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Probability (0.0 - 1.0)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _probabilityController,
                  decoration: InputDecoration(
                    hintText: 'e.g., 0.5 for 50%',
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
                      Icons.percent,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final prob = double.tryParse(value);
                      if (prob == null || prob < 0 || prob > 1) {
                        return 'Probability must be between 0.0 and 1.0';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Impact
            Column(
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
                TextFormField(
                  controller: _impactController,
                  decoration: InputDecoration(
                    hintText: 'Potential impact if risk occurs',
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
                      Icons.trending_up,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Mitigation
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mitigation Strategy',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mitigationController,
                  decoration: InputDecoration(
                    hintText: 'How to mitigate or prevent this risk',
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
                      Icons.shield_outlined,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainView(BuildContext context) {
    if (_risk == null) {
      return const Center(child: Text('No risk data available'));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final risk = _risk!; // Safe to use! since we checked above

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            risk.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // Status and Severity Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(risk.status)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getStatusColor(risk.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            risk.statusLabel,
                            style: TextStyle(
                              color: _getStatusColor(risk.status),
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
                      'Severity',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(risk.severity)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag,
                            size: 16,
                            color: _getSeverityColor(risk.severity),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            risk.severityLabel,
                            style: TextStyle(
                              color: _getSeverityColor(risk.severity),
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

          const SizedBox(height: 20),

          // Description
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(risk.description),
              ),
            ],
          ),

          // Mitigation
          if (risk.mitigation != null && risk.mitigation!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mitigation Strategy',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(risk.mitigation!),
                ),
              ],
            ),
          ],

          // Impact
          if (risk.impact != null && risk.impact!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Impact',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(risk.impact!),
                ),
              ],
            ),
          ],

          // Probability
          if (risk.probability != null) ...[
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Probability',
                      style: theme.textTheme.labelLarge,
                    ),
                    Text(
                      '${(risk.probability! * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getSeverityColor(risk.severity),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: risk.probability!,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  color: _getSeverityColor(risk.severity),
                  backgroundColor:
                      _getSeverityColor(risk.severity).withValues(alpha: 0.2),
                ),
              ],
            ),
          ],

          // Assignment
          if (risk.assignedTo != null || risk.assignedToEmail != null) ...[
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assignment',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (risk.assignedTo != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(risk.assignedTo!),
                          ],
                        ),
                      ],
                      if (risk.assignedToEmail != null) ...[
                        if (risk.assignedTo != null) const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.email,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(risk.assignedToEmail!),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],

          // Metadata
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),

          Text(
            'Metadata',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (risk.identifiedDate != null)
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
                      'Identified: ${DateFormat('MMM d, y').format(risk.identifiedDate!)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              if (risk.lastUpdated != null)
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
                      'Updated: ${DateFormat('MMM d, y').format(risk.lastUpdated!)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatesTab() {
    // TODO: Replace with actual updates from backend when API is ready
    final mockUpdates = <ItemUpdate>[
      ItemUpdate(
        id: '1',
        content: 'Risk created and assigned to team lead',
        authorName: 'Current User',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        type: ItemUpdateType.created,
      ),
    ];

    return ItemUpdatesTab(
      updates: mockUpdates,
      itemType: 'risk',
      onAddComment: (content) async {
        // TODO: Implement comment submission to backend
        ref
            .read(notificationServiceProvider.notifier)
            .showSuccess('Comment added (not yet persisted)');
      },
    );
  }
}
