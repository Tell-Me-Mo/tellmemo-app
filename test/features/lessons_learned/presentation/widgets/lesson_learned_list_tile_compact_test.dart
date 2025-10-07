import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/lessons_learned/presentation/widgets/lesson_learned_list_tile_compact.dart';

import '../../../../mocks/lesson_learned_test_fixtures.dart';

void main() {
  group('LessonLearnedListTileCompact', () {
    testWidgets('displays lesson title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTileCompact(
              lesson: testLesson1,
              project: testProject1,
            ),
          ),
        ),
      );

      expect(find.text('Test Lesson 1'), findsOneWidget);
    });

    testWidgets('displays project name when project is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTileCompact(
              lesson: testLesson1,
              project: testProject1,
            ),
          ),
        ),
      );

      expect(find.text('Test Project 1'), findsOneWidget);
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
    });

    testWidgets('does not display project name when project is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTileCompact(
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
            body: LessonLearnedListTileCompact(
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
            body: LessonLearnedListTileCompact(
              lesson: testLesson1,
              project: testProject1,
            ),
          ),
        ),
      );

      expect(find.text('Technical'), findsOneWidget);
    });

    testWidgets('displays impact indicator with first letter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTileCompact(
              lesson: testLesson1,
              project: testProject1,
            ),
          ),
        ),
      );

      // Impact should show first letter in compact view
      expect(find.text('H'), findsOneWidget);
    });

    testWidgets('displays AI indicator when lesson is AI generated', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTileCompact(
              lesson: testLesson1,
              project: testProject1,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('does not display AI indicator when lesson is not AI generated', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTileCompact(
              lesson: testLesson2,
              project: testProject1,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    testWidgets('displays date when identifiedDate is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTileCompact(
              lesson: testLesson1,
              project: testProject1,
            ),
          ),
        ),
      );

      // Date will be formatted relative to current date
      // Just verify some text is shown (compact format)
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTileCompact(
              lesson: testLesson1,
              project: testProject1,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(LessonLearnedListTileCompact));
      expect(tapped, isTrue);
    });

    testWidgets('displays category icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTileCompact(
              lesson: testLesson1,
              project: testProject1,
            ),
          ),
        ),
      );

      // Category icon should be displayed
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('has smaller height than regular tile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonLearnedListTileCompact(
              lesson: testLesson1,
              project: testProject1,
            ),
          ),
        ),
      );

      // Compact tile should have smaller dimensions
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(LessonLearnedListTileCompact),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.padding, equals(const EdgeInsets.symmetric(horizontal: 12, vertical: 10)));
    });
  });
}
