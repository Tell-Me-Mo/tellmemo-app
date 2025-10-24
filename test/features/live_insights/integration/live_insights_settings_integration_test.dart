import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/live_insights/domain/models/live_insight_model.dart';
import 'package:pm_master_v2/features/live_insights/domain/models/live_insights_settings.dart';

/// Integration test for Live Insights Settings.
///
/// Tests the end-to-end flow of insight type filtering:
/// 1. User configures enabled insight types via settings
/// 2. Settings filter insights on the frontend
/// 3. (In production: Settings are sent to backend via WebSocket init message)
void main() {
  group('Live Insights Settings Integration', () {
    test('settings filter workflow - only enabled types pass through', () {
      // Arrange: User enables only specific insight types (cost optimization)
      const settings = LiveInsightsSettings(
        enabledInsightTypes: {
          LiveInsightType.actionItem,
          LiveInsightType.risk,
          LiveInsightType.decision,
        },
      );

      // Simulate insights coming from backend (8 different types)
      final allInsights = [
        _createInsight(LiveInsightType.actionItem, 'Schedule code review'),
        _createInsight(LiveInsightType.risk, 'Database bottleneck detected'),
        _createInsight(LiveInsightType.decision, 'Use PostgreSQL'),
        _createInsight(LiveInsightType.question, 'What about caching?'),
        _createInsight(LiveInsightType.keyPoint, 'Performance matters'),
        _createInsight(LiveInsightType.relatedDiscussion, 'Last sprint discussion'),
        _createInsight(LiveInsightType.contradiction, 'Conflicts with previous decision'),
        _createInsight(LiveInsightType.missingInfo, 'Need deployment details'),
      ];

      // Act: Filter insights through settings (simulating frontend filtering)
      final filteredInsights = allInsights.where((insight) {
        return settings.shouldShowInsight(insight);
      }).toList();

      // Assert: Only enabled types should pass through
      expect(filteredInsights.length, equals(3),
          reason: 'Only 3 types enabled: actionItem, risk, decision');

      expect(
        filteredInsights.every((i) =>
            i.type == LiveInsightType.actionItem ||
            i.type == LiveInsightType.risk ||
            i.type == LiveInsightType.decision),
        true,
        reason: 'All filtered insights should be of enabled types',
      );

      // Disabled types should be filtered out
      expect(
        filteredInsights.any((i) => i.type == LiveInsightType.question),
        false,
        reason: 'Questions should be filtered out',
      );
      expect(
        filteredInsights.any((i) => i.type == LiveInsightType.keyPoint),
        false,
        reason: 'Key points should be filtered out',
      );
    });

    test('cost optimization scenario - only Risks enabled', () {
      // Arrange: Extreme cost optimization - user only wants to see risks
      const settings = LiveInsightsSettings(
        enabledInsightTypes: {
          LiveInsightType.risk,
        },
      );

      final allInsights = [
        _createInsight(LiveInsightType.actionItem, 'Do something'),
        _createInsight(LiveInsightType.risk, 'Critical risk identified'),
        _createInsight(LiveInsightType.decision, 'Decision made'),
        _createInsight(LiveInsightType.risk, 'Another risk found'),
      ];

      // Act
      final filteredInsights = allInsights
          .where((insight) => settings.shouldShowInsight(insight))
          .toList();

      // Assert: 87.5% cost reduction (1 of 8 types enabled)
      expect(filteredInsights.length, equals(2));
      expect(filteredInsights.every((i) => i.type == LiveInsightType.risk), true);

      // Verify expected enum conversion for backend
      // Flutter enum .name returns camelCase: "risk"
      final typeName = LiveInsightType.risk.name;
      expect(typeName, equals('risk'));
    });

    test('settings serialization includes insight types', () {
      // Arrange
      const settings = LiveInsightsSettings(
        enabledInsightTypes: {
          LiveInsightType.actionItem,
          LiveInsightType.risk,
        },
      );

      // Act: Serialize to JSON (as would be stored in SharedPreferences)
      final json = settings.toJson();

      // Assert
      expect(json.containsKey('enabledInsightTypes'), true);
      expect(json['enabledInsightTypes'] is List, true);

      // Deserialize and verify
      final restored = LiveInsightsSettings.fromJson(json);
      expect(restored.enabledInsightTypes.length, equals(2));
      expect(restored.enabledInsightTypes.contains(LiveInsightType.actionItem), true);
      expect(restored.enabledInsightTypes.contains(LiveInsightType.risk), true);
    });

    test('default settings enable all insight types', () {
      // Arrange & Act
      const settings = LiveInsightsSettings();

      // Assert: All 8 types enabled by default (no cost optimization)
      expect(settings.enabledInsightTypes.length, equals(8));
      expect(settings.enabledInsightTypes, equals(LiveInsightsSettings.allInsightTypes));

      // All insights should pass through with default settings
      final testInsights = LiveInsightsSettings.allInsightTypes
          .map((type) => _createInsight(type, 'Test content'))
          .toList();

      final filtered = testInsights
          .where((insight) => settings.shouldShowInsight(insight))
          .toList();

      expect(filtered.length, equals(8),
          reason: 'All types should pass with default settings');
    });
  });
}

/// Helper to create test insights
LiveInsightModel _createInsight(LiveInsightType type, String content) {
  return LiveInsightModel(
    id: 'test-${type.name}',
    type: type,
    content: content,
    priority: LiveInsightPriority.medium,
    confidenceScore: 0.85,
    timestamp: DateTime.now(),
  );
}
