import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/program.dart';
import '../../../projects/data/models/project_model.dart';

part 'program_model.freezed.dart';
part 'program_model.g.dart';

@freezed
class ProgramModel with _$ProgramModel {
  const factory ProgramModel({
    required String id,
    required String name,
    String? description,
    @JsonKey(name: 'portfolio_id') String? portfolioId,
    @JsonKey(name: 'portfolio_name') String? portfolioName,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    @Default([]) List<ProjectModel> projects,
    @JsonKey(name: 'project_count') @Default(0) int projectCount,
  }) = _ProgramModel;

  factory ProgramModel.fromJson(Map<String, dynamic> json) =>
      _$ProgramModelFromJson(json);
}

extension ProgramModelX on ProgramModel {
  Program toEntity() {
    return Program(
      id: id,
      name: name,
      description: description,
      portfolioId: portfolioId,
      portfolioName: portfolioName,
      createdBy: createdBy ?? '',
      createdAt: DateTime.parse('${createdAt}Z').toLocal(),
      updatedAt: DateTime.parse('${updatedAt}Z').toLocal(),
      projects: projects.map((p) => p.toEntity()).toList(),
      projectCount: projectCount,
    );
  }
}

extension ProgramX on Program {
  ProgramModel toModel() {
    return ProgramModel(
      id: id,
      name: name,
      description: description,
      portfolioId: portfolioId,
      portfolioName: portfolioName,
      createdBy: createdBy ?? '',
      createdAt: createdAt.toIso8601String(),
      updatedAt: updatedAt.toIso8601String(),
      projects: projects.map((p) => p.toModel()).toList(),
      projectCount: projects.length,
    );
  }
}