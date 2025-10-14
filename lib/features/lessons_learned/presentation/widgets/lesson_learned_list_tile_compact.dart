import 'package:flutter/material.dart';
import '../../../projects/domain/entities/lesson_learned.dart';
import '../../../projects/domain/entities/project.dart';
import '../utils/lesson_ui_helpers.dart';

class LessonLearnedListTileCompact extends StatelessWidget {
  final LessonLearned lesson;
  final Project? project;
  final VoidCallback? onTap;

  const LessonLearnedListTileCompact({
    super.key,
    required this.lesson,
    this.project,
    this.onTap,
  });


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final impactColor = LessonUIHelpers.getImpactColor(lesson.impact);
    final typeColor = LessonUIHelpers.getTypeColor(lesson.lessonType);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Impact indicator
              Container(
                width: 2,
                height: 36,
                decoration: BoxDecoration(
                  color: impactColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 10),

              // Category icon
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  LessonUIHelpers.getCategoryIcon(lesson.category),
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title and labels row
                    Row(
                      children: [
                        // Title
                        Expanded(
                          child: Text(
                            lesson.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Impact badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: impactColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            lesson.impact.label.substring(0, 1).toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: impactColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Metadata row
                    Row(
                      children: [
                        // Left side - labels
                        Expanded(
                          child: Row(
                            children: [
                              // Project label
                              if (project != null) ...[
                                Icon(
                                  Icons.folder_outlined,
                                  size: 11,
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 3),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 100),
                                  child: Text(
                                    project!.name,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],

                              // Type badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  lesson.lessonType.label,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: typeColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Category label
                              Text(
                                lesson.categoryLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Date on the right
                        if (lesson.identifiedDate != null)
                          Text(
                            _formatDate(lesson.identifiedDate!),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              fontSize: 11,
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo';
    } else {
      return '${(difference.inDays / 365).floor()}y';
    }
  }
}