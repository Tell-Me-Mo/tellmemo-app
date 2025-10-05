import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/organizations/presentation/widgets/invitation_notifications_widget.dart';
import 'package:pm_master_v2/features/organizations/presentation/providers/invitation_notifications_provider.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  group('InvitationNotificationsWidget Widget Tests', () {
    testWidgets('renders notification bell icon', (WidgetTester tester) async {
      // Arrange
      final mockNotifications = InvitationNotificationState(notifications: []);

      // Act
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          appBar: AppBar(
            actions: [InvitationNotificationsWidget()],
          ),
        ),
        overrides: [
          invitationNotificationsProvider.overrideWith(
            (ref) => InvitationNotificationsNotifier(ref)..state = mockNotifications,
          ),
        ],
      );

      // Assert
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('shows active bell icon when there are unread notifications',
        (WidgetTester tester) async {
      // Arrange
      final mockNotifications = InvitationNotificationState(
        notifications: [
          InvitationNotification(
            id: '1',
            userName: 'John Doe',
            userEmail: 'john@test.com',
            organizationId: 'org-1',
            acceptedAt: DateTime.now(),
            isRead: false,
          ),
        ],
      );

      // Act
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          appBar: AppBar(
            actions: [InvitationNotificationsWidget()],
          ),
        ),
        overrides: [
          invitationNotificationsProvider.overrideWith(
            (ref) => InvitationNotificationsNotifier(ref)..state = mockNotifications,
          ),
        ],
      );

      // Assert
      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    });

    testWidgets('displays unread notification badge when there are unread notifications',
        (WidgetTester tester) async {
      // Arrange
      final mockNotifications = InvitationNotificationState(
        notifications: [
          InvitationNotification(
            id: '1',
            userName: 'John Doe',
            userEmail: 'john@test.com',
            organizationId: 'org-1',
            acceptedAt: DateTime.now(),
            isRead: false,
          ),
        ],
      );

      // Act
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          appBar: AppBar(
            actions: [InvitationNotificationsWidget()],
          ),
        ),
        overrides: [
          invitationNotificationsProvider.overrideWith(
            (ref) => InvitationNotificationsNotifier(ref)..state = mockNotifications,
          ),
        ],
      );

      // Assert
      expect(find.byType(Stack), findsWidgets);
      // Red badge should be visible
      final container = find.byType(Container).evaluate().where(
        (element) {
          final widget = element.widget as Container;
          return widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == Colors.red;
        },
      );
      expect(container, isNotEmpty);
    });

    testWidgets('shows empty state when no notifications',
        (WidgetTester tester) async {
      // Arrange
      final mockNotifications = InvitationNotificationState(notifications: []);

      // Act
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          appBar: AppBar(
            actions: [InvitationNotificationsWidget()],
          ),
        ),
        overrides: [
          invitationNotificationsProvider.overrideWith(
            (ref) => InvitationNotificationsNotifier(ref)..state = mockNotifications,
          ),
        ],
      );

      // Tap to open menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No notifications'), findsOneWidget);
    });

    testWidgets('displays notification list when there are notifications',
        (WidgetTester tester) async {
      // Arrange
      final mockNotifications = InvitationNotificationState(
        notifications: [
          InvitationNotification(
            id: '1',
            userName: 'John Doe',
            userEmail: 'john@test.com',
            organizationId: 'org-1',
            acceptedAt: DateTime.now().subtract(const Duration(minutes: 5)),
            isRead: false,
          ),
          InvitationNotification(
            id: '2',
            userName: 'Jane Smith',
            userEmail: 'jane@test.com',
            organizationId: 'org-1',
            acceptedAt: DateTime.now().subtract(const Duration(hours: 2)),
            isRead: true,
          ),
        ],
      );

      // Act
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          appBar: AppBar(
            actions: [InvitationNotificationsWidget()],
          ),
        ),
        overrides: [
          invitationNotificationsProvider.overrideWith(
            (ref) => InvitationNotificationsNotifier(ref)..state = mockNotifications,
          ),
        ],
      );

      // Tap to open menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Invitation Notifications'), findsOneWidget);
      expect(find.text('John Doe accepted'), findsOneWidget);
      expect(find.text('john@test.com'), findsOneWidget);
      expect(find.text('Jane Smith accepted'), findsOneWidget);
      expect(find.text('jane@test.com'), findsOneWidget);
    });

    testWidgets('displays unread count badge in header',
        (WidgetTester tester) async {
      // Arrange
      final mockNotifications = InvitationNotificationState(
        notifications: [
          InvitationNotification(
            id: '1',
            userName: 'John Doe',
            userEmail: 'john@test.com',
            organizationId: 'org-1',
            acceptedAt: DateTime.now(),
            isRead: false,
          ),
          InvitationNotification(
            id: '2',
            userName: 'Jane Smith',
            userEmail: 'jane@test.com',
            organizationId: 'org-1',
            acceptedAt: DateTime.now(),
            isRead: false,
          ),
          InvitationNotification(
            id: '3',
            userName: 'Bob Johnson',
            userEmail: 'bob@test.com',
            organizationId: 'org-1',
            acceptedAt: DateTime.now(),
            isRead: true,
          ),
        ],
      );

      // Act
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          appBar: AppBar(
            actions: [InvitationNotificationsWidget()],
          ),
        ),
        overrides: [
          invitationNotificationsProvider.overrideWith(
            (ref) => InvitationNotificationsNotifier(ref)..state = mockNotifications,
          ),
        ],
      );

      // Tap to open menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Assert - Should show count of 2 unread notifications
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('shows mark all as read and clear all actions',
        (WidgetTester tester) async {
      // Arrange
      final mockNotifications = InvitationNotificationState(
        notifications: [
          InvitationNotification(
            id: '1',
            userName: 'John Doe',
            userEmail: 'john@test.com',
            organizationId: 'org-1',
            acceptedAt: DateTime.now(),
            isRead: false,
          ),
        ],
      );

      // Act
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          appBar: AppBar(
            actions: [InvitationNotificationsWidget()],
          ),
        ),
        overrides: [
          invitationNotificationsProvider.overrideWith(
            (ref) => InvitationNotificationsNotifier(ref)..state = mockNotifications,
          ),
        ],
      );

      // Tap to open menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Mark all as read'), findsOneWidget);
      expect(find.text('Clear all'), findsOneWidget);
      expect(find.byIcon(Icons.done_all), findsOneWidget);
      expect(find.byIcon(Icons.clear_all), findsOneWidget);
    });

    testWidgets('displays correct time format for notifications',
        (WidgetTester tester) async {
      // Arrange
      final now = DateTime.now();
      final mockNotifications = InvitationNotificationState(
        notifications: [
          InvitationNotification(
            id: '1',
            userName: 'Just Now User',
            userEmail: 'justnow@test.com',
            organizationId: 'org-1',
            acceptedAt: now,
            isRead: false,
          ),
          InvitationNotification(
            id: '2',
            userName: 'Minutes Ago User',
            userEmail: 'minutes@test.com',
            organizationId: 'org-1',
            acceptedAt: now.subtract(const Duration(minutes: 30)),
            isRead: false,
          ),
          InvitationNotification(
            id: '3',
            userName: 'Hours Ago User',
            userEmail: 'hours@test.com',
            organizationId: 'org-1',
            acceptedAt: now.subtract(const Duration(hours: 3)),
            isRead: false,
          ),
          InvitationNotification(
            id: '4',
            userName: 'Yesterday User',
            userEmail: 'yesterday@test.com',
            organizationId: 'org-1',
            acceptedAt: now.subtract(const Duration(days: 1)),
            isRead: false,
          ),
        ],
      );

      // Act
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          appBar: AppBar(
            actions: [InvitationNotificationsWidget()],
          ),
        ),
        overrides: [
          invitationNotificationsProvider.overrideWith(
            (ref) => InvitationNotificationsNotifier(ref)..state = mockNotifications,
          ),
        ],
      );

      // Tap to open menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Assert - Check time formatting
      expect(find.text('Just now'), findsOneWidget);
      expect(find.textContaining('min ago'), findsOneWidget);
      expect(find.textContaining('hour'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
    });

    testWidgets('shows blue dot indicator for unread notifications',
        (WidgetTester tester) async {
      // Arrange
      final mockNotifications = InvitationNotificationState(
        notifications: [
          InvitationNotification(
            id: '1',
            userName: 'Unread User',
            userEmail: 'unread@test.com',
            organizationId: 'org-1',
            acceptedAt: DateTime.now(),
            isRead: false,
          ),
          InvitationNotification(
            id: '2',
            userName: 'Read User',
            userEmail: 'read@test.com',
            organizationId: 'org-1',
            acceptedAt: DateTime.now(),
            isRead: true,
          ),
        ],
      );

      // Act
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          appBar: AppBar(
            actions: [InvitationNotificationsWidget()],
          ),
        ),
        overrides: [
          invitationNotificationsProvider.overrideWith(
            (ref) => InvitationNotificationsNotifier(ref)..state = mockNotifications,
          ),
        ],
      );

      // Tap to open menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Assert - Find blue dot for unread notifications
      final blueDots = find.byType(Container).evaluate().where(
        (element) {
          final widget = element.widget as Container;
          return widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == Colors.blue &&
              (widget.decoration as BoxDecoration).shape == BoxShape.circle;
        },
      );
      expect(blueDots.length, 1); // Only one unread notification
    });

    testWidgets('limits notifications display to 5 items',
        (WidgetTester tester) async {
      // Arrange
      final mockNotifications = InvitationNotificationState(
        notifications: List.generate(
          10,
          (index) => InvitationNotification(
            id: '$index',
            userName: 'User $index',
            userEmail: 'user$index@test.com',
            organizationId: 'org-1',
            acceptedAt: DateTime.now(),
            isRead: false,
          ),
        ),
      );

      // Act
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          appBar: AppBar(
            actions: [InvitationNotificationsWidget()],
          ),
        ),
        overrides: [
          invitationNotificationsProvider.overrideWith(
            (ref) => InvitationNotificationsNotifier(ref)..state = mockNotifications,
          ),
        ],
      );

      // Tap to open menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Assert - Should only show first 5
      expect(find.text('User 0 accepted'), findsOneWidget);
      expect(find.text('User 4 accepted'), findsOneWidget);
      expect(find.text('User 9 accepted'), findsNothing); // Should not show beyond 5
    });

    testWidgets('has correct tooltip', (WidgetTester tester) async {
      // Arrange
      final mockNotifications = InvitationNotificationState(notifications: []);

      // Act
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          appBar: AppBar(
            actions: [InvitationNotificationsWidget()],
          ),
        ),
        overrides: [
          invitationNotificationsProvider.overrideWith(
            (ref) => InvitationNotificationsNotifier(ref)..state = mockNotifications,
          ),
        ],
      );

      // Assert
      final popupButton = tester.widget<PopupMenuButton<String>>(
        find.byType(PopupMenuButton<String>),
      );
      expect(popupButton.tooltip, 'Invitation Notifications');
    });

    testWidgets('callback is triggered when notification is tapped',
        (WidgetTester tester) async {
      // Arrange
      bool callbackCalled = false;
      final mockNotifications = InvitationNotificationState(
        notifications: [
          InvitationNotification(
            id: '1',
            userName: 'John Doe',
            userEmail: 'john@test.com',
            organizationId: 'org-1',
            acceptedAt: DateTime.now(),
            isRead: false,
          ),
        ],
      );

      // Act
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          appBar: AppBar(
            actions: [
              InvitationNotificationsWidget(
                onNotificationTapped: () {
                  callbackCalled = true;
                },
              ),
            ],
          ),
        ),
        overrides: [
          invitationNotificationsProvider.overrideWith(
            (ref) => InvitationNotificationsNotifier(ref)..state = mockNotifications,
          ),
        ],
      );

      // Tap to open menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap on notification
      await tester.tap(find.text('John Doe accepted'));
      await tester.pumpAndSettle();

      // Assert
      expect(callbackCalled, true);
    });
  });
}
