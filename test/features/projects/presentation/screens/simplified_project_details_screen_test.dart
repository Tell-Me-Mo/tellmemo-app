import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/features/projects/presentation/screens/simplified_project_details_screen.dart';
import 'package:pm_master_v2/features/projects/domain/entities/project.dart';
import 'package:pm_master_v2/features/projects/presentation/providers/projects_provider.dart';
import 'package:pm_master_v2/features/meetings/presentation/providers/meetings_provider.dart';
import 'package:pm_master_v2/features/meetings/domain/entities/content.dart';
import 'package:pm_master_v2/features/summaries/presentation/providers/summary_provider.dart';
import 'package:pm_master_v2/features/summaries/data/models/summary_model.dart';
import 'package:pm_master_v2/features/content/presentation/providers/new_items_provider.dart';
import 'package:pm_master_v2/features/jobs/presentation/providers/job_websocket_provider.dart';
import 'package:pm_master_v2/features/jobs/domain/models/job_model.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late Project testProject;

  setUp(() {
    testProject = Project(
      id: 'project-1',
      name: 'Test Project',
      description: 'Test description for project',
      status: ProjectStatus.active,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 5),
      createdBy: 'test@example.com',
      memberCount: 5,
    );
  });

  // Helper to create minimal overrides for the screen
  List<Override> createMinimalOverrides({
    Project? project,
    Object? projectError,
  }) {
    return [
      // Project detail provider (family provider)
      projectDetailProvider(testProject.id).overrideWith(() {
        return MockProjectDetail(project: project, error: projectError);
      }),

      // Selected project state
      selectedProjectProvider.overrideWith((ref) => project),

      // Meetings list (empty for basic tests)
      meetingsListProvider.overrideWith((ref) async => <Content>[]),

      // Project summaries (StateNotifierProvider - use mock)
      projectSummariesProvider(testProject.id).overrideWith((ref) {
        return MockProjectSummariesNotifier();
      }),

      // Meetings statistics
      meetingsStatisticsProvider.overrideWith((ref) async => {
        'total': 0,
        'meetings': 0,
        'emails': 0,
        'processed': 0,
        'processing': 0,
        'errors': 0,
      }),

      // New items provider
      newItemsProvider.overrideWith(() => MockNewItems()),

      // WebSocket job tracker
      webSocketActiveJobsTrackerProvider.overrideWith(() => MockWebSocketJobsTracker()),
    ];
  }

  group('SimplifiedProjectDetailsScreen', () {
    testWidgets('displays error message when project fails to load', (tester) async {
      await pumpWidgetWithProviders(
        tester,
        const SimplifiedProjectDetailsScreen(projectId: 'project-1'),
        overrides: createMinimalOverrides(
          projectError: Exception('Network error'),
        ),
      );

      // Should show error message
      expect(find.textContaining('Error loading project'), findsOneWidget);
      expect(find.textContaining('Network error'), findsOneWidget);
    });

    testWidgets('displays "Project not found" when project is null', (tester) async {
      await pumpWidgetWithProviders(
        tester,
        const SimplifiedProjectDetailsScreen(projectId: 'project-1'),
        overrides: createMinimalOverrides(project: null),
      );

      // Should show "Project not found" message
      expect(find.text('Project not found'), findsOneWidget);
    });

    // Note: Full UI rendering tests (project details, tabs, content) are not included
    // due to the screen's complexity (4513 lines) and extensive dependencies on:
    // - contentAvailabilityService (singleton, needs DioClient mock)
    // - Multiple providers for meetings, summaries, activities, risks, tasks
    // - WebSocket job updates integration
    // - Complex tab system with conditional rendering
    // Comprehensive testing would require significant mock infrastructure setup
    // that is beyond the scope of basic widget testing.
  });
}

// Mock classes for testing

class MockProjectDetail extends ProjectDetail {
  final Project? _project;
  final Object? _error;

  MockProjectDetail({Project? project, Object? error})
      : _project = project,
        _error = error,
        super();

  @override
  Future<Project?> build(String projectId) async {
    if (_error != null) throw _error!;
    return _project;
  }
}

class MockProjectSummariesNotifier extends ProjectSummariesNotifier {
  MockProjectSummariesNotifier() : super(null as dynamic, '');

  @override
  AsyncValue<List<SummaryModel>> build(String projectId) {
    return const AsyncValue.data([]);
  }
}

class MockWebSocketJobsTracker extends WebSocketActiveJobsTracker {
  @override
  Future<List<JobModel>> build() async => [];

  @override
  Future<void> subscribeToProject(String projectId) async {
    // No-op for testing
  }

  @override
  void unsubscribeFromProject(String projectId) {
    // No-op for testing
  }

  @override
  bool isJobActive(String jobId) => false;
}

class MockNewItems extends NewItems {
  @override
  Map<String, NewItemEntry> build() => {};
}
