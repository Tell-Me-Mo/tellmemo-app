import 'package:pm_master_v2/features/projects/domain/entities/lesson_learned.dart';
import 'package:pm_master_v2/features/projects/domain/entities/project.dart';

/// Test fixtures for lesson learned testing

final testLesson1 = LessonLearned(
  id: 'lesson-1',
  projectId: 'project-1',
  title: 'Test Lesson 1',
  description: 'This is a test lesson about technical issues',
  category: LessonCategory.technical,
  lessonType: LessonType.challenge,
  impact: LessonImpact.high,
  recommendation: 'Recommendation for lesson 1',
  context: 'Context for lesson 1',
  tags: ['testing', 'technical'],
  aiGenerated: true,
  aiConfidence: 0.9,
  identifiedDate: DateTime(2024, 1, 15),
  lastUpdated: DateTime(2024, 1, 15),
);

final testLesson2 = LessonLearned(
  id: 'lesson-2',
  projectId: 'project-1',
  title: 'Test Lesson 2',
  description: 'This is a test lesson about process improvements',
  category: LessonCategory.process,
  lessonType: LessonType.improvement,
  impact: LessonImpact.medium,
  recommendation: 'Recommendation for lesson 2',
  context: 'Context for lesson 2',
  tags: ['process', 'improvement'],
  aiGenerated: false,
  identifiedDate: DateTime(2024, 1, 10),
  lastUpdated: DateTime(2024, 1, 10),
);

final testLesson3 = LessonLearned(
  id: 'lesson-3',
  projectId: 'project-2',
  title: 'Best Practice Lesson',
  description: 'This is a test lesson about best practices',
  category: LessonCategory.quality,
  lessonType: LessonType.bestPractice,
  impact: LessonImpact.low,
  recommendation: 'Recommendation for lesson 3',
  tags: ['quality', 'best-practice'],
  aiGenerated: true,
  aiConfidence: 0.85,
  identifiedDate: DateTime(2024, 1, 5),
  lastUpdated: DateTime(2024, 1, 5),
);

final testLesson4 = LessonLearned(
  id: 'lesson-4',
  projectId: 'project-2',
  title: 'Communication Success',
  description: 'This is a test lesson about communication success',
  category: LessonCategory.communication,
  lessonType: LessonType.success,
  impact: LessonImpact.medium,
  tags: ['communication'],
  aiGenerated: false,
  identifiedDate: DateTime(2024, 1, 20),
  lastUpdated: DateTime(2024, 1, 20),
);

final testProject1 = Project(
  id: 'project-1',
  name: 'Test Project 1',
  description: 'A test project',
  status: ProjectStatus.active,
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
  memberCount: 3,
);

final testProject2 = Project(
  id: 'project-2',
  name: 'Test Project 2',
  description: 'Another test project',
  status: ProjectStatus.active,
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
  memberCount: 5,
);

final List<LessonLearned> testLessons = [
  testLesson1,
  testLesson2,
  testLesson3,
  testLesson4,
];

final List<Project> testProjects = [
  testProject1,
  testProject2,
];
