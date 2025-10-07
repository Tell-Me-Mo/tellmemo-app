import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/hierarchy/presentation/widgets/create_project_from_hierarchy_dialog.dart';
import 'package:pm_master_v2/features/hierarchy/domain/entities/portfolio.dart';
import 'package:pm_master_v2/features/hierarchy/domain/entities/program.dart';
import 'package:pm_master_v2/features/projects/domain/entities/project.dart';
import '../../../../helpers/test_helpers.dart';
import '../../../../mocks/mock_providers.dart';

void main() {
  late List<Portfolio> testPortfolios;
  late List<Program> testPrograms;

  setUp(() {
    testPortfolios = [
      Portfolio(
        id: 'portfolio-1',
        name: 'Portfolio A',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        programs: [],
        directProjects: [],
      ),
      Portfolio(
        id: 'portfolio-2',
        name: 'Portfolio B',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        programs: [],
        directProjects: [],
      ),
    ];

    testPrograms = [
      Program(
        id: 'program-1',
        name: 'Program 1',
        portfolioId: 'portfolio-1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        projects: [],
      ),
      Program(
        id: 'program-2',
        name: 'Program 2',
        portfolioId: 'portfolio-1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        projects: [],
      ),
    ];
  });

  Future<void> pumpTestDialog(
    WidgetTester tester, {
    String? preselectedPortfolioId,
    String? preselectedProgramId,
    Future<Project> Function({
      required String name,
      required String description,
      required String createdBy,
      String? portfolioId,
      String? programId,
    })? onCreate,
  }) async {
    final overrides = [
      createPortfolioListOverride(portfolios: testPortfolios),
      createProgramListOverride(programs: testPrograms),
      createProjectsListOverride(onCreate: onCreate),
    ];

    await pumpWidgetWithProviders(
      tester,
      Builder(
        builder: (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => CreateProjectDialogFromHierarchy(
                    preselectedPortfolioId: preselectedPortfolioId,
                    preselectedProgramId: preselectedProgramId,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          );
        },
      ),
      overrides: overrides,
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();
  }

  group('CreateProjectDialogFromHierarchy', () {
    testWidgets('displays dialog with Material widget (bug fix verification)', (tester) async {
      await pumpTestDialog(tester);

      // Should render without Material widget errors
      expect(find.byType(CreateProjectDialogFromHierarchy), findsOneWidget);
      expect(find.byType(Material), findsWidgets);
    });

    testWidgets('displays header with close button', (tester) async {
      await pumpTestDialog(tester);

      // Should show header
      expect(find.text('Create New Project'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('displays project name field', (tester) async {
      await pumpTestDialog(tester);

      // Should show name field
      expect(find.text('Project Name'), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('displays description field', (tester) async {
      await pumpTestDialog(tester);

      // Should show description field
      expect(find.text('Description (Optional)'), findsOneWidget);
    });

    testWidgets('validates required project name', (tester) async {
      await pumpTestDialog(tester);

      // Try to submit without name
      await tester.tap(find.text('Create Project'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a project name'), findsOneWidget);
    });

    testWidgets('validates minimum name length', (tester) async {
      await pumpTestDialog(tester);

      // Enter short name
      await tester.enterText(find.byType(TextFormField).first, 'AB');
      await tester.tap(find.text('Create Project'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Project name must be at least 3 characters'), findsOneWidget);
    });

    testWidgets('cancel button closes dialog', (tester) async {
      await pumpTestDialog(tester);

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.byType(CreateProjectDialogFromHierarchy), findsNothing);
    });

    testWidgets('close button closes dialog', (tester) async {
      await pumpTestDialog(tester);

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.byType(CreateProjectDialogFromHierarchy), findsNothing);
    });

    testWidgets('displays portfolio dropdown when portfolios exist', (tester) async {
      await pumpTestDialog(tester);

      // Should show portfolio section
      expect(find.text('Portfolio (Optional)'), findsOneWidget);
    });

    testWidgets('pre-selects portfolio when provided', (tester) async {
      await pumpTestDialog(tester, preselectedPortfolioId: 'portfolio-1');

      // Should have portfolio pre-selected (Portfolio A should be visible)
      expect(find.text('Portfolio A'), findsOneWidget);
    });

    testWidgets('creates project with valid data', (tester) async {
      String? capturedName;
      String? capturedDescription;

      await pumpTestDialog(
        tester,
        onCreate: ({
          required String name,
          required String description,
          required String createdBy,
          String? portfolioId,
          String? programId,
        }) async {
          capturedName = name;
          capturedDescription = description;

          return Project(
            id: 'new-project',
            name: name,
            description: description,
            status: ProjectStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: createdBy,
            portfolioId: portfolioId,
            programId: programId,
          );
        },
      );

      // Enter project name
      await tester.enterText(find.byType(TextFormField).first, 'New Test Project');

      // Enter description
      await tester.enterText(find.byType(TextFormField).at(1), 'Test description');

      // Submit
      await tester.tap(find.text('Create Project'));
      await tester.pumpAndSettle();

      // Verify project was created with correct data
      expect(capturedName, 'New Test Project');
      expect(capturedDescription, 'Test description');
    });

    testWidgets('handles creation error', (tester) async {
      await pumpTestDialog(
        tester,
        onCreate: ({
          required String name,
          required String description,
          required String createdBy,
          String? portfolioId,
          String? programId,
        }) async {
          throw Exception('Failed to create project');
        },
      );

      // Enter valid data
      await tester.enterText(find.byType(TextFormField).first, 'Test Project');

      // Submit
      await tester.tap(find.text('Create Project'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.textContaining('Failed to create project'), findsOneWidget);

      // Dialog should still be open
      expect(find.byType(CreateProjectDialogFromHierarchy), findsOneWidget);
    });
  });
}
