import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/projects/domain/entities/project_member.dart';

void main() {
  group('ProjectMember', () {
    group('Constructor', () {
      test('creates ProjectMember with all fields', () {
        // Arrange & Act
        final member = ProjectMember(
          id: 'member-123',
          projectId: 'proj-456',
          name: 'John Doe',
          email: 'john.doe@example.com',
          role: 'developer',
          addedAt: DateTime(2024, 1, 15),
        );

        // Assert
        expect(member.id, 'member-123');
        expect(member.projectId, 'proj-456');
        expect(member.name, 'John Doe');
        expect(member.email, 'john.doe@example.com');
        expect(member.role, 'developer');
        expect(member.addedAt, DateTime(2024, 1, 15));
      });

      test('creates ProjectMember with optional fields as null', () {
        // Arrange & Act
        final member = ProjectMember(
          projectId: 'proj-456',
          name: 'John Doe',
          email: 'john.doe@example.com',
          role: 'developer',
        );

        // Assert
        expect(member.id, isNull);
        expect(member.addedAt, isNull);
      });
    });

    group('copyWith', () {
      test('creates copy with updated id', () {
        // Arrange
        final original = ProjectMember(
          id: 'member-123',
          projectId: 'proj-456',
          name: 'John Doe',
          email: 'john.doe@example.com',
          role: 'developer',
        );

        // Act
        final copy = original.copyWith(id: 'member-789');

        // Assert
        expect(copy.id, 'member-789');
        expect(copy.projectId, original.projectId);
        expect(copy.name, original.name);
        expect(copy.email, original.email);
        expect(copy.role, original.role);
      });

      test('creates copy with updated name', () {
        // Arrange
        final original = ProjectMember(
          projectId: 'proj-456',
          name: 'John Doe',
          email: 'john.doe@example.com',
          role: 'developer',
        );

        // Act
        final copy = original.copyWith(name: 'Jane Smith');

        // Assert
        expect(copy.name, 'Jane Smith');
        expect(copy.email, original.email);
      });

      test('creates copy with updated email', () {
        // Arrange
        final original = ProjectMember(
          projectId: 'proj-456',
          name: 'John Doe',
          email: 'john.doe@example.com',
          role: 'developer',
        );

        // Act
        final copy = original.copyWith(email: 'john.smith@example.com');

        // Assert
        expect(copy.email, 'john.smith@example.com');
        expect(copy.name, original.name);
      });

      test('creates copy with updated role', () {
        // Arrange
        final original = ProjectMember(
          projectId: 'proj-456',
          name: 'John Doe',
          email: 'john.doe@example.com',
          role: 'developer',
        );

        // Act
        final copy = original.copyWith(role: 'manager');

        // Assert
        expect(copy.role, 'manager');
        expect(copy.name, original.name);
      });

      test('creates copy with updated projectId', () {
        // Arrange
        final original = ProjectMember(
          projectId: 'proj-456',
          name: 'John Doe',
          email: 'john.doe@example.com',
          role: 'developer',
        );

        // Act
        final copy = original.copyWith(projectId: 'proj-789');

        // Assert
        expect(copy.projectId, 'proj-789');
        expect(copy.name, original.name);
      });

      test('creates copy with updated addedAt date', () {
        // Arrange
        final original = ProjectMember(
          projectId: 'proj-456',
          name: 'John Doe',
          email: 'john.doe@example.com',
          role: 'developer',
          addedAt: DateTime(2024, 1, 15),
        );

        final newDate = DateTime(2024, 2, 20);

        // Act
        final copy = original.copyWith(addedAt: newDate);

        // Assert
        expect(copy.addedAt, newDate);
        expect(copy.name, original.name);
      });

      test('creates exact copy when no parameters provided', () {
        // Arrange
        final original = ProjectMember(
          id: 'member-123',
          projectId: 'proj-456',
          name: 'John Doe',
          email: 'john.doe@example.com',
          role: 'developer',
          addedAt: DateTime(2024, 1, 15),
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.id, original.id);
        expect(copy.projectId, original.projectId);
        expect(copy.name, original.name);
        expect(copy.email, original.email);
        expect(copy.role, original.role);
        expect(copy.addedAt, original.addedAt);
      });

      test('creates copy with multiple updated fields', () {
        // Arrange
        final original = ProjectMember(
          id: 'member-123',
          projectId: 'proj-456',
          name: 'John Doe',
          email: 'john.doe@example.com',
          role: 'developer',
        );

        // Act
        final copy = original.copyWith(
          name: 'Jane Smith',
          email: 'jane.smith@example.com',
          role: 'senior_developer',
        );

        // Assert
        expect(copy.name, 'Jane Smith');
        expect(copy.email, 'jane.smith@example.com');
        expect(copy.role, 'senior_developer');
        expect(copy.id, original.id); // unchanged
        expect(copy.projectId, original.projectId); // unchanged
      });
    });

    group('JSON Serialization', () {
      test('fromJson creates valid ProjectMember from complete JSON', () {
        // Arrange
        final json = {
          'id': 'member-123',
          'project_id': 'proj-456',
          'name': 'John Doe',
          'email': 'john.doe@example.com',
          'role': 'developer',
          'added_at': '2024-01-15T10:30:00Z',
        };

        // Act
        final member = ProjectMember.fromJson(json);

        // Assert
        expect(member.id, 'member-123');
        expect(member.projectId, 'proj-456');
        expect(member.name, 'John Doe');
        expect(member.email, 'john.doe@example.com');
        expect(member.role, 'developer');
        expect(member.addedAt, DateTime.parse('2024-01-15T10:30:00Z'));
      });

      test('fromJson creates ProjectMember with minimal required fields', () {
        // Arrange
        final json = {
          'project_id': 'proj-456',
          'name': 'John Doe',
          'email': 'john.doe@example.com',
          'role': 'developer',
        };

        // Act
        final member = ProjectMember.fromJson(json);

        // Assert
        expect(member.id, isNull);
        expect(member.projectId, 'proj-456');
        expect(member.name, 'John Doe');
        expect(member.email, 'john.doe@example.com');
        expect(member.role, 'developer');
        expect(member.addedAt, isNull);
      });

      test('toJson serializes complete ProjectMember to JSON', () {
        // Arrange
        final member = ProjectMember(
          id: 'member-123',
          projectId: 'proj-456',
          name: 'John Doe',
          email: 'john.doe@example.com',
          role: 'developer',
          addedAt: DateTime.parse('2024-01-15T10:30:00Z'),
        );

        // Act
        final json = member.toJson();

        // Assert
        expect(json['id'], 'member-123');
        expect(json['project_id'], 'proj-456');
        expect(json['name'], 'John Doe');
        expect(json['email'], 'john.doe@example.com');
        expect(json['role'], 'developer');
        expect(json['added_at'], contains('2024-01-15'));
      });

      test('toJson excludes null optional fields', () {
        // Arrange
        final member = ProjectMember(
          projectId: 'proj-456',
          name: 'John Doe',
          email: 'john.doe@example.com',
          role: 'developer',
        );

        // Act
        final json = member.toJson();

        // Assert
        expect(json.containsKey('id'), false);
        expect(json.containsKey('added_at'), false);
        expect(json['project_id'], 'proj-456');
        expect(json['name'], 'John Doe');
      });

      test('round-trip JSON conversion preserves data', () {
        // Arrange
        final originalJson = {
          'id': 'member-123',
          'project_id': 'proj-456',
          'name': 'John Doe',
          'email': 'john.doe@example.com',
          'role': 'senior_developer',
          'added_at': '2024-01-15T10:30:00Z',
        };

        // Act
        final member = ProjectMember.fromJson(originalJson);
        final resultJson = member.toJson();

        // Assert
        expect(resultJson['id'], originalJson['id']);
        expect(resultJson['project_id'], originalJson['project_id']);
        expect(resultJson['name'], originalJson['name']);
        expect(resultJson['email'], originalJson['email']);
        expect(resultJson['role'], originalJson['role']);
        expect(resultJson['added_at'], isNotNull);
      });
    });

    group('Edge Cases', () {
      test('handles empty string values', () {
        // Arrange & Act
        final member = ProjectMember(
          projectId: '',
          name: '',
          email: '',
          role: '',
        );

        // Assert
        expect(member.projectId, '');
        expect(member.name, '');
        expect(member.email, '');
        expect(member.role, '');
      });

      test('handles special characters in strings', () {
        // Arrange & Act
        final member = ProjectMember(
          projectId: 'proj-456',
          name: "O'Brien, John Jr.",
          email: 'john+test@example.com',
          role: 'senior/lead developer',
        );

        // Assert
        expect(member.name, "O'Brien, John Jr.");
        expect(member.email, 'john+test@example.com');
        expect(member.role, 'senior/lead developer');
      });

      test('handles very long strings', () {
        // Arrange
        final longName = 'A' * 1000;
        final longEmail = '${'user' * 50}@${'domain' * 50}.com';

        // Act
        final member = ProjectMember(
          projectId: 'proj-456',
          name: longName,
          email: longEmail,
          role: 'developer',
        );

        // Assert
        expect(member.name.length, 1000);
        expect(member.email, longEmail);
      });
    });
  });
}
