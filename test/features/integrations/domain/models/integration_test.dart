import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/integrations/domain/models/integration.dart';

void main() {
  group('IntegrationType enum', () {
    test('has all expected values', () {
      expect(IntegrationType.values, [
        IntegrationType.aiBrain,
        IntegrationType.fireflies,
        IntegrationType.slack,
        IntegrationType.teams,
        IntegrationType.zoom,
        IntegrationType.transcription,
      ]);
    });
  });

  group('IntegrationStatus enum', () {
    test('has all expected values', () {
      expect(IntegrationStatus.values, [
        IntegrationStatus.notConnected,
        IntegrationStatus.connecting,
        IntegrationStatus.connected,
        IntegrationStatus.error,
        IntegrationStatus.disconnected,
      ]);
    });
  });

  group('Integration model', () {
    group('fromJson', () {
      test('creates Integration from complete JSON', () {
        final json = {
          'id': 'int-123',
          'type': 'fireflies',
          'name': 'Fireflies.ai',
          'description': 'Meeting transcription service',
          'iconUrl': 'https://example.com/icon.png',
          'status': 'connected',
          'configuration': {
            'apiKey': 'test-key',
            'autoRecord': true,
          },
          'connectedAt': '2024-01-15T10:00:00Z',
          'lastSyncAt': '2024-01-15T12:00:00Z',
          'errorMessage': null,
          'metadata': {'version': '1.0'},
        };

        final integration = Integration.fromJson(json);

        expect(integration.id, 'int-123');
        expect(integration.type, IntegrationType.fireflies);
        expect(integration.name, 'Fireflies.ai');
        expect(integration.description, 'Meeting transcription service');
        expect(integration.iconUrl, 'https://example.com/icon.png');
        expect(integration.status, IntegrationStatus.connected);
        expect(integration.configuration, {'apiKey': 'test-key', 'autoRecord': true});
        expect(integration.connectedAt, DateTime.parse('2024-01-15T10:00:00Z'));
        expect(integration.lastSyncAt, DateTime.parse('2024-01-15T12:00:00Z'));
        expect(integration.errorMessage, null);
        expect(integration.metadata, {'version': '1.0'});
      });

      test('creates Integration from minimal JSON', () {
        final json = {
          'id': 'int-456',
          'type': 'slack',
          'name': 'Slack',
          'description': 'Team communication',
          'iconUrl': 'https://example.com/slack.png',
          'status': 'notConnected',
        };

        final integration = Integration.fromJson(json);

        expect(integration.id, 'int-456');
        expect(integration.type, IntegrationType.slack);
        expect(integration.name, 'Slack');
        expect(integration.status, IntegrationStatus.notConnected);
        expect(integration.configuration, null);
        expect(integration.connectedAt, null);
        expect(integration.lastSyncAt, null);
        expect(integration.errorMessage, null);
        expect(integration.metadata, null);
      });

      test('handles all IntegrationType values', () {
        final types = {
          'aiBrain': IntegrationType.aiBrain,
          'fireflies': IntegrationType.fireflies,
          'slack': IntegrationType.slack,
          'teams': IntegrationType.teams,
          'zoom': IntegrationType.zoom,
          'transcription': IntegrationType.transcription,
        };

        for (final entry in types.entries) {
          final json = {
            'id': '1',
            'type': entry.key,
            'name': 'Test',
            'description': 'Test',
            'iconUrl': 'url',
            'status': 'notConnected',
          };

          final integration = Integration.fromJson(json);
          expect(integration.type, entry.value);
        }
      });

      test('handles all IntegrationStatus values', () {
        final statuses = {
          'notConnected': IntegrationStatus.notConnected,
          'connecting': IntegrationStatus.connecting,
          'connected': IntegrationStatus.connected,
          'error': IntegrationStatus.error,
          'disconnected': IntegrationStatus.disconnected,
        };

        for (final entry in statuses.entries) {
          final json = {
            'id': '1',
            'type': 'fireflies',
            'name': 'Test',
            'description': 'Test',
            'iconUrl': 'url',
            'status': entry.key,
          };

          final integration = Integration.fromJson(json);
          expect(integration.status, entry.value);
        }
      });
    });

    group('toJson', () {
      test('serializes Integration with all fields', () {
        final integration = Integration(
          id: 'int-789',
          type: IntegrationType.teams,
          name: 'Microsoft Teams',
          description: 'Video conferencing',
          iconUrl: 'https://example.com/teams.png',
          status: IntegrationStatus.connected,
          configuration: {'setting': 'value'},
          connectedAt: DateTime.parse('2024-01-15T10:00:00Z'),
          lastSyncAt: DateTime.parse('2024-01-15T12:00:00Z'),
          errorMessage: 'Test error',
          metadata: {'key': 'value'},
        );

        final json = integration.toJson();

        expect(json['id'], 'int-789');
        expect(json['type'], 'teams');
        expect(json['name'], 'Microsoft Teams');
        expect(json['description'], 'Video conferencing');
        expect(json['iconUrl'], 'https://example.com/teams.png');
        expect(json['status'], 'connected');
        expect(json['configuration'], {'setting': 'value'});
        expect(json['connectedAt'], '2024-01-15T10:00:00.000Z');
        expect(json['lastSyncAt'], '2024-01-15T12:00:00.000Z');
        expect(json['errorMessage'], 'Test error');
        expect(json['metadata'], {'key': 'value'});
      });

      test('serializes Integration with minimal fields', () {
        final integration = Integration(
          id: 'int-999',
          type: IntegrationType.zoom,
          name: 'Zoom',
          description: 'Video meetings',
          iconUrl: 'https://example.com/zoom.png',
          status: IntegrationStatus.notConnected,
        );

        final json = integration.toJson();

        expect(json['id'], 'int-999');
        expect(json['type'], 'zoom');
        expect(json['status'], 'notConnected');
        expect(json.containsKey('configuration'), true);
        expect(json.containsKey('connectedAt'), true);
        expect(json.containsKey('lastSyncAt'), true);
      });
    });

    group('round-trip conversion', () {
      test('preserves all data through JSON round-trip', () {
        final original = Integration(
          id: 'int-round',
          type: IntegrationType.fireflies,
          name: 'Fireflies',
          description: 'Transcription',
          iconUrl: 'icon.png',
          status: IntegrationStatus.connected,
          configuration: {'key': 'value'},
          connectedAt: DateTime.parse('2024-01-15T10:00:00Z'),
          lastSyncAt: DateTime.parse('2024-01-15T12:00:00Z'),
          errorMessage: 'error',
          metadata: {'meta': 'data'},
        );

        final json = original.toJson();
        final recovered = Integration.fromJson(json);

        expect(recovered.id, original.id);
        expect(recovered.type, original.type);
        expect(recovered.name, original.name);
        expect(recovered.description, original.description);
        expect(recovered.iconUrl, original.iconUrl);
        expect(recovered.status, original.status);
        expect(recovered.configuration, original.configuration);
        expect(recovered.connectedAt, original.connectedAt);
        expect(recovered.lastSyncAt, original.lastSyncAt);
        expect(recovered.errorMessage, original.errorMessage);
        expect(recovered.metadata, original.metadata);
      });
    });

    group('copyWith', () {
      test('copies with updated status', () {
        final integration = Integration(
          id: 'int-1',
          type: IntegrationType.fireflies,
          name: 'Fireflies',
          description: 'Test',
          iconUrl: 'icon',
          status: IntegrationStatus.notConnected,
        );

        final updated = integration.copyWith(status: IntegrationStatus.connected);

        expect(updated.status, IntegrationStatus.connected);
        expect(updated.id, integration.id);
        expect(updated.name, integration.name);
      });

      test('copies with updated configuration', () {
        final integration = Integration(
          id: 'int-2',
          type: IntegrationType.slack,
          name: 'Slack',
          description: 'Test',
          iconUrl: 'icon',
          status: IntegrationStatus.notConnected,
        );

        final updated = integration.copyWith(
          configuration: {'apiKey': 'new-key'},
        );

        expect(updated.configuration, {'apiKey': 'new-key'});
        expect(updated.id, integration.id);
      });
    });
  });

  group('IntegrationConfig model', () {
    group('fromJson', () {
      test('creates IntegrationConfig from complete JSON', () {
        final json = {
          'integrationId': 'int-123',
          'type': 'fireflies',
          'apiKey': 'test-key',
          'apiSecret': 'test-secret',
          'webhookUrl': 'https://webhook.com',
          'webhookSecret': 'webhook-secret',
          'customSettings': {'setting1': 'value1'},
          'autoSync': true,
          'syncIntervalMinutes': 30,
          'allowedProjects': ['proj-1', 'proj-2'],
        };

        final config = IntegrationConfig.fromJson(json);

        expect(config.integrationId, 'int-123');
        expect(config.type, IntegrationType.fireflies);
        expect(config.apiKey, 'test-key');
        expect(config.apiSecret, 'test-secret');
        expect(config.webhookUrl, 'https://webhook.com');
        expect(config.webhookSecret, 'webhook-secret');
        expect(config.customSettings, {'setting1': 'value1'});
        expect(config.autoSync, true);
        expect(config.syncIntervalMinutes, 30);
        expect(config.allowedProjects, ['proj-1', 'proj-2']);
      });

      test('creates IntegrationConfig from minimal JSON', () {
        final json = {
          'integrationId': 'int-456',
          'type': 'slack',
        };

        final config = IntegrationConfig.fromJson(json);

        expect(config.integrationId, 'int-456');
        expect(config.type, IntegrationType.slack);
        expect(config.apiKey, null);
        expect(config.apiSecret, null);
        expect(config.autoSync, null);
      });
    });

    group('toJson', () {
      test('serializes IntegrationConfig with all fields', () {
        final config = IntegrationConfig(
          integrationId: 'int-789',
          type: IntegrationType.teams,
          apiKey: 'key',
          apiSecret: 'secret',
          webhookUrl: 'url',
          webhookSecret: 'webhook',
          customSettings: {'key': 'value'},
          autoSync: false,
          syncIntervalMinutes: 60,
          allowedProjects: ['proj-3'],
        );

        final json = config.toJson();

        expect(json['integrationId'], 'int-789');
        expect(json['type'], 'teams');
        expect(json['apiKey'], 'key');
        expect(json['autoSync'], false);
        expect(json['syncIntervalMinutes'], 60);
      });
    });
  });

  group('FirefliesData model', () {
    group('fromJson', () {
      test('creates FirefliesData from complete JSON', () {
        final json = {
          'transcriptId': 'tr-123',
          'title': 'Team Meeting',
          'transcript': 'Meeting transcript text',
          'meetingDate': '2024-01-15T14:00:00Z',
          'duration': 3600,
          'participants': ['Alice', 'Bob'],
          'meetingUrl': 'https://meeting.com/123',
          'recordingUrl': 'https://recording.com/123',
          'metadata': {'topic': 'Planning'},
        };

        final data = FirefliesData.fromJson(json);

        expect(data.transcriptId, 'tr-123');
        expect(data.title, 'Team Meeting');
        expect(data.transcript, 'Meeting transcript text');
        expect(data.meetingDate, DateTime.parse('2024-01-15T14:00:00Z'));
        expect(data.duration, 3600);
        expect(data.participants, ['Alice', 'Bob']);
        expect(data.meetingUrl, 'https://meeting.com/123');
        expect(data.recordingUrl, 'https://recording.com/123');
        expect(data.metadata, {'topic': 'Planning'});
      });

      test('creates FirefliesData from minimal JSON', () {
        final json = {
          'transcriptId': 'tr-456',
          'title': 'Quick Sync',
          'transcript': 'Short meeting',
          'meetingDate': '2024-01-15T10:00:00Z',
          'duration': 900,
        };

        final data = FirefliesData.fromJson(json);

        expect(data.transcriptId, 'tr-456');
        expect(data.title, 'Quick Sync');
        expect(data.participants, null);
        expect(data.meetingUrl, null);
        expect(data.recordingUrl, null);
        expect(data.metadata, null);
      });
    });

    group('toJson', () {
      test('serializes FirefliesData with all fields', () {
        final data = FirefliesData(
          transcriptId: 'tr-789',
          title: 'Planning Session',
          transcript: 'Full transcript',
          meetingDate: DateTime.parse('2024-01-15T15:00:00Z'),
          duration: 7200,
          participants: ['Charlie', 'Diana'],
          meetingUrl: 'https://meet.com',
          recordingUrl: 'https://rec.com',
          metadata: {'status': 'completed'},
        );

        final json = data.toJson();

        expect(json['transcriptId'], 'tr-789');
        expect(json['title'], 'Planning Session');
        expect(json['duration'], 7200);
        expect(json['participants'], ['Charlie', 'Diana']);
      });
    });

    group('round-trip conversion', () {
      test('preserves all data through JSON round-trip', () {
        final original = FirefliesData(
          transcriptId: 'tr-round',
          title: 'Test Meeting',
          transcript: 'Test transcript',
          meetingDate: DateTime.parse('2024-01-15T16:00:00Z'),
          duration: 1800,
          participants: ['Eve', 'Frank'],
          meetingUrl: 'url',
          recordingUrl: 'rec-url',
          metadata: {'key': 'value'},
        );

        final json = original.toJson();
        final recovered = FirefliesData.fromJson(json);

        expect(recovered.transcriptId, original.transcriptId);
        expect(recovered.title, original.title);
        expect(recovered.transcript, original.transcript);
        expect(recovered.meetingDate, original.meetingDate);
        expect(recovered.duration, original.duration);
        expect(recovered.participants, original.participants);
        expect(recovered.meetingUrl, original.meetingUrl);
        expect(recovered.recordingUrl, original.recordingUrl);
        expect(recovered.metadata, original.metadata);
      });
    });
  });
}
