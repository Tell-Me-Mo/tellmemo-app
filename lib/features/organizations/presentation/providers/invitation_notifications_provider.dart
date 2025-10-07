import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/features/organizations/data/models/organization_member.dart';

/// Provider for managing invitation acceptance notifications
///
/// **Usage:**
/// - To display notifications: Just watch the provider in your widget
/// - To enable automatic polling: Call `ref.read(invitationNotificationsProvider.notifier).startPolling()`
///   when you want to actively monitor for new invitation acceptances
/// - To stop polling: Call `ref.read(invitationNotificationsProvider.notifier).stopPolling()`
///
/// **Example:**
/// ```dart
/// // In a screen that needs to monitor invitations:
/// @override
/// void initState() {
///   super.initState();
///   // Start polling when screen is shown
///   Future.microtask(() {
///     ref.read(invitationNotificationsProvider.notifier).startPolling();
///   });
/// }
///
/// @override
/// void dispose() {
///   // Stop polling when screen is disposed
///   ref.read(invitationNotificationsProvider.notifier).stopPolling();
///   super.dispose();
/// }
/// ```
final invitationNotificationsProvider = StateNotifierProvider<InvitationNotificationsNotifier, InvitationNotificationState>((ref) {
  return InvitationNotificationsNotifier(ref);
});

class InvitationNotificationState {
  final List<InvitationNotification> notifications;
  final bool hasUnread;
  final Map<String, DateTime> lastCheckedMembers;

  InvitationNotificationState({
    this.notifications = const [],
    this.hasUnread = false,
    this.lastCheckedMembers = const {},
  });

  InvitationNotificationState copyWith({
    List<InvitationNotification>? notifications,
    bool? hasUnread,
    Map<String, DateTime>? lastCheckedMembers,
  }) {
    return InvitationNotificationState(
      notifications: notifications ?? this.notifications,
      hasUnread: hasUnread ?? this.hasUnread,
      lastCheckedMembers: lastCheckedMembers ?? this.lastCheckedMembers,
    );
  }
}

class InvitationNotification {
  final String id;
  final String userEmail;
  final String userName;
  final String organizationId;
  final DateTime acceptedAt;
  final bool isRead;

  InvitationNotification({
    required this.id,
    required this.userEmail,
    required this.userName,
    required this.organizationId,
    required this.acceptedAt,
    this.isRead = false,
  });
}

class InvitationNotificationsNotifier extends StateNotifier<InvitationNotificationState> {
  Timer? _pollingTimer;
  final Map<String, Set<String>> _previousInvitedMembers = {};
  bool _isPolling = false;

  InvitationNotificationsNotifier(Ref ref) : super(InvitationNotificationState()) {
    // Polling is now opt-in - call startPolling() explicitly when needed
    // This prevents automatic timer creation and allows proper cleanup in tests
  }

  /// Start polling for invitation acceptances
  /// Call this method when you need to actively monitor for new invitations
  void startPolling() {
    if (_isPolling) return; // Already polling

    _isPolling = true;
    // Poll every 30 seconds for new acceptances
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkForAcceptedInvitations();
    });
  }

  /// Stop polling for invitation acceptances
  void stopPolling() {
    _isPolling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _checkForAcceptedInvitations() async {
    // This method would be called periodically to check for newly accepted invitations
    // It compares the current members list with previously invited members
  }

  void checkOrganizationMembers(String organizationId, List<OrganizationMember> members) {
    final currentInvited = members
        .where((m) => m.status == 'invited')
        .map((m) => m.userEmail)
        .toSet();

    final currentActive = members
        .where((m) => m.status == 'active')
        .map((m) => m.userEmail)
        .toSet();

    // Check if this is first time checking this organization
    if (!_previousInvitedMembers.containsKey(organizationId)) {
      _previousInvitedMembers[organizationId] = currentInvited;
      return;
    }

    final previousInvited = _previousInvitedMembers[organizationId] ?? {};

    // Find newly accepted invitations (were invited, now active)
    final newlyAccepted = previousInvited.intersection(currentActive);

    if (newlyAccepted.isNotEmpty) {
      final newNotifications = <InvitationNotification>[];

      for (final email in newlyAccepted) {
        final member = members.firstWhere((m) => m.userEmail == email);
        newNotifications.add(
          InvitationNotification(
            id: '${organizationId}_${member.userId}_${DateTime.now().millisecondsSinceEpoch}',
            userEmail: member.userEmail,
            userName: member.userName,
            organizationId: organizationId,
            acceptedAt: member.joinedAt ?? DateTime.now(),
          ),
        );
      }

      // Add new notifications to state
      state = state.copyWith(
        notifications: [...newNotifications, ...state.notifications],
        hasUnread: true,
      );

      // Update the previous invited list
      _previousInvitedMembers[organizationId] = currentInvited;
    }
  }

  void markAsRead(String notificationId) {
    final updatedNotifications = state.notifications.map((n) {
      if (n.id == notificationId) {
        return InvitationNotification(
          id: n.id,
          userEmail: n.userEmail,
          userName: n.userName,
          organizationId: n.organizationId,
          acceptedAt: n.acceptedAt,
          isRead: true,
        );
      }
      return n;
    }).toList();

    final hasUnread = updatedNotifications.any((n) => !n.isRead);

    state = state.copyWith(
      notifications: updatedNotifications,
      hasUnread: hasUnread,
    );
  }

  void markAllAsRead() {
    final updatedNotifications = state.notifications.map((n) {
      return InvitationNotification(
        id: n.id,
        userEmail: n.userEmail,
        userName: n.userName,
        organizationId: n.organizationId,
        acceptedAt: n.acceptedAt,
        isRead: true,
      );
    }).toList();

    state = state.copyWith(
      notifications: updatedNotifications,
      hasUnread: false,
    );
  }

  void clearNotifications() {
    state = state.copyWith(
      notifications: [],
      hasUnread: false,
    );
  }

  void showNotificationSnackbar(BuildContext context, InvitationNotification notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${notification.userName} joined your organization',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    notification.userEmail,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to members screen
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}