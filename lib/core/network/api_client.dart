import 'package:dio/dio.dart';
import '../../features/projects/data/models/project_model.dart';

class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  // Expose Dio instance for legacy ApiService
  Dio get dio => _dio;

  // Health check
  Future<dynamic> healthCheck() async {
    final response = await _dio.get('/api/v1/health');
    return response.data;
  }

  // Projects endpoints
  Future<List<ProjectModel>> getProjects() async {
    final response = await _dio.get('/api/v1/projects/');
    final List<dynamic> data = response.data;
    return data.map((json) => ProjectModel.fromJson(json)).toList();
  }

  Future<ProjectModel> getProject(String id) async {
    final response = await _dio.get('/api/v1/projects/$id');
    return ProjectModel.fromJson(response.data);
  }

  Future<ProjectModel> createProject(Map<String, dynamic> project) async {
    try {
      final response = await _dio.post('/api/v1/projects/', data: project);
      return ProjectModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final errorMessage = e.response?.data['detail'] ?? 'Project name already exists';
        throw Exception(errorMessage);
      }
      throw Exception(e.response?.data['detail'] ?? 'Failed to create project');
    }
  }

  Future<ProjectModel> updateProject(String id, Map<String, dynamic> project) async {
    try {
      final response = await _dio.put('/api/v1/projects/$id', data: project);
      return ProjectModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final errorMessage = e.response?.data['detail'] ?? 'Project name already exists';
        throw Exception(errorMessage);
      }
      throw Exception(e.response?.data['detail'] ?? 'Failed to update project');
    }
  }

  Future<void> archiveProject(String id) async {
    await _dio.patch('/api/v1/projects/$id/archive');
  }

  Future<void> restoreProject(String id) async {
    await _dio.patch('/api/v1/projects/$id/restore');
  }

  Future<void> deleteProject(String id) async {
    await _dio.delete('/api/v1/projects/$id');
  }

  // Text content upload with optional AI matching
  Future<dynamic> uploadTextContent(
    String projectId,
    String contentType,
    String title,
    String content,
    String date, {
    bool useAiMatching = false,
  }) async {
    final requestData = {
      'content_type': contentType,
      'title': title,
      'content': content,
      'date': date.isNotEmpty ? date : null,
      'use_ai_matching': useAiMatching,
    };
    final response = await _dio.post('/api/v1/projects/$projectId/upload/text', data: requestData);
    return response.data;
  }
  
  // Upload content with AI project matching
  Future<dynamic> uploadContentWithAIMatching(
    String contentType,
    String title,
    String content,
    String date,
  ) async {
    final requestData = {
      'content_type': contentType,
      'title': title,
      'content': content,
      'date': date.isNotEmpty ? date : null,
      'use_ai_matching': true,
    };
    final response = await _dio.post('/api/v1/upload/with-ai-matching', data: requestData);
    return response.data;
  }

  // File upload with optional AI matching
  Future<dynamic> uploadFile({
    required String projectId,
    required MultipartFile file,
    required String contentType,
    required String title,
    required String date,
    bool useAiMatching = false,
  }) async {
    final formData = FormData.fromMap({
      'file': file,
      'content_type': contentType,
      'title': title,
      'content_date': date.isNotEmpty ? date : null,
      'use_ai_matching': useAiMatching,
    });
    final response = await _dio.post('/api/v1/projects/$projectId/upload', data: formData);
    return response.data;
  }

  // Audio transcription with optional AI matching
  Future<dynamic> transcribeAudio({
    required String projectId,
    required MultipartFile audioFile,
    required String meetingTitle,
    String language = 'en',
    bool useAiMatching = false,
  }) async {
    final formData = FormData.fromMap({
      'audio_file': audioFile,
      'project_id': projectId,
      'meeting_title': meetingTitle,
      'language': language,
      'use_ai_matching': useAiMatching,
    });
    final response = await _dio.post('/api/v1/transcribe', data: formData);
    return response.data;
  }

  // Query
  Future<dynamic> queryProject(String projectId, Map<String, dynamic> query) async {
    final response = await _dio.post('/api/v1/projects/$projectId/query', data: query);
    return response.data;
  }

  Future<dynamic> queryProgram(String programId, Map<String, dynamic> query) async {
    final response = await _dio.post('/api/v1/projects/program/$programId/query', data: query);
    return response.data;
  }

  Future<dynamic> queryPortfolio(String portfolioId, Map<String, dynamic> query) async {
    final response = await _dio.post('/api/v1/projects/portfolio/$portfolioId/query', data: query);
    return response.data;
  }

  Future<dynamic> queryOrganization(Map<String, dynamic> query) async {
    final response = await _dio.post('/api/v1/projects/organization/query', data: query);
    return response.data;
  }

  // Conversations
  Future<List<dynamic>> getConversations(String projectId, {String? contextId}) async {
    final response = await _dio.get(
      '/api/v1/projects/$projectId/conversations',
      queryParameters: contextId != null ? {'context_id': contextId} : null,
    );
    return response.data;
  }

  Future<dynamic> createConversation(
    String projectId,
    Map<String, dynamic> conversation,
  ) async {
    final response = await _dio.post(
      '/api/v1/projects/$projectId/conversations',
      data: conversation,
    );
    return response.data;
  }

  Future<dynamic> updateConversation(
    String projectId,
    String conversationId,
    Map<String, dynamic> conversation,
  ) async {
    final response = await _dio.put(
      '/api/v1/projects/$projectId/conversations/$conversationId',
      data: conversation,
    );
    return response.data;
  }

  Future<dynamic> getConversation(
    String projectId,
    String conversationId,
  ) async {
    final response = await _dio.get(
      '/api/v1/projects/$projectId/conversations/$conversationId',
    );
    return response.data;
  }

  Future<void> deleteConversation(
    String projectId,
    String conversationId,
  ) async {
    await _dio.delete('/api/v1/projects/$projectId/conversations/$conversationId');
  }


  // Unified Summary Generation
  Future<dynamic> generateUnifiedSummary(Map<String, dynamic> request) async {
    final response = await _dio.post('/api/v1/summaries/generate', data: request);
    return response.data;
  }


  // Get summary by ID (unified endpoint)
  Future<dynamic> getSummaryById(String summaryId) async {
    final response = await _dio.get('/api/v1/summaries/$summaryId');
    return response.data;
  }

  // List summaries with filters (unified endpoint)
  Future<List<dynamic>> listSummaries({
    String? entityType,
    String? entityId,
    String? summaryType,
    String? format,
    DateTime? createdAfter,
    DateTime? createdBefore,
    int limit = 100,
    int offset = 0,
  }) async {
    final filters = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };

    if (entityType != null) filters['entity_type'] = entityType;
    if (entityId != null) filters['entity_id'] = entityId;
    if (summaryType != null) filters['summary_type'] = summaryType;
    if (format != null) filters['format'] = format;
    if (createdAfter != null) filters['created_after'] = createdAfter.toIso8601String();
    if (createdBefore != null) filters['created_before'] = createdBefore.toIso8601String();

    final response = await _dio.post('/api/v1/summaries/list', data: filters);
    return response.data;
  }

  // Update summary (unified endpoint)
  Future<dynamic> updateSummary(String summaryId, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/v1/summaries/$summaryId', data: data);
    return response.data;
  }

  // Delete summary (unified endpoint)
  Future<dynamic> deleteSummary(String summaryId) async {
    final response = await _dio.delete('/api/v1/summaries/$summaryId');
    return response.data;
  }


  // Hierarchy summary endpoints
  Future<List<dynamic>> getProgramSummaries(String programId, {int? limit}) async {
    final queryParams = <String, dynamic>{};
    if (limit != null) queryParams['limit'] = limit;

    final response = await _dio.get(
      '/api/v1/hierarchy/program/$programId/summaries',
      queryParameters: queryParams,
    );
    return response.data;
  }

  Future<List<dynamic>> getPortfolioSummaries(String portfolioId, {int? limit}) async {
    final queryParams = <String, dynamic>{};
    if (limit != null) queryParams['limit'] = limit;

    final response = await _dio.get(
      '/api/v1/hierarchy/portfolio/$portfolioId/summaries',
      queryParameters: queryParams,
    );
    return response.data;
  }


  // Content endpoints
  Future<List<dynamic>> getProjectContent(
    String projectId, {
    String? contentType,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{};
    if (contentType != null) queryParams['content_type'] = contentType;
    if (limit != null) queryParams['limit'] = limit;

    final response = await _dio.get(
      '/api/v1/projects/$projectId/content',
      queryParameters: queryParams,
    );
    return response.data;
  }

  Future<dynamic> getContent(String projectId, String contentId) async {
    final response = await _dio.get('/api/v1/projects/$projectId/content/$contentId');
    return response.data;
  }

  // Admin reset (development only)
  Future<dynamic> resetDatabase(String apiKey, Map<String, dynamic> confirmation) async {
    final response = await _dio.delete(
      '/api/v1/admin/reset',
      data: confirmation,
      options: Options(headers: {'X-API-Key': apiKey}),
    );
    return response.data;
  }
}