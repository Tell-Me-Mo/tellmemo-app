// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/app/app.dart';

void main() {
  testWidgets('TellMeMo app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: PMasterApp(),
      ),
    );

    // Verify that our app loads the dashboard.
    expect(find.text('Welcome to TellMeMo'), findsOneWidget);
    expect(find.text('Meeting RAG System Dashboard'), findsOneWidget);
  });
}
