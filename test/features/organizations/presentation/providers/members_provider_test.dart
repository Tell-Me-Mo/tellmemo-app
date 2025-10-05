import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pm_master_v2/features/organizations/data/models/organization_member.dart';
import 'package:pm_master_v2/features/organizations/presentation/providers/members_provider.dart';
import 'package:pm_master_v2/features/organizations/presentation/providers/organization_provider.dart';
import '../../../../mocks/generate_mocks.mocks.dart';
import '../../../../mocks/organization_test_fixtures.dart';

void main() {
  group('Members Provider Tests', () {
    late MockOrganizationApiService mockApiService;
    late ProviderContainer container;
    const String testOrgId = 'org-1';

    setUp(() {
      mockApiService = MockOrganizationApiService();
    });

    tearDown(() {
      container.dispose();
    });

    group('MembersNotifier initialization', () {
      test('loads members on initialization', () async {
        // Arrange
        final members = OrganizationTestFixtures.sampleMembers;
        when(mockApiService.getOrganizationMembers(testOrgId))
            .thenAnswer((_) async => {
                  'members': members.map((m) => m.toJson()).toList()
                });

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Act - Listen and wait for the provider to complete loading
        AsyncValue<List<OrganizationMember>>? finalState;

        final subscription = container.listen(
          membersProvider(testOrgId),
          (previous, next) {
            finalState = next;
          },
        );

        // Trigger the provider by reading it
        container.read(membersProvider(testOrgId));

        // Wait for async operation to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Keep checking until we have a value or timeout
        for (var i = 0; i < 20 && !(finalState?.hasValue ?? false); i++) {
          await Future.delayed(const Duration(milliseconds: 50));
        }

        // Assert
        expect(finalState?.hasValue, true);
        final loadedMembers = finalState?.value;
        expect(loadedMembers?.length, members.length);
        expect(loadedMembers?.first.userEmail, members.first.userEmail);
        verify(mockApiService.getOrganizationMembers(testOrgId)).called(1);

        subscription.close();
      });

      test('sets error state when loading members fails', () async {
        // Arrange
        when(mockApiService.getOrganizationMembers(testOrgId))
            .thenThrow(Exception('Network error'));

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Act & Assert
        final listener = container.listen(
          membersProvider(testOrgId),
          (prev, next) {},
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(listener.read().hasError, true);
        verify(mockApiService.getOrganizationMembers(testOrgId)).called(greaterThanOrEqualTo(1));
      });
    });

    group('loadMembers', () {
      test('successfully loads members', () async {
        // Arrange
        final members = OrganizationTestFixtures.sampleMembers;
        when(mockApiService.getOrganizationMembers(testOrgId))
            .thenAnswer((_) async => {
                  'members': members.map((m) => m.toJson()).toList()
                });

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Act
        await container.read(membersProvider(testOrgId).notifier).loadMembers();

        // Assert
        final state = container.read(membersProvider(testOrgId));
        expect(state.hasValue, true);
        expect(state.value?.length, members.length);
      });

      test('sets loading state during load', () async {
        // Arrange
        final members = OrganizationTestFixtures.sampleMembers;
        when(mockApiService.getOrganizationMembers(testOrgId))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return {
            'members': members.map((m) => m.toJson()).toList()
          };
        });

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Wait for initial load
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        final loadFuture = container.read(membersProvider(testOrgId).notifier).loadMembers();

        // Assert loading state
        await Future.delayed(const Duration(milliseconds: 10));
        final stateWhileLoading = container.read(membersProvider(testOrgId));
        expect(stateWhileLoading.isLoading, true);

        await loadFuture;
      });
    });

    group('removeMember', () {
      test('successfully removes a member', () async {
        // Arrange
        final members = OrganizationTestFixtures.sampleMembers;
        final updatedMembers = members.where((m) => m.userId != 'user-2').toList();

        when(mockApiService.getOrganizationMembers(testOrgId))
            .thenAnswer((_) async => {
                  'members': members.map((m) => m.toJson()).toList()
                });

        when(mockApiService.removeOrganizationMember(testOrgId, 'user-2'))
            .thenAnswer((_) async {});

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Wait for initial load
        await Future.delayed(const Duration(milliseconds: 100));

        // Update mock to return updated list after removal
        when(mockApiService.getOrganizationMembers(testOrgId))
            .thenAnswer((_) async => {
                  'members': updatedMembers.map((m) => m.toJson()).toList()
                });

        // Act
        await container.read(membersProvider(testOrgId).notifier).removeMember('user-2');

        // Assert
        verify(mockApiService.removeOrganizationMember(testOrgId, 'user-2')).called(1);
        verify(mockApiService.getOrganizationMembers(testOrgId)).called(greaterThanOrEqualTo(2));

        final state = container.read(membersProvider(testOrgId)).value!;
        expect(state.length, updatedMembers.length);
        expect(state.any((m) => m.userId == 'user-2'), false);
      });

      test('propagates error when removal fails', () async {
        // Arrange
        final members = OrganizationTestFixtures.sampleMembers;
        when(mockApiService.getOrganizationMembers(testOrgId))
            .thenAnswer((_) async => {
                  'members': members.map((m) => m.toJson()).toList()
                });

        when(mockApiService.removeOrganizationMember(testOrgId, 'user-2'))
            .thenThrow(Exception('Removal failed'));

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Wait for initial load
        await Future.delayed(const Duration(milliseconds: 100));

        // Act & Assert
        expect(
          () => container.read(membersProvider(testOrgId).notifier).removeMember('user-2'),
          throwsA(isA<Exception>()),
        );

        verify(mockApiService.removeOrganizationMember(testOrgId, 'user-2')).called(1);
      });
    });

    group('removeMembersInBatch', () {
      test('successfully removes multiple members', () async {
        // Arrange
        final members = OrganizationTestFixtures.sampleMembers;
        final userIdsToRemove = ['user-2', 'user-3'];
        final updatedMembers = members
            .where((m) => !userIdsToRemove.contains(m.userId))
            .toList();

        when(mockApiService.getOrganizationMembers(testOrgId))
            .thenAnswer((_) async => {
                  'members': members.map((m) => m.toJson()).toList()
                });

        when(mockApiService.removeOrganizationMember(testOrgId, any))
            .thenAnswer((_) async {});

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Wait for initial load
        await Future.delayed(const Duration(milliseconds: 100));

        // Update mock to return updated list after batch removal
        when(mockApiService.getOrganizationMembers(testOrgId))
            .thenAnswer((_) async => {
                  'members': updatedMembers.map((m) => m.toJson()).toList()
                });

        // Act
        await container
            .read(membersProvider(testOrgId).notifier)
            .removeMembersInBatch(userIdsToRemove);

        // Assert
        verify(mockApiService.removeOrganizationMember(testOrgId, 'user-2')).called(1);
        verify(mockApiService.removeOrganizationMember(testOrgId, 'user-3')).called(1);

        final state = container.read(membersProvider(testOrgId)).value!;
        expect(state.length, updatedMembers.length);
        expect(state.any((m) => userIdsToRemove.contains(m.userId)), false);
      });

      test('stops on first error and propagates it', () async {
        // Arrange
        final members = OrganizationTestFixtures.sampleMembers;
        final userIdsToRemove = ['user-2', 'user-3'];

        when(mockApiService.getOrganizationMembers(testOrgId))
            .thenAnswer((_) async => {
                  'members': members.map((m) => m.toJson()).toList()
                });

        when(mockApiService.removeOrganizationMember(testOrgId, 'user-2'))
            .thenThrow(Exception('Removal failed'));

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Wait for initial load
        await Future.delayed(const Duration(milliseconds: 100));

        // Act & Assert
        expect(
          () => container
              .read(membersProvider(testOrgId).notifier)
              .removeMembersInBatch(userIdsToRemove),
          throwsA(isA<Exception>()),
        );

        verify(mockApiService.removeOrganizationMember(testOrgId, 'user-2')).called(1);
        // user-3 should not be called since user-2 failed
        verifyNever(mockApiService.removeOrganizationMember(testOrgId, 'user-3'));
      });
    });

    group('updateMemberRole', () {
      test('successfully updates member role', () async {
        // Arrange
        final members = OrganizationTestFixtures.sampleMembers;
        final updatedMembers = members.map((m) {
          if (m.userId == 'user-2') {
            return OrganizationTestFixtures.createMember(
              userId: 'user-2',
              email: 'member@test.com',
              name: 'Member User',
              role: 'admin',
            );
          }
          return m;
        }).toList();

        when(mockApiService.getOrganizationMembers(testOrgId))
            .thenAnswer((_) async => {
                  'members': members.map((m) => m.toJson()).toList()
                });

        when(mockApiService.updateOrganizationMemberRole(
          testOrgId,
          'user-2',
          {'role': 'admin'},
        )).thenAnswer((_) async {});

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Wait for initial load
        await Future.delayed(const Duration(milliseconds: 100));

        // Update mock to return updated list after role change
        when(mockApiService.getOrganizationMembers(testOrgId))
            .thenAnswer((_) async => {
                  'members': updatedMembers.map((m) => m.toJson()).toList()
                });

        // Act
        await container
            .read(membersProvider(testOrgId).notifier)
            .updateMemberRole('user-2', 'admin');

        // Assert
        verify(mockApiService.updateOrganizationMemberRole(
          testOrgId,
          'user-2',
          {'role': 'admin'},
        )).called(1);

        final state = container.read(membersProvider(testOrgId)).value!;
        final updatedMember = state.firstWhere((m) => m.userId == 'user-2');
        expect(updatedMember.role, 'admin');
      });

      test('propagates error when role update fails', () async {
        // Arrange
        final members = OrganizationTestFixtures.sampleMembers;
        when(mockApiService.getOrganizationMembers(testOrgId))
            .thenAnswer((_) async => {
                  'members': members.map((m) => m.toJson()).toList()
                });

        when(mockApiService.updateOrganizationMemberRole(
          testOrgId,
          'user-2',
          {'role': 'admin'},
        )).thenThrow(Exception('Update failed'));

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Wait for initial load
        await Future.delayed(const Duration(milliseconds: 100));

        // Act & Assert
        expect(
          () => container
              .read(membersProvider(testOrgId).notifier)
              .updateMemberRole('user-2', 'admin'),
          throwsA(isA<Exception>()),
        );

        verify(mockApiService.updateOrganizationMemberRole(
          testOrgId,
          'user-2',
          {'role': 'admin'},
        )).called(1);
      });
    });

    group('resendInvitation', () {
      test('successfully resends invitation', () async {
        // Arrange
        final members = OrganizationTestFixtures.sampleMembers;
        when(mockApiService.getOrganizationMembers(testOrgId))
            .thenAnswer((_) async => {
                  'members': members.map((m) => m.toJson()).toList()
                });

        when(mockApiService.resendInvitation(testOrgId, {'email': 'pending@test.com'}))
            .thenAnswer((_) async {});

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Wait for initial load
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        await container
            .read(membersProvider(testOrgId).notifier)
            .resendInvitation('pending@test.com');

        // Assert
        verify(mockApiService.resendInvitation(testOrgId, {'email': 'pending@test.com'}))
            .called(1);
      });

      test('propagates error when resend fails', () async {
        // Arrange
        final members = OrganizationTestFixtures.sampleMembers;
        when(mockApiService.getOrganizationMembers(testOrgId))
            .thenAnswer((_) async => {
                  'members': members.map((m) => m.toJson()).toList()
                });

        when(mockApiService.resendInvitation(testOrgId, {'email': 'pending@test.com'}))
            .thenThrow(Exception('Resend failed'));

        container = ProviderContainer(
          overrides: [
            organizationApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );

        // Wait for initial load
        await Future.delayed(const Duration(milliseconds: 100));

        // Act & Assert
        expect(
          () => container
              .read(membersProvider(testOrgId).notifier)
              .resendInvitation('pending@test.com'),
          throwsA(isA<Exception>()),
        );

        verify(mockApiService.resendInvitation(testOrgId, {'email': 'pending@test.com'}))
            .called(1);
      });
    });
  });
}
