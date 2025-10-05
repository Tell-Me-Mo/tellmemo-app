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
import 'package:pm_master_v2/features/hierarchy/domain/entities/portfolio.dart';
import 'package:pm_master_v2/features/hierarchy/domain/entities/program.dart';
import 'package:pm_master_v2/features/hierarchy/domain/entities/hierarchy_item.dart';
import 'package:pm_master_v2/features/hierarchy/presentation/providers/hierarchy_providers.dart';

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
  final Map<String, dynamic> Function(String, Map<String, dynamic>)? _onUpdate;
  final Function(String)? _onDelete;
  final Function(String)? _onArchive;
  final Function(String)? _onRestore;
  final Future<Project> Function({
    required String name,
    required String description,
    required String createdBy,
    String? portfolioId,
    String? programId,
  })? _onCreate;

  MockProjectsList({
    List<Project> projects = const [],
    Object? error,
    Map<String, dynamic> Function(String, Map<String, dynamic>)? onUpdate,
    Function(String)? onDelete,
    Function(String)? onArchive,
    Function(String)? onRestore,
    Future<Project> Function({
      required String name,
      required String description,
      required String createdBy,
      String? portfolioId,
      String? programId,
    })? onCreate,
  })  : _projects = projects,
        _error = error,
        _onUpdate = onUpdate,
        _onDelete = onDelete,
        _onArchive = onArchive,
        _onRestore = onRestore,
        _onCreate = onCreate;

  @override
  Future<List<Project>> build() async {
    if (_error != null) {
      throw _error!;
    }
    return _projects;
  }

  @override
  Future<void> updateProject(String id, Map<String, dynamic> updates) async {
    if (_onUpdate != null) {
      _onUpdate!(id, updates);
    }
    // Don't call super to avoid actual API call
  }

  @override
  Future<void> deleteProject(String id) async {
    if (_onDelete != null) {
      _onDelete!(id);
    }
    // Don't call super to avoid actual API call
  }

  @override
  Future<void> archiveProject(String id) async {
    if (_onArchive != null) {
      _onArchive!(id);
    }
    // Don't call super to avoid actual API call
  }

  @override
  Future<void> restoreProject(String id) async {
    if (_onRestore != null) {
      _onRestore!(id);
    }
    // Don't call super to avoid actual API call
  }

  @override
  Future<Project> createProject({
    required String name,
    required String description,
    required String createdBy,
    String? portfolioId,
    String? programId,
  }) async {
    if (_onCreate != null) {
      return _onCreate!(
        name: name,
        description: description,
        createdBy: createdBy,
        portfolioId: portfolioId,
        programId: programId,
      );
    }
    // Default mock project
    return Project(
      id: 'new-project-id',
      name: name,
      description: description,
      status: ProjectStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: createdBy,
      portfolioId: portfolioId,
      programId: programId,
    );
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
Override createProjectsListOverride({
  List<Project> projects = const [],
  Object? error,
  Map<String, dynamic> Function(String, Map<String, dynamic>)? onUpdate,
  Function(String)? onDelete,
  Function(String)? onArchive,
  Function(String)? onRestore,
  Future<Project> Function({
    required String name,
    required String description,
    required String createdBy,
    String? portfolioId,
    String? programId,
  })? onCreate,
}) {
  return projectsListProvider.overrideWith(() {
    return MockProjectsList(
      projects: projects,
      error: error,
      onUpdate: onUpdate,
      onDelete: onDelete,
      onArchive: onArchive,
      onRestore: onRestore,
      onCreate: onCreate,
    );
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

/// Mock PortfolioList notifier for testing
class MockPortfolioList extends PortfolioList {
  final List<Portfolio> _portfolios;
  final Object? _error;
  final Future<Portfolio> Function({required String name, String? description})? _onCreate;
  final Future<Portfolio> Function({
    required String portfolioId,
    String? name,
    String? description,
  })? _onUpdate;
  final Future<void> Function({required String portfolioId, bool cascadeDelete})? _onDelete;

  MockPortfolioList({
    List<Portfolio> portfolios = const [],
    Object? error,
    Future<Portfolio> Function({required String name, String? description})? onCreate,
    Future<Portfolio> Function({
      required String portfolioId,
      String? name,
      String? description,
    })? onUpdate,
    Future<void> Function({required String portfolioId, bool cascadeDelete})? onDelete,
  })  : _portfolios = portfolios,
        _error = error,
        _onCreate = onCreate,
        _onUpdate = onUpdate,
        _onDelete = onDelete;

  @override
  Future<List<Portfolio>> build() async {
    if (_error != null) {
      throw _error!;
    }
    return _portfolios;
  }

  @override
  Future<Portfolio> createPortfolio({required String name, String? description}) async {
    if (_onCreate != null) {
      return _onCreate!(name: name, description: description);
    }
    // Default mock portfolio
    return Portfolio(
      id: 'new-portfolio-id',
      name: name,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Portfolio> updatePortfolio({
    required String portfolioId,
    String? name,
    String? description,
    String? owner,
    HealthStatus? healthStatus,
    String? riskSummary,
  }) async {
    if (_onUpdate != null) {
      return _onUpdate!(portfolioId: portfolioId, name: name, description: description);
    }
    // Default mock portfolio
    final existing = _portfolios.firstWhere((p) => p.id == portfolioId);
    return existing.copyWith(
      name: name ?? existing.name,
      description: description ?? existing.description,
    );
  }

  @override
  Future<void> deletePortfolio({required String portfolioId, bool cascadeDelete = false}) async {
    if (_onDelete != null) {
      return _onDelete!(portfolioId: portfolioId, cascadeDelete: cascadeDelete);
    }
  }
}

/// Mock ProgramList notifier for testing
class MockProgramList extends ProgramList {
  final List<Program> _programs;
  final Object? _error;
  final Future<Program> Function({
    required String name,
    String? portfolioId,
    String? description,
  })? _onCreate;
  final Future<Program> Function({
    required String programId,
    String? name,
    String? description,
    String? portfolioId,
  })? _onUpdate;
  final Future<void> Function({
    required String programId,
    bool cascadeDelete,
    String? portfolioId,
  })? _onDelete;

  MockProgramList({
    List<Program> programs = const [],
    Object? error,
    Future<Program> Function({
      required String name,
      String? portfolioId,
      String? description,
    })? onCreate,
    Future<Program> Function({
      required String programId,
      String? name,
      String? description,
      String? portfolioId,
    })? onUpdate,
    Future<void> Function({
      required String programId,
      bool cascadeDelete,
      String? portfolioId,
    })? onDelete,
  })  : _programs = programs,
        _error = error,
        _onCreate = onCreate,
        _onUpdate = onUpdate,
        _onDelete = onDelete;

  @override
  Future<List<Program>> build({String? portfolioId}) async {
    if (_error != null) {
      throw _error!;
    }
    // Filter by portfolioId if provided
    if (portfolioId != null) {
      return _programs.where((p) => p.portfolioId == portfolioId).toList();
    }
    return _programs;
  }

  @override
  Future<Program> createProgram({
    required String name,
    String? portfolioId,
    String? description,
  }) async {
    if (_onCreate != null) {
      return _onCreate!(name: name, portfolioId: portfolioId, description: description);
    }
    // Default mock program
    return Program(
      id: 'new-program-id',
      name: name,
      description: description,
      portfolioId: portfolioId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Program> updateProgram({
    required String programId,
    String? name,
    String? description,
    String? portfolioId,
  }) async {
    if (_onUpdate != null) {
      return _onUpdate!(
        programId: programId,
        name: name,
        description: description,
        portfolioId: portfolioId,
      );
    }
    // Default mock program
    final existing = _programs.firstWhere((p) => p.id == programId);
    return existing.copyWith(
      name: name ?? existing.name,
      description: description ?? existing.description,
      portfolioId: portfolioId ?? existing.portfolioId,
    );
  }

  @override
  Future<void> deleteProgram({
    required String programId,
    bool cascadeDelete = false,
    String? portfolioId,
  }) async {
    if (_onDelete != null) {
      return _onDelete!(
        programId: programId,
        cascadeDelete: cascadeDelete,
        portfolioId: portfolioId,
      );
    }
  }
}

/// Helper function to create portfolio list provider override
Override createPortfolioListOverride({
  List<Portfolio> portfolios = const [],
  Object? error,
  Future<Portfolio> Function({required String name, String? description})? onCreate,
  Future<Portfolio> Function({
    required String portfolioId,
    String? name,
    String? description,
  })? onUpdate,
  Future<void> Function({required String portfolioId, bool cascadeDelete})? onDelete,
}) {
  return portfolioListProvider.overrideWith(() {
    return MockPortfolioList(
      portfolios: portfolios,
      error: error,
      onCreate: onCreate,
      onUpdate: onUpdate,
      onDelete: onDelete,
    );
  });
}

/// Helper function to create program list provider override
Override createProgramListOverride({
  List<Program> programs = const [],
  Object? error,
  String? portfolioId,
  Future<Program> Function({
    required String name,
    String? portfolioId,
    String? description,
  })? onCreate,
  Future<Program> Function({
    required String programId,
    String? name,
    String? description,
    String? portfolioId,
  })? onUpdate,
  Future<void> Function({
    required String programId,
    bool cascadeDelete,
    String? portfolioId,
  })? onDelete,
}) {
  return programListProvider(portfolioId: portfolioId).overrideWith(() {
    return MockProgramList(
      programs: programs,
      error: error,
      onCreate: onCreate,
      onUpdate: onUpdate,
      onDelete: onDelete,
    );
  });
}

/// Mock Program provider for testing individual programs
class MockProgramProvider {
  final Program? program;
  final Object? error;

  MockProgramProvider({this.program, this.error});

  Future<Program?> call() async {
    if (error != null) {
      throw error!;
    }
    return program;
  }
}

/// Helper function to create program provider override (single program)
Override createProgramOverride(String programId, {Program? program, Object? error}) {
  return programProvider(programId).overrideWith((ref) async {
    if (error != null) {
      throw error;
    }
    return program;
  });
}

/// Helper function to create portfolio provider override (single portfolio)
Override createPortfolioOverride(String portfolioId, {Portfolio? portfolio, Object? error}) {
  return portfolioProvider(portfolioId).overrideWith((ref) async {
    if (error != null) {
      throw error;
    }
    return portfolio;
  });
}

/// Mock HierarchyState notifier for testing
class MockHierarchyState extends HierarchyState {
  final List<HierarchyItem> _items;
  final Object? _error;

  MockHierarchyState({List<HierarchyItem> items = const [], Object? error})
      : _items = items,
        _error = error;

  @override
  Future<List<HierarchyItem>> build({bool includeArchived = false}) async {
    if (_error != null) {
      throw _error!;
    }
    return _items;
  }
}

/// Helper function to create hierarchy state provider override
Override createHierarchyStateOverride({
  List<HierarchyItem> items = const [],
  Object? error,
}) {
  return hierarchyStateProvider().overrideWith(() {
    return MockHierarchyState(items: items, error: error);
  });
}
