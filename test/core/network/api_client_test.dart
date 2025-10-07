import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pm_master_v2/core/network/api_client.dart';
import 'package:pm_master_v2/features/projects/data/models/project_model.dart';

@GenerateMocks([Dio])
import 'api_client_test.mocks.dart';

void main() {
  late MockDio mockDio;
  late ApiClient apiClient;

  setUp(() {
    mockDio = MockDio();
    apiClient = ApiClient(mockDio);
  });

  group('ApiClient - Health Check', () {
    test('healthCheck returns response data', () async {
      // Arrange
      final responseData = {'status': 'healthy'};
      when(mockDio.get('/api/v1/health')).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/health'),
        ),
      );

      // Act
      final result = await apiClient.healthCheck();

      // Assert
      expect(result, responseData);
      verify(mockDio.get('/api/v1/health')).called(1);
    });
  });

  group('ApiClient - Projects GET', () {
    test('getProjects returns list of ProjectModel', () async {
      // Arrange
      final projectsData = [
        {
          'id': '1',
          'name': 'Project A',
          'description': 'Test project A',
          'status': 'active',
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-01T00:00:00Z',
        },
        {
          'id': '2',
          'name': 'Project B',
          'description': 'Test project B',
          'status': 'active',
          'created_at': '2024-01-02T00:00:00Z',
          'updated_at': '2024-01-02T00:00:00Z',
        },
      ];

      when(mockDio.get('/api/v1/projects')).thenAnswer(
        (_) async => Response(
          data: projectsData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/projects'),
        ),
      );

      // Act
      final result = await apiClient.getProjects();

      // Assert
      expect(result, isA<List<ProjectModel>>());
      expect(result.length, 2);
      expect(result[0].id, '1');
      expect(result[0].name, 'Project A');
      expect(result[1].id, '2');
      expect(result[1].name, 'Project B');
      verify(mockDio.get('/api/v1/projects')).called(1);
    });

    test('getProject returns single ProjectModel', () async {
      // Arrange
      final projectData = {
        'id': '123',
        'name': 'Test Project',
        'description': 'Test description',
        'status': 'active',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      when(mockDio.get('/api/v1/projects/123')).thenAnswer(
        (_) async => Response(
          data: projectData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/projects/123'),
        ),
      );

      // Act
      final result = await apiClient.getProject('123');

      // Assert
      expect(result, isA<ProjectModel>());
      expect(result.id, '123');
      expect(result.name, 'Test Project');
      verify(mockDio.get('/api/v1/projects/123')).called(1);
    });
  });

  group('ApiClient - Projects POST', () {
    test('createProject returns ProjectModel on success', () async {
      // Arrange
      final projectRequest = {
        'name': 'New Project',
        'description': 'Test description',
      };

      final projectResponse = {
        'id': 'new-123',
        'name': 'New Project',
        'description': 'Test description',
        'status': 'active',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      when(mockDio.post('/api/v1/projects', data: projectRequest)).thenAnswer(
        (_) async => Response(
          data: projectResponse,
          statusCode: 201,
          requestOptions: RequestOptions(path: '/api/v1/projects'),
        ),
      );

      // Act
      final result = await apiClient.createProject(projectRequest);

      // Assert
      expect(result, isA<ProjectModel>());
      expect(result.id, 'new-123');
      expect(result.name, 'New Project');
      verify(mockDio.post('/api/v1/projects', data: projectRequest)).called(1);
    });

    test('createProject throws Exception with 409 conflict error', () async {
      // Arrange
      final projectRequest = {'name': 'Duplicate Project'};

      when(mockDio.post('/api/v1/projects', data: projectRequest)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/projects'),
          response: Response(
            data: {'detail': 'Project name already exists'},
            statusCode: 409,
            requestOptions: RequestOptions(path: '/api/v1/projects'),
          ),
        ),
      );

      // Act & Assert
      expect(
        () => apiClient.createProject(projectRequest),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Project name already exists'),
        )),
      );
    });

    test('createProject throws Exception with generic error', () async {
      // Arrange
      final projectRequest = {'name': 'Test Project'};

      when(mockDio.post('/api/v1/projects', data: projectRequest)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/projects'),
          response: Response(
            data: {'detail': 'Internal server error'},
            statusCode: 500,
            requestOptions: RequestOptions(path: '/api/v1/projects'),
          ),
        ),
      );

      // Act & Assert
      expect(
        () => apiClient.createProject(projectRequest),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Internal server error'),
        )),
      );
    });
  });

  group('ApiClient - Projects PUT', () {
    test('updateProject returns updated ProjectModel', () async {
      // Arrange
      final updateRequest = {'name': 'Updated Project'};
      final updateResponse = {
        'id': '123',
        'name': 'Updated Project',
        'description': 'Updated description',
        'status': 'active',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-02T00:00:00Z',
      };

      when(mockDio.put('/api/v1/projects/123', data: updateRequest)).thenAnswer(
        (_) async => Response(
          data: updateResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/projects/123'),
        ),
      );

      // Act
      final result = await apiClient.updateProject('123', updateRequest);

      // Assert
      expect(result, isA<ProjectModel>());
      expect(result.name, 'Updated Project');
      verify(mockDio.put('/api/v1/projects/123', data: updateRequest)).called(1);
    });

    test('updateProject throws Exception with 409 conflict error', () async {
      // Arrange
      final updateRequest = {'name': 'Duplicate Name'};

      when(mockDio.put('/api/v1/projects/123', data: updateRequest)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/projects/123'),
          response: Response(
            data: {'detail': 'Project name already exists'},
            statusCode: 409,
            requestOptions: RequestOptions(path: '/api/v1/projects/123'),
          ),
        ),
      );

      // Act & Assert
      expect(
        () => apiClient.updateProject('123', updateRequest),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ApiClient - Projects PATCH', () {
    test('archiveProject completes successfully', () async {
      // Arrange
      when(mockDio.patch('/api/v1/projects/123/archive')).thenAnswer(
        (_) async => Response(
          data: null,
          statusCode: 204,
          requestOptions: RequestOptions(path: '/api/v1/projects/123/archive'),
        ),
      );

      // Act
      await apiClient.archiveProject('123');

      // Assert
      verify(mockDio.patch('/api/v1/projects/123/archive')).called(1);
    });

    test('restoreProject completes successfully', () async {
      // Arrange
      when(mockDio.patch('/api/v1/projects/123/restore')).thenAnswer(
        (_) async => Response(
          data: null,
          statusCode: 204,
          requestOptions: RequestOptions(path: '/api/v1/projects/123/restore'),
        ),
      );

      // Act
      await apiClient.restoreProject('123');

      // Assert
      verify(mockDio.patch('/api/v1/projects/123/restore')).called(1);
    });
  });

  group('ApiClient - Projects DELETE', () {
    test('deleteProject completes successfully', () async {
      // Arrange
      when(mockDio.delete('/api/v1/projects/123')).thenAnswer(
        (_) async => Response(
          data: null,
          statusCode: 204,
          requestOptions: RequestOptions(path: '/api/v1/projects/123'),
        ),
      );

      // Act
      await apiClient.deleteProject('123');

      // Assert
      verify(mockDio.delete('/api/v1/projects/123')).called(1);
    });
  });

  group('ApiClient - Content Upload', () {
    test('uploadTextContent sends correct request with AI matching disabled', () async {
      // Arrange
      final responseData = {'content_id': 'content-123', 'status': 'processing'};

      when(mockDio.post(
        '/api/v1/projects/proj-1/upload/text',
        data: anyNamed('data'),
      )).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 201,
          requestOptions: RequestOptions(path: '/api/v1/projects/proj-1/upload/text'),
        ),
      );

      // Act
      final result = await apiClient.uploadTextContent(
        'proj-1',
        'meeting',
        'Q1 Planning',
        'Meeting notes here...',
        '2024-01-15',
        useAiMatching: false,
      );

      // Assert
      expect(result, responseData);
      final captured = verify(mockDio.post(
        '/api/v1/projects/proj-1/upload/text',
        data: captureAnyNamed('data'),
      )).captured.single as Map<String, dynamic>;

      expect(captured['content_type'], 'meeting');
      expect(captured['title'], 'Q1 Planning');
      expect(captured['content'], 'Meeting notes here...');
      expect(captured['date'], '2024-01-15');
      expect(captured['use_ai_matching'], false);
    });

    test('uploadTextContent handles empty date', () async {
      // Arrange
      when(mockDio.post(
        '/api/v1/projects/proj-1/upload/text',
        data: anyNamed('data'),
      )).thenAnswer(
        (_) async => Response(
          data: {},
          statusCode: 201,
          requestOptions: RequestOptions(path: '/api/v1/projects/proj-1/upload/text'),
        ),
      );

      // Act
      await apiClient.uploadTextContent(
        'proj-1',
        'email',
        'Test Email',
        'Content',
        '',
      );

      // Assert
      final captured = verify(mockDio.post(
        '/api/v1/projects/proj-1/upload/text',
        data: captureAnyNamed('data'),
      )).captured.single as Map<String, dynamic>;

      expect(captured['date'], null);
    });

    test('uploadContentWithAIMatching sends correct request', () async {
      // Arrange
      final responseData = {'matched_project_id': 'proj-123', 'confidence': 0.95};

      when(mockDio.post(
        '/api/v1/upload/with-ai-matching',
        data: anyNamed('data'),
      )).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 201,
          requestOptions: RequestOptions(path: '/api/v1/upload/with-ai-matching'),
        ),
      );

      // Act
      final result = await apiClient.uploadContentWithAIMatching(
        'meeting',
        'Sprint Planning',
        'Meeting content',
        '2024-01-20',
      );

      // Assert
      expect(result, responseData);
      final captured = verify(mockDio.post(
        '/api/v1/upload/with-ai-matching',
        data: captureAnyNamed('data'),
      )).captured.single as Map<String, dynamic>;

      expect(captured['use_ai_matching'], true);
    });
  });

  group('ApiClient - Query Endpoints', () {
    test('queryProject sends correct request', () async {
      // Arrange
      final queryRequest = {'question': 'What was discussed?'};
      final queryResponse = {
        'answer': 'We discussed the Q1 roadmap',
        'sources': [],
        'confidence': 0.89,
      };

      when(mockDio.post('/api/v1/projects/proj-1/query', data: queryRequest))
          .thenAnswer(
        (_) async => Response(
          data: queryResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/projects/proj-1/query'),
        ),
      );

      // Act
      final result = await apiClient.queryProject('proj-1', queryRequest);

      // Assert
      expect(result, queryResponse);
      verify(mockDio.post('/api/v1/projects/proj-1/query', data: queryRequest))
          .called(1);
    });

    test('queryProgram sends correct request', () async {
      // Arrange
      final queryRequest = {'question': 'Show me risks'};
      final queryResponse = {'answer': 'Here are the risks...', 'sources': []};

      when(mockDio.post('/api/v1/projects/program/prog-1/query', data: queryRequest))
          .thenAnswer(
        (_) async => Response(
          data: queryResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/projects/program/prog-1/query'),
        ),
      );

      // Act
      final result = await apiClient.queryProgram('prog-1', queryRequest);

      // Assert
      expect(result, queryResponse);
    });

    test('queryPortfolio sends correct request', () async {
      // Arrange
      final queryRequest = {'question': 'Status update?'};
      final queryResponse = {'answer': 'Status is...', 'sources': []};

      when(mockDio.post(
        '/api/v1/projects/portfolio/port-1/query',
        data: queryRequest,
      )).thenAnswer(
        (_) async => Response(
          data: queryResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/projects/portfolio/port-1/query'),
        ),
      );

      // Act
      final result = await apiClient.queryPortfolio('port-1', queryRequest);

      // Assert
      expect(result, queryResponse);
    });

    test('queryOrganization sends correct request', () async {
      // Arrange
      final queryRequest = {'question': 'Overall progress?'};
      final queryResponse = {'answer': 'Progress is...', 'sources': []};

      when(mockDio.post(
        '/api/v1/projects/organization/query',
        data: queryRequest,
      )).thenAnswer(
        (_) async => Response(
          data: queryResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/projects/organization/query'),
        ),
      );

      // Act
      final result = await apiClient.queryOrganization(queryRequest);

      // Assert
      expect(result, queryResponse);
    });
  });

  group('ApiClient - Conversations', () {
    test('getConversations returns list', () async {
      // Arrange
      final conversationsData = [
        {'id': 'conv-1', 'title': 'Conversation 1'},
        {'id': 'conv-2', 'title': 'Conversation 2'},
      ];

      when(mockDio.get('/api/v1/projects/proj-1/conversations')).thenAnswer(
        (_) async => Response(
          data: conversationsData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/projects/proj-1/conversations'),
        ),
      );

      // Act
      final result = await apiClient.getConversations('proj-1');

      // Assert
      expect(result, conversationsData);
      expect(result.length, 2);
    });

    test('createConversation returns created conversation', () async {
      // Arrange
      final conversationRequest = {'title': 'New Chat'};
      final conversationResponse = {'id': 'conv-new', 'title': 'New Chat'};

      when(mockDio.post(
        '/api/v1/projects/proj-1/conversations',
        data: conversationRequest,
      )).thenAnswer(
        (_) async => Response(
          data: conversationResponse,
          statusCode: 201,
          requestOptions: RequestOptions(path: '/api/v1/projects/proj-1/conversations'),
        ),
      );

      // Act
      final result = await apiClient.createConversation('proj-1', conversationRequest);

      // Assert
      expect(result, conversationResponse);
    });

    test('updateConversation returns updated conversation', () async {
      // Arrange
      final updateRequest = {'title': 'Updated Title'};
      final updateResponse = {'id': 'conv-1', 'title': 'Updated Title'};

      when(mockDio.put(
        '/api/v1/projects/proj-1/conversations/conv-1',
        data: updateRequest,
      )).thenAnswer(
        (_) async => Response(
          data: updateResponse,
          statusCode: 200,
          requestOptions:
              RequestOptions(path: '/api/v1/projects/proj-1/conversations/conv-1'),
        ),
      );

      // Act
      final result =
          await apiClient.updateConversation('proj-1', 'conv-1', updateRequest);

      // Assert
      expect(result, updateResponse);
    });

    test('getConversation returns single conversation', () async {
      // Arrange
      final conversationData = {'id': 'conv-1', 'title': 'Test Conversation'};

      when(mockDio.get('/api/v1/projects/proj-1/conversations/conv-1')).thenAnswer(
        (_) async => Response(
          data: conversationData,
          statusCode: 200,
          requestOptions:
              RequestOptions(path: '/api/v1/projects/proj-1/conversations/conv-1'),
        ),
      );

      // Act
      final result = await apiClient.getConversation('proj-1', 'conv-1');

      // Assert
      expect(result, conversationData);
    });

    test('deleteConversation completes successfully', () async {
      // Arrange
      when(mockDio.delete('/api/v1/projects/proj-1/conversations/conv-1')).thenAnswer(
        (_) async => Response(
          data: null,
          statusCode: 204,
          requestOptions:
              RequestOptions(path: '/api/v1/projects/proj-1/conversations/conv-1'),
        ),
      );

      // Act
      await apiClient.deleteConversation('proj-1', 'conv-1');

      // Assert
      verify(mockDio.delete('/api/v1/projects/proj-1/conversations/conv-1')).called(1);
    });
  });

  group('ApiClient - Summaries', () {
    test('generateUnifiedSummary sends correct request', () async {
      // Arrange
      final summaryRequest = {
        'entity_type': 'project',
        'entity_id': 'proj-1',
        'summary_type': 'weekly',
      };
      final summaryResponse = {'summary_id': 'sum-123', 'status': 'processing'};

      when(mockDio.post('/api/v1/summaries/generate', data: summaryRequest)).thenAnswer(
        (_) async => Response(
          data: summaryResponse,
          statusCode: 201,
          requestOptions: RequestOptions(path: '/api/v1/summaries/generate'),
        ),
      );

      // Act
      final result = await apiClient.generateUnifiedSummary(summaryRequest);

      // Assert
      expect(result, summaryResponse);
    });

    test('getSummaryById returns summary', () async {
      // Arrange
      final summaryData = {'id': 'sum-123', 'content': 'Summary content'};

      when(mockDio.get('/api/v1/summaries/sum-123')).thenAnswer(
        (_) async => Response(
          data: summaryData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/summaries/sum-123'),
        ),
      );

      // Act
      final result = await apiClient.getSummaryById('sum-123');

      // Assert
      expect(result, summaryData);
    });

    test('listSummaries with all filters', () async {
      // Arrange
      final summariesData = [
        {'id': 'sum-1', 'title': 'Summary 1'},
        {'id': 'sum-2', 'title': 'Summary 2'},
      ];

      when(mockDio.post('/api/v1/summaries/list', data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          data: summariesData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/summaries/list'),
        ),
      );

      // Act
      final result = await apiClient.listSummaries(
        entityType: 'project',
        entityId: 'proj-1',
        summaryType: 'weekly',
        format: 'markdown',
        createdAfter: DateTime(2024, 1, 1),
        createdBefore: DateTime(2024, 12, 31),
        limit: 50,
        offset: 10,
      );

      // Assert
      expect(result, summariesData);
      final captured = verify(mockDio.post(
        '/api/v1/summaries/list',
        data: captureAnyNamed('data'),
      )).captured.single as Map<String, dynamic>;

      expect(captured['entity_type'], 'project');
      expect(captured['entity_id'], 'proj-1');
      expect(captured['summary_type'], 'weekly');
      expect(captured['format'], 'markdown');
      expect(captured['limit'], 50);
      expect(captured['offset'], 10);
      expect(captured['created_after'], isNotNull);
      expect(captured['created_before'], isNotNull);
    });

    test('listSummaries with minimal filters', () async {
      // Arrange
      when(mockDio.post('/api/v1/summaries/list', data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          data: [],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/summaries/list'),
        ),
      );

      // Act
      await apiClient.listSummaries();

      // Assert
      final captured = verify(mockDio.post(
        '/api/v1/summaries/list',
        data: captureAnyNamed('data'),
      )).captured.single as Map<String, dynamic>;

      expect(captured['limit'], 100);
      expect(captured['offset'], 0);
      expect(captured.containsKey('entity_type'), false);
    });

    test('updateSummary returns updated summary', () async {
      // Arrange
      final updateData = {'content': 'Updated content'};
      final updateResponse = {'id': 'sum-123', 'content': 'Updated content'};

      when(mockDio.put('/api/v1/summaries/sum-123', data: updateData)).thenAnswer(
        (_) async => Response(
          data: updateResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/summaries/sum-123'),
        ),
      );

      // Act
      final result = await apiClient.updateSummary('sum-123', updateData);

      // Assert
      expect(result, updateResponse);
    });

    test('deleteSummary returns response', () async {
      // Arrange
      final deleteResponse = {'message': 'Deleted successfully'};

      when(mockDio.delete('/api/v1/summaries/sum-123')).thenAnswer(
        (_) async => Response(
          data: deleteResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/summaries/sum-123'),
        ),
      );

      // Act
      final result = await apiClient.deleteSummary('sum-123');

      // Assert
      expect(result, deleteResponse);
    });
  });

  group('ApiClient - Content Endpoints', () {
    test('getProjectContent with filters', () async {
      // Arrange
      final contentData = [
        {'id': 'content-1', 'type': 'meeting'},
        {'id': 'content-2', 'type': 'meeting'},
      ];

      when(mockDio.get(
        '/api/v1/projects/proj-1/content',
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer(
        (_) async => Response(
          data: contentData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/projects/proj-1/content'),
        ),
      );

      // Act
      final result = await apiClient.getProjectContent(
        'proj-1',
        contentType: 'meeting',
        limit: 10,
      );

      // Assert
      expect(result, contentData);
      final captured = verify(mockDio.get(
        '/api/v1/projects/proj-1/content',
        queryParameters: captureAnyNamed('queryParameters'),
      )).captured.single as Map<String, dynamic>;

      expect(captured['content_type'], 'meeting');
      expect(captured['limit'], 10);
    });

    test('getContent returns single content item', () async {
      // Arrange
      final contentData = {'id': 'content-123', 'title': 'Meeting Notes'};

      when(mockDio.get('/api/v1/projects/proj-1/content/content-123')).thenAnswer(
        (_) async => Response(
          data: contentData,
          statusCode: 200,
          requestOptions:
              RequestOptions(path: '/api/v1/projects/proj-1/content/content-123'),
        ),
      );

      // Act
      final result = await apiClient.getContent('proj-1', 'content-123');

      // Assert
      expect(result, contentData);
    });
  });

  group('ApiClient - Admin Endpoints', () {
    test('resetDatabase sends correct request with API key', () async {
      // Arrange
      final confirmation = {'confirm': 'RESET_ALL_DATA'};
      final responseData = {'message': 'Database reset successfully'};

      when(mockDio.delete(
        '/api/v1/admin/reset',
        data: confirmation,
        options: anyNamed('options'),
      )).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/admin/reset'),
        ),
      );

      // Act
      final result = await apiClient.resetDatabase('test-api-key', confirmation);

      // Assert
      expect(result, responseData);
      final captured = verify(mockDio.delete(
        '/api/v1/admin/reset',
        data: confirmation,
        options: captureAnyNamed('options'),
      )).captured.single as Options;

      expect(captured.headers?['X-API-Key'], 'test-api-key');
    });
  });
}
