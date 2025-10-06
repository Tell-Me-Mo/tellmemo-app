import 'package:dio/dio.dart';
import '../../domain/models/integration.dart';

class IntegrationsService {
  final Dio _dio;

  IntegrationsService(this._dio);

  Future<List<Integration>> getIntegrations() async {
    try {
      final response = await _dio.get('/api/integrations');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => _parseIntegration(json)).toList();
      } else {
        throw Exception('Failed to load integrations');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> connectIntegration(
    String integrationId,
    Map<String, dynamic> config,
  ) async {
    try {
      final response = await _dio.post(
        '/api/integrations/$integrationId/connect',
        data: {
          'api_key': config['apiKey'],
          'webhook_secret': config['webhookSecret'],
          'auto_sync': config['autoSync'] ?? true,
          'selected_project': config['selectedProject'],
          'custom_settings': config['customSettings'],
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to connect integration');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> disconnectIntegration(String integrationId) async {
    try {
      final response = await _dio.post(
        '/api/integrations/$integrationId/disconnect',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to disconnect integration');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> syncIntegration(String integrationId) async {
    try {
      final response = await _dio.post(
        '/api/integrations/$integrationId/sync',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to sync integration');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getIntegrationActivity(
    String integrationId, {
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/api/integrations/$integrationId/activity',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to load activity');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Integration _parseIntegration(Map<String, dynamic> json) {
    final type = _parseIntegrationType(json['type']);
    final status = _parseIntegrationStatus(json['status']);
    
    return Integration(
      id: json['id'],
      type: type,
      name: json['name'],
      description: _getIntegrationDescription(type),
      iconUrl: _getIntegrationIconUrl(type),
      status: status,
      connectedAt: json['connected_at'] != null
          ? DateTime.parse('${json['connected_at']}Z').toLocal()
          : null,
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.parse('${json['last_sync_at']}Z').toLocal()
          : null,
      configuration: json['configuration'],
      metadata: json['metadata'],
    );
  }

  IntegrationType _parseIntegrationType(String type) {
    switch (type) {
      case 'ai_brain':
      case 'aiBrain':
        return IntegrationType.aiBrain;
      case 'fireflies':
        return IntegrationType.fireflies;
      case 'slack':
        return IntegrationType.slack;
      case 'teams':
        return IntegrationType.teams;
      case 'zoom':
        return IntegrationType.zoom;
      case 'transcription':
        return IntegrationType.transcription;
      default:
        // Default to fireflies for unknown types
        return IntegrationType.fireflies;
    }
  }

  IntegrationStatus _parseIntegrationStatus(String status) {
    switch (status) {
      case 'connected':
        return IntegrationStatus.connected;
      case 'connecting':
        return IntegrationStatus.connecting;
      case 'error':
        return IntegrationStatus.error;
      case 'disconnected':
        return IntegrationStatus.disconnected;
      case 'not_connected':
      default:
        return IntegrationStatus.notConnected;
    }
  }

  String _getIntegrationDescription(IntegrationType type) {
    switch (type) {
      case IntegrationType.fireflies:
        return 'Automatically transcribe and analyze your meetings with AI-powered insights';
      case IntegrationType.slack:
        return 'Connect to Slack for meeting notifications and summaries';
      case IntegrationType.teams:
        return 'Integrate with Microsoft Teams for collaboration';
      case IntegrationType.zoom:
        return 'Connect Zoom meetings for automatic recording and transcription';
      case IntegrationType.transcription:
        return 'Configure audio transcription using local Whisper AI or cloud-based Salad API';
      case IntegrationType.aiBrain:
        return 'Configure AI providers for intelligent content analysis';
    }
  }

  String _getIntegrationIconUrl(IntegrationType type) {
    // These would be actual asset paths in production
    switch (type) {
      case IntegrationType.fireflies:
        return 'assets/icons/fireflies.png';
      case IntegrationType.slack:
        return 'assets/icons/slack.png';
      case IntegrationType.teams:
        return 'assets/icons/teams.png';
      case IntegrationType.zoom:
        return 'assets/icons/zoom.png';
      case IntegrationType.transcription:
        return 'assets/icons/transcription.png';
      case IntegrationType.aiBrain:
        return 'assets/icons/ai_brain.png';
    }
  }

  Exception _handleError(DioException error) {
    if (error.response != null) {
      final message = error.response?.data['detail'] ?? 
                     error.response?.data['message'] ?? 
                     'Server error';
      return Exception(message);
    } else {
      return Exception('Network error: ${error.message}');
    }
  }
}