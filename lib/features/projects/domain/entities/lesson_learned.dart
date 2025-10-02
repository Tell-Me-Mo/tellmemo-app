import 'package:equatable/equatable.dart';

enum LessonCategory {
  technical('technical'),
  process('process'),
  communication('communication'),
  planning('planning'),
  resource('resource'),
  quality('quality'),
  other('other');

  final String value;
  const LessonCategory(this.value);

  static LessonCategory fromString(String value) {
    return LessonCategory.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => LessonCategory.other,
    );
  }
}

enum LessonType {
  success('success'),
  improvement('improvement'),
  challenge('challenge'),
  bestPractice('best_practice');

  final String value;
  const LessonType(this.value);

  static LessonType fromString(String value) {
    return LessonType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => LessonType.improvement,
    );
  }

  String get label {
    switch (this) {
      case LessonType.success:
        return 'Success';
      case LessonType.improvement:
        return 'Improvement';
      case LessonType.challenge:
        return 'Challenge';
      case LessonType.bestPractice:
        return 'Best Practice';
    }
  }
}

enum LessonImpact {
  low('low'),
  medium('medium'),
  high('high');

  final String value;
  const LessonImpact(this.value);

  static LessonImpact fromString(String value) {
    return LessonImpact.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => LessonImpact.medium,
    );
  }

  String get label => value[0].toUpperCase() + value.substring(1);
}

class LessonLearned extends Equatable {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final LessonCategory category;
  final LessonType lessonType;
  final LessonImpact impact;
  final String? recommendation;
  final String? context;
  final List<String> tags;
  final bool aiGenerated;
  final double? aiConfidence;
  final String? sourceContentId;
  final DateTime? identifiedDate;
  final DateTime? lastUpdated;
  final String? updatedBy;

  const LessonLearned({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.category,
    required this.lessonType,
    required this.impact,
    this.recommendation,
    this.context,
    this.tags = const [],
    this.aiGenerated = false,
    this.aiConfidence,
    this.sourceContentId,
    this.identifiedDate,
    this.lastUpdated,
    this.updatedBy,
  });

  String get categoryLabel {
    switch (category) {
      case LessonCategory.technical:
        return 'Technical';
      case LessonCategory.process:
        return 'Process';
      case LessonCategory.communication:
        return 'Communication';
      case LessonCategory.planning:
        return 'Planning';
      case LessonCategory.resource:
        return 'Resource';
      case LessonCategory.quality:
        return 'Quality';
      case LessonCategory.other:
        return 'Other';
    }
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        title,
        description,
        category,
        lessonType,
        impact,
        recommendation,
        context,
        tags,
        aiGenerated,
        aiConfidence,
        sourceContentId,
        identifiedDate,
        lastUpdated,
        updatedBy,
      ];
}