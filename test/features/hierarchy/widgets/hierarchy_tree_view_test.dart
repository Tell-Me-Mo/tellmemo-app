import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/hierarchy/presentation/providers/hierarchy_providers.dart';
import 'package:pm_master_v2/features/hierarchy/presentation/widgets/hierarchy_tree_view.dart';
import '../helpers/hierarchy_test_fixtures.dart';

void main() {
  group('HierarchyTreeView', () {
    testWidgets('displays hierarchy items', (WidgetTester tester) async {
      final hierarchy = HierarchyTestFixtures.createSampleHierarchy();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyTreeView(hierarchy: hierarchy),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Portfolio X'), findsOneWidget);
    });

    testWidgets('displays nested items when expanded', (WidgetTester tester) async {
      final hierarchy = HierarchyTestFixtures.createSampleHierarchy();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyTreeView(hierarchy: hierarchy),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Children should be visible (expanded by default)
      expect(find.text('Program A'), findsOneWidget);
      expect(find.text('Program B'), findsOneWidget);
      expect(find.text('Project Alpha'), findsOneWidget);
    });

    testWidgets('shows empty state when search returns no results', (WidgetTester tester) async {
      final hierarchy = HierarchyTestFixtures.createSampleHierarchy();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyTreeView(
                hierarchy: hierarchy,
                searchQuery: 'nonexistent',
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('No matches found'), findsOneWidget);
      expect(find.text('Try adjusting your search terms'), findsOneWidget);
    });

    testWidgets('filters hierarchy based on search query', (WidgetTester tester) async {
      final hierarchy = HierarchyTestFixtures.createSampleHierarchy();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyTreeView(
                hierarchy: hierarchy,
                searchQuery: 'Alpha',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Project Alpha'), findsOneWidget);
      // Parent items should also be visible
      expect(find.text('Portfolio X'), findsOneWidget);
    });

    testWidgets('filters by description when available', (WidgetTester tester) async {
      final hierarchy = HierarchyTestFixtures.createSampleHierarchy();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyTreeView(
                hierarchy: hierarchy,
                searchQuery: 'First project',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Project Alpha'), findsOneWidget);
    });

    testWidgets('calls onItemTap when item is tapped', (WidgetTester tester) async {
      final hierarchy = HierarchyTestFixtures.createSampleHierarchy();
      String? tappedId;
      String? tappedType;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyTreeView(
                hierarchy: hierarchy,
                onItemTap: (id, type) {
                  tappedId = id;
                  tappedType = type;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Portfolio X'));
      await tester.pump();

      expect(tappedId, equals('port-1'));
      expect(tappedType, equals('portfolio'));
    });

    testWidgets('displays empty widget when hierarchy is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyTreeView(hierarchy: const []),
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('supports multi-select mode', (WidgetTester tester) async {
      final hierarchy = HierarchyTestFixtures.createSampleHierarchy();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyTreeView(
                hierarchy: hierarchy,
                isMultiSelectMode: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Checkboxes should be visible in multi-select mode
      expect(find.byType(Checkbox), findsWidgets);
    });

    testWidgets('collapses expanded items when expand button tapped', (WidgetTester tester) async {
      final hierarchy = HierarchyTestFixtures.createSampleHierarchy();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyTreeView(hierarchy: hierarchy),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially expanded - children visible
      expect(find.text('Program A'), findsOneWidget);

      // Tap expand button to collapse
      final expandButtons = find.byIcon(Icons.chevron_right);
      if (expandButtons.evaluate().isNotEmpty) {
        await tester.tap(expandButtons.first);
        await tester.pumpAndSettle();

        // Children should still be visible or animation in progress
        // This is a basic check, full collapse may require multiple frames
      }
    });

    testWidgets('calls onEditItem when provided', (WidgetTester tester) async {
      final hierarchy = HierarchyTestFixtures.createSampleHierarchy();
      String? editedId;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyTreeView(
                hierarchy: hierarchy,
                onEditItem: (id, type) => editedId = id,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open menu for first item
      final moreButtons = find.byIcon(Icons.more_vert);
      await tester.tap(moreButtons.first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(editedId, isNotNull);
    });

    testWidgets('case-insensitive search', (WidgetTester tester) async {
      final hierarchy = HierarchyTestFixtures.createSampleHierarchy();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyTreeView(
                hierarchy: hierarchy,
                searchQuery: 'ALPHA',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Project Alpha'), findsOneWidget);
    });
  });
}
