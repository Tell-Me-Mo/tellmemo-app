import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/content/data/models/content_status_model.dart';

void main() {
  group('ContentStatusModel', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final testEstimatedCompletion = DateTime(2024, 1, 15, 11, 0);

    group('fromJson', () {
      test('creates instance with complete JSON', () {
        final json = {
          'content_id': 'content-1',
          'project_id': 'proj-1',
          'status': 'processing',
          'processing_message': 'Analyzing chunks',
          'progress_percentage': 65,
          'chunk_count': 42,
          'summary_generated': true,
          'summary_id': 'summary-1',
          'error_message': null,
          'created_at': testDate.toIso8601String(),
          'updated_at': testDate.toIso8601String(),
          'estimated_completion': testEstimatedCompletion.toIso8601String(),
        };

        final model = ContentStatusModel.fromJson(json);

        expect(model.contentId, 'content-1');
        expect(model.projectId, 'proj-1');
        expect(model.status, ProcessingStatus.processing);
        expect(model.processingMessage, 'Analyzing chunks');
        expect(model.progressPercentage, 65);
        expect(model.chunkCount, 42);
        expect(model.summaryGenerated, true);
        expect(model.summaryId, 'summary-1');
        expect(model.errorMessage, null);
        expect(model.createdAt, testDate);
        expect(model.updatedAt, testDate);
        expect(model.estimatedCompletion, testEstimatedCompletion);
      });

      test('creates instance with minimal JSON (defaults applied)', () {
        final json = {
          'content_id': 'content-2',
          'project_id': 'proj-2',
          'status': 'queued',
          'created_at': testDate.toIso8601String(),
          'updated_at': testDate.toIso8601String(),
        };

        final model = ContentStatusModel.fromJson(json);

        expect(model.contentId, 'content-2');
        expect(model.projectId, 'proj-2');
        expect(model.status, ProcessingStatus.queued);
        expect(model.processingMessage, null);
        expect(model.progressPercentage, 0);
        expect(model.chunkCount, 0);
        expect(model.summaryGenerated, false);
        expect(model.summaryId, null);
        expect(model.errorMessage, null);
        expect(model.estimatedCompletion, null);
      });

      test('parses all status enum values correctly', () {
        final statuses = ['queued', 'processing', 'completed', 'failed'];
        final expected = [
          ProcessingStatus.queued,
          ProcessingStatus.processing,
          ProcessingStatus.completed,
          ProcessingStatus.failed,
        ];

        for (var i = 0; i < statuses.length; i++) {
          final json = {
            'content_id': 'content-$i',
            'project_id': 'proj-1',
            'status': statuses[i],
            'created_at': testDate.toIso8601String(),
            'updated_at': testDate.toIso8601String(),
          };

          final model = ContentStatusModel.fromJson(json);
          expect(model.status, expected[i], reason: 'Failed for status: ${statuses[i]}');
        }
      });

      test('handles null optional fields correctly', () {
        final json = {
          'content_id': 'content-3',
          'project_id': 'proj-3',
          'status': 'completed',
          'processing_message': null,
          'summary_id': null,
          'error_message': null,
          'estimated_completion': null,
          'created_at': testDate.toIso8601String(),
          'updated_at': testDate.toIso8601String(),
        };

        final model = ContentStatusModel.fromJson(json);

        expect(model.processingMessage, null);
        expect(model.summaryId, null);
        expect(model.errorMessage, null);
        expect(model.estimatedCompletion, null);
      });
    });

    group('toJson', () {
      test('serializes complete model correctly', () {
        final model = ContentStatusModel(
          contentId: 'content-1',
          projectId: 'proj-1',
          status: ProcessingStatus.processing,
          processingMessage: 'Analyzing chunks',
          progressPercentage: 65,
          chunkCount: 42,
          summaryGenerated: true,
          summaryId: 'summary-1',
          errorMessage: null,
          createdAt: testDate,
          updatedAt: testDate,
          estimatedCompletion: testEstimatedCompletion,
        );

        final json = model.toJson();

        expect(json['content_id'], 'content-1');
        expect(json['project_id'], 'proj-1');
        expect(json['status'], 'processing');
        expect(json['processing_message'], 'Analyzing chunks');
        expect(json['progress_percentage'], 65);
        expect(json['chunk_count'], 42);
        expect(json['summary_generated'], true);
        expect(json['summary_id'], 'summary-1');
        expect(json['created_at'], testDate.toIso8601String());
        expect(json['updated_at'], testDate.toIso8601String());
        expect(json['estimated_completion'], testEstimatedCompletion.toIso8601String());
      });

      test('serializes model with null optional fields', () {
        final model = ContentStatusModel(
          contentId: 'content-2',
          projectId: 'proj-2',
          status: ProcessingStatus.queued,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = model.toJson();

        expect(json['processing_message'], null);
        expect(json['summary_id'], null);
        expect(json['error_message'], null);
        expect(json['estimated_completion'], null);
      });

      test('serializes all status enum values correctly', () {
        final statuses = [
          ProcessingStatus.queued,
          ProcessingStatus.processing,
          ProcessingStatus.completed,
          ProcessingStatus.failed,
        ];
        final expected = ['queued', 'processing', 'completed', 'failed'];

        for (var i = 0; i < statuses.length; i++) {
          final model = ContentStatusModel(
            contentId: 'content-$i',
            projectId: 'proj-1',
            status: statuses[i],
            createdAt: testDate,
            updatedAt: testDate,
          );

          final json = model.toJson();
          expect(json['status'], expected[i], reason: 'Failed for status: ${statuses[i]}');
        }
      });
    });

    group('Helper methods', () {
      test('isProcessing returns true only for processing status', () {
        final processing = ContentStatusModel(
          contentId: 'c1',
          projectId: 'p1',
          status: ProcessingStatus.processing,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final queued = ContentStatusModel(
          contentId: 'c2',
          projectId: 'p2',
          status: ProcessingStatus.queued,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final completed = ContentStatusModel(
          contentId: 'c3',
          projectId: 'p3',
          status: ProcessingStatus.completed,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final failed = ContentStatusModel(
          contentId: 'c4',
          projectId: 'p4',
          status: ProcessingStatus.failed,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(processing.isProcessing, true);
        expect(queued.isProcessing, false);
        expect(completed.isProcessing, false);
        expect(failed.isProcessing, false);
      });

      test('isCompleted returns true only for completed status', () {
        final processing = ContentStatusModel(
          contentId: 'c1',
          projectId: 'p1',
          status: ProcessingStatus.processing,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final queued = ContentStatusModel(
          contentId: 'c2',
          projectId: 'p2',
          status: ProcessingStatus.queued,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final completed = ContentStatusModel(
          contentId: 'c3',
          projectId: 'p3',
          status: ProcessingStatus.completed,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final failed = ContentStatusModel(
          contentId: 'c4',
          projectId: 'p4',
          status: ProcessingStatus.failed,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(processing.isCompleted, false);
        expect(queued.isCompleted, false);
        expect(completed.isCompleted, true);
        expect(failed.isCompleted, false);
      });

      test('isFailed returns true only for failed status', () {
        final processing = ContentStatusModel(
          contentId: 'c1',
          projectId: 'p1',
          status: ProcessingStatus.processing,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final queued = ContentStatusModel(
          contentId: 'c2',
          projectId: 'p2',
          status: ProcessingStatus.queued,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final completed = ContentStatusModel(
          contentId: 'c3',
          projectId: 'p3',
          status: ProcessingStatus.completed,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final failed = ContentStatusModel(
          contentId: 'c4',
          projectId: 'p4',
          status: ProcessingStatus.failed,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(processing.isFailed, false);
        expect(queued.isFailed, false);
        expect(completed.isFailed, false);
        expect(failed.isFailed, true);
      });

      test('isQueued returns true only for queued status', () {
        final processing = ContentStatusModel(
          contentId: 'c1',
          projectId: 'p1',
          status: ProcessingStatus.processing,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final queued = ContentStatusModel(
          contentId: 'c2',
          projectId: 'p2',
          status: ProcessingStatus.queued,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final completed = ContentStatusModel(
          contentId: 'c3',
          projectId: 'p3',
          status: ProcessingStatus.completed,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final failed = ContentStatusModel(
          contentId: 'c4',
          projectId: 'p4',
          status: ProcessingStatus.failed,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(processing.isQueued, false);
        expect(queued.isQueued, true);
        expect(completed.isQueued, false);
        expect(failed.isQueued, false);
      });
    });

    group('Round-trip conversion', () {
      test('JSON -> Model -> JSON preserves data', () {
        final originalJson = {
          'content_id': 'content-99',
          'project_id': 'proj-99',
          'status': 'completed',
          'processing_message': 'All done!',
          'progress_percentage': 100,
          'chunk_count': 50,
          'summary_generated': true,
          'summary_id': 'summary-99',
          'error_message': null,
          'created_at': testDate.toIso8601String(),
          'updated_at': testDate.toIso8601String(),
          'estimated_completion': null,
        };

        final model = ContentStatusModel.fromJson(originalJson);
        final resultJson = model.toJson();

        expect(resultJson['content_id'], originalJson['content_id']);
        expect(resultJson['project_id'], originalJson['project_id']);
        expect(resultJson['status'], originalJson['status']);
        expect(resultJson['processing_message'], originalJson['processing_message']);
        expect(resultJson['progress_percentage'], originalJson['progress_percentage']);
        expect(resultJson['chunk_count'], originalJson['chunk_count']);
        expect(resultJson['summary_generated'], originalJson['summary_generated']);
        expect(resultJson['summary_id'], originalJson['summary_id']);
      });
    });

    group('Edge cases', () {
      test('handles very long strings', () {
        final longMessage = 'A' * 1000;
        final json = {
          'content_id': 'content-long',
          'project_id': 'proj-long',
          'status': 'failed',
          'processing_message': longMessage,
          'error_message': longMessage,
          'created_at': testDate.toIso8601String(),
          'updated_at': testDate.toIso8601String(),
        };

        final model = ContentStatusModel.fromJson(json);

        expect(model.processingMessage, longMessage);
        expect(model.errorMessage, longMessage);
      });

      test('handles progress percentage edge values', () {
        final testCases = [0, 50, 100, -1, 101, 999];

        for (final value in testCases) {
          final json = {
            'content_id': 'content-$value',
            'project_id': 'proj-1',
            'status': 'processing',
            'progress_percentage': value,
            'created_at': testDate.toIso8601String(),
            'updated_at': testDate.toIso8601String(),
          };

          final model = ContentStatusModel.fromJson(json);
          expect(model.progressPercentage, value, reason: 'Failed for value: $value');
        }
      });

      test('handles chunk count edge values', () {
        final testCases = [0, 1, 100, 1000, 999999];

        for (final value in testCases) {
          final json = {
            'content_id': 'content-$value',
            'project_id': 'proj-1',
            'status': 'completed',
            'chunk_count': value,
            'created_at': testDate.toIso8601String(),
            'updated_at': testDate.toIso8601String(),
          };

          final model = ContentStatusModel.fromJson(json);
          expect(model.chunkCount, value, reason: 'Failed for value: $value');
        }
      });
    });
  });
}
