import '../entities/lesson_learned.dart';

abstract class LessonsLearnedRepository {
  Future<List<LessonLearned>> getProjectLessonsLearned(String projectId);
  Future<LessonLearned> createLessonLearned(String projectId, LessonLearned lesson);
  Future<LessonLearned> updateLessonLearned(String lessonId, LessonLearned lesson);
  Future<void> deleteLessonLearned(String lessonId);
}