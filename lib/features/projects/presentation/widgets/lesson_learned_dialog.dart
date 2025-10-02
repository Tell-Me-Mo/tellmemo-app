import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/lesson_learned.dart';
import '../providers/lessons_learned_provider.dart';
import '../providers/projects_provider.dart';
import '../../../lessons_learned/presentation/providers/aggregated_lessons_learned_provider.dart';

class LessonLearnedDialog extends ConsumerStatefulWidget {
  final String? projectId;
  final String? projectName;
  final LessonLearned? lesson;

  const LessonLearnedDialog({
    super.key,
    this.projectId,
    this.projectName,
    this.lesson,
  });

  @override
  ConsumerState<LessonLearnedDialog> createState() => _LessonLearnedDialogState();
}

class _LessonLearnedDialogState extends ConsumerState<LessonLearnedDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _recommendationController;
  late final TextEditingController _contextController;
  late final TextEditingController _tagsController;

  late LessonCategory _selectedCategory;
  late LessonType _selectedType;
  late LessonImpact _selectedImpact;
  String? _selectedProjectId;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isEditing => widget.lesson != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.lesson?.title ?? '');
    _descriptionController = TextEditingController(text: widget.lesson?.description ?? '');
    _recommendationController = TextEditingController(text: widget.lesson?.recommendation ?? '');
    _contextController = TextEditingController(text: widget.lesson?.context ?? '');
    _tagsController = TextEditingController(text: widget.lesson?.tags.join(', ') ?? '');

    _selectedCategory = widget.lesson?.category ?? LessonCategory.other;
    _selectedType = widget.lesson?.lessonType ?? LessonType.improvement;
    _selectedImpact = widget.lesson?.impact ?? LessonImpact.medium;
    _selectedProjectId = widget.projectId ?? widget.lesson?.projectId;
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

  Future<void> _saveLessonLearned() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProjectId == null || _selectedProjectId!.isEmpty) {
      setState(() {
        _errorMessage = 'Please select a project';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final lesson = LessonLearned(
        id: widget.lesson?.id ?? '',
        projectId: _selectedProjectId!,
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
        aiGenerated: false,
      );

      final notifier = ref.read(lessonsLearnedNotifierProvider(_selectedProjectId!).notifier);

      if (isEditing) {
        await notifier.updateLessonLearned(lesson);
      } else {
        await notifier.addLessonLearned(lesson);
      }

      // Force refresh the aggregated lessons (clear cache and invalidate)
      ref.read(forceRefreshLessonsProvider)();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteLessonLearned() async {
    if (!isEditing || widget.lesson == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson Learned'),
        content: const Text('Are you sure you want to delete this lesson learned?'),
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

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notifier = ref.read(lessonsLearnedNotifierProvider(_selectedProjectId!).notifier);
      await notifier.deleteLessonLearned(widget.lesson!.id);

      // Force refresh the aggregated lessons (clear cache and invalidate)
      ref.read(forceRefreshLessonsProvider)();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to delete: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: isMobile ? EdgeInsets.zero : const EdgeInsets.only(right: 100), // Add padding to push dialog left on desktop
      child: Dialog(
      insetPadding: isMobile
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 24)
          : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 500,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          minWidth: isMobile ? 0 : 400,
        ),
        child: IntrinsicHeight(
          child: Form(
            key: _formKey,
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
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: colorScheme.primary,
                        size: isMobile ? 20 : 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Lesson Learned' : 'Create New Lesson',
                          style: (isMobile ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.lesson?.aiGenerated == true) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                'AI',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        iconSize: isMobile ? 20 : 24,
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
                    padding: EdgeInsets.all(isMobile ? 12 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Selection
                    Consumer(
                      builder: (context, ref, child) {
                        final projectsAsync = ref.watch(projectsListProvider);
                        return projectsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => Text('Error loading projects: $error'),
                          data: (projects) => DropdownButtonFormField<String>(
                            value: _selectedProjectId,
                            decoration: InputDecoration(
                              labelText: 'Project *',
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
                                Icons.folder,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            items: projects.map((project) {
                              return DropdownMenuItem(
                                value: project.id,
                                child: Text(project.name),
                              );
                            }).toList(),
                            onChanged: _isLoading ? null : (value) {
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
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'Title *',
                        hintText: 'Brief title of the lesson learned',
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
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Type and Category Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<LessonType>(
                            value: _selectedType,
                            onChanged: _isLoading ? null : (value) {
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
                            items: LessonType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Row(
                                  children: [
                                    _getTypeIcon(type),
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
                          child: DropdownButtonFormField<LessonCategory>(
                            value: _selectedCategory,
                            onChanged: _isLoading ? null : (value) {
                              if (value != null) {
                                setState(() => _selectedCategory = value);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Category',
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
                            items: LessonCategory.values.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(_getCategoryLabel(category)),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Impact
                    DropdownButtonFormField<LessonImpact>(
                      value: _selectedImpact,
                      onChanged: _isLoading ? null : (value) {
                        if (value != null) {
                          setState(() => _selectedImpact = value);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Impact',
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
                    ),
                    const SizedBox(height: 20),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      enabled: !_isLoading,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Detailed description of the lesson learned',
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Recommendation
                    TextFormField(
                      controller: _recommendationController,
                      enabled: !_isLoading,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Recommendation',
                        hintText: 'What should be done differently in the future?',
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
                          Icons.lightbulb_outline,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Context
                    TextFormField(
                      controller: _contextController,
                      enabled: !_isLoading,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Context',
                        hintText: 'Additional context or background information',
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
                          Icons.info_outline,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tags
                    TextFormField(
                      controller: _tagsController,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'Tags',
                        hintText: 'Comma-separated tags (e.g., deployment, testing, ui)',
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
                          Icons.label_outline,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

                // Actions
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isEditing && !isMobile)
                        TextButton.icon(
                          onPressed: _isLoading ? null : _deleteLessonLearned,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      if (isEditing && isMobile)
                        IconButton(
                          onPressed: _isLoading ? null : _deleteLessonLearned,
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red,
                          tooltip: 'Delete',
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveLessonLearned,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(isEditing ? Icons.save : Icons.add),
                        label: Text(_isLoading
                            ? 'Saving...'
                            : isEditing ? 'Save Changes' : 'Create Lesson'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _getTypeIcon(LessonType type) {
    switch (type) {
      case LessonType.success:
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case LessonType.improvement:
        return const Icon(Icons.trending_up, color: Colors.orange, size: 20);
      case LessonType.challenge:
        return const Icon(Icons.warning, color: Colors.red, size: 20);
      case LessonType.bestPractice:
        return const Icon(Icons.star, color: Colors.blue, size: 20);
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
}