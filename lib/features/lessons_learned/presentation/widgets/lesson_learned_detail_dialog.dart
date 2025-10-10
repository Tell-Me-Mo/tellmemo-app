import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import '../../../projects/domain/entities/lesson_learned.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/presentation/widgets/lesson_learned_dialog.dart';
import '../providers/aggregated_lessons_learned_provider.dart';
import '../utils/lesson_ui_helpers.dart';
import '../../../queries/presentation/widgets/ask_ai_panel.dart';
import '../../../queries/presentation/providers/query_provider.dart';

class LessonLearnedDetailDialog extends ConsumerWidget {
  final LessonLearned lesson;
  final Project? project;

  const LessonLearnedDetailDialog({
    super.key,
    required this.lesson,
    this.project,
  });

  String _buildLessonContext(LessonLearned lesson) {
    final buffer = StringBuffer();
    buffer.writeln('- Type: ${lesson.lessonType.label}');
    buffer.writeln('- Impact: ${lesson.impact.label}');
    buffer.writeln('- Category: ${lesson.categoryLabel}');
    buffer.writeln('- Description: ${lesson.description}');
    if (lesson.recommendation != null && lesson.recommendation!.isNotEmpty) {
      buffer.writeln('- Recommendation: ${lesson.recommendation}');
    }
    if (lesson.context != null && lesson.context!.isNotEmpty) {
      buffer.writeln('- Context: ${lesson.context}');
    }
    if (lesson.tags.isNotEmpty) {
      buffer.writeln('- Tags: ${lesson.tags.join(", ")}');
    }
    if (lesson.identifiedDate != null) {
      buffer.writeln('- Identified: ${lesson.identifiedDate!.toIso8601String().split('T')[0]}');
    }
    return buffer.toString();
  }

  void _openAIDialog(BuildContext context, WidgetRef ref) {
    // Build the lesson context that will be prepended invisibly
    final lessonContext = '''Context: Analyzing a lesson learned in the project.
Lesson Title: ${lesson.title}
${_buildLessonContext(lesson)}''';

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AskAIPanel(
          projectId: lesson.projectId,
          projectName: project?.name ?? 'Project',
          contextInfo: lessonContext,
          conversationId: 'lesson_${lesson.id}', // Unique ID for this lesson's conversation
          rightOffset: 0.0,  // Keep panel at right edge
          onClose: () {
            Navigator.of(context).pop();
            ref.read(queryProvider.notifier).clearConversation();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final impactColor = LessonUIHelpers.getImpactColor(lesson.impact);
    final typeColor = LessonUIHelpers.getTypeColor(lesson.lessonType);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: isMobile ? EdgeInsets.zero : const EdgeInsets.only(right: 100), // Add padding to push dialog left on desktop
      child: Dialog(
        insetPadding: isMobile
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 24)
            : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    Icons.lightbulb,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lesson Learned',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // More actions menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'More actions',
                    offset: const Offset(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _handleEdit(context);
                          break;
                        case 'delete':
                          _handleDelete(context, ref);
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
                    onPressed: () => _openAIDialog(context, ref),
                    icon: const Icon(Icons.auto_awesome),
                    tooltip: 'AI Assistant',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                      foregroundColor: Colors.green,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Clean Content
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      lesson.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Status badges
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Type',
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      size: 16,
                                      color: typeColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      lesson.lessonType.label,
                                      style: TextStyle(
                                        color: typeColor,
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
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: impactColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.flag,
                                      size: 16,
                                      color: impactColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      lesson.impact.label,
                                      style: TextStyle(
                                        color: impactColor,
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
                          Text(
                            'Recommendation',
                            style: theme.textTheme.labelLarge,
                          ),
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
                          Text(
                            'Context',
                            style: theme.textTheme.labelLarge,
                          ),
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
                      Text(
                        'Tags',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: lesson.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              tag,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }).toList(),
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
                        if (lesson.identifiedDate != null)
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
                                'Identified: ${LessonUIHelpers.formatDateRelative(lesson.identifiedDate!)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        if (lesson.lastUpdated != null)
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
                                'Updated: ${LessonUIHelpers.formatDateRelative(lesson.lastUpdated!)}',
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
              ),
            ),

            ],
          ),
        ),
      ),
      ),
    );
  }



  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text('Are you sure you want to delete "${lesson.title}"?'),
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

    if (confirm == true && context.mounted) {
      try {
        final repository = ref.read(lessonsLearnedRepositoryProvider);
        await repository.deleteLessonLearned(lesson.id);
        ref.read(forceRefreshLessonsProvider)();

        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          ref.read(notificationServiceProvider.notifier).showError('Failed to delete lesson: $e');
        }
      }
    }
  }

  void _handleEdit(BuildContext context) {
    Navigator.of(context).pop(); // Close current dialog
    showDialog(
      context: context,
      builder: (context) => LessonLearnedDialog(
        projectId: lesson.projectId,
        lesson: lesson,
      ),
    );
  }
}