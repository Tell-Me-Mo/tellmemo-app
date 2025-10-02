import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/features/organizations/data/models/organization_member.dart';
import 'package:pm_master_v2/features/organizations/data/services/organization_api_service.dart';
import 'package:pm_master_v2/features/organizations/presentation/providers/organization_provider.dart';

final membersProvider = StateNotifierProvider.family<MembersNotifier, AsyncValue<List<OrganizationMember>>, String>((ref, organizationId) {
  final apiService = ref.watch(organizationApiServiceProvider);
  return MembersNotifier(apiService, organizationId);
});

class MembersNotifier extends StateNotifier<AsyncValue<List<OrganizationMember>>> {
  final OrganizationApiService _apiService;
  final String _organizationId;

  MembersNotifier(this._apiService, this._organizationId) : super(const AsyncValue.loading()) {
    loadMembers();
  }

  Future<void> loadMembers() async {
    try {
      state = const AsyncValue.loading();
      final response = await _apiService.getOrganizationMembers(_organizationId);

      final members = (response['members'] as List)
          .map((json) => OrganizationMember.fromJson(json))
          .toList();

      state = AsyncValue.data(members);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeMember(String userId) async {
    try {
      await _apiService.removeOrganizationMember(_organizationId, userId);
      await loadMembers();
    } catch (e) {
      // Handle error
      throw e;
    }
  }

  Future<void> removeMembersInBatch(List<String> userIds) async {
    try {
      for (final userId in userIds) {
        await _apiService.removeOrganizationMember(_organizationId, userId);
      }
      await loadMembers();
    } catch (e) {
      // Handle error
      throw e;
    }
  }

  Future<void> updateMemberRole(String userId, String role) async {
    try {
      await _apiService.updateOrganizationMemberRole(_organizationId, userId, {'role': role});
      await loadMembers();
    } catch (e) {
      // Handle error
      throw e;
    }
  }

  Future<void> resendInvitation(String email) async {
    try {
      await _apiService.resendInvitation(_organizationId, {'email': email});
      // Optionally show success message
    } catch (e) {
      // Handle error
      throw e;
    }
  }
}