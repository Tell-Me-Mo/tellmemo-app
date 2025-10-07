import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/lessons_learned/presentation/widgets/lesson_learned_list_tile.dart';

import '../../../../mocks/lesson_learned_test_fixtures.dart';

void main() {
  group('LessonLearnedListTile', () {
    testWidgets('displays lesson title and description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTile(
              lesson: testLesson1,
              project: testProject1,
            ),
          ),
        ),
      );

      expect(find.text('Test Lesson 1'), findsOneWidget);
      expect(find.text('This is a test lesson about technical issues'), findsOneWidget);
    });

    testWidgets('displays project name when project is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTile(
              lesson: testLesson1,
              project: testProject1,
            ),
          ),
        ),
      );

      expect(find.text('Test Project 1'), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsOneWidget);
    });

    testWidgets('does not display project name when project is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTile(
              lesson: testLesson1,
            ),
          ),
        ),
      );

      expect(find.text('Test Project 1'), findsNothing);
    });

    testWidgets('displays lesson type label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTile(
              lesson: testLesson1,
              project: testProject1,
            ),
          ),
        ),
      );

      expect(find.text('Challenge'), findsOneWidget);
    });

    testWidgets('displays category label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTile(
              lesson: testLesson1,
              project: testProject1,
            ),
          ),
        ),
      );

      expect(find.text('Technical'), findsOneWidget);
    });

    testWidgets('displays impact label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTile(
              lesson: testLesson1,
              project: testProject1,
            ),
          ),
        ),
      );

      expect(find.text('HIGH'), findsOneWidget);
    });

    testWidgets('displays AI indicator when lesson is AI generated', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTile(
              lesson: testLesson1,
              project: testProject1,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
    });

    testWidgets('does not display AI indicator when lesson is not AI generated', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTile(
              lesson: testLesson2,
              project: testProject1,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.auto_awesome), findsNothing);
      expect(find.text('AI'), findsNothing);
    });

    testWidgets('displays tags (up to 3)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTile(
              lesson: testLesson1,
              project: testProject1,
            ),
          ),
        ),
      );

      expect(find.text('testing'), findsOneWidget);
      expect(find.text('technical'), findsOneWidget);
    });

    testWidgets('displays date when identifiedDate is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTile(
              lesson: testLesson1,
              project: testProject1,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.access_time), findsOneWidget);
      // Date will be formatted relative to current date, so just check icon exists
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTile(
              lesson: testLesson1,
              project: testProject1,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(LessonLearnedListTile));
      expect(tapped, isTrue);
    });

    testWidgets('displays category icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTile(
              lesson: testLesson1,
              project: testProject1,
            ),
          ),
        ),
      );

      // Category icon should be displayed (specific icon depends on category)
      expect(find.byType(Icon), findsWidgets);
    });
  });
}
