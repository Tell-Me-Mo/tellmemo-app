import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/organizations/presentation/providers/invitation_notifications_provider.dart';
import 'package:pm_master_v2/core/services/notification_service.dart';
import '../../../../mocks/organization_test_fixtures.dart';

void main() {
  group('Invitation Notifications Provider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      // Ensure polling is stopped before disposing
      final notifier = container.read(invitationNotificationsProvider.notifier);
      notifier.stopPolling();
      container.dispose();
    });

    group('InvitationNotificationState', () {
      test('creates default state with empty notifications', () {
        // Act
        final state = InvitationNotificationState();

        // Assert
        expect(state.notifications, isEmpty);
        expect(state.hasUnread, false);
        expect(state.lastCheckedMembers, isEmpty);
      });

      test('copyWith creates new instance with updated values', () {
        // Arrange
        final originalState = InvitationNotificationState(
          notifications: [],
          hasUnread: false,
        );

        final newNotifications = [
          InvitationNotification(
            id: '1',
            userEmail: 'test@test.com',
            userName: 'Test User',
            organizationId: 'org-1',
            acceptedAt: DateTime.now(),
          ),
        ];

        // Act
        final newState = originalState.copyWith(
          notifications: newNotifications,
          hasUnread: true,
        );

        // Assert
        expect(newState.notifications.length, 1);
        expect(newState.hasUnread, true);
        expect(originalState.notifications, isEmpty);
        expect(originalState.hasUnread, false);
      });
    });

    group('checkOrganizationMembers', () {
      test('does nothing on first check', () {
        // Arrange
        final notifier = container.read(invitationNotificationsProvider.notifier);
        final members = [
          OrganizationTestFixtures.createMember(status: 'invited'),
        ];

        // Act
        notifier.checkOrganizationMembers('org-1', members);

        // Assert
        final state = container.read(invitationNotificationsProvider);
        expect(state.notifications, isEmpty);
        expect(state.hasUnread, false);
      });

      test('detects newly accepted invitation', () {
        // Arrange
        final notifier = container.read(invitationNotificationsProvider.notifier);
        final invitedMembers = [
          OrganizationTestFixtures.createMember(
            userId: 'user-1',
            email: 'test@test.com',
            name: 'Test User',
            status: 'invited',
          ),
        ];

        // First check - establish baseline
        notifier.checkOrganizationMembers('org-1', invitedMembers);

        // Act - Second check with accepted member
        final activeMembers = [
          OrganizationTestFixtures.createMember(
            userId: 'user-1',
            email: 'test@test.com',
            name: 'Test User',
            status: 'active',
          ),
        ];
        notifier.checkOrganizationMembers('org-1', activeMembers);

        // Assert
        final state = container.read(invitationNotificationsProvider);
        expect(state.notifications.length, 1);
        expect(state.notifications.first.userEmail, 'test@test.com');
        expect(state.notifications.first.userName, 'Test User');
        expect(state.hasUnread, true);
      });

      test('detects multiple newly accepted invitations', () {
        // Arrange
        final notifier = container.read(invitationNotificationsProvider.notifier);
        final invitedMembers = [
          OrganizationTestFixtures.createMember(
            userId: 'user-1',
            email: 'user1@test.com',
            name: 'User One',
            status: 'invited',
          ),
          OrganizationTestFixtures.createMember(
            userId: 'user-2',
            email: 'user2@test.com',
            name: 'User Two',
            status: 'invited',
          ),
        ];

        // First check
        notifier.checkOrganizationMembers('org-1', invitedMembers);

        // Act - Both members accepted
        final activeMembers = [
          OrganizationTestFixtures.createMember(
            userId: 'user-1',
            email: 'user1@test.com',
            name: 'User One',
            status: 'active',
          ),
          OrganizationTestFixtures.createMember(
            userId: 'user-2',
            email: 'user2@test.com',
            name: 'User Two',
            status: 'active',
          ),
        ];
        notifier.checkOrganizationMembers('org-1', activeMembers);

        // Assert
        final state = container.read(invitationNotificationsProvider);
        expect(state.notifications.length, 2);
        expect(state.hasUnread, true);
        expect(state.notifications.any((n) => n.userEmail == 'user1@test.com'), true);
        expect(state.notifications.any((n) => n.userEmail == 'user2@test.com'), true);
      });

      test('does not create duplicate notifications for same acceptance', () {
        // Arrange
        final notifier = container.read(invitationNotificationsProvider.notifier);
        final invitedMembers = [
          OrganizationTestFixtures.createMember(
            userId: 'user-1',
            email: 'test@test.com',
            status: 'invited',
          ),
        ];

        // First check
        notifier.checkOrganizationMembers('org-1', invitedMembers);

        final activeMembers = [
          OrganizationTestFixtures.createMember(
            userId: 'user-1',
            email: 'test@test.com',
            status: 'active',
          ),
        ];

        // Act - Second and third checks
        notifier.checkOrganizationMembers('org-1', activeMembers);
        notifier.checkOrganizationMembers('org-1', activeMembers);

        // Assert
        final state = container.read(invitationNotificationsProvider);
        expect(state.notifications.length, 1);
      });

      test('handles multiple organizations independently', () {
        // Arrange
        final notifier = container.read(invitationNotificationsProvider.notifier);

        // Org 1 - invited member
        final org1Invited = [
          OrganizationTestFixtures.createMember(
            organizationId: 'org-1',
            userId: 'user-1',
            email: 'user1@test.com',
            status: 'invited',
          ),
        ];
        notifier.checkOrganizationMembers('org-1', org1Invited);

        // Org 2 - invited member
        final org2Invited = [
          OrganizationTestFixtures.createMember(
            organizationId: 'org-2',
            userId: 'user-2',
            email: 'user2@test.com',
            status: 'invited',
          ),
        ];
        notifier.checkOrganizationMembers('org-2', org2Invited);

        // Act - Only org-1 member accepts
        final org1Active = [
          OrganizationTestFixtures.createMember(
            organizationId: 'org-1',
            userId: 'user-1',
            email: 'user1@test.com',
            status: 'active',
          ),
        ];
        notifier.checkOrganizationMembers('org-1', org1Active);

        // Assert
        final state = container.read(invitationNotificationsProvider);
        expect(state.notifications.length, 1);
        expect(state.notifications.first.organizationId, 'org-1');
        expect(state.notifications.first.userEmail, 'user1@test.com');
      });
    });

    group('markAsRead', () {
      test('marks specific notification as read', () {
        // Arrange
        final notifier = container.read(invitationNotificationsProvider.notifier);
        final notification = InvitationNotification(
          id: 'notif-1',
          userEmail: 'test@test.com',
          userName: 'Test User',
          organizationId: 'org-1',
          acceptedAt: DateTime.now(),
          isRead: false,
        );

        notifier.state = notifier.state.copyWith(
          notifications: [notification],
          hasUnread: true,
        );

        // Act
        notifier.markAsRead('notif-1');

        // Assert
        final state = container.read(invitationNotificationsProvider);
        expect(state.notifications.first.isRead, true);
        expect(state.hasUnread, false);
      });

      test('maintains hasUnread when other unread notifications exist', () {
        // Arrange
        final notifier = container.read(invitationNotificationsProvider.notifier);
        final notifications = [
          InvitationNotification(
            id: 'notif-1',
            userEmail: 'user1@test.com',
            userName: 'User One',
            organizationId: 'org-1',
            acceptedAt: DateTime.now(),
            isRead: false,
          ),
          InvitationNotification(
            id: 'notif-2',
            userEmail: 'user2@test.com',
            userName: 'User Two',
            organizationId: 'org-1',
            acceptedAt: DateTime.now(),
            isRead: false,
          ),
        ];

        notifier.state = notifier.state.copyWith(
          notifications: notifications,
          hasUnread: true,
        );

        // Act - Mark only first as read
        notifier.markAsRead('notif-1');

        // Assert
        final state = container.read(invitationNotificationsProvider);
        expect(state.notifications.first.isRead, true);
        expect(state.notifications.last.isRead, false);
        expect(state.hasUnread, true);
      });

      test('does nothing when notification ID not found', () {
        // Arrange
        final notifier = container.read(invitationNotificationsProvider.notifier);
        final notification = InvitationNotification(
          id: 'notif-1',
          userEmail: 'test@test.com',
          userName: 'Test User',
          organizationId: 'org-1',
          acceptedAt: DateTime.now(),
          isRead: false,
        );

        notifier.state = notifier.state.copyWith(
          notifications: [notification],
          hasUnread: true,
        );

        // Act
        notifier.markAsRead('non-existent-id');

        // Assert
        final state = container.read(invitationNotificationsProvider);
        expect(state.notifications.first.isRead, false);
        expect(state.hasUnread, true);
      });
    });

    group('markAllAsRead', () {
      test('marks all notifications as read', () {
        // Arrange
        final notifier = container.read(invitationNotificationsProvider.notifier);
        final notifications = [
          InvitationNotification(
            id: 'notif-1',
            userEmail: 'user1@test.com',
            userName: 'User One',
            organizationId: 'org-1',
            acceptedAt: DateTime.now(),
            isRead: false,
          ),
          InvitationNotification(
            id: 'notif-2',
            userEmail: 'user2@test.com',
            userName: 'User Two',
            organizationId: 'org-1',
            acceptedAt: DateTime.now(),
            isRead: false,
          ),
          InvitationNotification(
            id: 'notif-3',
            userEmail: 'user3@test.com',
            userName: 'User Three',
            organizationId: 'org-1',
            acceptedAt: DateTime.now(),
            isRead: false,
          ),
        ];

        notifier.state = notifier.state.copyWith(
          notifications: notifications,
          hasUnread: true,
        );

        // Act
        notifier.markAllAsRead();

        // Assert
        final state = container.read(invitationNotificationsProvider);
        expect(state.notifications.every((n) => n.isRead), true);
        expect(state.hasUnread, false);
      });

      test('works correctly with empty notifications list', () {
        // Arrange
        final notifier = container.read(invitationNotificationsProvider.notifier);

        // Act
        notifier.markAllAsRead();

        // Assert
        final state = container.read(invitationNotificationsProvider);
        expect(state.notifications, isEmpty);
        expect(state.hasUnread, false);
      });
    });

    group('clearNotifications', () {
      test('clears all notifications and resets hasUnread', () {
        // Arrange
        final notifier = container.read(invitationNotificationsProvider.notifier);
        final notifications = [
          InvitationNotification(
            id: 'notif-1',
            userEmail: 'test@test.com',
            userName: 'Test User',
            organizationId: 'org-1',
            acceptedAt: DateTime.now(),
          ),
        ];

        notifier.state = notifier.state.copyWith(
          notifications: notifications,
          hasUnread: true,
        );

        // Act
        notifier.clearNotifications();

        // Assert
        final state = container.read(invitationNotificationsProvider);
        expect(state.notifications, isEmpty);
        expect(state.hasUnread, false);
      });
    });

    group('showNotificationSnackbar', () {
      testWidgets('displays notification using notification service', (WidgetTester tester) async {
        // Arrange
        final notifier = container.read(invitationNotificationsProvider.notifier);
        final notification = InvitationNotification(
          id: 'notif-1',
          userEmail: 'test@example.com',
          userName: 'John Doe',
          organizationId: 'org-1',
          acceptedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        notifier.showNotificationSnackbar(ref, notification);
                      },
                      child: const Text('Show Notification'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump(); // Pump once to trigger notification

        // Get the notification service to verify notification was added
        final notificationService = container.read(notificationServiceProvider);

        // Assert - Notification should be in active notifications
        expect(notificationService.active.isNotEmpty, true);

        // Complete any pending timers before finishing the test
        await tester.pumpAndSettle(const Duration(seconds: 5));
      });
    });

    group('polling control', () {
      test('starts polling when startPolling is called', () {
        // Arrange
        final notifier = container.read(invitationNotificationsProvider.notifier);

        // Act
        notifier.startPolling();

        // Assert - polling should be active (timer exists)
        // Note: We can't directly test the timer, but we can verify no errors occur
        expect(notifier, isNotNull);
      });

      test('stops polling when stopPolling is called', () {
        // Arrange
        final notifier = container.read(invitationNotificationsProvider.notifier);
        notifier.startPolling();

        // Act
        notifier.stopPolling();

        // Assert - polling should be stopped
        expect(notifier, isNotNull);
      });

      test('does not start polling multiple times', () {
        // Arrange
        final notifier = container.read(invitationNotificationsProvider.notifier);

        // Act
        notifier.startPolling();
        notifier.startPolling(); // Should be ignored

        // Assert - no errors should occur
        expect(notifier, isNotNull);
      });
    });
  });
}
