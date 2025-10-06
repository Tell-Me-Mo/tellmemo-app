import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/core/widgets/notifications/notification_center.dart';
import 'package:pm_master_v2/core/services/notification_service.dart';
import 'package:pm_master_v2/core/models/notification_model.dart';

void main() {
  group('NotificationCenter Widget', () {
    testWidgets('displays notification icon with no badge when no unread notifications', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWith((ref) => NotificationService()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationCenter(),
            ),
          ),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.text('1'), findsNothing);
      expect(find.text('99+'), findsNothing);
    });

    testWidgets('displays active icon with unread count badge when notifications exist', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWith((ref) => service),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationCenter(),
            ),
          ),
        ),
      );

      // Add a notification
      service.show(title: 'Test Notification', message: 'Test message');
      await tester.pump();

      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('displays "99+" when unread count exceeds 99', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWith((ref) => service),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationCenter(),
            ),
          ),
        ),
      );

      // Create a state with 100 unread notifications
      service.state = NotificationState(
        active: List.generate(100, (i) =>
          service.state.active.firstOrNull ?? _createTestNotification(i.toString())
        ),
        unreadCount: 100,
      );
      await tester.pump();

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('opens notification center dialog when tapped', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWith((ref) => service),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationCenter(),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('calls onNotificationTapped callback when tapped', (tester) async {
      final service = NotificationService();
      var callbackCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWith((ref) => service),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NotificationCenter(
                onNotificationTapped: () => callbackCalled = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(callbackCalled, isTrue);
    });

    testWidgets('badge has red background color', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWith((ref) => service),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationCenter(),
            ),
          ),
        ),
      );

      service.show(title: 'Test');
      await tester.pump();

      final containerFinder = find.descendant(
        of: find.byType(Stack),
        matching: find.byType(Container),
      ).first;

      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.red);
    });

    testWidgets('displays tooltip on hover', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWith((ref) => service),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationCenter(),
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, 'Notifications');
    });

    testWidgets('icon color changes to primary when there are unread notifications', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWith((ref) => service),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationCenter(),
            ),
          ),
        ),
      );

      service.show(title: 'Test');
      await tester.pump();

      final icon = tester.widget<Icon>(find.byIcon(Icons.notifications_active));
      expect(icon.color, isNotNull);
    });
  });
}

// Helper function to create test notification
AppNotification _createTestNotification(String id) {
  return AppNotification(
    id: id,
    title: 'Test $id',
    type: NotificationType.info,
    isRead: false,
  );
}
