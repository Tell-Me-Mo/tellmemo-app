import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/organization_model.dart';
import 'organization_provider.dart';

part 'organization_settings_provider.g.dart';

@riverpod
Future<OrganizationModel> updateOrganizationSettings(
  Ref ref, {
  required String organizationId,
  required Map<String, dynamic> settings,
}) async {
  final apiService = ref.read(organizationApiServiceProvider);
  final updatedOrganization = await apiService.updateOrganization(
    organizationId,
    settings,
  );

  await ref.read(currentOrganizationProvider.notifier).setOrganization(
    updatedOrganization.toEntity(),
  );

  await ref.read(userOrganizationsProvider.notifier).refresh();

  return updatedOrganization;
}

@riverpod
Future<void> deleteOrganization(
  Ref ref,
  String organizationId,
) async {
  final apiService = ref.read(organizationApiServiceProvider);
  await apiService.deleteOrganization(organizationId);

  await ref.read(userOrganizationsProvider.notifier).refresh();

  // Clear the current organization after deletion
  ref.invalidate(currentOrganizationProvider);
}