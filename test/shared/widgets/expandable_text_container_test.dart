import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/shared/widgets/expandable_text_container.dart';

void main() {
  group('ExpandableTextContainer Widget', () {
    late ColorScheme colorScheme;

    setUp(() {
      colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
    });

    Widget createTestWidget(String text, {bool showAsPlaceholder = false}) {
      return MaterialApp(
        home: Scaffold(
          body: ExpandableTextContainer(
            text: text,
            colorScheme: colorScheme,
            showAsPlaceholder: showAsPlaceholder,
          ),
        ),
      );
    }

    testWidgets('displays short text without truncation', (WidgetTester tester) async {
      const shortText = 'This is a short text.';
      await tester.pumpWidget(createTestWidget(shortText));

      // Should display the full text
      expect(find.text(shortText), findsOneWidget);

      // Should not show read more button
      expect(find.text('Read more'), findsNothing);
    });

    testWidgets('truncates long text and shows read more button', (WidgetTester tester) async {
      final longText = 'This is a very long text that exceeds 200 characters. ' * 10;
      await tester.pumpWidget(createTestWidget(longText));

      // Should show truncated text
      expect(find.textContaining('...'), findsOneWidget);

      // Should show read more button
      expect(find.text('Read more'), findsOneWidget);
    });

    testWidgets('expands text when read more is tapped', (WidgetTester tester) async {
      final longText = 'This is a very long text that exceeds 200 characters. ' * 10;
      await tester.pumpWidget(createTestWidget(longText));

      // Initially should show read more
      expect(find.text('Read more'), findsOneWidget);

      // Tap read more
      await tester.tap(find.text('Read more'));
      await tester.pumpAndSettle();

      // Should now show read less
      expect(find.text('Read less'), findsOneWidget);
      expect(find.text('Read more'), findsNothing);
    });

    testWidgets('collapses text when read less is tapped', (WidgetTester tester) async {
      final longText = 'This is a very long text that exceeds 200 characters. ' * 10;
      await tester.pumpWidget(createTestWidget(longText));

      // Expand the text
      await tester.tap(find.text('Read more'));
      await tester.pumpAndSettle();

      // Tap read less
      await tester.tap(find.text('Read less'));
      await tester.pumpAndSettle();

      // Should show read more again
      expect(find.text('Read more'), findsOneWidget);
      expect(find.text('Read less'), findsNothing);
    });

    testWidgets('handles empty string gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(''));

      // Should show placeholder text
      expect(find.text('No content available'), findsOneWidget);

      // Should not show read more button
      expect(find.text('Read more'), findsNothing);
    });

    testWidgets('applies placeholder styling when showAsPlaceholder is true', (WidgetTester tester) async {
      const text = 'Placeholder text';
      await tester.pumpWidget(createTestWidget(text, showAsPlaceholder: true));

      // Should display the text
      expect(find.text(text), findsOneWidget);

      // Verify placeholder styling is applied by checking SelectableText widget
      final selectableText = tester.widget<SelectableText>(find.byType(SelectableText));
      expect(selectableText.style?.color, colorScheme.onSurfaceVariant);
    });

    testWidgets('truncates extremely long strings for performance', (WidgetTester tester) async {
      // Create a string longer than maxAllowedLength (default 100,000)
      final extremelyLongText = 'x' * 150000;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandableTextContainer(
              text: extremelyLongText,
              colorScheme: colorScheme,
              maxAllowedLength: 100000,
            ),
          ),
        ),
      );

      // Should show truncation message - the text is truncated at maxCharacters (200) by default
      // so we won't see the full truncation message, but we can verify the behavior
      final selectableText = tester.widget<SelectableText>(find.byType(SelectableText));

      // The text should be truncated to maxCharacters (200) and end with "..."
      expect(selectableText.data?.endsWith('...'), true);
      expect(selectableText.data?.length, lessThanOrEqualTo(203)); // 200 + "..."

      // Should show read more button since text is longer than maxCharacters
      expect(find.text('Read more'), findsOneWidget);
    });

    testWidgets('respects custom maxCharacters parameter', (WidgetTester tester) async {
      const text = 'This is a text that is longer than 50 characters but shorter than 200.';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandableTextContainer(
              text: text,
              colorScheme: colorScheme,
              maxCharacters: 50,
            ),
          ),
        ),
      );

      // Should show read more button with custom limit
      expect(find.text('Read more'), findsOneWidget);
      expect(find.textContaining('...'), findsOneWidget);
    });
  });
}
