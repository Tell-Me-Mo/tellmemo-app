import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'dio_client.dart';

class ApiService {
  final ApiClient client;

  ApiService(this.client);

  Future<List<Map<String, dynamic>>> getProjectActivities(String projectId) async {
    try {
      final response = await client.dio.get(
        '/api/v1/projects/$projectId/activities',
      );
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Failed to fetch activities: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentActivities(List<String> projectIds) async {
    try {
      final response = await client.dio.get(
        '/api/v1/activities/recent',
        queryParameters: {
          'project_ids': projectIds.join(','),
        },
      );
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Failed to fetch recent activities: $e');
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  final client = ApiClient(DioClient.instance);
  return ApiService(client);
});