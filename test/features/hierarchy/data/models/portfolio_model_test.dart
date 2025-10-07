import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/hierarchy/data/models/portfolio_model.dart';
import 'package:pm_master_v2/features/hierarchy/domain/entities/portfolio.dart';

void main() {
  group('PortfolioModel', () {
    group('fromJson', () {
      test('creates valid PortfolioModel from complete JSON', () {
        // Arrange
        final json = {
          'id': 'port-123',
          'name': 'Test Portfolio',
          'description': 'A test portfolio description',
          'owner': 'John Doe',
          'health_status': 'green',
          'risk_summary': 'All risks managed',
          'created_by': 'user-456',
          'created_at': '2024-01-15T10:30:00',
          'updated_at': '2024-01-20T15:45:00',
          'programs': [],
          'direct_projects': [],
          'program_count': 3,
          'direct_project_count': 5,
          'total_project_count': 12,
        };

        // Act
        final model = PortfolioModel.fromJson(json);

        // Assert
        expect(model.id, 'port-123');
        expect(model.name, 'Test Portfolio');
        expect(model.description, 'A test portfolio description');
        expect(model.owner, 'John Doe');
        expect(model.healthStatus, 'green');
        expect(model.riskSummary, 'All risks managed');
        expect(model.createdBy, 'user-456');
        expect(model.createdAt, '2024-01-15T10:30:00');
        expect(model.updatedAt, '2024-01-20T15:45:00');
        expect(model.programs, isEmpty);
        expect(model.directProjects, isEmpty);
        expect(model.programCount, 3);
        expect(model.directProjectCount, 5);
        expect(model.totalProjectCount, 12);
      });

      test('creates PortfolioModel with minimal required fields', () {
        // Arrange
        final json = {
          'id': 'port-123',
          'name': 'Minimal Portfolio',
          'created_at': '2024-01-15T10:30:00',
          'updated_at': '2024-01-20T15:45:00',
        };

        // Act
        final model = PortfolioModel.fromJson(json);

        // Assert
        expect(model.id, 'port-123');
        expect(model.name, 'Minimal Portfolio');
        expect(model.description, isNull);
        expect(model.owner, isNull);
        expect(model.healthStatus, 'not_set'); // Default value
        expect(model.riskSummary, isNull);
        expect(model.createdBy, isNull);
        expect(model.programs, isEmpty);
        expect(model.directProjects, isEmpty);
        expect(model.programCount, 0);
        expect(model.directProjectCount, 0);
        expect(model.totalProjectCount, 0);
      });

      test('creates PortfolioModel with all health status values', () {
        final statuses = ['green', 'amber', 'red', 'not_set'];

        for (final status in statuses) {
          final json = {
            'id': 'port-123',
            'name': 'Portfolio',
            'health_status': status,
            'created_at': '2024-01-15T10:30:00',
            'updated_at': '2024-01-20T15:45:00',
          };

          final model = PortfolioModel.fromJson(json);
          expect(model.healthStatus, status);
        }
      });
    });

    group('toJson', () {
      test('serializes complete PortfolioModel to JSON', () {
        // Arrange
        final model = PortfolioModel(
          id: 'port-123',
          name: 'Test Portfolio',
          description: 'A test portfolio description',
          owner: 'John Doe',
          healthStatus: 'green',
          riskSummary: 'All risks managed',
          createdBy: 'user-456',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
          programs: [],
          directProjects: [],
          programCount: 3,
          directProjectCount: 5,
          totalProjectCount: 12,
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['id'], 'port-123');
        expect(json['name'], 'Test Portfolio');
        expect(json['description'], 'A test portfolio description');
        expect(json['owner'], 'John Doe');
        expect(json['health_status'], 'green');
        expect(json['risk_summary'], 'All risks managed');
        expect(json['created_by'], 'user-456');
        expect(json['created_at'], '2024-01-15T10:30:00');
        expect(json['updated_at'], '2024-01-20T15:45:00');
        expect(json['programs'], isEmpty);
        expect(json['direct_projects'], isEmpty);
        expect(json['program_count'], 3);
        expect(json['direct_project_count'], 5);
        expect(json['total_project_count'], 12);
      });

      test('serializes PortfolioModel with null optional fields', () {
        // Arrange
        final model = PortfolioModel(
          id: 'port-123',
          name: 'Minimal Portfolio',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['description'], isNull);
        expect(json['owner'], isNull);
        expect(json['risk_summary'], isNull);
        expect(json['created_by'], isNull);
      });
    });

    group('toEntity', () {
      test('converts PortfolioModel to Portfolio entity with all fields', () {
        // Arrange
        final model = PortfolioModel(
          id: 'port-123',
          name: 'Test Portfolio',
          description: 'A test portfolio',
          owner: 'John Doe',
          healthStatus: 'green',
          riskSummary: 'Low risk',
          createdBy: 'user-456',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
          programs: [],
          directProjects: [],
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.id, 'port-123');
        expect(entity.name, 'Test Portfolio');
        expect(entity.description, 'A test portfolio');
        expect(entity.owner, 'John Doe');
        expect(entity.healthStatus, HealthStatus.green);
        expect(entity.riskSummary, 'Low risk');
        expect(entity.createdBy, 'user-456');
        expect(entity.createdAt, isA<DateTime>());
        expect(entity.updatedAt, isA<DateTime>());
        expect(entity.programs, isEmpty);
        expect(entity.directProjects, isEmpty);
      });

      test('parses health status correctly - green', () {
        final model = PortfolioModel(
          id: 'port-123',
          name: 'Portfolio',
          healthStatus: 'green',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
        );

        final entity = model.toEntity();
        expect(entity.healthStatus, HealthStatus.green);
      });

      test('parses health status correctly - amber', () {
        final model = PortfolioModel(
          id: 'port-123',
          name: 'Portfolio',
          healthStatus: 'amber',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
        );

        final entity = model.toEntity();
        expect(entity.healthStatus, HealthStatus.amber);
      });

      test('parses health status correctly - red', () {
        final model = PortfolioModel(
          id: 'port-123',
          name: 'Portfolio',
          healthStatus: 'red',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
        );

        final entity = model.toEntity();
        expect(entity.healthStatus, HealthStatus.red);
      });

      test('parses health status correctly - not_set', () {
        final model = PortfolioModel(
          id: 'port-123',
          name: 'Portfolio',
          healthStatus: 'not_set',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
        );

        final entity = model.toEntity();
        expect(entity.healthStatus, HealthStatus.notSet);
      });

      test('handles invalid health status - defaults to notSet', () {
        final model = PortfolioModel(
          id: 'port-123',
          name: 'Portfolio',
          healthStatus: 'invalid_status',
          createdAt: '2024-01-15T10:30:00',
          updatedAt: '2024-01-20T15:45:00',
        );

        final entity = model.toEntity();
        expect(entity.healthStatus, HealthStatus.notSet);
      });

      test('converts timestamps to UTC DateTime', () {
        final model = PortfolioModel(
          id: 'port-123',
          name: 'Portfolio',
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
      test('converts Portfolio entity to PortfolioModel', () {
        // Arrange
        final entity = Portfolio(
          id: 'port-123',
          name: 'Test Portfolio',
          description: 'Test description',
          owner: 'John Doe',
          healthStatus: HealthStatus.green,
          riskSummary: 'Low risk',
          createdBy: 'user-456',
          createdAt: DateTime(2024, 1, 15, 10, 30),
          updatedAt: DateTime(2024, 1, 20, 15, 45),
          programs: [],
          directProjects: [],
        );

        // Act
        final model = entity.toModel();

        // Assert
        expect(model.id, 'port-123');
        expect(model.name, 'Test Portfolio');
        expect(model.description, 'Test description');
        expect(model.owner, 'John Doe');
        expect(model.healthStatus, 'green');
        expect(model.riskSummary, 'Low risk');
        expect(model.createdBy, 'user-456');
        expect(model.createdAt, contains('2024-01-15'));
        expect(model.updatedAt, contains('2024-01-20'));
      });

      test('converts health status enums to strings correctly', () {
        final testCases = {
          HealthStatus.green: 'green',
          HealthStatus.amber: 'amber',
          HealthStatus.red: 'red',
          HealthStatus.notSet: 'not_set',
        };

        for (final entry in testCases.entries) {
          final entity = Portfolio(
            id: 'port-123',
            name: 'Portfolio',
            healthStatus: entry.key,
            createdAt: DateTime(2024, 1, 15),
            updatedAt: DateTime(2024, 1, 20),
          );

          final model = entity.toModel();
          expect(model.healthStatus, entry.value);
        }
      });

      test('formats DateTime to ISO 8601 string', () {
        final entity = Portfolio(
          id: 'port-123',
          name: 'Portfolio',
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
          'id': 'port-123',
          'name': 'Test Portfolio',
          'description': 'Test description',
          'owner': 'John Doe',
          'health_status': 'green',
          'risk_summary': 'Low risk',
          'created_by': 'user-456',
          'created_at': '2024-01-15T10:30:00',
          'updated_at': '2024-01-20T15:45:00',
          'programs': [],
          'direct_projects': [],
          'program_count': 0,
          'direct_project_count': 0,
          'total_project_count': 0,
        };

        // Act
        final model1 = PortfolioModel.fromJson(originalJson);
        final entity = model1.toEntity();
        final model2 = entity.toModel();
        final finalJson = model2.toJson();

        // Assert - key fields preserved
        expect(finalJson['id'], originalJson['id']);
        expect(finalJson['name'], originalJson['name']);
        expect(finalJson['description'], originalJson['description']);
        expect(finalJson['owner'], originalJson['owner']);
        expect(finalJson['health_status'], originalJson['health_status']);
        expect(finalJson['risk_summary'], originalJson['risk_summary']);
        expect(finalJson['created_by'], originalJson['created_by']);
      });
    });

    group('Edge cases', () {
      test('handles empty strings', () {
        final json = {
          'id': 'port-123',
          'name': '',
          'description': '',
          'owner': '',
          'created_at': '2024-01-15T10:30:00',
          'updated_at': '2024-01-20T15:45:00',
        };

        final model = PortfolioModel.fromJson(json);
        expect(model.name, '');
        expect(model.description, '');
        expect(model.owner, '');
      });

      test('handles very long strings', () {
        final longString = 'A' * 10000;
        final json = {
          'id': 'port-123',
          'name': longString,
          'description': longString,
          'owner': longString,
          'risk_summary': longString,
          'created_at': '2024-01-15T10:30:00',
          'updated_at': '2024-01-20T15:45:00',
        };

        final model = PortfolioModel.fromJson(json);
        expect(model.name.length, 10000);
        expect(model.description?.length, 10000);
      });

      test('handles special characters in strings', () {
        final json = {
          'id': 'port-123',
          'name': 'Portfolio <>&"\'',
          'description': 'Test\nwith\ttabs',
          'owner': 'John@Doe.com',
          'created_at': '2024-01-15T10:30:00',
          'updated_at': '2024-01-20T15:45:00',
        };

        final model = PortfolioModel.fromJson(json);
        expect(model.name, 'Portfolio <>&"\'');
        expect(model.description, 'Test\nwith\ttabs');
        expect(model.owner, 'John@Doe.com');
      });
    });
  });
}
