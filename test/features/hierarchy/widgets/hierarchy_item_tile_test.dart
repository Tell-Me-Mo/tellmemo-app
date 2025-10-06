import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/hierarchy/presentation/widgets/hierarchy_item_tile.dart';
import '../helpers/hierarchy_test_fixtures.dart';

void main() {
  group('HierarchyItemTile', () {
    testWidgets('displays item name', (WidgetTester tester) async {
      final item = HierarchyTestFixtures.createProject(name: 'My Project');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyItemTile(
                item: item,
                isSelected: false,
                isExpanded: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('My Project'), findsOneWidget);
    });

    testWidgets('displays description when provided', (WidgetTester tester) async {
      final item = HierarchyTestFixtures.createProject(
        name: 'Project',
        description: 'Project description',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyItemTile(
                item: item,
                isSelected: false,
                isExpanded: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Project description'), findsOneWidget);
    });

    testWidgets('does not display description when null', (WidgetTester tester) async {
      final item = HierarchyTestFixtures.createProject(
        name: 'Project',
        description: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyItemTile(
                item: item,
                isSelected: false,
                isExpanded: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Project'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget); // Only the name
    });

    testWidgets('displays correct icon for portfolio', (WidgetTester tester) async {
      final item = HierarchyTestFixtures.createPortfolio();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyItemTile(
                item: item,
                isSelected: false,
                isExpanded: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.business_center), findsOneWidget);
    });

    testWidgets('displays correct icon for program', (WidgetTester tester) async {
      final item = HierarchyTestFixtures.createProgram();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyItemTile(
                item: item,
                isSelected: false,
                isExpanded: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.category), findsOneWidget);
    });

    testWidgets('displays correct icon for project', (WidgetTester tester) async {
      final item = HierarchyTestFixtures.createProject();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyItemTile(
                item: item,
                isSelected: false,
                isExpanded: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.folder), findsOneWidget);
    });

    testWidgets('displays expand button for items with children', (WidgetTester tester) async {
      final item = HierarchyTestFixtures.createPortfolio(
        children: [HierarchyTestFixtures.createProject()],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyItemTile(
                item: item,
                isSelected: false,
                isExpanded: false,
                onExpand: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('rotates expand icon when expanded', (WidgetTester tester) async {
      final item = HierarchyTestFixtures.createPortfolio(
        children: [HierarchyTestFixtures.createProject()],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyItemTile(
                item: item,
                isSelected: false,
                isExpanded: true,
                onExpand: () {},
              ),
            ),
          ),
        ),
      );

      final animatedRotation = tester.widget<AnimatedRotation>(
        find.byType(AnimatedRotation),
      );
      expect(animatedRotation.turns, equals(0.25));
    });

    testWidgets('displays checkbox when onSelectionChanged provided', (WidgetTester tester) async {
      final item = HierarchyTestFixtures.createProject();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyItemTile(
                item: item,
                isSelected: false,
                isExpanded: false,
                onSelectionChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('checkbox reflects selected state', (WidgetTester tester) async {
      final item = HierarchyTestFixtures.createProject();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyItemTile(
                item: item,
                isSelected: true,
                isExpanded: false,
                onSelectionChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('displays count badge when metadata contains count', (WidgetTester tester) async {
      final item = HierarchyTestFixtures.createPortfolio(
        metadata: {'count': 5},
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyItemTile(
                item: item,
                isSelected: false,
                isExpanded: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('displays popup menu button', (WidgetTester tester) async {
      final item = HierarchyTestFixtures.createProject();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyItemTile(
                item: item,
                isSelected: false,
                isExpanded: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('shows menu options when popup button tapped', (WidgetTester tester) async {
      final item = HierarchyTestFixtures.createProject();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyItemTile(
                item: item,
                isSelected: false,
                isExpanded: false,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Move'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('calls onEdit when edit menu item selected', (WidgetTester tester) async {
      final item = HierarchyTestFixtures.createProject();
      bool editCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyItemTile(
                item: item,
                isSelected: false,
                isExpanded: false,
                onEdit: () => editCalled = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(editCalled, isTrue);
    });

    testWidgets('calls onMove when move menu item selected', (WidgetTester tester) async {
      final item = HierarchyTestFixtures.createProject();
      bool moveCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyItemTile(
                item: item,
                isSelected: false,
                isExpanded: false,
                onMove: () => moveCalled = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move'));
      await tester.pumpAndSettle();

      expect(moveCalled, isTrue);
    });

    testWidgets('calls onDelete when delete menu item selected', (WidgetTester tester) async {
      final item = HierarchyTestFixtures.createProject();
      bool deleteCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyItemTile(
                item: item,
                isSelected: false,
                isExpanded: false,
                onDelete: () => deleteCalled = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
    });

    testWidgets('calls onTap when tile is tapped', (WidgetTester tester) async {
      final item = HierarchyTestFixtures.createProject();
      bool tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyItemTile(
                item: item,
                isSelected: false,
                isExpanded: false,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('applies indentation based on indentLevel', (WidgetTester tester) async {
      final item = HierarchyTestFixtures.createProject();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyItemTile(
                item: item,
                isSelected: false,
                isExpanded: false,
                indentLevel: 2,
              ),
            ),
          ),
        ),
      );

      // Verify widget builds successfully with indentation
      expect(find.byType(HierarchyItemTile), findsOneWidget);
      expect(find.text(item.name), findsOneWidget);
    });
  });
}
