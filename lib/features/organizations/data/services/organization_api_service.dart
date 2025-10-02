import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/organization_model.dart';
import '../models/create_organization_request.dart';

part 'organization_api_service.g.dart';

@RestApi()
abstract class OrganizationApiService {
  factory OrganizationApiService(Dio dio, {String? baseUrl}) = _OrganizationApiService;

  @POST('/api/v1/organizations')
  Future<OrganizationModel> createOrganization(
    @Body() CreateOrganizationRequest request,
  );

  @GET('/api/v1/organizations')
  Future<dynamic> listUserOrganizations({
    @Query('include_inactive') bool includeInactive = false,
  });

  @GET('/api/v1/organizations/{id}')
  Future<OrganizationModel> getOrganization(@Path('id') String organizationId);

  @PUT('/api/v1/organizations/{id}')
  Future<OrganizationModel> updateOrganization(
    @Path('id') String organizationId,
    @Body() Map<String, dynamic> request,
  );

  @DELETE('/api/v1/organizations/{id}')
  Future<void> deleteOrganization(@Path('id') String organizationId);

  @POST('/api/v1/organizations/{id}/switch')
  Future<dynamic> switchOrganization(@Path('id') String organizationId);

  @GET('/api/v1/organizations/{id}/members')
  Future<dynamic> listOrganizationMembers(@Path('id') String organizationId);

  @POST('/api/v1/organizations/{id}/members/invite')
  Future<dynamic> inviteMember(
    @Path('id') String organizationId,
    @Body() Map<String, dynamic> invitation,
  );

  @GET('/api/v1/organizations/{id}/invitations')
  Future<dynamic> listPendingInvitations(@Path('id') String organizationId);

  @GET('/api/v1/organizations/{id}/members')
  Future<dynamic> getOrganizationMembers(@Path('id') String organizationId);

  @DELETE('/api/v1/organizations/{id}/members/{userId}')
  Future<void> removeOrganizationMember(
    @Path('id') String organizationId,
    @Path('userId') String userId,
  );

  @PUT('/api/v1/organizations/{id}/members/{userId}')
  Future<void> updateOrganizationMemberRole(
    @Path('id') String organizationId,
    @Path('userId') String userId,
    @Body() Map<String, dynamic> roleUpdate,
  );

  @POST('/api/v1/organizations/{id}/members/resend-invitation')
  Future<void> resendInvitation(
    @Path('id') String organizationId,
    @Body() Map<String, dynamic> request,
  );

  @POST('/api/v1/organizations/{id}/members/invite')
  Future<dynamic> inviteToOrganization(
    @Path('id') String organizationId,
    @Body() Map<String, dynamic> invitation,
  );
}