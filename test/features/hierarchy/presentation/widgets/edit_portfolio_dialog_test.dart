import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/features/hierarchy/presentation/widgets/edit_portfolio_dialog.dart';
import 'package:pm_master_v2/features/hierarchy/domain/entities/portfolio.dart';
import 'package:pm_master_v2/features/hierarchy/presentation/providers/hierarchy_providers.dart';
import '../../../../mocks/mock_providers.dart';

void main() {
  group('EditPortfolioDialog', () {
    late Portfolio testPortfolio;

    setUp(() {
      testPortfolio = Portfolio(
        id: 'portfolio-1',
        name: 'Test Portfolio',
        description: 'Test description',
        owner: 'John Doe',
        healthStatus: HealthStatus.green,
        riskSummary: 'No major risks',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    });

    // Helper to build the dialog with providers
    Widget buildDialog({
      Portfolio? portfolio,
      Future<Portfolio> Function({
        required String portfolioId,
        String? name,
        String? description,
        String? owner,
        HealthStatus? healthStatus,
        String? riskSummary,
      })? onUpdate,
      Object? error,
    }) {
      return ProviderScope(
        overrides: [
          portfolioProvider(testPortfolio.id).overrideWith((ref) async {
            if (error != null) {
              throw error;
            }
            return portfolio ?? testPortfolio;
          }),
          portfolioListProvider.overrideWith(() {
            return MockPortfolioList(
              portfolios: [portfolio ?? testPortfolio],
              onUpdate: onUpdate,
            );
          }),
          createHierarchyStateOverride(),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: EditPortfolioDialog(
              portfolioId: testPortfolio.id,
            ),
          ),
        ),
      );
    }

    testWidgets('displays dialog with header and close button', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      // Verify header
      expect(find.text('Edit Portfolio'), findsOneWidget);
      expect(find.text('Update portfolio information and settings'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('pre-populates form fields with portfolio data', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      // Verify all fields are populated
      expect(find.text('Test Portfolio'), findsWidgets);
      expect(find.text('Test description'), findsWidgets);
      expect(find.text('John Doe'), findsWidgets);
      expect(find.text('No major risks'), findsWidgets);
    });

    testWidgets('displays health status dropdown with current status', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      // Find health status dropdown
      expect(find.byType(DropdownButtonFormField<HealthStatus>), findsOneWidget);
      expect(find.text('Healthy'), findsOneWidget);
    });

    testWidgets('validates required name field', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      // Clear the name field
      await tester.enterText(find.widgetWithText(TextFormField, 'Test Portfolio').first, '');
      await tester.pumpAndSettle();

      // Try to submit
      await tester.tap(find.text('Update Portfolio'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a portfolio name'), findsOneWidget);
    });

    testWidgets('validates minimum name length', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      // Enter short name
      await tester.enterText(find.widgetWithText(TextFormField, 'Test Portfolio').first, 'AB');
      await tester.pumpAndSettle();

      // Try to submit
      await tester.tap(find.text('Update Portfolio'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Portfolio name must be at least 3 characters'), findsOneWidget);
    });

    testWidgets('updates portfolio with valid data', (tester) async {
      bool updateCalled = false;
      String? updatedName;
      String? updatedDescription;
      String? updatedOwner;
      HealthStatus? updatedHealthStatus;
      String? updatedRiskSummary;

      await tester.pumpWidget(buildDialog(
        onUpdate: ({
          required portfolioId,
          name,
          description,
          owner,
          healthStatus,
          riskSummary,
        }) async {
          updateCalled = true;
          updatedName = name;
          updatedDescription = description;
          updatedOwner = owner;
          updatedHealthStatus = healthStatus;
          updatedRiskSummary = riskSummary;
          return testPortfolio.copyWith(
            name: name ?? testPortfolio.name,
            description: description,
          );
        },
      ));
      await tester.pumpAndSettle();

      // Update name
      await tester.enterText(find.widgetWithText(TextFormField, 'Test Portfolio').first, 'Updated Portfolio');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Update Portfolio'));
      await tester.pumpAndSettle();

      // Verify update was called
      expect(updateCalled, isTrue);
      expect(updatedName, 'Updated Portfolio');
    });

    testWidgets('updates health status', (tester) async {
      HealthStatus? updatedHealthStatus;

      await tester.pumpWidget(buildDialog(
        onUpdate: ({
          required portfolioId,
          name,
          description,
          owner,
          healthStatus,
          riskSummary,
        }) async {
          updatedHealthStatus = healthStatus;
          return testPortfolio.copyWith(healthStatus: healthStatus ?? testPortfolio.healthStatus);
        },
      ));
      await tester.pumpAndSettle();

      // Open health status dropdown
      await tester.tap(find.byType(DropdownButtonFormField<HealthStatus>));
      await tester.pumpAndSettle();

      // Select "At Risk" option
      await tester.tap(find.text('At Risk').last);
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Update Portfolio'));
      await tester.pumpAndSettle();

      // Verify status was updated
      expect(updatedHealthStatus, HealthStatus.amber);
    });

    testWidgets('handles "already exists" error', (tester) async {
      await tester.pumpWidget(buildDialog(
        onUpdate: ({
          required portfolioId,
          name,
          description,
          owner,
          healthStatus,
          riskSummary,
        }) async {
          throw Exception('Portfolio with name already exists');
        },
      ));
      await tester.pumpAndSettle();

      // Update name
      await tester.enterText(find.widgetWithText(TextFormField, 'Test Portfolio').first, 'Duplicate Name');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Update Portfolio'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.textContaining('already exists'), findsOneWidget);
    });

    testWidgets('handles 409 conflict error', (tester) async {
      await tester.pumpWidget(buildDialog(
        onUpdate: ({
          required portfolioId,
          name,
          description,
          owner,
          healthStatus,
          riskSummary,
        }) async {
          throw Exception('409');
        },
      ));
      await tester.pumpAndSettle();

      // Update name
      await tester.enterText(find.widgetWithText(TextFormField, 'Test Portfolio').first, 'Conflict Name');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Update Portfolio'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('This portfolio name is already taken. Please choose another name.'), findsOneWidget);
    });

    testWidgets('handles generic error', (tester) async {
      await tester.pumpWidget(buildDialog(
        onUpdate: ({
          required portfolioId,
          name,
          description,
          owner,
          healthStatus,
          riskSummary,
        }) async {
          throw Exception('Network error');
        },
      ));
      await tester.pumpAndSettle();

      // Update name
      await tester.enterText(find.widgetWithText(TextFormField, 'Test Portfolio').first, 'New Name');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Update Portfolio'));
      await tester.pumpAndSettle();

      // Verify generic error message
      expect(find.text('Failed to update portfolio. Please try again.'), findsOneWidget);
    });

    testWidgets('closes dialog on cancel', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed (Update Portfolio button should not be visible)
      expect(find.text('Update Portfolio'), findsNothing);
    });

    testWidgets('closes dialog on close button', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Update Portfolio'), findsNothing);
    });

    testWidgets('shows loading indicator during update', (tester) async {
      await tester.pumpWidget(buildDialog(
        onUpdate: ({
          required portfolioId,
          name,
          description,
          owner,
          healthStatus,
          riskSummary,
        }) async {
          // Delay to simulate network request
          await Future.delayed(const Duration(milliseconds: 100));
          return testPortfolio;
        },
      ));
      await tester.pumpAndSettle();

      // Update name
      await tester.enterText(find.widgetWithText(TextFormField, 'Test Portfolio').first, 'Updated Name');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Update Portfolio'));
      await tester.pump();

      // Verify loading indicator is shown
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('trims whitespace from inputs', (tester) async {
      String? updatedName;
      String? updatedDescription;

      await tester.pumpWidget(buildDialog(
        onUpdate: ({
          required portfolioId,
          name,
          description,
          owner,
          healthStatus,
          riskSummary,
        }) async {
          updatedName = name;
          updatedDescription = description;
          return testPortfolio;
        },
      ));
      await tester.pumpAndSettle();

      // Enter name with whitespace
      await tester.enterText(find.widgetWithText(TextFormField, 'Test Portfolio').first, '  Trimmed Name  ');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Update Portfolio'));
      await tester.pumpAndSettle();

      // Verify whitespace was trimmed
      expect(updatedName, 'Trimmed Name');
    });

    testWidgets('sends null for empty description', (tester) async {
      String? updatedDescription;

      await tester.pumpWidget(buildDialog(
        onUpdate: ({
          required portfolioId,
          name,
          description,
          owner,
          healthStatus,
          riskSummary,
        }) async {
          updatedDescription = description;
          return testPortfolio;
        },
      ));
      await tester.pumpAndSettle();

      // Clear description
      await tester.enterText(find.widgetWithText(TextFormField, 'Test description').first, '');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Update Portfolio'));
      await tester.pumpAndSettle();

      // Verify description is null
      expect(updatedDescription, isNull);
    });

    testWidgets('handles portfolio with no optional fields', (tester) async {
      final minimalPortfolio = Portfolio(
        id: 'portfolio-2',
        name: 'Minimal Portfolio',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(buildDialog(portfolio: minimalPortfolio));
      await tester.pumpAndSettle();

      // Verify dialog loads without errors
      expect(find.text('Edit Portfolio'), findsOneWidget);
      expect(find.text('Minimal Portfolio'), findsWidgets);
    });

    testWidgets('disables submit button during loading', (tester) async {
      await tester.pumpWidget(buildDialog(
        onUpdate: ({
          required portfolioId,
          name,
          description,
          owner,
          healthStatus,
          riskSummary,
        }) async {
          await Future.delayed(const Duration(milliseconds: 200));
          return testPortfolio;
        },
      ));
      await tester.pumpAndSettle();

      // Update name
      await tester.enterText(find.widgetWithText(TextFormField, 'Test Portfolio').first, 'New Name');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Update Portfolio'));
      await tester.pump();

      // Try to submit again (button should be disabled)
      final button = tester.widget<FilledButton>(find.ancestor(
        of: find.text('Update Portfolio'),
        matching: find.byType(FilledButton),
      ));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows success snackbar on successful update', (tester) async {
      await tester.pumpWidget(buildDialog(
        onUpdate: ({
          required portfolioId,
          name,
          description,
          owner,
          healthStatus,
          riskSummary,
        }) async {
          return testPortfolio.copyWith(name: name ?? testPortfolio.name);
        },
      ));
      await tester.pumpAndSettle();

      // Update name
      await tester.enterText(find.widgetWithText(TextFormField, 'Test Portfolio').first, 'Success Name');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Update Portfolio'));
      await tester.pumpAndSettle();

      // Verify success snackbar
      expect(find.text('Portfolio updated successfully'), findsOneWidget);
    });

    testWidgets('shows error state when portfolio fails to load', (tester) async {
      await tester.pumpWidget(buildDialog(error: Exception('Failed to load portfolio')));
      await tester.pumpAndSettle();

      // Verify error dialog
      expect(find.text('Error'), findsOneWidget);
      expect(find.textContaining('Failed to load portfolio'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('dropdown renders without overflow (preventive fix verification)', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      // Find the health status dropdown
      expect(find.byType(DropdownButtonFormField<HealthStatus>), findsOneWidget);

      // Open dropdown to verify it renders without overflow
      await tester.tap(find.byType(DropdownButtonFormField<HealthStatus>));
      await tester.pumpAndSettle();

      // Should render all dropdown items without overflow
      expect(find.text('Healthy'), findsWidgets);
      expect(find.text('At Risk'), findsWidgets);
      expect(find.text('Critical'), findsWidgets);
      expect(find.text('Not Set'), findsWidgets);
    });

    testWidgets('updates all fields correctly', (tester) async {
      String? updatedName;
      String? updatedDescription;
      String? updatedOwner;
      HealthStatus? updatedHealthStatus;
      String? updatedRiskSummary;

      await tester.pumpWidget(buildDialog(
        onUpdate: ({
          required portfolioId,
          name,
          description,
          owner,
          healthStatus,
          riskSummary,
        }) async {
          updatedName = name;
          updatedDescription = description;
          updatedOwner = owner;
          updatedHealthStatus = healthStatus;
          updatedRiskSummary = riskSummary;
          return testPortfolio.copyWith(
            name: name ?? testPortfolio.name,
            description: description,
            owner: owner,
            healthStatus: healthStatus ?? testPortfolio.healthStatus,
            riskSummary: riskSummary,
          );
        },
      ));
      await tester.pumpAndSettle();

      // Update all fields
      await tester.enterText(find.widgetWithText(TextFormField, 'Test Portfolio').first, 'Complete Update');
      await tester.enterText(find.widgetWithText(TextFormField, 'Test description').first, 'New description');
      await tester.enterText(find.widgetWithText(TextFormField, 'John Doe').first, 'Jane Smith');
      await tester.enterText(find.widgetWithText(TextFormField, 'No major risks').first, 'Updated risks');

      // Update health status
      await tester.tap(find.byType(DropdownButtonFormField<HealthStatus>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Critical').last);
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Update Portfolio'));
      await tester.pumpAndSettle();

      // Verify all fields were updated
      expect(updatedName, 'Complete Update');
      expect(updatedDescription, 'New description');
      expect(updatedOwner, 'Jane Smith');
      expect(updatedHealthStatus, HealthStatus.red);
      expect(updatedRiskSummary, 'Updated risks');
    });
  });
}
