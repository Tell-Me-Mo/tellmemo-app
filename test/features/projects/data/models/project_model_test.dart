import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/projects/data/models/project_model.dart';
import 'package:pm_master_v2/features/projects/domain/entities/project.dart';

void main() {
  group('ProjectModel', () {
    group('fromJson', () {
      test('creates valid ProjectModel from complete JSON', () {
        // Arrange
        final json = {
          'id': 'proj-123',
          'name': 'Test Project',
          'description': 'A test project description',
          'created_by': 'user-456',
          'created_at': '2024-01-15T10:30:00',
          'updated_at': '2024-01-20T15:45:00',
          'status': 'active',
          'portfolio_id': 'port-789',
          'program_id': 'prog-012',
          'member_count': 5,
        };

        // Act
        final model = ProjectModel.fromJson(json);

        // Assert
        expect(model.id, 'proj-123');
        expect(model.name, 'Test Project');
        expect(model.description, 'A test project description');
        expect(model.createdBy, 'user-456');
        expect(model.createdAt, '2024-01-15T10:30:00');
        expect(model.updatedAt, '2024-01-20T15:45:00');
        expect(model.status, 'active');
        expect(model.portfolioId, 'port-789');
        expect(model.programId, 'prog-012');
        expect(model.memberCount, 5);
      });

      test('creates ProjectModel with minimal required fields', () {
        // Arrange
        final json = {
          'id': 'proj-123',
          'name': 'Minimal Project',
          'created_at': '2024-01-15T10:30:00',
          'updated_at': '2024-01-20T15:45:00',
          'status': 'active',
        };

        // Act
        final model = ProjectModel.fromJson(json);

        // Assert
        expect(model.id, 'proj-123');
        expect(model.name, 'Minimal Project');
        expect(model.description, isNull);
        expect(model.createdBy, isNull);
        expect(model.portfolioId, isNull);
        expect(model.programId, isNull);
        expect(model.memberCount, isNull);
      });

      test('creates ProjectModel with archived status', () {
        // Arrange
        final json = {
          'id': 'proj-123',
          'name': 'Archived Project',
          'created_at': '2024-01-15T10:30:00',
          'updated_at': '2024-01-20T15:45:00',
          'status': 'archived',
        };

        // Act
        final model = ProjectModel.fromJson(json);

        // Assert
        expect(model.status, 'archived');
      });
    });

    group('toJson', () {
      test('serializes complete ProjectModel to JSON', () {
        // Arrange
        final model = ProjectModel(
          id: 'proj-123',
          name: 'Test Project',
          description: 'A test project description',
          createdBy: 'user-456',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
          status: 'active',
          portfolioId: 'port-789',
          programId: 'prog-012',
          memberCount: 5,
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['id'], 'proj-123');
        expect(json['name'], 'Test Project');
        expect(json['description'], 'A test project description');
        expect(json['created_by'], 'user-456');
        expect(json['created_at'], '2024-01-15T10:30:00');
        expect(json['updated_at'], '2024-01-20T15:45:00');
        expect(json['status'], 'active');
        expect(json['portfolio_id'], 'port-789');
        expect(json['program_id'], 'prog-012');
        expect(json['member_count'], 5);
      });

      test('serializes ProjectModel with null optional fields', () {
        // Arrange
        final model = ProjectModel(
          id: 'proj-123',
          name: 'Minimal Project',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
          status: 'active',
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['description'], isNull);
        expect(json['created_by'], isNull);
        expect(json['portfolio_id'], isNull);
        expect(json['program_id'], isNull);
        expect(json['member_count'], isNull);
      });
    });

    group('toEntity', () {
      test('converts ProjectModel to Project entity with active status', () {
        // Arrange
        final model = ProjectModel(
          id: 'proj-123',
          name: 'Test Project',
          description: 'A test project',
          createdBy: 'user-456',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
          status: 'active',
          portfolioId: 'port-789',
          programId: 'prog-012',
          memberCount: 5,
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.id, 'proj-123');
        expect(entity.name, 'Test Project');
        expect(entity.description, 'A test project');
        expect(entity.createdBy, 'user-456');
        expect(entity.status, ProjectStatus.active);
        expect(entity.portfolioId, 'port-789');
        expect(entity.programId, 'prog-012');
        expect(entity.memberCount, 5);

        // Check that dates are converted to local time
        expect(entity.createdAt.isUtc, isFalse);
        expect(entity.updatedAt.isUtc, isFalse);
      });

      test('converts ProjectModel to Project entity with archived status', () {
        // Arrange
        final model = ProjectModel(
          id: 'proj-123',
          name: 'Archived Project',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
          status: 'archived',
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.status, ProjectStatus.archived);
      });

      test('handles invalid status gracefully, defaults to active', () {
        // Arrange
        final model = ProjectModel(
          id: 'proj-123',
          name: 'Test Project',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
          status: 'invalid_status',
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.status, ProjectStatus.active);
      });

      test('correctly parses UTC timestamps without Z suffix', () {
        // Arrange
        final model = ProjectModel(
          id: 'proj-123',
          name: 'Test Project',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
          status: 'active',
        );

        // Act
        final entity = model.toEntity();

        // Assert - Backend sends UTC without Z, we append Z and convert to local
        expect(entity.createdAt, isA<DateTime>());
        expect(entity.updatedAt, isA<DateTime>());
        expect(entity.createdAt.year, 2024);
        expect(entity.createdAt.month, 1);
        expect(entity.createdAt.day, 15);
      });
    });

    group('ProjectEntity toModel', () {
      test('converts Project entity to ProjectModel', () {
        // Arrange
        final entity = Project(
          id: 'proj-123',
          name: 'Test Project',
          description: 'A test project',
          createdBy: 'user-456',
          createdAt: DateTime(2024, 1, 15, 10, 30),
          updatedAt: DateTime(2024, 1, 20, 15, 45),
          status: ProjectStatus.active,
          portfolioId: 'port-789',
          programId: 'prog-012',
          memberCount: 5,
        );

        // Act
        final model = entity.toModel();

        // Assert
        expect(model.id, 'proj-123');
        expect(model.name, 'Test Project');
        expect(model.description, 'A test project');
        expect(model.createdBy, 'user-456');
        expect(model.status, 'active');
        expect(model.portfolioId, 'port-789');
        expect(model.programId, 'prog-012');
        expect(model.memberCount, 5);

        // Check ISO 8601 format
        expect(model.createdAt, contains('2024-01-15'));
        expect(model.updatedAt, contains('2024-01-20'));
      });

      test('converts Project entity with archived status', () {
        // Arrange
        final entity = Project(
          id: 'proj-123',
          name: 'Archived Project',
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 20),
          status: ProjectStatus.archived,
        );

        // Act
        final model = entity.toModel();

        // Assert
        expect(model.status, 'archived');
      });
    });

    group('Round-trip conversion', () {
      test('JSON -> Model -> Entity -> Model -> JSON preserves data', () {
        // Arrange
        final originalJson = {
          'id': 'proj-123',
          'name': 'Test Project',
          'description': 'Description',
          'created_by': 'user-456',
          'created_at': '2024-01-15T10:30:00',
          'updated_at': '2024-01-20T15:45:00',
          'status': 'active',
          'portfolio_id': 'port-789',
          'program_id': 'prog-012',
          'member_count': 5,
        };

        // Act
        final model1 = ProjectModel.fromJson(originalJson);
        final entity = model1.toEntity();
        final model2 = entity.toModel();
        final resultJson = model2.toJson();

        // Assert - Core data should be preserved
        expect(resultJson['id'], originalJson['id']);
        expect(resultJson['name'], originalJson['name']);
        expect(resultJson['description'], originalJson['description']);
        expect(resultJson['created_by'], originalJson['created_by']);
        expect(resultJson['status'], originalJson['status']);
        expect(resultJson['portfolio_id'], originalJson['portfolio_id']);
        expect(resultJson['program_id'], originalJson['program_id']);
        expect(resultJson['member_count'], originalJson['member_count']);
      });
    });
  });
}
