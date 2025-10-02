import 'package:freezed_annotation/freezed_annotation.dart';

part 'organization_member.freezed.dart';
part 'organization_member.g.dart';

@freezed
class OrganizationMember with _$OrganizationMember {
  const factory OrganizationMember({
    required String organizationId,
    required String userId,
    required String userEmail,
    required String userName,
    String? userAvatarUrl,
    required String role,
    @Default('active') String status,
    String? invitedBy,
    DateTime? joinedAt,
    DateTime? invitedAt,
    DateTime? lastActiveAt,
  }) = _OrganizationMember;

  factory OrganizationMember.fromJson(Map<String, dynamic> json) =>
      _$OrganizationMemberFromJson(json);
}