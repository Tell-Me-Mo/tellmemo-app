import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/organizations/data/models/organization_member.dart';

void main() {
  group('OrganizationMember', () {
    final testJoinedAt = DateTime(2024, 1, 15, 10, 30);
    final testInvitedAt = DateTime(2024, 1, 10, 9, 0);
    final testLastActiveAt = DateTime(2024, 1, 20, 15, 45);

    group('fromJson', () {
      test('creates valid OrganizationMember from complete JSON', () {
        // Arrange
        final json = {
          'organizationId': 'org-123',
          'userId': 'user-456',
          'userEmail': 'test@example.com',
          'userName': 'Test User',
          'userAvatarUrl': 'https://example.com/avatar.png',
          'role': 'admin',
          'status': 'active',
          'invitedBy': 'user-789',
          'joinedAt': testJoinedAt.toIso8601String(),
          'invitedAt': testInvitedAt.toIso8601String(),
          'lastActiveAt': testLastActiveAt.toIso8601String(),
        };

        // Act
        final member = OrganizationMember.fromJson(json);

        // Assert
        expect(member.organizationId, 'org-123');
        expect(member.userId, 'user-456');
        expect(member.userEmail, 'test@example.com');
        expect(member.userName, 'Test User');
        expect(member.userAvatarUrl, 'https://example.com/avatar.png');
        expect(member.role, 'admin');
        expect(member.status, 'active');
        expect(member.invitedBy, 'user-789');
        expect(member.joinedAt, testJoinedAt);
        expect(member.invitedAt, testInvitedAt);
        expect(member.lastActiveAt, testLastActiveAt);
      });

      test('creates OrganizationMember with minimal required fields', () {
        // Arrange
        final json = {
          'organizationId': 'org-123',
          'userId': 'user-456',
          'userEmail': 'test@example.com',
          'userName': 'Test User',
          'role': 'member',
        };

        // Act
        final member = OrganizationMember.fromJson(json);

        // Assert
        expect(member.organizationId, 'org-123');
        expect(member.userId, 'user-456');
        expect(member.userEmail, 'test@example.com');
        expect(member.userName, 'Test User');
        expect(member.role, 'member');
        expect(member.status, 'active'); // Default value
        expect(member.userAvatarUrl, isNull);
        expect(member.invitedBy, isNull);
        expect(member.joinedAt, isNull);
        expect(member.invitedAt, isNull);
        expect(member.lastActiveAt, isNull);
      });

      test('creates OrganizationMember with different roles', () {
        // Arrange
        final roles = ['admin', 'member', 'viewer', 'owner'];

        for (final role in roles) {
          final json = {
            'organizationId': 'org-123',
            'userId': 'user-456',
            'userEmail': 'test@example.com',
            'userName': 'Test User',
            'role': role,
          };

          // Act
          final member = OrganizationMember.fromJson(json);

          // Assert
          expect(member.role, role);
        }
      });

      test('creates OrganizationMember with different statuses', () {
        // Arrange
        final statuses = ['active', 'inactive', 'pending', 'suspended'];

        for (final status in statuses) {
          final json = {
            'organizationId': 'org-123',
            'userId': 'user-456',
            'userEmail': 'test@example.com',
            'userName': 'Test User',
            'role': 'member',
            'status': status,
          };

          // Act
          final member = OrganizationMember.fromJson(json);

          // Assert
          expect(member.status, status);
        }
      });
    });

    group('toJson', () {
      test('serializes complete OrganizationMember to JSON', () {
        // Arrange
        final member = OrganizationMember(
          organizationId: 'org-123',
          userId: 'user-456',
          userEmail: 'test@example.com',
          userName: 'Test User',
          userAvatarUrl: 'https://example.com/avatar.png',
          role: 'admin',
          status: 'active',
          invitedBy: 'user-789',
          joinedAt: testJoinedAt,
          invitedAt: testInvitedAt,
          lastActiveAt: testLastActiveAt,
        );

        // Act
        final json = member.toJson();

        // Assert
        expect(json['organizationId'], 'org-123');
        expect(json['userId'], 'user-456');
        expect(json['userEmail'], 'test@example.com');
        expect(json['userName'], 'Test User');
        expect(json['userAvatarUrl'], 'https://example.com/avatar.png');
        expect(json['role'], 'admin');
        expect(json['status'], 'active');
        expect(json['invitedBy'], 'user-789');
        expect(json['joinedAt'], testJoinedAt.toIso8601String());
        expect(json['invitedAt'], testInvitedAt.toIso8601String());
        expect(json['lastActiveAt'], testLastActiveAt.toIso8601String());
      });

      test('serializes OrganizationMember with null fields', () {
        // Arrange
        final member = OrganizationMember(
          organizationId: 'org-123',
          userId: 'user-456',
          userEmail: 'test@example.com',
          userName: 'Test User',
          role: 'member',
        );

        // Act
        final json = member.toJson();

        // Assert
        expect(json['organizationId'], 'org-123');
        expect(json['userId'], 'user-456');
        expect(json['userEmail'], 'test@example.com');
        expect(json['userName'], 'Test User');
        expect(json['role'], 'member');
        expect(json['status'], 'active');
        expect(json['userAvatarUrl'], isNull);
        expect(json['invitedBy'], isNull);
        expect(json['joinedAt'], isNull);
        expect(json['invitedAt'], isNull);
        expect(json['lastActiveAt'], isNull);
      });
    });

    group('round-trip conversion', () {
      test('JSON -> Model -> JSON preserves data', () {
        // Arrange
        final originalJson = {
          'organizationId': 'org-123',
          'userId': 'user-456',
          'userEmail': 'test@example.com',
          'userName': 'Test User',
          'userAvatarUrl': 'https://example.com/avatar.png',
          'role': 'admin',
          'status': 'active',
          'invitedBy': 'user-789',
          'joinedAt': testJoinedAt.toIso8601String(),
          'invitedAt': testInvitedAt.toIso8601String(),
          'lastActiveAt': testLastActiveAt.toIso8601String(),
        };

        // Act
        final member = OrganizationMember.fromJson(originalJson);
        final finalJson = member.toJson();

        // Assert
        expect(finalJson['organizationId'], originalJson['organizationId']);
        expect(finalJson['userId'], originalJson['userId']);
        expect(finalJson['userEmail'], originalJson['userEmail']);
        expect(finalJson['userName'], originalJson['userName']);
        expect(finalJson['userAvatarUrl'], originalJson['userAvatarUrl']);
        expect(finalJson['role'], originalJson['role']);
        expect(finalJson['status'], originalJson['status']);
        expect(finalJson['invitedBy'], originalJson['invitedBy']);
        expect(finalJson['joinedAt'], originalJson['joinedAt']);
        expect(finalJson['invitedAt'], originalJson['invitedAt']);
        expect(finalJson['lastActiveAt'], originalJson['lastActiveAt']);
      });
    });

    group('edge cases', () {
      test('handles very long user name', () {
        // Arrange
        final longName = 'A' * 1000;
        final json = {
          'organizationId': 'org-123',
          'userId': 'user-456',
          'userEmail': 'test@example.com',
          'userName': longName,
          'role': 'member',
        };

        // Act
        final member = OrganizationMember.fromJson(json);

        // Assert
        expect(member.userName, longName);
      });

      test('handles special characters in user name and email', () {
        // Arrange
        final json = {
          'organizationId': 'org-123',
          'userId': 'user-456',
          'userEmail': 'test+special@example.co.uk',
          'userName': 'Test & Co. <User> "Special" émojis 🎉',
          'role': 'member',
        };

        // Act
        final member = OrganizationMember.fromJson(json);

        // Assert
        expect(member.userEmail, 'test+special@example.co.uk');
        expect(member.userName, 'Test & Co. <User> "Special" émojis 🎉');
      });

      test('handles empty string fields', () {
        // Arrange
        final json = {
          'organizationId': '',
          'userId': '',
          'userEmail': '',
          'userName': '',
          'role': '',
        };

        // Act
        final member = OrganizationMember.fromJson(json);

        // Assert
        expect(member.organizationId, '');
        expect(member.userId, '');
        expect(member.userEmail, '');
        expect(member.userName, '');
        expect(member.role, '');
      });

      test('handles very long avatar URL', () {
        // Arrange
        final longUrl = 'https://example.com/${'a' * 2000}.png';
        final json = {
          'organizationId': 'org-123',
          'userId': 'user-456',
          'userEmail': 'test@example.com',
          'userName': 'Test User',
          'userAvatarUrl': longUrl,
          'role': 'member',
        };

        // Act
        final member = OrganizationMember.fromJson(json);

        // Assert
        expect(member.userAvatarUrl, longUrl);
      });

      test('handles various email formats', () {
        // Arrange
        final emails = [
          'simple@example.com',
          'with+plus@example.com',
          'with.dots@example.com',
          'with-dashes@example.com',
          'with_underscores@example.com',
          'numbers123@example.com',
          'subdomain@mail.example.com',
        ];

        for (final email in emails) {
          final json = {
            'organizationId': 'org-123',
            'userId': 'user-456',
            'userEmail': email,
            'userName': 'Test User',
            'role': 'member',
          };

          // Act
          final member = OrganizationMember.fromJson(json);

          // Assert
          expect(member.userEmail, email);
        }
      });

      test('handles past, present, and future dates', () {
        // Arrange
        final pastDate = DateTime(2020, 1, 1);
        final presentDate = DateTime.now();
        final futureDate = DateTime(2030, 12, 31);

        final json = {
          'organizationId': 'org-123',
          'userId': 'user-456',
          'userEmail': 'test@example.com',
          'userName': 'Test User',
          'role': 'member',
          'joinedAt': pastDate.toIso8601String(),
          'invitedAt': pastDate.toIso8601String(),
          'lastActiveAt': presentDate.toIso8601String(),
        };

        // Act
        final member = OrganizationMember.fromJson(json);

        // Assert
        expect(member.joinedAt, pastDate);
        expect(member.lastActiveAt, presentDate);
      });
    });
  });
}
