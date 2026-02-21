import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/services/organization_api_service.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../hierarchy/presentation/providers/hierarchy_providers.dart';
import 'organization_provider.dart';

part 'demo_data_provider.g.dart';

@riverpod
class DemoData extends _$DemoData {
  @override
  Future<bool> build() async {
    final org = await ref.watch(currentOrganizationProvider.future);
    if (org == null) return false;
    return org.hasDemoData;
  }

  Future<void> clearDemoData() async {
    final org = await ref.read(currentOrganizationProvider.future);
    if (org == null) return;

    state = const AsyncValue.loading();
    try {
      final apiService = ref.read(organizationApiServiceProvider);
      await apiService.clearDemoData(org.id);

      // Invalidate all data providers to refresh without demo data
      ref.invalidate(currentOrganizationProvider);
      ref.invalidate(projectsListProvider);
      ref.invalidate(hierarchyStateProvider);
      ref.read(organizationChangedProvider.notifier).trigger();

      state = const AsyncValue.data(false);
    } catch (error, _) {
      // Restore to true — demo data was NOT removed
      state = const AsyncValue.data(true);
      rethrow;
    }
  }
}
