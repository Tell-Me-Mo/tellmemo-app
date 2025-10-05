import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/auth/presentation/screens/auth_loading_screen.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthLoadingScreen Widget Tests', () {
    testWidgets('displays loading UI elements', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));

      await pumpWidgetWithProviders(
        tester,
        const AuthLoadingScreen(),
        settle: false,
      );

      expect(find.byIcon(Icons.dashboard_rounded), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('TellMeMo'), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });
  });
}
