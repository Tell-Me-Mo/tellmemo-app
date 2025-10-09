import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:pm_master_v2/features/projects/domain/entities/project.dart';
import 'package:pm_master_v2/features/projects/domain/repositories/projects_repository.dart';
import 'package:pm_master_v2/features/projects/presentation/providers/projects_provider.dart';

@GenerateMocks([ProjectsRepository])
import 'projects_provider_test.mocks.dart';

void main() {
  late MockProjectsRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockProjectsRepository();
    container = ProviderContainer(
      overrides: [
        projectsRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  final testProject = Project(
    id: 'test-id',
    name: 'Test Project',
    description: 'Test Description',
    status: ProjectStatus.active,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    createdBy: 'test@example.com',
  );

  group('ProjectsList Provider', () {
    test('updateProject refreshes the list', () async {
      // Arrange
      when(mockRepository.getProjects())
          .thenAnswer((_) async => [testProject]);
      when(mockRepository.updateProject('test-id', any))
          .thenAnswer((_) async => testProject.copyWith(name: 'Updated Project'));

      // Act - Load initial data
      final notifier = container.read(projectsListProvider.notifier);
      await container.read(projectsListProvider.future);

      // Update project
      await notifier.updateProject('test-id', {'name': 'Updated Project'});

      // Assert - Verify repository was called twice (initial load + refresh)
      verify(mockRepository.getProjects()).called(2);
    });

    test('archiveProject refreshes the list', () async {
      // Arrange
      when(mockRepository.getProjects())
          .thenAnswer((_) async => [testProject]);
      when(mockRepository.archiveProject('test-id'))
          .thenAnswer((_) async => {});

      // Act
      final notifier = container.read(projectsListProvider.notifier);
      await container.read(projectsListProvider.future);

      await notifier.archiveProject('test-id');

      // Assert - Verify repository was called twice (initial load + refresh)
      verify(mockRepository.getProjects()).called(2);
      verify(mockRepository.archiveProject('test-id')).called(1);
    });

    test('restoreProject refreshes the list', () async {
      // Arrange
      when(mockRepository.getProjects())
          .thenAnswer((_) async => [testProject]);
      when(mockRepository.restoreProject('test-id'))
          .thenAnswer((_) async => {});

      // Act
      final notifier = container.read(projectsListProvider.notifier);
      await container.read(projectsListProvider.future);

      await notifier.restoreProject('test-id');

      // Assert - Verify repository was called twice (initial load + refresh)
      verify(mockRepository.getProjects()).called(2);
      verify(mockRepository.restoreProject('test-id')).called(1);
    });

    test('deleteProject refreshes the list', () async {
      // Arrange
      when(mockRepository.getProjects())
          .thenAnswer((_) async => [testProject]);
      when(mockRepository.deleteProject('test-id'))
          .thenAnswer((_) async => {});

      // Act
      final notifier = container.read(projectsListProvider.notifier);
      await container.read(projectsListProvider.future);

      await notifier.deleteProject('test-id');

      // Assert - Verify repository was called twice (initial load + refresh)
      verify(mockRepository.getProjects()).called(2);
      verify(mockRepository.deleteProject('test-id')).called(1);
    });
  });

  group('ProjectDetail Provider', () {
    test('updateProject updates the detail state', () async {
      // Arrange
      when(mockRepository.getProject('test-id'))
          .thenAnswer((_) async => testProject);
      when(mockRepository.updateProject('test-id', any))
          .thenAnswer((_) async => testProject.copyWith(name: 'Updated Project'));

      // Act - Load initial data
      final notifier = container.read(projectDetailProvider('test-id').notifier);
      final initialData = await container.read(projectDetailProvider('test-id').future);

      expect(initialData?.name, 'Test Project');

      // Update project
      await notifier.updateProject({'name': 'Updated Project'});

      // Get updated data
      final updatedData = container.read(projectDetailProvider('test-id')).value;

      // Assert
      expect(updatedData?.name, 'Updated Project');
      verify(mockRepository.updateProject('test-id', any)).called(1);
    });
  });
}
