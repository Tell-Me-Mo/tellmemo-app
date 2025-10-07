import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pm_master_v2/features/auth/presentation/providers/auth_provider.dart';
import 'package:pm_master_v2/features/auth/presentation/screens/forgot_password_screen.dart';
import '../../../helpers/test_helpers.dart';
import '../../../mocks/generate_mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ForgotPasswordScreen Widget Tests', () {
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
        const ForgotPasswordScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );

      expect(find.byIcon(Icons.lock_reset_outlined), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Send Reset Email'), findsOneWidget);

      FlutterError.onError = originalOnError;
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('validates email format', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));

      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (!details.toString().contains('RenderFlex overflowed')) {
          originalOnError?.call(details);
        }
      };

      await pumpWidgetWithProviders(
        tester,
        const ForgotPasswordScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );

      await tester.enterText(find.byType(TextFormField), 'invalid-email');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Send Reset Email'));
      await tester.pump();

      expect(find.text('Please enter a valid email address'), findsOneWidget);

      FlutterError.onError = originalOnError;
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('successfully sends reset email', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));

      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (!details.toString().contains('RenderFlex overflowed')) {
          originalOnError?.call(details);
        }
      };

      when(mockAuthRepository.resetPassword('test@example.com'))
          .thenAnswer((_) async {});

      await pumpWidgetWithProviders(
        tester,
        const ForgotPasswordScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Send Reset Email'));
      await tester.pumpAndSettle();

      verify(mockAuthRepository.resetPassword('test@example.com')).called(1);
      expect(find.text('Check your email'), findsOneWidget);

      FlutterError.onError = originalOnError;
      await tester.binding.setSurfaceSize(null);
    });
  });
}
