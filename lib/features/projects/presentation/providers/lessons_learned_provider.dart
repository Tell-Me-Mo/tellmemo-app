import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/lesson_learned.dart';
import '../../data/models/lesson_learned_model.dart';
import '../../domain/repositories/lessons_learned_repository.dart';
import '../../data/repositories/lessons_learned_repository_impl.dart';
import '../../../../core/network/dio_client.dart';

// Repository provider
final lessonsLearnedRepositoryProvider = Provider<LessonsLearnedRepository>((ref) {
  return LessonsLearnedRepositoryImpl(dio: DioClient.instance);
});

// Lessons learned provider for a specific project
final projectLessonsLearnedProvider = FutureProvider.family<List<LessonLearned>, String>((ref, projectId) async {
  final repository = ref.watch(lessonsLearnedRepositoryProvider);
  return repository.getProjectLessonsLearned(projectId);
});

// State notifier for managing lessons learned
class LessonsLearnedNotifier extends StateNotifier<AsyncValue<List<LessonLearned>>> {
  final LessonsLearnedRepository _repository;
  final String projectId;

  LessonsLearnedNotifier(this._repository, this.projectId) : super(const AsyncValue.loading()) {
    loadLessonsLearned();
  }

  Future<void> loadLessonsLearned() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final lessons = await _repository.getProjectLessonsLearned(projectId);
      if (!mounted) return;
      state = AsyncValue.data(lessons);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addLessonLearned(LessonLearned lesson) async {
    try {
      final newLesson = await _repository.createLessonLearned(projectId, lesson);
      if (!mounted) return;
      state = state.whenData((lessons) => [...lessons, newLesson]);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateLessonLearned(LessonLearned lesson) async {
    try {
      final updatedLesson = await _repository.updateLessonLearned(lesson.id, lesson);
      if (!mounted) return;
      state = state.whenData((lessons) {
        final index = lessons.indexWhere((l) => l.id == lesson.id);
        if (index != -1) {
          final newList = [...lessons];
          newList[index] = updatedLesson;
          return newList;
        }
        return lessons;
      });
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteLessonLearned(String lessonId) async {
    try {
      await _repository.deleteLessonLearned(lessonId);
      if (!mounted) return;
      state = state.whenData((lessons) => lessons.where((l) => l.id != lessonId).toList());
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    if (!mounted) return;
    await loadLessonsLearned();
  }
}

// State notifier provider
final lessonsLearnedNotifierProvider = StateNotifierProvider.family<
    LessonsLearnedNotifier, AsyncValue<List<LessonLearned>>, String>((ref, projectId) {
  final repository = ref.watch(lessonsLearnedRepositoryProvider);
  return LessonsLearnedNotifier(repository, projectId);
});