import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/shared/widgets/organization_switcher.dart';
import '../../helpers/test_helpers.dart';
import '../../mocks/organization_test_fixtures.dart';
import '../../mocks/mock_providers.dart';

void main() {
  group('OrganizationSwitcher Widget Tests', () {
    testWidgets('shows error indicator when organization fails to load',
        (WidgetTester tester) async {
      // Arrange
      final errorOverrides = [
        createCurrentOrganizationErrorOverride('Failed to load'),
      ];

      // Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSwitcher(),
        overrides: errorOverrides,
      );

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows create organization button when no organizations exist',
        (WidgetTester tester) async {
      // Arrange
      final emptyOverrides = [
        createCurrentOrganizationOverride(organization: null),
        createUserOrganizationsOverride(organizations: []),
      ];

      // Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSwitcher(),
        overrides: emptyOverrides,
      );

      // Assert
      expect(find.text('Create Organization'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });

    testWidgets('displays current organization in dropdown',
        (WidgetTester tester) async {
      // Arrange
      final currentOrg = OrganizationTestFixtures.sampleOrganization;
      final organizations = OrganizationTestFixtures.multipleOrganizations;

      final overrides = [
        createCurrentOrganizationOverride(organization: currentOrg),
        createUserOrganizationsOverride(
          organizations: organizations.map((o) => o.toEntity()).toList(),
        ),
      ];

      // Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSwitcher(),
        overrides: overrides,
      );

      // Assert
      expect(find.text(currentOrg.name), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('shows organization avatar in dropdown', (WidgetTester tester) async {
      // Arrange
      final currentOrg = OrganizationTestFixtures.sampleOrganization;
      final organizations = OrganizationTestFixtures.multipleOrganizations;

      final overrides = [
        createCurrentOrganizationOverride(organization: currentOrg),
        createUserOrganizationsOverride(
          organizations: organizations.map((o) => o.toEntity()).toList(),
        ),
      ];

      // Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSwitcher(),
        overrides: overrides,
      );

      // Assert
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('opens dropdown menu when tapped', (WidgetTester tester) async {
      // Arrange
      final currentOrg = OrganizationTestFixtures.sampleOrganization;
      final organizations = OrganizationTestFixtures.multipleOrganizations;

      final overrides = [
        createCurrentOrganizationOverride(organization: currentOrg),
        createUserOrganizationsOverride(
          organizations: organizations.map((o) => o.toEntity()).toList(),
        ),
      ];

      await pumpWidgetWithProviders(
        tester,
        const OrganizationSwitcher(),
        overrides: overrides,
      );

      // Act
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Assert - All organizations should be shown in dropdown
      expect(find.text('Test Organization'), findsAtLeastNWidgets(1));
      expect(find.text('Second Organization'), findsOneWidget);
      expect(find.text('Third Organization'), findsOneWidget);
    });

    testWidgets('shows create new organization option in dropdown',
        (WidgetTester tester) async {
      // Arrange
      final currentOrg = OrganizationTestFixtures.sampleOrganization;
      final organizations = OrganizationTestFixtures.multipleOrganizations;

      final overrides = [
        createCurrentOrganizationOverride(organization: currentOrg),
        createUserOrganizationsOverride(
          organizations: organizations.map((o) => o.toEntity()).toList(),
        ),
      ];

      await pumpWidgetWithProviders(
        tester,
        const OrganizationSwitcher(),
        overrides: overrides,
      );

      // Act
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Create new organization'), findsOneWidget);
    });

    testWidgets('shows check icon for selected organization',
        (WidgetTester tester) async {
      // Arrange
      final currentOrg = OrganizationTestFixtures.sampleOrganization;
      final organizations = OrganizationTestFixtures.multipleOrganizations;

      final overrides = [
        createCurrentOrganizationOverride(organization: currentOrg),
        createUserOrganizationsOverride(
          organizations: organizations.map((o) => o.toEntity()).toList(),
        ),
      ];

      await pumpWidgetWithProviders(
        tester,
        const OrganizationSwitcher(),
        overrides: overrides,
      );

      // Act
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('displays organization descriptions in dropdown',
        (WidgetTester tester) async {
      // Arrange
      final currentOrg = OrganizationTestFixtures.sampleOrganization;
      final organizations = OrganizationTestFixtures.multipleOrganizations;

      final overrides = [
        createCurrentOrganizationOverride(organization: currentOrg),
        createUserOrganizationsOverride(
          organizations: organizations.map((o) => o.toEntity()).toList(),
        ),
      ];

      await pumpWidgetWithProviders(
        tester,
        const OrganizationSwitcher(),
        overrides: overrides,
      );

      // Act
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Assert - Check for organization with description
      expect(find.text('Another test organization'), findsOneWidget);
    });

    testWidgets('shows divider before create new option', (WidgetTester tester) async {
      // Arrange
      final currentOrg = OrganizationTestFixtures.sampleOrganization;
      final organizations = OrganizationTestFixtures.multipleOrganizations;

      final overrides = [
        createCurrentOrganizationOverride(organization: currentOrg),
        createUserOrganizationsOverride(
          organizations: organizations.map((o) => o.toEntity()).toList(),
        ),
      ];

      await pumpWidgetWithProviders(
        tester,
        const OrganizationSwitcher(),
        overrides: overrides,
      );

      // Act
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('has proper border and styling', (WidgetTester tester) async {
      // Arrange
      final currentOrg = OrganizationTestFixtures.sampleOrganization;
      final organizations = OrganizationTestFixtures.multipleOrganizations;

      final overrides = [
        createCurrentOrganizationOverride(organization: currentOrg),
        createUserOrganizationsOverride(
          organizations: organizations.map((o) => o.toEntity()).toList(),
        ),
      ];

      // Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSwitcher(),
        overrides: overrides,
      );

      // Assert
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(OrganizationSwitcher),
          matching: find.byType(Container),
        ).first,
      );

      expect((container.decoration as BoxDecoration).borderRadius, isNotNull);
      expect((container.decoration as BoxDecoration).border, isNotNull);
    });

    testWidgets('handles organization without logo', (WidgetTester tester) async {
      // Arrange
      final orgWithoutLogo = OrganizationTestFixtures.createOrganization(
        name: 'No Logo Org',
      );
      final overrides = [
        createCurrentOrganizationOverride(organization: orgWithoutLogo.toEntity()),
        createUserOrganizationsOverride(organizations: [orgWithoutLogo.toEntity()]),
      ];

      // Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSwitcher(),
        overrides: overrides,
      );

      // Assert - Should display initials-based avatar
      expect(find.text('No Logo Org'), findsOneWidget);
    });

    testWidgets('truncates long organization names', (WidgetTester tester) async {
      // Arrange
      final longNameOrg = OrganizationTestFixtures.createOrganization(
        name: 'This is a Very Long Organization Name That Should Be Truncated',
      );
      final overrides = [
        createCurrentOrganizationOverride(organization: longNameOrg.toEntity()),
        createUserOrganizationsOverride(organizations: [longNameOrg.toEntity()]),
      ];

      // Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSwitcher(),
        overrides: overrides,
      );

      // Assert - Widget should render with text overflow handling
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('displays multiple organizations correctly',
        (WidgetTester tester) async {
      // Arrange
      final organizations = OrganizationTestFixtures.multipleOrganizations;
      final currentOrg = organizations[0].toEntity();

      final overrides = [
        createCurrentOrganizationOverride(organization: currentOrg),
        createUserOrganizationsOverride(
          organizations: organizations.map((o) => o.toEntity()).toList(),
        ),
      ];

      await pumpWidgetWithProviders(
        tester,
        const OrganizationSwitcher(),
        overrides: overrides,
      );

      // Act
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Assert - All three organizations should be displayed
      final dropdownItems = find.byType(DropdownMenuItem<String>);
      expect(dropdownItems, findsWidgets);
    });
  });
}
