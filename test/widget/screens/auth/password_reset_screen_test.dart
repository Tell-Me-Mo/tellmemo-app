import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pm_master_v2/features/auth/presentation/providers/auth_provider.dart';
import 'package:pm_master_v2/features/auth/presentation/screens/password_reset_screen.dart';
import '../../../helpers/test_helpers.dart';
import '../../../mocks/mock_auth.dart';
import '../../../mocks/generate_mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PasswordResetScreen Widget Tests', () {
    late MockAuthInterface mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthInterface();
    });

    testWidgets('displays all required UI elements', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));

      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (!details.toString().contains('RenderFlex overflowed')) {
          originalOnError?.call(details);
        }
      };

      await pumpWidgetWithProviders(
        tester,
        const PasswordResetScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );

      expect(find.byIcon(Icons.lock_reset_outlined), findsOneWidget);
      expect(find.text('Create new password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      FlutterError.onError = originalOnError;
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('validates password match', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));

      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (!details.toString().contains('RenderFlex overflowed')) {
          originalOnError?.call(details);
        }
      };

      await pumpWidgetWithProviders(
        tester,
        const PasswordResetScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'password123');
      await tester.enterText(fields.last, 'different');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Reset Password'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);

      FlutterError.onError = originalOnError;
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('successfully resets password', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));

      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (!details.toString().contains('RenderFlex overflowed')) {
          originalOnError?.call(details);
        }
      };

      when(mockAuthRepository.updatePassword('newpassword123'))
          .thenAnswer((_) async => createMockAuthResult());

      await pumpWidgetWithProviders(
        tester,
        const PasswordResetScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'newpassword123');
      await tester.enterText(fields.last, 'newpassword123');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Reset Password'));
      await tester.pumpAndSettle();

      verify(mockAuthRepository.updatePassword('newpassword123')).called(1);

      FlutterError.onError = originalOnError;
      await tester.binding.setSurfaceSize(null);
    });
  });
}
