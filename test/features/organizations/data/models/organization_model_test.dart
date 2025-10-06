import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/organizations/data/models/organization_model.dart';
import 'package:pm_master_v2/features/organizations/domain/entities/organization.dart';

void main() {
  group('OrganizationModel', () {
    final testDateTime = DateTime(2024, 1, 15, 10, 30);
    final testUpdatedDateTime = DateTime(2024, 1, 20, 15, 45);

    group('fromJson', () {
      test('creates valid OrganizationModel from complete JSON', () {
        // Arrange
        final json = {
          'id': 'org-123',
          'name': 'Test Organization',
          'slug': 'test-org',
          'description': 'A test organization',
          'logo_url': 'https://example.com/logo.png',
          'settings': {'theme': 'dark', 'language': 'en'},
          'is_active': true,
          'created_by': 'user-456',
          'created_at': testDateTime.toIso8601String(),
          'updated_at': testUpdatedDateTime.toIso8601String(),
          'member_count': 10,
          'current_user_role': 'admin',
          'current_user_id': 'user-789',
          'project_count': 5,
          'document_count': 20,
        };

        // Act
        final model = OrganizationModel.fromJson(json);

        // Assert
        expect(model.id, 'org-123');
        expect(model.name, 'Test Organization');
        expect(model.slug, 'test-org');
        expect(model.description, 'A test organization');
        expect(model.logoUrl, 'https://example.com/logo.png');
        expect(model.settings, {'theme': 'dark', 'language': 'en'});
        expect(model.isActive, true);
        expect(model.createdBy, 'user-456');
        expect(model.createdAt, testDateTime);
        expect(model.updatedAt, testUpdatedDateTime);
        expect(model.memberCount, 10);
        expect(model.currentUserRole, 'admin');
        expect(model.currentUserId, 'user-789');
        expect(model.projectCount, 5);
        expect(model.documentCount, 20);
      });

      test('creates OrganizationModel with minimal required fields', () {
        // Arrange
        final json = {
          'id': 'org-123',
          'name': 'Minimal Org',
          'slug': 'minimal-org',
          'created_at': testDateTime.toIso8601String(),
          'updated_at': testUpdatedDateTime.toIso8601String(),
        };

        // Act
        final model = OrganizationModel.fromJson(json);

        // Assert
        expect(model.id, 'org-123');
        expect(model.name, 'Minimal Org');
        expect(model.slug, 'minimal-org');
        expect(model.description, isNull);
        expect(model.logoUrl, isNull);
        expect(model.settings, {});
        expect(model.isActive, true); // Default value
        expect(model.createdBy, isNull);
        expect(model.memberCount, isNull);
        expect(model.currentUserRole, isNull);
        expect(model.currentUserId, isNull);
        expect(model.projectCount, isNull);
        expect(model.documentCount, isNull);
      });

      test('creates OrganizationModel with inactive status', () {
        // Arrange
        final json = {
          'id': 'org-123',
          'name': 'Inactive Org',
          'slug': 'inactive-org',
          'is_active': false,
          'created_at': testDateTime.toIso8601String(),
          'updated_at': testUpdatedDateTime.toIso8601String(),
        };

        // Act
        final model = OrganizationModel.fromJson(json);

        // Assert
        expect(model.isActive, false);
      });

      test('creates OrganizationModel with empty settings', () {
        // Arrange
        final json = {
          'id': 'org-123',
          'name': 'Test Org',
          'slug': 'test-org',
          'settings': <String, dynamic>{},
          'created_at': testDateTime.toIso8601String(),
          'updated_at': testUpdatedDateTime.toIso8601String(),
        };

        // Act
        final model = OrganizationModel.fromJson(json);

        // Assert
        expect(model.settings, {});
      });

      test('creates OrganizationModel with complex nested settings', () {
        // Arrange
        final json = {
          'id': 'org-123',
          'name': 'Test Org',
          'slug': 'test-org',
          'settings': {
            'theme': 'dark',
            'notifications': {'email': true, 'push': false},
            'features': ['feature1', 'feature2'],
          },
          'created_at': testDateTime.toIso8601String(),
          'updated_at': testUpdatedDateTime.toIso8601String(),
        };

        // Act
        final model = OrganizationModel.fromJson(json);

        // Assert
        expect(model.settings['theme'], 'dark');
        expect(model.settings['notifications'], {'email': true, 'push': false});
        expect(model.settings['features'], ['feature1', 'feature2']);
      });
    });

    group('toJson', () {
      test('serializes complete OrganizationModel to JSON', () {
        // Arrange
        final model = OrganizationModel(
          id: 'org-123',
          name: 'Test Organization',
          slug: 'test-org',
          description: 'A test organization',
          logoUrl: 'https://example.com/logo.png',
          settings: {'theme': 'dark'},
          isActive: true,
          createdBy: 'user-456',
          createdAt: testDateTime,
          updatedAt: testUpdatedDateTime,
          memberCount: 10,
          currentUserRole: 'admin',
          currentUserId: 'user-789',
          projectCount: 5,
          documentCount: 20,
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['id'], 'org-123');
        expect(json['name'], 'Test Organization');
        expect(json['slug'], 'test-org');
        expect(json['description'], 'A test organization');
        expect(json['logo_url'], 'https://example.com/logo.png');
        expect(json['settings'], {'theme': 'dark'});
        expect(json['is_active'], true);
        expect(json['created_by'], 'user-456');
        expect(json['created_at'], testDateTime.toIso8601String());
        expect(json['updated_at'], testUpdatedDateTime.toIso8601String());
        expect(json['member_count'], 10);
        expect(json['current_user_role'], 'admin');
        expect(json['current_user_id'], 'user-789');
        expect(json['project_count'], 5);
        expect(json['document_count'], 20);
      });

      test('serializes OrganizationModel with null fields', () {
        // Arrange
        final model = OrganizationModel(
          id: 'org-123',
          name: 'Test Organization',
          slug: 'test-org',
          createdAt: testDateTime,
          updatedAt: testUpdatedDateTime,
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['id'], 'org-123');
        expect(json['name'], 'Test Organization');
        expect(json['slug'], 'test-org');
        expect(json['description'], isNull);
        expect(json['logo_url'], isNull);
        expect(json['settings'], {});
        expect(json['is_active'], true);
        expect(json['created_by'], isNull);
        expect(json['member_count'], isNull);
        expect(json['current_user_role'], isNull);
        expect(json['current_user_id'], isNull);
        expect(json['project_count'], isNull);
        expect(json['document_count'], isNull);
      });
    });

    group('toEntity', () {
      test('converts OrganizationModel to Organization entity', () {
        // Arrange
        final model = OrganizationModel(
          id: 'org-123',
          name: 'Test Organization',
          slug: 'test-org',
          description: 'A test organization',
          logoUrl: 'https://example.com/logo.png',
          settings: {'theme': 'dark'},
          isActive: true,
          createdBy: 'user-456',
          createdAt: testDateTime,
          updatedAt: testUpdatedDateTime,
          memberCount: 10,
          currentUserRole: 'admin',
          currentUserId: 'user-789',
          projectCount: 5,
          documentCount: 20,
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity, isA<Organization>());
        expect(entity.id, 'org-123');
        expect(entity.name, 'Test Organization');
        expect(entity.slug, 'test-org');
        expect(entity.description, 'A test organization');
        expect(entity.logoUrl, 'https://example.com/logo.png');
        expect(entity.settings, {'theme': 'dark'});
        expect(entity.isActive, true);
        expect(entity.createdBy, 'user-456');
        expect(entity.createdAt, testDateTime);
        expect(entity.updatedAt, testUpdatedDateTime);
        expect(entity.memberCount, 10);
        expect(entity.currentUserRole, 'admin');
        expect(entity.currentUserId, 'user-789');
        expect(entity.projectCount, 5);
        expect(entity.documentCount, 20);
      });

      test('converts OrganizationModel with null fields to entity', () {
        // Arrange
        final model = OrganizationModel(
          id: 'org-123',
          name: 'Test Organization',
          slug: 'test-org',
          settings: {},
          isActive: true,
          createdAt: testDateTime,
          updatedAt: testUpdatedDateTime,
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.id, 'org-123');
        expect(entity.name, 'Test Organization');
        expect(entity.slug, 'test-org');
        expect(entity.description, isNull);
        expect(entity.logoUrl, isNull);
        expect(entity.settings, {});
        expect(entity.createdBy, isNull);
        expect(entity.memberCount, isNull);
        expect(entity.currentUserRole, isNull);
        expect(entity.currentUserId, isNull);
        expect(entity.projectCount, isNull);
        expect(entity.documentCount, isNull);
      });
    });

    group('fromEntity', () {
      test('converts Organization entity to OrganizationModel', () {
        // Arrange
        final entity = Organization(
          id: 'org-123',
          name: 'Test Organization',
          slug: 'test-org',
          description: 'A test organization',
          logoUrl: 'https://example.com/logo.png',
          settings: {'theme': 'dark'},
          isActive: true,
          createdBy: 'user-456',
          createdAt: testDateTime,
          updatedAt: testUpdatedDateTime,
          memberCount: 10,
          currentUserRole: 'admin',
          currentUserId: 'user-789',
          projectCount: 5,
          documentCount: 20,
        );

        // Act
        final model = OrganizationModel.fromEntity(entity);

        // Assert
        expect(model, isA<OrganizationModel>());
        expect(model.id, 'org-123');
        expect(model.name, 'Test Organization');
        expect(model.slug, 'test-org');
        expect(model.description, 'A test organization');
        expect(model.logoUrl, 'https://example.com/logo.png');
        expect(model.settings, {'theme': 'dark'});
        expect(model.isActive, true);
        expect(model.createdBy, 'user-456');
        expect(model.createdAt, testDateTime);
        expect(model.updatedAt, testUpdatedDateTime);
        expect(model.memberCount, 10);
        expect(model.currentUserRole, 'admin');
        expect(model.currentUserId, 'user-789');
        expect(model.projectCount, 5);
        expect(model.documentCount, 20);
      });
    });

    group('round-trip conversion', () {
      test('JSON -> Model -> Entity -> Model -> JSON preserves data', () {
        // Arrange
        final originalJson = {
          'id': 'org-123',
          'name': 'Test Organization',
          'slug': 'test-org',
          'description': 'A test organization',
          'logo_url': 'https://example.com/logo.png',
          'settings': {'theme': 'dark'},
          'is_active': true,
          'created_by': 'user-456',
          'created_at': testDateTime.toIso8601String(),
          'updated_at': testUpdatedDateTime.toIso8601String(),
          'member_count': 10,
          'current_user_role': 'admin',
          'current_user_id': 'user-789',
          'project_count': 5,
          'document_count': 20,
        };

        // Act
        final model1 = OrganizationModel.fromJson(originalJson);
        final entity = model1.toEntity();
        final model2 = OrganizationModel.fromEntity(entity);
        final finalJson = model2.toJson();

        // Assert
        expect(finalJson['id'], originalJson['id']);
        expect(finalJson['name'], originalJson['name']);
        expect(finalJson['slug'], originalJson['slug']);
        expect(finalJson['description'], originalJson['description']);
        expect(finalJson['logo_url'], originalJson['logo_url']);
        expect(finalJson['settings'], originalJson['settings']);
        expect(finalJson['is_active'], originalJson['is_active']);
        expect(finalJson['created_by'], originalJson['created_by']);
        expect(finalJson['member_count'], originalJson['member_count']);
        expect(finalJson['current_user_role'], originalJson['current_user_role']);
        expect(finalJson['current_user_id'], originalJson['current_user_id']);
        expect(finalJson['project_count'], originalJson['project_count']);
        expect(finalJson['document_count'], originalJson['document_count']);
      });
    });

    group('edge cases', () {
      test('handles very long organization name', () {
        // Arrange
        final longName = 'A' * 1000;
        final json = {
          'id': 'org-123',
          'name': longName,
          'slug': 'test-org',
          'created_at': testDateTime.toIso8601String(),
          'updated_at': testUpdatedDateTime.toIso8601String(),
        };

        // Act
        final model = OrganizationModel.fromJson(json);

        // Assert
        expect(model.name, longName);
      });

      test('handles special characters in name and description', () {
        // Arrange
        final json = {
          'id': 'org-123',
          'name': 'Test & Co. <Organization> "Special"',
          'slug': 'test-org',
          'description': 'Description with émojis 🎉 and symbols: @#\$%',
          'created_at': testDateTime.toIso8601String(),
          'updated_at': testUpdatedDateTime.toIso8601String(),
        };

        // Act
        final model = OrganizationModel.fromJson(json);

        // Assert
        expect(model.name, 'Test & Co. <Organization> "Special"');
        expect(model.description, 'Description with émojis 🎉 and symbols: @#\$%');
      });

      test('handles empty string fields', () {
        // Arrange
        final json = {
          'id': 'org-123',
          'name': '',
          'slug': '',
          'description': '',
          'created_at': testDateTime.toIso8601String(),
          'updated_at': testUpdatedDateTime.toIso8601String(),
        };

        // Act
        final model = OrganizationModel.fromJson(json);

        // Assert
        expect(model.name, '');
        expect(model.slug, '');
        expect(model.description, '');
      });

      test('handles zero counts', () {
        // Arrange
        final json = {
          'id': 'org-123',
          'name': 'Test Org',
          'slug': 'test-org',
          'member_count': 0,
          'project_count': 0,
          'document_count': 0,
          'created_at': testDateTime.toIso8601String(),
          'updated_at': testUpdatedDateTime.toIso8601String(),
        };

        // Act
        final model = OrganizationModel.fromJson(json);

        // Assert
        expect(model.memberCount, 0);
        expect(model.projectCount, 0);
        expect(model.documentCount, 0);
      });

      test('handles very large counts', () {
        // Arrange
        final json = {
          'id': 'org-123',
          'name': 'Test Org',
          'slug': 'test-org',
          'member_count': 999999,
          'project_count': 999999,
          'document_count': 999999,
          'created_at': testDateTime.toIso8601String(),
          'updated_at': testUpdatedDateTime.toIso8601String(),
        };

        // Act
        final model = OrganizationModel.fromJson(json);

        // Assert
        expect(model.memberCount, 999999);
        expect(model.projectCount, 999999);
        expect(model.documentCount, 999999);
      });
    });
  });
}
