import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/lesson_learned.dart';
import '../providers/lessons_learned_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../lessons_learned/presentation/widgets/lesson_learned_detail_panel.dart';
import '../providers/projects_provider.dart';

class ProjectLessonsLearnedWidget extends ConsumerWidget {
  final String projectId;
  final bool showHeader;
  final int? limit;

  const ProjectLessonsLearnedWidget({
    super.key,
    required this.projectId,
    this.showHeader = true,
    this.limit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsLearnedNotifierProvider(projectId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          lessonsAsync.when(
            data: (lessons) => _buildHeader(context, ref, theme, lessons.isNotEmpty),
            loading: () => _buildHeader(context, ref, theme, false),
            error: (_, __) => _buildHeader(context, ref, theme, false),
          ),
          const SizedBox(height: 12),
        ],
        lessonsAsync.when(
          data: (lessons) {
            if (lessons.isEmpty) {
              return _buildEmptyCard(context, ref, 'No lessons learned yet');
            }

            // Apply limit if specified
            List<LessonLearned> limitedLessons = lessons;
            if (limit != null) {
              limitedLessons = lessons.take(limit!).toList();
            }

            // Group lessons by type (from limited set)
            final successes = limitedLessons.where((l) => l.lessonType == LessonType.success).toList();
            final improvements = limitedLessons.where((l) => l.lessonType == LessonType.improvement).toList();
            final challenges = limitedLessons.where((l) => l.lessonType == LessonType.challenge).toList();
            final bestPractices = limitedLessons.where((l) => l.lessonType == LessonType.bestPractice).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (successes.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Successes', Colors.green),
                  ...successes.map((lesson) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildLessonCard(context, ref, lesson),
                  )),
                ],
                if (improvements.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSectionHeader(context, 'Improvements', Colors.orange),
                  ...improvements.map((lesson) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildLessonCard(context, ref, lesson),
                  )),
                ],
                if (challenges.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSectionHeader(context, 'Challenges', Colors.red),
                  ...challenges.map((lesson) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildLessonCard(context, ref, lesson),
                  )),
                ],
                if (bestPractices.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSectionHeader(context, 'Best Practices', Colors.blue),
                  ...bestPractices.map((lesson) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildLessonCard(context, ref, lesson),
                  )),
                ],
              ],
            );
          },
          loading: () => Column(
            children: [
              const LinearProgressIndicator(),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Loading lessons learned...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          error: (error, stackTrace) => _buildErrorCard(context, ref, error),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, ThemeData theme, bool hasLessons) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Lessons Learned',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasLessons)
              TextButton(
                onPressed: () => context.push('/lessons?project=$projectId&from=project'),
                child: const Text('See all'),
              ),
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => _showAddLessonDialog(context, ref),
              tooltip: 'Add Lesson Learned',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context, WidgetRef ref, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.lightbulb_outline,
                size: 32,
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No lessons captured yet',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Upload meeting transcripts to automatically capture project insights and lessons learned',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, WidgetRef ref, Object error) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load lessons learned',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              ref.invalidate(lessonsLearnedNotifierProvider(projectId));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(BuildContext context, WidgetRef ref, LessonLearned lesson) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLessonDetails(context, ref, lesson),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Type indicator icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getTypeColor(lesson.lessonType).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  _getTypeIcon(lesson.lessonType),
                  size: 14,
                  color: _getTypeColor(lesson.lessonType).withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(width: 10),
              // Content
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${lesson.impact.label} impact',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (lesson.aiGenerated)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'AI',
                          style: TextStyle(
                            color: Colors.blue.withValues(alpha: 0.8),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
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

  void _showAddLessonDialog(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.read(projectDetailProvider(projectId));

    projectAsync.when(
      data: (project) {
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.transparent,
          transitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return LessonLearnedDetailPanel(
              projectId: projectId,
              projectName: project?.name,
              initiallyInEditMode: true,
            );
          },
        );
      },
      loading: () {
        // Fallback: show panel without project name
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.transparent,
          transitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return LessonLearnedDetailPanel(
              projectId: projectId,
              projectName: null,
              initiallyInEditMode: true,
            );
          },
        );
      },
      error: (error, stackTrace) {
        // Fallback: show panel without project name
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.transparent,
          transitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return LessonLearnedDetailPanel(
              projectId: projectId,
              projectName: null,
              initiallyInEditMode: true,
            );
          },
        );
      },
    );
  }

  void _showLessonDetails(BuildContext context, WidgetRef ref, LessonLearned lesson) {
    final projectAsync = ref.watch(projectDetailProvider(projectId));

    projectAsync.when(
      data: (project) {
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.transparent,
          transitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return LessonLearnedDetailPanel(
              lesson: lesson,
              projectId: project?.id,
              projectName: project?.name,
            );
          },
        );
      },
      loading: () {
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Loading project details...'),
              ],
            ),
          ),
        );
      },
      error: (error, stackTrace) {
        // Fallback to panel without project info
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.transparent,
          transitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return LessonLearnedDetailPanel(
              lesson: lesson,
              projectId: null,
              projectName: null,
            );
          },
        );
      },
    );
  }

  IconData _getTypeIcon(LessonType type) {
    switch (type) {
      case LessonType.success:
        return Icons.check_circle_outline;
      case LessonType.improvement:
        return Icons.trending_up;
      case LessonType.challenge:
        return Icons.warning_amber_outlined;
      case LessonType.bestPractice:
        return Icons.star_outline;
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
}