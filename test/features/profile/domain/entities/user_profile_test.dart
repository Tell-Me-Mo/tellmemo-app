import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/profile/domain/entities/user_profile.dart';

void main() {
  group('UserProfile', () {
    final now = DateTime(2024, 1, 15, 10, 30);
    final completeJson = {
      'id': 'user-123',
      'email': 'john.doe@example.com',
      'name': 'John Doe',
      'avatar_url': 'https://example.com/avatar.jpg',
      'bio': 'Software engineer at Example Corp',
      'created_at': '2024-01-15T10:30:00.000',
      'updated_at': '2024-01-15T11:30:00.000',
      'preferences': {
        'theme': 'dark',
        'timezone': 'America/New_York',
      },
      'user_metadata': {
        'department': 'Engineering',
        'title': 'Senior Engineer',
      },
    };

    group('fromJson', () {
      test('creates UserProfile with all fields', () {
        final profile = UserProfile.fromJson(completeJson);

        expect(profile.id, 'user-123');
        expect(profile.email, 'john.doe@example.com');
        expect(profile.name, 'John Doe');
        expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
        expect(profile.bio, 'Software engineer at Example Corp');
        expect(profile.createdAt, DateTime(2024, 1, 15, 10, 30));
        expect(profile.updatedAt, DateTime(2024, 1, 15, 11, 30));
        expect(profile.preferences, {
          'theme': 'dark',
          'timezone': 'America/New_York',
        });
        expect(profile.userMetadata, {
          'department': 'Engineering',
          'title': 'Senior Engineer',
        });
      });

      test('creates UserProfile with minimal JSON (only required fields)', () {
        final minimalJson = {
          'id': 'user-456',
          'email': 'jane@example.com',
          'created_at': '2024-01-15T10:30:00.000',
          'updated_at': '2024-01-15T10:30:00.000',
        };

        final profile = UserProfile.fromJson(minimalJson);

        expect(profile.id, 'user-456');
        expect(profile.email, 'jane@example.com');
        expect(profile.name, null);
        expect(profile.avatarUrl, null);
        expect(profile.bio, null);
        expect(profile.createdAt, DateTime(2024, 1, 15, 10, 30));
        expect(profile.updatedAt, DateTime(2024, 1, 15, 10, 30));
        expect(profile.preferences, null);
        expect(profile.userMetadata, null);
      });

      test('handles empty string values', () {
        final emptyStringsJson = {
          'id': 'user-789',
          'email': 'test@example.com',
          'name': '',
          'avatar_url': '',
          'bio': '',
          'created_at': '2024-01-15T10:30:00.000',
          'updated_at': '2024-01-15T10:30:00.000',
        };

        final profile = UserProfile.fromJson(emptyStringsJson);

        expect(profile.name, '');
        expect(profile.avatarUrl, '');
        expect(profile.bio, '');
      });
    });

    group('toJson', () {
      test('serializes UserProfile with all fields', () {
        final profile = UserProfile(
          id: 'user-123',
          email: 'john.doe@example.com',
          name: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          bio: 'Software engineer',
          createdAt: DateTime(2024, 1, 15, 10, 30),
          updatedAt: DateTime(2024, 1, 15, 11, 30),
          preferences: {'theme': 'dark'},
          userMetadata: {'department': 'Engineering'},
        );

        final json = profile.toJson();

        expect(json['id'], 'user-123');
        expect(json['email'], 'john.doe@example.com');
        expect(json['name'], 'John Doe');
        expect(json['avatar_url'], 'https://example.com/avatar.jpg');
        expect(json['bio'], 'Software engineer');
        expect(json['created_at'], '2024-01-15T10:30:00.000');
        expect(json['updated_at'], '2024-01-15T11:30:00.000');
        expect(json['preferences'], {'theme': 'dark'});
        expect(json['user_metadata'], {'department': 'Engineering'});
      });

      test('includes null fields in JSON', () {
        final profile = UserProfile(
          id: 'user-456',
          email: 'jane@example.com',
          createdAt: DateTime(2024, 1, 15, 10, 30),
          updatedAt: DateTime(2024, 1, 15, 10, 30),
        );

        final json = profile.toJson();

        expect(json['name'], null);
        expect(json['avatar_url'], null);
        expect(json['bio'], null);
        expect(json['preferences'], null);
        expect(json['user_metadata'], null);
      });
    });

    group('copyWith', () {
      final original = UserProfile(
        id: 'user-123',
        email: 'john.doe@example.com',
        name: 'John Doe',
        avatarUrl: 'https://example.com/avatar.jpg',
        bio: 'Software engineer',
        createdAt: DateTime(2024, 1, 15, 10, 30),
        updatedAt: DateTime(2024, 1, 15, 11, 30),
        preferences: {'theme': 'light'},
        userMetadata: {'department': 'Engineering'},
      );

      test('creates copy with updated id', () {
        final copy = original.copyWith(id: 'user-999');
        expect(copy.id, 'user-999');
        expect(copy.email, original.email);
      });

      test('creates copy with updated email', () {
        final copy = original.copyWith(email: 'new@example.com');
        expect(copy.email, 'new@example.com');
        expect(copy.id, original.id);
      });

      test('creates copy with updated name', () {
        final copy = original.copyWith(name: 'Jane Smith');
        expect(copy.name, 'Jane Smith');
        expect(copy.email, original.email);
      });

      test('creates copy with updated avatarUrl', () {
        final copy = original.copyWith(avatarUrl: 'https://example.com/new.jpg');
        expect(copy.avatarUrl, 'https://example.com/new.jpg');
        expect(copy.name, original.name);
      });

      test('creates copy with updated bio', () {
        final copy = original.copyWith(bio: 'Senior Software Engineer');
        expect(copy.bio, 'Senior Software Engineer');
        expect(copy.name, original.name);
      });

      test('creates copy with updated preferences', () {
        final copy = original.copyWith(preferences: {'theme': 'dark'});
        expect(copy.preferences, {'theme': 'dark'});
        expect(copy.name, original.name);
      });

      test('creates copy with updated userMetadata', () {
        final copy = original.copyWith(userMetadata: {'role': 'Admin'});
        expect(copy.userMetadata, {'role': 'Admin'});
        expect(copy.name, original.name);
      });

      test('creates copy with no changes when no parameters provided', () {
        final copy = original.copyWith();
        expect(copy.id, original.id);
        expect(copy.email, original.email);
        expect(copy.name, original.name);
        expect(copy.avatarUrl, original.avatarUrl);
        expect(copy.bio, original.bio);
      });
    });

    group('round-trip conversion', () {
      test('preserves all data through JSON serialization', () {
        final original = UserProfile(
          id: 'user-123',
          email: 'test@example.com',
          name: 'Test User',
          avatarUrl: 'https://example.com/avatar.jpg',
          bio: 'Test bio',
          createdAt: DateTime(2024, 1, 15, 10, 30),
          updatedAt: DateTime(2024, 1, 15, 11, 30),
          preferences: {'theme': 'dark', 'timezone': 'UTC'},
          userMetadata: {'department': 'Engineering', 'level': 'Senior'},
        );

        final json = original.toJson();
        final decoded = UserProfile.fromJson(json);

        expect(decoded.id, original.id);
        expect(decoded.email, original.email);
        expect(decoded.name, original.name);
        expect(decoded.avatarUrl, original.avatarUrl);
        expect(decoded.bio, original.bio);
        expect(decoded.createdAt, original.createdAt);
        expect(decoded.updatedAt, original.updatedAt);
        expect(decoded.preferences, original.preferences);
        expect(decoded.userMetadata, original.userMetadata);
      });
    });

    group('edge cases', () {
      test('handles very long strings', () {
        final longString = 'A' * 10000;
        final profile = UserProfile(
          id: 'user-123',
          email: 'test@example.com',
          name: longString,
          bio: longString,
          createdAt: DateTime(2024, 1, 15, 10, 30),
          updatedAt: DateTime(2024, 1, 15, 10, 30),
        );

        expect(profile.name, longString);
        expect(profile.bio, longString);
      });

      test('handles special characters in strings', () {
        final specialChars = 'Test \n\t\r "quotes" \'single\' <html> & special chars: ñ é ü';
        final profile = UserProfile(
          id: 'user-123',
          email: 'test@example.com',
          name: specialChars,
          bio: specialChars,
          createdAt: DateTime(2024, 1, 15, 10, 30),
          updatedAt: DateTime(2024, 1, 15, 10, 30),
        );

        final json = profile.toJson();
        final decoded = UserProfile.fromJson(json);

        expect(decoded.name, specialChars);
        expect(decoded.bio, specialChars);
      });

      test('handles special characters in email', () {
        final email = 'test+tag@sub.example.co.uk';
        final profile = UserProfile(
          id: 'user-123',
          email: email,
          createdAt: DateTime(2024, 1, 15, 10, 30),
          updatedAt: DateTime(2024, 1, 15, 10, 30),
        );

        expect(profile.email, email);
      });

      test('handles URLs with query parameters', () {
        final avatarUrl = 'https://example.com/avatar.jpg?size=large&format=png';
        final profile = UserProfile(
          id: 'user-123',
          email: 'test@example.com',
          avatarUrl: avatarUrl,
          createdAt: DateTime(2024, 1, 15, 10, 30),
          updatedAt: DateTime(2024, 1, 15, 10, 30),
        );

        expect(profile.avatarUrl, avatarUrl);
      });
    });
  });

  group('UserPreferences', () {
    group('fromJson', () {
      test('creates UserPreferences with all fields', () {
        final json = {
          'timezone': 'America/New_York',
          'locale': 'en_US',
          'email_notifications': true,
          'push_notifications': false,
          'weekly_digest': true,
          'theme': 'dark',
          'default_organization_id': 'org-123',
        };

        final prefs = UserPreferences.fromJson(json);

        expect(prefs.timezone, 'America/New_York');
        expect(prefs.locale, 'en_US');
        expect(prefs.emailNotifications, true);
        expect(prefs.pushNotifications, false);
        expect(prefs.weeklyDigest, true);
        expect(prefs.theme, 'dark');
        expect(prefs.defaultOrganizationId, 'org-123');
      });

      test('creates UserPreferences with defaults for missing fields', () {
        final json = <String, dynamic>{};

        final prefs = UserPreferences.fromJson(json);

        expect(prefs.timezone, null);
        expect(prefs.locale, null);
        expect(prefs.emailNotifications, true); // default
        expect(prefs.pushNotifications, false); // default
        expect(prefs.weeklyDigest, false); // default
        expect(prefs.theme, 'light'); // default
        expect(prefs.defaultOrganizationId, null);
      });

      test('handles partial JSON', () {
        final json = {
          'email_notifications': false,
          'theme': 'dark',
        };

        final prefs = UserPreferences.fromJson(json);

        expect(prefs.emailNotifications, false);
        expect(prefs.theme, 'dark');
        expect(prefs.pushNotifications, false); // default
        expect(prefs.weeklyDigest, false); // default
      });
    });

    group('toJson', () {
      test('serializes UserPreferences with all fields', () {
        final prefs = UserPreferences(
          timezone: 'Europe/London',
          locale: 'en_GB',
          emailNotifications: false,
          pushNotifications: true,
          weeklyDigest: true,
          theme: 'dark',
          defaultOrganizationId: 'org-456',
        );

        final json = prefs.toJson();

        expect(json['timezone'], 'Europe/London');
        expect(json['locale'], 'en_GB');
        expect(json['email_notifications'], false);
        expect(json['push_notifications'], true);
        expect(json['weekly_digest'], true);
        expect(json['theme'], 'dark');
        expect(json['default_organization_id'], 'org-456');
      });

      test('includes null fields in JSON', () {
        final prefs = UserPreferences();

        final json = prefs.toJson();

        expect(json['timezone'], null);
        expect(json['locale'], null);
        expect(json['email_notifications'], true); // default
        expect(json['push_notifications'], false); // default
        expect(json['weekly_digest'], false); // default
        expect(json['theme'], 'light'); // default
      });
    });

    group('copyWith', () {
      final original = UserPreferences(
        timezone: 'America/New_York',
        locale: 'en_US',
        emailNotifications: true,
        pushNotifications: false,
        weeklyDigest: true,
        theme: 'dark',
        defaultOrganizationId: 'org-123',
      );

      test('creates copy with updated timezone', () {
        final copy = original.copyWith(timezone: 'Europe/London');
        expect(copy.timezone, 'Europe/London');
        expect(copy.locale, original.locale);
      });

      test('creates copy with updated emailNotifications', () {
        final copy = original.copyWith(emailNotifications: false);
        expect(copy.emailNotifications, false);
        expect(copy.timezone, original.timezone);
      });

      test('creates copy with updated theme', () {
        final copy = original.copyWith(theme: 'light');
        expect(copy.theme, 'light');
        expect(copy.timezone, original.timezone);
      });

      test('creates copy with no changes when no parameters provided', () {
        final copy = original.copyWith();
        expect(copy.timezone, original.timezone);
        expect(copy.locale, original.locale);
        expect(copy.emailNotifications, original.emailNotifications);
        expect(copy.theme, original.theme);
      });
    });

    group('round-trip conversion', () {
      test('preserves all data through JSON serialization', () {
        final original = UserPreferences(
          timezone: 'Asia/Tokyo',
          locale: 'ja_JP',
          emailNotifications: false,
          pushNotifications: true,
          weeklyDigest: false,
          theme: 'dark',
          defaultOrganizationId: 'org-789',
        );

        final json = original.toJson();
        final decoded = UserPreferences.fromJson(json);

        expect(decoded.timezone, original.timezone);
        expect(decoded.locale, original.locale);
        expect(decoded.emailNotifications, original.emailNotifications);
        expect(decoded.pushNotifications, original.pushNotifications);
        expect(decoded.weeklyDigest, original.weeklyDigest);
        expect(decoded.theme, original.theme);
        expect(decoded.defaultOrganizationId, original.defaultOrganizationId);
      });
    });

    group('edge cases', () {
      test('handles special timezone values', () {
        final timezones = [
          'UTC',
          'GMT',
          'America/New_York',
          'Europe/London',
          'Asia/Shanghai',
          'Pacific/Auckland',
        ];

        for (final tz in timezones) {
          final prefs = UserPreferences(timezone: tz);
          expect(prefs.timezone, tz);

          final json = prefs.toJson();
          final decoded = UserPreferences.fromJson(json);
          expect(decoded.timezone, tz);
        }
      });

      test('handles boolean toggling', () {
        final prefs = UserPreferences(
          emailNotifications: true,
          pushNotifications: false,
          weeklyDigest: true,
        );

        final toggled = prefs.copyWith(
          emailNotifications: !prefs.emailNotifications,
          pushNotifications: !prefs.pushNotifications,
          weeklyDigest: !prefs.weeklyDigest,
        );

        expect(toggled.emailNotifications, false);
        expect(toggled.pushNotifications, true);
        expect(toggled.weeklyDigest, false);
      });
    });
  });
}
