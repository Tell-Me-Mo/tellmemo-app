import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/risk.dart';

part 'risk_model.freezed.dart';
part 'risk_model.g.dart';

@freezed
class RiskModel with _$RiskModel {
  const factory RiskModel({
    required String id,
    @JsonKey(name: 'project_id') required String projectId,
    required String title,
    required String description,
    required String severity,
    required String status,
    String? mitigation,
    String? impact,
    double? probability,
    @JsonKey(name: 'ai_generated') required bool aiGenerated,
    @JsonKey(name: 'ai_confidence') double? aiConfidence,
    @JsonKey(name: 'source_content_id') String? sourceContentId,
    @JsonKey(name: 'identified_date') String? identifiedDate,
    @JsonKey(name: 'resolved_date') String? resolvedDate,
    @JsonKey(name: 'last_updated') String? lastUpdated,
    @JsonKey(name: 'updated_by') String? updatedBy,
    @JsonKey(name: 'assigned_to') String? assignedTo,
    @JsonKey(name: 'assigned_to_email') String? assignedToEmail,
  }) = _RiskModel;

  factory RiskModel.fromJson(Map<String, dynamic> json) =>
      _$RiskModelFromJson(json);
}

extension RiskModelX on RiskModel {
  Risk toEntity() {
    return Risk(
      id: id,
      projectId: projectId,
      title: title,
      description: description,
      severity: RiskSeverity.values.firstWhere(
        (s) => s.name == severity,
        orElse: () => RiskSeverity.medium,
      ),
      status: RiskStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => RiskStatus.identified,
      ),
      mitigation: mitigation,
      impact: impact,
      probability: probability,
      aiGenerated: aiGenerated,
      aiConfidence: aiConfidence,
      sourceContentId: sourceContentId,
      identifiedDate: identifiedDate != null
        ? DateTime.parse(identifiedDate! + (identifiedDate!.endsWith('Z') ? '' : 'Z')).toLocal()
        : null,
      resolvedDate: resolvedDate != null
        ? DateTime.parse(resolvedDate! + (resolvedDate!.endsWith('Z') ? '' : 'Z')).toLocal()
        : null,
      lastUpdated: lastUpdated != null
        ? DateTime.parse(lastUpdated! + (lastUpdated!.endsWith('Z') ? '' : 'Z')).toLocal()
        : null,
      updatedBy: updatedBy,
      assignedTo: assignedTo,
      assignedToEmail: assignedToEmail,
    );
  }
}

extension RiskX on Risk {
  RiskModel toModel() {
    return RiskModel(
      id: id,
      projectId: projectId,
      title: title,
      description: description,
      severity: severity.name,
      status: status.name,
      mitigation: mitigation,
      impact: impact,
      probability: probability,
      aiGenerated: aiGenerated,
      aiConfidence: aiConfidence,
      sourceContentId: sourceContentId,
      identifiedDate: identifiedDate?.toUtc().toIso8601String(),
      resolvedDate: resolvedDate?.toUtc().toIso8601String(),
      lastUpdated: lastUpdated?.toUtc().toIso8601String(),
      updatedBy: updatedBy,
      assignedTo: assignedTo,
      assignedToEmail: assignedToEmail,
    );
  }
}