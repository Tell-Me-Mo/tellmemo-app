import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/shared/widgets/ai_assist_button.dart';

void main() {
  group('AIAssistButton Widget', () {
    testWidgets('renders with default properties', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIAssistButton(
              onPressed: () => wasPressed = true,
            ),
          ),
        ),
      );

      // Should find the button
      expect(find.byType(IconButton), findsOneWidget);

      // Should find the sparkle icon
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

      // Should have default tooltip
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, 'Ask AI for more information');
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIAssistButton(
              onPressed: () => wasPressed = true,
            ),
          ),
        ),
      );

      // Tap the button
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // Callback should have been called
      expect(wasPressed, true);
    });

    testWidgets('uses custom tooltip when provided', (WidgetTester tester) async {
      const customTooltip = 'Custom AI tooltip';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIAssistButton(
              onPressed: () {},
              tooltip: customTooltip,
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, customTooltip);
    });

    testWidgets('uses custom icon size when provided', (WidgetTester tester) async {
      const customSize = 24.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIAssistButton(
              onPressed: () {},
              iconSize: customSize,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.auto_awesome));
      expect(icon.size, customSize);
    });

    testWidgets('uses custom accent color when provided', (WidgetTester tester) async {
      const customColor = Colors.red;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIAssistButton(
              onPressed: () {},
              accentColor: customColor,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.auto_awesome));
      expect(icon.color, customColor);
    });

    testWidgets('uses theme primary color when no accent color provided', (WidgetTester tester) async {
      const seedColor = Colors.blue;
      final colorScheme = ColorScheme.fromSeed(seedColor: seedColor);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: colorScheme),
          home: Scaffold(
            body: AIAssistButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.auto_awesome));
      expect(icon.color, colorScheme.primary);
    });

    testWidgets('has correct button constraints', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIAssistButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.constraints, const BoxConstraints(
        minWidth: 24,
        minHeight: 24,
      ));
    });

    testWidgets('has zero padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIAssistButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.padding, EdgeInsets.zero);
    });

    testWidgets('shows tooltip on long press', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIAssistButton(
              onPressed: () {},
              tooltip: 'Test tooltip',
            ),
          ),
        ),
      );

      // Long press to show tooltip
      await tester.longPress(find.byType(IconButton));
      await tester.pump(const Duration(milliseconds: 10));

      // Tooltip should be visible
      expect(find.text('Test tooltip'), findsOneWidget);
    });
  });
}
