import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/organizations/presentation/screens/member_management_screen.dart';
import '../../../../helpers/test_helpers.dart';
import '../../../../mocks/organization_test_fixtures.dart';
import '../../../../mocks/mock_providers.dart';

void main() {
  group('MemberManagementScreen Widget Tests', () {
    late List<Override> mockOverrides;

    setUp(() {
      final sampleOrg = OrganizationTestFixtures.sampleOrganization;
      final sampleMembers = OrganizationTestFixtures.sampleMembers;

      mockOverrides = [
        createCurrentOrganizationOverride(organization: sampleOrg),
        createMembersProviderOverride(sampleOrg.id, sampleMembers),
      ];
    });

    testWidgets('renders screen with app bar and title', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: mockOverrides,
      );

      // Assert
      expect(find.text('Organization Members'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows loading indicator when organization is loading', (WidgetTester tester) async {
      // Arrange
      final loadingOverrides = [
        createCurrentOrganizationLoadingOverride(),
      ];

      // Act
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: loadingOverrides,
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows invite members button for admin users', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: mockOverrides,
      );

      // Assert
      expect(find.text('Invite Members'), findsOneWidget);
      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('hides invite members button for non-admin users', (WidgetTester tester) async {
      // Arrange
      final memberOrg = OrganizationTestFixtures.sampleOrganizationAsMember.toEntity();
      final memberOverrides = [
        createCurrentOrganizationOverride(organization: memberOrg),
        createMembersProviderOverride(memberOrg.id, OrganizationTestFixtures.sampleMembers),
      ];

      // Act
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: memberOverrides,
      );

      // Assert
      expect(find.text('Invite Members'), findsNothing);
    });

    testWidgets('displays search bar and filter chips', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: mockOverrides,
      );

      // Assert
      expect(find.text('Search by name or email...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('All Roles'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('displays all members in the list', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: mockOverrides,
      );

      // Assert
      expect(find.text('admin@test.com'), findsOneWidget);
      expect(find.text('member@test.com'), findsOneWidget);
      expect(find.text('viewer@test.com'), findsOneWidget);
      // Pending invitation should not show in active filter
      expect(find.text('pending@test.com'), findsNothing);
    });

    testWidgets('shows member count in results summary', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: mockOverrides,
      );

      // Assert
      expect(find.textContaining('member'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows role badges for each member', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: mockOverrides,
      );

      // Assert
      expect(find.text('admin'), findsOneWidget);
      expect(find.text('member'), findsAtLeastNWidgets(1));
      expect(find.text('viewer'), findsOneWidget);
    });

    testWidgets('shows "You" badge for current user', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: mockOverrides,
      );

      // Assert
      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('shows "Owner" badge for organization creator', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: mockOverrides,
      );

      // Assert
      expect(find.text('Owner'), findsOneWidget);
    });

    testWidgets('filters members by search query', (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: mockOverrides,
      );

      // Act - Search for "admin"
      await tester.enterText(find.byType(TextField), 'admin');
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('admin@test.com'), findsOneWidget);
      expect(find.text('member@test.com'), findsNothing);
      expect(find.text('viewer@test.com'), findsNothing);
    });

    testWidgets('can clear search query', (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: mockOverrides,
      );

      // Act - Enter search query
      await tester.enterText(find.byType(TextField), 'admin');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // Act - Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('admin@test.com'), findsOneWidget);
      expect(find.text('member@test.com'), findsOneWidget);
    });

    testWidgets('filters members by role', (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: mockOverrides,
      );

      // Act - Open role filter menu
      await tester.tap(find.text('All Roles'));
      await tester.pumpAndSettle();

      // Select "Admin" role
      await tester.tap(find.text('Admin').last);
      await tester.pumpAndSettle();

      // Assert - Only admin should be visible
      expect(find.text('admin@test.com'), findsOneWidget);
      expect(find.text('member@test.com'), findsNothing);
    });

    testWidgets('filters by pending invitations', (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: mockOverrides,
      );

      // Act - Switch to invited status filter
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pending Invitations'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('pending@test.com'), findsOneWidget);
      expect(find.text('admin@test.com'), findsNothing);
    });

    testWidgets('shows more options menu for admin on non-owner members',
        (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: mockOverrides,
      );

      // Assert - Should have more_vert icons for non-owner members
      expect(find.byIcon(Icons.more_vert), findsAtLeastNWidgets(2));
    });

    testWidgets('opens member action menu when more button is tapped',
        (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: mockOverrides,
      );

      // Act - Tap more button on second member (member@test.com)
      await tester.tap(find.byIcon(Icons.more_vert).at(1));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Change Role'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('shows resend invitation option for pending members',
        (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: mockOverrides,
      );

      // Act - Switch to pending invitations
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pending Invitations'));
      await tester.pumpAndSettle();

      // Open menu for pending member
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Resend Invitation'), findsOneWidget);
    });

    testWidgets('enables multi-select mode when checklist icon is tapped',
        (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: mockOverrides,
      );

      // Act
      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pumpAndSettle();

      // Assert - Checkboxes should appear
      expect(find.byType(Checkbox), findsAtLeastNWidgets(1));
    });

    testWidgets('can select multiple members in multi-select mode',
        (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: mockOverrides,
      );

      // Act - Enable multi-select
      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pumpAndSettle();

      // Select a member (not owner/current user) - select the second checkbox
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Remove ('), findsOneWidget);
    });

    testWidgets('shows empty state when no members match filters',
        (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: mockOverrides,
      );

      // Act - Search for non-existent member
      await tester.enterText(find.byType(TextField), 'nonexistent@test.com');
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No members found matching your search'), findsOneWidget);
      expect(find.byIcon(Icons.group_off), findsOneWidget);
    });

    testWidgets('shows error state when members fail to load', (WidgetTester tester) async {
      // Arrange
      final sampleOrg = OrganizationTestFixtures.sampleOrganization;
      final errorOverrides = [
        createCurrentOrganizationOverride(organization: sampleOrg),
        createMembersErrorOverride(sampleOrg.id, 'Failed to load members'),
      ];

      // Act
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: errorOverrides,
      );

      // Assert
      expect(find.text('Failed to load members'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('displays last active time for active members', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: mockOverrides,
      );

      // Assert
      expect(find.textContaining('Active'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Pending badge for invited members', (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: mockOverrides,
      );

      // Act - Switch to pending invitations
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pending Invitations'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('displays member avatars', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: mockOverrides,
      );

      // Assert
      expect(find.byType(CircleAvatar), findsAtLeastNWidgets(3));
    });

    testWidgets('shows invite first member button when empty', (WidgetTester tester) async {
      // Arrange
      final sampleOrg = OrganizationTestFixtures.sampleOrganization;
      final emptyOverrides = [
        createCurrentOrganizationOverride(organization: sampleOrg),
        createMembersProviderOverride(sampleOrg.id, []),
      ];

      // Act
      await pumpWidgetWithProviders(
        tester,
        const MemberManagementScreen(),
        overrides: emptyOverrides,
      );

      // Assert
      expect(find.text('No members to display'), findsOneWidget);
      expect(find.text('Invite First Member'), findsOneWidget);
    });
  });
}
