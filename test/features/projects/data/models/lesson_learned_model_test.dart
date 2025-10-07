import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/projects/data/models/lesson_learned_model.dart';
import 'package:pm_master_v2/features/projects/domain/entities/lesson_learned.dart';

void main() {
  group('LessonLearnedModel', () {
    group('fromJson', () {
      test('creates valid LessonLearnedModel from complete JSON', () {
        // Arrange
        final json = {
          'id': 'lesson-123',
          'project_id': 'proj-456',
          'title': 'Lesson Title',
          'description': 'Lesson Description',
          'category': 'technical',
          'lesson_type': 'success',
          'impact': 'high',
          'recommendation': 'Use this approach in future',
          'context': 'During sprint 3',
          'tags': ['backend', 'api', 'performance'],
          'ai_generated': true,
          'ai_confidence': 0.95,
          'source_content_id': 'content-789',
          'identified_date': '2024-01-15T10:30:00Z',
          'last_updated': '2024-01-20T15:45:00Z',
          'updated_by': 'user-012',
        };

        // Act
        final model = LessonLearnedModel.fromJson(json);

        // Assert
        expect(model.id, 'lesson-123');
        expect(model.projectId, 'proj-456');
        expect(model.title, 'Lesson Title');
        expect(model.description, 'Lesson Description');
        expect(model.category, LessonCategory.technical);
        expect(model.lessonType, LessonType.success);
        expect(model.impact, LessonImpact.high);
        expect(model.recommendation, 'Use this approach in future');
        expect(model.context, 'During sprint 3');
        expect(model.tags, ['backend', 'api', 'performance']);
        expect(model.aiGenerated, true);
        expect(model.aiConfidence, 0.95);
        expect(model.sourceContentId, 'content-789');
        expect(model.identifiedDate, DateTime.parse('2024-01-15T10:30:00Z'));
        expect(model.lastUpdated, DateTime.parse('2024-01-20T15:45:00Z'));
        expect(model.updatedBy, 'user-012');
      });

      test('creates LessonLearnedModel with minimal required fields', () {
        // Arrange
        final json = {
          'id': 'lesson-123',
          'project_id': 'proj-456',
          'title': 'Minimal Lesson',
          'description': 'Description',
          'category': 'other',
          'lesson_type': 'improvement',
          'impact': 'medium',
        };

        // Act
        final model = LessonLearnedModel.fromJson(json);

        // Assert
        expect(model.id, 'lesson-123');
        expect(model.projectId, 'proj-456');
        expect(model.title, 'Minimal Lesson');
        expect(model.description, 'Description');
        expect(model.category, LessonCategory.other);
        expect(model.lessonType, LessonType.improvement);
        expect(model.impact, LessonImpact.medium);
        expect(model.recommendation, isNull);
        expect(model.context, isNull);
        expect(model.tags, isEmpty);
        expect(model.aiGenerated, false);
        expect(model.aiConfidence, isNull);
        expect(model.sourceContentId, isNull);
        expect(model.identifiedDate, isNull);
        expect(model.lastUpdated, isNull);
        expect(model.updatedBy, isNull);
      });

      test('handles missing fields with defaults', () {
        // Arrange
        final json = <String, dynamic>{
          // All fields missing except those with defaults
        };

        // Act
        final model = LessonLearnedModel.fromJson(json);

        // Assert
        expect(model.id, '');
        expect(model.projectId, '');
        expect(model.title, '');
        expect(model.description, '');
        expect(model.category, LessonCategory.other);
        expect(model.lessonType, LessonType.improvement);
        expect(model.impact, LessonImpact.medium);
        expect(model.aiGenerated, false);
        expect(model.tags, isEmpty);
      });

      test('handles all lesson categories correctly', () {
        // Test each category
        for (final category in LessonCategory.values) {
          final json = {
            'category': category.value,
            'lesson_type': 'improvement',
            'impact': 'medium',
          };

          final model = LessonLearnedModel.fromJson(json);
          expect(model.category, category);
        }
      });

      test('handles all lesson types correctly', () {
        // Test each type
        for (final type in LessonType.values) {
          final json = {
            'category': 'technical',
            'lesson_type': type.value,
            'impact': 'medium',
          };

          final model = LessonLearnedModel.fromJson(json);
          expect(model.lessonType, type);
        }
      });

      test('handles all impact levels correctly', () {
        // Test each impact level
        for (final impact in LessonImpact.values) {
          final json = {
            'category': 'technical',
            'lesson_type': 'improvement',
            'impact': impact.value,
          };

          final model = LessonLearnedModel.fromJson(json);
          expect(model.impact, impact);
        }
      });

      test('handles invalid category gracefully, defaults to other', () {
        // Arrange
        final json = {
          'category': 'invalid_category',
          'lesson_type': 'improvement',
          'impact': 'medium',
        };

        // Act
        final model = LessonLearnedModel.fromJson(json);

        // Assert
        expect(model.category, LessonCategory.other);
      });

      test('handles invalid lesson_type gracefully, defaults to improvement', () {
        // Arrange
        final json = {
          'category': 'technical',
          'lesson_type': 'invalid_type',
          'impact': 'medium',
        };

        // Act
        final model = LessonLearnedModel.fromJson(json);

        // Assert
        expect(model.lessonType, LessonType.improvement);
      });

      test('handles invalid impact gracefully, defaults to medium', () {
        // Arrange
        final json = {
          'category': 'technical',
          'lesson_type': 'improvement',
          'impact': 'invalid_impact',
        };

        // Act
        final model = LessonLearnedModel.fromJson(json);

        // Assert
        expect(model.impact, LessonImpact.medium);
      });

      test('handles tags as list correctly', () {
        // Arrange
        final json = {
          'category': 'technical',
          'lesson_type': 'improvement',
          'impact': 'medium',
          'tags': ['tag1', 'tag2', 'tag3'],
        };

        // Act
        final model = LessonLearnedModel.fromJson(json);

        // Assert
        expect(model.tags, ['tag1', 'tag2', 'tag3']);
      });

      test('handles empty tags list', () {
        // Arrange
        final json = {
          'category': 'technical',
          'lesson_type': 'improvement',
          'impact': 'medium',
          'tags': [],
        };

        // Act
        final model = LessonLearnedModel.fromJson(json);

        // Assert
        expect(model.tags, isEmpty);
      });

      test('handles non-list tags gracefully', () {
        // Arrange
        final json = {
          'category': 'technical',
          'lesson_type': 'improvement',
          'impact': 'medium',
          'tags': 'not-a-list',
        };

        // Act
        final model = LessonLearnedModel.fromJson(json);

        // Assert
        expect(model.tags, isEmpty);
      });

      test('converts ai_confidence from int to double', () {
        // Arrange
        final json = {
          'category': 'technical',
          'lesson_type': 'improvement',
          'impact': 'medium',
          'ai_confidence': 1, // int instead of double
        };

        // Act
        final model = LessonLearnedModel.fromJson(json);

        // Assert
        expect(model.aiConfidence, 1.0);
        expect(model.aiConfidence, isA<double>());
      });
    });

    group('toJson', () {
      test('serializes complete LessonLearnedModel to JSON', () {
        // Arrange
        final model = LessonLearnedModel(
          id: 'lesson-123',
          projectId: 'proj-456',
          title: 'Lesson Title',
          description: 'Lesson Description',
          category: LessonCategory.technical,
          lessonType: LessonType.success,
          impact: LessonImpact.high,
          recommendation: 'Use this approach',
          context: 'Sprint 3',
          tags: ['backend', 'api'],
          aiGenerated: true,
          aiConfidence: 0.95,
          sourceContentId: 'content-789',
          identifiedDate: DateTime.parse('2024-01-15T10:30:00Z'),
          lastUpdated: DateTime.parse('2024-01-20T15:45:00Z'),
          updatedBy: 'user-012',
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['id'], 'lesson-123');
        expect(json['project_id'], 'proj-456');
        expect(json['title'], 'Lesson Title');
        expect(json['description'], 'Lesson Description');
        expect(json['category'], 'technical');
        expect(json['lesson_type'], 'success');
        expect(json['impact'], 'high');
        expect(json['recommendation'], 'Use this approach');
        expect(json['context'], 'Sprint 3');
        expect(json['tags'], 'backend,api'); // Tags joined with comma
        expect(json['ai_generated'], true);
        expect(json['ai_confidence'], 0.95);
        expect(json['source_content_id'], 'content-789');
        expect(json['identified_date'], '2024-01-15T10:30:00.000Z');
        expect(json['last_updated'], '2024-01-20T15:45:00.000Z');
        expect(json['updated_by'], 'user-012');
      });

      test('excludes null optional fields from JSON', () {
        // Arrange
        final model = LessonLearnedModel(
          id: 'lesson-123',
          projectId: 'proj-456',
          title: 'Minimal Lesson',
          description: 'Description',
          category: LessonCategory.technical,
          lessonType: LessonType.improvement,
          impact: LessonImpact.medium,
          aiGenerated: false,
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json.containsKey('recommendation'), false);
        expect(json.containsKey('context'), false);
        expect(json.containsKey('ai_confidence'), false);
        expect(json.containsKey('source_content_id'), false);
        expect(json.containsKey('identified_date'), false);
        expect(json.containsKey('last_updated'), false);
        expect(json.containsKey('updated_by'), false);
      });

      test('excludes empty tags from JSON', () {
        // Arrange
        final model = LessonLearnedModel(
          id: 'lesson-123',
          projectId: 'proj-456',
          title: 'Lesson',
          description: 'Description',
          category: LessonCategory.technical,
          lessonType: LessonType.improvement,
          impact: LessonImpact.medium,
          tags: [],
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json.containsKey('tags'), false);
      });

      test('includes tags when not empty', () {
        // Arrange
        final model = LessonLearnedModel(
          id: 'lesson-123',
          projectId: 'proj-456',
          title: 'Lesson',
          description: 'Description',
          category: LessonCategory.technical,
          lessonType: LessonType.improvement,
          impact: LessonImpact.medium,
          tags: ['tag1', 'tag2', 'tag3'],
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['tags'], 'tag1,tag2,tag3');
      });
    });

    group('toCreateJson', () {
      test('serializes only required fields for creation', () {
        // Arrange
        final model = LessonLearnedModel(
          id: 'lesson-123', // Should be excluded in create
          projectId: 'proj-456', // Should be excluded in create
          title: 'Lesson Title',
          description: 'Lesson Description',
          category: LessonCategory.technical,
          lessonType: LessonType.success,
          impact: LessonImpact.high,
          recommendation: 'Use this approach',
          context: 'Sprint 3',
          tags: ['backend', 'api'],
          aiGenerated: true, // Should be excluded in create
          sourceContentId: 'content-789', // Should be excluded in create
        );

        // Act
        final json = model.toCreateJson();

        // Assert
        expect(json.containsKey('id'), false);
        expect(json.containsKey('project_id'), false);
        expect(json.containsKey('ai_generated'), false);
        expect(json.containsKey('source_content_id'), false);

        expect(json['title'], 'Lesson Title');
        expect(json['description'], 'Lesson Description');
        expect(json['category'], 'technical');
        expect(json['lesson_type'], 'success');
        expect(json['impact'], 'high');
        expect(json['recommendation'], 'Use this approach');
        expect(json['context'], 'Sprint 3');
        expect(json['tags'], 'backend,api');
      });

      test('excludes null optional fields in create JSON', () {
        // Arrange
        final model = LessonLearnedModel(
          id: 'lesson-123',
          projectId: 'proj-456',
          title: 'Lesson',
          description: 'Description',
          category: LessonCategory.technical,
          lessonType: LessonType.improvement,
          impact: LessonImpact.medium,
        );

        // Act
        final json = model.toCreateJson();

        // Assert
        expect(json.containsKey('recommendation'), false);
        expect(json.containsKey('context'), false);
        expect(json.containsKey('tags'), false);
      });
    });

    group('Round-trip conversion', () {
      test('JSON -> Model -> JSON preserves data', () {
        // Arrange
        final originalJson = {
          'id': 'lesson-123',
          'project_id': 'proj-456',
          'title': 'Test Lesson',
          'description': 'Description',
          'category': 'technical',
          'lesson_type': 'success',
          'impact': 'high',
          'recommendation': 'Recommendation',
          'context': 'Context',
          'tags': ['tag1', 'tag2'],
          'ai_generated': true,
          'ai_confidence': 0.85,
        };

        // Act
        final model = LessonLearnedModel.fromJson(originalJson);
        final resultJson = model.toJson();

        // Assert
        expect(resultJson['id'], originalJson['id']);
        expect(resultJson['project_id'], originalJson['project_id']);
        expect(resultJson['title'], originalJson['title']);
        expect(resultJson['description'], originalJson['description']);
        expect(resultJson['category'], originalJson['category']);
        expect(resultJson['lesson_type'], originalJson['lesson_type']);
        expect(resultJson['impact'], originalJson['impact']);
        expect(resultJson['recommendation'], originalJson['recommendation']);
        expect(resultJson['context'], originalJson['context']);
        expect(resultJson['tags'], 'tag1,tag2'); // Note: converted to comma-separated string
        expect(resultJson['ai_generated'], originalJson['ai_generated']);
        expect(resultJson['ai_confidence'], originalJson['ai_confidence']);
      });
    });

    group('Edge Cases', () {
      test('handles very long strings', () {
        // Arrange
        final longTitle = 'A' * 1000;
        final longDescription = 'B' * 5000;

        final json = {
          'title': longTitle,
          'description': longDescription,
          'category': 'technical',
          'lesson_type': 'improvement',
          'impact': 'medium',
        };

        // Act
        final model = LessonLearnedModel.fromJson(json);

        // Assert
        expect(model.title.length, 1000);
        expect(model.description.length, 5000);
      });

      test('handles special characters in strings', () {
        // Arrange
        final json = {
          'title': 'Lesson: "Special" Characters & <HTML> Tags',
          'description': "It's a lesson with special chars: @#\$%^&*()",
          'category': 'technical',
          'lesson_type': 'improvement',
          'impact': 'medium',
        };

        // Act
        final model = LessonLearnedModel.fromJson(json);

        // Assert
        expect(model.title, 'Lesson: "Special" Characters & <HTML> Tags');
        expect(model.description, "It's a lesson with special chars: @#\$%^&*()");
      });

      test('handles edge case ai_confidence values', () {
        // Test 0.0
        var json = {
          'category': 'technical',
          'lesson_type': 'improvement',
          'impact': 'medium',
          'ai_confidence': 0.0,
        };
        var model = LessonLearnedModel.fromJson(json);
        expect(model.aiConfidence, 0.0);

        // Test 1.0
        json = {
          'category': 'technical',
          'lesson_type': 'improvement',
          'impact': 'medium',
          'ai_confidence': 1.0,
        };
        model = LessonLearnedModel.fromJson(json);
        expect(model.aiConfidence, 1.0);
      });

      test('handles tags with commas in toJson', () {
        // Arrange
        final model = LessonLearnedModel(
          id: 'lesson-123',
          projectId: 'proj-456',
          title: 'Lesson',
          description: 'Description',
          category: LessonCategory.technical,
          lessonType: LessonType.improvement,
          impact: LessonImpact.medium,
          tags: ['tag,with,commas', 'normal-tag', 'another,one'],
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['tags'], 'tag,with,commas,normal-tag,another,one');
      });
    });
  });
}
