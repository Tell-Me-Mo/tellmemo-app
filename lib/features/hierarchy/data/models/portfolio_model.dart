import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/portfolio.dart';
import 'program_model.dart';
import '../../../projects/data/models/project_model.dart';

part 'portfolio_model.freezed.dart';
part 'portfolio_model.g.dart';

@freezed
class PortfolioModel with _$PortfolioModel {
  const factory PortfolioModel({
    required String id,
    required String name,
    String? description,
    String? owner,
    @JsonKey(name: 'health_status') @Default('not_set') String healthStatus,
    @JsonKey(name: 'risk_summary') String? riskSummary,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    @Default([]) List<ProgramModel> programs,
    @JsonKey(name: 'direct_projects') @Default([]) List<ProjectModel> directProjects,
    @JsonKey(name: 'program_count') @Default(0) int programCount,
    @JsonKey(name: 'direct_project_count') @Default(0) int directProjectCount,
    @JsonKey(name: 'total_project_count') @Default(0) int totalProjectCount,
  }) = _PortfolioModel;

  factory PortfolioModel.fromJson(Map<String, dynamic> json) =>
      _$PortfolioModelFromJson(json);
}

extension PortfolioModelX on PortfolioModel {
  Portfolio toEntity() {
    return Portfolio(
      id: id,
      name: name,
      description: description,
      owner: owner,
      healthStatus: _parseHealthStatus(healthStatus),
      riskSummary: riskSummary,
      createdBy: createdBy,
      createdAt: DateTime.parse('${createdAt}Z').toLocal(),
      updatedAt: DateTime.parse('${updatedAt}Z').toLocal(),
      programs: programs.map((p) => p.toEntity()).toList(),
      directProjects: directProjects.map((p) => p.toEntity()).toList(),
    );
  }

  HealthStatus _parseHealthStatus(String status) {
    switch (status.toLowerCase()) {
      case 'green':
        return HealthStatus.green;
      case 'amber':
        return HealthStatus.amber;
      case 'red':
        return HealthStatus.red;
      case 'not_set':
      default:
        return HealthStatus.notSet;
    }
  }
}

extension PortfolioX on Portfolio {
  PortfolioModel toModel() {
    return PortfolioModel(
      id: id,
      name: name,
      description: description,
      owner: owner,
      healthStatus: _healthStatusToString(healthStatus),
      riskSummary: riskSummary,
      createdBy: createdBy,
      createdAt: createdAt.toIso8601String(),
      updatedAt: updatedAt.toIso8601String(),
      programs: programs.map((p) => p.toModel()).toList(),
      directProjects: directProjects.map((p) => p.toModel()).toList(),
      programCount: programs.length,
      directProjectCount: directProjects.length,
      totalProjectCount: totalProjectCount,
    );
  }

  String _healthStatusToString(HealthStatus status) {
    switch (status) {
      case HealthStatus.green:
        return 'green';
      case HealthStatus.amber:
        return 'amber';
      case HealthStatus.red:
        return 'red';
      case HealthStatus.notSet:
        return 'not_set';
    }
  }
}