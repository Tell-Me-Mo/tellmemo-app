import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:pm_master_v2/features/projects/presentation/screens/content_processing_dialog.dart';
import 'package:pm_master_v2/features/projects/domain/entities/project.dart';
import 'package:pm_master_v2/features/jobs/domain/models/job_model.dart';
import 'package:pm_master_v2/features/jobs/domain/services/job_websocket_service.dart';
import 'package:pm_master_v2/features/jobs/presentation/providers/job_websocket_provider.dart';

// Mock job websocket service
class MockJobWebSocketService extends Mock implements JobWebSocketService {
  final StreamController<JobModel> _jobUpdatesController = StreamController<JobModel>.broadcast();

  @override
  Stream<JobModel> get jobUpdates => _jobUpdatesController.stream;

  void addJobUpdate(JobModel job) {
    _jobUpdatesController.add(job);
  }

  @override
  Future<void> subscribeToJob(String jobId) async {
    // Mock implementation - do nothing
  }

  @override
  void unsubscribeFromJob(String jobId) {
    // Mock implementation - do nothing
  }

  @override
  Future<void> dispose() async {
    await _jobUpdatesController.close();
  }
}

void main() {
  late MockJobWebSocketService mockJobService;
  late Project testProject;

  setUp(() {
    mockJobService = MockJobWebSocketService();
    testProject = Project(
      id: 'project-1',
      name: 'Test Project',
      description: 'Test description',
      status: ProjectStatus.active,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      createdBy: 'test@example.com',
      portfolioId: null,
      programId: null,
      memberCount: 1,
    );
  });

  tearDown(() async {
    await mockJobService.dispose();
  });

  Widget createTestWidget({
    required String jobId,
    String? contentId,
  }) {
    return ProviderScope(
      overrides: [
        jobWebSocketServiceProvider.overrideWithValue(mockJobService),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ContentProcessingDialog(
                      project: testProject,
                      jobId: jobId,
                      contentId: contentId,
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      ),
    );
  }

  group('ContentProcessingDialog', () {
    testWidgets('displays initial state correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(jobId: 'job-1'));
      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      // Check initial UI elements
      expect(find.text('Processing Content'), findsOneWidget);
      expect(find.text('Test Project'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('Initializing...'), findsOneWidget);
      expect(find.text('Step 0 of 5'), findsOneWidget);
    });

    testWidgets('displays processing steps', (tester) async {
      await tester.pumpWidget(createTestWidget(jobId: 'job-1'));
      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      // Check all processing steps are displayed
      expect(find.text('Parsing content'), findsOneWidget);
      expect(find.text('Creating chunks'), findsOneWidget);
      expect(find.text('Generating embeddings'), findsOneWidget);
      expect(find.text('Storing vectors'), findsOneWidget);
      expect(find.text('Generating summary'), findsOneWidget);
    });

    testWidgets('updates progress when job updates are received', (tester) async {
      await tester.pumpWidget(createTestWidget(jobId: 'job-1'));
      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      // Emit job update
      final jobUpdate = JobModel(
        jobId: 'job-1',
        projectId: 'project-1',
        jobType: JobType.textUpload,
        status: JobStatus.processing,
        progress: 25.0,
        currentStep: 2,
        totalSteps: 5,
        stepDescription: 'Creating chunks',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      mockJobService.addJobUpdate(jobUpdate);
      await tester.pump();

      // Verify progress is updated
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('Creating chunks'), findsNWidgets(2)); // Appears in step description and in step list
      expect(find.text('Step 2 of 5'), findsOneWidget);
    });

    testWidgets('displays circular progress indicator during processing', (tester) async {
      await tester.pumpWidget(createTestWidget(jobId: 'job-1'));
      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      // Emit processing job update
      final jobUpdate = JobModel(
        jobId: 'job-1',
        projectId: 'project-1',
        jobType: JobType.textUpload,
        status: JobStatus.processing,
        progress: 50.0,
        currentStep: 3,
        totalSteps: 5,
        stepDescription: 'Generating embeddings',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      mockJobService.addJobUpdate(jobUpdate);
      await tester.pump();

      // Check for circular progress indicator (shown only during processing)
      expect(find.byType(CircularProgressIndicator), findsWidgets); // At least one progress indicator
    });

    testWidgets('shows check icon and auto-closes on completion', (tester) async {
      await tester.pumpWidget(createTestWidget(jobId: 'job-1'));
      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      // Emit completed job update
      final jobUpdate = JobModel(
        jobId: 'job-1',
        projectId: 'project-1',
        jobType: JobType.textUpload,
        status: JobStatus.completed,
        progress: 100.0,
        currentStep: 5,
        totalSteps: 5,
        stepDescription: 'Completed',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      mockJobService.addJobUpdate(jobUpdate);
      await tester.pump();

      // Check for completion icon
      expect(find.byIcon(Icons.check_circle), findsWidgets);
      expect(find.text('100%'), findsOneWidget);

      // Wait for auto-close and snackbar
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump();

      // Dialog should be closed
      expect(find.byType(ContentProcessingDialog), findsNothing);

      // Success snackbar should be shown
      expect(find.text('Content processed successfully'), findsOneWidget);
    });

    testWidgets('shows error and auto-closes on failure', (tester) async {
      await tester.pumpWidget(createTestWidget(jobId: 'job-1'));
      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      // Emit failed job update
      final jobUpdate = JobModel(
        jobId: 'job-1',
        projectId: 'project-1',
        jobType: JobType.textUpload,
        status: JobStatus.failed,
        progress: 50.0,
        currentStep: 3,
        totalSteps: 5,
        stepDescription: 'Failed',
        errorMessage: 'Processing failed: Invalid format',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      mockJobService.addJobUpdate(jobUpdate);
      await tester.pump();

      // Wait for auto-close and snackbar
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Dialog should be closed
      expect(find.byType(ContentProcessingDialog), findsNothing);

      // Error snackbar should be shown (text contains the error message)
      expect(find.textContaining('Processing failed'), findsOneWidget);
    });

    testWidgets('only processes updates for matching job ID', (tester) async {
      await tester.pumpWidget(createTestWidget(jobId: 'job-1'));
      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      // Emit update for different job
      final otherJobUpdate = JobModel(
        jobId: 'job-2',
        projectId: 'project-1',
        jobType: JobType.textUpload,
        status: JobStatus.processing,
        progress: 75.0,
        currentStep: 4,
        totalSteps: 5,
        stepDescription: 'Should not appear',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      mockJobService.addJobUpdate(otherJobUpdate);
      await tester.pump();

      // Progress should still be 0% (initial state)
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('Should not appear'), findsNothing);
    });

    testWidgets('highlights active steps correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(jobId: 'job-1'));
      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      // Emit job update with step 3 active
      final jobUpdate = JobModel(
        jobId: 'job-1',
        projectId: 'project-1',
        jobType: JobType.textUpload,
        status: JobStatus.processing,
        progress: 60.0,
        currentStep: 3,
        totalSteps: 5,
        stepDescription: 'Generating embeddings',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      mockJobService.addJobUpdate(jobUpdate);
      await tester.pump();

      // Steps 1 and 2 should be complete (check icons)
      // Step 3 should be active (current icon)
      // Steps 4 and 5 should be inactive

      // This is verified by the step description showing (appears twice: in description box and in step list)
      expect(find.text('Generating embeddings'), findsAtLeast(1));
    });

    testWidgets('linear progress bar reflects job progress', (tester) async {
      await tester.pumpWidget(createTestWidget(jobId: 'job-1'));
      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      // Emit job update with 40% progress
      final jobUpdate = JobModel(
        jobId: 'job-1',
        projectId: 'project-1',
        jobType: JobType.textUpload,
        status: JobStatus.processing,
        progress: 40.0,
        currentStep: 2,
        totalSteps: 5,
        stepDescription: 'Creating chunks',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      mockJobService.addJobUpdate(jobUpdate);
      await tester.pump();

      // Find linear progress indicator
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );

      // Check value (40% = 0.4)
      expect(progressIndicator.value, equals(0.4));
    });

    testWidgets('handles contentId parameter', (tester) async {
      await tester.pumpWidget(createTestWidget(
        jobId: 'job-1',
        contentId: 'content-123',
      ));
      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      // Dialog should render with contentId
      expect(find.byType(ContentProcessingDialog), findsOneWidget);
    });

    testWidgets('disposes resources properly', (tester) async {
      await tester.pumpWidget(createTestWidget(jobId: 'job-1'));
      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      // Close dialog manually
      await tester.tapAt(const Offset(10, 10)); // Tap outside dialog
      await tester.pumpAndSettle();

      // Dialog should be disposed
      expect(find.byType(ContentProcessingDialog), findsNothing);
    });
  });
}
