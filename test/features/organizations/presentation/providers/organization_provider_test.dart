import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pm_master_v2/features/organizations/data/models/create_organization_request.dart';
import 'package:pm_master_v2/features/organizations/presentation/providers/organization_provider.dart';
import '../../../../mocks/generate_mocks.mocks.dart';
import '../../../../mocks/organization_test_fixtures.dart';
import '../../../../mocks/mock_auth_providers.dart';

void main() {
  group('Organization Provider Tests', () {
    late MockOrganizationApiService mockApiService;
    late MockSecureStorage mockSecureStorage;
    late ProviderContainer container;

    setUp(() {
      mockApiService = MockOrganizationApiService();
      mockSecureStorage = MockSecureStorage();
    });

    tearDown(() {
      container.dispose();
    });

    group('CurrentOrganization Provider', () {
      test('builds with null when user is not authenticated', () async {
        // Arrange
        when(mockSecureStorage.read('current_organization_id')).thenAnswer((_) async => null);
        when(mockSecureStorage.delete('current_organization_id')).thenAnswer((_) async {});

        container = createUnauthenticatedContainer(
          additionalOverrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
            secureStorageProvider.overrideWithValue(mockSecureStorage),
          ],
        );

        // Act
        final org = await container.read(currentOrganizationProvider.future);

        // Assert
        expect(org, isNull);
        verify(mockSecureStorage.delete('current_organization_id')).called(1);
      });

      test('loads organization from storage when user is authenticated', () async {
        // Arrange
        const orgId = 'org-1';
        final organization = OrganizationTestFixtures.sampleOrganizationModel;

        when(mockSecureStorage.read('current_organization_id')).thenAnswer((_) async => orgId);
        when(mockApiService.getOrganization(orgId)).thenAnswer((_) async => organization);

        container = createAuthenticatedContainer(
          additionalOverrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
            secureStorageProvider.overrideWithValue(mockSecureStorage),
          ],
        );

        // Act
        final org = await container.read(currentOrganizationProvider.future);

        // Assert
        expect(org, isNotNull);
        expect(org!.id, orgId);
        expect(org.name, organization.name);
        verify(mockSecureStorage.read('current_organization_id')).called(greaterThanOrEqualTo(1));
        verify(mockApiService.getOrganization(orgId)).called(1);
      });

      test('clears storage and returns null when stored organization not found (404)', () async {
        // Arrange
        const orgId = 'org-1';
        final exception = DioException(
          requestOptions: RequestOptions(path: '/api/v1/organizations/$orgId'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/organizations/$orgId'),
            statusCode: 404,
          ),
        );

        when(mockSecureStorage.read('current_organization_id')).thenAnswer((_) async => orgId);
        when(mockSecureStorage.delete('current_organization_id')).thenAnswer((_) async {});
        when(mockApiService.getOrganization(orgId)).thenThrow(exception);
        when(mockApiService.listUserOrganizations()).thenAnswer((_) async => {'organizations': []});

        container = createAuthenticatedContainer(
          additionalOverrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
            secureStorageProvider.overrideWithValue(mockSecureStorage),
          ],
        );

        // Act
        final org = await container.read(currentOrganizationProvider.future);

        // Assert
        expect(org, isNull);
        verify(mockSecureStorage.delete('current_organization_id')).called(1);
      });

      test('switchOrganization updates state and persists to storage', () async {
        // Arrange
        const orgId = 'org-1';
        const newOrgId = 'org-2';
        final initialOrg = OrganizationTestFixtures.sampleOrganizationModel;
        final newOrg = OrganizationTestFixtures.sampleOrganizationModel.copyWith(
          id: newOrgId,
          name: 'New Organization',
        );

        when(mockSecureStorage.read('current_organization_id')).thenAnswer((_) async => orgId);
        when(mockSecureStorage.write('current_organization_id', any)).thenAnswer((_) async {});
        when(mockApiService.getOrganization(orgId)).thenAnswer((_) async => initialOrg);
        when(mockApiService.switchOrganization(newOrgId)).thenAnswer((_) async => {});
        when(mockApiService.getOrganization(newOrgId)).thenAnswer((_) async => newOrg);
        when(mockApiService.listUserOrganizations()).thenAnswer((_) async => {
              'organizations': [initialOrg.toJson(), newOrg.toJson()]
            });

        container = createAuthenticatedContainer(
          additionalOverrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
            secureStorageProvider.overrideWithValue(mockSecureStorage),
          ],
        );

        // Load initial organization
        final initialState = await container.read(currentOrganizationProvider.future);
        expect(initialState!.id, orgId);

        // Act - switch organization
        await container.read(currentOrganizationProvider.notifier).switchOrganization(newOrgId);

        // Assert
        final updatedState = await container.read(currentOrganizationProvider.future);
        expect(updatedState!.id, newOrgId);
        expect(updatedState.name, 'New Organization');
        verify(mockApiService.switchOrganization(newOrgId)).called(1);
        verify(mockSecureStorage.write('current_organization_id', newOrgId)).called(1);
      });

      test('switchOrganization triggers organizationChangedProvider', () async {
        // Arrange
        const newOrgId = 'org-2';
        final newOrg = OrganizationTestFixtures.sampleOrganizationModel.copyWith(
          id: newOrgId,
          name: 'New Organization',
        );

        when(mockSecureStorage.read('current_organization_id')).thenAnswer((_) async => null);
        when(mockSecureStorage.write('current_organization_id', any)).thenAnswer((_) async {});
        when(mockApiService.switchOrganization(newOrgId)).thenAnswer((_) async => {});
        when(mockApiService.getOrganization(newOrgId)).thenAnswer((_) async => newOrg);
        when(mockApiService.listUserOrganizations()).thenAnswer((_) async => {
              'organizations': [newOrg.toJson()]
            });

        container = createAuthenticatedContainer(
          additionalOverrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
            secureStorageProvider.overrideWithValue(mockSecureStorage),
          ],
        );

        // Track organizationChangedProvider state
        final initialCounter = container.read(organizationChangedProvider);

        // Act
        await container.read(currentOrganizationProvider.notifier).switchOrganization(newOrgId);

        // Assert
        final updatedCounter = container.read(organizationChangedProvider);
        expect(updatedCounter, greaterThan(initialCounter));
      });

      test('switchOrganization propagates error when API call fails', () async {
        // Arrange
        const newOrgId = 'org-2';

        when(mockSecureStorage.read('current_organization_id')).thenAnswer((_) async => null);
        when(mockApiService.switchOrganization(newOrgId)).thenThrow(Exception('Network error'));
        when(mockApiService.listUserOrganizations()).thenAnswer((_) async => {'organizations': []});

        container = createAuthenticatedContainer(
          additionalOverrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
            secureStorageProvider.overrideWithValue(mockSecureStorage),
          ],
        );

        // Act & Assert
        await expectLater(
          container.read(currentOrganizationProvider.notifier).switchOrganization(newOrgId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('UserOrganizations Provider', () {
      test('successfully loads list of organizations', () async {
        // Arrange
        final organizations = OrganizationTestFixtures.multipleOrganizations;

        when(mockApiService.listUserOrganizations()).thenAnswer((_) async => {
              'organizations': organizations.map((o) => o.toJson()).toList()
            });

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Act
        final orgs = await container.read(userOrganizationsProvider.future);

        // Assert
        expect(orgs.length, organizations.length);
        expect(orgs.first.id, organizations.first.id);
        verify(mockApiService.listUserOrganizations()).called(1);
      });

      test('returns empty list when no organizations', () async {
        // Arrange
        when(mockApiService.listUserOrganizations()).thenAnswer((_) async => {'organizations': []});

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Act
        final orgs = await container.read(userOrganizationsProvider.future);

        // Assert
        expect(orgs, isEmpty);
      });

      test('propagates error when API call fails', () async {
        // Arrange
        when(mockApiService.listUserOrganizations()).thenThrow(Exception('Network error'));

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Act & Assert
        await expectLater(
          container.read(userOrganizationsProvider.future),
          throwsA(isA<Exception>()),
        );
      });

      test('refresh invalidates and reloads data', () async {
        // Arrange
        final initialOrgs = [OrganizationTestFixtures.sampleOrganizationModel];
        final updatedOrgs = OrganizationTestFixtures.multipleOrganizations;

        var callCount = 0;
        when(mockApiService.listUserOrganizations()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return {'organizations': initialOrgs.map((o) => o.toJson()).toList()};
          } else {
            return {'organizations': updatedOrgs.map((o) => o.toJson()).toList()};
          }
        });

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Load initial data
        final orgs1 = await container.read(userOrganizationsProvider.future);
        expect(orgs1.length, initialOrgs.length);

        // Act - refresh
        await container.read(userOrganizationsProvider.notifier).refresh();

        // Assert
        final orgs2 = await container.read(userOrganizationsProvider.future);
        expect(orgs2.length, updatedOrgs.length);
        verify(mockApiService.listUserOrganizations()).called(2);
      });
    });

    group('CreateOrganizationController', () {
      test('propagates error when creation fails', () async {
        // Arrange
        final request = CreateOrganizationRequest(name: 'New Organization');

        when(mockApiService.createOrganization(request)).thenThrow(Exception('Creation failed'));

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Act & Assert
        expect(
          () => container
              .read(createOrganizationControllerProvider.notifier)
              .createOrganization(request),
          throwsA(isA<Exception>()),
        );

        verify(mockApiService.createOrganization(request)).called(1);
      });
    });

    group('OrganizationWizard Provider', () {
      test('initializes with default state', () {
        // Arrange
        container = ProviderContainer();

        // Act
        final state = container.read(organizationWizardProvider);

        // Assert
        expect(state.currentStep, 0);
        expect(state.name, isNull);
        expect(state.description, isNull);
        expect(state.timezone, 'UTC');
        expect(state.locale, 'en_US');
        expect(state.integrationSettings, isEmpty);
        expect(state.invitedEmails, isEmpty);
      });

      test('updateName updates the name field', () {
        // Arrange
        container = ProviderContainer();

        // Act
        container.read(organizationWizardProvider.notifier).updateName('My Organization');

        // Assert
        final state = container.read(organizationWizardProvider);
        expect(state.name, 'My Organization');
      });

      test('updateDescription updates the description field', () {
        // Arrange
        container = ProviderContainer();

        // Act
        container.read(organizationWizardProvider.notifier).updateDescription('Test description');

        // Assert
        final state = container.read(organizationWizardProvider);
        expect(state.description, 'Test description');
      });

      test('updateTimezone updates the timezone field', () {
        // Arrange
        container = ProviderContainer();

        // Act
        container.read(organizationWizardProvider.notifier).updateTimezone('America/New_York');

        // Assert
        final state = container.read(organizationWizardProvider);
        expect(state.timezone, 'America/New_York');
      });

      test('updateLocale updates the locale field', () {
        // Arrange
        container = ProviderContainer();

        // Act
        container.read(organizationWizardProvider.notifier).updateLocale('fr_FR');

        // Assert
        final state = container.read(organizationWizardProvider);
        expect(state.locale, 'fr_FR');
      });

      test('updateIntegrationSettings updates integration settings', () {
        // Arrange
        container = ProviderContainer();
        final settings = {'fireflies': true, 'slack': false};

        // Act
        container.read(organizationWizardProvider.notifier).updateIntegrationSettings(settings);

        // Assert
        final state = container.read(organizationWizardProvider);
        expect(state.integrationSettings, settings);
      });

      test('addInvitedEmail adds email to list', () {
        // Arrange
        container = ProviderContainer();

        // Act
        container.read(organizationWizardProvider.notifier).addInvitedEmail('user1@test.com');
        container.read(organizationWizardProvider.notifier).addInvitedEmail('user2@test.com');

        // Assert
        final state = container.read(organizationWizardProvider);
        expect(state.invitedEmails.length, 2);
        expect(state.invitedEmails.contains('user1@test.com'), true);
        expect(state.invitedEmails.contains('user2@test.com'), true);
      });

      test('removeInvitedEmail removes email from list', () {
        // Arrange
        container = ProviderContainer();
        container.read(organizationWizardProvider.notifier).addInvitedEmail('user1@test.com');
        container.read(organizationWizardProvider.notifier).addInvitedEmail('user2@test.com');

        // Act
        container.read(organizationWizardProvider.notifier).removeInvitedEmail('user1@test.com');

        // Assert
        final state = container.read(organizationWizardProvider);
        expect(state.invitedEmails.length, 1);
        expect(state.invitedEmails.contains('user1@test.com'), false);
        expect(state.invitedEmails.contains('user2@test.com'), true);
      });

      test('nextStep increments current step', () {
        // Arrange
        container = ProviderContainer();

        // Act
        container.read(organizationWizardProvider.notifier).nextStep();
        container.read(organizationWizardProvider.notifier).nextStep();

        // Assert
        final state = container.read(organizationWizardProvider);
        expect(state.currentStep, 2);
      });

      test('nextStep does not increment beyond max step', () {
        // Arrange
        container = ProviderContainer();

        // Act
        for (int i = 0; i < 10; i++) {
          container.read(organizationWizardProvider.notifier).nextStep();
        }

        // Assert
        final state = container.read(organizationWizardProvider);
        expect(state.currentStep, 3); // Max step is 3
      });

      test('previousStep decrements current step', () {
        // Arrange
        container = ProviderContainer();
        container.read(organizationWizardProvider.notifier).nextStep();
        container.read(organizationWizardProvider.notifier).nextStep();

        // Act
        container.read(organizationWizardProvider.notifier).previousStep();

        // Assert
        final state = container.read(organizationWizardProvider);
        expect(state.currentStep, 1);
      });

      test('previousStep does not decrement below 0', () {
        // Arrange
        container = ProviderContainer();

        // Act
        for (int i = 0; i < 5; i++) {
          container.read(organizationWizardProvider.notifier).previousStep();
        }

        // Assert
        final state = container.read(organizationWizardProvider);
        expect(state.currentStep, 0);
      });

      test('goToStep sets specific step', () {
        // Arrange
        container = ProviderContainer();

        // Act
        container.read(organizationWizardProvider.notifier).goToStep(2);

        // Assert
        final state = container.read(organizationWizardProvider);
        expect(state.currentStep, 2);
      });

      test('goToStep validates step bounds', () {
        // Arrange
        container = ProviderContainer();

        // Act - try invalid steps
        container.read(organizationWizardProvider.notifier).goToStep(-1);
        expect(container.read(organizationWizardProvider).currentStep, 0);

        container.read(organizationWizardProvider.notifier).goToStep(10);
        expect(container.read(organizationWizardProvider).currentStep, 0);

        // Act - try valid step
        container.read(organizationWizardProvider.notifier).goToStep(2);
        expect(container.read(organizationWizardProvider).currentStep, 2);
      });

      test('reset returns wizard to initial state', () {
        // Arrange
        container = ProviderContainer();
        final notifier = container.read(organizationWizardProvider.notifier);

        // Modify state
        notifier.updateName('Test Org');
        notifier.updateDescription('Description');
        notifier.addInvitedEmail('test@test.com');
        notifier.nextStep();
        notifier.nextStep();

        // Act
        notifier.reset();

        // Assert
        final state = container.read(organizationWizardProvider);
        expect(state.currentStep, 0);
        expect(state.name, isNull);
        expect(state.description, isNull);
        expect(state.invitedEmails, isEmpty);
      });

      test('buildRequest creates correct CreateOrganizationRequest', () {
        // Arrange
        container = ProviderContainer();
        final notifier = container.read(organizationWizardProvider.notifier);

        notifier.updateName('My Organization');
        notifier.updateDescription('Test description');
        notifier.updateTimezone('America/New_York');
        notifier.updateLocale('en_US');
        notifier.updateIntegrationSettings({'fireflies': true});

        // Act
        final request = notifier.buildRequest();

        // Assert
        expect(request.name, 'My Organization');
        expect(request.description, 'Test description');
        expect(request.settings['timezone'], 'America/New_York');
        expect(request.settings['locale'], 'en_US');
        expect(request.settings['fireflies'], true);
      });
    });
  });
}
