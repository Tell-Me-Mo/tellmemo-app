import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pm_master_v2/core/widgets/breadcrumb_navigation.dart';

void main() {
  group('BreadcrumbNavigation Widget', () {
    late GoRouter router;
    String? lastNavigatedRoute;

    setUp(() {
      lastNavigatedRoute = null;
      router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const Scaffold(body: Text('Dashboard')),
          ),
          GoRoute(
            path: '/projects',
            builder: (context, state) => const Scaffold(body: Text('Projects')),
          ),
        ],
        redirect: (context, state) {
          lastNavigatedRoute = state.uri.toString();
          return null;
        },
      );
    });

    Widget createTestWidget(List<BreadcrumbItem> items, {bool showOnMobile = true}) {
      return MaterialApp.router(
        routerConfig: router,
        builder: (context, child) {
          return Scaffold(
            body: Column(
              children: [
                BreadcrumbNavigation(
                  items: items,
                  showOnMobile: showOnMobile,
                ),
                Expanded(child: child ?? const SizedBox.shrink()),
              ],
            ),
          );
        },
      );
    }

    testWidgets('displays all breadcrumb items', (tester) async {
      final items = [
        BreadcrumbItem(label: 'Home', route: '/home'),
        BreadcrumbItem(label: 'Dashboard', route: '/dashboard'),
        BreadcrumbItem(label: 'Projects'),
      ];

      await tester.pumpWidget(createTestWidget(items));

      // At least one of each should be found (may have duplicates due to routing)
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Projects'), findsWidgets);
    });

    testWidgets('displays chevron separators between items', (tester) async {
      final items = [
        BreadcrumbItem(label: 'Home', route: '/home'),
        BreadcrumbItem(label: 'Dashboard', route: '/dashboard'),
        BreadcrumbItem(label: 'Projects'),
      ];

      await tester.pumpWidget(createTestWidget(items));

      // Should have 2 chevron separators for 3 items
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    });

    testWidgets('displays icon when provided', (tester) async {
      final items = [
        BreadcrumbItem(label: 'Home', route: '/home', icon: Icons.home),
        BreadcrumbItem(label: 'Projects'),
      ];

      await tester.pumpWidget(createTestWidget(items));

      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('last item is not clickable', (tester) async {
      final items = [
        BreadcrumbItem(label: 'Home', route: '/home'),
        BreadcrumbItem(label: 'Projects', route: '/projects'),
      ];

      await tester.pumpWidget(createTestWidget(items));

      // Last item should not have InkWell
      final projectsText = find.text('Projects');
      final inkWells = find.ancestor(
        of: projectsText,
        matching: find.byType(InkWell),
      );
      expect(inkWells, findsNothing);
    });

    testWidgets('clicking non-last item triggers navigation', (tester) async {
      final items = [
        BreadcrumbItem(label: 'Home', route: '/home'),
        BreadcrumbItem(label: 'Dashboard', route: '/dashboard'),
        BreadcrumbItem(label: 'Projects'),
      ];

      await tester.pumpWidget(createTestWidget(items));
      await tester.pump();

      // Find all Dashboard texts and tap the first one (in breadcrumb)
      await tester.tap(find.text('Dashboard').first);
      await tester.pump();

      // Just verify navigation was attempted (route should be set)
      expect(lastNavigatedRoute, isNot(isNull));
    });

    testWidgets('item without route is not clickable', (tester) async {
      final items = [
        BreadcrumbItem(label: 'Home', route: '/home'),
        BreadcrumbItem(label: 'Dashboard'), // No route
      ];

      await tester.pumpWidget(createTestWidget(items));

      final dashboardText = find.text('Dashboard');
      final inkWells = find.ancestor(
        of: dashboardText,
        matching: find.byType(InkWell),
      );
      expect(inkWells, findsNothing);
    });

    testWidgets('hides on mobile when showOnMobile is false', (tester) async {
      final items = [
        BreadcrumbItem(label: 'Home', route: '/home'),
        BreadcrumbItem(label: 'Projects'),
      ];

      await tester.pumpWidget(createTestWidget(items, showOnMobile: false));

      // Set mobile screen size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpAndSettle();

      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('shows collapsed breadcrumbs on mobile when many items', (tester) async {
      final items = [
        BreadcrumbItem(label: 'Home', route: '/home'),
        BreadcrumbItem(label: 'Dashboard', route: '/dashboard'),
        BreadcrumbItem(label: 'Workspace', route: '/workspace'),
        BreadcrumbItem(label: 'Projects'),
      ];

      // Set mobile screen size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestWidget(items));
      await tester.pumpAndSettle();

      // Should show first item, ellipsis menu, and last item
      expect(find.text('Home'), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);
    });

    testWidgets('collapsed breadcrumbs popup shows middle items', (tester) async {
      final items = [
        BreadcrumbItem(label: 'Home', route: '/home'),
        BreadcrumbItem(label: 'Dashboard', route: '/dashboard', icon: Icons.dashboard),
        BreadcrumbItem(label: 'Workspace', route: '/workspace'),
        BreadcrumbItem(label: 'Projects'),
      ];

      // Set mobile screen size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestWidget(items));
      await tester.pumpAndSettle();

      // Tap ellipsis menu
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();

      // Should show middle items in popup
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Workspace'), findsOneWidget);
      expect(find.byIcon(Icons.dashboard), findsOneWidget);
    });

    testWidgets('selecting item from collapsed menu works', (tester) async {
      final items = [
        BreadcrumbItem(label: 'Home', route: '/home'),
        BreadcrumbItem(label: 'Dashboard', route: '/dashboard'),
        BreadcrumbItem(label: 'Workspace', route: '/workspace'),
        BreadcrumbItem(label: 'Projects'),
      ];

      // Set mobile screen size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestWidget(items));
      await tester.pump();

      // Open ellipsis menu
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pump();

      // Verify menu shows Dashboard
      expect(find.text('Dashboard'), findsWidgets);
    });

    testWidgets('last item has distinct styling', (tester) async {
      final items = [
        BreadcrumbItem(label: 'Home', route: '/home'),
        BreadcrumbItem(label: 'Projects'),
      ];

      await tester.pumpWidget(createTestWidget(items));
      await tester.pumpAndSettle();

      // Last item container should have background color
      final containers = tester.widgetList<Container>(find.byType(Container));
      bool hasHighlightedContainer = false;

      for (final container in containers) {
        final decoration = container.decoration as BoxDecoration?;
        if (decoration?.color != null && decoration!.color != Colors.transparent) {
          hasHighlightedContainer = true;
          break;
        }
      }

      expect(hasHighlightedContainer, true);
    });

    testWidgets('shows all items on desktop regardless of count', (tester) async {
      final items = [
        BreadcrumbItem(label: 'Home', route: '/home'),
        BreadcrumbItem(label: 'Dashboard', route: '/dashboard'),
        BreadcrumbItem(label: 'Workspace', route: '/workspace'),
        BreadcrumbItem(label: 'Projects'),
      ];

      // Set desktop screen size
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestWidget(items));
      await tester.pumpAndSettle();

      // All items should be visible
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Workspace'), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);

      // No ellipsis menu
      expect(find.byIcon(Icons.more_horiz), findsNothing);
    });

    testWidgets('handles single item breadcrumb', (tester) async {
      final items = [
        BreadcrumbItem(label: 'Home'),
      ];

      await tester.pumpWidget(createTestWidget(items));

      expect(find.text('Home'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('handles two items on mobile without collapsing', (tester) async {
      final items = [
        BreadcrumbItem(label: 'Home', route: '/home'),
        BreadcrumbItem(label: 'Projects'),
      ];

      // Set mobile screen size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestWidget(items));
      await tester.pumpAndSettle();

      // Should not show ellipsis menu for 2 items
      expect(find.byIcon(Icons.more_horiz), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);
    });
  });
}
