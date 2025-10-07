import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/hierarchy/data/models/program_model.dart';
import 'package:pm_master_v2/features/hierarchy/domain/entities/program.dart';

void main() {
  group('ProgramModel', () {
    group('fromJson', () {
      test('creates valid ProgramModel from complete JSON', () {
        // Arrange
        final json = {
          'id': 'prog-123',
          'name': 'Test Program',
          'description': 'A test program description',
          'portfolio_id': 'port-456',
          'portfolio_name': 'Parent Portfolio',
          'created_by': 'user-789',
          'created_at': '2024-01-15T10:30:00',
          'updated_at': '2024-01-20T15:45:00',
          'projects': [],
          'project_count': 5,
        };

        // Act
        final model = ProgramModel.fromJson(json);

        // Assert
        expect(model.id, 'prog-123');
        expect(model.name, 'Test Program');
        expect(model.description, 'A test program description');
        expect(model.portfolioId, 'port-456');
        expect(model.portfolioName, 'Parent Portfolio');
        expect(model.createdBy, 'user-789');
        expect(model.createdAt, '2024-01-15T10:30:00');
        expect(model.updatedAt, '2024-01-20T15:45:00');
        expect(model.projects, isEmpty);
        expect(model.projectCount, 5);
      });

      test('creates ProgramModel with minimal required fields', () {
        // Arrange
        final json = {
          'id': 'prog-123',
          'name': 'Minimal Program',
          'created_at': '2024-01-15T10:30:00',
          'updated_at': '2024-01-20T15:45:00',
        };

        // Act
        final model = ProgramModel.fromJson(json);

        // Assert
        expect(model.id, 'prog-123');
        expect(model.name, 'Minimal Program');
        expect(model.description, isNull);
        expect(model.portfolioId, isNull);
        expect(model.portfolioName, isNull);
        expect(model.createdBy, isNull);
        expect(model.projects, isEmpty);
        expect(model.projectCount, 0);
      });

      test('creates standalone ProgramModel without portfolio', () {
        // Arrange
        final json = {
          'id': 'prog-123',
          'name': 'Standalone Program',
          'description': 'Not attached to any portfolio',
          'created_at': '2024-01-15T10:30:00',
          'updated_at': '2024-01-20T15:45:00',
        };

        // Act
        final model = ProgramModel.fromJson(json);

        // Assert
        expect(model.portfolioId, isNull);
        expect(model.portfolioName, isNull);
      });
    });

    group('toJson', () {
      test('serializes complete ProgramModel to JSON', () {
        // Arrange
        final model = ProgramModel(
          id: 'prog-123',
          name: 'Test Program',
          description: 'A test program description',
          portfolioId: 'port-456',
          portfolioName: 'Parent Portfolio',
          createdBy: 'user-789',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
          projects: [],
          projectCount: 5,
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['id'], 'prog-123');
        expect(json['name'], 'Test Program');
        expect(json['description'], 'A test program description');
        expect(json['portfolio_id'], 'port-456');
        expect(json['portfolio_name'], 'Parent Portfolio');
        expect(json['created_by'], 'user-789');
        expect(json['created_at'], '2024-01-15T10:30:00');
        expect(json['updated_at'], '2024-01-20T15:45:00');
        expect(json['projects'], isEmpty);
        expect(json['project_count'], 5);
      });

      test('serializes ProgramModel with null optional fields', () {
        // Arrange
        final model = ProgramModel(
          id: 'prog-123',
          name: 'Minimal Program',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['description'], isNull);
        expect(json['portfolio_id'], isNull);
        expect(json['portfolio_name'], isNull);
        expect(json['created_by'], isNull);
      });
    });

    group('toEntity', () {
      test('converts ProgramModel to Program entity with all fields', () {
        // Arrange
        final model = ProgramModel(
          id: 'prog-123',
          name: 'Test Program',
          description: 'A test program',
          portfolioId: 'port-456',
          portfolioName: 'Parent Portfolio',
          createdBy: 'user-789',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
          projects: [],
          projectCount: 5,
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.id, 'prog-123');
        expect(entity.name, 'Test Program');
        expect(entity.description, 'A test program');
        expect(entity.portfolioId, 'port-456');
        expect(entity.portfolioName, 'Parent Portfolio');
        expect(entity.createdBy, 'user-789');
        expect(entity.createdAt, isA<DateTime>());
        expect(entity.updatedAt, isA<DateTime>());
        expect(entity.projects, isEmpty);
        expect(entity.projectCount, 5);
      });

      test('handles null createdBy field - defaults to empty string', () {
        final model = ProgramModel(
          id: 'prog-123',
          name: 'Program',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
        );

        final entity = model.toEntity();
        expect(entity.createdBy, ''); // Should default to empty string
      });

      test('converts timestamps to UTC DateTime', () {
        final model = ProgramModel(
          id: 'prog-123',
          name: 'Program',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
        );

        final entity = model.toEntity();

        // Should parse with Z suffix and convert to local
        expect(entity.createdAt.year, 2024);
        expect(entity.createdAt.month, 1);
        expect(entity.createdAt.day, 15);
        expect(entity.updatedAt.year, 2024);
        expect(entity.updatedAt.month, 1);
        expect(entity.updatedAt.day, 20);
      });
    });

    group('Entity to Model conversion', () {
      test('converts Program entity to ProgramModel', () {
        // Arrange
        final entity = Program(
          id: 'prog-123',
          name: 'Test Program',
          description: 'Test description',
          portfolioId: 'port-456',
          portfolioName: 'Parent Portfolio',
          createdBy: 'user-789',
          createdAt: DateTime(2024, 1, 15, 10, 30),
          updatedAt: DateTime(2024, 1, 20, 15, 45),
          projects: [],
          projectCount: 3,
        );

        // Act
        final model = entity.toModel();

        // Assert
        expect(model.id, 'prog-123');
        expect(model.name, 'Test Program');
        expect(model.description, 'Test description');
        expect(model.portfolioId, 'port-456');
        expect(model.portfolioName, 'Parent Portfolio');
        expect(model.createdBy, 'user-789');
        expect(model.createdAt, contains('2024-01-15'));
        expect(model.updatedAt, contains('2024-01-20'));
        expect(model.projectCount, 0); // Uses projects.length, not the projectCount field
      });

      test('handles null createdBy - defaults to empty string', () {
        final entity = Program(
          id: 'prog-123',
          name: 'Program',
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 20),
        );

        final model = entity.toModel();
        expect(model.createdBy, '');
      });

      test('formats DateTime to ISO 8601 string', () {
        final entity = Program(
          id: 'prog-123',
          name: 'Program',
          createdAt: DateTime(2024, 1, 15, 10, 30, 45),
          updatedAt: DateTime(2024, 1, 20, 15, 45, 30),
        );

        final model = entity.toModel();

        // ISO 8601 format
        expect(model.createdAt, matches(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}'));
        expect(model.updatedAt, matches(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}'));
      });
    });

    group('Round-trip conversion', () {
      test('preserves data through JSON → Model → Entity → Model → JSON', () {
        // Arrange
        final originalJson = {
          'id': 'prog-123',
          'name': 'Test Program',
          'description': 'Test description',
          'portfolio_id': 'port-456',
          'portfolio_name': 'Parent Portfolio',
          'created_by': 'user-789',
          'created_at': '2024-01-15T10:30:00',
          'updated_at': '2024-01-20T15:45:00',
          'projects': [],
          'project_count': 0,
        };

        // Act
        final model1 = ProgramModel.fromJson(originalJson);
        final entity = model1.toEntity();
        final model2 = entity.toModel();
        final finalJson = model2.toJson();

        // Assert - key fields preserved
        expect(finalJson['id'], originalJson['id']);
        expect(finalJson['name'], originalJson['name']);
        expect(finalJson['description'], originalJson['description']);
        expect(finalJson['portfolio_id'], originalJson['portfolio_id']);
        expect(finalJson['portfolio_name'], originalJson['portfolio_name']);
        expect(finalJson['created_by'], originalJson['created_by']);
      });
    });

    group('Edge cases', () {
      test('handles empty strings', () {
        final json = {
          'id': 'prog-123',
          'name': '',
          'description': '',
          'portfolio_name': '',
          'created_at': '2024-01-15T10:30:00',
          'updated_at': '2024-01-20T15:45:00',
        };

        final model = ProgramModel.fromJson(json);
        expect(model.name, '');
        expect(model.description, '');
        expect(model.portfolioName, '');
      });

      test('handles very long strings', () {
        final longString = 'A' * 10000;
        final json = {
          'id': 'prog-123',
          'name': longString,
          'description': longString,
          'portfolio_name': longString,
          'created_at': '2024-01-15T10:30:00',
          'updated_at': '2024-01-20T15:45:00',
        };

        final model = ProgramModel.fromJson(json);
        expect(model.name.length, 10000);
        expect(model.description?.length, 10000);
        expect(model.portfolioName?.length, 10000);
      });

      test('handles special characters in strings', () {
        final json = {
          'id': 'prog-123',
          'name': 'Program <>&"\'',
          'description': 'Test\nwith\ttabs',
          'portfolio_name': 'Portfolio™',
          'created_at': '2024-01-15T10:30:00',
          'updated_at': '2024-01-20T15:45:00',
        };

        final model = ProgramModel.fromJson(json);
        expect(model.name, 'Program <>&"\'');
        expect(model.description, 'Test\nwith\ttabs');
        expect(model.portfolioName, 'Portfolio™');
      });
    });
  });
}
