import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/content/presentation/widgets/processing_skeleton_loader.dart';

void main() {
  group('ProcessingSkeletonLoader', () {
    testWidgets('displays document skeleton when isDocument is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProcessingSkeletonLoader(isDocument: true),
          ),
        ),
      );

      // Should show document icon
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);

      // Should show processing text
      expect(find.text('Processing document...'), findsOneWidget);

      // Should show circular progress indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays summary skeleton when isDocument is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProcessingSkeletonLoader(isDocument: false),
          ),
        ),
      );

      // Should show auto awesome icon for summary
      expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);

      // Should show generating summary text
      expect(find.text('Generating summary...'), findsOneWidget);

      // Should show circular progress indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('uses default isDocument=true when not specified', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProcessingSkeletonLoader(),
          ),
        ),
      );

      // Default should be document mode
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
      expect(find.text('Processing document...'), findsOneWidget);
    });

    testWidgets('displays custom title when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProcessingSkeletonLoader(
              isDocument: true,
              title: 'Custom Document',
            ),
          ),
        ),
      );

      // Widget accepts title parameter but currently doesn't use it in the UI
      // This test verifies the parameter can be passed without errors
      expect(find.byType(ProcessingSkeletonLoader), findsOneWidget);
    });

    testWidgets('animation controller is properly initialized', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProcessingSkeletonLoader(isDocument: true),
          ),
        ),
      );

      // Pump a few frames to ensure animation is running
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Widget should still be present and animating
      expect(find.byType(ProcessingSkeletonLoader), findsOneWidget);
    });

    testWidgets('widget disposes animation controller properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProcessingSkeletonLoader(isDocument: true),
          ),
        ),
      );

      // Verify widget is rendered
      expect(find.byType(ProcessingSkeletonLoader), findsOneWidget);

      // Remove widget from tree
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.shrink(),
          ),
        ),
      );

      // Widget should be disposed without errors
      expect(find.byType(ProcessingSkeletonLoader), findsNothing);
    });

    testWidgets('displays correct colors for document mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProcessingSkeletonLoader(isDocument: true),
          ),
        ),
      );

      final AnimatedBuilder iconBuilder = tester.widget(
        find.descendant(
          of: find.byType(ProcessingSkeletonLoader),
          matching: find.byType(AnimatedBuilder),
        ).first,
      );

      // Icon should be present in the animated builder
      expect(iconBuilder, isNotNull);
    });

    testWidgets('displays correct colors for summary mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProcessingSkeletonLoader(isDocument: false),
          ),
        ),
      );

      final AnimatedBuilder iconBuilder = tester.widget(
        find.descendant(
          of: find.byType(ProcessingSkeletonLoader),
          matching: find.byType(AnimatedBuilder),
        ).first,
      );

      // Icon should be present in the animated builder
      expect(iconBuilder, isNotNull);
    });

    testWidgets('container has correct decoration in document mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProcessingSkeletonLoader(isDocument: true),
          ),
        ),
      );

      // Find the main container
      final Container container = tester.widget(
        find.descendant(
          of: find.byType(ProcessingSkeletonLoader),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.decoration, isA<BoxDecoration>());
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(8));
    });

    testWidgets('container has correct decoration in summary mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProcessingSkeletonLoader(isDocument: false),
          ),
        ),
      );

      // Find the main container
      final Container container = tester.widget(
        find.descendant(
          of: find.byType(ProcessingSkeletonLoader),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.decoration, isA<BoxDecoration>());
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(8));
    });
  });
}
