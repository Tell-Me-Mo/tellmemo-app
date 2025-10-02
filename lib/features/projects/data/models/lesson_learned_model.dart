import '../../domain/entities/lesson_learned.dart';

class LessonLearnedModel extends LessonLearned {
  const LessonLearnedModel({
    required super.id,
    required super.projectId,
    required super.title,
    required super.description,
    required super.category,
    required super.lessonType,
    required super.impact,
    super.recommendation,
    super.context,
    super.tags,
    super.aiGenerated,
    super.aiConfidence,
    super.sourceContentId,
    super.identifiedDate,
    super.lastUpdated,
    super.updatedBy,
  });

  factory LessonLearnedModel.fromJson(Map<String, dynamic> json) {
    return LessonLearnedModel(
      id: json['id'] ?? '',
      projectId: json['project_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: LessonCategory.fromString(json['category'] ?? 'other'),
      lessonType: LessonType.fromString(json['lesson_type'] ?? 'improvement'),
      impact: LessonImpact.fromString(json['impact'] ?? 'medium'),
      recommendation: json['recommendation'],
      context: json['context'],
      tags: json['tags'] is List ? List<String>.from(json['tags']) : [],
      aiGenerated: json['ai_generated'] ?? false,
      aiConfidence: json['ai_confidence'] is num
          ? json['ai_confidence'].toDouble()
          : null,
      sourceContentId: json['source_content_id'],
      identifiedDate: json['identified_date'] != null
          ? DateTime.parse(json['identified_date'])
          : null,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : null,
      updatedBy: json['updated_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'title': title,
      'description': description,
      'category': category.value,
      'lesson_type': lessonType.value,
      'impact': impact.value,
      if (recommendation != null) 'recommendation': recommendation,
      if (context != null) 'context': context,
      if (tags.isNotEmpty) 'tags': tags.join(','),
      'ai_generated': aiGenerated,
      if (aiConfidence != null) 'ai_confidence': aiConfidence,
      if (sourceContentId != null) 'source_content_id': sourceContentId,
      if (identifiedDate != null) 'identified_date': identifiedDate!.toIso8601String(),
      if (lastUpdated != null) 'last_updated': lastUpdated!.toIso8601String(),
      if (updatedBy != null) 'updated_by': updatedBy,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'description': description,
      'category': category.value,
      'lesson_type': lessonType.value,
      'impact': impact.value,
      if (recommendation != null) 'recommendation': recommendation,
      if (context != null) 'context': context,
      if (tags.isNotEmpty) 'tags': tags.join(','),
    };
  }
}