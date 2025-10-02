import 'package:dio/dio.dart';
import '../../domain/repositories/lessons_learned_repository.dart';
import '../../domain/entities/lesson_learned.dart';
import '../models/lesson_learned_model.dart';

class LessonsLearnedRepositoryImpl implements LessonsLearnedRepository {
  final Dio dio;

  LessonsLearnedRepositoryImpl({required this.dio});

  @override
  Future<List<LessonLearned>> getProjectLessonsLearned(String projectId) async {
    try {
      final response = await dio.get('/api/projects/$projectId/lessons-learned');

      if (response.data is List) {
        return (response.data as List)
            .map((json) => LessonLearnedModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch lessons learned: $e');
    }
  }

  @override
  Future<LessonLearned> createLessonLearned(String projectId, LessonLearned lesson) async {
    try {
      final lessonModel = LessonLearnedModel(
        id: '',
        projectId: projectId,
        title: lesson.title,
        description: lesson.description,
        category: lesson.category,
        lessonType: lesson.lessonType,
        impact: lesson.impact,
        recommendation: lesson.recommendation,
        context: lesson.context,
        tags: lesson.tags,
        aiGenerated: lesson.aiGenerated,
      );

      final response = await dio.post(
        '/api/projects/$projectId/lessons-learned',
        data: lessonModel.toCreateJson(),
      );

      return LessonLearnedModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create lesson learned: $e');
    }
  }

  @override
  Future<LessonLearned> updateLessonLearned(String lessonId, LessonLearned lesson) async {
    try {
      final updateData = {
        'title': lesson.title,
        'description': lesson.description,
        'category': lesson.category.value,
        'lesson_type': lesson.lessonType.value,
        'impact': lesson.impact.value,
        'recommendation': lesson.recommendation,
        'context': lesson.context,
        if (lesson.tags.isNotEmpty) 'tags': lesson.tags.join(','),
      };

      final response = await dio.put(
        '/api/lessons-learned/$lessonId',
        data: updateData,
      );

      return LessonLearnedModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update lesson learned: $e');
    }
  }

  @override
  Future<void> deleteLessonLearned(String lessonId) async {
    try {
      await dio.delete('/api/lessons-learned/$lessonId');
    } catch (e) {
      throw Exception('Failed to delete lesson learned: $e');
    }
  }
}