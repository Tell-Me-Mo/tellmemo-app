import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/features/projects/presentation/widgets/edit_project_dialog.dart';
import 'package:pm_master_v2/features/projects/domain/entities/project.dart';
import '../../../../helpers/test_helpers.dart';
import '../../../../mocks/mock_providers.dart';

void main() {
  late Project testProject;

  setUp(() {
    testProject = Project(
      id: 'project-1',
      name: 'Test Project',
      description: 'Original description',
      status: ProjectStatus.active,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 5),
      createdBy: 'test@example.com',
      memberCount: 3,
    );
  });

  Future<void> pumpTestWidget(
    WidgetTester tester, {
    Map<String, dynamic> Function(String, Map<String, dynamic>)? onUpdate,
  }) async {
    final overrides = [
      createProjectsListOverride(onUpdate: onUpdate),
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
                  builder: (_) => EditProjectDialog(project: testProject),
                );
              },
              child: const Text('Show Dialog'),
            ),
          );
        },
      ),
      overrides: overrides,
    );
  }

  group('EditProjectDialog', () {
    testWidgets('displays project information correctly', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Edit Project'), findsOneWidget);
      expect(find.text('Update project information and status'), findsOneWidget);

      // Check form fields are pre-filled
      expect(find.text('Test Project'), findsOneWidget);
      expect(find.text('Original description'), findsOneWidget);

      // Check project info section
      expect(find.text('Created: 01/01/2024'), findsOneWidget);
      expect(find.text('Updated: 05/01/2024'), findsOneWidget);
      expect(find.text('Members: 3'), findsOneWidget);

      // Check buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Update Project'), findsOneWidget);
    });

    testWidgets('displays status dropdown with current status', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Check status dropdown shows Active
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('validates project name is required', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Clear the name field
      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.tap(find.text('Update Project'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a project name'), findsOneWidget);
    });

    testWidgets('validates project name minimum length', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter short name
      await tester.enterText(find.byType(TextFormField).first, 'AB');
      await tester.tap(find.text('Update Project'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Project name must be at least 3 characters'), findsOneWidget);
    });

    testWidgets('successfully updates project with valid data', (tester) async {
      String? capturedId;
      Map<String, dynamic>? capturedUpdates;

      await pumpTestWidget(
        tester,
        onUpdate: (id, updates) {
          capturedId = id;
          capturedUpdates = updates;
          return updates;
        },
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Update project name
      await tester.enterText(find.byType(TextFormField).first, 'Updated Project');

      // Update description
      await tester.enterText(find.byType(TextFormField).at(1), 'Updated description');

      await tester.tap(find.text('Update Project'));
      await tester.pumpAndSettle();

      // Verify update was called with correct data
      expect(capturedId, 'project-1');
      expect(capturedUpdates?['name'], 'Updated Project');
      expect(capturedUpdates?['description'], 'Updated description');
      expect(capturedUpdates?['status'], 'active');

      // Dialog should be closed
      expect(find.byType(EditProjectDialog), findsNothing);

      // Success snackbar should be shown
      expect(find.text('Project "Updated Project" updated successfully'), findsOneWidget);
    });

    testWidgets('updates project status correctly', (tester) async {
      Map<String, dynamic>? capturedUpdates;

      await pumpTestWidget(
        tester,
        onUpdate: (id, updates) {
          capturedUpdates = updates;
          return updates;
        },
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Open status dropdown
      await tester.tap(find.byType(DropdownButtonFormField<ProjectStatus>));
      await tester.pumpAndSettle();

      // Select Archived
      await tester.tap(find.text('Archived').last);
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Update Project'));
      await tester.pumpAndSettle();

      // Verify status was updated
      expect(capturedUpdates?['status'], 'archived');
    });

    testWidgets('handles duplicate name error (409)', (tester) async {
      await pumpTestWidget(
        tester,
        onUpdate: (id, updates) {
          throw Exception('409');
        },
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Try to update
      await tester.enterText(find.byType(TextFormField).first, 'Duplicate Name');
      await tester.tap(find.text('Update Project'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('This project name is already taken. Please choose another name.'), findsOneWidget);

      // Dialog should still be open
      expect(find.byType(EditProjectDialog), findsOneWidget);
    });

    testWidgets('handles "already exists" error message', (tester) async {
      await pumpTestWidget(
        tester,
        onUpdate: (id, updates) {
          throw Exception('Project already exists');
        },
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Try to update
      await tester.enterText(find.byType(TextFormField).first, 'Existing Project');
      await tester.tap(find.text('Update Project'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('A project with this name already exists. Please choose a different name.'), findsOneWidget);

      // Dialog should still be open
      expect(find.byType(EditProjectDialog), findsOneWidget);
    });

    testWidgets('handles generic error', (tester) async {
      await pumpTestWidget(
        tester,
        onUpdate: (id, updates) {
          throw Exception('Network error');
        },
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Try to update
      await tester.enterText(find.byType(TextFormField).first, 'New Name');
      await tester.tap(find.text('Update Project'));
      await tester.pumpAndSettle();

      // Should show generic error message
      expect(find.text('Failed to update project. Please try again.'), findsOneWidget);

      // Dialog should still be open
      expect(find.byType(EditProjectDialog), findsOneWidget);
    });

    testWidgets('cancel button closes dialog', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.byType(EditProjectDialog), findsNothing);
    });

    testWidgets('close button in header closes dialog', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap close button (IconButton with close icon)
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.byType(EditProjectDialog), findsNothing);
    });

    testWidgets('description field is optional', (tester) async {
      String? capturedId;

      await pumpTestWidget(
        tester,
        onUpdate: (id, updates) {
          capturedId = id;
          return updates;
        },
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Clear description
      await tester.enterText(find.byType(TextFormField).at(1), '');
      await tester.tap(find.text('Update Project'));
      await tester.pumpAndSettle();

      // Update should succeed
      expect(capturedId, 'project-1');
    });

    testWidgets('displays edit icon in header', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Check for edit icon
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('displays project without member count', (tester) async {
      final projectWithoutMembers = Project(
        id: 'project-2',
        name: 'Test Project',
        description: 'Description',
        status: ProjectStatus.active,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        memberCount: null,
      );

      final overrides = [createProjectsListOverride()];

      await pumpWidgetWithProviders(
        tester,
        Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => EditProjectDialog(project: projectWithoutMembers),
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

      // Members info should not be shown
      expect(find.textContaining('Members:'), findsNothing);
    });
  });
}
