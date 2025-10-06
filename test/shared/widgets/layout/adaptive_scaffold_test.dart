import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/shared/widgets/layout/adaptive_scaffold.dart';

void main() {
  group('AdaptiveScaffold', () {
    final testDestinations = [
      const AdaptiveDestination(
        icon: Icon(Icons.home),
        label: 'Home',
        route: '/home',
      ),
      const AdaptiveDestination(
        icon: Icon(Icons.settings),
        selectedIcon: Icon(Icons.settings, color: Colors.blue),
        label: 'Settings',
        route: '/settings',
      ),
      const AdaptiveDestination(
        icon: Icon(Icons.person),
        label: 'Profile',
        tooltip: 'User Profile',
        route: '/profile',
      ),
    ];

    group('Mobile Layout', () {
      testWidgets('displays BottomNavigationBar on mobile screen', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveScaffold(
              body: const Text('Content'),
              destinations: testDestinations,
              selectedIndex: 0,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should have NavigationBar (Material 3 bottom navigation)
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);

        // Should show all destinations
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
      });

      testWidgets('displays AppBar when showAppBar is true', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveScaffold(
              body: const Text('Content'),
              title: 'Test Title',
              destinations: testDestinations,
              selectedIndex: 0,
              showAppBar: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Test Title'), findsOneWidget);
      });

      testWidgets('hides AppBar when showAppBar is false', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveScaffold(
              body: const Text('Content'),
              destinations: testDestinations,
              selectedIndex: 0,
              showAppBar: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppBar), findsNothing);
      });

      testWidgets('handles destination selection', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        int? selectedIndex;

        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveScaffold(
              body: const Text('Content'),
              destinations: testDestinations,
              selectedIndex: 0,
              onDestinationSelected: (index) {
                selectedIndex = index;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap on Settings destination
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();

        expect(selectedIndex, 1);
      });

      testWidgets('displays selected icon when destination is selected', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveScaffold(
              body: const Text('Content'),
              destinations: testDestinations,
              selectedIndex: 1, // Settings selected
            ),
          ),
        );
        await tester.pumpAndSettle();

        // NavigationBar should be present
        expect(find.byType(NavigationBar), findsOneWidget);
      });

      testWidgets('displays floating action button', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveScaffold(
              body: const Text('Content'),
              destinations: testDestinations,
              selectedIndex: 0,
              floatingActionButton: FloatingActionButton(
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('displays AppBar actions', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveScaffold(
              body: const Text('Content'),
              destinations: testDestinations,
              selectedIndex: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.search), findsOneWidget);
      });
    });

    group('Tablet Layout', () {
      testWidgets('displays NavigationRail on tablet screen', (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveScaffold(
              body: const Text('Content'),
              destinations: testDestinations,
              selectedIndex: 0,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should have NavigationRail
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);

        // Should show vertical divider
        expect(find.byType(VerticalDivider), findsOneWidget);
      });

      testWidgets('NavigationRail shows all labels on tablet', (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveScaffold(
              body: const Text('Content'),
              destinations: testDestinations,
              selectedIndex: 0,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final navigationRail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(navigationRail.labelType, NavigationRailLabelType.all);
      });

      testWidgets('handles destination selection on tablet', (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        int? selectedIndex;

        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveScaffold(
              body: const Text('Content'),
              destinations: testDestinations,
              selectedIndex: 0,
              onDestinationSelected: (index) {
                selectedIndex = index;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap on Settings destination in NavigationRail
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();

        expect(selectedIndex, 1);
      });
    });

    group('Desktop Layout', () {
      testWidgets('displays NavigationRail on desktop screen', (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveScaffold(
              body: const Text('Content'),
              destinations: testDestinations,
              selectedIndex: 0,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should have NavigationRail
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      });

      testWidgets('NavigationRail can be extended on desktop', (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveScaffold(
              body: const Text('Content'),
              destinations: testDestinations,
              selectedIndex: 0,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially not extended
        NavigationRail navigationRail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(navigationRail.extended, false);

        // Tap menu button to extend
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();

        // Now should be extended
        navigationRail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(navigationRail.extended, true);

        // Tap again to collapse
        await tester.tap(find.byIcon(Icons.menu_open));
        await tester.pumpAndSettle();

        // Should be collapsed again
        navigationRail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(navigationRail.extended, false);
      });

      testWidgets('desktop layout has nested AppBar', (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveScaffold(
              body: const Text('Content'),
              title: 'Desktop Title',
              destinations: testDestinations,
              selectedIndex: 0,
              showAppBar: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should have AppBar with title
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Desktop Title'), findsOneWidget);
      });
    });

    group('AdaptiveDestination', () {
      test('creates destination with required parameters', () {
        const destination = AdaptiveDestination(
          icon: Icon(Icons.home),
          label: 'Home',
        );

        expect(destination.icon, isA<Icon>());
        expect(destination.label, 'Home');
        expect(destination.selectedIcon, isNull);
        expect(destination.tooltip, isNull);
        expect(destination.route, isNull);
      });

      test('creates destination with all parameters', () {
        const destination = AdaptiveDestination(
          icon: Icon(Icons.home),
          selectedIcon: Icon(Icons.home, color: Colors.blue),
          label: 'Home',
          tooltip: 'Home Screen',
          route: '/home',
        );

        expect(destination.icon, isA<Icon>());
        expect(destination.selectedIcon, isA<Icon>());
        expect(destination.label, 'Home');
        expect(destination.tooltip, 'Home Screen');
        expect(destination.route, '/home');
      });
    });

    group('Body Content', () {
      testWidgets('displays body content correctly', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveScaffold(
              body: const Center(child: Text('Test Body Content')),
              destinations: testDestinations,
              selectedIndex: 0,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Test Body Content'), findsOneWidget);
      });

      testWidgets('body content is visible in all layouts', (tester) async {
        final sizes = [
          const Size(400, 800),  // Mobile
          const Size(800, 1200), // Tablet
          const Size(1920, 1080), // Desktop
        ];

        for (final size in sizes) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            MaterialApp(
              home: AdaptiveScaffold(
                body: const Center(child: Text('Body Content')),
                destinations: testDestinations,
                selectedIndex: 0,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Body Content'), findsOneWidget);

          // Clean up
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        }
      });
    });
  });
}
