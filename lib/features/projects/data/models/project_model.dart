import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/project.dart';

part 'project_model.freezed.dart';
part 'project_model.g.dart';

@freezed
class ProjectModel with _$ProjectModel {
  const factory ProjectModel({
    required String id,
    required String name,
    String? description,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    required String status,
    @JsonKey(name: 'portfolio_id') String? portfolioId,
    @JsonKey(name: 'program_id') String? programId,
    @JsonKey(name: 'member_count') int? memberCount,
  }) = _ProjectModel;

  factory ProjectModel.fromJson(Map<String, dynamic> json) =>
      _$ProjectModelFromJson(json);
}

extension ProjectModelX on ProjectModel {
  Project toEntity() {
    // The backend sends UTC times without 'Z' suffix, so we need to parse as UTC
    final createdAtUtc = DateTime.parse(createdAt + 'Z');
    final updatedAtUtc = DateTime.parse(updatedAt + 'Z');

    return Project(
      id: id,
      name: name,
      description: description,
      createdBy: createdBy,
      createdAt: createdAtUtc.toLocal(),
      updatedAt: updatedAtUtc.toLocal(),
      status: ProjectStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => ProjectStatus.active,
      ),
      portfolioId: portfolioId,
      programId: programId,
      memberCount: memberCount,
    );
  }
}

extension ProjectX on Project {
  ProjectModel toModel() {
    return ProjectModel(
      id: id,
      name: name,
      description: description,
      createdBy: createdBy,
      createdAt: createdAt.toIso8601String(),
      updatedAt: updatedAt.toIso8601String(),
      status: status.name,
      portfolioId: portfolioId,
      programId: programId,
      memberCount: memberCount,
    );
  }
}