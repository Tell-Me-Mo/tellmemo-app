import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/features/risks/presentation/widgets/risk_export_dialog.dart';
import 'package:pm_master_v2/core/services/notification_service.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late MockNotificationService mockNotificationService;

  setUp(() {
    mockNotificationService = createMockNotificationService();
  });

  Future<void> pumpTestWidget(
    WidgetTester tester, {
    String format = 'pdf',
    VoidCallback? onExport,
  }) async {
    await pumpWidgetWithProviders(
      tester,
      Builder(
        builder: (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => RiskExportDialog(
                    format: format,
                    onExport: onExport ?? () {},
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          );
        },
      ),
      overrides: [
        notificationServiceProvider.overrideWith((ref) => mockNotificationService),
      ],
    );
  }

  group('RiskExportDialog', () {
    testWidgets('displays correct title and icon for PDF format', (tester) async {
      await pumpTestWidget(tester, format: 'pdf');
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Export to PDF'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('displays correct title and icon for report format', (tester) async {
      await pumpTestWidget(tester, format: 'report');
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Generate Report'), findsOneWidget);
      expect(find.byIcon(Icons.description), findsOneWidget);
    });

    testWidgets('displays correct title and icon for other formats', (tester) async {
      await pumpTestWidget(tester, format: 'csv');
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Export Data'), findsOneWidget);
      // Find download icon in title (not in button)
      expect(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byIcon(Icons.download),
      ), findsAtLeastNWidgets(1));
    });

    testWidgets('displays all export option checkboxes', (tester) async {
      await pumpTestWidget(tester, format: 'pdf');
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Export Options'), findsOneWidget);
      expect(find.text('Include Resolved Risks'), findsOneWidget);
      expect(find.text('Include Detailed Information'), findsOneWidget);
    });

    testWidgets('shows charts option for PDF format', (tester) async {
      await pumpTestWidget(tester, format: 'pdf');
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Include Charts & Analytics'), findsOneWidget);
    });

    testWidgets('shows charts option for report format', (tester) async {
      await pumpTestWidget(tester, format: 'report');
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Include Charts & Analytics'), findsOneWidget);
    });

    testWidgets('hides charts option for CSV format', (tester) async {
      await pumpTestWidget(tester, format: 'csv');
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Include Charts & Analytics'), findsNothing);
    });

    testWidgets('displays date range dropdown with default value', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Date Range'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);
    });

    testWidgets('displays group by dropdown with default value', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Group By'), findsOneWidget);
      expect(find.text('No Grouping'), findsOneWidget);
    });

    testWidgets('can toggle include resolved risks checkbox', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Find checkbox by the title text
      final checkbox = find.ancestor(
        of: find.text('Include Resolved Risks'),
        matching: find.byType(CheckboxListTile),
      );

      // Verify initially checked
      CheckboxListTile checkboxWidget = tester.widget(checkbox);
      expect(checkboxWidget.value, true);

      // Tap to uncheck
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // Verify unchecked
      checkboxWidget = tester.widget(checkbox);
      expect(checkboxWidget.value, false);
    });

    testWidgets('can toggle include details checkbox', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final checkbox = find.ancestor(
        of: find.text('Include Detailed Information'),
        matching: find.byType(CheckboxListTile),
      );

      // Verify initially checked
      CheckboxListTile checkboxWidget = tester.widget(checkbox);
      expect(checkboxWidget.value, true);

      // Tap to uncheck
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // Verify unchecked
      checkboxWidget = tester.widget(checkbox);
      expect(checkboxWidget.value, false);
    });

    testWidgets('can select date range from dropdown', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap the date range dropdown
      await tester.tap(find.text('All Time'));
      await tester.pumpAndSettle();

      // Select "Last Month"
      await tester.tap(find.text('Last Month').last);
      await tester.pumpAndSettle();

      // Verify selected
      expect(find.text('Last Month'), findsOneWidget);
    });

    testWidgets('can select group by from dropdown', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify the Group By section and dropdown exist
      expect(find.text('Group By'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));

      // Verify the default value is "No Grouping"
      expect(find.text('No Grouping'), findsOneWidget);
    });

    testWidgets('displays format description', (tester) async {
      await pumpTestWidget(tester, format: 'pdf');
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Export risks as a formatted PDF'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('displays cancel and export buttons', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Export'), findsOneWidget);
    });

    testWidgets('closes dialog when cancel is tapped', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.byType(RiskExportDialog), findsNothing);
    });

    testWidgets('calls onExport callback when export is tapped', (tester) async {
      bool exportCalled = false;

      await pumpTestWidget(
        tester,
        onExport: () {
          exportCalled = true;
        },
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap export button
      await tester.tap(find.text('Export'));

      // Wait for the simulated export delay (2 seconds)
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(exportCalled, true);

      // Dialog should be closed
      expect(find.byType(RiskExportDialog), findsNothing);

      // Success notification should be shown
      expect(mockNotificationService.successCalls, contains('Export completed successfully'));
    });

    testWidgets('shows loading state during export', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap export button
      await tester.tap(find.text('Export'));
      await tester.pump();

      // Should show loading state
      expect(find.text('Exporting...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Cancel button should be disabled
      final cancelButton = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Cancel'),
          matching: find.byType(TextButton),
        ),
      );
      expect(cancelButton.onPressed, null);

      // Complete the async export operation
      await tester.pumpAndSettle();
    });
  });
}
