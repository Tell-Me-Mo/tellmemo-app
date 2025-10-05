import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/features/organizations/domain/entities/organization.dart';
import 'package:pm_master_v2/features/organizations/data/models/organization_member.dart';
import 'package:pm_master_v2/features/organizations/data/models/organization_model.dart';
import 'package:pm_master_v2/features/organizations/data/models/create_organization_request.dart';
import 'package:pm_master_v2/features/organizations/data/services/organization_api_service.dart';
import 'package:pm_master_v2/features/organizations/presentation/providers/organization_provider.dart';
import 'package:pm_master_v2/features/organizations/presentation/providers/members_provider.dart';
import 'package:pm_master_v2/features/projects/domain/entities/project.dart';
import 'package:pm_master_v2/features/projects/presentation/providers/projects_provider.dart';
import 'package:pm_master_v2/features/documents/presentation/providers/documents_provider.dart';

/// Simple mock API service for testing - implements interface with noSuchMethod
class _MockOrganizationApiService implements OrganizationApiService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('Mock should not call API');
}

/// Mock CurrentOrganization notifier for testing
class MockCurrentOrganization extends CurrentOrganization {
  final Organization? _organization;
  final Object? _error;

  MockCurrentOrganization({Organization? organization, Object? error})
      : _organization = organization,
        _error = error;

  @override
  Future<Organization?> build() async {
    if (_error != null) {
      throw _error!;
    }
    return _organization;
  }
}

/// Mock UserOrganizations notifier for testing
class MockUserOrganizations extends UserOrganizations {
  final List<Organization> _organizations;
  final Object? _error;

  MockUserOrganizations({List<Organization> organizations = const [], Object? error})
      : _organizations = organizations,
        _error = error;

  @override
  Future<List<Organization>> build() async {
    if (_error != null) {
      throw _error!;
    }
    return _organizations;
  }
}

/// Mock ProjectsList notifier for testing
class MockProjectsList extends ProjectsList {
  final List<Project> _projects;
  final Object? _error;

  MockProjectsList({List<Project> projects = const [], Object? error})
      : _projects = projects,
        _error = error;

  @override
  Future<List<Project>> build() async {
    if (_error != null) {
      throw _error!;
    }
    return _projects;
  }
}

/// Mock MembersNotifier for testing - doesn't call API
class MockMembersNotifier extends MembersNotifier {
  final List<OrganizationMember> _members;

  MockMembersNotifier(this._members, String organizationId)
      : super(_MockOrganizationApiService(), organizationId);

  @override
  Future<void> loadMembers() async {
    // Don't call API, just set the state with provided members
    state = AsyncValue.data(_members);
  }
}

/// Helper function to create organization provider override
Override createCurrentOrganizationOverride({Organization? organization, Object? error}) {
  return currentOrganizationProvider.overrideWith(() {
    return MockCurrentOrganization(organization: organization, error: error);
  });
}

/// Helper function to create user organizations provider override
Override createUserOrganizationsOverride({List<Organization> organizations = const [], Object? error}) {
  return userOrganizationsProvider.overrideWith(() {
    return MockUserOrganizations(organizations: organizations, error: error);
  });
}

/// Helper function to create projects list provider override
Override createProjectsListOverride({List<Project> projects = const [], Object? error}) {
  return projectsListProvider.overrideWith(() {
    return MockProjectsList(projects: projects, error: error);
  });
}

/// Helper function to create members provider override
Override createMembersProviderOverride(String organizationId, List<OrganizationMember> members) {
  return membersProvider(organizationId).overrideWith((ref) {
    return MockMembersNotifier(members, organizationId);
  });
}

/// Helper function to create documents statistics provider override
Override createDocumentsStatisticsOverride({Map<String, int> stats = const {}}) {
  return documentsStatisticsProvider.overrideWith((ref) async => stats);
}

/// Helper to create loading state for current organization
Override createCurrentOrganizationLoadingOverride() {
  return currentOrganizationProvider.overrideWith(() {
    return MockCurrentOrganization(organization: null);
  });
}

/// Helper to create error state for current organization
Override createCurrentOrganizationErrorOverride(Object error) {
  return currentOrganizationProvider.overrideWith(() {
    return MockCurrentOrganization(error: error);
  });
}

/// Helper to create loading state for members
Override createMembersLoadingOverride(String organizationId) {
  return membersProvider(organizationId).overrideWith((ref) {
    final notifier = MockMembersNotifier([], organizationId);
    notifier.state = const AsyncValue.loading();
    return notifier;
  });
}

/// Helper to create error state for members
Override createMembersErrorOverride(String organizationId, Object error) {
  return membersProvider(organizationId).overrideWith((ref) {
    final notifier = MockMembersNotifier([], organizationId);
    notifier.state = AsyncValue.error(error, StackTrace.empty);
    return notifier;
  });
}
