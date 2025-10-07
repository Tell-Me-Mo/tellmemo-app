import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/hierarchy/presentation/widgets/hierarchy_action_bar.dart';
import '../helpers/hierarchy_test_fixtures.dart';

void main() {
  group('HierarchyActionBar', () {
    testWidgets('returns empty widget when no items selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyActionBar(
                selectedCount: 0,
                selectedItems: const [],
                onClearSelection: () {},
                onMoveItems: (_) {},
                onDeleteItems: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('selected'), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('displays selection count', (WidgetTester tester) async {
      final items = [
        HierarchyTestFixtures.createProject(),
        HierarchyTestFixtures.createProgram(),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyActionBar(
                selectedCount: 2,
                selectedItems: items,
                onClearSelection: () {},
                onMoveItems: (_) {},
                onDeleteItems: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('2 selected'), findsOneWidget);
    });

    testWidgets('displays close button', (WidgetTester tester) async {
      final items = [HierarchyTestFixtures.createProject()];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyActionBar(
                selectedCount: 1,
                selectedItems: items,
                onClearSelection: () {},
                onMoveItems: (_) {},
                onDeleteItems: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('displays move and delete buttons', (WidgetTester tester) async {
      final items = [HierarchyTestFixtures.createProject()];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyActionBar(
                selectedCount: 1,
                selectedItems: items,
                onClearSelection: () {},
                onMoveItems: (_) {},
                onDeleteItems: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Move'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.byIcon(Icons.drive_file_move_outline), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('calls onClearSelection when close button tapped', (WidgetTester tester) async {
      final items = [HierarchyTestFixtures.createProject()];
      bool cleared = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyActionBar(
                selectedCount: 1,
                selectedItems: items,
                onClearSelection: () => cleared = true,
                onMoveItems: (_) {},
                onDeleteItems: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(cleared, isTrue);
    });

    testWidgets('shows move dialog when move button tapped', (WidgetTester tester) async {
      final items = [HierarchyTestFixtures.createProject()];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyActionBar(
                selectedCount: 1,
                selectedItems: items,
                onClearSelection: () {},
                onMoveItems: (_) {},
                onDeleteItems: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Move'));
      await tester.pumpAndSettle();

      expect(find.text('Move Items'), findsOneWidget);
      expect(find.text('Move 1 item(s) to a different location?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Move'), findsOneWidget);
    });

    testWidgets('shows delete dialog when delete button tapped', (WidgetTester tester) async {
      final items = [HierarchyTestFixtures.createProject()];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyActionBar(
                selectedCount: 1,
                selectedItems: items,
                onClearSelection: () {},
                onMoveItems: (_) {},
                onDeleteItems: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Items'), findsOneWidget);
      expect(find.text('Are you sure you want to delete 1 item(s)?'), findsOneWidget);
    });

    testWidgets('calls onMoveItems when move confirmed', (WidgetTester tester) async {
      final items = [HierarchyTestFixtures.createProject()];
      List<dynamic>? movedItems;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyActionBar(
                selectedCount: 1,
                selectedItems: items,
                onClearSelection: () {},
                onMoveItems: (items) => movedItems = items,
                onDeleteItems: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Move'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Move'));
      await tester.pumpAndSettle();

      expect(movedItems, equals(items));
    });

    testWidgets('calls onDeleteItems when delete confirmed', (WidgetTester tester) async {
      final items = [HierarchyTestFixtures.createProject()];
      List<dynamic>? deletedItems;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyActionBar(
                selectedCount: 1,
                selectedItems: items,
                onClearSelection: () {},
                onMoveItems: (_) {},
                onDeleteItems: (items) => deletedItems = items,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(deletedItems, equals(items));
    });

    testWidgets('displays correct count for multiple items', (WidgetTester tester) async {
      final items = List.generate(5, (i) => HierarchyTestFixtures.createProject(id: 'proj-$i'));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyActionBar(
                selectedCount: 5,
                selectedItems: items,
                onClearSelection: () {},
                onMoveItems: (_) {},
                onDeleteItems: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('5 selected'), findsOneWidget);
    });
  });
}
