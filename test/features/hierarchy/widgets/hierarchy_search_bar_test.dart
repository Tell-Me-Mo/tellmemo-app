import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/hierarchy/presentation/widgets/hierarchy_search_bar.dart';

void main() {
  group('HierarchySearchBar', () {
    testWidgets('displays search icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchySearchBar(
                onSearchChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('displays hint text', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchySearchBar(
                onSearchChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Search portfolios, programs, and projects...'), findsOneWidget);
    });

    testWidgets('calls onSearchChanged when text is entered', (WidgetTester tester) async {
      String? searchQuery;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchySearchBar(
                onSearchChanged: (query) => searchQuery = query,
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test query');
      await tester.pump();

      expect(searchQuery, equals('test query'));
    });

    testWidgets('shows clear button when text is entered', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchySearchBar(
                onSearchChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      // Initially no clear button
      expect(find.byIcon(Icons.clear), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      // Clear button appears
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('clears text when clear button tapped', (WidgetTester tester) async {
      String? searchQuery;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchySearchBar(
                onSearchChanged: (query) => searchQuery = query,
              ),
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Text cleared
      expect(find.text('test'), findsNothing);
      expect(searchQuery, equals(''));
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('displays filter button when onFilterTap is provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchySearchBar(
                onSearchChanged: (_) {},
                onFilterTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.tune), findsOneWidget);
    });

    testWidgets('does not display filter button when onFilterTap is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchySearchBar(
                onSearchChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.tune), findsNothing);
    });

    testWidgets('calls onFilterTap when filter button tapped', (WidgetTester tester) async {
      bool filterTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchySearchBar(
                onSearchChanged: (_) {},
                onFilterTap: () => filterTapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pump();

      expect(filterTapped, isTrue);
    });
  });
}
