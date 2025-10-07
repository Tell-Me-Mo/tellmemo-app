import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/core/widgets/loading/progress_indicator_dialog.dart';

void main() {
  group('ProgressIndicatorDialog Widget', () {
    testWidgets('displays title and circular progress indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorDialog(
              title: 'Loading...',
            ),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays message when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorDialog(
              title: 'Processing',
              message: 'Please wait while we process your request',
            ),
          ),
        ),
      );

      expect(find.text('Processing'), findsOneWidget);
      expect(find.text('Please wait while we process your request'), findsOneWidget);
    });

    testWidgets('displays linear progress indicator when no progress value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorDialog(
              title: 'Loading',
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, isNull); // Indeterminate progress
    });

    testWidgets('displays progress with value when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorDialog(
              title: 'Loading',
              progress: 0.5,
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      final circularProgressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(circularProgressIndicator.value, 0.5);
    });

    testWidgets('displays currentItem and totalItems progress text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorDialog(
              title: 'Processing Items',
              currentItem: 5,
              totalItems: 10,
            ),
          ),
        ),
      );

      expect(find.text('Processing item 5 of 10'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('shows cancel button when onCancel is provided', (tester) async {
      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorDialog(
              title: 'Processing',
              onCancel: () {
                cancelCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(cancelCalled, true);
    });

    testWidgets('does not show cancel button when onCancel is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorDialog(
              title: 'Processing',
            ),
          ),
        ),
      );

      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('respects canDismiss property with PopScope', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorDialog(
              title: 'Processing',
              canDismiss: true,
            ),
          ),
        ),
      );

      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, true);
    });

    testWidgets('prevents dismissal when canDismiss is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorDialog(
              title: 'Processing',
              canDismiss: false,
            ),
          ),
        ),
      );

      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, false);
    });

    testWidgets('static show method displays dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ProgressIndicatorDialog.show(
                      context: context,
                      title: 'Test Dialog',
                      message: 'Test message',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pump(); // Just pump once to show dialog

      expect(find.text('Test Dialog'), findsOneWidget);
      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('calculates progress from currentItem and totalItems', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorDialog(
              title: 'Processing',
              currentItem: 3,
              totalItems: 10,
            ),
          ),
        ),
      );

      expect(find.text('30%'), findsOneWidget);
    });

    testWidgets('animates progress changes with TweenAnimationBuilder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorDialog(
              title: 'Processing',
              progress: 0.0,
            ),
          ),
        ),
      );

      expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
    });
  });

  group('BulkOperationProgress Widget', () {
    testWidgets('displays operation title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BulkOperationProgress(
              operation: 'Deleting Items',
              items: const ['item1', 'item2'],
              processor: (item, onProgress) async {},
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Deleting Items'), findsOneWidget);
    });

    testWidgets('shows cancel button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BulkOperationProgress(
              operation: 'Processing',
              items: const ['item1', 'item2'],
              processor: (item, onProgress) async {},
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('uses TweenAnimationBuilder for smooth progress', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BulkOperationProgress(
              operation: 'Processing',
              items: const ['item1', 'item2'],
              processor: (item, onProgress) async {},
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
    });
  });
}
