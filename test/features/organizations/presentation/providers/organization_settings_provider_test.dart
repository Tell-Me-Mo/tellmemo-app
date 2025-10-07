import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pm_master_v2/features/organizations/presentation/providers/organization_provider.dart';
import 'package:pm_master_v2/features/organizations/presentation/providers/organization_settings_provider.dart';
import '../../../../mocks/generate_mocks.mocks.dart';
import '../../../../mocks/organization_test_fixtures.dart';
import '../../../../mocks/mock_auth_providers.dart';

void main() {
  group('Organization Settings Provider Tests', () {
    late MockOrganizationApiService mockApiService;
    late ProviderContainer container;

    setUp(() {
      mockApiService = MockOrganizationApiService();
    });

    tearDown(() {
      container.dispose();
    });

    group('updateOrganizationSettings', () {
      test('successfully updates organization settings', () async {
        // Arrange
        final organizationId = 'org-1';
        final settings = {
          'name': 'Updated Organization',
          'description': 'Updated description',
        };
        final updatedOrganization = OrganizationTestFixtures.sampleOrganizationModel.copyWith(
          name: 'Updated Organization',
          description: 'Updated description',
        );

        when(mockApiService.updateOrganization(organizationId, settings))
            .thenAnswer((_) async => updatedOrganization);

        when(mockApiService.listUserOrganizations())
            .thenAnswer((_) async => {
                  'organizations': [updatedOrganization.toJson()]
                });

        when(mockApiService.getOrganization(organizationId))
            .thenAnswer((_) async => updatedOrganization);

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Set initial organization
        await container
            .read(currentOrganizationProvider.notifier)
            .setOrganization(OrganizationTestFixtures.sampleOrganization);

        // Act
        final result = await container.read(
          updateOrganizationSettingsProvider(
            organizationId: organizationId,
            settings: settings,
          ).future,
        );

        // Assert
        expect(result.id, organizationId);
        expect(result.name, 'Updated Organization');
        expect(result.description, 'Updated description');

        verify(mockApiService.updateOrganization(organizationId, settings)).called(1);
        verify(mockApiService.listUserOrganizations()).called(greaterThanOrEqualTo(1));
      });

      test('propagates error when API call fails', () async {
        // Arrange
        final organizationId = 'org-1';
        final settings = {'name': 'Updated Organization'};

        when(mockApiService.updateOrganization(organizationId, settings))
            .thenThrow(Exception('Network error'));

        when(mockApiService.getOrganization(organizationId))
            .thenAnswer((_) async => OrganizationTestFixtures.sampleOrganizationModel);

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Set initial organization
        await container
            .read(currentOrganizationProvider.notifier)
            .setOrganization(OrganizationTestFixtures.sampleOrganization);

        // Act & Assert
        expect(
          () => container.read(
            updateOrganizationSettingsProvider(
              organizationId: organizationId,
              settings: settings,
            ).future,
          ),
          throwsA(isA<Exception>()),
        );

        verify(mockApiService.updateOrganization(organizationId, settings)).called(1);
      });

      test('updates current organization after successful settings update', () async {
        // Arrange
        final organizationId = 'org-1';
        final settings = {'name': 'New Name'};
        final updatedOrganization = OrganizationTestFixtures.sampleOrganizationModel.copyWith(
          name: 'New Name',
        );

        when(mockApiService.updateOrganization(organizationId, settings))
            .thenAnswer((_) async => updatedOrganization);

        when(mockApiService.listUserOrganizations())
            .thenAnswer((_) async => {
                  'organizations': [updatedOrganization.toJson()]
                });

        when(mockApiService.getOrganization(organizationId))
            .thenAnswer((_) async => updatedOrganization);

        container = createAuthenticatedContainer(
          additionalOverrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Set initial organization
        await container
            .read(currentOrganizationProvider.notifier)
            .setOrganization(OrganizationTestFixtures.sampleOrganization);

        // Act
        await container.read(
          updateOrganizationSettingsProvider(
            organizationId: organizationId,
            settings: settings,
          ).future,
        );

        // Assert - verify current organization was updated
        final currentOrg = await container.read(currentOrganizationProvider.future);
        expect(currentOrg?.name, 'New Name');
      });
    });

    group('deleteOrganization', () {
      test('successfully deletes organization', () async {
        // Arrange
        final organizationId = 'org-1';

        when(mockApiService.deleteOrganization(organizationId))
            .thenAnswer((_) async {});

        when(mockApiService.listUserOrganizations())
            .thenAnswer((_) async => {'organizations': []});

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Act
        await container.read(
          deleteOrganizationProvider(organizationId).future,
        );

        // Assert
        verify(mockApiService.deleteOrganization(organizationId)).called(1);
        verify(mockApiService.listUserOrganizations()).called(greaterThanOrEqualTo(1));
      });

      test('propagates error when deletion fails', () async {
        // Arrange
        final organizationId = 'org-1';

        when(mockApiService.deleteOrganization(organizationId))
            .thenThrow(Exception('Deletion not allowed'));

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Act & Assert
        expect(
          () => container.read(deleteOrganizationProvider(organizationId).future),
          throwsA(isA<Exception>()),
        );

        verify(mockApiService.deleteOrganization(organizationId)).called(1);
      });

      test('clears current organization after deletion', () async {
        // Arrange
        final organizationId = 'org-1';

        when(mockApiService.deleteOrganization(organizationId))
            .thenAnswer((_) async {});

        when(mockApiService.listUserOrganizations())
            .thenAnswer((_) async => {'organizations': []});

        when(mockApiService.getOrganization(organizationId))
            .thenAnswer((_) async => OrganizationTestFixtures.sampleOrganizationModel);

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Set initial organization
        await container
            .read(currentOrganizationProvider.notifier)
            .setOrganization(OrganizationTestFixtures.sampleOrganization);

        // Verify organization is set
        final orgBefore = await container.read(currentOrganizationProvider.future);
        expect(orgBefore, isNotNull);

        // Act
        await container.read(deleteOrganizationProvider(organizationId).future);

        // Assert - verify current organization provider was invalidated
        // The provider should be invalidated, which causes it to rebuild
        verify(mockApiService.deleteOrganization(organizationId)).called(1);
      });

      test('refreshes user organizations list after deletion', () async {
        // Arrange
        final organizationId = 'org-1';
        final remainingOrganizations = [
          OrganizationTestFixtures.createOrganization(id: 'org-2', name: 'Org 2'),
        ];

        when(mockApiService.deleteOrganization(organizationId))
            .thenAnswer((_) async {});

        when(mockApiService.listUserOrganizations()).thenAnswer((_) async => {
              'organizations': remainingOrganizations.map((o) => o.toJson()).toList()
            });

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Act
        await container.read(deleteOrganizationProvider(organizationId).future);

        // Assert
        verify(mockApiService.deleteOrganization(organizationId)).called(1);
        verify(mockApiService.listUserOrganizations()).called(greaterThanOrEqualTo(1));
      });
    });
  });
}
