import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/core/utils/animation_utils.dart';
import 'package:pm_master_v2/core/constants/ui_constants.dart';

void main() {
  group('AnimationUtils', () {
    group('slideUpDialogRoute', () {
      testWidgets('creates route with correct default parameters', (tester) async {
        final route = AnimationUtils.slideUpDialogRoute<void>(
          builder: (context) => const Text('Test Dialog'),
        ) as PageRouteBuilder<void>;

        expect(route, isA<PageRouteBuilder<void>>());
        expect(route.barrierDismissible, true);
        expect(route.barrierColor, Colors.black54);
        expect(route.transitionDuration, UIConstants.normalAnimation);
        expect(route.reverseTransitionDuration, UIConstants.shortAnimation);
      });

      testWidgets('creates route with custom parameters', (tester) async {
        const customColor = Colors.red;
        const customLabel = 'Custom Dialog';

        final route = AnimationUtils.slideUpDialogRoute<String>(
          builder: (context) => const Text('Test Dialog'),
          barrierDismissible: false,
          barrierColor: customColor,
          barrierLabel: customLabel,
        ) as PageRouteBuilder<String>;

        expect(route.barrierDismissible, false);
        expect(route.barrierColor, customColor);
        expect(route.barrierLabel, customLabel);
      });

      testWidgets('displays widget from builder', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      AnimationUtils.slideUpDialogRoute<void>(
                        builder: (context) => const Material(
                          child: Center(child: Text('Dialog Content')),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Dialog Content'), findsOneWidget);
      });

      testWidgets('animates with slide and fade transition', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      AnimationUtils.slideUpDialogRoute<void>(
                        builder: (context) => const Material(
                          child: Center(child: Text('Animated Dialog')),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pump(); // Start animation
        await tester.pump(const Duration(milliseconds: 50)); // Mid-animation

        // Dialog should be visible during animation
        expect(find.text('Animated Dialog'), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.text('Animated Dialog'), findsOneWidget);
      });
    });

    group('fadeScaleDialogRoute', () {
      testWidgets('creates route with correct default parameters', (tester) async {
        final route = AnimationUtils.fadeScaleDialogRoute<void>(
          builder: (context) => const Text('Test Dialog'),
        ) as PageRouteBuilder<void>;

        expect(route, isA<PageRouteBuilder<void>>());
        expect(route.barrierDismissible, true);
        expect(route.barrierColor, Colors.black54);
        expect(route.transitionDuration, UIConstants.normalAnimation);
        expect(route.reverseTransitionDuration, UIConstants.shortAnimation);
      });

      testWidgets('creates route with custom parameters', (tester) async {
        final route = AnimationUtils.fadeScaleDialogRoute<int>(
          builder: (context) => const Text('Test Dialog'),
          barrierDismissible: false,
          barrierColor: Colors.blue,
          barrierLabel: 'Test Label',
        ) as PageRouteBuilder<int>;

        expect(route.barrierDismissible, false);
        expect(route.barrierColor, Colors.blue);
        expect(route.barrierLabel, 'Test Label');
      });

      testWidgets('displays widget from builder', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      AnimationUtils.fadeScaleDialogRoute<void>(
                        builder: (context) => const Material(
                          child: Center(child: Text('Scale Dialog')),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Scale Dialog'), findsOneWidget);
      });
    });

    group('buildAnimatedListItem', () {
      testWidgets('builds widget with slide and fade animation', (tester) async {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: tester,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return AnimationUtils.buildAnimatedListItem(
                  child: const Text('List Item'),
                  animation: controller,
                );
              },
            ),
          ),
        );

        expect(find.text('List Item'), findsOneWidget);
        controller.dispose();
      });

      testWidgets('slides from left by default', (tester) async {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: tester,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return AnimationUtils.buildAnimatedListItem(
                  child: const Text('Left Slide'),
                  animation: controller,
                  slideFromRight: false,
                );
              },
            ),
          ),
        );

        expect(find.text('Left Slide'), findsOneWidget);
        controller.dispose();
      });

      testWidgets('slides from right when specified', (tester) async {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: tester,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return AnimationUtils.buildAnimatedListItem(
                  child: const Text('Right Slide'),
                  animation: controller,
                  slideFromRight: true,
                );
              },
            ),
          ),
        );

        expect(find.text('Right Slide'), findsOneWidget);
        controller.dispose();
      });
    });

    group('createStaggeredAnimations', () {
      test('creates correct number of animations', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 500),
          vsync: const TestVSync(),
        );

        final animations = AnimationUtils.createStaggeredAnimations(
          controller: controller,
          itemCount: 5,
        );

        expect(animations.length, 5);
        controller.dispose();
      });

      test('creates animations with correct interval', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 500),
          vsync: const TestVSync(),
        );

        final animations = AnimationUtils.createStaggeredAnimations(
          controller: controller,
          itemCount: 3,
        );

        expect(animations.length, 3);
        expect(animations[0], isA<Animation<double>>());
        expect(animations[1], isA<Animation<double>>());
        expect(animations[2], isA<Animation<double>>());
        controller.dispose();
      });

      test('handles single item', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 500),
          vsync: const TestVSync(),
        );

        final animations = AnimationUtils.createStaggeredAnimations(
          controller: controller,
          itemCount: 1,
        );

        expect(animations.length, 1);
        controller.dispose();
      });

      test('handles empty list', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 500),
          vsync: const TestVSync(),
        );

        final animations = AnimationUtils.createStaggeredAnimations(
          controller: controller,
          itemCount: 0,
        );

        expect(animations.length, 0);
        controller.dispose();
      });

      test('respects custom total duration', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 1000),
          vsync: const TestVSync(),
        );

        final animations = AnimationUtils.createStaggeredAnimations(
          controller: controller,
          itemCount: 3,
          totalDuration: const Duration(milliseconds: 1000),
        );

        expect(animations.length, 3);
        controller.dispose();
      });
    });
  });

  group('AnimatedExpansion', () {
    testWidgets('displays child when expanded', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedExpansion(
            isExpanded: true,
            child: Text('Expanded Content'),
          ),
        ),
      );

      expect(find.text('Expanded Content'), findsOneWidget);
    });

    testWidgets('hides child when collapsed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedExpansion(
            isExpanded: false,
            child: Text('Collapsed Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Content is still in widget tree but has zero size
      expect(find.text('Collapsed Content'), findsOneWidget);
    });

    testWidgets('animates between expanded and collapsed states', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedExpansion(
            isExpanded: false,
            child: Text('Animated Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedExpansion(
            isExpanded: true,
            child: Text('Animated Content'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Animated Content'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Animated Content'), findsOneWidget);
    });

    testWidgets('uses custom duration when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedExpansion(
            isExpanded: false,
            duration: Duration(milliseconds: 500),
            child: Text('Custom Duration'),
          ),
        ),
      );

      expect(find.text('Custom Duration'), findsOneWidget);
    });

    testWidgets('uses custom curve when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedExpansion(
            isExpanded: false,
            curve: Curves.easeIn,
            child: Text('Custom Curve'),
          ),
        ),
      );

      expect(find.text('Custom Curve'), findsOneWidget);
    });

    testWidgets('properly disposes animation controller', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedExpansion(
            isExpanded: true,
            child: Text('Dispose Test'),
          ),
        ),
      );

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      // If controller wasn't disposed, this would throw
      await tester.pumpAndSettle();
    });
  });

  group('AnimatedStateTransition', () {
    testWidgets('displays child by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedStateTransition(
            child: Text('Main Content'),
          ),
        ),
      );

      expect(find.text('Main Content'), findsOneWidget);
    });

    testWidgets('displays loading widget when showLoading is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedStateTransition(
            showLoading: true,
            loadingWidget: Text('Loading'),
            child: Text('Main Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Loading'), findsOneWidget);
      expect(find.text('Main Content'), findsNothing);
    });

    testWidgets('displays error widget when showError is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedStateTransition(
            showError: true,
            errorWidget: Text('Error'),
            child: Text('Main Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Main Content'), findsNothing);
    });

    testWidgets('displays empty widget when showEmpty is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedStateTransition(
            showEmpty: true,
            emptyWidget: Text('Empty'),
            child: Text('Main Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Empty'), findsOneWidget);
      expect(find.text('Main Content'), findsNothing);
    });

    testWidgets('loading takes precedence over error and empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedStateTransition(
            showLoading: true,
            showError: true,
            showEmpty: true,
            loadingWidget: Text('Loading'),
            errorWidget: Text('Error'),
            emptyWidget: Text('Empty'),
            child: Text('Main Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Loading'), findsOneWidget);
      expect(find.text('Error'), findsNothing);
      expect(find.text('Empty'), findsNothing);
      expect(find.text('Main Content'), findsNothing);
    });

    testWidgets('error takes precedence over empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedStateTransition(
            showError: true,
            showEmpty: true,
            errorWidget: Text('Error'),
            emptyWidget: Text('Empty'),
            child: Text('Main Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Empty'), findsNothing);
      expect(find.text('Main Content'), findsNothing);
    });

    testWidgets('animates state changes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedStateTransition(
            child: Text('Main Content'),
          ),
        ),
      );

      expect(find.text('Main Content'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedStateTransition(
            showLoading: true,
            loadingWidget: Text('Loading'),
            child: Text('Main Content'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Loading'), findsOneWidget);
    });

    testWidgets('uses custom duration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedStateTransition(
            duration: Duration(milliseconds: 500),
            child: Text('Custom Duration'),
          ),
        ),
      );

      expect(find.text('Custom Duration'), findsOneWidget);
    });

    testWidgets('displays child when no state widgets provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedStateTransition(
            showLoading: true,
            showError: true,
            showEmpty: true,
            child: Text('Fallback Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Fallback Content'), findsOneWidget);
    });
  });

  group('ShimmerLoading', () {
    testWidgets('displays child without shimmer when not loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ShimmerLoading(
            isLoading: false,
            child: Text('Content'),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('displays child with shimmer when loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ShimmerLoading(
            isLoading: true,
            child: Text('Loading Content'),
          ),
        ),
      );

      expect(find.text('Loading Content'), findsOneWidget);
    });

    testWidgets('starts shimmer animation when loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ShimmerLoading(
            isLoading: true,
            child: Text('Shimmer Test'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Shimmer Test'), findsOneWidget);
    });

    testWidgets('stops shimmer animation when not loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ShimmerLoading(
            isLoading: true,
            child: Text('Shimmer Test'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(
        const MaterialApp(
          home: ShimmerLoading(
            isLoading: false,
            child: Text('Shimmer Test'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Shimmer Test'), findsOneWidget);
    });

    testWidgets('uses custom duration when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ShimmerLoading(
            isLoading: true,
            duration: Duration(milliseconds: 2000),
            child: Text('Custom Duration'),
          ),
        ),
      );

      expect(find.text('Custom Duration'), findsOneWidget);
    });

    testWidgets('properly disposes animation controller', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ShimmerLoading(
            isLoading: true,
            child: Text('Dispose Test'),
          ),
        ),
      );

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();
      // If controller wasn't disposed, this would throw
    });

    testWidgets('toggles shimmer animation on state change', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ShimmerLoading(
            isLoading: false,
            child: Text('Toggle Test'),
          ),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ShimmerLoading(
            isLoading: true,
            child: Text('Toggle Test'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Toggle Test'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: ShimmerLoading(
            isLoading: false,
            child: Text('Toggle Test'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Toggle Test'), findsOneWidget);
    });
  });
}

// Helper class for testing AnimationController
class TestVSync extends TickerProvider {
  const TestVSync();

  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}
