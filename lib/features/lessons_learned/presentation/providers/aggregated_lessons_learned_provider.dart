import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/domain/entities/lesson_learned.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../projects/domain/repositories/lessons_learned_repository.dart';
import '../../../projects/data/repositories/lessons_learned_repository_impl.dart';
import '../../../../core/network/dio_client.dart';
import 'lessons_learned_filter_provider.dart';

// Repository provider
final lessonsLearnedRepositoryProvider = Provider<LessonsLearnedRepository>((ref) {
  return LessonsLearnedRepositoryImpl(dio: DioClient.instance);
});

// Aggregated data class for lessons learned with project info
class AggregatedLessonLearned {
  final LessonLearned lesson;
  final Project? project;

  const AggregatedLessonLearned({
    required this.lesson,
    this.project,
  });
}

// Provider to track loading errors per project
final lessonLoadErrorsProvider = StateProvider<Map<String, String>>((ref) => {});

// Main aggregated lessons learned provider
final aggregatedLessonsLearnedProvider = FutureProvider<List<AggregatedLessonLearned>>((ref) async {
  final repository = ref.watch(lessonsLearnedRepositoryProvider);
  final projectsAsyncValue = ref.watch(projectsListProvider);

  return await projectsAsyncValue.when(
    data: (projects) async {
      final List<AggregatedLessonLearned> allLessons = [];
      final errorMap = <String, String>{};

      // Fetch lessons from all projects in parallel
      final futures = projects.map((project) async {
        try {
          final lessons = await repository.getProjectLessonsLearned(project.id);
          return lessons.map((lesson) => AggregatedLessonLearned(
            lesson: lesson,
            project: project,
          )).toList();
        } catch (e) {
          // Track errors per project
          errorMap[project.id] = e.toString();
          return <AggregatedLessonLearned>[];
        }
      });

      final results = await Future.wait(futures);

      // Flatten results
      for (final projectLessons in results) {
        allLessons.addAll(projectLessons);
      }

      // Update error state
      ref.read(lessonLoadErrorsProvider.notifier).state = errorMap;

      // Sort by identified date (most recent first)
      allLessons.sort((a, b) {
        final dateA = a.lesson.identifiedDate ?? DateTime.now();
        final dateB = b.lesson.identifiedDate ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      return allLessons;
    },
    loading: () => throw Future.value([]),
    error: (error, stack) => throw error,
  );
});

// Filtered lessons learned provider
final filteredLessonsLearnedProvider = Provider<List<AggregatedLessonLearned>>((ref) {
  final lessonsAsync = ref.watch(aggregatedLessonsLearnedProvider);
  final filter = ref.watch(lessonsLearnedFilterProvider);

  return lessonsAsync.when(
    data: (lessons) {
      var filtered = lessons;

      // Apply search filter
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase();
        filtered = filtered.where((item) {
          final lesson = item.lesson;
          return lesson.title.toLowerCase().contains(query) ||
                 lesson.description.toLowerCase().contains(query) ||
                 (lesson.recommendation?.toLowerCase().contains(query) ?? false) ||
                 (lesson.context?.toLowerCase().contains(query) ?? false) ||
                 lesson.tags.any((tag) => tag.toLowerCase().contains(query)) ||
                 (item.project?.name.toLowerCase().contains(query) ?? false);
        }).toList();
      }

      // Apply category filter
      if (filter.selectedCategories.isNotEmpty) {
        filtered = filtered.where((item) =>
          filter.selectedCategories.contains(item.lesson.category)
        ).toList();
      }

      // Apply type filter
      if (filter.selectedTypes.isNotEmpty) {
        filtered = filtered.where((item) =>
          filter.selectedTypes.contains(item.lesson.lessonType)
        ).toList();
      }

      // Apply impact filter
      if (filter.selectedImpacts.isNotEmpty) {
        filtered = filtered.where((item) =>
          filter.selectedImpacts.contains(item.lesson.impact)
        ).toList();
      }

      // Apply project filter
      if (filter.selectedProjectIds.isNotEmpty) {
        filtered = filtered.where((item) =>
          filter.selectedProjectIds.contains(item.lesson.projectId)
        ).toList();
      }

      // Apply AI generated filter
      if (filter.showOnlyAiGenerated) {
        filtered = filtered.where((item) => item.lesson.aiGenerated).toList();
      }

      return filtered;
    },
    loading: () => [],
    error: (error, stack) => [],
  );
});

// Refresh provider
final lessonsRefreshProvider = Provider((ref) {
  return () {
    ref.invalidate(aggregatedLessonsLearnedProvider);
  };
});

// Force refresh provider with cache clearing
final forceRefreshLessonsProvider = Provider((ref) {
  return () {
    // Clear any error state
    ref.read(lessonLoadErrorsProvider.notifier).state = {};

    // Invalidate the main provider
    ref.invalidate(aggregatedLessonsLearnedProvider);
  };
});