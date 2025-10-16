import 'package:pm_master_v2/core/network/api_client.dart';

/// Mock API client for testing query provider
class MockApiClient implements ApiClient {
  // Response data
  Map<String, dynamic>? queryProjectResponse;
  Map<String, dynamic>? queryProgramResponse;
  Map<String, dynamic>? queryPortfolioResponse;
  Map<String, dynamic>? queryOrganizationResponse;
  List<dynamic>? getConversationsResponse;
  Map<String, dynamic>? createConversationResponse;
  Map<String, dynamic>? updateConversationResponse;

  // Call tracking
  bool queryProjectCalled = false;
  bool queryProgramCalled = false;
  bool queryPortfolioCalled = false;
  bool queryOrganizationCalled = false;
  Map<String, dynamic>? lastQueryProjectRequest;

  // Error simulation
  bool shouldThrowError = false;

  @override
  Future<dynamic> queryProject(String projectId, Map<String, dynamic> query) async {
    queryProjectCalled = true;
    lastQueryProjectRequest = query;

    if (shouldThrowError) {
      throw Exception('Query project failed');
    }

    return queryProjectResponse ?? {'answer': '', 'sources': [], 'confidence': 0.0};
  }

  @override
  Future<dynamic> queryProgram(String programId, Map<String, dynamic> query) async {
    queryProgramCalled = true;

    if (shouldThrowError) {
      throw Exception('Query program failed');
    }

    return queryProgramResponse ?? {'answer': '', 'sources': [], 'confidence': 0.0};
  }

  @override
  Future<dynamic> queryPortfolio(String portfolioId, Map<String, dynamic> query) async {
    queryPortfolioCalled = true;

    if (shouldThrowError) {
      throw Exception('Query portfolio failed');
    }

    return queryPortfolioResponse ?? {'answer': '', 'sources': [], 'confidence': 0.0};
  }

  @override
  Future<dynamic> queryOrganization(Map<String, dynamic> query) async {
    queryOrganizationCalled = true;

    if (shouldThrowError) {
      throw Exception('Query organization failed');
    }

    return queryOrganizationResponse ?? {'answer': '', 'sources': [], 'confidence': 0.0};
  }

  @override
  Future<List<dynamic>> getConversations(String projectId, {String? contextId}) async {
    if (shouldThrowError) {
      throw Exception('Get conversations failed');
    }

    return getConversationsResponse ?? [];
  }

  @override
  Future<dynamic> createConversation(
    String projectId,
    Map<String, dynamic> data,
  ) async {
    if (shouldThrowError) {
      throw Exception('Create conversation failed');
    }

    return createConversationResponse ?? {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      ...data,
    };
  }

  @override
  Future<dynamic> updateConversation(
    String projectId,
    String conversationId,
    Map<String, dynamic> data,
  ) async {
    if (shouldThrowError) {
      throw Exception('Update conversation failed');
    }

    return updateConversationResponse ?? {
      'id': conversationId,
      ...data,
    };
  }

  @override
  Future<void> deleteConversation(String projectId, String conversationId) async {
    if (shouldThrowError) {
      throw Exception('Delete conversation failed');
    }
  }

  // Implement all other ApiClient methods as noSuchMethod to avoid implementing entire interface
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
