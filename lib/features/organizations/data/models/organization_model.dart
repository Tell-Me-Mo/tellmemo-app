import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/organization.dart';

part 'organization_model.freezed.dart';
part 'organization_model.g.dart';

@freezed
class OrganizationModel with _$OrganizationModel {
  const OrganizationModel._();

  const factory OrganizationModel({
    required String id,
    required String name,
    required String slug,
    String? description,
    @JsonKey(name: 'logo_url') String? logoUrl,
    @Default({}) Map<String, dynamic> settings,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'member_count') int? memberCount,
    @JsonKey(name: 'current_user_role') String? currentUserRole,
    @JsonKey(name: 'current_user_id') String? currentUserId,
    @JsonKey(name: 'project_count') int? projectCount,
    @JsonKey(name: 'document_count') int? documentCount,
  }) = _OrganizationModel;

  factory OrganizationModel.fromJson(Map<String, dynamic> json) =>
      _$OrganizationModelFromJson(json);

  Organization toEntity() {
    return Organization(
      id: id,
      name: name,
      slug: slug,
      description: description,
      logoUrl: logoUrl,
      settings: settings,
      isActive: isActive,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      memberCount: memberCount,
      currentUserRole: currentUserRole,
      currentUserId: currentUserId,
      projectCount: projectCount,
      documentCount: documentCount,
    );
  }

  factory OrganizationModel.fromEntity(Organization entity) {
    return OrganizationModel(
      id: entity.id,
      name: entity.name,
      slug: entity.slug,
      description: entity.description,
      logoUrl: entity.logoUrl,
      settings: entity.settings,
      isActive: entity.isActive,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      memberCount: entity.memberCount,
      currentUserRole: entity.currentUserRole,
      currentUserId: entity.currentUserId,
      projectCount: entity.projectCount,
      documentCount: entity.documentCount,
    );
  }
}