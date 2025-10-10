import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/presentation/providers/projects_provider.dart';

// Dialog constants matching create dialog
class _DialogConstants {
  static const double borderRadius = 12.0;
  static const double largeBorderRadius = 20.0;
  static const double padding = 20.0;
  static const double smallPadding = 16.0;
  static const double tinyPadding = 12.0;
  static const double spacing = 16.0;
  static const double smallSpacing = 8.0;

  // Opacity values
  static const double highOpacity = 0.3;
  static const double mediumOpacity = 0.2;
  static const double lowOpacity = 0.1;
  static const double minimalOpacity = 0.05;
}

class EditProjectDialog extends ConsumerStatefulWidget {
  final Project project;

  const EditProjectDialog({
    super.key,
    required this.project,
  });

  @override
  ConsumerState<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends ConsumerState<EditProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late ProjectStatus _selectedStatus;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descriptionController = TextEditingController(text: widget.project.description);
    _selectedStatus = widget.project.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(projectsListProvider.notifier).updateProject(
        widget.project.id,
        {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'status': _selectedStatus.name,
        },
      );

      // Invalidate the project detail provider to refresh the UI
      ref.invalidate(projectDetailProvider(widget.project.id));

      if (mounted) {
        Navigator.of(context).pop();
        ref.read(notificationServiceProvider.notifier).showSuccess(
          'Project "${_nameController.text}" updated successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          String errorMsg = e.toString();
          if (errorMsg.contains('already exists')) {
            _errorMessage = 'A project with this name already exists. Please choose a different name.';
          } else if (errorMsg.contains('409')) {
            _errorMessage = 'This project name is already taken. Please choose another name.';
          } else {
            _errorMessage = 'Failed to update project. Please try again.';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_DialogConstants.largeBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _DialogHeader(
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: _DialogConstants.padding,
                  vertical: _DialogConstants.padding,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Project Name Field
                      _StyledFormField(
                        controller: _nameController,
                        label: 'Project Name',
                        hint: 'Enter project name',
                        icon: Icons.work,
                        colorScheme: colorScheme,
                        enabled: !_isLoading,
                        autofocus: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a project name';
                          }
                          if (value.trim().length < 3) {
                            return 'Project name must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: _DialogConstants.spacing),

                      // Status Dropdown
                      _StatusDropdown(
                        value: _selectedStatus,
                        colorScheme: colorScheme,
                        enabled: !_isLoading,
                        onChanged: (status) {
                          if (status != null) {
                            setState(() => _selectedStatus = status);
                          }
                        },
                      ),
                      const SizedBox(height: _DialogConstants.spacing),

                      // Project Description Field
                      _StyledFormField(
                        controller: _descriptionController,
                        label: 'Description (Optional)',
                        hint: 'Enter project description',
                        icon: Icons.description,
                        colorScheme: colorScheme,
                        enabled: !_isLoading,
                        maxLines: 4,
                      ),

                      // Project Info Section
                      const SizedBox(height: _DialogConstants.spacing),
                      _ProjectInfoSection(
                        project: widget.project,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),

                      // Error Message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: _DialogConstants.spacing),
                        Container(
                          padding: const EdgeInsets.all(_DialogConstants.tinyPadding),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer.withValues(
                              alpha: _DialogConstants.mediumOpacity,
                            ),
                            borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
                            border: Border.all(
                              color: colorScheme.error.withValues(
                                alpha: _DialogConstants.highOpacity,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: _DialogConstants.smallSpacing),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: colorScheme.onErrorContainer,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Progress Indicator
                      if (_isLoading) ...[
                        const SizedBox(height: _DialogConstants.spacing),
                        const LinearProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            _DialogActions(
              isLoading: _isLoading,
              colorScheme: colorScheme,
              onCancel: () => Navigator.of(context).pop(),
              onSubmit: _updateProject,
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog Header Component
class _DialogHeader extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _DialogHeader({
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_DialogConstants.padding),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: _DialogConstants.highOpacity),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_DialogConstants.largeBorderRadius),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: _DialogConstants.lowOpacity),
              borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: _DialogConstants.spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Project',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Update project information and status',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: _DialogConstants.highOpacity,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Styled Form Field Component
class _StyledFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final ColorScheme colorScheme;
  final bool enabled;
  final bool autofocus;
  final int? maxLines;
  final String? Function(String?)? validator;

  const _StyledFormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.colorScheme,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      maxLines: maxLines,
      validator: validator,
      textCapitalization: maxLines == 1 ? TextCapitalization.words : TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(
          icon,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: _DialogConstants.mediumOpacity),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: _DialogConstants.mediumOpacity),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: _DialogConstants.lowOpacity),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: _DialogConstants.smallPadding,
          vertical: 14,
        ),
      ),
    );
  }
}

// Status Dropdown Component
class _StatusDropdown extends StatelessWidget {
  final ProjectStatus value;
  final ColorScheme colorScheme;
  final bool enabled;
  final Function(ProjectStatus?) onChanged;

  const _StatusDropdown({
    required this.value,
    required this.colorScheme,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ProjectStatus>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Project Status',
        prefixIcon: Icon(
          Icons.flag,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: _DialogConstants.mediumOpacity),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: _DialogConstants.mediumOpacity),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: _DialogConstants.lowOpacity),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: _DialogConstants.smallPadding,
          vertical: 14,
        ),
      ),
      items: ProjectStatus.values.map((status) {
        IconData icon;
        Color color;
        String label;

        switch (status) {
          case ProjectStatus.active:
            icon = Icons.play_circle_outline;
            color = Colors.green;
            label = 'Active';
            break;
          case ProjectStatus.archived:
            icon = Icons.archive_outlined;
            color = Colors.grey;
            label = 'Archived';
            break;
        }

        return DropdownMenuItem(
          value: status,
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }
}

// Project Info Section
class _ProjectInfoSection extends StatelessWidget {
  final Project project;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _ProjectInfoSection({
    required this.project,
    required this.colorScheme,
    required this.textTheme,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_DialogConstants.tinyPadding),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: _DialogConstants.minimalOpacity),
        borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: _DialogConstants.lowOpacity),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Information',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                'Created: ${_formatDate(project.createdAt)}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.update, size: 16, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                'Updated: ${_formatDate(project.updatedAt)}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          if (project.memberCount != null && project.memberCount! > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text(
                  'Members: ${project.memberCount}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// Dialog Actions Component
class _DialogActions extends StatelessWidget {
  final bool isLoading;
  final ColorScheme colorScheme;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const _DialogActions({
    required this.isLoading,
    required this.colorScheme,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_DialogConstants.padding),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: _DialogConstants.minimalOpacity),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(_DialogConstants.largeBorderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: isLoading ? null : onCancel,
            child: const Text('Cancel'),
          ),
          const SizedBox(width: _DialogConstants.smallSpacing),
          FilledButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Update Project'),
          ),
        ],
      ),
    );
  }
}