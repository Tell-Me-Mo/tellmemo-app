import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pm_master_v2/features/queries/presentation/widgets/query_suggestions.dart';
import 'package:pm_master_v2/features/queries/presentation/providers/query_provider.dart';

void main() {
  group('QuerySuggestions', () {
    Widget createTestWidget({
      required String query,
      required Function(String) onSuggestionSelected,
      List<String>? customSuggestions,
    }) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: QuerySuggestions(
              query: query,
              onSuggestionSelected: onSuggestionSelected,
              customSuggestions: customSuggestions,
            ),
          ),
        ),
      );
    }

    testWidgets('returns empty widget when no suggestions match query', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(
        query: 'xyz123nomatch',
        onSuggestionSelected: (_) {},
      ));

      // Assert - widget returns SizedBox.shrink(), no ListView or Container
      expect(find.byType(ListView), findsNothing);
      expect(find.text('xyz123nomatch'), findsNothing);
    });

    testWidgets('displays filtered suggestions based on query', (WidgetTester tester) async {
      // Arrange
      final customSuggestions = [
        'What are the key decisions?',
        'Show me action items',
        'What are the blockers?',
        'Summarize the project',
      ];

      // Act
      await tester.pumpWidget(createTestWidget(
        query: 'action',
        onSuggestionSelected: (_) {},
        customSuggestions: customSuggestions,
      ));

      // Assert
      expect(find.text('Show me action items'), findsOneWidget);
      expect(find.text('What are the key decisions?'), findsNothing);
    });

    testWidgets('displays search icon for each suggestion', (WidgetTester tester) async {
      // Arrange
      final customSuggestions = [
        'Test suggestion 1',
        'Test suggestion 2',
      ];

      // Act
      await tester.pumpWidget(createTestWidget(
        query: 'Test',
        onSuggestionSelected: (_) {},
        customSuggestions: customSuggestions,
      ));

      // Assert
      expect(find.byIcon(Icons.search), findsNWidgets(2));
    });

    testWidgets('limits suggestions to 5 items', (WidgetTester tester) async {
      // Arrange
      final customSuggestions = [
        'Suggestion 1',
        'Suggestion 2',
        'Suggestion 3',
        'Suggestion 4',
        'Suggestion 5',
        'Suggestion 6',
        'Suggestion 7',
      ];

      // Act
      await tester.pumpWidget(createTestWidget(
        query: 'Suggestion',
        onSuggestionSelected: (_) {},
        customSuggestions: customSuggestions,
      ));

      // Assert - should only show 5 suggestions
      expect(find.text('Suggestion 1'), findsOneWidget);
      expect(find.text('Suggestion 5'), findsOneWidget);
      expect(find.text('Suggestion 6'), findsNothing);
      expect(find.text('Suggestion 7'), findsNothing);
    });

    testWidgets('calls onSuggestionSelected when tapping a suggestion', (WidgetTester tester) async {
      // Arrange
      String? selectedSuggestion;
      final customSuggestions = ['Test suggestion'];

      await tester.pumpWidget(createTestWidget(
        query: 'Test',
        onSuggestionSelected: (suggestion) {
          selectedSuggestion = suggestion;
        },
        customSuggestions: customSuggestions,
      ));

      // Act
      await tester.tap(find.text('Test suggestion'));
      await tester.pumpAndSettle();

      // Assert
      expect(selectedSuggestion, 'Test suggestion');
    });

    testWidgets('uses default suggestions from provider when customSuggestions is null', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(
        query: 'decisions',
        onSuggestionSelected: (_) {},
      ));

      // Assert - should show suggestions from querySuggestionsProvider
      expect(find.text('What were the key decisions made this week?'), findsOneWidget);
    });

    testWidgets('filters suggestions case-insensitively', (WidgetTester tester) async {
      // Arrange
      final customSuggestions = [
        'Show ACTION Items',
        'What are the Blockers?',
      ];

      // Act
      await tester.pumpWidget(createTestWidget(
        query: 'action',
        onSuggestionSelected: (_) {},
        customSuggestions: customSuggestions,
      ));

      // Assert
      expect(find.text('Show ACTION Items'), findsOneWidget);
    });

    testWidgets('displays dividers between suggestions except for last item', (WidgetTester tester) async {
      // Arrange
      final customSuggestions = [
        'Suggestion 1',
        'Suggestion 2',
        'Suggestion 3',
      ];

      // Act
      await tester.pumpWidget(createTestWidget(
        query: 'Suggestion',
        onSuggestionSelected: (_) {},
        customSuggestions: customSuggestions,
      ));

      // Assert - should have 2 dividers (between 1-2 and 2-3, but not after 3)
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('has proper Material styling with elevation and border', (WidgetTester tester) async {
      // Arrange
      final customSuggestions = ['Test suggestion'];

      // Act
      await tester.pumpWidget(createTestWidget(
        query: 'Test',
        onSuggestionSelected: (_) {},
        customSuggestions: customSuggestions,
      ));

      // Assert - find Material widget that contains ListView (the suggestions Material)
      final suggestionsMaterial = tester.widget<Material>(
        find.ancestor(
          of: find.byType(ListView),
          matching: find.byType(Material),
        ).first,
      );
      expect(suggestionsMaterial.elevation, 8);
      expect(suggestionsMaterial.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('constrains height to maximum 300 pixels', (WidgetTester tester) async {
      // Arrange
      final customSuggestions = List.generate(10, (i) => 'Suggestion $i');

      // Act
      await tester.pumpWidget(createTestWidget(
        query: 'Suggestion',
        onSuggestionSelected: (_) {},
        customSuggestions: customSuggestions,
      ));

      // Assert
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(Material),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.constraints?.maxHeight, 300);
    });
  });
}
