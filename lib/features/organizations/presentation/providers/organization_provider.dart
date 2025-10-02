import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/storage/secure_storage_factory.dart';
import '../../data/models/organization_model.dart';
import '../../data/models/create_organization_request.dart';
import '../../data/services/organization_api_service.dart';
import '../../domain/entities/organization.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

part 'organization_provider.g.dart';

// Simple state notifier to track organization changes
final organizationChangedProvider = StateNotifierProvider<OrganizationChangedNotifier, int>((ref) {
  return OrganizationChangedNotifier();
});

class OrganizationChangedNotifier extends StateNotifier<int> {
  OrganizationChangedNotifier() : super(0);

  void trigger() {
    state = state + 1;
  }
}

// Provider for the API service
final organizationApiServiceProvider = Provider<OrganizationApiService>((ref) {
  final dio = DioClient.instance;
  return OrganizationApiService(dio);
});

// Provider for secure storage
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorageFactory.create();
});

// State for current organization with enhanced functionality
@riverpod
class CurrentOrganization extends _$CurrentOrganization {
  static const String _storageKey = 'current_organization_id';

  @override
  Future<Organization?> build() async {
    // Watch auth state to refresh on user changes
    final user = await ref.watch(authControllerProvider.future);

    if (user == null) {
      // Clear stored organization if user is not authenticated
      final storage = ref.read(secureStorageProvider);
      await storage.delete(_storageKey);
      return null;
    }

    // Try to load the last active organization
    final storage = ref.read(secureStorageProvider);
    final storedOrgId = await storage.read(_storageKey);

    if (storedOrgId != null) {
      try {
        final apiService = ref.read(organizationApiServiceProvider);
        final organizationModel = await apiService.getOrganization(storedOrgId);
        return organizationModel.toEntity();
      } catch (e) {
        // Only clear storage if the organization is truly invalid (404)
        if (e is DioException) {
          final statusCode = e.response?.statusCode;

          if (statusCode == 404) {
            // Organization doesn't exist, clear it
            await storage.delete(_storageKey);
          } else if (statusCode == 401 || statusCode == 403) {
            // Authentication issue, don't clear organization
            // Let the error propagate for auth handling
            rethrow;
          } else {
            // Server error or network issue
            // Keep the organization in storage and show error state
            // Return the stored org ID with error state
            state = AsyncValue.error(e, StackTrace.current);
            // Return null to indicate error but don't clear storage
            return null;
          }
        } else {
          // Unknown error type, keep organization and propagate error
          state = AsyncValue.error(e, StackTrace.current);
          return null;
        }
      }
    }

    // If no stored organization, try to get the first available organization
    try {
      final organizations = await ref.read(userOrganizationsProvider.future);
      if (organizations.isNotEmpty) {
        final firstOrg = organizations.first;
        await setOrganization(firstOrg);
        return firstOrg;
      }
    } catch (e) {
      // Handle errors when fetching organizations
      if (e is DioException) {
        final statusCode = e.response?.statusCode;

        if (statusCode == 401 || statusCode == 403) {
          // Authentication issue
          rethrow;
        } else if (statusCode != 404) {
          // Server or network error, set error state
          state = AsyncValue.error(e, StackTrace.current);
          return null;
        }
      }
      // If it's a 404 or other expected error, just return null
      // (user has no organizations)
    }

    return null;
  }

  Future<void> setOrganization(Organization organization) async {
    state = AsyncValue.data(organization);

    // Persist the selection
    final storage = ref.read(secureStorageProvider);
    await storage.write(_storageKey, organization.id);
  }

  Future<void> switchOrganization(String organizationId) async {
    state = const AsyncValue.loading();
    try {
      final apiService = ref.read(organizationApiServiceProvider);

      // Call backend to switch organization context
      await apiService.switchOrganization(organizationId);

      // Get the organization details
      final organizationModel = await apiService.getOrganization(organizationId);
      final organization = organizationModel.toEntity();

      // Update state
      state = AsyncValue.data(organization);

      // Persist the selection
      final storage = ref.read(secureStorageProvider);
      await storage.write(_storageKey, organizationId);

      // Invalidate all data providers to refresh with new organization context
      _invalidateOrganizationDependentData();

      // Also refresh user organizations list to ensure consistency
      ref.invalidate(userOrganizationsProvider);

    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      // Re-throw to let UI handle the error
      rethrow;
    }
  }

  Future<void> clearOrganization() async {
    state = const AsyncValue.data(null);

    // Clear from storage
    final storage = ref.read(secureStorageProvider);
    await storage.delete(_storageKey);

    // Invalidate all data providers
    _invalidateOrganizationDependentData();
  }

  void _invalidateOrganizationDependentData() {
    // Invalidate all providers that depend on organization context
    // This will force them to refetch data with the new organization

    // Reset the Dio client to ensure interceptors pick up new organization
    DioClient.reset();

    // Don't invalidate apiClientProvider here as it already watches currentOrganizationProvider
    // and will automatically rebuild when this provider changes
    // ref.invalidate(apiClientProvider); // REMOVED to prevent circular dependency

    // Trigger a global refresh event that other providers can listen to
    // This event-based approach prevents circular dependencies
    ref.read(organizationChangedProvider.notifier).trigger();
  }
}

// Provider for user's organizations list
@riverpod
class UserOrganizations extends _$UserOrganizations {
  @override
  Future<List<Organization>> build() async {
    try {
      final apiService = ref.read(organizationApiServiceProvider);
      final response = await apiService.listUserOrganizations();

      // Handle the dynamic response
      if (response is Map<String, dynamic>) {
        final organizations = response['organizations'] as List<dynamic>?;
        if (organizations != null) {
          return organizations
              .map((json) => OrganizationModel.fromJson(json as Map<String, dynamic>))
              .map((model) => model.toEntity())
              .toList();
        }
      }

      return [];
    } catch (error) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// Controller for creating organizations
@riverpod
class CreateOrganizationController extends _$CreateOrganizationController {
  @override
  Future<void> build() async {}

  Future<Organization> createOrganization(CreateOrganizationRequest request) async {
    state = const AsyncValue.loading();
    try {
      final apiService = ref.read(organizationApiServiceProvider);
      final organizationModel = await apiService.createOrganization(request);

      // Refresh the user's organizations list
      await ref.read(userOrganizationsProvider.notifier).refresh();

      // Set as current organization
      final organization = organizationModel.toEntity();
      await ref.read(currentOrganizationProvider.notifier).setOrganization(organization);

      state = const AsyncValue.data(null);
      return organization;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

// State for wizard progress
class OrganizationWizardState {
  final int currentStep;
  final String? name;
  final String? description;
  final String? timezone;
  final String? locale;
  final Map<String, dynamic> integrationSettings;
  final List<String> invitedEmails;

  const OrganizationWizardState({
    this.currentStep = 0,
    this.name,
    this.description,
    this.timezone = 'UTC',
    this.locale = 'en_US',
    this.integrationSettings = const {},
    this.invitedEmails = const [],
  });

  OrganizationWizardState copyWith({
    int? currentStep,
    String? name,
    String? description,
    String? timezone,
    String? locale,
    Map<String, dynamic>? integrationSettings,
    List<String>? invitedEmails,
  }) {
    return OrganizationWizardState(
      currentStep: currentStep ?? this.currentStep,
      name: name ?? this.name,
      description: description ?? this.description,
      timezone: timezone ?? this.timezone,
      locale: locale ?? this.locale,
      integrationSettings: integrationSettings ?? this.integrationSettings,
      invitedEmails: invitedEmails ?? this.invitedEmails,
    );
  }
}

// Provider for wizard state
@riverpod
class OrganizationWizard extends _$OrganizationWizard {
  @override
  OrganizationWizardState build() {
    return const OrganizationWizardState();
  }

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  void updateTimezone(String timezone) {
    state = state.copyWith(timezone: timezone);
  }

  void updateLocale(String locale) {
    state = state.copyWith(locale: locale);
  }

  void updateIntegrationSettings(Map<String, dynamic> settings) {
    state = state.copyWith(integrationSettings: settings);
  }

  void addInvitedEmail(String email) {
    state = state.copyWith(
      invitedEmails: [...state.invitedEmails, email],
    );
  }

  void removeInvitedEmail(String email) {
    state = state.copyWith(
      invitedEmails: state.invitedEmails.where((e) => e != email).toList(),
    );
  }

  void nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 3) {
      state = state.copyWith(currentStep: step);
    }
  }

  void reset() {
    state = const OrganizationWizardState();
  }

  CreateOrganizationRequest buildRequest() {
    return CreateOrganizationRequest(
      name: state.name ?? '',
      description: state.description,
      settings: {
        'timezone': state.timezone,
        'locale': state.locale,
        ...state.integrationSettings,
      },
    );
  }
}