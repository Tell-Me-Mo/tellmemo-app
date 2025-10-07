import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/core/widgets/notifications/notification_toast.dart';
import 'package:pm_master_v2/core/models/notification_model.dart';

void main() {
  group('NotificationToast Widget', () {
    testWidgets('displays notification title', (tester) async {
      final notification = _createTestNotification(
        title: 'Test Title',
        message: 'Test message',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationToast(
              notification: notification,
              onDismiss: () {},
              animation: const AlwaysStoppedAnimation(1.0),
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('displays notification message when provided', (tester) async {
      final notification = _createTestNotification(
        title: 'Title',
        message: 'This is a test message',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationToast(
              notification: notification,
              onDismiss: () {},
              animation: const AlwaysStoppedAnimation(1.0),
            ),
          ),
        ),
      );

      expect(find.text('This is a test message'), findsOneWidget);
    });

    testWidgets('does not display message when null', (tester) async {
      final notification = _createTestNotification(
        title: 'Title',
        message: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationToast(
              notification: notification,
              onDismiss: () {},
              animation: const AlwaysStoppedAnimation(1.0),
            ),
          ),
        ),
      );

      expect(find.byType(Text), findsOneWidget); // Only title
    });

    testWidgets('displays icon when provided', (tester) async {
      final notification = _createTestNotification(
        title: 'Title',
        icon: Icons.check_circle,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationToast(
              notification: notification,
              onDismiss: () {},
              animation: const AlwaysStoppedAnimation(1.0),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays close button', (tester) async {
      final notification = _createTestNotification(title: 'Title');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationToast(
              notification: notification,
              onDismiss: () {},
              animation: const AlwaysStoppedAnimation(1.0),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('calls onDismiss when close button is tapped', (tester) async {
      final notification = _createTestNotification(title: 'Title');
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NotificationToast(
                notification: notification,
                onDismiss: () => dismissed = true,
                animation: const AlwaysStoppedAnimation(1.0),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('displays action button when actionLabel is provided', (tester) async {
      final notification = _createTestNotification(
        title: 'Title',
        actionLabel: 'View',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationToast(
              notification: notification,
              onDismiss: () {},
              animation: const AlwaysStoppedAnimation(1.0),
            ),
          ),
        ),
      );

      expect(find.text('View'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('calls onAction and onDismiss when action button is tapped', (tester) async {
      var actionCalled = false;
      var dismissed = false;

      final notification = _createTestNotification(
        title: 'Title',
        actionLabel: 'Action',
        onAction: () => actionCalled = true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NotificationToast(
                notification: notification,
                onDismiss: () => dismissed = true,
                animation: const AlwaysStoppedAnimation(1.0),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Action'));
      await tester.pumpAndSettle();

      expect(actionCalled, isTrue);
      expect(dismissed, isTrue);
    });

    testWidgets('displays avatar when avatarUrl is provided', (tester) async {
      final notification = _createTestNotification(
        title: 'Title',
        avatarUrl: 'https://example.com/avatar.png',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NotificationToast(
                notification: notification,
                onDismiss: () {},
                animation: const AlwaysStoppedAnimation(1.0),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('calls onAction when notification body is tapped (if provided)', (tester) async {
      var actionCalled = false;

      final notification = _createTestNotification(
        title: 'Title',
        message: 'Message',
        onAction: () => actionCalled = true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NotificationToast(
                notification: notification,
                onDismiss: () {},
                animation: const AlwaysStoppedAnimation(1.0),
              ),
            ),
          ),
        ),
      );

      // Tap on the title text instead of InkWell (which has multiple instances)
      await tester.tap(find.text('Title'));
      await tester.pump();

      expect(actionCalled, isTrue);
    });

    testWidgets('has correct constraints', (tester) async {
      final notification = _createTestNotification(title: 'Title');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationToast(
              notification: notification,
              onDismiss: () {},
              animation: const AlwaysStoppedAnimation(1.0),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(NotificationToast),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.constraints, isNotNull);
      expect(container.constraints!.minWidth, 300);
      expect(container.constraints!.maxWidth, 400);
    });
  });
}

AppNotification _createTestNotification({
  required String title,
  String? message,
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
  String? avatarUrl,
  String? imageUrl,
  NotificationType type = NotificationType.info,
  NotificationPosition position = NotificationPosition.topRight,
}) {
  return AppNotification(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: title,
    message: message,
    type: type,
    position: position,
    icon: icon,
    actionLabel: actionLabel,
    onAction: onAction,
    avatarUrl: avatarUrl,
    imageUrl: imageUrl,
  );
}
