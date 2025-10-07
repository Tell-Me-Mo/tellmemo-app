import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/projects/data/models/risk_model.dart';
import 'package:pm_master_v2/features/projects/domain/entities/risk.dart';

void main() {
  group('RiskModel', () {
    group('fromJson', () {
      test('creates valid RiskModel from complete JSON', () {
        // Arrange
        final json = {
          'id': 'risk-123',
          'project_id': 'proj-456',
          'title': 'Security Vulnerability',
          'description': 'Potential SQL injection vulnerability',
          'severity': 'critical',
          'status': 'identified',
          'mitigation': 'Use parameterized queries',
          'impact': 'Data breach possible',
          'probability': 0.75,
          'ai_generated': true,
          'ai_confidence': 0.92,
          'source_content_id': 'content-789',
          'identified_date': '2024-01-15T10:30:00Z',
          'resolved_date': '2024-01-20T15:45:00Z',
          'last_updated': '2024-01-22T09:00:00Z',
          'updated_by': 'user-012',
          'assigned_to': 'John Doe',
          'assigned_to_email': 'john.doe@example.com',
        };

        // Act
        final model = RiskModel.fromJson(json);

        // Assert
        expect(model.id, 'risk-123');
        expect(model.projectId, 'proj-456');
        expect(model.title, 'Security Vulnerability');
        expect(model.description, 'Potential SQL injection vulnerability');
        expect(model.severity, 'critical');
        expect(model.status, 'identified');
        expect(model.mitigation, 'Use parameterized queries');
        expect(model.impact, 'Data breach possible');
        expect(model.probability, 0.75);
        expect(model.aiGenerated, true);
        expect(model.aiConfidence, 0.92);
        expect(model.sourceContentId, 'content-789');
        expect(model.identifiedDate, '2024-01-15T10:30:00Z');
        expect(model.resolvedDate, '2024-01-20T15:45:00Z');
        expect(model.lastUpdated, '2024-01-22T09:00:00Z');
        expect(model.updatedBy, 'user-012');
        expect(model.assignedTo, 'John Doe');
        expect(model.assignedToEmail, 'john.doe@example.com');
      });

      test('creates RiskModel with minimal required fields', () {
        // Arrange
        final json = {
          'id': 'risk-123',
          'project_id': 'proj-456',
          'title': 'Minimal Risk',
          'description': 'Description',
          'severity': 'medium',
          'status': 'identified',
          'ai_generated': false,
        };

        // Act
        final model = RiskModel.fromJson(json);

        // Assert
        expect(model.id, 'risk-123');
        expect(model.projectId, 'proj-456');
        expect(model.title, 'Minimal Risk');
        expect(model.description, 'Description');
        expect(model.severity, 'medium');
        expect(model.status, 'identified');
        expect(model.aiGenerated, false);
        expect(model.mitigation, isNull);
        expect(model.impact, isNull);
        expect(model.probability, isNull);
        expect(model.aiConfidence, isNull);
        expect(model.sourceContentId, isNull);
        expect(model.identifiedDate, isNull);
        expect(model.resolvedDate, isNull);
        expect(model.lastUpdated, isNull);
        expect(model.updatedBy, isNull);
        expect(model.assignedTo, isNull);
        expect(model.assignedToEmail, isNull);
      });

      test('handles all severity levels correctly', () {
        // Test each severity
        for (final severity in RiskSeverity.values) {
          final json = {
            'id': 'risk-123',
            'project_id': 'proj-456',
            'title': 'Risk',
            'description': 'Description',
            'severity': severity.name,
            'status': 'identified',
            'ai_generated': false,
          };

          final model = RiskModel.fromJson(json);
          expect(model.severity, severity.name);
        }
      });

      test('handles all status values correctly', () {
        // Test each status
        for (final status in RiskStatus.values) {
          final json = {
            'id': 'risk-123',
            'project_id': 'proj-456',
            'title': 'Risk',
            'description': 'Description',
            'severity': 'medium',
            'status': status.name,
            'ai_generated': false,
          };

          final model = RiskModel.fromJson(json);
          expect(model.status, status.name);
        }
      });
    });

    group('toJson', () {
      test('serializes complete RiskModel to JSON', () {
        // Arrange
        final model = RiskModel(
          id: 'risk-123',
          projectId: 'proj-456',
          title: 'Security Vulnerability',
          description: 'Potential SQL injection',
          severity: 'critical',
          status: 'identified',
          mitigation: 'Use parameterized queries',
          impact: 'Data breach possible',
          probability: 0.75,
          aiGenerated: true,
          aiConfidence: 0.92,
          sourceContentId: 'content-789',
          identifiedDate: '2024-01-15T10:30:00Z',
          resolvedDate: '2024-01-20T15:45:00Z',
          lastUpdated: '2024-01-22T09:00:00Z',
          updatedBy: 'user-012',
          assignedTo: 'John Doe',
          assignedToEmail: 'john.doe@example.com',
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['id'], 'risk-123');
        expect(json['project_id'], 'proj-456');
        expect(json['title'], 'Security Vulnerability');
        expect(json['description'], 'Potential SQL injection');
        expect(json['severity'], 'critical');
        expect(json['status'], 'identified');
        expect(json['mitigation'], 'Use parameterized queries');
        expect(json['impact'], 'Data breach possible');
        expect(json['probability'], 0.75);
        expect(json['ai_generated'], true);
        expect(json['ai_confidence'], 0.92);
        expect(json['source_content_id'], 'content-789');
        expect(json['identified_date'], '2024-01-15T10:30:00Z');
        expect(json['resolved_date'], '2024-01-20T15:45:00Z');
        expect(json['last_updated'], '2024-01-22T09:00:00Z');
        expect(json['updated_by'], 'user-012');
        expect(json['assigned_to'], 'John Doe');
        expect(json['assigned_to_email'], 'john.doe@example.com');
      });

      test('includes null optional fields in JSON', () {
        // Arrange
        final model = RiskModel(
          id: 'risk-123',
          projectId: 'proj-456',
          title: 'Minimal Risk',
          description: 'Description',
          severity: 'medium',
          status: 'identified',
          aiGenerated: false,
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['mitigation'], isNull);
        expect(json['impact'], isNull);
        expect(json['probability'], isNull);
        expect(json['ai_confidence'], isNull);
        expect(json['source_content_id'], isNull);
        expect(json['identified_date'], isNull);
        expect(json['resolved_date'], isNull);
        expect(json['last_updated'], isNull);
        expect(json['updated_by'], isNull);
        expect(json['assigned_to'], isNull);
        expect(json['assigned_to_email'], isNull);
      });
    });

    group('toEntity', () {
      test('converts RiskModel to Risk entity with all fields', () {
        // Arrange
        final model = RiskModel(
          id: 'risk-123',
          projectId: 'proj-456',
          title: 'Security Risk',
          description: 'Description',
          severity: 'critical',
          status: 'mitigating',
          mitigation: 'Mitigation plan',
          impact: 'High impact',
          probability: 0.8,
          aiGenerated: true,
          aiConfidence: 0.95,
          sourceContentId: 'content-789',
          identifiedDate: '2024-01-15T10:30:00',
          resolvedDate: '2024-01-20T15:45:00',
          lastUpdated: '2024-01-22T09:00:00',
          updatedBy: 'user-012',
          assignedTo: 'John Doe',
          assignedToEmail: 'john.doe@example.com',
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.id, 'risk-123');
        expect(entity.projectId, 'proj-456');
        expect(entity.title, 'Security Risk');
        expect(entity.description, 'Description');
        expect(entity.severity, RiskSeverity.critical);
        expect(entity.status, RiskStatus.mitigating);
        expect(entity.mitigation, 'Mitigation plan');
        expect(entity.impact, 'High impact');
        expect(entity.probability, 0.8);
        expect(entity.aiGenerated, true);
        expect(entity.aiConfidence, 0.95);
        expect(entity.sourceContentId, 'content-789');
        expect(entity.assignedTo, 'John Doe');
        expect(entity.assignedToEmail, 'john.doe@example.com');

        // Check that dates are converted to local time
        expect(entity.identifiedDate, isA<DateTime>());
        expect(entity.resolvedDate, isA<DateTime>());
        expect(entity.lastUpdated, isA<DateTime>());
        expect(entity.identifiedDate!.isUtc, isFalse);
        expect(entity.resolvedDate!.isUtc, isFalse);
        expect(entity.lastUpdated!.isUtc, isFalse);
      });

      test('converts all severity levels correctly', () {
        for (final severity in RiskSeverity.values) {
          final model = RiskModel(
            id: 'risk-123',
            projectId: 'proj-456',
            title: 'Risk',
            description: 'Description',
            severity: severity.name,
            status: 'identified',
            aiGenerated: false,
          );

          final entity = model.toEntity();
          expect(entity.severity, severity);
        }
      });

      test('converts all status values correctly', () {
        for (final status in RiskStatus.values) {
          final model = RiskModel(
            id: 'risk-123',
            projectId: 'proj-456',
            title: 'Risk',
            description: 'Description',
            severity: 'medium',
            status: status.name,
            aiGenerated: false,
          );

          final entity = model.toEntity();
          expect(entity.status, status);
        }
      });

      test('handles invalid severity gracefully, defaults to medium', () {
        // Arrange
        final model = RiskModel(
          id: 'risk-123',
          projectId: 'proj-456',
          title: 'Risk',
          description: 'Description',
          severity: 'invalid_severity',
          status: 'identified',
          aiGenerated: false,
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.severity, RiskSeverity.medium);
      });

      test('handles invalid status gracefully, defaults to identified', () {
        // Arrange
        final model = RiskModel(
          id: 'risk-123',
          projectId: 'proj-456',
          title: 'Risk',
          description: 'Description',
          severity: 'medium',
          status: 'invalid_status',
          aiGenerated: false,
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.status, RiskStatus.identified);
      });

      test('handles timestamps with Z suffix correctly', () {
        // Arrange
        final model = RiskModel(
          id: 'risk-123',
          projectId: 'proj-456',
          title: 'Risk',
          description: 'Description',
          severity: 'medium',
          status: 'identified',
          aiGenerated: false,
          identifiedDate: '2024-01-15T10:30:00Z', // With Z
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.identifiedDate, isA<DateTime>());
        expect(entity.identifiedDate!.year, 2024);
        expect(entity.identifiedDate!.month, 1);
        expect(entity.identifiedDate!.day, 15);
      });

      test('handles timestamps without Z suffix correctly', () {
        // Arrange
        final model = RiskModel(
          id: 'risk-123',
          projectId: 'proj-456',
          title: 'Risk',
          description: 'Description',
          severity: 'medium',
          status: 'identified',
          aiGenerated: false,
          identifiedDate: '2024-01-15T10:30:00', // Without Z
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.identifiedDate, isA<DateTime>());
        expect(entity.identifiedDate!.year, 2024);
        expect(entity.identifiedDate!.month, 1);
        expect(entity.identifiedDate!.day, 15);
      });
    });

    group('RiskEntity toModel', () {
      test('converts Risk entity to RiskModel', () {
        // Arrange
        final entity = Risk(
          id: 'risk-123',
          projectId: 'proj-456',
          title: 'Security Risk',
          description: 'Description',
          severity: RiskSeverity.high,
          status: RiskStatus.mitigating,
          mitigation: 'Mitigation plan',
          impact: 'High impact',
          probability: 0.7,
          aiGenerated: true,
          aiConfidence: 0.88,
          sourceContentId: 'content-789',
          identifiedDate: DateTime(2024, 1, 15, 10, 30),
          resolvedDate: DateTime(2024, 1, 20, 15, 45),
          lastUpdated: DateTime(2024, 1, 22, 9, 0),
          updatedBy: 'user-012',
          assignedTo: 'John Doe',
          assignedToEmail: 'john.doe@example.com',
        );

        // Act
        final model = entity.toModel();

        // Assert
        expect(model.id, 'risk-123');
        expect(model.projectId, 'proj-456');
        expect(model.title, 'Security Risk');
        expect(model.description, 'Description');
        expect(model.severity, 'high');
        expect(model.status, 'mitigating');
        expect(model.mitigation, 'Mitigation plan');
        expect(model.impact, 'High impact');
        expect(model.probability, 0.7);
        expect(model.aiGenerated, true);
        expect(model.aiConfidence, 0.88);
        expect(model.sourceContentId, 'content-789');
        expect(model.updatedBy, 'user-012');
        expect(model.assignedTo, 'John Doe');
        expect(model.assignedToEmail, 'john.doe@example.com');

        // Check ISO 8601 UTC format for dates
        expect(model.identifiedDate, contains('2024-01-15'));
        expect(model.identifiedDate, endsWith('Z'));
        expect(model.resolvedDate, contains('2024-01-20'));
        expect(model.lastUpdated, contains('2024-01-22'));
      });

      test('converts entity with null optional fields', () {
        // Arrange
        final entity = Risk(
          id: 'risk-123',
          projectId: 'proj-456',
          title: 'Risk',
          description: 'Description',
          severity: RiskSeverity.low,
          status: RiskStatus.accepted,
          aiGenerated: false,
        );

        // Act
        final model = entity.toModel();

        // Assert
        expect(model.mitigation, isNull);
        expect(model.impact, isNull);
        expect(model.probability, isNull);
        expect(model.aiConfidence, isNull);
        expect(model.sourceContentId, isNull);
        expect(model.identifiedDate, isNull);
        expect(model.resolvedDate, isNull);
        expect(model.lastUpdated, isNull);
        expect(model.updatedBy, isNull);
        expect(model.assignedTo, isNull);
        expect(model.assignedToEmail, isNull);
      });
    });

    group('Round-trip conversion', () {
      test('JSON -> Model -> Entity -> Model -> JSON preserves data', () {
        // Arrange
        final originalJson = {
          'id': 'risk-123',
          'project_id': 'proj-456',
          'title': 'Test Risk',
          'description': 'Description',
          'severity': 'high',
          'status': 'mitigating',
          'mitigation': 'Mitigation',
          'impact': 'Impact',
          'probability': 0.65,
          'ai_generated': true,
          'ai_confidence': 0.9,
        };

        // Act
        final model1 = RiskModel.fromJson(originalJson);
        final entity = model1.toEntity();
        final model2 = entity.toModel();
        final resultJson = model2.toJson();

        // Assert - Core data should be preserved
        expect(resultJson['id'], originalJson['id']);
        expect(resultJson['project_id'], originalJson['project_id']);
        expect(resultJson['title'], originalJson['title']);
        expect(resultJson['description'], originalJson['description']);
        expect(resultJson['severity'], originalJson['severity']);
        expect(resultJson['status'], originalJson['status']);
        expect(resultJson['mitigation'], originalJson['mitigation']);
        expect(resultJson['impact'], originalJson['impact']);
        expect(resultJson['probability'], originalJson['probability']);
        expect(resultJson['ai_generated'], originalJson['ai_generated']);
        expect(resultJson['ai_confidence'], originalJson['ai_confidence']);
      });
    });

    group('Edge Cases', () {
      test('handles very long strings', () {
        // Arrange
        final longTitle = 'A' * 1000;
        final longDescription = 'B' * 5000;
        final longMitigation = 'C' * 3000;

        final json = {
          'id': 'risk-123',
          'project_id': 'proj-456',
          'title': longTitle,
          'description': longDescription,
          'severity': 'medium',
          'status': 'identified',
          'mitigation': longMitigation,
          'ai_generated': false,
        };

        // Act
        final model = RiskModel.fromJson(json);

        // Assert
        expect(model.title.length, 1000);
        expect(model.description.length, 5000);
        expect(model.mitigation!.length, 3000);
      });

      test('handles special characters in strings', () {
        // Arrange
        final json = {
          'id': 'risk-123',
          'project_id': 'proj-456',
          'title': 'Risk: "Special" Characters & <HTML> Tags',
          'description': "It's a risk with special chars: @#\$%^&*()",
          'severity': 'medium',
          'status': 'identified',
          'ai_generated': false,
        };

        // Act
        final model = RiskModel.fromJson(json);

        // Assert
        expect(model.title, 'Risk: "Special" Characters & <HTML> Tags');
        expect(model.description, "It's a risk with special chars: @#\$%^&*()");
      });

      test('handles edge case probability values', () {
        // Test 0.0
        var json = {
          'id': 'risk-123',
          'project_id': 'proj-456',
          'title': 'Risk',
          'description': 'Description',
          'severity': 'medium',
          'status': 'identified',
          'probability': 0.0,
          'ai_generated': false,
        };
        var model = RiskModel.fromJson(json);
        expect(model.probability, 0.0);

        // Test 1.0
        json['probability'] = 1.0;
        model = RiskModel.fromJson(json);
        expect(model.probability, 1.0);
      });

      test('handles email with special characters', () {
        // Arrange
        final json = {
          'id': 'risk-123',
          'project_id': 'proj-456',
          'title': 'Risk',
          'description': 'Description',
          'severity': 'medium',
          'status': 'identified',
          'ai_generated': false,
          'assigned_to_email': 'john+test@example.co.uk',
        };

        // Act
        final model = RiskModel.fromJson(json);

        // Assert
        expect(model.assignedToEmail, 'john+test@example.co.uk');
      });
    });
  });
}
