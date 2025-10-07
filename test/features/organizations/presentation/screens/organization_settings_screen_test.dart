import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/organizations/presentation/screens/organization_settings_screen.dart';
import '../../../../helpers/test_helpers.dart';
import '../../../../mocks/organization_test_fixtures.dart';
import '../../../../mocks/mock_providers.dart';

void main() {
  group('OrganizationSettingsScreen Widget Tests', () {
    late List<Override> mockOverrides;

    setUp(() {
      final sampleOrg = OrganizationTestFixtures.sampleOrganization;

      mockOverrides = [
        createCurrentOrganizationOverride(organization: sampleOrg),
        createProjectsListOverride(),
        createDocumentsStatisticsOverride(),
      ];
    });

    testWidgets('renders all main sections when loaded', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSettingsScreen(),
        overrides: mockOverrides,
      );

      // Assert
      expect(find.text('Organization Settings'), findsOneWidget);
      expect(find.text('Manage your organization configuration and preferences'), findsOneWidget);
      expect(find.text('Organization Profile'), findsOneWidget);
      expect(find.text('Data Management'), findsOneWidget);
      expect(find.text('Notification Preferences'), findsOneWidget);
    });

    testWidgets('shows loading indicator when organization is loading', (WidgetTester tester) async {
      // Arrange
      final loadingOverrides = [
        createCurrentOrganizationLoadingOverride(),
      ];

      // Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSettingsScreen(),
        overrides: loadingOverrides,
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state when organization fails to load', (WidgetTester tester) async {
      // Arrange
      final errorOverrides = [
        createCurrentOrganizationErrorOverride('Failed to load'),
      ];

      // Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSettingsScreen(),
        overrides: errorOverrides,
      );

      // Assert
      expect(find.text('Error loading organization'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('displays organization profile section with name and description fields',
        (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSettingsScreen(),
        overrides: mockOverrides,
      );

      // Assert
      expect(find.text('Organization Profile'), findsOneWidget);
      expect(find.text('Organization Name'), findsOneWidget);
      expect(find.text('Description (Optional)'), findsOneWidget);
      expect(find.byIcon(Icons.business), findsAtLeastNWidgets(1));
    });

    testWidgets('shows edit button for admin users', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSettingsScreen(),
        overrides: mockOverrides,
      );

      // Assert
      expect(find.text('Edit Settings'), findsOneWidget);
    });

    testWidgets('hides edit button for non-admin users', (WidgetTester tester) async {
      // Arrange
      final memberOrg = OrganizationTestFixtures.sampleOrganizationAsMember.toEntity();
      final memberOverrides = [
        createCurrentOrganizationOverride(organization: memberOrg),
        createProjectsListOverride(),
        createDocumentsStatisticsOverride(),
      ];

      // Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSettingsScreen(),
        overrides: memberOverrides,
      );

      // Assert
      expect(find.text('Edit Settings'), findsNothing);
    });

    testWidgets('enables edit mode when edit button is tapped', (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSettingsScreen(),
        overrides: mockOverrides,
      );

      // Act
      await tester.tap(find.text('Edit Settings'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('shows data retention dropdown with all options', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSettingsScreen(),
        overrides: mockOverrides,
      );

      // Assert
      expect(find.text('Data Retention Period'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('shows notification settings switches', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSettingsScreen(),
        overrides: mockOverrides,
      );

      // Assert
      expect(find.text('Email Notifications'), findsOneWidget);
      expect(find.text('Weekly Reports'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNWidgets(2));
    });

    testWidgets('shows danger zone for admin users', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSettingsScreen(),
        overrides: mockOverrides,
      );

      // Assert
      expect(find.text('Danger Zone'), findsOneWidget);
      expect(find.text('Delete Organization'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('hides danger zone for non-admin users', (WidgetTester tester) async {
      // Arrange
      final memberOrg = OrganizationTestFixtures.sampleOrganizationAsMember.toEntity();
      final memberOverrides = [
        createCurrentOrganizationOverride(organization: memberOrg),
        createProjectsListOverride(),
        createDocumentsStatisticsOverride(),
      ];

      // Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSettingsScreen(),
        overrides: memberOverrides,
      );

      // Assert
      expect(find.text('Danger Zone'), findsNothing);
      expect(find.text('Delete Organization'), findsNothing);
    });

    testWidgets('shows quick actions section', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSettingsScreen(),
        overrides: mockOverrides,
        screenSize: const Size(1400, 900), // Desktop size
      );

      // Assert
      expect(find.text('Quick Actions'), findsAtLeastNWidgets(1));
      expect(find.text('Manage Members'), findsOneWidget);
      expect(find.text('Backup Data'), findsOneWidget);
      expect(find.text('View Analytics'), findsOneWidget);
    });

    testWidgets('shows organization statistics panel', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSettingsScreen(),
        overrides: mockOverrides,
        screenSize: const Size(1400, 900), // Desktop size
      );

      // Assert
      expect(find.text('Organization Overview'), findsOneWidget);
      // "Members" might appear in multiple places (stats + quick actions grid)
      expect(find.text('Members'), findsAtLeast(1));
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
    });

    testWidgets('shows admin quick links for admin users', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSettingsScreen(),
        overrides: mockOverrides,
        screenSize: const Size(1400, 900), // Desktop size
      );

      // Assert
      expect(find.text('Admin Controls'), findsOneWidget);
      expect(find.text('Admin Panel'), findsOneWidget);
      expect(find.text('Security Settings'), findsOneWidget);
      expect(find.text('Billing & Usage'), findsOneWidget);
    });

    testWidgets('can cancel edit mode', (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSettingsScreen(),
        overrides: mockOverrides,
      );

      // Act - Enter edit mode
      await tester.tap(find.text('Edit Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel'), findsOneWidget);

      // Act - Cancel edit mode
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Edit Settings'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('displays pull to refresh indicator', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSettingsScreen(),
        overrides: mockOverrides,
      );

      // Assert
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('fields are disabled when not in edit mode', (WidgetTester tester) async {
      // Arrange & Act
      await pumpWidgetWithProviders(
        tester,
        const OrganizationSettingsScreen(),
        overrides: mockOverrides,
      );

      // Assert - Fields should be disabled (enabled=false)
      final textFields = tester.widgetList<TextFormField>(find.byType(TextFormField));
      for (final field in textFields) {
        expect(field.enabled, isFalse);
      }
    });
  });
}
