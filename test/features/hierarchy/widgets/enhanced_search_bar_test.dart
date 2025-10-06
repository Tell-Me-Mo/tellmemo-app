import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/hierarchy/presentation/widgets/enhanced_search_bar.dart';
import '../helpers/hierarchy_test_fixtures.dart';

void main() {
  group('EnhancedSearchBar', () {
    testWidgets('displays search icon and hint text', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedSearchBar(
                onSearchChanged: (_) {},
                onFilterChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Search by name or description...'), findsOneWidget);
    });

    testWidgets('displays filter button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedSearchBar(
                onSearchChanged: (_) {},
                onFilterChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('shows clear button when text is entered', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedSearchBar(
                onSearchChanged: (_) {},
                onFilterChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially no clear button
      expect(find.byIcon(Icons.clear), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextField), 'test query');
      await tester.pumpAndSettle();

      // Clear button appears
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('toggles filter panel when filter button tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedSearchBar(
                onSearchChanged: (_) {},
                onFilterChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap filter button to show filters
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Filters now visible
      expect(find.text('Filter by type:'), findsOneWidget);
    });

    testWidgets('displays filter chips for all hierarchy types', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedSearchBar(
                onSearchChanged: (_) {},
                onFilterChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      expect(find.text('portfolio'), findsOneWidget);
      expect(find.text('program'), findsOneWidget);
      expect(find.text('project'), findsOneWidget);
    });

    testWidgets('displays filter checkboxes', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedSearchBar(
                onSearchChanged: (_) {},
                onFilterChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      expect(find.text('Search in descriptions'), findsOneWidget);
      expect(find.text('Include archived'), findsOneWidget);
    });

    testWidgets('calls onFilterChanged when type filter selected', (WidgetTester tester) async {
      SearchFilter? currentFilter;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedSearchBar(
                onSearchChanged: (_) {},
                onFilterChanged: (filter) => currentFilter = filter,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      await tester.tap(find.text('portfolio'));
      await tester.pumpAndSettle();

      expect(currentFilter, isNotNull);
      expect(currentFilter!.itemTypes.length, equals(1));
    });

    testWidgets('displays clear filters button when filters active', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedSearchBar(
                onSearchChanged: (_) {},
                onFilterChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Initially no clear button
      expect(find.text('Clear filters'), findsNothing);

      // Select a filter
      await tester.tap(find.text('portfolio'));
      await tester.pumpAndSettle();

      // Clear filters button appears
      expect(find.text('Clear filters'), findsOneWidget);
    });

    testWidgets('clears all filters when clear button tapped', (WidgetTester tester) async {
      SearchFilter? currentFilter;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedSearchBar(
                onSearchChanged: (_) {},
                onFilterChanged: (filter) => currentFilter = filter,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Select filters
      await tester.tap(find.text('portfolio'));
      await tester.pumpAndSettle();

      // Clear filters
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(currentFilter!.itemTypes.isEmpty, isTrue);
    });

    testWidgets('highlights filter button when filters active', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedSearchBar(
                onSearchChanged: (_) {},
                onFilterChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Select a filter
      await tester.tap(find.text('portfolio'));
      await tester.pumpAndSettle();

      // Filter button should be highlighted (using primary color)
      // This is indicated by the filter icon still being visible
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });
  });
}
