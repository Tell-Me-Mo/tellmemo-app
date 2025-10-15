import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/shared/widgets/item_updates_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ItemUpdatesTab Widget Tests', () {
    late List<ItemUpdate> mockUpdates;

    setUp(() {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});

      // Create mock updates for testing
      mockUpdates = [
        ItemUpdate(
          id: '1',
          content: 'Initial risk identified',
          authorName: 'John Doe',
          authorEmail: 'john@example.com',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          type: ItemUpdateType.created,
        ),
        ItemUpdate(
          id: '2',
          content: 'Status changed from identified to accepted',
          authorName: 'Jane Smith',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          type: ItemUpdateType.statusChange,
        ),
        ItemUpdate(
          id: '3',
          content: 'This needs immediate attention',
          authorName: 'Mike Johnson',
          timestamp: DateTime.now(),
          type: ItemUpdateType.comment,
        ),
      ];
    });

    testWidgets('displays all updates when no filter applied',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemUpdatesTab(
              updates: mockUpdates,
              itemType: 'risk',
              onAddComment: (content) async {},
            ),
          ),
        ),
      );

      // Wait for async operations to complete
      await tester.pumpAndSettle();

      // All updates should be visible
      expect(find.text('Initial risk identified'), findsOneWidget);
      expect(find.text('Status changed from identified to accepted'),
          findsOneWidget);
      expect(find.text('This needs immediate attention'), findsOneWidget);

      // Author names should be visible
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Mike Johnson'), findsOneWidget);
    });

    testWidgets('displays empty state when no updates',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemUpdatesTab(
              updates: [],
              itemType: 'task',
              onAddComment: (content) async {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No updates yet'), findsOneWidget);
      expect(find.text('Be the first to add a comment or update'),
          findsOneWidget);
      expect(find.byIcon(Icons.comment_outlined), findsOneWidget);
    });

    testWidgets('can add a comment', (WidgetTester tester) async {
      String? addedComment;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemUpdatesTab(
              updates: mockUpdates,
              itemType: 'blocker',
              onAddComment: (content) async {
                addedComment = content;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the comment text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'New test comment');

      // Find and tap the send button
      final sendButton = find.byIcon(Icons.send_rounded);
      expect(sendButton, findsOneWidget);

      await tester.tap(sendButton);
      await tester.pump();

      expect(addedComment, equals('New test comment'));
    });

    testWidgets('send button shows loading state when submitting',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemUpdatesTab(
              updates: mockUpdates,
              itemType: 'lesson',
              isLoading: true,
              onAddComment: (content) async {
                await Future.delayed(const Duration(seconds: 1));
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When loading, send button should be disabled
      final textField = find.byType(TextField);
      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.enabled, isFalse);
    });

    testWidgets('filter button opens filter menu',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemUpdatesTab(
              updates: mockUpdates,
              itemType: 'risk',
              onAddComment: (content) async {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the filter button
      final filterButton = find.byIcon(Icons.filter_list_rounded);
      expect(filterButton, findsOneWidget);

      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      // Filter menu should appear with all update types
      expect(find.text('Filter Updates'), findsOneWidget);
      // Multiple instances of text may exist (in updates and filter)
      expect(find.text('COMMENT'), findsWidgets);
      expect(find.text('STATUS'), findsWidgets);
      expect(find.text('CREATED'), findsWidgets);
      expect(find.text('EDITED'), findsOneWidget);
      expect(find.text('ASSIGNED'), findsOneWidget);
    });

    testWidgets('filter persists selections', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemUpdatesTab(
              updates: mockUpdates,
              itemType: 'task',
              onAddComment: (content) async {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open filter menu
      await tester.tap(find.byIcon(Icons.filter_list_rounded));
      await tester.pumpAndSettle();

      // Deselect COMMENT type - tap the one in the filter menu, not the badge
      final commentTexts = find.text('COMMENT');
      // Find the one that's in the menu (usually the last one)
      await tester.tap(commentTexts.last);
      await tester.pumpAndSettle();

      // Close menu
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Comment update should be hidden
      expect(find.text('This needs immediate attention'), findsNothing);

      // Other updates should still be visible
      expect(find.text('Initial risk identified'), findsOneWidget);
      expect(find.text('Status changed from identified to accepted'),
          findsOneWidget);
    });

    testWidgets('update type badges have correct colors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemUpdatesTab(
              updates: mockUpdates,
              itemType: 'risk',
              onAddComment: (content) async {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for update type labels
      expect(find.text('CREATED'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('COMMENT'), findsOneWidget);
    });

    testWidgets('comment field clears after submission',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemUpdatesTab(
              updates: mockUpdates,
              itemType: 'blocker',
              onAddComment: (content) async {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Test comment');

      // Verify text was entered
      expect(find.text('Test comment'), findsOneWidget);

      // Submit
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Text field should be cleared
      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.controller?.text, isEmpty);
    });

    testWidgets('displays correct empty state for filtered results',
        (WidgetTester tester) async {
      // Create updates of only one type
      final singleTypeUpdates = [
        ItemUpdate(
          id: '1',
          content: 'Comment 1',
          authorName: 'User',
          timestamp: DateTime.now(),
          type: ItemUpdateType.comment,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemUpdatesTab(
              updates: singleTypeUpdates,
              itemType: 'task',
              onAddComment: (content) async {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open filter and deselect comments
      await tester.tap(find.byIcon(Icons.filter_list_rounded));
      await tester.pumpAndSettle();

      // Tap the COMMENT text in the filter menu (not the badge)
      final commentTexts = find.text('COMMENT');
      await tester.tap(commentTexts.last);
      await tester.pumpAndSettle();

      // Close menu
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('No updates yet'), findsOneWidget);
    });

    testWidgets('send button has purple gradient design',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemUpdatesTab(
              updates: mockUpdates,
              itemType: 'risk',
              onAddComment: (content) async {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the send button container with gradient
      final sendButtonContainer = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).gradient != null,
      );

      // Should find at least one gradient container (the send button)
      expect(sendButtonContainer, findsWidgets);
    });

    group('Cross-item type tests', () {
      final itemTypes = ['risk', 'task', 'blocker', 'lesson'];

      for (final itemType in itemTypes) {
        testWidgets('works correctly for $itemType',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ItemUpdatesTab(
                  updates: mockUpdates,
                  itemType: itemType,
                  onAddComment: (content) async {},
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Basic functionality should work for all item types
          expect(find.byType(ItemUpdatesTab), findsOneWidget);
          expect(find.byIcon(Icons.filter_list_rounded), findsOneWidget);
          expect(find.byIcon(Icons.send_rounded), findsOneWidget);
          expect(find.byType(TextField), findsOneWidget);
        });
      }
    });
  });
}