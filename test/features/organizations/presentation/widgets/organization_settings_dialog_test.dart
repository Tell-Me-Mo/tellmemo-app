import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/organizations/domain/entities/organization.dart';
import 'package:pm_master_v2/features/organizations/presentation/widgets/organization_settings_dialog.dart';
import '../../../../helpers/test_helpers.dart';
import '../../../../mocks/organization_test_fixtures.dart';
import '../../../../mocks/mock_providers.dart';

void main() {
  group('OrganizationSettingsDialog', () {
    late Organization testOrganization;
    late Organization memberOrganization;

    setUp(() {
      testOrganization = OrganizationTestFixtures.sampleOrganization;
      memberOrganization = OrganizationTestFixtures.sampleOrganizationAsMember.toEntity();
    });

    Future<void> pumpDialogWithSize(
      WidgetTester tester, {
      required Organization organization,
      double screenWidth = 1920,
      double screenHeight = 1080,
    }) async {
      final overrides = [
        createCurrentOrganizationOverride(organization: organization),
        createProjectsListOverride(),
        createDocumentsStatisticsOverride(),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(screenWidth, screenHeight),
            ),
            child: const MaterialApp(
              home: Scaffold(
                body: OrganizationSettingsDialog(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    group('Mobile Layout', () {
      testWidgets('displays mobile tabs on screen width <= 768', (tester) async {
        await pumpDialogWithSize(
          tester,
          organization: testOrganization,
          screenWidth: 768,
          screenHeight: 1024,
        );

        // Verify mobile tabs are present (horizontal scrollable)
        expect(find.text('General'), findsOneWidget);
        expect(find.text('Notifications'), findsOneWidget);
        expect(find.text('Data'), findsOneWidget);
        expect(find.text('Danger'), findsOneWidget);

        // Mobile layout should show header with title
        expect(find.text('General Settings'), findsOneWidget);
      });

      testWidgets('displays full-screen dialog on mobile', (tester) async {
        await pumpDialogWithSize(
          tester,
          organization: testOrganization,
          screenWidth: 375,
          screenHeight: 812,
        );

        // Find the dialog container
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(Dialog),
            matching: find.byType(Container),
          ).first,
        );

        // Mobile should have zero border radius for full-screen appearance
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.zero);
      });

      testWidgets('displays desktop sidebar layout for screen width > 1200', (tester) async {
        await pumpDialogWithSize(
          tester,
          organization: testOrganization,
          screenWidth: 1920,
          screenHeight: 1080,
        );

        // Desktop layout should show sidebar with organization info
        expect(find.text('T'), findsOneWidget); // Organization avatar initial
        expect(find.text('Admin'), findsOneWidget); // Admin badge in sidebar
      });

      testWidgets('hides sidebar on mobile screens', (tester) async {
        await pumpDialogWithSize(
          tester,
          organization: testOrganization,
          screenWidth: 600,
          screenHeight: 800,
        );

        // Mobile layout should not show organization avatar initial 'T' in sidebar
        final organizationInitial = find.text('T');
        expect(organizationInitial, findsNothing);
      });

      testWidgets('shows all tabs for admin user including Danger zone', (tester) async {
        await pumpDialogWithSize(
          tester,
          organization: testOrganization,
          screenWidth: 375,
          screenHeight: 812,
        );

        // Admin should see Danger tab
        expect(find.text('Danger'), findsOneWidget);
      });

      testWidgets('hides Danger tab for non-admin user on mobile', (tester) async {
        await pumpDialogWithSize(
          tester,
          organization: memberOrganization,
          screenWidth: 375,
          screenHeight: 812,
        );

        // Member should not see Danger tab
        expect(find.text('Danger'), findsNothing);
      });
    });

    group('Mobile Tab Navigation', () {
      testWidgets('mobile tabs are horizontally scrollable', (tester) async {
        await pumpDialogWithSize(
          tester,
          organization: testOrganization,
          screenWidth: 320,
          screenHeight: 568,
        );

        // Find the ListView containing mobile tabs
        final listView = find.byType(ListView);
        expect(listView, findsAtLeastNWidgets(1));

        // Should have multiple tab items (InkWell for tap detection)
        final tabItems = find.byType(InkWell);
        expect(tabItems, findsAtLeastNWidgets(4));
      });

      testWidgets('mobile tabs have proper styling', (tester) async {
        await pumpDialogWithSize(
          tester,
          organization: testOrganization,
          screenWidth: 375,
          screenHeight: 812,
        );

        // Verify tab text exists
        final generalTab = find.text('General');
        expect(generalTab, findsOneWidget);

        // Find container wrapping the tab
        final tabContainer = find.ancestor(
          of: generalTab,
          matching: find.byType(Container),
        );
        expect(tabContainer, findsAtLeastNWidgets(1));
      });
    });

    group('Responsive Behavior', () {
      testWidgets('adjusts content padding for mobile vs desktop', (tester) async {
        // Test mobile
        await pumpDialogWithSize(
          tester,
          organization: testOrganization,
          screenWidth: 375,
          screenHeight: 812,
        );

        // Should have scrollable content
        expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));

        // Test desktop
        await pumpDialogWithSize(
          tester,
          organization: testOrganization,
          screenWidth: 1920,
          screenHeight: 1080,
        );

        // Desktop should also have scrollable content
        expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
      });

      testWidgets('close button is present on both mobile and desktop', (tester) async {
        // Test on mobile
        await pumpDialogWithSize(
          tester,
          organization: testOrganization,
          screenWidth: 375,
          screenHeight: 812,
        );
        expect(find.byIcon(Icons.close), findsOneWidget);

        // Test on desktop
        await pumpDialogWithSize(
          tester,
          organization: testOrganization,
          screenWidth: 1920,
          screenHeight: 1080,
        );
        expect(find.byIcon(Icons.close), findsOneWidget);
      });
    });

    group('Content Display', () {
      testWidgets('displays organization name and description on mobile', (tester) async {
        await pumpDialogWithSize(
          tester,
          organization: testOrganization,
          screenWidth: 375,
          screenHeight: 812,
        );

        // Should display organization name in text field
        expect(find.text('Test Organization'), findsOneWidget);

        // Should display description in text field
        expect(find.text('A test organization for unit testing'), findsOneWidget);
      });

      testWidgets('shows correct initial view title', (tester) async {
        await pumpDialogWithSize(
          tester,
          organization: testOrganization,
          screenWidth: 375,
          screenHeight: 812,
        );

        // Initially on General tab
        expect(find.text('General Settings'), findsOneWidget);
        expect(find.text('Basic Information'), findsOneWidget);
      });
    });
  });
}
