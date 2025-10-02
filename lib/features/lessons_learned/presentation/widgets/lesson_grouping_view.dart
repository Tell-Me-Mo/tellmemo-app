import 'package:flutter/material.dart';
import '../providers/aggregated_lessons_learned_provider.dart';
import '../widgets/lesson_group_dialog.dart';
import 'lesson_learned_list_tile_compact.dart';
import 'lesson_learned_list_tile.dart';
import 'lesson_learned_detail_dialog.dart';

class LessonGroupingView extends StatelessWidget {
  final List<AggregatedLessonLearned> lessons;
  final LessonGroupingMode groupingMode;
  final bool isCompact;

  const LessonGroupingView({
    super.key,
    required this.lessons,
    required this.groupingMode,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final groupedLessons = _groupLessons();

    return Column(
      children: groupedLessons.entries.map((entry) {
        final groupKey = entry.key;
        final groupLessons = entry.value;
        final isExpanded = true; // Can make this stateful if needed

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: isExpanded,
              title: _buildGroupHeader(context, groupKey, groupLessons.length),
              children: groupLessons.map((aggregatedLesson) {
                return _buildLessonItem(context, aggregatedLesson);
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Map<String, List<AggregatedLessonLearned>> _groupLessons() {
    final grouped = <String, List<AggregatedLessonLearned>>{};

    for (final lesson in lessons) {
      String key;
      switch (groupingMode) {
        case LessonGroupingMode.project:
          key = lesson.project?.name ?? 'No Project';
          break;
        case LessonGroupingMode.category:
          key = lesson.lesson.category.name.toUpperCase();
          break;
        case LessonGroupingMode.type:
          key = lesson.lesson.lessonType.name.toUpperCase();
          break;
        case LessonGroupingMode.impact:
          key = lesson.lesson.impact.name.toUpperCase();
          break;
        case LessonGroupingMode.none:
          key = 'All';
          break;
      }

      grouped.putIfAbsent(key, () => []).add(lesson);
    }

    // Sort groups
    final sortedKeys = grouped.keys.toList();
    if (groupingMode == LessonGroupingMode.impact) {
      // Sort by impact priority
      final impactOrder = {
        'HIGH': 0,
        'MEDIUM': 1,
        'LOW': 2,
      };
      sortedKeys.sort((a, b) =>
          (impactOrder[a] ?? 99).compareTo(impactOrder[b] ?? 99));
    } else {
      sortedKeys.sort();
    }

    final sortedGrouped = <String, List<AggregatedLessonLearned>>{};
    for (final key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }

  Widget _buildGroupHeader(BuildContext context, String groupName, int count) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    IconData icon;
    Color color;

    switch (groupingMode) {
      case LessonGroupingMode.project:
        icon = Icons.folder;
        color = colorScheme.primary;
        break;
      case LessonGroupingMode.category:
        icon = Icons.category;
        color = _getCategoryColorFromLabel(groupName);
        break;
      case LessonGroupingMode.type:
        icon = Icons.label;
        color = _getTypeColorFromLabel(groupName);
        break;
      case LessonGroupingMode.impact:
        icon = Icons.flag;
        color = _getImpactColorFromLabel(groupName);
        break;
      case LessonGroupingMode.none:
        icon = Icons.list;
        color = colorScheme.primary;
        break;
    }

    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          groupName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLessonItem(BuildContext context, AggregatedLessonLearned aggregatedLesson) {
    return isCompact
        ? LessonLearnedListTileCompact(
            lesson: aggregatedLesson.lesson,
            project: aggregatedLesson.project,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => LessonLearnedDetailDialog(
                  lesson: aggregatedLesson.lesson,
                  project: aggregatedLesson.project,
                ),
              );
            },
          )
        : LessonLearnedListTile(
            lesson: aggregatedLesson.lesson,
            project: aggregatedLesson.project,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => LessonLearnedDetailDialog(
                  lesson: aggregatedLesson.lesson,
                  project: aggregatedLesson.project,
                ),
              );
            },
          );
  }

  Color _getCategoryColorFromLabel(String label) {
    switch (label.toLowerCase()) {
      case 'technical':
        return Colors.blue;
      case 'process':
        return Colors.green;
      case 'communication':
        return Colors.purple;
      case 'planning':
        return Colors.orange;
      case 'quality':
        return Colors.red;
      case 'other':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getTypeColorFromLabel(String label) {
    switch (label.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'challenge':
        return Colors.orange;
      case 'bestpractice':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Color _getImpactColorFromLabel(String label) {
    switch (label.toLowerCase()) {
      case 'low':
        return Colors.blue;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}