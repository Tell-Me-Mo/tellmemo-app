import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/live_insights/domain/models/proactive_assistance_model.dart';

/// Integration tests for Phase 2: Proactive Clarification feature
///
/// Tests clarification data models, parsing, and basic integration.
void main() {
  group('Clarification Assistance Integration Tests', () {
    test('ClarificationAssistance model can be created and serialized', () {
      final now = DateTime.now();
      final clarification = ClarificationAssistance(
        insightId: 'test_insight_1',
        statement: 'Someone should handle this soon',
        vaguenessType: 'assignment',
        suggestedQuestions: [
          'Who specifically will handle this?',
          'Who is the owner for this task?',
        ],
        confidence: 0.85,
        reasoning: 'Detected assignment vagueness',
        timestamp: now,
      );

      expect(clarification.insightId, 'test_insight_1');
      expect(clarification.statement, 'Someone should handle this soon');
      expect(clarification.vaguenessType, 'assignment');
      expect(clarification.suggestedQuestions.length, 2);
      expect(clarification.confidence, 0.85);

      // Test JSON serialization
      final json = clarification.toJson();
      expect(json['insight_id'], 'test_insight_1');
      expect(json['vagueness_type'], 'assignment');
      expect(json['suggested_questions'], isA<List>());
    });

    test('ClarificationAssistance can be created from JSON', () {
      final json = {
        'insight_id': 'session_0_5',
        'statement': 'We need to deploy soon',
        'vagueness_type': 'time',
        'suggested_questions': [
          'What is the specific deadline?',
          'By when should this be deployed?',
        ],
        'confidence': 0.87,
        'reasoning': 'Detected time vagueness',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final clarification = ClarificationAssistance.fromJson(json);

      expect(clarification.insightId, 'session_0_5');
      expect(clarification.vaguenessType, 'time');
      expect(clarification.suggestedQuestions.length, 2);
      expect(clarification.confidence, 0.87);
    });

    test('ProactiveAssistanceModel supports clarification type', () {
      final json = {
        'type': 'clarification_needed',
        'insight_id': 'test_1',
        'statement': 'Fix the bug',
        'vagueness_type': 'detail',
        'suggested_questions': ['Which specific bug?', 'What are the details?'],
        'confidence': 0.80,
        'reasoning': 'Missing details',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final model = ProactiveAssistanceModel.fromJson(json);

      expect(model.type, ProactiveAssistanceType.clarificationNeeded);
      expect(model.clarification, isNotNull);
      expect(model.clarification!.vaguenessType, 'detail');
      expect(model.clarification!.suggestedQuestions.length, 2);
    });

    test('All vagueness types are supported', () {
      final types = ['time', 'assignment', 'detail', 'scope'];

      for (final type in types) {
        final json = {
          'type': 'clarification_needed',
          'insight_id': 'test_$type',
          'statement': 'Test statement',
          'vagueness_type': type,
          'suggested_questions': ['Question 1?', 'Question 2?'],
          'confidence': 0.75,
          'reasoning': 'Test',
          'timestamp': DateTime.now().toIso8601String(),
        };

        final model = ProactiveAssistanceModel.fromJson(json);
        expect(model.type, ProactiveAssistanceType.clarificationNeeded);
        expect(model.clarification!.vaguenessType, type);
      }
    });

    test('Clarification with multiple suggested questions', () {
      final json = {
        'type': 'clarification_needed',
        'insight_id': 'multi_q',
        'statement': 'Maybe we should consider this',
        'vagueness_type': 'scope',
        'suggested_questions': [
          'What level of certainty do we have?',
          'Should we treat this as confirmed?',
          'Do we need to decide now?',
        ],
        'confidence': 0.78,
        'reasoning': 'Uncertain scope',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final model = ProactiveAssistanceModel.fromJson(json);

      expect(model.clarification!.suggestedQuestions.length, 3);
      expect(
        model.clarification!.suggestedQuestions,
        contains('What level of certainty do we have?'),
      );
    });

    test('High confidence clarification', () {
      final json = {
        'type': 'clarification_needed',
        'insight_id': 'high_conf',
        'statement': 'Someone needs to review',
        'vagueness_type': 'assignment',
        'suggested_questions': ['Who will review this?'],
        'confidence': 0.95,
        'reasoning': 'Clear assignment vagueness',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final model = ProactiveAssistanceModel.fromJson(json);

      expect(model.clarification!.confidence, greaterThanOrEqualTo(0.9));
    });

    test('Low confidence clarification', () {
      final json = {
        'type': 'clarification_needed',
        'insight_id': 'low_conf',
        'statement': 'We might need to look at this',
        'vagueness_type': 'scope',
        'suggested_questions': ['Is this a firm requirement?'],
        'confidence': 0.65,
        'reasoning': 'Subtle scope vagueness',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final model = ProactiveAssistanceModel.fromJson(json);

      expect(model.clarification!.confidence, lessThan(0.7));
      expect(model.clarification!.confidence, greaterThanOrEqualTo(0.6));
    });
  });

  group('Clarification vs Auto-Answer Distinction', () {
    test('Clarification and auto-answer are different types', () {
      final clarificationJson = {
        'type': 'clarification_needed',
        'insight_id': 'clar_1',
        'statement': 'Someone should fix this',
        'vagueness_type': 'assignment',
        'suggested_questions': ['Who will fix this?'],
        'confidence': 0.85,
        'reasoning': 'Assignment vagueness',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final autoAnswerJson = {
        'type': 'auto_answer',
        'insight_id': 'aa_1',
        'question': 'What was the Q4 budget?',
        'answer': '\$50K for marketing',
        'confidence': 0.89,
        'sources': [],
        'reasoning': 'Found in past meeting',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final clarModel = ProactiveAssistanceModel.fromJson(clarificationJson);
      final aaModel = ProactiveAssistanceModel.fromJson(autoAnswerJson);

      expect(clarModel.type, ProactiveAssistanceType.clarificationNeeded);
      expect(aaModel.type, ProactiveAssistanceType.autoAnswer);
      expect(clarModel.clarification, isNotNull);
      expect(clarModel.autoAnswer, isNull);
      expect(aaModel.autoAnswer, isNotNull);
      expect(aaModel.clarification, isNull);
    });
  });

  group('Edge Cases', () {
    test('Clarification with empty suggested questions list', () {
      final json = {
        'type': 'clarification_needed',
        'insight_id': 'empty_q',
        'statement': 'Test statement',
        'vagueness_type': 'detail',
        'suggested_questions': <String>[],
        'confidence': 0.70,
        'reasoning': 'Test',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final model = ProactiveAssistanceModel.fromJson(json);

      expect(model.clarification!.suggestedQuestions, isEmpty);
    });

    test('Clarification with very long statement', () {
      final longStatement = 'Someone ' * 50 + 'should handle this task';
      final json = {
        'type': 'clarification_needed',
        'insight_id': 'long',
        'statement': longStatement,
        'vagueness_type': 'assignment',
        'suggested_questions': ['Who is responsible?'],
        'confidence': 0.82,
        'reasoning': 'Assignment vagueness',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final model = ProactiveAssistanceModel.fromJson(json);

      expect(model.clarification!.statement.length, greaterThan(100));
      expect(model.clarification!.statement, contains('should handle this task'));
    });

    test('Clarification with special characters in questions', () {
      final json = {
        'type': 'clarification_needed',
        'insight_id': 'special',
        'statement': 'Deploy the v2.0 feature',
        'vagueness_type': 'time',
        'suggested_questions': [
          'What\'s the deployment date?',
          'By when (DD/MM/YYYY)?',
        ],
        'confidence': 0.75,
        'reasoning': 'Time vagueness',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final model = ProactiveAssistanceModel.fromJson(json);

      expect(model.clarification!.suggestedQuestions[0], contains('\''));
      expect(model.clarification!.suggestedQuestions[1], contains('('));
    });
  });

  group('Performance Tests', () {
    test('Can parse 100 clarification messages quickly', () {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        final json = {
          'type': 'clarification_needed',
          'insight_id': 'perf_$i',
          'statement': 'Test statement $i',
          'vagueness_type': 'time',
          'suggested_questions': ['Question 1?', 'Question 2?'],
          'confidence': 0.75,
          'reasoning': 'Test',
          'timestamp': DateTime.now().toIso8601String(),
        };

        ProactiveAssistanceModel.fromJson(json);
      }

      stopwatch.stop();

      // Should be able to parse 100 messages in less than 500ms
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason:
            'Parsing 100 clarifications should be fast (<500ms), got ${stopwatch.elapsedMilliseconds}ms',
      );
    });
  });
}
