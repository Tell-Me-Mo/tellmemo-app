import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../projects/domain/entities/lesson_learned.dart';
import '../../../projects/presentation/providers/lessons_learned_provider.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../providers/aggregated_lessons_learned_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/item_detail_panel.dart';
import '../../../../shared/widgets/item_updates_tab.dart';
import '../../../queries/presentation/widgets/ask_ai_panel.dart';
import '../../../queries/presentation/providers/query_provider.dart';

class LessonLearnedDetailPanel extends ConsumerStatefulWidget {
  final String? projectId;
  final String? projectName;
  final LessonLearned? lesson; // null for creating new lesson
  final bool initiallyInEditMode;

  const LessonLearnedDetailPanel({
    super.key,
    this.projectId,
    this.projectName,
    this.lesson,
    this.initiallyInEditMode = false,
  }) : assert(lesson != null || (projectId != null && projectName != null),
              'Either lesson or both projectId and projectName must be provided');

  @override
  ConsumerState<LessonLearnedDetailPanel> createState() => _LessonLearnedDetailPanelState();
}

class _LessonLearnedDetailPanelState extends ConsumerState<LessonLearnedDetailPanel> {
  late LessonLearned? _lesson;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _recommendationController;
  late TextEditingController _contextController;
  late TextEditingController _tagsController;
  late LessonCategory _selectedCategory;
  late LessonType _selectedType;
  late LessonImpact _selectedImpact;
  late String? _selectedProjectId; // Track selected project
  bool _isEditing = false;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _lesson = widget.lesson;
    _isEditing = widget.initiallyInEditMode || widget.lesson == null;
    _selectedProjectId = _lesson?.projectId; // Don't default to widget.projectId

    _titleController = TextEditingController(text: _lesson?.title ?? '');
    _descriptionController = TextEditingController(text: _lesson?.description ?? '');
    _recommendationController = TextEditingController(text: _lesson?.recommendation ?? '');
    _contextController = TextEditingController(text: _lesson?.context ?? '');
    _tagsController = TextEditingController(text: _lesson?.tags.join(', ') ?? '');
    _selectedCategory = _lesson?.category ?? LessonCategory.other;
    _selectedType = _lesson?.lessonType ?? LessonType.improvement;
    _selectedImpact = _lesson?.impact ?? LessonImpact.medium;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _recommendationController.dispose();
    _contextController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing && _lesson != null) {
        // Reset form to current lesson values when entering edit mode
        _titleController.text = _lesson!.title;
        _descriptionController.text = _lesson!.description;
        _recommendationController.text = _lesson!.recommendation ?? '';
        _contextController.text = _lesson!.context ?? '';
        _tagsController.text = _lesson!.tags.join(', ');
        _selectedCategory = _lesson!.category;
        _selectedType = _lesson!.lessonType;
        _selectedImpact = _lesson!.impact;
      }
    });
  }

  void _cancelEdit() {
    if (_lesson == null) {
      // If creating new, close the panel
      Navigator.of(context).pop();
    } else {
      // If editing existing, just exit edit mode
      setState(() {
        _isEditing = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (_titleController.text.trim().isEmpty) {
      ref.read(notificationServiceProvider.notifier).showWarning('Title cannot be empty');
      return;
    }

    if (_selectedProjectId == null || _selectedProjectId!.isEmpty) {
      ref.read(notificationServiceProvider.notifier).showWarning('Please select a project');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final projectIdToUse = _selectedProjectId!;
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final lessonToSave = LessonLearned(
        id: _lesson?.id ?? '',
        projectId: projectIdToUse,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        lessonType: _selectedType,
        impact: _selectedImpact,
        recommendation: _recommendationController.text.trim().isEmpty
            ? null
            : _recommendationController.text.trim(),
        context: _contextController.text.trim().isEmpty
            ? null
            : _contextController.text.trim(),
        tags: tags,
        aiGenerated: _lesson?.aiGenerated ?? false,
        identifiedDate: _lesson?.identifiedDate ?? DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      final notifier = ref.read(lessonsLearnedNotifierProvider(projectIdToUse).notifier);

      if (_lesson == null) {
        // Creating new lesson
        await notifier.addLessonLearned(lessonToSave);
        ref.read(forceRefreshLessonsProvider)();
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Updating existing lesson
        await notifier.updateLessonLearned(lessonToSave);
        ref.read(forceRefreshLessonsProvider)();
        if (mounted) {
          setState(() {
            _lesson = lessonToSave;
            _isEditing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Error saving lesson: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteLessonLearned() async {
    if (_lesson == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson Learned'),
        content: const Text('Are you sure you want to delete this lesson learned?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final notifier = ref.read(lessonsLearnedNotifierProvider(_lesson!.projectId).notifier);
      await notifier.deleteLessonLearned(_lesson!.id);

      ref.read(forceRefreshLessonsProvider)();

      if (mounted) {
        Navigator.of(context).pop();
        ref.read(notificationServiceProvider.notifier).showSuccess('Lesson deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Failed to delete: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Color _getTypeColor(LessonType type) {
    switch (type) {
      case LessonType.success:
        return Colors.green;
      case LessonType.improvement:
        return Colors.orange;
      case LessonType.challenge:
        return Colors.red;
      case LessonType.bestPractice:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(LessonType type) {
    switch (type) {
      case LessonType.success:
        return Icons.check_circle;
      case LessonType.improvement:
        return Icons.trending_up;
      case LessonType.challenge:
        return Icons.warning;
      case LessonType.bestPractice:
        return Icons.star;
    }
  }

  Color _getImpactColor(LessonImpact impact) {
    switch (impact) {
      case LessonImpact.low:
        return Colors.blue;
      case LessonImpact.medium:
        return Colors.orange;
      case LessonImpact.high:
        return Colors.red;
    }
  }

  String _getCategoryLabel(LessonCategory category) {
    switch (category) {
      case LessonCategory.technical:
        return 'Technical';
      case LessonCategory.process:
        return 'Process';
      case LessonCategory.communication:
        return 'Communication';
      case LessonCategory.planning:
        return 'Planning';
      case LessonCategory.resource:
        return 'Resource';
      case LessonCategory.quality:
        return 'Quality';
      case LessonCategory.other:
        return 'Other';
    }
  }

  String _buildLessonContext(LessonLearned lesson) {
    final buffer = StringBuffer();
    buffer.writeln('- Type: ${lesson.lessonType.label}');
    buffer.writeln('- Category: ${_getCategoryLabel(lesson.category)}');
    buffer.writeln('- Impact: ${lesson.impact.label}');
    buffer.writeln('- Description: ${lesson.description}');
    if (lesson.recommendation != null && lesson.recommendation!.isNotEmpty) {
      buffer.writeln('- Recommendation: ${lesson.recommendation}');
    }
    if (lesson.context != null && lesson.context!.isNotEmpty) {
      buffer.writeln('- Context: ${lesson.context}');
    }
    if (lesson.tags.isNotEmpty) {
      buffer.writeln('- Tags: ${lesson.tags.join(', ')}');
    }
    return buffer.toString();
  }

  void _openAIDialog() {
    if (_lesson == null) return;

    final lesson = _lesson!;
    final lessonContext = '''Context: Analyzing a lesson learned in the project.
Lesson Title: ${lesson.title}
${_buildLessonContext(lesson)}''';

    final projectId = _selectedProjectId ?? widget.projectId!;
    final projectName = widget.projectName ?? 'Project';

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AskAIPanel(
          projectId: projectId,
          projectName: projectName,
          contextInfo: lessonContext,
          conversationId: 'lesson_${lesson.id}',
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
    final isCreating = _lesson == null;

    return ItemDetailPanel(
      title: isCreating ? 'Create New Lesson' : (_isEditing ? 'Edit Lesson' : 'Lesson Learned'),
      subtitle: widget.projectName ?? 'Project',
      headerIcon: Icons.lightbulb,
      headerIconColor: _lesson != null ? _getTypeColor(_lesson!.lessonType) : Colors.orange,
      onClose: () => Navigator.of(context).pop(),
      headerActions: _isEditing ? [
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
          label: Text(_isSaving ? 'Saving...' : (isCreating ? 'Create' : 'Save')),
        ),
      ] : [
        // View mode actions
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'More actions',
          offset: const Offset(0, 45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _toggleEditMode();
                break;
              case 'delete':
                _deleteLessonLearned();
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

        const SizedBox(width: 8),
        Container(
          width: 1,
          height: 24,
          color: colorScheme.outline.withValues(alpha: 0.2),
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
            // Title
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
                    hintText: 'Brief title of the lesson learned',
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
                      Icons.lightbulb_outline,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Project Selection (only when creating new lesson)
            if (_lesson == null) ...[
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
              const SizedBox(height: 24),
            ],

            // Type and Category Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Type',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<LessonType>(
                        initialValue: _selectedType,
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
                        items: LessonType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Icon(_getTypeIcon(type), size: 16, color: _getTypeColor(type)),
                                const SizedBox(width: 8),
                                Text(type.label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
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
                        'Category',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<LessonCategory>(
                        initialValue: _selectedCategory,
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
                        items: LessonCategory.values.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(_getCategoryLabel(category)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
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
                DropdownButtonFormField<LessonImpact>(
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
                  items: LessonImpact.values.map((impact) {
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
                          Text(impact.label),
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
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Detailed description of the lesson learned',
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recommendation
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommendation',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _recommendationController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'What should be done differently in the future?',
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
                      Icons.lightbulb_outline,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Context
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Context',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contextController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Additional context or background information',
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
                      Icons.info_outline,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tags
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tags',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    hintText: 'Comma-separated tags (e.g., deployment, testing, ui)',
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
                      Icons.label_outline,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainView(BuildContext context) {
    if (_lesson == null) {
      return const Center(child: Text('No lesson data available'));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lesson = _lesson!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            lesson.title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // Type, Category, and Impact Row
          Row(
            children: [
              // Type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getTypeColor(lesson.lessonType).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getTypeIcon(lesson.lessonType),
                              size: 16, color: _getTypeColor(lesson.lessonType)),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              lesson.lessonType.label,
                              style: TextStyle(
                                  color: _getTypeColor(lesson.lessonType), fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getCategoryLabel(lesson.category),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Impact
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Impact', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getImpactColor(lesson.impact).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(color: _getImpactColor(lesson.impact), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              lesson.impact.label,
                              style: TextStyle(color: _getImpactColor(lesson.impact), fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
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
              Text('Description', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(lesson.description),
              ),
            ],
          ),

          // Recommendation
          if (lesson.recommendation != null && lesson.recommendation!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recommendation', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(lesson.recommendation!),
                ),
              ],
            ),
          ],

          // Context
          if (lesson.context != null && lesson.context!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Context', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(lesson.context!),
                ),
              ],
            ),
          ],

          // Tags
          if (lesson.tags.isNotEmpty) ...[
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tags', style: theme.textTheme.labelLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: lesson.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.label, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            tag,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],

          // Metadata
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),

          Text('Metadata', style: theme.textTheme.labelLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (lesson.identifiedDate != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.create, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Identified: ${DateFormat('MMM d, y').format(lesson.identifiedDate!)}',
                      style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              if (lesson.lastUpdated != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.update, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Updated: ${DateFormat('MMM d, y').format(lesson.lastUpdated!)}',
                      style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
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
        content: 'Lesson learned documented',
        authorName: 'Current User',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: ItemUpdateType.created,
      ),
    ];

    return ItemUpdatesTab(
      updates: mockUpdates,
      itemType: 'lesson',
      onAddComment: (content) async {
        // TODO: Implement comment submission to backend
        ref.read(notificationServiceProvider.notifier).showSuccess('Comment added (not yet persisted)');
      },
    );
  }
}
