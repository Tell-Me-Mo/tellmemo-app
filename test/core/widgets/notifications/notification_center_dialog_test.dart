import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/core/widgets/notifications/notification_center_dialog.dart';
import 'package:pm_master_v2/core/services/notification_service.dart';

void main() {
  group('NotificationCenterDialog Widget', () {
    // Helper to create widget with proper size for non-narrow layout
    // Dialog width = screenSize.width * 0.35
    // Need content width >= 360px for wide mode: dialog width >= 392px
    // So: screenSize.width * 0.35 >= 392, screenSize.width >= 1120
    Widget buildTestWidget(NotificationService service) {
      return ProviderScope(
        overrides: [
          notificationServiceProvider.overrideWith((ref) => service),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: const MediaQueryData(size: Size(1400, 900)),
              child: const NotificationCenterDialog(),
            ),
          ),
        ),
      );
    }

    testWidgets('displays "Notifications" title', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(buildTestWidget(service));

      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('displays close button in header', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(buildTestWidget(service));

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('displays empty state when no notifications exist', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(buildTestWidget(service));

      expect(find.text('No notifications'), findsOneWidget);
      expect(find.text('You\'re all caught up!'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    });

    testWidgets('displays "Mark all read" button when there are unread notifications', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(buildTestWidget(service));

      // Add an unread notification
      service.show(title: 'Test', showInCenter: true, showAsToast: false);
      await tester.pump();

      expect(find.text('Mark all read'), findsOneWidget);
    });

    testWidgets('displays "Clear all" button when notifications exist', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(buildTestWidget(service));

      service.show(title: 'Test', showInCenter: true, showAsToast: false);
      await tester.pump();

      expect(find.text('Clear all'), findsOneWidget);
    });

    testWidgets('displays unread count badge when there are unread notifications', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(buildTestWidget(service));

      service.show(title: 'Test 1', showInCenter: true, showAsToast: false, persistent: true);
      service.show(title: 'Test 2', showInCenter: true, showAsToast: false, persistent: true);
      await tester.pump();

      expect(find.text('2 new'), findsOneWidget);
    });

    testWidgets('displays filter toggle (All/Unread)', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(buildTestWidget(service));

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.byType(SegmentedButton<bool>), findsOneWidget);
    });

    testWidgets('marks all notifications as read when "Mark all read" is tapped', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(buildTestWidget(service));

      service.show(title: 'Test', showInCenter: true, showAsToast: false);
      await tester.pump();

      expect(service.state.unreadCount, 1);

      await tester.tap(find.text('Mark all read'));
      await tester.pump();

      expect(service.state.unreadCount, 0);
    });

    testWidgets('clears all notifications when "Clear all" is tapped', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(buildTestWidget(service));

      service.show(title: 'Test', showInCenter: true, showAsToast: false);
      await tester.pump();

      expect(service.state.active.length, 1);

      await tester.tap(find.text('Clear all'));
      await tester.pump();

      expect(service.state.active.length, 0);
      expect(service.state.history.length, 0);
    });

    testWidgets('displays notification in list when added', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(buildTestWidget(service));

      service.show(
        title: 'Test Notification',
        message: 'Test message',
        showInCenter: true,
        showAsToast: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Notification'), findsOneWidget);
      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('marks notification as read when tapped', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(buildTestWidget(service));

      service.show(
        title: 'Test Notification',
        showInCenter: true,
        showAsToast: false,
      );
      await tester.pumpAndSettle();

      expect(service.state.unreadCount, 1);

      // Tap on the notification card
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      expect(service.state.unreadCount, 0);
    });

    testWidgets('displays "IMPORTANT" section for persistent notifications', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(buildTestWidget(service));

      service.show(
        title: 'Important',
        persistent: true,
        showInCenter: true,
        showAsToast: false,
      );
      await tester.pump();

      expect(find.text('IMPORTANT'), findsOneWidget);
    });

    testWidgets('displays "RECENT" section for non-persistent notifications', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(buildTestWidget(service));

      // Add a persistent notification first (to create the IMPORTANT section)
      service.show(title: 'Important', persistent: true, showInCenter: true, showAsToast: false);
      // Then add non-persistent (to create the RECENT section)
      service.show(title: 'Recent', persistent: false, showInCenter: true, showAsToast: false);
      await tester.pumpAndSettle();

      expect(find.text('RECENT'), findsOneWidget);
    });

    testWidgets('filters to show only unread notifications when "Unread" is selected', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(buildTestWidget(service));

      // Add both read and unread notifications (persistent to avoid timer issues)
      final id1 = service.show(title: 'Unread Notification', showInCenter: true, showAsToast: false, persistent: true);
      final id2 = service.show(title: 'Read Notification', showInCenter: true, showAsToast: false, persistent: true);
      await tester.pump(); // Initial pump to start processing queue
      await tester.pump(); // Second pump to complete queue processing
      await tester.pump(); // Final pump to update UI

      // Debug: Verify both notifications are in the active list
      expect(service.state.active.length, 2, reason: 'Should have 2 active notifications');
      expect(service.state.persistentNotifications.length, 2, reason: 'Should have 2 persistent notifications');

      // Mark one as read
      service.markAsRead(id2);
      await tester.pump(); // Pump to update UI after marking as read

      // Debug: Verify both notifications are still in the active list after marking as read
      expect(service.state.active.length, 2, reason: 'Should still have 2 active notifications after marking as read');
      expect(service.state.persistentNotifications.length, 2, reason: 'Should still have 2 persistent notifications after marking as read');
      expect(service.state.unreadCount, 1, reason: 'Should have 1 unread notification');

      // Should show both initially (using findsWidgets since text may appear multiple times in widget tree)
      expect(find.text('Unread Notification'), findsWidgets);
      expect(find.text('Read Notification'), findsWidgets);

      // Tap "Unread" filter - find by icon since text appears multiple times
      await tester.tap(find.byIcon(Icons.markunread));
      await tester.pump();

      // Should only show unread (using findsWidgets since text may appear multiple times in widget tree)
      expect(find.text('Unread Notification'), findsWidgets);
      expect(find.text('Read Notification'), findsNothing);
    });

    testWidgets('shows empty state message when filtering to unread with no unread notifications', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(buildTestWidget(service));

      // Add a persistent notification and mark it as read
      final id = service.show(title: 'Read', showInCenter: true, showAsToast: false, persistent: true);
      await tester.pump();
      service.markAsRead(id);
      await tester.pump();

      // Tap "Unread" filter
      await tester.tap(find.text('Unread'));
      await tester.pump();

      expect(find.text('No unread notifications'), findsOneWidget);
      expect(find.text('All notifications have been read'), findsOneWidget);
    });
  });
}
