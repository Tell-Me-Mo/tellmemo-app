import 'package:mockito/annotations.dart';
import 'package:pm_master_v2/features/auth/domain/auth_interface.dart';
import 'package:pm_master_v2/features/organizations/data/services/organization_api_service.dart';
import 'package:pm_master_v2/core/storage/secure_storage.dart';

// This file is used to generate mocks using build_runner
// Run: flutter pub run build_runner build --delete-conflicting-outputs

@GenerateMocks([
  AuthInterface,
  OrganizationApiService,
  SecureStorage,
])
void main() {}
