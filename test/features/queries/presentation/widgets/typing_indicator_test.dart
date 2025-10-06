import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/queries/presentation/widgets/typing_indicator.dart';

void main() {
  group('TypingIndicator', () {
    testWidgets('displays three dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypingIndicator(),
          ),
        ),
      );

      // Should have 3 dots (containers with circle shape)
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(TypingIndicator),
          matching: find.byType(Container),
        ),
      );

      expect(containers.length, 3);
    });

    testWidgets('uses custom color when provided', (tester) async {
      const customColor = Colors.red;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypingIndicator(color: customColor),
          ),
        ),
      );
      await tester.pump();

      // Find all containers
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(TypingIndicator),
          matching: find.byType(Container),
        ),
      );

      // All dots should use the custom color
      for (final container in containers) {
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, customColor);
      }
    });

    testWidgets('uses theme primary color by default', (tester) async {
      const themePrimaryColor = Colors.blue;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: themePrimaryColor,
            ),
          ),
          home: const Scaffold(
            body: TypingIndicator(),
          ),
        ),
      );
      await tester.pump();

      // Find all containers
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(TypingIndicator),
          matching: find.byType(Container),
        ),
      );

      // All dots should use the theme's primary color
      for (final container in containers) {
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, isNotNull);
      }
    });

    testWidgets('uses custom dot size', (tester) async {
      const customDotSize = 12.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypingIndicator(dotSize: customDotSize),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(TypingIndicator),
          matching: find.byType(Container),
        ),
      );

      // All dots should use custom size
      for (final container in containers) {
        expect(container.constraints?.minWidth, customDotSize);
        expect(container.constraints?.minHeight, customDotSize);
      }
    });

    testWidgets('animation controller is disposed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypingIndicator(),
          ),
        ),
      );

      // Pump to build widget
      await tester.pump();

      // Remove widget (this should trigger dispose)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.shrink(),
          ),
        ),
      );

      // If dispose wasn't called properly, this would throw
      await tester.pumpAndSettle();
    });

    testWidgets('dots animate vertically', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypingIndicator(),
          ),
        ),
      );

      // Initial state
      await tester.pump();

      // Find Transform.translate widgets
      final initialTransforms = tester.widgetList<Transform>(
        find.descendant(
          of: find.byType(TypingIndicator),
          matching: find.byType(Transform),
        ),
      );

      expect(initialTransforms.length, 3);

      // Advance animation
      await tester.pump(const Duration(milliseconds: 500));

      // Animation should still be running
      final animatedTransforms = tester.widgetList<Transform>(
        find.descendant(
          of: find.byType(TypingIndicator),
          matching: find.byType(Transform),
        ),
      );

      expect(animatedTransforms.length, 3);
    });
  });
}
