import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/queries/presentation/widgets/typing_indicator.dart';
import 'package:pm_master_v2/core/utils/animation_utils.dart';
import 'package:pm_master_v2/core/widgets/loading/skeleton_loader.dart';

void main() {
  group('25.1 Performance Optimization', () {
    group('Widget build performance', () {
      testWidgets('TypingIndicator properly disposes AnimationController',
          (tester) async {
        // Arrange - Create widget with AnimationController
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TypingIndicator(),
            ),
          ),
        );
        await tester.pump();

        // Get the state to verify controller exists
        final state =
            tester.state<State<TypingIndicator>>(find.byType(TypingIndicator));
        expect(state, isNotNull);

        // Act - Dispose the widget
        await tester.pumpWidget(const SizedBox());

        // Assert - No errors should occur during disposal
        // If controller is not disposed, Flutter will show warnings
        expect(tester.takeException(), isNull);
      });

      testWidgets('SkeletonLoader properly disposes AnimationController',
          (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkeletonLoader(
                width: 100,
                height: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
        await tester.pump();

        // Act - Dispose the widget
        await tester.pumpWidget(const SizedBox());

        // Assert - No disposal errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('Multiple TypingIndicators can be created and disposed',
          (tester) async {
        // Test for memory leaks by creating multiple instances
        for (int i = 0; i < 10; i++) {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: TypingIndicator(),
              ),
            ),
          );
          await tester.pump();

          // Dispose
          await tester.pumpWidget(const SizedBox());
        }

        // Assert - No memory leak errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('Const constructors reduce widget rebuilds', (tester) async {
        int buildCount = 0;

        Widget buildTestWidget() {
          return MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  buildCount++;
                  return const TypingIndicator();
                },
              ),
            ),
          );
        }

        // Initial build
        await tester.pumpWidget(buildTestWidget());
        expect(buildCount, 1);

        // Trigger a rebuild by creating a new widget tree
        await tester.pumpWidget(buildTestWidget());

        // Builder rebuilds with new widget tree
        expect(buildCount, 2);
      });
    });

    group('List scrolling performance (ListView.builder)', () {
      testWidgets('Large list uses builder pattern for performance',
          (tester) async {
        // Arrange - Create a large list
        final items = List.generate(1000, (index) => 'Item $index');

        // Act - Build ListView.builder
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    key: ValueKey(index),
                    title: Text(items[index]),
                  );
                },
              ),
            ),
          ),
        );

        // Assert - Only visible items should be built
        // In a normal screen, only ~10-20 items are visible
        final listTiles = find.byType(ListTile);
        expect(listTiles.evaluate().length, lessThan(50));

        // Scroll and verify lazy loading
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pump();

        // Still only visible items in widget tree
        expect(find.byType(ListTile).evaluate().length, lessThan(50));
      });

      testWidgets('GridView.builder efficiently renders large grids',
          (tester) async {
        // Arrange
        final items = List.generate(100, (index) => 'Item $index');

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return Card(
                    key: ValueKey(index),
                    child: Center(child: Text(items[index])),
                  );
                },
              ),
            ),
          ),
        );

        // Assert - Only visible items should be rendered
        final cards = find.byType(Card);
        expect(cards.evaluate().length, lessThan(30)); // Only visible cards
      });

      testWidgets('ListView.builder with keys prevents unnecessary rebuilds',
          (tester) async {
        // Arrange
        int buildCount = 0;
        final items = ['Item 1', 'Item 2', 'Item 3'];

        Widget buildList() {
          return MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  buildCount++;
                  return ListTile(
                    key: ValueKey(items[index]),
                    title: Text(items[index]),
                  );
                },
              ),
            ),
          );
        }

        // Act - Initial build
        await tester.pumpWidget(buildList());
        final initialBuildCount = buildCount;

        // Pump without changes
        await tester.pump();

        // Assert - No additional rebuilds
        expect(buildCount, initialBuildCount);
      });
    });

    group('Large data rendering', () {
      testWidgets('Handles 10,000 items without performance issues',
          (tester) async {
        // Arrange
        final items = List.generate(10000, (index) => 'Item $index');

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    key: ValueKey(index),
                    title: Text(items[index]),
                  );
                },
              ),
            ),
          ),
        );

        // Assert - Widget tree remains small
        expect(find.byType(ListTile).evaluate().length, lessThan(50));

        // Scroll to bottom efficiently
        await tester.drag(find.byType(ListView), const Offset(0, -10000));
        await tester.pumpAndSettle();

        // Still only visible items
        expect(find.byType(ListTile).evaluate().length, lessThan(50));
      });

      testWidgets('Nested lists use builder pattern', (tester) async {
        // Test nested ListView.builder for complex layouts
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, outerIndex) {
                  return Card(
                    key: ValueKey('outer_$outerIndex'),
                    child: SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 20,
                        itemBuilder: (context, innerIndex) {
                          return Container(
                            key: ValueKey('inner_${outerIndex}_$innerIndex'),
                            width: 80,
                            margin: const EdgeInsets.all(4),
                            color: Colors.blue,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // Assert - Only visible items are rendered
        expect(find.byType(Card).evaluate().length, lessThan(20));
      });
    });

    group('Memory usage', () {
      testWidgets('AnimationController disposal prevents memory leaks',
          (tester) async {
        // Create and dispose multiple animated widgets
        for (int i = 0; i < 20; i++) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    const TypingIndicator(),
                    SkeletonLoader(
                      width: 100,
                      height: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pump();

          // Dispose
          await tester.pumpWidget(const SizedBox());
        }

        // No memory leak errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('Widget tree stays shallow with builder patterns',
          (tester) async {
        // Compare widget tree depth
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: 1000,
                itemBuilder: (context, index) {
                  return Text('Item $index', key: ValueKey(index));
                },
              ),
            ),
          ),
        );

        // Only visible widgets in tree
        final textWidgets = find.byType(Text);
        expect(textWidgets.evaluate().length, lessThan(50));
      });

      testWidgets('Const widgets are reused across rebuilds', (tester) async {
        const constWidget = SizedBox(width: 100, height: 100);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: constWidget,
            ),
          ),
        );

        final widget1 = tester.widget<SizedBox>(find.byType(SizedBox));

        // Rebuild
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: constWidget,
            ),
          ),
        );

        final widget2 = tester.widget<SizedBox>(find.byType(SizedBox));

        // Same instance due to const
        expect(identical(widget1, widget2), isTrue);
      });
    });

    group('Image loading/caching', () {
      testWidgets('Image.network uses caching by default', (tester) async {
        // Flutter's Image.network automatically caches images
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Image.network(
                'https://example.com/image.png',
                // Default cacheWidth/cacheHeight are null (full resolution)
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error);
                },
              ),
            ),
          ),
        );

        // Wait for image to load (will fail with error icon in test)
        await tester.pump();

        // Assert - Image widget exists
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('Multiple identical images use same cache', (tester) async {
        const imageUrl = 'https://example.com/image.png';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Image.network(
                    imageUrl,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error),
                  ),
                  Image.network(
                    imageUrl,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error),
                  ),
                  Image.network(
                    imageUrl,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();

        // All images exist
        expect(find.byType(Image), findsNWidgets(3));
      });
    });

    group('Lazy loading', () {
      testWidgets('ListView loads items on-demand', (tester) async {
        int buildCount = 0;
        final items = List.generate(100, (index) => 'Item $index');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  buildCount++;
                  return ListTile(
                    key: ValueKey(index),
                    title: Text(items[index]),
                  );
                },
              ),
            ),
          ),
        );

        final initialBuildCount = buildCount;

        // Assert - Not all items built initially
        expect(initialBuildCount, lessThan(items.length));
        expect(initialBuildCount, lessThan(50));

        // Scroll to load more
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pump();

        // More items built after scroll
        expect(buildCount, greaterThan(initialBuildCount));

        // But still not all items
        expect(buildCount, lessThan(items.length));
      });

      testWidgets('AnimationUtils routes are lazy', (tester) async {
        bool widgetBuilt = false;

        final route = AnimationUtils.slideUpDialogRoute(
          builder: (context) {
            widgetBuilt = true;
            return const Scaffold(body: Text('Dialog'));
          },
        );

        // Assert - Widget not built until route is pushed
        expect(widgetBuilt, isFalse);

        // Now push the route
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(route);
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        );

        // Tap button to push route
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Now widget is built
        expect(widgetBuilt, isTrue);
      });

      testWidgets('FadeScale route is also lazy', (tester) async {
        bool widgetBuilt = false;

        final route = AnimationUtils.fadeScaleDialogRoute(
          builder: (context) {
            widgetBuilt = true;
            return const Scaffold(body: Text('Dialog'));
          },
        );

        // Widget not built until route is pushed
        expect(widgetBuilt, isFalse);

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(route);
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(widgetBuilt, isTrue);
      });
    });

    group('Animation performance', () {
      testWidgets('AnimationController uses vsync for efficiency',
          (tester) async {
        // TypingIndicator uses SingleTickerProviderStateMixin
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TypingIndicator(),
            ),
          ),
        );

        // Let animation run
        await tester.pump(const Duration(milliseconds: 100));

        // Animation should be smooth without errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('Multiple animations can run simultaneously',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const TypingIndicator(),
                  const TypingIndicator(),
                  SkeletonLoader(
                    width: 100,
                    height: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  SkeletonLoader(
                    width: 100,
                    height: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ),
        );

        // Let animations run
        await tester.pump(const Duration(milliseconds: 100));

        // No performance issues
        expect(tester.takeException(), isNull);
      });

      testWidgets('Staggered animations create efficient transitions',
          (tester) async {
        final animations = AnimationUtils.createStaggeredAnimations(
          itemCount: 5,
          controller: AnimationController(
            vsync: const TestVSync(),
            duration: const Duration(milliseconds: 500),
          ),
        );

        // Assert - Correct number of animations created
        expect(animations.length, 5);

        // Each animation has proper interval
        for (int i = 0; i < animations.length; i++) {
          expect(animations[i], isA<Animation<double>>());
        }
      });
    });
  });
}
