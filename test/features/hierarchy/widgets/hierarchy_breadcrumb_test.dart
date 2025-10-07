import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/hierarchy/domain/entities/hierarchy_item.dart';
import 'package:pm_master_v2/features/hierarchy/presentation/widgets/hierarchy_breadcrumb.dart' as widget;
import '../helpers/hierarchy_test_fixtures.dart';

void main() {
  group('HierarchyBreadcrumb', () {
    testWidgets('displays home icon', (WidgetTester tester) async {
      final portfolio = HierarchyTestFixtures.createPortfolio();
      final path = [portfolio];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: widget.HierarchyBreadcrumb(path: path),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('displays single item path', (WidgetTester tester) async {
      final portfolio = HierarchyTestFixtures.createPortfolio(name: 'My Portfolio');
      final path = [portfolio];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: widget.HierarchyBreadcrumb(path: path),
            ),
          ),
        ),
      );

      expect(find.text('My Portfolio'), findsOneWidget);
      expect(find.byIcon(Icons.business_center), findsOneWidget);
    });

    testWidgets('displays multiple items with separators', (WidgetTester tester) async {
      final portfolio = HierarchyTestFixtures.createPortfolio(name: 'Portfolio A');
      final program = HierarchyTestFixtures.createProgram(name: 'Program B');
      final project = HierarchyTestFixtures.createProject(name: 'Project C');
      final path = [portfolio, program, project];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: widget.HierarchyBreadcrumb(path: path),
            ),
          ),
        ),
      );

      expect(find.text('Portfolio A'), findsOneWidget);
      expect(find.text('Program B'), findsOneWidget);
      expect(find.text('Project C'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    });

    testWidgets('calls onItemTap when non-last item is tapped', (WidgetTester tester) async {
      final portfolio = HierarchyTestFixtures.createPortfolio(name: 'Portfolio A');
      final program = HierarchyTestFixtures.createProgram(name: 'Program B');
      final path = [portfolio, program];

      HierarchyItem? tappedItem;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: widget.HierarchyBreadcrumb(
                path: path,
                onItemTap: (item) => tappedItem = item,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Portfolio A'));
      await tester.pumpAndSettle();

      expect(tappedItem, equals(portfolio));
    });

    testWidgets('does not call onItemTap for last item', (WidgetTester tester) async {
      final portfolio = HierarchyTestFixtures.createPortfolio(name: 'Portfolio A');
      final program = HierarchyTestFixtures.createProgram(name: 'Program B');
      final path = [portfolio, program];

      HierarchyItem? tappedItem;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: widget.HierarchyBreadcrumb(
                path: path,
                onItemTap: (item) => tappedItem = item,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Program B'));
      await tester.pumpAndSettle();

      expect(tappedItem, isNull);
    });

    testWidgets('returns empty widget when path is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: widget.HierarchyBreadcrumb(path: const []),
            ),
          ),
        ),
      );

      expect(find.byType(widget.HierarchyBreadcrumb), findsOneWidget);
      expect(find.byIcon(Icons.home), findsNothing);
    });

    testWidgets('displays correct icons for each type', (WidgetTester tester) async {
      final portfolio = HierarchyTestFixtures.createPortfolio();
      final program = HierarchyTestFixtures.createProgram();
      final project = HierarchyTestFixtures.createProject();
      final path = [portfolio, program, project];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: widget.HierarchyBreadcrumb(path: path),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.business_center), findsOneWidget);
      expect(find.byIcon(Icons.category), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsOneWidget);
    });
  });
}
