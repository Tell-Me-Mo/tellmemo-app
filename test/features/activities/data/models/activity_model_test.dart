import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/activities/data/models/activity_model.dart';
import 'package:pm_master_v2/features/activities/domain/entities/activity.dart';

void main() {
  group('ActivityModel', () {
    group('fromJson', () {
      test('creates ActivityModel from complete JSON', () {
        final json = {
          'id': '123',
          'project_id': 'proj-456',
          'type': 'project_created',
          'title': 'New Project',
          'description': 'A new project was created',
          'metadata': '{"key": "value"}',
          'timestamp': '2024-01-15T10:30:00Z',
          'user_id': 'user-789',
          'user_name': 'John Doe',
        };

        final model = ActivityModel.fromJson(json);

        expect(model.id, '123');
        expect(model.projectId, 'proj-456');
        expect(model.type, 'project_created');
        expect(model.title, 'New Project');
        expect(model.description, 'A new project was created');
        expect(model.metadata, '{"key": "value"}');
        expect(model.timestamp.isUtc, true);
        expect(model.timestamp.year, 2024);
        expect(model.timestamp.month, 1);
        expect(model.timestamp.day, 15);
        expect(model.timestamp.hour, 10);
        expect(model.timestamp.minute, 30);
        expect(model.userId, 'user-789');
        expect(model.userName, 'John Doe');
      });

      test('creates ActivityModel from minimal JSON', () {
        final json = {
          'id': '123',
          'project_id': 'proj-456',
          'type': 'project_updated',
          'title': 'Update',
          'description': 'Updated',
          'timestamp': '2024-01-15T10:30:00Z',
        };

        final model = ActivityModel.fromJson(json);

        expect(model.id, '123');
        expect(model.projectId, 'proj-456');
        expect(model.type, 'project_updated');
        expect(model.metadata, isNull);
        expect(model.userId, isNull);
        expect(model.userName, isNull);
      });

      test('parses timestamp without Z suffix as UTC', () {
        final json = {
          'id': '123',
          'project_id': 'proj-456',
          'type': 'content_uploaded',
          'title': 'Content',
          'description': 'Uploaded',
          'timestamp': '2024-01-15T10:30:00',
        };

        final model = ActivityModel.fromJson(json);

        expect(model.timestamp.isUtc, true);
        expect(model.timestamp.year, 2024);
        expect(model.timestamp.month, 1);
        expect(model.timestamp.day, 15);
      });

      test('converts non-UTC timestamp to UTC', () {
        final json = {
          'id': '123',
          'project_id': 'proj-456',
          'type': 'summary_generated',
          'title': 'Summary',
          'description': 'Generated',
          'timestamp': '2024-01-15T10:30:00+05:00',
        };

        final model = ActivityModel.fromJson(json);

        expect(model.timestamp.isUtc, true);
        // The UTC time should be 5 hours earlier
        expect(model.timestamp.hour, 5);
        expect(model.timestamp.minute, 30);
      });
    });

    group('toJson', () {
      test('serializes ActivityModel to JSON with all fields', () {
        final timestamp = DateTime.utc(2024, 1, 15, 10, 30);
        final model = ActivityModel(
          id: '123',
          projectId: 'proj-456',
          type: 'project_created',
          title: 'New Project',
          description: 'Created',
          metadata: '{"key": "value"}',
          timestamp: timestamp,
          userId: 'user-789',
          userName: 'John Doe',
        );

        final json = model.toJson();

        expect(json['id'], '123');
        expect(json['project_id'], 'proj-456');
        expect(json['type'], 'project_created');
        expect(json['title'], 'New Project');
        expect(json['description'], 'Created');
        expect(json['metadata'], '{"key": "value"}');
        expect(json['timestamp'], '2024-01-15T10:30:00.000Z');
        expect(json['user_id'], 'user-789');
        expect(json['user_name'], 'John Doe');
      });

      test('serializes ActivityModel to JSON with null fields', () {
        final timestamp = DateTime.utc(2024, 1, 15, 10, 30);
        final model = ActivityModel(
          id: '123',
          projectId: 'proj-456',
          type: 'project_updated',
          title: 'Update',
          description: 'Updated',
          timestamp: timestamp,
        );

        final json = model.toJson();

        expect(json['metadata'], isNull);
        expect(json['user_id'], isNull);
        expect(json['user_name'], isNull);
      });

      test('converts local timestamp to UTC in JSON', () {
        final localTime = DateTime(2024, 1, 15, 15, 30); // Local time
        final model = ActivityModel(
          id: '123',
          projectId: 'proj-456',
          type: 'content_uploaded',
          title: 'Content',
          description: 'Uploaded',
          timestamp: localTime,
        );

        final json = model.toJson();

        // Should be in UTC format
        expect(json['timestamp'], contains('Z'));
        expect(json['timestamp'], contains('T'));
      });
    });

    group('toEntity', () {
      test('converts ActivityModel to Activity entity', () {
        final timestamp = DateTime.utc(2024, 1, 15, 10, 30);
        final model = ActivityModel(
          id: '123',
          projectId: 'proj-456',
          type: 'project_created',
          title: 'New Project',
          description: 'Created',
          metadata: '{"key": "value"}',
          timestamp: timestamp,
          userId: 'user-789',
          userName: 'John Doe',
        );

        final entity = model.toEntity();

        expect(entity.id, '123');
        expect(entity.projectId, 'proj-456');
        expect(entity.type, ActivityType.projectCreated);
        expect(entity.title, 'New Project');
        expect(entity.description, 'Created');
        expect(entity.metadata, '{"key": "value"}');
        expect(entity.timestamp.isUtc, false); // Should be converted to local
        expect(entity.userId, 'user-789');
        expect(entity.userName, 'John Doe');
      });

      test('parses all activity types correctly', () {
        final types = {
          'project_created': ActivityType.projectCreated,
          'project_updated': ActivityType.projectUpdated,
          'project_deleted': ActivityType.projectDeleted,
          'content_uploaded': ActivityType.contentUploaded,
          'summary_generated': ActivityType.summaryGenerated,
          'query_submitted': ActivityType.querySubmitted,
          'report_generated': ActivityType.reportGenerated,
          'member_added': ActivityType.memberAdded,
          'member_removed': ActivityType.memberRemoved,
        };

        for (final entry in types.entries) {
          final model = ActivityModel(
            id: '123',
            projectId: 'proj-456',
            type: entry.key,
            title: 'Test',
            description: 'Test',
            timestamp: DateTime.utc(2024, 1, 15, 10, 30),
          );

          final entity = model.toEntity();
          expect(entity.type, entry.value, reason: 'Failed for type: ${entry.key}');
        }
      });

      test('uses default type for unknown activity type', () {
        final model = ActivityModel(
          id: '123',
          projectId: 'proj-456',
          type: 'unknown_type',
          title: 'Test',
          description: 'Test',
          timestamp: DateTime.utc(2024, 1, 15, 10, 30),
        );

        final entity = model.toEntity();

        expect(entity.type, ActivityType.projectUpdated); // Default fallback
      });

      test('converts UTC timestamp to local time', () {
        final utcTime = DateTime.utc(2024, 1, 15, 10, 30);
        final model = ActivityModel(
          id: '123',
          projectId: 'proj-456',
          type: 'content_uploaded',
          title: 'Content',
          description: 'Uploaded',
          timestamp: utcTime,
        );

        final entity = model.toEntity();

        expect(entity.timestamp.isUtc, false);
        // The date values should match the local conversion
        expect(entity.timestamp.toUtc().year, 2024);
        expect(entity.timestamp.toUtc().month, 1);
        expect(entity.timestamp.toUtc().day, 15);
      });
    });

    group('round-trip conversion', () {
      test('JSON -> Model -> JSON preserves data', () {
        final originalJson = {
          'id': '123',
          'project_id': 'proj-456',
          'type': 'summary_generated',
          'title': 'Summary',
          'description': 'Generated summary',
          'metadata': '{"tokens": 1000}',
          'timestamp': '2024-01-15T10:30:00Z',
          'user_id': 'user-789',
          'user_name': 'Jane Smith',
        };

        final model = ActivityModel.fromJson(originalJson);
        final resultJson = model.toJson();

        expect(resultJson['id'], originalJson['id']);
        expect(resultJson['project_id'], originalJson['project_id']);
        expect(resultJson['type'], originalJson['type']);
        expect(resultJson['title'], originalJson['title']);
        expect(resultJson['description'], originalJson['description']);
        expect(resultJson['metadata'], originalJson['metadata']);
        expect(resultJson['user_id'], originalJson['user_id']);
        expect(resultJson['user_name'], originalJson['user_name']);
        // Timestamp format may differ slightly, but should represent same time
        expect(resultJson['timestamp'], contains('2024-01-15T10:30:00'));
      });

      test('JSON -> Model -> Entity maintains data integrity', () {
        final json = {
          'id': '123',
          'project_id': 'proj-456',
          'type': 'query_submitted',
          'title': 'New Query',
          'description': 'User submitted a query',
          'timestamp': '2024-01-15T10:30:00Z',
          'user_id': 'user-789',
          'user_name': 'John Doe',
        };

        final model = ActivityModel.fromJson(json);
        final entity = model.toEntity();

        expect(entity.id, json['id']);
        expect(entity.projectId, json['project_id']);
        expect(entity.type, ActivityType.querySubmitted);
        expect(entity.title, json['title']);
        expect(entity.description, json['description']);
        expect(entity.userId, json['user_id']);
        expect(entity.userName, json['user_name']);
      });
    });

    group('edge cases', () {
      test('handles empty strings', () {
        final json = {
          'id': '',
          'project_id': '',
          'type': 'project_created',
          'title': '',
          'description': '',
          'timestamp': '2024-01-15T10:30:00Z',
        };

        final model = ActivityModel.fromJson(json);

        expect(model.id, '');
        expect(model.projectId, '');
        expect(model.title, '');
        expect(model.description, '');
      });

      test('handles very long strings', () {
        final longString = 'A' * 10000;
        final json = {
          'id': '123',
          'project_id': 'proj-456',
          'type': 'report_generated',
          'title': longString,
          'description': longString,
          'metadata': longString,
          'timestamp': '2024-01-15T10:30:00Z',
        };

        final model = ActivityModel.fromJson(json);

        expect(model.title.length, 10000);
        expect(model.description.length, 10000);
        expect(model.metadata?.length, 10000);
      });

      test('handles special characters in strings', () {
        final json = {
          'id': '123',
          'project_id': 'proj-456',
          'type': 'member_added',
          'title': 'Test "quotes" and \'apostrophes\'',
          'description': 'Special chars: <>&\n\t\r',
          'metadata': '{"emoji": "😀🎉"}',
          'timestamp': '2024-01-15T10:30:00Z',
          'user_name': 'O\'Brien',
        };

        final model = ActivityModel.fromJson(json);

        expect(model.title, contains('quotes'));
        expect(model.description, contains('Special'));
        expect(model.metadata, contains('emoji'));
        expect(model.userName, contains('O\'Brien'));
      });
    });
  });

  group('UtcDateTimeConverter', () {
    const converter = UtcDateTimeConverter();

    test('fromJson parses UTC timestamp', () {
      final result = converter.fromJson('2024-01-15T10:30:00Z');

      expect(result.isUtc, true);
      expect(result.year, 2024);
      expect(result.month, 1);
      expect(result.day, 15);
      expect(result.hour, 10);
      expect(result.minute, 30);
    });

    test('fromJson converts non-UTC to UTC', () {
      final result = converter.fromJson('2024-01-15T10:30:00');

      expect(result.isUtc, true);
    });

    test('toJson converts DateTime to ISO 8601 UTC', () {
      final dateTime = DateTime(2024, 1, 15, 10, 30);
      final result = converter.toJson(dateTime);

      expect(result, contains('T'));
      expect(result, endsWith('Z'));
      expect(result, contains('2024-01-15'));
    });

    test('toJson converts local DateTime to UTC', () {
      final localTime = DateTime(2024, 1, 15, 10, 30);
      final result = converter.toJson(localTime);

      expect(result, endsWith('Z'));
    });
  });
}
