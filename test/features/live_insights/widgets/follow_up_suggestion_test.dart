import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/live_insights/domain/models/proactive_assistance_model.dart';

/// Integration tests for Phase 5: Follow-up Suggestions
///
/// Tests the data models and JSON serialization for follow-up suggestions
/// in the Active Meeting Intelligence system.
///
/// Author: Claude Code AI Assistant
/// Date: October 20, 2025

void main() {
  group('FollowUpSuggestionAssistance Model Tests', () {
    test('should create FollowUpSuggestionAssistance with all fields', () {
      final assistance = FollowUpSuggestionAssistance(
        insightId: 'session_0_5',
        topic: 'Q4 budget update',
        reason: 'Discussed last week; update may be relevant',
        relatedContentId: 'content_123',
        relatedTitle: 'Q3 Planning Meeting',
        relatedDate: DateTime.parse('2025-10-13T14:30:00Z'),
        urgency: 'medium',
        contextSnippet: 'We allocated \$50K for Q4 marketing...',
        confidence: 0.78,
        timestamp: DateTime.parse('2025-10-20T15:30:00Z'),
      );

      expect(assistance.insightId, equals('session_0_5'));
      expect(assistance.topic, equals('Q4 budget update'));
      expect(assistance.urgency, equals('medium'));
      expect(assistance.confidence, equals(0.78));
      expect(assistance.relatedTitle, equals('Q3 Planning Meeting'));
    });

    test('should serialize FollowUpSuggestionAssistance to JSON', () {
      final assistance = FollowUpSuggestionAssistance(
        insightId: 'session_0_5',
        topic: 'Q4 budget update',
        reason: 'Discussed last week; update relevant',
        relatedContentId: 'content_123',
        relatedTitle: 'Q3 Planning Meeting',
        relatedDate: DateTime.parse('2025-10-13T14:30:00Z'),
        urgency: 'medium',
        contextSnippet: 'We allocated \$50K...',
        confidence: 0.78,
        timestamp: DateTime.parse('2025-10-20T15:30:00Z'),
      );

      final json = assistance.toJson();

      expect(json['insight_id'], equals('session_0_5'));
      expect(json['topic'], equals('Q4 budget update'));
      expect(json['urgency'], equals('medium'));
      expect(json['confidence'], equals(0.78));
      expect(json['related_title'], equals('Q3 Planning Meeting'));
    });

    test('should deserialize FollowUpSuggestionAssistance from JSON', () {
      final json = {
        'insight_id': 'session_0_5',
        'topic': 'Q4 budget update',
        'reason': 'Discussed last week; update relevant',
        'related_content_id': 'content_123',
        'related_title': 'Q3 Planning Meeting',
        'related_date': '2025-10-13T14:30:00.000Z',
        'urgency': 'medium',
        'context_snippet': 'We allocated \$50K...',
        'confidence': 0.78,
        'timestamp': '2025-10-20T15:30:00.000Z',
      };

      final assistance = FollowUpSuggestionAssistance.fromJson(json);

      expect(assistance.insightId, equals('session_0_5'));
      expect(assistance.topic, equals('Q4 budget update'));
      expect(assistance.urgency, equals('medium'));
      expect(assistance.confidence, equals(0.78));
    });
  });

  group('ProactiveAssistanceModel Follow-up Integration Tests', () {
    test('should parse follow_up_suggestion type correctly', () {
      final json = {
        'type': 'follow_up_suggestion',
        'insight_id': 'session_0_5',
        'topic': 'Q4 budget update',
        'reason': 'Discussed last week',
        'related_content_id': 'content_123',
        'related_title': 'Q3 Planning',
        'related_date': '2025-10-13T14:30:00.000Z',
        'urgency': 'medium',
        'context_snippet': 'Budget discussion...',
        'confidence': 0.78,
        'timestamp': '2025-10-20T15:30:00.000Z',
      };

      final model = ProactiveAssistanceModel.fromJson(json);

      expect(model.type, equals(ProactiveAssistanceType.followUpSuggestion));
      expect(model.followUpSuggestion, isNotNull);
      expect(model.followUpSuggestion!.topic, equals('Q4 budget update'));
      expect(model.followUpSuggestion!.urgency, equals('medium'));
    });

    test('should handle different urgency levels', () {
      final urgencyLevels = ['high', 'medium', 'low'];

      for (final urgency in urgencyLevels) {
        final json = {
          'type': 'follow_up_suggestion',
          'insight_id': 'test_${urgency}',
          'topic': 'Test topic',
          'reason': 'Test reason',
          'related_content_id': 'content_123',
          'related_title': 'Test Meeting',
          'related_date': '2025-10-13T14:30:00.000Z',
          'urgency': urgency,
          'context_snippet': 'Test snippet',
          'confidence': 0.75,
          'timestamp': '2025-10-20T15:30:00.000Z',
        };

        final model = ProactiveAssistanceModel.fromJson(json);

        expect(model.followUpSuggestion!.urgency, equals(urgency));
      }
    });

    test('should handle high confidence follow-up suggestions', () {
      final json = {
        'type': 'follow_up_suggestion',
        'insight_id': 'session_high_conf',
        'topic': 'Critical deadline',
        'reason': 'Blocking issue',
        'related_content_id': 'content_456',
        'related_title': 'Sprint Planning',
        'related_date': '2025-10-15T10:00:00.000Z',
        'urgency': 'high',
        'context_snippet': 'Critical path item...',
        'confidence': 0.95,
        'timestamp': '2025-10-20T15:30:00.000Z',
      };

      final model = ProactiveAssistanceModel.fromJson(json);

      expect(model.followUpSuggestion!.confidence, equals(0.95));
      expect(model.followUpSuggestion!.urgency, equals('high'));
    });

    test('should handle low confidence follow-up suggestions', () {
      final json = {
        'type': 'follow_up_suggestion',
        'insight_id': 'session_low_conf',
        'topic': 'Optional topic',
        'reason': 'Contextual information',
        'related_content_id': 'content_789',
        'related_title': 'Past Discussion',
        'related_date': '2025-09-20T14:00:00.000Z',
        'urgency': 'low',
        'context_snippet': 'Background context...',
        'confidence': 0.66,
        'timestamp': '2025-10-20T15:30:00.000Z',
      };

      final model = ProactiveAssistanceModel.fromJson(json);

      expect(model.followUpSuggestion!.confidence, equals(0.66));
      expect(model.followUpSuggestion!.urgency, equals('low'));
    });
  });

  group('Follow-up Suggestion Edge Cases', () {
    test('should handle empty context snippet', () {
      final json = {
        'type': 'follow_up_suggestion',
        'insight_id': 'session_empty',
        'topic': 'Test topic',
        'reason': 'Test reason',
        'related_content_id': 'content_123',
        'related_title': 'Test Meeting',
        'related_date': '2025-10-13T14:30:00.000Z',
        'urgency': 'medium',
        'context_snippet': '',
        'confidence': 0.70,
        'timestamp': '2025-10-20T15:30:00.000Z',
      };

      final model = ProactiveAssistanceModel.fromJson(json);

      expect(model.followUpSuggestion!.contextSnippet, equals(''));
    });

    test('should handle very long topic names', () {
      final longTopic = 'Very long topic name that exceeds normal length';
      final json = {
        'type': 'follow_up_suggestion',
        'insight_id': 'session_long',
        'topic': longTopic,
        'reason': 'Test reason',
        'related_content_id': 'content_123',
        'related_title': 'Test Meeting',
        'related_date': '2025-10-13T14:30:00.000Z',
        'urgency': 'medium',
        'context_snippet': 'Context...',
        'confidence': 0.75,
        'timestamp': '2025-10-20T15:30:00.000Z',
      };

      final model = ProactiveAssistanceModel.fromJson(json);

      expect(model.followUpSuggestion!.topic, equals(longTopic));
    });

    test('should handle old related dates', () {
      final oldDate = '2024-01-01T00:00:00.000Z';
      final json = {
        'type': 'follow_up_suggestion',
        'insight_id': 'session_old',
        'topic': 'Old topic',
        'reason': 'Historical reference',
        'related_content_id': 'content_old',
        'related_title': 'Old Meeting',
        'related_date': oldDate,
        'urgency': 'low',
        'context_snippet': 'Old discussion...',
        'confidence': 0.65,
        'timestamp': '2025-10-20T15:30:00.000Z',
      };

      final model = ProactiveAssistanceModel.fromJson(json);

      expect(
        model.followUpSuggestion!.relatedDate.year,
        equals(2024),
      );
    });
  });

  group('ProactiveAssistanceType Enum Tests', () {
    test('should include followUpSuggestion in enum', () {
      final type = ProactiveAssistanceType.followUpSuggestion;
      expect(type, isNotNull);
    });

    test('should have correct JSON value for followUpSuggestion', () {
      // The enum should serialize to 'follow_up_suggestion'
      final json = {
        'type': 'follow_up_suggestion',
        'insight_id': 'test',
        'topic': 'Test',
        'reason': 'Test',
        'related_content_id': 'test',
        'related_title': 'Test',
        'related_date': '2025-10-13T14:30:00.000Z',
        'urgency': 'medium',
        'context_snippet': 'Test',
        'confidence': 0.75,
        'timestamp': '2025-10-20T15:30:00.000Z',
      };

      final model = ProactiveAssistanceModel.fromJson(json);

      expect(model.type, equals(ProactiveAssistanceType.followUpSuggestion));
    });
  });
}
