import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/features/hierarchy/presentation/widgets/edit_program_dialog.dart';
import 'package:pm_master_v2/features/hierarchy/domain/entities/portfolio.dart';
import 'package:pm_master_v2/features/hierarchy/domain/entities/program.dart';
import 'package:pm_master_v2/features/hierarchy/presentation/providers/hierarchy_providers.dart';
import '../../../../mocks/mock_providers.dart';

void main() {
  group('EditProgramDialog', () {
    late Program testProgram;
    late List<Portfolio> testPortfolios;
    late List<Program> testPrograms;

    setUp(() {
      testPortfolios = [
        Portfolio(
          id: 'portfolio-1',
          name: 'Portfolio A',
          description: 'First portfolio',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
        Portfolio(
          id: 'portfolio-2',
          name: 'Portfolio B',
          description: 'Second portfolio',
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 1, 2),
        ),
      ];

      testProgram = Program(
        id: 'program-1',
        name: 'Test Program',
        description: 'Test description',
        portfolioId: 'portfolio-1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      testPrograms = [testProgram];
    });

    // Helper to build the dialog with providers
    Widget buildDialog({
      Program? program,
      List<Portfolio>? portfolios,
      Future<Program> Function({
        required String programId,
        String? name,
        String? portfolioId,
        String? description,
      })? onUpdate,
    }) {
      return ProviderScope(
        overrides: [
          createPortfolioListOverride(portfolios: portfolios ?? testPortfolios),
          // Create overrides for all possible portfolio IDs
          createProgramListOverride(
            programs: testPrograms,
            portfolioId: 'portfolio-1',
            onUpdate: onUpdate,
          ),
          createProgramListOverride(
            programs: testPrograms,
            portfolioId: 'portfolio-2',
            onUpdate: onUpdate,
          ),
          createProgramListOverride(
            programs: testPrograms,
            portfolioId: null,
            onUpdate: onUpdate,
          ),
          programProvider(testProgram.id).overrideWith((ref) {
            final mock = MockProgramProvider(program: program ?? testProgram);
            return mock();
          }),
          createHierarchyStateOverride(),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: EditProgramDialog(
              programId: testProgram.id,
            ),
          ),
        ),
      );
    }

    testWidgets('displays dialog with header and close button', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      // Verify header
      expect(find.text('Edit Program'), findsOneWidget);
      expect(find.text('Update program information and settings'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('displays program name field with current value', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      expect(find.text('Program Name'), findsOneWidget);
      final nameField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Program Name'),
      );
      expect(nameField.controller?.text, 'Test Program');
    });

    testWidgets('displays description field with current value', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      expect(find.text('Description (Optional)'), findsOneWidget);
      final descriptionField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Description (Optional)'),
      );
      expect(descriptionField.controller?.text, 'Test description');
    });

    testWidgets('displays portfolio dropdown with current value', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      expect(find.text('Portfolio'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('loads program data successfully', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      // Should show form after loading
      expect(find.text('Edit Program'), findsOneWidget);
      expect(find.text('Test Program'), findsOneWidget);
    });

    testWidgets('displays error when program fails to load', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          createPortfolioListOverride(portfolios: testPortfolios),
          createProgramListOverride(programs: testPrograms, portfolioId: null),
          programProvider(testProgram.id).overrideWith((ref) {
            final mock = MockProgramProvider(error: Exception('Failed to load'));
            return mock();
          }),
          createHierarchyStateOverride(),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: EditProgramDialog(programId: testProgram.id),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Should show error dialog
      expect(find.text('Error'), findsOneWidget);
      expect(find.textContaining('Failed to load program'), findsOneWidget);
    });

    testWidgets('validates required program name', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      // Clear the name field
      final nameField = find.widgetWithText(TextFormField, 'Program Name');
      await tester.enterText(nameField, '');

      // Try to submit
      final updateButton = find.widgetWithText(FilledButton, 'Update Program');
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a program name'), findsOneWidget);
    });

    testWidgets('validates minimum program name length', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      // Enter a name that's too short
      final nameField = find.widgetWithText(TextFormField, 'Program Name');
      await tester.enterText(nameField, 'AB');

      // Try to submit
      final updateButton = find.widgetWithText(FilledButton, 'Update Program');
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Program name must be at least 3 characters'), findsOneWidget);
    });

    testWidgets('updates program with valid data', (tester) async {
      bool updateCalled = false;
      Program? updatedProgram;

      await tester.pumpWidget(buildDialog(
        onUpdate: ({
          required programId,
          name,
          portfolioId,
          description,
        }) async {
          updateCalled = true;
          updatedProgram = Program(
            id: programId,
            name: name!,
            description: description,
            portfolioId: portfolioId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          return updatedProgram!;
        },
      ));
      await tester.pumpAndSettle();

      // Change program name
      final nameField = find.widgetWithText(TextFormField, 'Program Name');
      await tester.enterText(nameField, 'Updated Program');

      // Change description
      final descriptionField = find.widgetWithText(TextFormField, 'Description (Optional)');
      await tester.enterText(descriptionField, 'Updated description');

      // Submit
      final updateButton = find.widgetWithText(FilledButton, 'Update Program');
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      // Verify update was called
      expect(updateCalled, true);
      expect(updatedProgram?.name, 'Updated Program');
      expect(updatedProgram?.description, 'Updated description');
    });

    testWidgets('updates program portfolio', (tester) async {
      Program? updatedProgram;

      await tester.pumpWidget(buildDialog(
        onUpdate: ({
          required programId,
          name,
          portfolioId,
          description,
        }) async {
          updatedProgram = Program(
            id: programId,
            name: name!,
            description: description,
            portfolioId: portfolioId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          return updatedProgram!;
        },
      ));
      await tester.pumpAndSettle();

      // Change portfolio
      final dropdown = find.byType(DropdownButtonFormField<String>);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Tap on Portfolio B
      await tester.tap(find.text('Portfolio B').last);
      await tester.pumpAndSettle();

      // Submit
      final updateButton = find.widgetWithText(FilledButton, 'Update Program');
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      // Verify portfolio was changed
      expect(updatedProgram?.portfolioId, 'portfolio-2');
    });

    testWidgets('can remove portfolio (make standalone)', (tester) async {
      Program? updatedProgram;

      await tester.pumpWidget(buildDialog(
        onUpdate: ({
          required programId,
          name,
          portfolioId,
          description,
        }) async {
          updatedProgram = Program(
            id: programId,
            name: name!,
            description: description,
            portfolioId: portfolioId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          return updatedProgram!;
        },
      ));
      await tester.pumpAndSettle();

      // Change to no portfolio
      final dropdown = find.byType(DropdownButtonFormField<String>);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Tap on "No Portfolio (Standalone)"
      await tester.tap(find.text('No Portfolio (Standalone)').last);
      await tester.pumpAndSettle();

      // Submit
      final updateButton = find.widgetWithText(FilledButton, 'Update Program');
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      // Verify portfolio was removed
      expect(updatedProgram?.portfolioId, null);
    });

    testWidgets('handles update error with "already exists" message', (tester) async {
      await tester.pumpWidget(buildDialog(
        onUpdate: ({
          required programId,
          name,
          portfolioId,
          description,
        }) async {
          throw Exception('already exists');
        },
      ));
      await tester.pumpAndSettle();

      // Change program name
      final nameField = find.widgetWithText(TextFormField, 'Program Name');
      await tester.enterText(nameField, 'Duplicate Program');

      // Submit
      final updateButton = find.widgetWithText(FilledButton, 'Update Program');
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('A program with this name already exists. Please choose a different name.'), findsOneWidget);
    });

    testWidgets('handles update error with 409 conflict', (tester) async {
      await tester.pumpWidget(buildDialog(
        onUpdate: ({
          required programId,
          name,
          portfolioId,
          description,
        }) async {
          throw Exception('409 Conflict');
        },
      ));
      await tester.pumpAndSettle();

      // Change program name
      final nameField = find.widgetWithText(TextFormField, 'Program Name');
      await tester.enterText(nameField, 'Duplicate Program');

      // Submit
      final updateButton = find.widgetWithText(FilledButton, 'Update Program');
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('This program name is already taken. Please choose another name.'), findsOneWidget);
    });

    testWidgets('handles generic update error', (tester) async {
      await tester.pumpWidget(buildDialog(
        onUpdate: ({
          required programId,
          name,
          portfolioId,
          description,
        }) async {
          throw Exception('Network error');
        },
      ));
      await tester.pumpAndSettle();

      // Change program name
      final nameField = find.widgetWithText(TextFormField, 'Program Name');
      await tester.enterText(nameField, 'Updated Program');

      // Submit
      final updateButton = find.widgetWithText(FilledButton, 'Update Program');
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      // Should show generic error message
      expect(find.text('Failed to update program. Please try again.'), findsOneWidget);
    });

    testWidgets('closes dialog on cancel button', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      // Tap cancel button
      final cancelButton = find.widgetWithText(TextButton, 'Cancel');
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Dialog should be closed (no longer visible)
      expect(find.text('Edit Program'), findsNothing);
    });

    testWidgets('closes dialog on close icon button', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      // Tap close icon button
      final closeButton = find.byIcon(Icons.close);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Dialog should be closed (no longer visible)
      expect(find.text('Edit Program'), findsNothing);
    });

    testWidgets('disables inputs while updating', (tester) async {
      await tester.pumpWidget(buildDialog(
        onUpdate: ({
          required programId,
          name,
          portfolioId,
          description,
        }) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return Program(
            id: programId,
            name: name!,
            description: description,
            portfolioId: portfolioId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        },
      ));
      await tester.pumpAndSettle();

      // Change program name
      final nameField = find.widgetWithText(TextFormField, 'Program Name');
      await tester.enterText(nameField, 'Updated Program');

      // Submit
      final updateButton = find.widgetWithText(FilledButton, 'Update Program');
      await tester.tap(updateButton);
      await tester.pump(); // Pump once to start the async operation

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Complete the operation
      await tester.pumpAndSettle();
    });

    testWidgets('trims whitespace from program name and description', (tester) async {
      Program? updatedProgram;

      await tester.pumpWidget(buildDialog(
        onUpdate: ({
          required programId,
          name,
          portfolioId,
          description,
        }) async {
          updatedProgram = Program(
            id: programId,
            name: name!,
            description: description,
            portfolioId: portfolioId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          return updatedProgram!;
        },
      ));
      await tester.pumpAndSettle();

      // Enter program name with whitespace
      final nameField = find.widgetWithText(TextFormField, 'Program Name');
      await tester.enterText(nameField, '  Updated Program  ');

      // Enter description with whitespace
      final descriptionField = find.widgetWithText(TextFormField, 'Description (Optional)');
      await tester.enterText(descriptionField, '  Updated description  ');

      // Submit
      final updateButton = find.widgetWithText(FilledButton, 'Update Program');
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      // Verify whitespace was trimmed
      expect(updatedProgram?.name, 'Updated Program');
      expect(updatedProgram?.description, 'Updated description');
    });

    testWidgets('sends null description when empty', (tester) async {
      Program? updatedProgram;

      await tester.pumpWidget(buildDialog(
        onUpdate: ({
          required programId,
          name,
          portfolioId,
          description,
        }) async {
          updatedProgram = Program(
            id: programId,
            name: name!,
            description: description,
            portfolioId: portfolioId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          return updatedProgram!;
        },
      ));
      await tester.pumpAndSettle();

      // Clear description
      final descriptionField = find.widgetWithText(TextFormField, 'Description (Optional)');
      await tester.enterText(descriptionField, '');

      // Submit
      final updateButton = find.widgetWithText(FilledButton, 'Update Program');
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      // Verify description is null
      expect(updatedProgram?.description, null);
    });

    testWidgets('displays action buttons (Cancel and Update Program)', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      // Verify action buttons
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Update Program'), findsOneWidget);
    });

    testWidgets('handles program with no description', (tester) async {
      final programNoDesc = Program(
        id: 'program-1',
        name: 'Test Program',
        description: null,
        portfolioId: 'portfolio-1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(buildDialog(program: programNoDesc));
      await tester.pumpAndSettle();

      // Should show empty description field
      final descriptionField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Description (Optional)'),
      );
      expect(descriptionField.controller?.text, '');
    });

    testWidgets('handles program with no portfolio', (tester) async {
      final programNoPortfolio = Program(
        id: 'program-1',
        name: 'Test Program',
        description: 'Test description',
        portfolioId: null,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(buildDialog(program: programNoPortfolio));
      await tester.pumpAndSettle();

      // Should show "No Portfolio (Standalone)" selected in dropdown
      final dropdown = find.byType(DropdownButtonFormField<String>);
      expect(dropdown, findsOneWidget);
    });

    testWidgets('shows error state in portfolios dropdown', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          createPortfolioListOverride(error: Exception('Failed to load')),
          createProgramListOverride(programs: testPrograms, portfolioId: null),
          programProvider(testProgram.id).overrideWith((ref) {
            final mock = MockProgramProvider(program: testProgram);
            return mock();
          }),
          createHierarchyStateOverride(),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: EditProgramDialog(programId: testProgram.id),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('Failed to load portfolios'), findsOneWidget);
    });
  });
}
