import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/queries/presentation/widgets/query_input_field.dart';

void main() {
  group('QueryInputField', () {
    late TextEditingController controller;
    late FocusNode focusNode;

    setUp(() {
      controller = TextEditingController();
      focusNode = FocusNode();
    });

    tearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('displays hint text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryInputField(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      );

      expect(find.text('Ask anything about your project...'), findsOneWidget);
    });

    testWidgets('displays psychology icon as prefix', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryInputField(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(QueryInputField),
          matching: find.byIcon(Icons.psychology_outlined),
        ),
        findsOneWidget,
      );
    });

    testWidgets('does not show suffix icons when text is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryInputField(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      );

      // No clear or send button when empty
      expect(find.byIcon(Icons.clear), findsNothing);
      expect(find.byIcon(Icons.send), findsNothing);
    });

    testWidgets('shows suffix icons when text is entered', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryInputField(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'Test query');
      await tester.pump();

      // Should show clear and send buttons
      expect(find.byIcon(Icons.clear), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('clear button clears text', (tester) async {
      bool onChangedCalled = false;
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryInputField(
              controller: controller,
              focusNode: focusNode,
              onChanged: (value) {
                onChangedCalled = true;
                changedValue = value;
              },
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'Test query');
      await tester.pump();

      // Reset flags
      onChangedCalled = false;
      changedValue = null;

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // Verify text is cleared
      expect(controller.text, isEmpty);
      expect(onChangedCalled, isTrue);
      expect(changedValue, '');
    });

    testWidgets('send button calls onSubmitted', (tester) async {
      bool onSubmittedCalled = false;
      String? submittedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryInputField(
              controller: controller,
              focusNode: focusNode,
              onSubmitted: (value) {
                onSubmittedCalled = true;
                submittedValue = value;
              },
            ),
          ),
        ),
      );

      // Enter text
      const testQuery = 'What are the action items?';
      await tester.enterText(find.byType(TextField), testQuery);
      await tester.pump();

      // Tap send button
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Verify callback
      expect(onSubmittedCalled, isTrue);
      expect(submittedValue, testQuery);
    });

    testWidgets('supports multiline input (up to 3 lines)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryInputField(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLines, 3);
      expect(textField.minLines, 1);
    });

    testWidgets('uses search text input action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryInputField(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.textInputAction, TextInputAction.search);
    });

    testWidgets('calls onSubmitted when pressing enter', (tester) async {
      bool onSubmittedCalled = false;
      String? submittedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryInputField(
              controller: controller,
              focusNode: focusNode,
              onSubmitted: (value) {
                onSubmittedCalled = true;
                submittedValue = value;
              },
            ),
          ),
        ),
      );

      // Enter text
      const testQuery = 'Show me risks';
      await tester.enterText(find.byType(TextField), testQuery);

      // Press enter (submit)
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      // Verify callback
      expect(onSubmittedCalled, isTrue);
      expect(submittedValue, testQuery);
    });

    testWidgets('disables field when enabled is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryInputField(
              controller: controller,
              focusNode: focusNode,
              enabled: false,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('disables send button when field is disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryInputField(
              controller: controller,
              focusNode: focusNode,
              enabled: false,
            ),
          ),
        ),
      );

      // Enter text (programmatically since field is disabled)
      controller.text = 'Test query';
      await tester.pump();

      // Send button should exist but be disabled
      final sendButton = tester.widget<IconButton>(
        find.descendant(
          of: find.byType(QueryInputField),
          matching: find.widgetWithIcon(IconButton, Icons.send),
        ),
      );

      expect(sendButton.onPressed, isNull);
    });

    testWidgets('calls onChanged when text changes', (tester) async {
      final changedValues = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryInputField(
              controller: controller,
              focusNode: focusNode,
              onChanged: (value) {
                changedValues.add(value);
              },
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pump();

      // Verify callback was called
      expect(changedValues, isNotEmpty);
      expect(changedValues.last, 'Test');
    });

    testWidgets('has rounded borders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryInputField(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      final decoration = textField.decoration!;
      final border = decoration.border as OutlineInputBorder;

      expect(border.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('has different border colors for different states', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryInputField(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      final decoration = textField.decoration!;

      // Should have enabled, focused, and disabled borders
      expect(decoration.enabledBorder, isNotNull);
      expect(decoration.focusedBorder, isNotNull);
      expect(decoration.disabledBorder, isNotNull);
    });
  });
}
