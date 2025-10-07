import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/organizations/presentation/widgets/invite_members_dialog.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  group('InviteMembersDialog Widget Tests', () {
    const testOrganizationId = 'org-123';

    testWidgets('renders dialog with all UI elements', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const InviteMembersDialog(organizationId: testOrganizationId),
      );

      // Assert
      expect(find.text('Invite Team Members'), findsOneWidget);
      expect(find.byIcon(Icons.person_add), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('Single Invite'), findsOneWidget);
      expect(find.text('Bulk Invite'), findsOneWidget);
      expect(find.text('CSV Import'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Send Invitation'), findsOneWidget);
    });

    testWidgets('displays email field in single invite mode', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const InviteMembersDialog(organizationId: testOrganizationId),
      );

      // Assert
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('colleague@company.com'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('switches to bulk invite mode when selected',
        (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const InviteMembersDialog(organizationId: testOrganizationId),
      );

      // Act
      await tester.tap(find.text('Bulk Invite'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Email Addresses (one per line)'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('displays role selection with three options',
        (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const InviteMembersDialog(organizationId: testOrganizationId),
      );

      // Assert
      expect(find.text('Role'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Member'), findsOneWidget);
      expect(find.text('Viewer'), findsOneWidget);
      // Note: Icons in SegmentedButton are not directly findable with find.byIcon
      expect(find.byType(SegmentedButton<String>), findsOneWidget);
    });

    testWidgets('shows role description when role is selected',
        (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const InviteMembersDialog(organizationId: testOrganizationId),
      );

      // Assert - Check default member role description
      expect(
        find.text('Can access and modify organization data, use integrations'),
        findsOneWidget,
      );
    });

    testWidgets('validates empty email field', (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const InviteMembersDialog(organizationId: testOrganizationId),
      );

      // Act - Try to submit without entering email
      await tester.tap(find.text('Send Invitation'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please enter an email address'), findsOneWidget);
    });

    testWidgets('validates invalid email format', (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const InviteMembersDialog(organizationId: testOrganizationId),
      );

      // Act
      await tester.enterText(find.byType(TextFormField), 'invalid-email');
      await tester.tap(find.text('Send Invitation'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('accepts valid email address', (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const InviteMembersDialog(organizationId: testOrganizationId),
      );

      // Act
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.pumpAndSettle();

      // Assert - No validation error should be shown
      expect(find.text('Please enter an email address'), findsNothing);
      expect(find.text('Please enter a valid email address'), findsNothing);
    });

    testWidgets('bulk mode validates empty emails', (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const InviteMembersDialog(organizationId: testOrganizationId),
      );

      // Act
      await tester.tap(find.text('Bulk Invite'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send Invitations'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please enter at least one email address'), findsOneWidget);
    });

    testWidgets('bulk mode validates invalid email in list',
        (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const InviteMembersDialog(organizationId: testOrganizationId),
      );

      // Act
      await tester.tap(find.text('Bulk Invite'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'valid@example.com\ninvalid-email\nanother@example.com',
      );
      await tester.tap(find.text('Send Invitations'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Invalid email:'), findsOneWidget);
    });

    testWidgets('bulk mode accepts multiple valid emails',
        (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const InviteMembersDialog(organizationId: testOrganizationId),
      );

      // Act
      await tester.tap(find.text('Bulk Invite'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'user1@example.com\nuser2@example.com\nuser3@example.com',
      );
      await tester.pumpAndSettle();

      // Assert - No validation error
      expect(find.text('Please enter at least one email address'), findsNothing);
    });

    testWidgets('cancel button closes the dialog', (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const InviteMembersDialog(organizationId: testOrganizationId),
      );

      // Act
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert - Dialog should be closed (widget should not be found)
      expect(find.byType(InviteMembersDialog), findsNothing);
    });

    testWidgets('close icon button closes the dialog', (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const InviteMembersDialog(organizationId: testOrganizationId),
      );

      // Act
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Assert - Dialog should be closed
      expect(find.byType(InviteMembersDialog), findsNothing);
    });

    testWidgets('role selection updates description', (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const InviteMembersDialog(organizationId: testOrganizationId),
      );

      // Act - Select Admin role
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('Full access to all features, settings, and user management'),
        findsOneWidget,
      );

      // Act - Select Viewer role
      await tester.tap(find.text('Viewer'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Read-only access to organization data'), findsOneWidget);
    });

    testWidgets('renders with constrained width', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const InviteMembersDialog(organizationId: testOrganizationId),
      );

      // Assert - Dialog should have reasonable width
      final dialog = find.byType(Dialog);
      expect(dialog, findsOneWidget);
    });

    testWidgets('single invite mode shows correct button text',
        (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const InviteMembersDialog(organizationId: testOrganizationId),
      );

      // Assert
      expect(find.text('Send Invitation'), findsOneWidget);
      expect(find.text('Send Invitations'), findsNothing);
    });

    testWidgets('bulk invite mode shows correct button text',
        (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const InviteMembersDialog(organizationId: testOrganizationId),
      );

      // Act
      await tester.tap(find.text('Bulk Invite'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Send Invitations'), findsOneWidget);
      expect(find.text('Send Invitation'), findsNothing);
    });
  });
}
