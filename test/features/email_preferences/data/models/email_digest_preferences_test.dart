import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/email_preferences/data/models/email_digest_preferences.dart';

void main() {
  group('EmailDigestPreferences', () {
    group('fromJson', () {
      test('creates instance with complete JSON', () {
        final json = {
          'enabled': true,
          'frequency': 'weekly',
          'content_types': ['summaries', 'tasks_assigned', 'risks_critical'],
          'include_portfolio_rollup': true,
          'last_sent_at': '2024-01-15T10:30:00Z',
        };

        final preferences = EmailDigestPreferences.fromJson(json);

        expect(preferences.enabled, true);
        expect(preferences.frequency, 'weekly');
        expect(preferences.contentTypes, ['summaries', 'tasks_assigned', 'risks_critical']);
        expect(preferences.includePortfolioRollup, true);
        expect(preferences.lastSentAt, '2024-01-15T10:30:00Z');
      });

      test('creates instance with minimal JSON', () {
        final json = {
          'enabled': false,
          'frequency': 'never',
        };

        final preferences = EmailDigestPreferences.fromJson(json);

        expect(preferences.enabled, false);
        expect(preferences.frequency, 'never');
        expect(preferences.contentTypes, isEmpty);
        expect(preferences.includePortfolioRollup, true); // Default is true
        expect(preferences.lastSentAt, isNull);
      });

      test('handles null values with defaults', () {
        final json = <String, dynamic>{};

        final preferences = EmailDigestPreferences.fromJson(json);

        expect(preferences.enabled, false);
        expect(preferences.frequency, 'weekly');
        expect(preferences.contentTypes, isEmpty);
        expect(preferences.includePortfolioRollup, true); // Default is true
        expect(preferences.lastSentAt, isNull);
      });

      test('handles empty content types list', () {
        final json = {
          'enabled': true,
          'frequency': 'daily',
          'content_types': <String>[],
        };

        final preferences = EmailDigestPreferences.fromJson(json);

        expect(preferences.contentTypes, isEmpty);
      });
    });

    group('toJson', () {
      test('serializes with complete data', () {
        final preferences = EmailDigestPreferences(
          enabled: true,
          frequency: 'weekly',
          contentTypes: const ['summaries', 'tasks_assigned'],
          includePortfolioRollup: true,
          lastSentAt: '2024-01-15T10:30:00Z',
        );

        final json = preferences.toJson();

        expect(json['enabled'], true);
        expect(json['frequency'], 'weekly');
        expect(json['content_types'], ['summaries', 'tasks_assigned']);
        expect(json['include_portfolio_rollup'], true);
        // lastSentAt should not be included in toJson (read-only field)
        expect(json.containsKey('last_sent_at'), false);
      });

      test('serializes with minimal data', () {
        final preferences = EmailDigestPreferences(
          enabled: false,
          frequency: 'never',
          contentTypes: const [],
          includePortfolioRollup: false,
        );

        final json = preferences.toJson();

        expect(json['enabled'], false);
        expect(json['frequency'], 'never');
        expect(json['content_types'], isEmpty);
        expect(json['include_portfolio_rollup'], false);
      });

      test('excludes null lastSentAt', () {
        final preferences = EmailDigestPreferences(
          enabled: true,
          frequency: 'daily',
          contentTypes: const ['summaries'],
          includePortfolioRollup: false,
          lastSentAt: null,
        );

        final json = preferences.toJson();

        expect(json.containsKey('last_sent_at'), false);
      });
    });

    group('copyWith', () {
      test('creates copy with updated enabled', () {
        final original = EmailDigestPreferences(
          enabled: true,
          frequency: 'weekly',
          contentTypes: const ['summaries'],
          includePortfolioRollup: true,
        );

        final updated = original.copyWith(enabled: false);

        expect(updated.enabled, false);
        expect(updated.frequency, 'weekly');
        expect(updated.contentTypes, ['summaries']);
        expect(updated.includePortfolioRollup, true);
      });

      test('creates copy with updated frequency', () {
        final original = EmailDigestPreferences(
          enabled: true,
          frequency: 'weekly',
          contentTypes: const ['summaries'],
          includePortfolioRollup: true,
        );

        final updated = original.copyWith(frequency: 'daily');

        expect(updated.enabled, true);
        expect(updated.frequency, 'daily');
      });

      test('creates copy with updated content types', () {
        final original = EmailDigestPreferences(
          enabled: true,
          frequency: 'weekly',
          contentTypes: const ['summaries'],
          includePortfolioRollup: true,
        );

        final updated = original.copyWith(
          contentTypes: ['summaries', 'tasks_assigned', 'risks_critical'],
        );

        expect(updated.contentTypes, ['summaries', 'tasks_assigned', 'risks_critical']);
      });

      test('creates copy with all fields updated', () {
        final original = EmailDigestPreferences(
          enabled: true,
          frequency: 'weekly',
          contentTypes: const ['summaries'],
          includePortfolioRollup: true,
        );

        final updated = original.copyWith(
          enabled: false,
          frequency: 'monthly',
          contentTypes: ['tasks_assigned'],
          includePortfolioRollup: false,
        );

        expect(updated.enabled, false);
        expect(updated.frequency, 'monthly');
        expect(updated.contentTypes, ['tasks_assigned']);
        expect(updated.includePortfolioRollup, false);
      });
    });

    group('round-trip conversion', () {
      test('preserves data through JSON serialization', () {
        final original = EmailDigestPreferences(
          enabled: true,
          frequency: 'weekly',
          contentTypes: const ['summaries', 'tasks_assigned', 'risks_critical'],
          includePortfolioRollup: true,
          lastSentAt: '2024-01-15T10:30:00Z',
        );

        final json = original.toJson();
        // Manually add lastSentAt back for round-trip test (simulating API response)
        json['last_sent_at'] = original.lastSentAt;
        final restored = EmailDigestPreferences.fromJson(json);

        expect(restored.enabled, original.enabled);
        expect(restored.frequency, original.frequency);
        expect(restored.contentTypes, original.contentTypes);
        expect(restored.includePortfolioRollup, original.includePortfolioRollup);
        expect(restored.lastSentAt, original.lastSentAt);
      });
    });
  });

  group('DigestFrequency', () {
    test('has correct constants', () {
      expect(DigestFrequency.daily, 'daily');
      expect(DigestFrequency.weekly, 'weekly');
      expect(DigestFrequency.monthly, 'monthly');
      expect(DigestFrequency.never, 'never');
    });

    test('displayName returns correct values', () {
      expect(DigestFrequency.displayName(DigestFrequency.daily), 'Daily');
      expect(DigestFrequency.displayName(DigestFrequency.weekly), 'Weekly');
      expect(DigestFrequency.displayName(DigestFrequency.monthly), 'Monthly');
      expect(DigestFrequency.displayName(DigestFrequency.never), 'Never');
    });

    test('all list contains all frequencies', () {
      expect(DigestFrequency.all, [
        DigestFrequency.daily,
        DigestFrequency.weekly,
        DigestFrequency.monthly,
        DigestFrequency.never,
      ]);
      expect(DigestFrequency.all.length, 4);
    });
  });

  group('DigestContentType', () {
    test('has correct constants', () {
      expect(DigestContentType.summaries, 'summaries');
      expect(DigestContentType.tasksAssigned, 'tasks_assigned');
      expect(DigestContentType.risksCritical, 'risks_critical');
      expect(DigestContentType.activities, 'activities');
      expect(DigestContentType.decisions, 'decisions');
    });

    test('displayName returns correct values', () {
      expect(DigestContentType.displayName(DigestContentType.summaries), 'Meeting Summaries');
      expect(DigestContentType.displayName(DigestContentType.tasksAssigned), 'Tasks Assigned to Me');
      expect(DigestContentType.displayName(DigestContentType.risksCritical), 'Critical Risks');
      expect(DigestContentType.displayName(DigestContentType.activities), 'Project Activities');
      expect(DigestContentType.displayName(DigestContentType.decisions), 'Key Decisions');
    });

    test('all list contains all content types', () {
      expect(DigestContentType.all, [
        DigestContentType.summaries,
        DigestContentType.tasksAssigned,
        DigestContentType.risksCritical,
        DigestContentType.activities,
        DigestContentType.decisions,
      ]);
      expect(DigestContentType.all.length, 5);
    });
  });
}
