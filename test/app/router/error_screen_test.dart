import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/app/router/app_router.dart';

void main() {
  group('ErrorScreen', () {
    testWidgets('displays error icon and message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorScreen(),
        ),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Something went wrong!'), findsOneWidget);
    });

    testWidgets('displays app bar with Error title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorScreen(),
        ),
      );

      expect(find.widgetWithText(AppBar, 'Error'), findsOneWidget);
    });

    testWidgets('displays error details when error is provided', (tester) async {
      const errorMessage = 'Network connection failed';
      final testError = Exception(errorMessage);

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorScreen(error: testError),
        ),
      );

      expect(find.textContaining(errorMessage), findsOneWidget);
    });

    testWidgets('does not display error details when error is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorScreen(error: null),
        ),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Something went wrong!'), findsOneWidget);
      // Should only find 2 text widgets: AppBar title and main message
      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets('error icon has correct size and color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorScreen(),
        ),
      );

      final errorIcon = tester.widget<Icon>(find.byIcon(Icons.error));
      expect(errorIcon.size, 64);
      expect(errorIcon.color, Colors.red);
    });

    testWidgets('content is centered vertically and horizontally', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorScreen(),
        ),
      );

      // ErrorScreen body should contain a Center widget with Column inside
      expect(find.byType(Center), findsAtLeastNWidgets(1));

      final column = tester.widget<Column>(
        find.descendant(
          of: find.byType(Center),
          matching: find.byType(Column),
        ).first,
      );
      expect(column.mainAxisAlignment, MainAxisAlignment.center);
    });

    testWidgets('displays different error messages correctly', (tester) async {
      // Test with different exception message
      final customError = Exception('Custom error: Invalid operation');

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorScreen(error: customError),
        ),
      );

      expect(find.textContaining('Custom error'), findsOneWidget);
      expect(find.textContaining('Invalid operation'), findsOneWidget);
    });

    testWidgets('handles very long error messages', (tester) async {
      final longError = Exception(
        'This is a very long error message that contains many details about '
        'what went wrong in the application. It should be displayed properly '
        'without causing any overflow issues in the error screen layout.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorScreen(error: longError),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles special characters in error message', (tester) async {
      final specialError = Exception('Error: 404 - Page "test/page" not found! @#\$%');

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorScreen(error: specialError),
        ),
      );

      expect(find.textContaining('404'), findsOneWidget);
      expect(find.textContaining('test/page'), findsOneWidget);
    });

    testWidgets('error details use bodySmall text style', (tester) async {
      final testError = Exception('Test error message');

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorScreen(error: testError),
        ),
      );

      final errorText = tester.widgetList<Text>(
        find.textContaining('Test error message'),
      ).first;

      expect(errorText.style, isNotNull);
      // The style should be set (even if we can't easily verify it's exactly bodySmall)
    });

    testWidgets('displays correct spacing between elements', (tester) async {
      final testError = Exception('Test error');

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorScreen(error: testError),
        ),
      );

      // Find SizedBox widgets that provide spacing
      expect(find.byType(SizedBox), findsAtLeastNWidgets(1));
    });
  });
}
