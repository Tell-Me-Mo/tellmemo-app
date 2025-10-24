import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/live_insights/domain/models/proactive_assistance_model.dart';

void main() {
  group('Confidence-Based Display Mode', () {
    test('Auto-answer: high confidence (>0.80) shows immediate', () {
      final assistance = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.autoAnswer,
        autoAnswer: AutoAnswerAssistance(
          insightId: 'test_1',
          question: 'What is the budget?',
          answer: 'Budget is 50K',
          confidence: 0.90,
          sources: [],
          reasoning: 'Found in past meeting',
          timestamp: DateTime.now(),
        ),
      );

      expect(assistance.displayMode, DisplayMode.immediate);
    });

    test('Auto-answer: medium confidence (0.65-0.80) shows collapsed', () {
      final assistance = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.autoAnswer,
        autoAnswer: AutoAnswerAssistance(
          insightId: 'test_2',
          question: 'What is the budget?',
          answer: 'Budget might be 50K',
          confidence: 0.70,
          sources: [],
          reasoning: 'Found in past meeting',
          timestamp: DateTime.now(),
        ),
      );

      expect(assistance.displayMode, DisplayMode.collapsed);
    });

    test('Auto-answer: low confidence (<0.65) is hidden', () {
      final assistance = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.autoAnswer,
        autoAnswer: AutoAnswerAssistance(
          insightId: 'test_3',
          question: 'What is the budget?',
          answer: 'Budget uncertain',
          confidence: 0.60,
          sources: [],
          reasoning: 'Weak match',
          timestamp: DateTime.now(),
        ),
      );

      expect(assistance.displayMode, DisplayMode.hidden);
    });

    test('Conflict: high confidence (>0.75) shows immediate', () {
      final assistance = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.conflictDetected,
        conflict: ConflictAssistance(
          insightId: 'test_4',
          currentStatement: 'Use REST',
          conflictingContentId: 'dec_123',
          conflictingTitle: 'Use GraphQL',
          conflictingSnippet: 'Decided to use GraphQL',
          conflictingDate: DateTime.now(),
          conflictSeverity: 'high',
          confidence: 0.85,
          reasoning: 'Direct contradiction',
          resolutionSuggestions: [],
          timestamp: DateTime.now(),
        ),
      );

      expect(assistance.displayMode, DisplayMode.immediate);
    });

    test('Conflict: medium confidence (0.65-0.75) shows collapsed', () {
      final assistance = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.conflictDetected,
        conflict: ConflictAssistance(
          insightId: 'test_5',
          currentStatement: 'Use REST',
          conflictingContentId: 'dec_123',
          conflictingTitle: 'Use GraphQL',
          conflictingSnippet: 'Decided to use GraphQL',
          conflictingDate: DateTime.now(),
          conflictSeverity: 'medium',
          confidence: 0.70,
          reasoning: 'Possible contradiction',
          resolutionSuggestions: [],
          timestamp: DateTime.now(),
        ),
      );

      expect(assistance.displayMode, DisplayMode.collapsed);
    });

    test('Conflict: low confidence (<0.65) is hidden', () {
      final assistance = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.conflictDetected,
        conflict: ConflictAssistance(
          insightId: 'test_6',
          currentStatement: 'Use REST',
          conflictingContentId: 'dec_123',
          conflictingTitle: 'Use GraphQL',
          conflictingSnippet: 'Decided to use GraphQL',
          conflictingDate: DateTime.now(),
          conflictSeverity: 'low',
          confidence: 0.60,
          reasoning: 'Weak conflict',
          resolutionSuggestions: [],
          timestamp: DateTime.now(),
        ),
      );

      expect(assistance.displayMode, DisplayMode.hidden);
    });

    test('Action item quality: incomplete (<0.7) shows immediate', () {
      final assistance = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.incompleteActionItem,
        actionItemQuality: ActionItemQualityAssistance(
          insightId: 'test_7',
          actionItem: 'Someone should fix this',
          completenessScore: 0.5,
          issues: [
            QualityIssue(
              field: 'owner',
              severity: 'critical',
              message: 'Missing owner',
            ),
          ],
          improvedVersion: 'John should fix the bug by Friday',
          timestamp: DateTime.now(),
        ),
      );

      expect(assistance.displayMode, DisplayMode.immediate);
    });

    test('Action item quality: complete (>=0.7) shows collapsed', () {
      final assistance = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.incompleteActionItem,
        actionItemQuality: ActionItemQualityAssistance(
          insightId: 'test_8',
          actionItem: 'John will fix the bug by Friday',
          completenessScore: 0.9,
          issues: [],
          improvedVersion: null,
          timestamp: DateTime.now(),
        ),
      );

      expect(assistance.displayMode, DisplayMode.collapsed);
    });

    test('Follow-up suggestion: high confidence (>0.70) shows immediate', () {
      final assistance = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.followUpSuggestion,
        followUpSuggestion: FollowUpSuggestionAssistance(
          insightId: 'test_9',
          topic: 'API Design',
          reason: 'Related to current discussion',
          relatedContentId: 'meeting_123',
          relatedTitle: 'API Review',
          relatedDate: DateTime.now(),
          urgency: 'high',
          contextSnippet: 'We discussed GraphQL APIs',
          confidence: 0.80,
          timestamp: DateTime.now(),
        ),
      );

      expect(assistance.displayMode, DisplayMode.immediate);
    });

    test('Clarification: high confidence (>0.75) shows immediate', () {
      final assistance = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.clarificationNeeded,
        clarification: ClarificationAssistance(
          insightId: 'test_10',
          statement: 'Someone should handle this soon',
          vaguenessType: 'assignment',
          suggestedQuestions: ['Who will handle this?'],
          confidence: 0.85,
          reasoning: 'Missing assignment',
          timestamp: DateTime.now(),
        ),
      );

      expect(assistance.displayMode, DisplayMode.immediate);
    });
  });
}
