import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/live_insights/domain/models/live_insights_settings.dart';
import 'package:pm_master_v2/features/live_insights/domain/models/live_insight_model.dart';
import 'package:pm_master_v2/features/live_insights/domain/models/proactive_assistance_model.dart';

void main() {
  group('LiveInsightsSettings', () {
    group('Default Settings', () {
      test('should have correct default values', () {
        const settings = LiveInsightsSettings();

        expect(settings.quietMode, false);
        expect(settings.showCollapsedItems, true);
        expect(settings.enableFeedback, true);
        expect(settings.autoExpandHighConfidence, true);
        expect(
          settings.enabledPhases,
          {
            ProactiveAssistanceType.autoAnswer,
            ProactiveAssistanceType.conflictDetected,
            ProactiveAssistanceType.incompleteActionItem,
          },
        );
      });

      test('defaultEnabledPhases should match constructor defaults', () {
        const settings = LiveInsightsSettings();

        expect(
          settings.enabledPhases,
          LiveInsightsSettings.defaultEnabledPhases,
        );
      });

      test('allPhases should contain all assistance types', () {
        expect(LiveInsightsSettings.allPhases.length, 5);
        expect(
          LiveInsightsSettings.allPhases,
          containsAll([
            ProactiveAssistanceType.autoAnswer,
            ProactiveAssistanceType.clarificationNeeded,
            ProactiveAssistanceType.conflictDetected,
            ProactiveAssistanceType.incompleteActionItem,
            ProactiveAssistanceType.followUpSuggestion,
          ]),
        );
      });
    });

    group('Priority Classification', () {
      test('conflictDetected should be critical priority', () {
        expect(
          LiveInsightsSettings.getPriorityForType(
            ProactiveAssistanceType.conflictDetected,
          ),
          AssistancePriority.critical,
        );
      });

      test('incompleteActionItem should be critical priority', () {
        expect(
          LiveInsightsSettings.getPriorityForType(
            ProactiveAssistanceType.incompleteActionItem,
          ),
          AssistancePriority.critical,
        );
      });

      test('autoAnswer should be important priority', () {
        expect(
          LiveInsightsSettings.getPriorityForType(
            ProactiveAssistanceType.autoAnswer,
          ),
          AssistancePriority.important,
        );
      });

      test('clarificationNeeded should be important priority', () {
        expect(
          LiveInsightsSettings.getPriorityForType(
            ProactiveAssistanceType.clarificationNeeded,
          ),
          AssistancePriority.important,
        );
      });

      test('followUpSuggestion should be informational priority', () {
        expect(
          LiveInsightsSettings.getPriorityForType(
            ProactiveAssistanceType.followUpSuggestion,
          ),
          AssistancePriority.informational,
        );
      });
    });

    group('Quiet Mode', () {
      test('quiet mode disabled shows all enabled phases', () {
        const settings = LiveInsightsSettings(
          quietMode: false,
          enabledPhases: LiveInsightsSettings.allPhases,
        );

        // Test critical priority (should show)
        final conflict = _createMockAssistance(
          ProactiveAssistanceType.conflictDetected,
          DisplayMode.immediate,
        );
        expect(settings.shouldShowAssistance(conflict), true);

        // Test important priority (should show)
        final autoAnswer = _createMockAssistance(
          ProactiveAssistanceType.autoAnswer,
          DisplayMode.immediate,
        );
        expect(settings.shouldShowAssistance(autoAnswer), true);

        // Test informational priority (should show)
        final followUp = _createMockAssistance(
          ProactiveAssistanceType.followUpSuggestion,
          DisplayMode.immediate,
        );
        expect(settings.shouldShowAssistance(followUp), true);
      });

      test('quiet mode enabled shows only critical priority', () {
        const settings = LiveInsightsSettings(
          quietMode: true,
          enabledPhases: LiveInsightsSettings.allPhases,
        );

        // Critical priority - should show
        final conflict = _createMockAssistance(
          ProactiveAssistanceType.conflictDetected,
          DisplayMode.immediate,
        );
        expect(settings.shouldShowAssistance(conflict), true);

        final actionItem = _createMockAssistance(
          ProactiveAssistanceType.incompleteActionItem,
          DisplayMode.immediate,
        );
        expect(settings.shouldShowAssistance(actionItem), true);

        // Important priority - should NOT show
        final autoAnswer = _createMockAssistance(
          ProactiveAssistanceType.autoAnswer,
          DisplayMode.immediate,
        );
        expect(settings.shouldShowAssistance(autoAnswer), false);

        final clarification = _createMockAssistance(
          ProactiveAssistanceType.clarificationNeeded,
          DisplayMode.immediate,
        );
        expect(settings.shouldShowAssistance(clarification), false);

        // Informational priority - should NOT show
        final followUp = _createMockAssistance(
          ProactiveAssistanceType.followUpSuggestion,
          DisplayMode.immediate,
        );
        expect(settings.shouldShowAssistance(followUp), false);
      });

      test('quiet mode respects enabled phases filter', () {
        const settings = LiveInsightsSettings(
          quietMode: true,
          enabledPhases: {
            ProactiveAssistanceType.conflictDetected,
            // incompleteActionItem NOT enabled
          },
        );

        // Enabled critical phase - should show
        final conflict = _createMockAssistance(
          ProactiveAssistanceType.conflictDetected,
          DisplayMode.immediate,
        );
        expect(settings.shouldShowAssistance(conflict), true);

        // Disabled critical phase - should NOT show
        final actionItem = _createMockAssistance(
          ProactiveAssistanceType.incompleteActionItem,
          DisplayMode.immediate,
        );
        expect(settings.shouldShowAssistance(actionItem), false);
      });
    });

    group('Enabled Phases Toggle', () {
      test('should show only enabled phases', () {
        const settings = LiveInsightsSettings(
          enabledPhases: {
            ProactiveAssistanceType.autoAnswer,
            ProactiveAssistanceType.conflictDetected,
          },
        );

        // Enabled phase - should show
        final autoAnswer = _createMockAssistance(
          ProactiveAssistanceType.autoAnswer,
          DisplayMode.immediate,
        );
        expect(settings.shouldShowAssistance(autoAnswer), true);

        final conflict = _createMockAssistance(
          ProactiveAssistanceType.conflictDetected,
          DisplayMode.immediate,
        );
        expect(settings.shouldShowAssistance(conflict), true);

        // Disabled phase - should NOT show
        final clarification = _createMockAssistance(
          ProactiveAssistanceType.clarificationNeeded,
          DisplayMode.immediate,
        );
        expect(settings.shouldShowAssistance(clarification), false);

        final followUp = _createMockAssistance(
          ProactiveAssistanceType.followUpSuggestion,
          DisplayMode.immediate,
        );
        expect(settings.shouldShowAssistance(followUp), false);
      });

      test('should hide all when no phases enabled', () {
        const settings = LiveInsightsSettings(
          enabledPhases: {},
        );

        for (final type in LiveInsightsSettings.allPhases) {
          final assistance = _createMockAssistance(type, DisplayMode.immediate);
          expect(
            settings.shouldShowAssistance(assistance),
            false,
            reason: 'Should hide $type when no phases enabled',
          );
        }
      });

      test('should show all when all phases enabled', () {
        const settings = LiveInsightsSettings(
          enabledPhases: LiveInsightsSettings.allPhases,
        );

        for (final type in LiveInsightsSettings.allPhases) {
          final assistance = _createMockAssistance(type, DisplayMode.immediate);
          expect(
            settings.shouldShowAssistance(assistance),
            true,
            reason: 'Should show $type when all phases enabled',
          );
        }
      });
    });

    group('Display Mode Filtering', () {
      test('should never show hidden items', () {
        const settings = LiveInsightsSettings(
          enabledPhases: LiveInsightsSettings.allPhases,
        );

        for (final type in LiveInsightsSettings.allPhases) {
          // Skip incompleteActionItem as it can never be hidden
          // (it's always either immediate or collapsed based on completeness score)
          if (type == ProactiveAssistanceType.incompleteActionItem) {
            continue;
          }

          final assistance = _createMockAssistance(type, DisplayMode.hidden);
          expect(
            settings.shouldShowAssistance(assistance),
            false,
            reason: 'Should never show hidden $type',
          );
        }
      });

      test('should show collapsed items when showCollapsedItems is true', () {
        const settings = LiveInsightsSettings(
          enabledPhases: LiveInsightsSettings.allPhases,
          showCollapsedItems: true,
        );

        for (final type in LiveInsightsSettings.allPhases) {
          final assistance = _createMockAssistance(type, DisplayMode.collapsed);
          expect(
            settings.shouldShowAssistance(assistance),
            true,
            reason: 'Should show collapsed $type when showCollapsedItems=true',
          );
        }
      });

      test('should hide collapsed items when showCollapsedItems is false', () {
        const settings = LiveInsightsSettings(
          enabledPhases: LiveInsightsSettings.allPhases,
          showCollapsedItems: false,
        );

        for (final type in LiveInsightsSettings.allPhases) {
          final assistance = _createMockAssistance(type, DisplayMode.collapsed);
          expect(
            settings.shouldShowAssistance(assistance),
            false,
            reason: 'Should hide collapsed $type when showCollapsedItems=false',
          );
        }
      });

      test('should always show immediate items regardless of showCollapsedItems', () {
        const settingsWithCollapsed = LiveInsightsSettings(
          enabledPhases: LiveInsightsSettings.allPhases,
          showCollapsedItems: true,
        );

        const settingsWithoutCollapsed = LiveInsightsSettings(
          enabledPhases: LiveInsightsSettings.allPhases,
          showCollapsedItems: false,
        );

        for (final type in LiveInsightsSettings.allPhases) {
          final assistance = _createMockAssistance(type, DisplayMode.immediate);

          expect(
            settingsWithCollapsed.shouldShowAssistance(assistance),
            true,
            reason: 'Should show immediate $type with showCollapsedItems=true',
          );

          expect(
            settingsWithoutCollapsed.shouldShowAssistance(assistance),
            true,
            reason: 'Should show immediate $type with showCollapsedItems=false',
          );
        }
      });
    });

    group('Combined Filters', () {
      test('quiet mode + disabled phase should not show', () {
        const settings = LiveInsightsSettings(
          quietMode: true,
          enabledPhases: {
            ProactiveAssistanceType.autoAnswer, // Not critical
          },
        );

        final autoAnswer = _createMockAssistance(
          ProactiveAssistanceType.autoAnswer,
          DisplayMode.immediate,
        );

        // autoAnswer is enabled but not critical, so quiet mode hides it
        expect(settings.shouldShowAssistance(autoAnswer), false);
      });

      test('enabled phase + hidden display mode should not show', () {
        const settings = LiveInsightsSettings(
          enabledPhases: {ProactiveAssistanceType.conflictDetected},
        );

        final conflict = _createMockAssistance(
          ProactiveAssistanceType.conflictDetected,
          DisplayMode.hidden,
        );

        expect(settings.shouldShowAssistance(conflict), false);
      });

      test('all filters pass should show', () {
        const settings = LiveInsightsSettings(
          quietMode: false,
          enabledPhases: {ProactiveAssistanceType.conflictDetected},
          showCollapsedItems: true,
        );

        final conflict = _createMockAssistance(
          ProactiveAssistanceType.conflictDetected,
          DisplayMode.collapsed,
        );

        expect(settings.shouldShowAssistance(conflict), true);
      });
    });

    group('Label and Description Helpers', () {
      test('getLabelForType returns correct labels', () {
        expect(
          LiveInsightsSettings.getLabelForType(
            ProactiveAssistanceType.autoAnswer,
          ),
          'Auto-Answer Questions',
        );
        expect(
          LiveInsightsSettings.getLabelForType(
            ProactiveAssistanceType.clarificationNeeded,
          ),
          'Clarification Suggestions',
        );
        expect(
          LiveInsightsSettings.getLabelForType(
            ProactiveAssistanceType.conflictDetected,
          ),
          'Conflict Detection',
        );
        expect(
          LiveInsightsSettings.getLabelForType(
            ProactiveAssistanceType.incompleteActionItem,
          ),
          'Action Item Quality',
        );
        expect(
          LiveInsightsSettings.getLabelForType(
            ProactiveAssistanceType.followUpSuggestion,
          ),
          'Follow-up Suggestions',
        );
      });

      test('getDescriptionForType returns non-empty descriptions', () {
        for (final type in LiveInsightsSettings.allPhases) {
          final description =
              LiveInsightsSettings.getDescriptionForType(type);
          expect(description.isNotEmpty, true);
          expect(description.length, greaterThan(20));
        }
      });

      test('getIconForType returns emoji icons', () {
        for (final type in LiveInsightsSettings.allPhases) {
          final icon = LiveInsightsSettings.getIconForType(type);
          expect(icon.isNotEmpty, true);
        }
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize correctly', () {
        const original = LiveInsightsSettings(
          enabledPhases: {
            ProactiveAssistanceType.autoAnswer,
            ProactiveAssistanceType.conflictDetected,
          },
          quietMode: true,
          showCollapsedItems: false,
          enableFeedback: false,
          autoExpandHighConfidence: false,
        );

        final json = original.toJson();
        final deserialized = LiveInsightsSettings.fromJson(json);

        expect(deserialized.enabledPhases, original.enabledPhases);
        expect(deserialized.quietMode, original.quietMode);
        expect(deserialized.showCollapsedItems, original.showCollapsedItems);
        expect(deserialized.enableFeedback, original.enableFeedback);
        expect(
          deserialized.autoExpandHighConfidence,
          original.autoExpandHighConfidence,
        );
      });

      test('should handle default values in JSON', () {
        final json = <String, dynamic>{};
        final settings = LiveInsightsSettings.fromJson(json);

        expect(settings.quietMode, false);
        expect(settings.showCollapsedItems, true);
        expect(settings.enableFeedback, true);
        expect(settings.autoExpandHighConfidence, true);
      });
    });

    group('Enabled Insight Types', () {
      test('should have all insight types enabled by default', () {
        const settings = LiveInsightsSettings();

        expect(settings.enabledInsightTypes.length, 8);
        expect(settings.enabledInsightTypes, LiveInsightsSettings.allInsightTypes);
        expect(
          settings.enabledInsightTypes,
          containsAll([
            LiveInsightType.actionItem,
            LiveInsightType.decision,
            LiveInsightType.question,
            LiveInsightType.risk,
            LiveInsightType.keyPoint,
            LiveInsightType.relatedDiscussion,
            LiveInsightType.contradiction,
            LiveInsightType.missingInfo,
          ]),
        );
      });

      test('should filter insights based on enabled types', () {
        const settings = LiveInsightsSettings(
          enabledInsightTypes: {
            LiveInsightType.actionItem,
            LiveInsightType.risk,
          },
        );

        // Enabled types - should show
        final actionItem = _createMockInsight(LiveInsightType.actionItem);
        expect(settings.shouldShowInsight(actionItem), true);

        final risk = _createMockInsight(LiveInsightType.risk);
        expect(settings.shouldShowInsight(risk), true);

        // Disabled types - should NOT show
        final decision = _createMockInsight(LiveInsightType.decision);
        expect(settings.shouldShowInsight(decision), false);

        final question = _createMockInsight(LiveInsightType.question);
        expect(settings.shouldShowInsight(question), false);

        final keyPoint = _createMockInsight(LiveInsightType.keyPoint);
        expect(settings.shouldShowInsight(keyPoint), false);
      });

      test('should hide all insights when no types enabled', () {
        const settings = LiveInsightsSettings(
          enabledInsightTypes: {},
        );

        for (final type in LiveInsightsSettings.allInsightTypes) {
          final insight = _createMockInsight(type);
          expect(
            settings.shouldShowInsight(insight),
            false,
            reason: 'Should hide $type when no insight types enabled',
          );
        }
      });

      test('should show all insights when all types enabled', () {
        const settings = LiveInsightsSettings(
          enabledInsightTypes: LiveInsightsSettings.allInsightTypes,
        );

        for (final type in LiveInsightsSettings.allInsightTypes) {
          final insight = _createMockInsight(type);
          expect(
            settings.shouldShowInsight(insight),
            true,
            reason: 'Should show $type when all insight types enabled',
          );
        }
      });

      test('getLabelForInsightType returns correct labels', () {
        expect(
          LiveInsightsSettings.getLabelForInsightType(LiveInsightType.actionItem),
          'Action Items',
        );
        expect(
          LiveInsightsSettings.getLabelForInsightType(LiveInsightType.decision),
          'Decisions',
        );
        expect(
          LiveInsightsSettings.getLabelForInsightType(LiveInsightType.question),
          'Questions',
        );
        expect(
          LiveInsightsSettings.getLabelForInsightType(LiveInsightType.risk),
          'Risks',
        );
        expect(
          LiveInsightsSettings.getLabelForInsightType(LiveInsightType.keyPoint),
          'Key Points',
        );
        expect(
          LiveInsightsSettings.getLabelForInsightType(LiveInsightType.relatedDiscussion),
          'Related Discussions',
        );
        expect(
          LiveInsightsSettings.getLabelForInsightType(LiveInsightType.contradiction),
          'Contradictions',
        );
        expect(
          LiveInsightsSettings.getLabelForInsightType(LiveInsightType.missingInfo),
          'Missing Info',
        );
      });

      test('getDescriptionForInsightType returns non-empty descriptions', () {
        for (final type in LiveInsightsSettings.allInsightTypes) {
          final description = LiveInsightsSettings.getDescriptionForInsightType(type);
          expect(description.isNotEmpty, true);
          expect(description.length, greaterThan(10));
        }
      });

      test('getIconForInsightType returns emoji icons', () {
        for (final type in LiveInsightsSettings.allInsightTypes) {
          final icon = LiveInsightsSettings.getIconForInsightType(type);
          expect(icon.isNotEmpty, true);
        }
      });

      test('JSON serialization includes enabledInsightTypes', () {
        const original = LiveInsightsSettings(
          enabledInsightTypes: {
            LiveInsightType.actionItem,
            LiveInsightType.risk,
            LiveInsightType.decision,
          },
        );

        final json = original.toJson();
        final deserialized = LiveInsightsSettings.fromJson(json);

        expect(deserialized.enabledInsightTypes.length, 3);
        expect(
          deserialized.enabledInsightTypes,
          containsAll([
            LiveInsightType.actionItem,
            LiveInsightType.risk,
            LiveInsightType.decision,
          ]),
        );
      });
    });
  });
}

/// Helper function to create mock LiveInsightModel for testing
LiveInsightModel _createMockInsight(LiveInsightType type) {
  return LiveInsightModel(
    id: 'test-id-${type.name}',
    type: type,
    content: 'Test content for $type',
    priority: LiveInsightPriority.medium,
    confidenceScore: 0.85,
    timestamp: DateTime.now(),
    sourceChunkIndex: 0,
  );
}

/// Helper function to create mock ProactiveAssistanceModel for testing
ProactiveAssistanceModel _createMockAssistance(
  ProactiveAssistanceType type,
  DisplayMode displayMode,
) {
  final now = DateTime.now();

  // Create assistance with specific display mode by setting appropriate confidence
  // Note: Thresholds vary by type, so we need to use values that work for each type
  final confidence = switch (displayMode) {
    DisplayMode.immediate => 0.95, // High confidence (above all thresholds)
    DisplayMode.collapsed => switch (type) {
        // For autoAnswer: need > 0.75 but <= 0.85
        ProactiveAssistanceType.autoAnswer => 0.80,
        // For conflicts and others: need > 0.70 but <= 0.80
        ProactiveAssistanceType.conflictDetected => 0.75,
        ProactiveAssistanceType.clarificationNeeded => 0.75,
        // For followUp: need > 0.65 but <= 0.75
        ProactiveAssistanceType.followUpSuggestion => 0.70,
        // Action items use completeness score, not confidence
        ProactiveAssistanceType.incompleteActionItem => 0.0,
      },
    DisplayMode.hidden => 0.50, // Low confidence (below all thresholds)
  };

  return switch (type) {
    ProactiveAssistanceType.autoAnswer => ProactiveAssistanceModel(
        type: type,
        autoAnswer: AutoAnswerAssistance(
          insightId: 'test-id',
          question: 'Test question?',
          answer: 'Test answer',
          confidence: confidence,
          sources: [],
          reasoning: 'Test reasoning',
          timestamp: now,
        ),
      ),
    ProactiveAssistanceType.clarificationNeeded => ProactiveAssistanceModel(
        type: type,
        clarification: ClarificationAssistance(
          insightId: 'test-id',
          statement: 'Test statement',
          vaguenessType: 'time',
          suggestedQuestions: ['Test question?'],
          confidence: confidence,
          reasoning: 'Test reasoning',
          timestamp: now,
        ),
      ),
    ProactiveAssistanceType.conflictDetected => ProactiveAssistanceModel(
        type: type,
        conflict: ConflictAssistance(
          insightId: 'test-id',
          currentStatement: 'Current statement',
          conflictingContentId: 'content-id',
          conflictingTitle: 'Conflicting title',
          conflictingSnippet: 'Conflicting snippet',
          conflictingDate: now,
          conflictSeverity: 'high',
          confidence: confidence,
          reasoning: 'Test reasoning',
          resolutionSuggestions: ['Suggestion'],
          timestamp: now,
        ),
      ),
    ProactiveAssistanceType.incompleteActionItem => ProactiveAssistanceModel(
        type: type,
        actionItemQuality: ActionItemQualityAssistance(
          insightId: 'test-id',
          actionItem: 'Test action item',
          completenessScore: displayMode == DisplayMode.immediate ? 0.5 : 0.8,
          issues: [],
          timestamp: now,
        ),
      ),
    ProactiveAssistanceType.followUpSuggestion => ProactiveAssistanceModel(
        type: type,
        followUpSuggestion: FollowUpSuggestionAssistance(
          insightId: 'test-id',
          topic: 'Test topic',
          reason: 'Test reason',
          relatedContentId: 'content-id',
          relatedTitle: 'Related title',
          relatedDate: now,
          urgency: 'medium',
          contextSnippet: 'Context snippet',
          confidence: confidence,
          timestamp: now,
        ),
      ),
  };
}
