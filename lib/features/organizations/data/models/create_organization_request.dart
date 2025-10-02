import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_organization_request.freezed.dart';
part 'create_organization_request.g.dart';

@freezed
class CreateOrganizationRequest with _$CreateOrganizationRequest {
  const factory CreateOrganizationRequest({
    required String name,
    String? slug,
    String? description,
    @JsonKey(name: 'logo_url') String? logoUrl,
    @Default({}) Map<String, dynamic> settings,
  }) = _CreateOrganizationRequest;

  factory CreateOrganizationRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateOrganizationRequestFromJson(json);
}