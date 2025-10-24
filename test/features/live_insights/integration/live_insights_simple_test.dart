import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/live_insights/domain/models/live_insight_model.dart';

void main() {
  group('Live Insights Model Integration Tests', () {
    test('LiveInsightModel fromJson parses correctly', () {
      final json = {
        'insight_id': 'test_123',
        'type': 'decision',  // snake_case as per JsonValue annotation
        'priority': 'high',
        'content': 'Agreed to use GraphQL for the API',
        'context': 'Team discussion',
        'timestamp': '2025-10-19T12:00:00Z',
        'assigned_to': 'John',
        'due_date': 'Friday',
        'confidence_score': 0.92,
        'source_chunk_index': 0,
        'related_content_ids': [],
      };

      final insight = LiveInsightModel.fromJson(json);

      expect(insight.insightId, equals('test_123'));
      expect(insight.type, equals(LiveInsightType.decision));
      expect(insight.priority, equals(LiveInsightPriority.high));
      expect(insight.content, equals('Agreed to use GraphQL for the API'));
      expect(insight.assignedTo, equals('John'));
      expect(insight.confidenceScore, equals(0.92));
    });

    test('TranscriptChunk fromJson parses correctly', () {
      final json = {
        'chunkIndex': 0,
        'text': 'Test transcript text',
        'speaker': 'John Doe',
        'timestamp': '2025-10-19T12:00:00Z',
      };

      final chunk = TranscriptChunk.fromJson(json);

      expect(chunk.chunkIndex, equals(0));
      expect(chunk.text, equals('Test transcript text'));
      expect(chunk.speaker, equals('John Doe'));
    });

    test('InsightsExtractionResult fromJson parses correctly', () {
      final json = {
        'chunk_index': 0,
        'insights': [
          {
            'insight_id': 'test_1',
            'type': 'decision',
            'priority': 'critical',
            'content': 'Use GraphQL',
            'context': 'Tech decision',
            'timestamp': '2025-10-19T12:00:00Z',
            'confidence_score': 0.95,
            'source_chunk_index': 0,
            'related_content_ids': [],
          }
        ],
        'total_insights': 1,
        'processing_time_ms': 1500,
        'timestamp': '2025-10-19T12:00:00Z',
      };

      final result = InsightsExtractionResult.fromJson(json);

      expect(result.chunkIndex, equals(0));
      expect(result.insights.length, equals(1));
      expect(result.insights[0].type, equals(LiveInsightType.decision));
      expect(result.totalInsights, equals(1));
      expect(result.processingTimeMs, equals(1500));
    });

    test('SessionMetrics fromJson parses correctly', () {
      final json = {
        'session_duration_seconds': 120.5,
        'chunks_processed': 12,
        'total_insights': 8,
        'insights_by_type': {
          'decision': 5,
          'risk': 3,
        },
        'avg_processing_time_ms': 1920.0,
        'avg_transcription_time_ms': 850.0,
      };

      final metrics = SessionMetrics.fromJson(json);

      expect(metrics.sessionDurationSeconds, equals(120.5));
      expect(metrics.chunksProcessed, equals(12));
      expect(metrics.totalInsights, equals(8));
      expect(metrics.insightsByType['decision'], equals(5));
      expect(metrics.insightsByType['risk'], equals(3));
      expect(metrics.avgProcessingTimeMs, equals(1920.0));
    });

    test('LiveInsightType enum has all expected values', () {
      expect(LiveInsightType.values.length, equals(2));
      expect(LiveInsightType.values.contains(LiveInsightType.decision), isTrue);
      expect(LiveInsightType.values.contains(LiveInsightType.risk), isTrue);
    });

    test('LiveInsightPriority enum has all expected values', () {
      expect(LiveInsightPriority.values.length, equals(4));
      expect(LiveInsightPriority.values.contains(LiveInsightPriority.critical), isTrue);
      expect(LiveInsightPriority.values.contains(LiveInsightPriority.high), isTrue);
      expect(LiveInsightPriority.values.contains(LiveInsightPriority.medium), isTrue);
      expect(LiveInsightPriority.values.contains(LiveInsightPriority.low), isTrue);
    });

    test('handles multiple insights of different types', () {
      final insights = [
        {
          'insight_id': '1',
          'type': 'decision',
          'priority': 'critical',
          'content': 'Decision 1',
          'context': 'Context 1',
          'timestamp': '2025-10-19T12:00:00Z',
          'confidence_score': 0.95,
          'source_chunk_index': 0,
          'related_content_ids': [],
        },
        {
          'insight_id': '2',
          'type': 'risk',
          'priority': 'high',
          'content': 'Risk 1',
          'context': 'Context 2',
          'timestamp': '2025-10-19T12:00:00Z',
          'confidence_score': 0.85,
          'source_chunk_index': 0,
          'related_content_ids': [],
        },
      ];

      final parsedInsights = insights
          .map((json) => LiveInsightModel.fromJson(json))
          .toList();

      expect(parsedInsights.length, equals(2));
      expect(parsedInsights[0].type, equals(LiveInsightType.decision));
      expect(parsedInsights[1].type, equals(LiveInsightType.risk));
    });

    test('LiveInsightMessage fromJson handles different message types', () {
      final sessionInitJson = {
        'type': 'session_initialized',
        'timestamp': '2025-10-19T12:00:00Z',
        'session_id': 'session_123',
        'project_id': 'project_456',
      };

      final message = LiveInsightMessage.fromJson(sessionInitJson);

      expect(message.type, equals(LiveInsightMessageType.sessionInitialized));
      expect(message.sessionId, equals('session_123'));
    });
  });
}
