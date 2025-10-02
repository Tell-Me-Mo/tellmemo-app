import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/dio_client.dart';
import '../../features/organizations/presentation/providers/organization_provider.dart';

part 'api_client_provider.g.dart';

@riverpod
ApiClient apiClient(Ref ref) {
  // Watch current organization to invalidate API client when organization changes
  ref.watch(currentOrganizationProvider);

  return ApiClient(DioClient.instance);
}