import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:pm_master_v2/features/projects/data/repositories/lessons_learned_repository_impl.dart';
import 'package:pm_master_v2/features/projects/domain/entities/lesson_learned.dart';

import 'lessons_learned_repository_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Dio>()])
void main() {
  late LessonsLearnedRepositoryImpl repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = LessonsLearnedRepositoryImpl(dio: mockDio);
  });

  group('LessonsLearnedRepositoryImpl', () {
    const projectId = 'proj-123';
    const lessonId = 'lesson-456';

    group('getProjectLessonsLearned', () {
      test('returns list of lessons learned on successful response', () async {
        // Arrange
        final responseData = [
          {
            'id': 'lesson-1',
            'project_id': projectId,
            'title': 'Lesson 1',
            'description': 'Description 1',
            'category': 'technical',
            'lesson_type': 'success',
            'impact': 'high',
          },
          {
            'id': 'lesson-2',
            'project_id': projectId,
            'title': 'Lesson 2',
            'description': 'Description 2',
            'category': 'process',
            'lesson_type': 'improvement',
            'impact': 'medium',
          },
        ];

        when(mockDio.get(
          '/api/v1/projects/$projectId/lessons-learned',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response(
                  data: responseData,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/api/v1/projects/$projectId/lessons-learned'),
                ));

        // Act
        final result = await repository.getProjectLessonsLearned(projectId);

        // Assert
        expect(result, isA<List<LessonLearned>>());
        expect(result.length, 2);
        expect(result[0].id, 'lesson-1');
        expect(result[0].title, 'Lesson 1');
        expect(result[0].category, LessonCategory.technical);
        expect(result[0].lessonType, LessonType.success);
        expect(result[0].impact, LessonImpact.high);
        expect(result[1].id, 'lesson-2');
        expect(result[1].title, 'Lesson 2');
        expect(result[1].category, LessonCategory.process);
        expect(result[1].lessonType, LessonType.improvement);
        expect(result[1].impact, LessonImpact.medium);
        verify(mockDio.get(
          '/api/v1/projects/$projectId/lessons-learned',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).called(1);
      });

      test('returns empty list when response data is not a list', () async {
        // Arrange
        when(mockDio.get(
          '/api/v1/projects/$projectId/lessons-learned',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response(
                  data: {'message': 'Not a list'},
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/api/v1/projects/$projectId/lessons-learned'),
                ));

        // Act
        final result = await repository.getProjectLessonsLearned(projectId);

        // Assert
        expect(result, isEmpty);
        verify(mockDio.get(
          '/api/v1/projects/$projectId/lessons-learned',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).called(1);
      });

      test('returns empty list when response data is empty list', () async {
        // Arrange
        when(mockDio.get(
          '/api/v1/projects/$projectId/lessons-learned',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response(
                  data: [],
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/api/v1/projects/$projectId/lessons-learned'),
                ));

        // Act
        final result = await repository.getProjectLessonsLearned(projectId);

        // Assert
        expect(result, isEmpty);
        verify(mockDio.get(
          '/api/v1/projects/$projectId/lessons-learned',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).called(1);
      });

      test('throws exception on DioException', () async {
        // Arrange
        when(mockDio.get(
          '/api/v1/projects/$projectId/lessons-learned',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/api/v1/projects/$projectId/lessons-learned'),
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: '/api/v1/projects/$projectId/lessons-learned'),
          ),
        ));

        // Act & Assert
        expect(
          () => repository.getProjectLessonsLearned(projectId),
          throwsA(isA<Exception>()),
        );
        verify(mockDio.get(
          '/api/v1/projects/$projectId/lessons-learned',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).called(1);
      });

      test('throws exception on generic error', () async {
        // Arrange
        when(mockDio.get(
          '/api/v1/projects/$projectId/lessons-learned',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => repository.getProjectLessonsLearned(projectId),
          throwsA(isA<Exception>()),
        );
        verify(mockDio.get(
          '/api/v1/projects/$projectId/lessons-learned',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).called(1);
      });
    });

    group('createLessonLearned', () {
      test('creates lesson learned successfully', () async {
        // Arrange
        final lesson = LessonLearned(
          id: '',
          projectId: projectId,
          title: 'New Lesson',
          description: 'New Description',
          category: LessonCategory.technical,
          lessonType: LessonType.success,
          impact: LessonImpact.high,
          recommendation: 'Recommended approach',
          context: 'Sprint 3',
          tags: ['backend', 'api'],
          aiGenerated: false,
        );

        final responseData = {
          'id': 'lesson-new',
          'project_id': projectId,
          'title': 'New Lesson',
          'description': 'New Description',
          'category': 'technical',
          'lesson_type': 'success',
          'impact': 'high',
          'recommendation': 'Recommended approach',
          'context': 'Sprint 3',
          'tags': ['backend', 'api'],
          'ai_generated': false,
        };

        when(mockDio.post(
          '/api/v1/projects/$projectId/lessons-learned',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response(
              data: responseData,
              statusCode: 201,
              requestOptions: RequestOptions(path: '/api/v1/projects/$projectId/lessons-learned'),
            ));

        // Act
        final result = await repository.createLessonLearned(projectId, lesson);

        // Assert
        expect(result, isA<LessonLearned>());
        expect(result.id, 'lesson-new');
        expect(result.title, 'New Lesson');
        expect(result.category, LessonCategory.technical);
        expect(result.lessonType, LessonType.success);
        expect(result.impact, LessonImpact.high);
        verify(mockDio.post(
          '/api/v1/projects/$projectId/lessons-learned',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).called(1);
      });

      test('sends correct data format in create request', () async {
        // Arrange
        final lesson = LessonLearned(
          id: 'ignored-id',
          projectId: 'ignored-project-id',
          title: 'Test Lesson',
          description: 'Test Description',
          category: LessonCategory.process,
          lessonType: LessonType.challenge,
          impact: LessonImpact.low,
          aiGenerated: false,
        );

        when(mockDio.post(
          '/api/v1/projects/$projectId/lessons-learned',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response(
              data: {
                'id': 'new-id',
                'project_id': projectId,
                'title': 'Test Lesson',
                'description': 'Test Description',
                'category': 'process',
                'lesson_type': 'challenge',
                'impact': 'low',
                'ai_generated': false,
              },
              statusCode: 201,
              requestOptions: RequestOptions(path: '/api/v1/projects/$projectId/lessons-learned'),
            ));

        // Act
        await repository.createLessonLearned(projectId, lesson);

        // Assert
        final captured = verify(mockDio.post(
          '/api/v1/projects/$projectId/lessons-learned',
          data: captureAnyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).captured.single as Map<String, dynamic>;

        // Verify toCreateJson excludes id, project_id, ai_generated
        expect(captured.containsKey('id'), false);
        expect(captured.containsKey('project_id'), false);
        expect(captured.containsKey('ai_generated'), false);
        expect(captured['title'], 'Test Lesson');
        expect(captured['description'], 'Test Description');
        expect(captured['category'], 'process');
        expect(captured['lesson_type'], 'challenge');
        expect(captured['impact'], 'low');
      });

      test('throws exception on DioException', () async {
        // Arrange
        final lesson = LessonLearned(
          id: '',
          projectId: projectId,
          title: 'Test',
          description: 'Test',
          category: LessonCategory.technical,
          lessonType: LessonType.success,
          impact: LessonImpact.medium,
          aiGenerated: false,
        );

        when(mockDio.post(
          '/api/v1/projects/$projectId/lessons-learned',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/api/v1/projects/$projectId/lessons-learned'),
          response: Response(
            statusCode: 400,
            requestOptions: RequestOptions(path: '/api/v1/projects/$projectId/lessons-learned'),
          ),
        ));

        // Act & Assert
        expect(
          () => repository.createLessonLearned(projectId, lesson),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updateLessonLearned', () {
      test('updates lesson learned successfully', () async {
        // Arrange
        final lesson = LessonLearned(
          id: lessonId,
          projectId: projectId,
          title: 'Updated Lesson',
          description: 'Updated Description',
          category: LessonCategory.communication,
          lessonType: LessonType.improvement,
          impact: LessonImpact.medium,
          recommendation: 'Updated recommendation',
          context: 'Sprint 4',
          tags: ['frontend', 'ui'],
          aiGenerated: false,
        );

        final responseData = {
          'id': lessonId,
          'project_id': projectId,
          'title': 'Updated Lesson',
          'description': 'Updated Description',
          'category': 'communication',
          'lesson_type': 'improvement',
          'impact': 'medium',
          'recommendation': 'Updated recommendation',
          'context': 'Sprint 4',
          'tags': ['frontend', 'ui'],
          'ai_generated': false,
        };

        when(mockDio.put(
          '/api/v1/lessons-learned/$lessonId',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response(
              data: responseData,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/lessons-learned/$lessonId'),
            ));

        // Act
        final result = await repository.updateLessonLearned(lessonId, lesson);

        // Assert
        expect(result, isA<LessonLearned>());
        expect(result.id, lessonId);
        expect(result.title, 'Updated Lesson');
        expect(result.category, LessonCategory.communication);
        expect(result.lessonType, LessonType.improvement);
        expect(result.impact, LessonImpact.medium);
        verify(mockDio.put(
          '/api/v1/lessons-learned/$lessonId',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).called(1);
      });

      test('sends correct data format in update request', () async {
        // Arrange
        final lesson = LessonLearned(
          id: lessonId,
          projectId: projectId,
          title: 'Title',
          description: 'Desc',
          category: LessonCategory.technical,
          lessonType: LessonType.success,
          impact: LessonImpact.high,
          recommendation: 'Rec',
          context: 'Ctx',
          tags: ['tag1', 'tag2'],
          aiGenerated: false,
        );

        when(mockDio.put(
          '/api/v1/lessons-learned/$lessonId',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response(
              data: {
                'id': lessonId,
                'project_id': projectId,
                'title': 'Title',
                'description': 'Desc',
                'category': 'technical',
                'lesson_type': 'success',
                'impact': 'high',
              },
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/lessons-learned/$lessonId'),
            ));

        // Act
        await repository.updateLessonLearned(lessonId, lesson);

        // Assert
        final captured = verify(mockDio.put(
          '/api/v1/lessons-learned/$lessonId',
          data: captureAnyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['title'], 'Title');
        expect(captured['description'], 'Desc');
        expect(captured['category'], 'technical');
        expect(captured['lesson_type'], 'success');
        expect(captured['impact'], 'high');
        expect(captured['recommendation'], 'Rec');
        expect(captured['context'], 'Ctx');
        expect(captured['tags'], 'tag1,tag2'); // Joined with comma
      });

      test('omits tags field when empty in update request', () async {
        // Arrange
        final lesson = LessonLearned(
          id: lessonId,
          projectId: projectId,
          title: 'Title',
          description: 'Desc',
          category: LessonCategory.technical,
          lessonType: LessonType.success,
          impact: LessonImpact.high,
          tags: [], // Empty tags
          aiGenerated: false,
        );

        when(mockDio.put(
          '/api/v1/lessons-learned/$lessonId',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response(
              data: {
                'id': lessonId,
                'project_id': projectId,
                'title': 'Title',
                'description': 'Desc',
                'category': 'technical',
                'lesson_type': 'success',
                'impact': 'high',
              },
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/lessons-learned/$lessonId'),
            ));

        // Act
        await repository.updateLessonLearned(lessonId, lesson);

        // Assert
        final captured = verify(mockDio.put(
          '/api/v1/lessons-learned/$lessonId',
          data: captureAnyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).captured.single as Map<String, dynamic>;

        expect(captured.containsKey('tags'), false);
      });

      test('throws exception on DioException', () async {
        // Arrange
        final lesson = LessonLearned(
          id: lessonId,
          projectId: projectId,
          title: 'Test',
          description: 'Test',
          category: LessonCategory.technical,
          lessonType: LessonType.success,
          impact: LessonImpact.medium,
          aiGenerated: false,
        );

        when(mockDio.put(
          '/api/v1/lessons-learned/$lessonId',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/api/v1/lessons-learned/$lessonId'),
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: '/api/v1/lessons-learned/$lessonId'),
          ),
        ));

        // Act & Assert
        expect(
          () => repository.updateLessonLearned(lessonId, lesson),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('deleteLessonLearned', () {
      test('deletes lesson learned successfully', () async {
        // Arrange
        when(mockDio.delete(
          '/api/v1/lessons-learned/$lessonId',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
        )).thenAnswer((_) async => Response(
                  data: {'message': 'Deleted'},
                  statusCode: 204,
                  requestOptions: RequestOptions(path: '/api/v1/lessons-learned/$lessonId'),
                ));

        // Act
        await repository.deleteLessonLearned(lessonId);

        // Assert
        verify(mockDio.delete(
          '/api/v1/lessons-learned/$lessonId',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
        )).called(1);
      });

      test('throws exception on DioException', () async {
        // Arrange
        when(mockDio.delete(
          '/api/v1/lessons-learned/$lessonId',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/api/v1/lessons-learned/$lessonId'),
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: '/api/v1/lessons-learned/$lessonId'),
          ),
        ));

        // Act & Assert
        expect(
          () => repository.deleteLessonLearned(lessonId),
          throwsA(isA<Exception>()),
        );
        verify(mockDio.delete(
          '/api/v1/lessons-learned/$lessonId',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
        )).called(1);
      });

      test('throws exception on generic error', () async {
        // Arrange
        when(mockDio.delete(
          '/api/v1/lessons-learned/$lessonId',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
        )).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => repository.deleteLessonLearned(lessonId),
          throwsA(isA<Exception>()),
        );
        verify(mockDio.delete(
          '/api/v1/lessons-learned/$lessonId',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
        )).called(1);
      });
    });

    group('Edge Cases', () {
      test('handles null/empty values in response data', () async {
        // Arrange
        final responseData = [
          {
            'id': 'lesson-1',
            'project_id': projectId,
            'title': '',
            'description': '',
            'category': 'other',
            'lesson_type': 'improvement',
            'impact': 'medium',
          },
        ];

        when(mockDio.get(
          '/api/v1/projects/$projectId/lessons-learned',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response(
                  data: responseData,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/api/v1/projects/$projectId/lessons-learned'),
                ));

        // Act
        final result = await repository.getProjectLessonsLearned(projectId);

        // Assert
        expect(result.length, 1);
        expect(result[0].title, '');
        expect(result[0].description, '');
      });

      test('handles special characters in lesson data', () async {
        // Arrange
        final lesson = LessonLearned(
          id: '',
          projectId: projectId,
          title: 'Lesson: "Special" & <HTML>',
          description: "It's a test with special chars: @#\$%",
          category: LessonCategory.technical,
          lessonType: LessonType.success,
          impact: LessonImpact.high,
          aiGenerated: false,
        );

        when(mockDio.post(
          '/api/v1/projects/$projectId/lessons-learned',
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response(
              data: {
                'id': 'lesson-new',
                'project_id': projectId,
                'title': 'Lesson: "Special" & <HTML>',
                'description': "It's a test with special chars: @#\$%",
                'category': 'technical',
                'lesson_type': 'success',
                'impact': 'high',
                'ai_generated': false,
              },
              statusCode: 201,
              requestOptions: RequestOptions(path: '/api/v1/projects/$projectId/lessons-learned'),
            ));

        // Act
        final result = await repository.createLessonLearned(projectId, lesson);

        // Assert
        expect(result.title, 'Lesson: "Special" & <HTML>');
        expect(result.description, "It's a test with special chars: @#\$%");
      });
    });
  });
}
