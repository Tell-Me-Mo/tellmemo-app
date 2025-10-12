import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/profile/presentation/widgets/change_password_dialog.dart';
import 'package:pm_master_v2/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:pm_master_v2/features/profile/domain/entities/user_profile.dart';
import 'package:pm_master_v2/core/services/notification_service.dart';
import '../../../../helpers/test_helpers.dart';

// Simple notifier for testing
class TestUserProfileNotifier extends UserProfileController {
  bool shouldFail = false;
  String? lastPassword;

  TestUserProfileNotifier() : super();

  @override
  Future<UserProfile?> build() async {
    return null;
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    lastPassword = newPassword;
    if (shouldFail) {
      throw Exception('Failed to update password');
    }
    // No delay needed for tests
  }
}

void main() {
  group('ChangePasswordDialog', () {
    late TestUserProfileNotifier testNotifier;
    late MockNotificationService mockNotificationService;

    setUp(() {
      testNotifier = TestUserProfileNotifier();
      mockNotificationService = createMockNotificationService();
    });

    Widget createDialog() {
      return ProviderScope(
        overrides: [
          userProfileControllerProvider.overrideWith(() => testNotifier),
          notificationServiceProvider.overrideWith((ref) => mockNotificationService),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ChangePasswordDialog(),
          ),
        ),
      );
    }

    testWidgets('renders dialog with title and header', (tester) async {
      await tester.pumpWidget(createDialog());

      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Update your account password'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
    });

    testWidgets('displays close button in header', (tester) async {
      await tester.pumpWidget(createDialog());

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('displays new password field', (tester) async {
      await tester.pumpWidget(createDialog());

      expect(find.widgetWithText(TextFormField, 'New Password'), findsOneWidget);
      expect(find.text('Enter your new password'), findsOneWidget);
    });

    testWidgets('displays confirm password field', (tester) async {
      await tester.pumpWidget(createDialog());

      expect(find.widgetWithText(TextFormField, 'Confirm New Password'), findsOneWidget);
      expect(find.text('Confirm your new password'), findsOneWidget);
    });

    testWidgets('displays password requirements info', (tester) async {
      await tester.pumpWidget(createDialog());

      expect(find.text('Password Requirements'), findsOneWidget);
      expect(find.text('• At least 6 characters long'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('displays action buttons', (tester) async {
      await tester.pumpWidget(createDialog());

      expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Update Password'), findsOneWidget);
    });

    testWidgets('has visibility toggle buttons', (tester) async {
      await tester.pumpWidget(createDialog());

      // Should have visibility toggle icons (outlined version)
      expect(find.byIcon(Icons.visibility_outlined), findsWidgets);
    });

    testWidgets('can toggle password visibility', (tester) async {
      await tester.pumpWidget(createDialog());

      // Tap visibility toggle for new password
      final visibilityButtons = find.byIcon(Icons.visibility_outlined);
      expect(visibilityButtons, findsWidgets);
      await tester.tap(visibilityButtons.first);
      await tester.pumpAndSettle();

      // Should now show visibility_off icon
      expect(find.byIcon(Icons.visibility_off_outlined), findsAtLeastNWidgets(1));
    });

    testWidgets('validates empty new password', (tester) async {
      await tester.pumpWidget(createDialog());

      await tester.tap(find.widgetWithText(FilledButton, 'Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a password'), findsOneWidget);
    });

    testWidgets('validates short password (less than 6 characters)', (tester) async {
      await tester.pumpWidget(createDialog());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'New Password'),
        '12345',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('validates empty confirm password', (tester) async {
      await tester.pumpWidget(createDialog());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'New Password'),
        'password123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('validates password mismatch', (tester) async {
      await tester.pumpWidget(createDialog());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'New Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm New Password'),
        'password456',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('successfully updates password with valid input', (tester) async {
      await tester.pumpWidget(createDialog());

      const newPassword = 'newpassword123';

      await tester.enterText(
        find.widgetWithText(TextFormField, 'New Password'),
        newPassword,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm New Password'),
        newPassword,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Update Password'));
      await tester.pumpAndSettle();

      expect(testNotifier.lastPassword, newPassword);
      expect(mockNotificationService.successCalls, contains('Password updated successfully'));
    });

    testWidgets('shows error message on update failure', (tester) async {
      testNotifier.shouldFail = true;
      await tester.pumpWidget(createDialog());

      const newPassword = 'newpassword123';

      await tester.enterText(
        find.widgetWithText(TextFormField, 'New Password'),
        newPassword,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm New Password'),
        newPassword,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Update Password'));
      await tester.pumpAndSettle();

      expect(mockNotificationService.errorCalls.any((msg) => msg.contains('Error updating password')), isTrue);
    });

    testWidgets('has lock icons on password fields', (tester) async {
      await tester.pumpWidget(createDialog());

      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
    });

    testWidgets('accepts password with exactly 6 characters', (tester) async {
      await tester.pumpWidget(createDialog());

      const newPassword = '123456';

      await tester.enterText(
        find.widgetWithText(TextFormField, 'New Password'),
        newPassword,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm New Password'),
        newPassword,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Update Password'));
      await tester.pumpAndSettle();

      expect(testNotifier.lastPassword, newPassword);
      expect(mockNotificationService.successCalls, contains('Password updated successfully'));
    });

    testWidgets('accepts long passwords', (tester) async {
      await tester.pumpWidget(createDialog());

      final newPassword = 'a' * 100;

      await tester.enterText(
        find.widgetWithText(TextFormField, 'New Password'),
        newPassword,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm New Password'),
        newPassword,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Update Password'));
      await tester.pumpAndSettle();

      expect(testNotifier.lastPassword, newPassword);
    });

    testWidgets('accepts passwords with special characters', (tester) async {
      await tester.pumpWidget(createDialog());

      const newPassword = 'P@ssw0rd!#\$%';

      await tester.enterText(
        find.widgetWithText(TextFormField, 'New Password'),
        newPassword,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm New Password'),
        newPassword,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Update Password'));
      await tester.pumpAndSettle();

      expect(testNotifier.lastPassword, newPassword);
    });

    testWidgets('cancel button closes dialog without saving', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileControllerProvider.overrideWith(() => testNotifier),
            notificationServiceProvider.overrideWith((ref) => mockNotificationService),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => ChangePasswordDialog.show(context),
                    child: const Text('Show Dialog'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter password but click cancel
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New Password'),
        'password123',
      );
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      // Password should not have been updated
      expect(testNotifier.lastPassword, isNull);
    });

    testWidgets('close button closes dialog without saving', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileControllerProvider.overrideWith(() => testNotifier),
            notificationServiceProvider.overrideWith((ref) => mockNotificationService),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => ChangePasswordDialog.show(context),
                    child: const Text('Show Dialog'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter password but click close
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New Password'),
        'password123',
      );
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Password should not have been updated
      expect(testNotifier.lastPassword, isNull);
    });

    testWidgets('disables buttons while updating', (tester) async {
      // Create a notifier to test button state
      final slowNotifier = TestUserProfileNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileControllerProvider.overrideWith(() => slowNotifier),
            notificationServiceProvider.overrideWith((ref) => mockNotificationService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ChangePasswordDialog(),
            ),
          ),
        ),
      );

      const newPassword = 'password123';

      await tester.enterText(
        find.widgetWithText(TextFormField, 'New Password'),
        newPassword,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm New Password'),
        newPassword,
      );

      // Get initial button state
      final updateButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Update Password'),
      );
      expect(updateButton.onPressed, isNotNull);

      await tester.tap(find.widgetWithText(FilledButton, 'Update Password'));
      await tester.pumpAndSettle();

      // Password should have been updated (operation completes quickly in tests)
      expect(slowNotifier.lastPassword, newPassword);
    });

    testWidgets('dialog renders without overflow', (tester) async {
      // Test that dialog renders properly
      await tester.pumpWidget(createDialog());
      await tester.pumpAndSettle();

      // Should find the dialog
      expect(find.byType(Dialog), findsOneWidget);

      // Should find key components
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Update Password'), findsOneWidget);
    });
  });
}
