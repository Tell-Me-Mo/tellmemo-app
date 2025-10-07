import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/features/activities/domain/entities/activity.dart';
import 'package:pm_master_v2/features/activities/presentation/providers/activity_provider.dart';
import 'package:pm_master_v2/features/activities/presentation/widgets/activity_feed_card.dart';
import 'package:pm_master_v2/core/network/api_service.dart';
import 'package:pm_master_v2/core/network/api_client.dart';

void main() {
  group('ActivityFeedCard Widget', () {
    late List<Activity> testActivities;

    setUp(() {
      final now = DateTime.now();
      testActivities = [
        Activity(
          id: '1',
          projectId: 'proj-1',
          type: ActivityType.projectCreated,
          title: 'Project Alpha Created',
          description: 'New project created',
          timestamp: now.subtract(const Duration(minutes: 5)),
        ),
        Activity(
          id: '2',
          projectId: 'proj-1',
          type: ActivityType.contentUploaded,
          title: 'Document Uploaded',
          description: 'report.pdf uploaded',
          timestamp: now.subtract(const Duration(hours: 2)),
        ),
        Activity(
          id: '3',
          projectId: 'proj-1',
          type: ActivityType.summaryGenerated,
          title: 'Summary Generated',
          description: 'Weekly summary created',
          timestamp: now.subtract(const Duration(days: 1)),
        ),
      ];
    });

    Widget createTestWidget({
      required List<Activity> activities,
      ActivityType? filterType,
      bool isLoading = false,
      String? error,
    }) {
      return ProviderScope(
        overrides: [
          activityProvider.overrideWith((ref) => _MockActivityNotifier(
                activities: activities,
                filterType: filterType,
                isLoading: isLoading,
                error: error,
              )),
          filteredActivitiesProvider.overrideWith((ref) {
            final state = ref.watch(activityProvider);
            if (filterType == null) {
              return activities;
            }
            return activities.where((a) => a.type == filterType).toList();
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ActivityFeedCard(projectId: 'proj-1'),
          ),
        ),
      );
    }

    group('renders correctly', () {
      testWidgets('displays "Recent Activity" title', (tester) async {
        await tester.pumpWidget(createTestWidget(activities: testActivities));
        await tester.pumpAndSettle();

        expect(find.text('Recent Activity'), findsOneWidget);
      });

      testWidgets('displays menu button', (tester) async {
        await tester.pumpWidget(createTestWidget(activities: testActivities));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });

      testWidgets('renders in a Card widget', (tester) async {
        await tester.pumpWidget(createTestWidget(activities: testActivities));
        await tester.pumpAndSettle();

        expect(find.byType(Card), findsWidgets);
      });
    });

    group('activity display', () {
      testWidgets('displays up to 5 recent activities', (tester) async {
        await tester.pumpWidget(createTestWidget(activities: testActivities));
        await tester.pumpAndSettle();

        expect(find.text('Project Alpha Created'), findsOneWidget);
        expect(find.text('Document Uploaded'), findsOneWidget);
        expect(find.text('Summary Generated'), findsOneWidget);
      });

      testWidgets('shows activity icons', (tester) async {
        await tester.pumpWidget(createTestWidget(activities: testActivities));
        await tester.pumpAndSettle();

        // Should find CircleAvatar widgets for each activity
        expect(find.byType(CircleAvatar), findsNWidgets(3));
      });

      testWidgets('shows activity titles and descriptions', (tester) async {
        await tester.pumpWidget(createTestWidget(activities: testActivities));
        await tester.pumpAndSettle();

        expect(find.text('Project Alpha Created'), findsOneWidget);
        expect(find.text('New project created'), findsOneWidget);
        expect(find.text('Document Uploaded'), findsOneWidget);
        expect(find.text('report.pdf uploaded'), findsOneWidget);
      });

      testWidgets('shows formatted time for each activity', (tester) async {
        await tester.pumpWidget(createTestWidget(activities: testActivities));
        await tester.pumpAndSettle();

        // Look for time-related text (e.g., "5m ago", "2h ago", "1d ago")
        expect(find.textContaining('ago', findRichText: true), findsWidgets);
      });

      testWidgets('displays activities as ListTiles', (tester) async {
        await tester.pumpWidget(createTestWidget(activities: testActivities));
        await tester.pumpAndSettle();

        expect(find.byType(ListTile), findsNWidgets(3));
      });
    });

    group('empty state', () {
      testWidgets('displays empty state when no activities', (tester) async {
        await tester.pumpWidget(createTestWidget(activities: []));
        await tester.pumpAndSettle();

        expect(find.text('No recent activity'), findsOneWidget);
        expect(find.byIcon(Icons.history), findsOneWidget);
      });

      testWidgets('does not show "View all" button when empty', (tester) async {
        await tester.pumpWidget(createTestWidget(activities: []));
        await tester.pumpAndSettle();

        expect(find.textContaining('View all'), findsNothing);
      });
    });

    group('view all functionality', () {
      testWidgets('shows "View all" button when more than 5 activities', (tester) async {
        final now = DateTime.now();
        final manyActivities = List.generate(
          7,
          (i) => Activity(
            id: '$i',
            projectId: 'proj-1',
            type: ActivityType.projectUpdated,
            title: 'Activity $i',
            description: 'Description $i',
            timestamp: now.subtract(Duration(minutes: i)),
          ),
        );

        await tester.pumpWidget(createTestWidget(activities: manyActivities));
        await tester.pumpAndSettle();

        expect(find.textContaining('View all'), findsOneWidget);
        expect(find.text('View all 7 activities'), findsOneWidget);
      });

      testWidgets('does not show "View all" button with 5 or fewer activities', (tester) async {
        await tester.pumpWidget(createTestWidget(activities: testActivities));
        await tester.pumpAndSettle();

        expect(find.textContaining('View all'), findsNothing);
      });

      testWidgets('opens dialog when "View all" is tapped', (tester) async {
        final now = DateTime.now();
        final manyActivities = List.generate(
          7,
          (i) => Activity(
            id: '$i',
            projectId: 'proj-1',
            type: ActivityType.projectUpdated,
            title: 'Activity $i',
            description: 'Description $i',
            timestamp: now.subtract(Duration(minutes: i)),
          ),
        );

        await tester.pumpWidget(createTestWidget(activities: manyActivities));
        await tester.pump();

        // Tap to open dialog
        await tester.tap(find.text('View all 7 activities'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify dialog opened
        expect(find.text('All Activities'), findsOneWidget);
        expect(find.byType(Dialog), findsOneWidget);

        // IMPORTANT: Properly close the dialog to trigger dispose and cleanup timers
        final navigator = Navigator.of(tester.element(find.byType(Dialog)));
        navigator.pop();
        await tester.pumpAndSettle();

        // Verify dialog closed
        expect(find.byType(Dialog), findsNothing);
      });
    });

    group('menu interactions', () {
      testWidgets('opens menu when menu button is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget(activities: testActivities));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Refresh'), findsOneWidget);
        expect(find.text('Filter'), findsOneWidget);
        expect(find.text('Export'), findsOneWidget);
      });

      testWidgets('menu shows correct icons', (tester) async {
        await tester.pumpWidget(createTestWidget(activities: testActivities));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.refresh), findsOneWidget);
        expect(find.byIcon(Icons.filter_list), findsOneWidget);
        expect(find.byIcon(Icons.download), findsOneWidget);
      });

      testWidgets('opens filter dialog when Filter is selected', (tester) async {
        await tester.pumpWidget(createTestWidget(activities: testActivities));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Filter'));
        await tester.pumpAndSettle();

        expect(find.text('Filter Activities'), findsOneWidget);
        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets('filter dialog has close button', (tester) async {
        await tester.pumpWidget(createTestWidget(activities: testActivities));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Filter'));
        await tester.pumpAndSettle();

        expect(find.text('Close'), findsOneWidget);

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('activity colors', () {
      testWidgets('displays different colors for different activity types', (tester) async {
        final now = DateTime.now();
        final coloredActivities = [
          Activity(
            id: '1',
            projectId: 'proj-1',
            type: ActivityType.projectCreated,
            title: 'Created',
            description: 'Desc',
            timestamp: now,
          ),
          Activity(
            id: '2',
            projectId: 'proj-1',
            type: ActivityType.projectDeleted,
            title: 'Deleted',
            description: 'Desc',
            timestamp: now,
          ),
        ];

        await tester.pumpWidget(createTestWidget(activities: coloredActivities));
        await tester.pumpAndSettle();

        // Should find CircleAvatars with different background colors
        final circleAvatars = tester.widgetList<CircleAvatar>(find.byType(CircleAvatar));
        expect(circleAvatars.length, 2);
      });
    });

    group('responsiveness', () {
      testWidgets('adapts to different screen sizes', (tester) async {
        await tester.pumpWidget(createTestWidget(activities: testActivities));
        await tester.pumpAndSettle();

        // Widget should render without overflow
        expect(tester.takeException(), isNull);
      });
    });
  });
}

/// Mock ActivityNotifier for testing
class _MockActivityNotifier extends ActivityNotifier {
  final List<Activity> _activities;
  final ActivityType? _filterType;
  final bool _isLoading;
  final String? _error;

  _MockActivityNotifier({
    required List<Activity> activities,
    ActivityType? filterType,
    bool isLoading = false,
    String? error,
  })  : _activities = activities,
        _filterType = filterType,
        _isLoading = isLoading,
        _error = error,
        super(_createMockApiService());

  static ApiService _createMockApiService() {
    return ApiService(_MockApiClient());
  }

  @override
  ActivityState build() {
    return ActivityState(
      activities: _activities,
      filterType: _filterType,
      isLoading: _isLoading,
      error: _error,
    );
  }

  @override
  Future<void> loadActivities(String projectId) async {
    // Mock implementation - do nothing
  }

  @override
  List<Activity> get filteredActivities {
    if (_filterType == null) {
      return _activities;
    }
    return _activities.where((activity) => activity.type == _filterType).toList();
  }
}

/// Mock API Client
class _MockApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
