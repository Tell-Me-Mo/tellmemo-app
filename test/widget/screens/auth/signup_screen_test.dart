import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pm_master_v2/features/auth/presentation/providers/auth_provider.dart';
import 'package:pm_master_v2/features/auth/presentation/screens/signup_screen.dart';
import '../../../helpers/test_helpers.dart';
import '../../../mocks/mock_auth.dart';
import '../../../mocks/generate_mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SignUpScreen Widget Tests', () {
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
        const SignUpScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );

      expect(find.byIcon(Icons.hub_outlined), findsOneWidget);
      expect(find.text('Welcome to TellMeMo'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
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
        const SignUpScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'different');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);

      FlutterError.onError = originalOnError;
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('successfully creates account', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));

      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (!details.toString().contains('RenderFlex overflowed')) {
          originalOnError?.call(details);
        }
      };

      when(mockAuthRepository.signUp(
        email: 'test@example.com',
        password: 'password123',
        metadata: {'name': 'John Doe'},
      )).thenAnswer((_) async => createMockAuthResult());

      await pumpWidgetWithProviders(
        tester,
        const SignUpScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'John Doe');
      await tester.enterText(fields.at(1), 'test@example.com');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password123');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pumpAndSettle();

      verify(mockAuthRepository.signUp(
        email: 'test@example.com',
        password: 'password123',
        metadata: {'name': 'John Doe'},
      )).called(1);

      FlutterError.onError = originalOnError;
      await tester.binding.setSurfaceSize(null);
    });
  });
}
