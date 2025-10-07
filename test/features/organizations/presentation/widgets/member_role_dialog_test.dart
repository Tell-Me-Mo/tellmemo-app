import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/organizations/presentation/widgets/member_role_dialog.dart';
import '../../../../helpers/test_helpers.dart';
import '../../../../mocks/organization_test_fixtures.dart';

void main() {
  group('MemberRoleDialog Widget Tests', () {
    final testMember = OrganizationTestFixtures.sampleRegularMember;

    testWidgets('renders dialog with all UI elements', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        MemberRoleDialog(
          member: testMember,
          currentRole: 'member',
        ),
      );

      // Assert
      expect(find.text('Change Member Role'), findsOneWidget);
      expect(find.text(testMember.userName), findsOneWidget);
      expect(find.text(testMember.userEmail), findsOneWidget);
      expect(find.text('Select New Role'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Update Role'), findsOneWidget);
    });

    testWidgets('displays all three role options', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        MemberRoleDialog(
          member: testMember,
          currentRole: 'member',
        ),
      );

      // Assert
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Full access to all features and settings'), findsOneWidget);
      expect(find.byIcon(Icons.admin_panel_settings), findsOneWidget);

      expect(find.text('Member'), findsOneWidget);
      expect(find.text('Can access and modify organization data'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);

      expect(find.text('Viewer'), findsOneWidget);
      expect(find.text('Read-only access to organization data'), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('current role is pre-selected', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        MemberRoleDialog(
          member: testMember,
          currentRole: 'member',
        ),
      );

      // Assert - All role options should be visible and member role is current
      expect(find.text('Member'), findsOneWidget);
      expect(find.byType(RadioListTile<String>), findsNWidgets(3));
    });

    testWidgets('can select different role', (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        MemberRoleDialog(
          member: testMember,
          currentRole: 'member',
        ),
      );

      // Act - Tap on Admin role
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();

      // Assert - Notification should appear showing role change
      expect(find.textContaining('Changing from member to admin'), findsOneWidget);
    });

    testWidgets('shows role change notification when role is changed',
        (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        MemberRoleDialog(
          member: testMember,
          currentRole: 'member',
        ),
      );

      // Initially no notification
      expect(find.textContaining('Changing from'), findsNothing);

      // Act - Change to admin
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();

      // Assert - Notification should appear
      expect(find.textContaining('Changing from member to admin'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('Update Role button is disabled when no change is made',
        (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        MemberRoleDialog(
          member: testMember,
          currentRole: 'member',
        ),
      );

      // Assert - Button should be disabled (no role change)
      final updateButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Update Role'),
      );
      expect(updateButton.onPressed, isNull);
    });

    testWidgets('Update Role button is enabled when role is changed',
        (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        MemberRoleDialog(
          member: testMember,
          currentRole: 'member',
        ),
      );

      // Act - Change to viewer
      await tester.tap(find.text('Viewer'));
      await tester.pumpAndSettle();

      // Assert - Button should be enabled
      final updateButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Update Role'),
      );
      expect(updateButton.onPressed, isNotNull);
    });

    testWidgets('Cancel button closes the dialog without returning a value',
        (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        MemberRoleDialog(
          member: testMember,
          currentRole: 'member',
        ),
      );

      // Act
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert - Dialog should be closed
      expect(find.byType(MemberRoleDialog), findsNothing);
    });

    testWidgets('Update Role button returns new role when pressed',
        (WidgetTester tester) async {
      // Arrange
      String? returnedRole;
      await pumpWidgetWithProviders(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              returnedRole = await showDialog<String>(
                context: context,
                builder: (context) => MemberRoleDialog(
                  member: testMember,
                  currentRole: 'member',
                ),
              );
            },
            child: const Text('Show Dialog'),
          ),
        ),
      );

      // Act - Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Change role to admin
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();

      // Tap Update Role button
      await tester.tap(find.text('Update Role'));
      await tester.pumpAndSettle();

      // Assert
      expect(returnedRole, 'admin');
      expect(find.byType(MemberRoleDialog), findsNothing);
    });

    testWidgets('displays member initials when no avatar', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        MemberRoleDialog(
          member: testMember,
          currentRole: 'member',
        ),
      );

      // Assert - Should show initials (first 2 chars of name)
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('ME'), findsOneWidget); // "ME" from "Member User"
    });

    testWidgets('can switch between all roles', (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        MemberRoleDialog(
          member: testMember,
          currentRole: 'member',
        ),
      );

      // Act & Assert - Switch to admin
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Changing from member to admin'), findsOneWidget);

      // Switch to viewer
      await tester.tap(find.text('Viewer'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Changing from member to viewer'), findsOneWidget);

      // Switch back to member (original)
      await tester.tap(find.text('Member'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Changing from'), findsNothing);
    });

    testWidgets('works correctly when starting with admin role',
        (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        MemberRoleDialog(
          member: OrganizationTestFixtures.sampleAdminMember,
          currentRole: 'admin',
        ),
      );

      // Assert - Admin role should be displayed
      expect(find.text('Admin'), findsOneWidget);

      // Update button should be disabled (no change yet)
      final updateButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Update Role'),
      );
      expect(updateButton.onPressed, isNull);
    });

    testWidgets('works correctly when starting with viewer role',
        (WidgetTester tester) async {
      // Arrange
      final viewerMember = testMember.copyWith(role: 'viewer');

      // Act
      await pumpWidgetWithProviders(
        tester,
        MemberRoleDialog(
          member: viewerMember,
          currentRole: 'viewer',
        ),
      );

      // Assert - Viewer role should be displayed
      expect(find.text('Viewer'), findsOneWidget);
      expect(find.text('Read-only access to organization data'), findsOneWidget);
    });
  });
}
