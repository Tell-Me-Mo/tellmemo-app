import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/core/network/api_client.dart';
import 'package:pm_master_v2/core/network/api_service.dart';
import 'package:pm_master_v2/features/queries/presentation/providers/query_provider.dart';
import 'package:pm_master_v2/features/queries/presentation/widgets/query_history_list.dart';

void main() {
  group('QueryHistoryList', () {
    // Helper to create widget with mock provider
    Widget createTestWidget({
      required List<String> queryHistory,
      required Function(String) onQuerySelected,
    }) {
      return ProviderScope(
        overrides: [
          queryProvider.overrideWith(
            (ref) => TestQueryNotifier(
              QueryState(queryHistory: queryHistory),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: QueryHistoryList(
              projectId: 'test-project',
              onQuerySelected: onQuerySelected,
            ),
          ),
        ),
      );
    }

    testWidgets('displays header with icon and title', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          queryHistory: [],
          onQuerySelected: (_) {},
        ),
      );

      expect(find.text('Recent Queries'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('displays empty state when no queries', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          queryHistory: [],
          onQuerySelected: (_) {},
        ),
      );

      expect(find.text('No queries yet'), findsOneWidget);
      expect(find.byIcon(Icons.history_toggle_off), findsOneWidget);
    });

    testWidgets('displays suggestions when no queries exist', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          queryHistory: [],
          onQuerySelected: (_) {},
        ),
      );

      expect(find.text('Try asking:'), findsOneWidget);
      expect(find.text('What are the key decisions?'), findsOneWidget);
      expect(find.text('Show me action items'), findsOneWidget);
      expect(find.text('What is the project status?'), findsOneWidget);
      expect(find.text('Any blockers identified?'), findsOneWidget);
    });

    testWidgets('suggestion items have lightbulb icons', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          queryHistory: [],
          onQuerySelected: (_) {},
        ),
      );

      // Find all lightbulb icons in suggestions
      final lightbulbIcons = tester.widgetList<Icon>(
        find.byIcon(Icons.lightbulb_outline),
      );

      expect(lightbulbIcons.length, 4); // 4 suggestions
    });

    testWidgets('tapping suggestion calls onQuerySelected', (tester) async {
      String? selectedQuery;

      await tester.pumpWidget(
        createTestWidget(
          queryHistory: [],
          onQuerySelected: (query) {
            selectedQuery = query;
          },
        ),
      );

      // Tap first suggestion
      await tester.tap(find.text('What are the key decisions?'));
      await tester.pump();

      expect(selectedQuery, 'What are the key decisions?');
    });

    testWidgets('displays query history when queries exist', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          queryHistory: [
            'What are the action items?',
            'Show me the risks',
            'Project status update',
          ],
          onQuerySelected: (_) {},
        ),
      );

      // Should display all 3 queries
      expect(find.text('What are the action items?'), findsOneWidget);
      expect(find.text('Show me the risks'), findsOneWidget);
      expect(find.text('Project status update'), findsOneWidget);
    });

    testWidgets('query history items have search icons', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          queryHistory: ['Test query 1', 'Test query 2'],
          onQuerySelected: (_) {},
        ),
      );

      // Find all search icons in history items
      final searchIcons = tester.widgetList<Icon>(
        find.byIcon(Icons.search),
      );

      expect(searchIcons.length, 2); // 2 history items
    });

    testWidgets('query history items have forward arrow icons', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          queryHistory: ['Test query 1', 'Test query 2'],
          onQuerySelected: (_) {},
        ),
      );

      // Find all forward arrow icons in history items
      final arrowIcons = tester.widgetList<Icon>(
        find.byIcon(Icons.arrow_forward_ios),
      );

      expect(arrowIcons.length, 2); // 2 history items
    });

    testWidgets('tapping history item calls onQuerySelected', (tester) async {
      String? selectedQuery;

      await tester.pumpWidget(
        createTestWidget(
          queryHistory: ['What are the action items?'],
          onQuerySelected: (query) {
            selectedQuery = query;
          },
        ),
      );

      // Tap history item
      await tester.tap(find.text('What are the action items?'));
      await tester.pump();

      expect(selectedQuery, 'What are the action items?');
    });

    testWidgets('does not show suggestions when history exists', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          queryHistory: ['Test query'],
          onQuerySelected: (_) {},
        ),
      );

      // Should not show "Try asking:" section
      expect(find.text('Try asking:'), findsNothing);
    });

    testWidgets('does not show empty state when history exists', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          queryHistory: ['Test query'],
          onQuerySelected: (_) {},
        ),
      );

      // Should not show empty state
      expect(find.text('No queries yet'), findsNothing);
      expect(find.byIcon(Icons.history_toggle_off), findsNothing);
    });

    testWidgets('history items are displayed in a ListView', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          queryHistory: ['Query 1', 'Query 2', 'Query 3'],
          onQuerySelected: (_) {},
        ),
      );

      // Should have a ListView.separated
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}

// Test QueryNotifier that returns fixed state
class TestQueryNotifier extends QueryNotifier {
  final QueryState _testState;

  TestQueryNotifier(this._testState) : super(_createMockApiService());

  @override
  QueryState get state => _testState;

  static ApiService _createMockApiService() {
    // Return a minimal mock - actual API calls won't happen in these tests
    final mockClient = _MockApiClient();
    return ApiService(mockClient);
  }
}

// Minimal mock ApiClient for testing
class _MockApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
