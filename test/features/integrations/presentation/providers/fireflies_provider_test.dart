import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/integrations/domain/models/integration.dart';
import 'package:pm_master_v2/features/integrations/presentation/providers/fireflies_provider.dart' as ff;
import 'package:pm_master_v2/features/integrations/presentation/providers/integrations_provider.dart';

void main() {
  group('Fireflies Provider Tests', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    group('firefliesIntegrationProvider', () {
      test('returns fireflies integration when it exists in integrations list', () async {
        // Arrange
        final firefliesIntegration = Integration(
          id: 'fireflies',
          type: IntegrationType.fireflies,
          name: 'Fireflies.ai',
          description: 'Meeting transcription',
          iconUrl: 'assets/icons/fireflies.png',
          status: IntegrationStatus.connected,
        );

        final otherIntegration = Integration(
          id: 'other',
          type: IntegrationType.aiBrain,
          name: 'Other Integration',
          description: 'Some other integration',
          iconUrl: 'assets/icons/other.png',
          status: IntegrationStatus.notConnected,
        );

        container = ProviderContainer(
          overrides: [
            // Override the integrationsProvider to return test data
            integrationsProvider.overrideWith(() {
              return MockIntegrations([otherIntegration, firefliesIntegration]);
            }),
          ],
        );

        // Act
        final integration = await container.read(ff.firefliesIntegrationProvider.future);

        // Assert
        expect(integration?.id, 'fireflies');
        expect(integration?.type, IntegrationType.fireflies);
        expect(integration?.status, IntegrationStatus.connected);
      });

      test('returns default fireflies integration when not found in integrations list', () async {
        // Arrange
        final otherIntegration = Integration(
          id: 'other',
          type: IntegrationType.aiBrain,
          name: 'Other Integration',
          description: 'Some other integration',
          iconUrl: 'assets/icons/other.png',
          status: IntegrationStatus.notConnected,
        );

        container = ProviderContainer(
          overrides: [
            integrationsProvider.overrideWith(() {
              return MockIntegrations([otherIntegration]);
            }),
          ],
        );

        // Act
        final integration = await container.read(ff.firefliesIntegrationProvider.future);

        // Assert
        expect(integration?.id, 'fireflies');
        expect(integration?.type, IntegrationType.fireflies);
        expect(integration?.name, 'Fireflies.ai');
        expect(integration?.status, IntegrationStatus.notConnected);
      });

      test('returns default fireflies integration when integrations list is empty', () async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            integrationsProvider.overrideWith(() {
              return MockIntegrations([]);
            }),
          ],
        );

        // Act
        final integration = await container.read(ff.firefliesIntegrationProvider.future);

        // Assert
        expect(integration?.id, 'fireflies');
        expect(integration?.type, IntegrationType.fireflies);
        expect(integration?.status, IntegrationStatus.notConnected);
      });
    });

    group('firefliesActivityProvider', () {
      test('returns empty list when fireflies is not connected', () async {
        // Arrange
        final firefliesIntegration = Integration(
          id: 'fireflies',
          type: IntegrationType.fireflies,
          name: 'Fireflies.ai',
          description: 'Meeting transcription',
          iconUrl: 'assets/icons/fireflies.png',
          status: IntegrationStatus.notConnected,
        );

        container = ProviderContainer(
          overrides: [
            integrationsProvider.overrideWith(() {
              return MockIntegrations([firefliesIntegration]);
            }),
          ],
        );

        // Act
        final activity = await container.read(ff.firefliesActivityProvider.future);

        // Assert
        expect(activity, isEmpty);
      });

      test('returns activity list when fireflies is connected', () async {
        // Arrange
        final firefliesIntegration = Integration(
          id: 'fireflies',
          type: IntegrationType.fireflies,
          name: 'Fireflies.ai',
          description: 'Meeting transcription',
          iconUrl: 'assets/icons/fireflies.png',
          status: IntegrationStatus.connected,
        );

        container = ProviderContainer(
          overrides: [
            integrationsProvider.overrideWith(() {
              return MockIntegrations([firefliesIntegration]);
            }),
          ],
        );

        // Act
        final activity = await container.read(ff.firefliesActivityProvider.future);

        // Assert
        expect(activity, isNotEmpty);
        expect(activity.length, greaterThan(0));

        // Check structure of first activity item
        final firstActivity = activity.first;
        expect(firstActivity.containsKey('id'), true);
        expect(firstActivity.containsKey('type'), true);
        expect(firstActivity.containsKey('title'), true);
        expect(firstActivity.containsKey('description'), true);
        expect(firstActivity.containsKey('timestamp'), true);
        expect(firstActivity.containsKey('status'), true);
      });
    });

    group('FirefliesWebhook', () {
      test('processes webhook payload successfully', () async {
        // Arrange
        container = ProviderContainer();

        final webhookPayload = {
          'id': 'transcript-123',
          'title': 'Team Standup',
          'transcript': 'This is the meeting transcript...',
          'date': '2024-01-15T10:00:00',
          'duration': 1800, // 30 minutes
          'participants': ['Alice', 'Bob', 'Charlie'],
          'meeting_url': 'https://fireflies.ai/meetings/123',
          'recording_url': 'https://fireflies.ai/recordings/123',
        };

        final notifier = container.read(ff.firefliesWebhookProvider.notifier);

        // Act
        final result = await notifier.processWebhook(webhookPayload);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['success'], true);
        expect(result.containsKey('contentId'), true);
        expect(result.containsKey('jobId'), true);
        expect(result.containsKey('message'), true);
      });

      test('processes webhook with minimal payload', () async {
        // Arrange
        container = ProviderContainer();

        final webhookPayload = {
          'id': 'transcript-456',
        };

        final notifier = container.read(ff.firefliesWebhookProvider.notifier);

        // Act
        final result = await notifier.processWebhook(webhookPayload);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['success'], true);
      });

      test('processes webhook with null values gracefully', () async {
        // Arrange
        container = ProviderContainer();

        final webhookPayload = {
          'id': null,
          'title': null,
          'transcript': null,
          'date': null,
          'duration': null,
          'participants': null,
          'meeting_url': null,
          'recording_url': null,
        };

        final notifier = container.read(ff.firefliesWebhookProvider.notifier);

        // Act
        final result = await notifier.processWebhook(webhookPayload);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['success'], true);
      });

      test('processes webhook with missing fields', () async {
        // Arrange
        container = ProviderContainer();

        final webhookPayload = <String, dynamic>{};

        final notifier = container.read(ff.firefliesWebhookProvider.notifier);

        // Act
        final result = await notifier.processWebhook(webhookPayload);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['success'], true);
      });
    });
  });
}

// Mock class for Integrations provider
class MockIntegrations extends Integrations {
  final List<Integration> mockIntegrations;

  MockIntegrations(this.mockIntegrations);

  @override
  Future<List<Integration>> build() async {
    return mockIntegrations;
  }
}
