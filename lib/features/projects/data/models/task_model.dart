import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/task.dart';

part 'task_model.freezed.dart';
part 'task_model.g.dart';

@freezed
class TaskModel with _$TaskModel {
  const factory TaskModel({
    required String id,
    @JsonKey(name: 'project_id') required String projectId,
    required String title,
    String? description,
    required String status,
    required String priority,
    String? assignee,
    @JsonKey(name: 'due_date') String? dueDate,
    @JsonKey(name: 'completed_date') String? completedDate,
    @JsonKey(name: 'progress_percentage') required int progressPercentage,
    @JsonKey(name: 'blocker_description') String? blockerDescription,
    @JsonKey(name: 'question_to_ask') String? questionToAsk,
    @JsonKey(name: 'ai_generated') required bool aiGenerated,
    @JsonKey(name: 'ai_confidence') double? aiConfidence,
    @JsonKey(name: 'source_content_id') String? sourceContentId,
    @JsonKey(name: 'depends_on_risk_id') String? dependsOnRiskId,
    @JsonKey(name: 'created_date') String? createdDate,
    @JsonKey(name: 'last_updated') String? lastUpdated,
    @JsonKey(name: 'updated_by') String? updatedBy,
  }) = _TaskModel;

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);
}

extension TaskModelX on TaskModel {
  Task toEntity() {
    return Task(
      id: id,
      projectId: projectId,
      title: title,
      description: description,
      status: TaskStatus.values.firstWhere(
        (s) => s.name == status || s.name == _convertStatusName(status),
        orElse: () => TaskStatus.todo,
      ),
      priority: TaskPriority.values.firstWhere(
        (s) => s.name == priority,
        orElse: () => TaskPriority.medium,
      ),
      assignee: assignee,
      dueDate: dueDate != null
        ? DateTime.parse(dueDate! + (dueDate!.endsWith('Z') ? '' : 'Z')).toLocal()
        : null,
      completedDate: completedDate != null
        ? DateTime.parse(completedDate! + (completedDate!.endsWith('Z') ? '' : 'Z')).toLocal()
        : null,
      progressPercentage: progressPercentage,
      blockerDescription: blockerDescription,
      questionToAsk: questionToAsk,
      aiGenerated: aiGenerated,
      aiConfidence: aiConfidence,
      sourceContentId: sourceContentId,
      dependsOnRiskId: dependsOnRiskId,
      createdDate: createdDate != null
        ? DateTime.parse(createdDate! + (createdDate!.endsWith('Z') ? '' : 'Z')).toLocal()
        : null,
      lastUpdated: lastUpdated != null
        ? DateTime.parse(lastUpdated! + (lastUpdated!.endsWith('Z') ? '' : 'Z')).toLocal()
        : null,
      updatedBy: updatedBy,
    );
  }

  // Helper to convert backend status names to enum names
  String _convertStatusName(String status) {
    switch (status) {
      case 'in_progress':
        return 'inProgress';
      default:
        return status;
    }
  }
}

extension TaskX on Task {
  TaskModel toModel() {
    return TaskModel(
      id: id,
      projectId: projectId,
      title: title,
      description: description,
      status: _convertStatusToBackend(status),
      priority: priority.name,
      assignee: assignee,
      dueDate: dueDate?.toUtc().toIso8601String(),
      completedDate: completedDate?.toUtc().toIso8601String(),
      progressPercentage: progressPercentage,
      blockerDescription: blockerDescription,
      questionToAsk: questionToAsk,
      aiGenerated: aiGenerated,
      aiConfidence: aiConfidence,
      sourceContentId: sourceContentId,
      dependsOnRiskId: dependsOnRiskId,
      createdDate: createdDate?.toUtc().toIso8601String(),
      lastUpdated: lastUpdated?.toUtc().toIso8601String(),
      updatedBy: updatedBy,
    );
  }

  // Helper to convert enum names to backend format
  String _convertStatusToBackend(TaskStatus status) {
    switch (status) {
      case TaskStatus.inProgress:
        return 'in_progress';
      default:
        return status.name;
    }
  }
}