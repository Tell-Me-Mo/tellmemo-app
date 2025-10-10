import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/profile/presentation/screens/change_password_screen.dart';
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
  group('ChangePasswordScreen', () {
    late TestUserProfileNotifier testNotifier;
    late MockNotificationService mockNotificationService;

    setUp(() {
      testNotifier = TestUserProfileNotifier();
      mockNotificationService = createMockNotificationService();
    });

    Widget createScreen() {
      return ProviderScope(
        overrides: [
          userProfileControllerProvider.overrideWith(() => testNotifier),
          notificationServiceProvider.overrideWith((ref) => mockNotificationService),
        ],
        child: const MaterialApp(
          home: ChangePasswordScreen(),
        ),
      );
    }

    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(createScreen());

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);
    });

    testWidgets('displays title in card', (tester) async {
      await tester.pumpWidget(createScreen());

      // Text appears in both card title and button, so check for at least one
      expect(find.text('Update Password'), findsWidgets);
    });

    testWidgets('displays new password field', (tester) async {
      await tester.pumpWidget(createScreen());

      expect(find.widgetWithText(TextFormField, 'New Password'), findsOneWidget);
    });

    testWidgets('displays confirm password field', (tester) async {
      await tester.pumpWidget(createScreen());

      expect(find.widgetWithText(TextFormField, 'Confirm New Password'), findsOneWidget);
    });

    testWidgets('displays password requirements', (tester) async {
      await tester.pumpWidget(createScreen());

      expect(find.text('Password Requirements:'), findsOneWidget);
      expect(find.text('• At least 6 characters long'), findsOneWidget);
    });

    testWidgets('displays update button', (tester) async {
      await tester.pumpWidget(createScreen());

      expect(find.widgetWithText(FilledButton, 'Update Password'), findsOneWidget);
    });

    testWidgets('has visibility toggle buttons', (tester) async {
      await tester.pumpWidget(createScreen());

      // Should have visibility toggle icons
      expect(find.byIcon(Icons.visibility), findsWidgets);
    });

    testWidgets('can toggle password visibility', (tester) async {
      await tester.pumpWidget(createScreen());

      // Tap visibility toggle for new password
      final visibilityButtons = find.byIcon(Icons.visibility);
      expect(visibilityButtons, findsWidgets);
      await tester.tap(visibilityButtons.first);
      await tester.pumpAndSettle();

      // Should now show visibility_off icon
      expect(find.byIcon(Icons.visibility_off), findsAtLeastNWidgets(1));
    });

    testWidgets('validates empty new password', (tester) async {
      await tester.pumpWidget(createScreen());

      await tester.tap(find.widgetWithText(FilledButton, 'Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a password'), findsOneWidget);
    });

    testWidgets('validates short password (less than 6 characters)', (tester) async {
      await tester.pumpWidget(createScreen());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'New Password'),
        '12345',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('validates empty confirm password', (tester) async {
      await tester.pumpWidget(createScreen());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'New Password'),
        'password123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('validates password mismatch', (tester) async {
      await tester.pumpWidget(createScreen());

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
      await tester.pumpWidget(createScreen());

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
      await tester.pumpWidget(createScreen());

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
      await tester.pumpWidget(createScreen());

      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('form is wrapped in a Card', (tester) async {
      await tester.pumpWidget(createScreen());

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('form has proper constraints (max width 400)', (tester) async {
      await tester.pumpWidget(createScreen());

      // Find all ConstrainedBox widgets
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );

      // At least one should have maxWidth of 400
      expect(
        constrainedBoxes.any((box) => box.constraints.maxWidth == 400),
        true,
      );
    });

    testWidgets('password fields have proper hints', (tester) async {
      await tester.pumpWidget(createScreen());

      expect(find.text('Enter your new password'), findsOneWidget);
      expect(find.text('Confirm your new password'), findsOneWidget);
    });

    testWidgets('accepts password with exactly 6 characters', (tester) async {
      await tester.pumpWidget(createScreen());

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
      await tester.pumpWidget(createScreen());

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
      await tester.pumpWidget(createScreen());

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
  });
}
