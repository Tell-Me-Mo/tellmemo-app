import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/integration.dart';
import 'integrations_provider.dart';

part 'fireflies_provider.g.dart';

@riverpod
Future<Integration?> firefliesIntegration(FirefliesIntegrationRef ref) async {
  final integrations = await ref.watch(integrationsProvider.future);
  return integrations.firstWhere(
    (i) => i.type == IntegrationType.fireflies,
    orElse: () => Integration(
      id: 'fireflies',
      type: IntegrationType.fireflies,
      name: 'Fireflies.ai',
      description: 'Automatically transcribe and analyze your meetings',
      iconUrl: 'assets/icons/fireflies.png',
      status: IntegrationStatus.notConnected,
    ),
  );
}

@riverpod
Future<List<Map<String, dynamic>>> firefliesActivity(FirefliesActivityRef ref) async {
  // TODO: Fetch actual activity from backend
  // For now, return sample data
  await Future.delayed(const Duration(seconds: 1));
  
  final integration = await ref.watch(firefliesIntegrationProvider.future);
  
  if (integration?.status != IntegrationStatus.connected) {
    return [];
  }
  
  return [
    {
      'id': '1',
      'type': 'import',
      'title': 'Meeting imported',
      'description': 'Weekly team standup - 45 minutes',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'success',
    },
    {
      'id': '2',
      'type': 'sync',
      'title': 'Sync completed',
      'description': '3 new meetings found',
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'status': 'success',
    },
    {
      'id': '3',
      'type': 'import',
      'title': 'Meeting imported',
      'description': 'Client review session - 60 minutes',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'success',
    },
    {
      'id': '4',
      'type': 'connect',
      'title': 'Integration connected',
      'description': 'Successfully connected to Fireflies',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'status': 'success',
    },
  ];
}

@riverpod
class FirefliesWebhook extends _$FirefliesWebhook {
  @override
  Future<void> build() async {
    // Initialize webhook handler
  }

  Future<Map<String, dynamic>> processWebhook(Map<String, dynamic> payload) async {
    // Extract meeting data from Fireflies webhook payload
    final transcriptId = payload['id'] as String?;
    final title = payload['title'] as String? ?? 'Untitled Meeting';
    final transcript = payload['transcript'] as String? ?? '';
    final meetingDateStr = payload['date'] as String?;
    final duration = payload['duration'] as int? ?? 0;
    final participants = (payload['participants'] as List<dynamic>?)
        ?.map((p) => p.toString())
        .toList();
    final meetingUrl = payload['meeting_url'] as String?;
    final recordingUrl = payload['recording_url'] as String?;
    
    final meetingDate = meetingDateStr != null
        ? DateTime.parse('${meetingDateStr}Z').toLocal()
        : DateTime.now();
    
    // Create FirefliesData object
    final firefliesData = FirefliesData(
      transcriptId: transcriptId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      transcript: transcript,
      meetingDate: meetingDate,
      duration: duration,
      participants: participants,
      meetingUrl: meetingUrl,
      recordingUrl: recordingUrl,
      metadata: payload,
    );
    
    // Process the data through existing upload flow
    return await _processFirefliesData(firefliesData);
  }
  
  Future<Map<String, dynamic>> _processFirefliesData(FirefliesData data) async {
    // TODO: Integrate with existing upload flow
    // This should:
    // 1. Get the configured project ID (or use default)
    // 2. Format the transcript data
    // 3. Call the upload provider to process the content
    // 4. Return the result
    
    return {
      'success': true,
      'contentId': 'generated-content-id',
      'jobId': 'generated-job-id',
      'message': 'Meeting transcript imported successfully',
    };
  }
}