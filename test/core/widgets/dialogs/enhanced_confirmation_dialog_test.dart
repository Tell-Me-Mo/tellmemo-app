import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/core/widgets/dialogs/enhanced_confirmation_dialog.dart';

void main() {
  group('EnhancedConfirmationDialog Widget', () {
    testWidgets('displays title and message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Confirm Action',
              message: 'Are you sure you want to proceed?',
            ),
          ),
        ),
      );

      expect(find.text('Confirm Action'), findsOneWidget);
      expect(find.text('Are you sure you want to proceed?'), findsOneWidget);
    });

    testWidgets('displays default confirm and cancel buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Confirm',
              message: 'Proceed?',
              severity: ConfirmationSeverity.warning,
            ),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Proceed'), findsOneWidget);
    });

    testWidgets('displays custom button text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Confirm',
              message: 'Proceed?',
              confirmText: 'Yes, Continue',
              cancelText: 'No, Go Back',
            ),
          ),
        ),
      );

      expect(find.text('Yes, Continue'), findsOneWidget);
      expect(find.text('No, Go Back'), findsOneWidget);
    });

    testWidgets('displays appropriate icon for info severity', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Information',
              message: 'This is an info message',
              severity: ConfirmationSeverity.info,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('displays appropriate icon for warning severity', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Warning',
              message: 'This is a warning',
              severity: ConfirmationSeverity.warning,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('displays appropriate icon for danger severity', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Danger',
              message: 'This is dangerous',
              severity: ConfirmationSeverity.danger,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.dangerous_outlined), findsOneWidget);
    });

    testWidgets('calls onConfirm when confirm button is pressed', (tester) async {
      bool confirmCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Confirm',
              message: 'Proceed?',
              onConfirm: () {
                confirmCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Proceed'));
      await tester.pump();

      expect(confirmCalled, true);
    });

    testWidgets('calls onCancel when cancel button is pressed', (tester) async {
      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Confirm',
              message: 'Proceed?',
              onCancel: () {
                cancelCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(cancelCalled, true);
    });

    testWidgets('shows undo hint when showUndoHint is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Delete',
              message: 'Delete this item?',
              showUndoHint: true,
            ),
          ),
        ),
      );

      expect(find.text('This action cannot be undone'), findsOneWidget);
    });

    testWidgets('does not show undo hint by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Delete',
              message: 'Delete this item?',
            ),
          ),
        ),
      );

      expect(find.text('This action cannot be undone'), findsNothing);
    });

    testWidgets('displays impact summary when provided', (tester) async {
      const impact = ImpactSummary(
        totalItems: 5,
        itemsByType: {'project': 3, 'task': 2},
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Delete',
              message: 'Delete items?',
              impact: impact,
            ),
          ),
        ),
      );

      expect(find.text('Impact Summary'), findsOneWidget);
      expect(find.textContaining('5 items will be affected'), findsOneWidget);
    });

    testWidgets('impact summary shows item types', (tester) async {
      const impact = ImpactSummary(
        totalItems: 5,
        itemsByType: {'project': 3, 'task': 2},
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Delete',
              message: 'Delete items?',
              impact: impact,
            ),
          ),
        ),
      );

      expect(find.text('3 projects'), findsOneWidget);
      expect(find.text('2 tasks'), findsOneWidget);
    });

    testWidgets('impact summary can show details', (tester) async {
      const impact = ImpactSummary(
        totalItems: 2,
        affectedItems: ['Project A', 'Project B'],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Delete',
              message: 'Delete items?',
              impact: impact,
            ),
          ),
        ),
      );

      // Initially details are hidden
      expect(find.text('Project A'), findsNothing);

      // Tap "Show Details" button
      await tester.tap(find.text('Show Details'));
      await tester.pump();

      // Now details should be visible
      expect(find.text('Project A'), findsOneWidget);
      expect(find.text('Project B'), findsOneWidget);
    });

    testWidgets('requires explicit confirmation when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Delete Project',
              message: 'This will permanently delete the project',
              severity: ConfirmationSeverity.danger,
              requireExplicitConfirmation: true,
            ),
          ),
        ),
      );

      expect(find.text('Type "Delete Project" to confirm:'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Confirm button should be disabled initially
      final confirmButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Delete'),
      );
      expect(confirmButton.onPressed, isNull);
    });

    testWidgets('enables confirm button when correct text is entered', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Delete Project',
              message: 'Confirm deletion',
              severity: ConfirmationSeverity.danger,
              requireExplicitConfirmation: true,
            ),
          ),
        ),
      );

      // Enter the correct confirmation text
      await tester.enterText(find.byType(TextField), 'Delete Project');
      await tester.pump();

      // Confirm button should now be enabled
      final confirmButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Delete'),
      );
      expect(confirmButton.onPressed, isNotNull);
    });

    testWidgets('uses custom explicit confirmation text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Delete',
              message: 'Confirm deletion',
              severity: ConfirmationSeverity.danger,
              requireExplicitConfirmation: true,
              explicitConfirmationText: 'PERMANENTLY DELETE',
            ),
          ),
        ),
      );

      expect(find.text('Type "PERMANENTLY DELETE" to confirm:'), findsOneWidget);

      // Enter the custom confirmation text
      await tester.enterText(find.byType(TextField), 'PERMANENTLY DELETE');
      await tester.pump();

      // Confirm button should be enabled
      final confirmButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Delete'),
      );
      expect(confirmButton.onPressed, isNotNull);
    });

    testWidgets('static show method returns true on confirm', (tester) async {
      late BuildContext savedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                savedContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final future = EnhancedConfirmationDialog.show(
        context: savedContext,
        title: 'Confirm',
        message: 'Proceed?',
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Proceed'));
      await tester.pumpAndSettle();

      final result = await future;
      expect(result, true);
    });

    testWidgets('static show method returns false on cancel', (tester) async {
      late BuildContext savedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                savedContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final future = EnhancedConfirmationDialog.show(
        context: savedContext,
        title: 'Confirm',
        message: 'Proceed?',
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      final result = await future;
      expect(result, false);
    });

    testWidgets('scales in with animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Confirm',
              message: 'Proceed?',
            ),
          ),
        ),
      );

      // ScaleTransition is present (may have multiple due to dialog animation)
      expect(find.byType(ScaleTransition), findsWidgets);
    });

    testWidgets('default confirm text depends on severity', (tester) async {
      // Info severity
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Info',
              message: 'Message',
              severity: ConfirmationSeverity.info,
            ),
          ),
        ),
      );
      expect(find.text('OK'), findsOneWidget);

      // Warning severity
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Warning',
              message: 'Message',
              severity: ConfirmationSeverity.warning,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Proceed'), findsOneWidget);

      // Danger severity
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Danger',
              message: 'Message',
              severity: ConfirmationSeverity.danger,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('impact summary additional info is displayed', (tester) async {
      const impact = ImpactSummary(
        totalItems: 1,
        additionalInfo: 'This will also affect related items',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Delete',
              message: 'Delete?',
              impact: impact,
            ),
          ),
        ),
      );

      expect(find.text('This will also affect related items'), findsOneWidget);
    });

    testWidgets('handles singular vs plural item count correctly', (tester) async {
      // Single item
      const impactSingle = ImpactSummary(totalItems: 1);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Delete',
              message: 'Delete?',
              impact: impactSingle,
            ),
          ),
        ),
      );

      expect(find.text('1 item will be affected'), findsOneWidget);

      // Multiple items
      const impactMultiple = ImpactSummary(totalItems: 5);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Delete',
              message: 'Delete?',
              impact: impactMultiple,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('5 items will be affected'), findsOneWidget);
    });

    testWidgets('toggles details visibility', (tester) async {
      const impact = ImpactSummary(
        totalItems: 2,
        affectedItems: ['Item 1', 'Item 2'],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedConfirmationDialog(
              title: 'Delete',
              message: 'Delete?',
              impact: impact,
            ),
          ),
        ),
      );

      // Show details
      await tester.tap(find.text('Show Details'));
      await tester.pump();
      expect(find.text('Item 1'), findsOneWidget);

      // Hide details
      await tester.tap(find.text('Hide Details'));
      await tester.pump();
      expect(find.text('Item 1'), findsNothing);
    });
  });
}
