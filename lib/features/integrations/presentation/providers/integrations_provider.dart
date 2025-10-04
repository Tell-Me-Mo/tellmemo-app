import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/integration.dart';
import '../../data/services/integrations_service.dart';

part 'integrations_provider.g.dart';

final integrationsServiceProvider = Provider<IntegrationsService>((ref) {
  return IntegrationsService();
});

@riverpod
class Integrations extends _$Integrations {
  late final IntegrationsService _service;

  @override
  Future<List<Integration>> build() async {
    // Keep alive with auto-dispose after 5 minutes of inactivity
    final link = ref.keepAlive();
    Timer(const Duration(minutes: 5), link.close);

    _service = ref.watch(integrationsServiceProvider);

    try {
      // Fetch from backend API
      return await _service.getIntegrations();
    } catch (e) {
      // Fallback to static list if API fails
      return _getAvailableIntegrations();
    }
  }

  List<Integration> _getAvailableIntegrations() {
    return [
      Integration(
        id: 'ai_brain',
        type: IntegrationType.aiBrain,
        name: 'AI Brain',
        description: 'Configure AI providers (Claude, OpenAI) for intelligent meeting analysis and summaries',
        iconUrl: 'assets/icons/ai_brain.png',
        status: IntegrationStatus.notConnected,
        metadata: {
          'features': [
            'Multiple AI providers',
            'Claude 3.5 models',
            'OpenAI GPT-4 models',
            'Automatic provider switching',
            'Cost optimization',
          ],
          'isCore': true,  // Mark as core integration
        },
      ),
      Integration(
        id: 'fireflies',
        type: IntegrationType.fireflies,
        name: 'Fireflies.ai',
        description: 'Automatically transcribe and analyze your meetings with AI-powered insights',
        iconUrl: 'assets/icons/fireflies.png',
        status: IntegrationStatus.notConnected,
        metadata: {
          'features': [
            'Automatic transcription',
            'Meeting summaries',
            'Action items extraction',
            'Webhook integration',
          ],
        },
      ),
      Integration(
        id: 'transcription',
        type: IntegrationType.transcription,
        name: 'Transcription Service',
        description: 'Configure audio transcription using local Whisper AI or cloud-based Salad API',
        iconUrl: 'assets/icons/transcription.png',
        status: IntegrationStatus.notConnected,
        metadata: {
          'features': [
            'Local Whisper AI (large-v3-turbo)',
            'Cloud Salad API',
            'Multi-language support',
            'Real-time processing',
          ],
        },
      ),
    ];
  }

  Future<void> connectIntegration(String integrationId, Map<String, dynamic> config) async {
    state = const AsyncValue.loading();
    
    try {
      // Call the actual API
      await _service.connectIntegration(integrationId, config);
      
      // Refresh the integrations list
      final updatedIntegrations = await _service.getIntegrations();
      state = AsyncValue.data(updatedIntegrations);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> disconnectIntegration(String integrationId) async {
    state = const AsyncValue.loading();
    
    try {
      // Call the actual API
      await _service.disconnectIntegration(integrationId);
      
      // Refresh the integrations list
      final updatedIntegrations = await _service.getIntegrations();
      state = AsyncValue.data(updatedIntegrations);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshIntegrationStatus(String integrationId) async {
    try {
      await _service.syncIntegration(integrationId);
      // Refresh the integrations list
      final updatedIntegrations = await _service.getIntegrations();
      state = AsyncValue.data(updatedIntegrations);
    } catch (e) {
      // Don't update state on error for refresh
    }
  }

  void updateIntegration(Integration updatedIntegration) {
    state.whenData((integrations) {
      final updatedList = integrations.map((integration) {
        if (integration.id == updatedIntegration.id) {
          return updatedIntegration;
        }
        return integration;
      }).toList();
      state = AsyncValue.data(updatedList);
    });
  }
}

@riverpod
Future<Integration?> firefliesIntegration(Ref ref) async {
  // Keep alive with auto-dispose after 5 minutes of inactivity
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 5), link.close);

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