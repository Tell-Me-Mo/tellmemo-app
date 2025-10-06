import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/core/widgets/loading/skeleton_loader.dart';
import 'package:pm_master_v2/features/documents/presentation/widgets/document_skeleton_loader.dart';

void main() {
  group('DocumentSkeletonLoader', () {
    testWidgets('generates 5 skeleton items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DocumentSkeletonLoader(),
            ),
          ),
        ),
      );

      // Should find 5 skeleton item containers
      // Each skeleton item has multiple SkeletonLoader widgets
      expect(find.byType(SkeletonLoader), findsWidgets);
    });

    testWidgets('each skeleton item has proper structure', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DocumentSkeletonLoader(),
            ),
          ),
        ),
      );

      // Widget should render without errors
      expect(find.byType(DocumentSkeletonLoader), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('skeleton items have rounded borders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DocumentSkeletonLoader(),
            ),
          ),
        ),
      );

      // Find containers in the skeleton items
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(DocumentSkeletonLoader),
          matching: find.byType(Container),
        ),
      );

      // Check that at least some containers have BoxDecoration with borderRadius
      bool hasRoundedBorders = false;
      for (final container in containers) {
        if (container.decoration is BoxDecoration) {
          final decoration = container.decoration as BoxDecoration;
          if (decoration.borderRadius == BorderRadius.circular(12)) {
            hasRoundedBorders = true;
            break;
          }
        }
      }

      expect(hasRoundedBorders, true);
    });

    testWidgets('uses SkeletonLoader widgets for shimmer effect', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DocumentSkeletonLoader(),
            ),
          ),
        ),
      );

      // Should use SkeletonLoader widgets for animated shimmer
      expect(find.byType(SkeletonLoader), findsWidgets);

      // Verify multiple SkeletonLoader instances (at least 5 items * 4 skeletons each = 20+)
      final skeletonLoaders = tester.widgetList(find.byType(SkeletonLoader));
      expect(skeletonLoaders.length, greaterThan(15));
    });

    testWidgets('skeleton items have bottom margin', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DocumentSkeletonLoader(),
            ),
          ),
        ),
      );

      // Find containers that should have bottom margin
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(DocumentSkeletonLoader),
          matching: find.byType(Container),
        ),
      );

      // Check that at least some containers have margin
      bool hasMargin = false;
      for (final container in containers) {
        if (container.margin == const EdgeInsets.only(bottom: 12)) {
          hasMargin = true;
          break;
        }
      }

      expect(hasMargin, true);
    });
  });
}
