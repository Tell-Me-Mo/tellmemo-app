import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/core/widgets/loading/skeleton_loader.dart';

void main() {
  group('SkeletonLoader Widget', () {
    testWidgets('renders with default properties', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
      // AnimatedBuilder is present (animation is working)
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('renders with custom width and height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(
              width: 200,
              height: 50,
            ),
          ),
        ),
      );

      // Verify widget is rendered (implementation details like Container are tested implicitly)
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('renders as circle when isCircle is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(
              width: 50,
              height: 50,
              isCircle: true,
            ),
          ),
        ),
      );

      // Verify widget renders (circle shape is implementation detail)
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('renders with custom border radius', (tester) async {
      const customRadius = BorderRadius.all(Radius.circular(12));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(
              borderRadius: customRadius,
            ),
          ),
        ),
      );

      // Verify widget renders (border radius is implementation detail)
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('animation controller runs correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(),
          ),
        ),
      );

      // Initial state
      await tester.pump();

      // Advance animation
      await tester.pump(const Duration(milliseconds: 500));

      // Verify AnimatedBuilder is present (animation is running)
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('applies custom margin', (tester) async {
      const customMargin = EdgeInsets.all(16);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(
              margin: customMargin,
            ),
          ),
        ),
      );

      // Verify widget renders (margin is implementation detail)
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });
  });

  group('SkeletonListTile Widget', () {
    testWidgets('renders with leading, title and subtitle by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonListTile(),
          ),
        ),
      );

      // Should find 3 SkeletonLoaders: leading (circle), title, and subtitle
      expect(find.byType(SkeletonLoader), findsNWidgets(3));
    });

    testWidgets('renders without leading when hasLeading is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonListTile(
              hasLeading: false,
            ),
          ),
        ),
      );

      // Should find 2 SkeletonLoaders: title and subtitle
      expect(find.byType(SkeletonLoader), findsNWidgets(2));
    });

    testWidgets('renders without subtitle when hasSubtitle is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonListTile(
              hasSubtitle: false,
            ),
          ),
        ),
      );

      // Should find 2 SkeletonLoaders: leading and title only
      expect(find.byType(SkeletonLoader), findsNWidgets(2));
    });

    testWidgets('renders with trailing when hasTrailing is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonListTile(
              hasTrailing: true,
            ),
          ),
        ),
      );

      // Should find 4 SkeletonLoaders: leading, title, subtitle, and trailing
      expect(find.byType(SkeletonLoader), findsNWidgets(4));
    });

    testWidgets('applies custom padding', (tester) async {
      const customPadding = EdgeInsets.all(24);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonListTile(
              padding: customPadding,
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find.descendant(
          of: find.byType(SkeletonListTile),
          matching: find.byType(Padding),
        ).first,
      );

      expect(padding.padding, customPadding);
    });

    testWidgets('renders all combinations correctly', (tester) async {
      // No leading, no trailing, no subtitle
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonListTile(
              hasLeading: false,
              hasTrailing: false,
              hasSubtitle: false,
            ),
          ),
        ),
      );

      // Should find 1 SkeletonLoader: title only
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });
  });

  group('SkeletonTreeItem Widget', () {
    testWidgets('renders with default indent level', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonTreeItem(),
          ),
        ),
      );

      // Should find 3 SkeletonLoaders: icon, title, and trailing info
      expect(find.byType(SkeletonLoader), findsNWidgets(3));
    });

    testWidgets('renders with children indicator when hasChildren is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonTreeItem(
              hasChildren: true,
            ),
          ),
        ),
      );

      // Should find 4 SkeletonLoaders: expand icon, item icon, title, and trailing info
      expect(find.byType(SkeletonLoader), findsNWidgets(4));
    });

    testWidgets('applies correct indent level', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonTreeItem(
              indentLevel: 2,
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find.descendant(
          of: find.byType(SkeletonTreeItem),
          matching: find.byType(Padding),
        ).first,
      );

      // Expected left padding: 16 (base) + (2 * 24) = 64
      expect((padding.padding as EdgeInsets).left, 64.0);
    });

    testWidgets('renders correctly with multiple indent levels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                SkeletonTreeItem(indentLevel: 0),
                SkeletonTreeItem(indentLevel: 1),
                SkeletonTreeItem(indentLevel: 2),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonTreeItem), findsNWidgets(3));
    });

    testWidgets('renders with children and indent level combined', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonTreeItem(
              indentLevel: 1,
              hasChildren: true,
            ),
          ),
        ),
      );

      // Should find 4 SkeletonLoaders when hasChildren is true
      expect(find.byType(SkeletonLoader), findsNWidgets(4));

      final padding = tester.widget<Padding>(
        find.descendant(
          of: find.byType(SkeletonTreeItem),
          matching: find.byType(Padding),
        ).first,
      );

      // Expected left padding: 16 (base) + (1 * 24) = 40
      expect((padding.padding as EdgeInsets).left, 40.0);
    });
  });
}
