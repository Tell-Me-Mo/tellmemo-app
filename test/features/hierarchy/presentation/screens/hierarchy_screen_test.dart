import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pm_master_v2/features/hierarchy/presentation/screens/hierarchy_screen.dart';
import 'package:pm_master_v2/features/hierarchy/domain/entities/hierarchy_item.dart';
import 'package:pm_master_v2/features/hierarchy/presentation/providers/hierarchy_providers.dart';
import 'package:pm_master_v2/features/hierarchy/presentation/providers/favorites_provider.dart';

import '../../../../mocks/mock_providers.dart';

// Helper to create MaterialApp with GoRouter for testing
Widget createTestApp(Widget child, List<Override> overrides) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => child,
      ),
    ],
  );

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  group('HierarchyScreen', () {
    late List<Override> overrides;

    setUp(() {
      overrides = [
        // Mock favorites provider - start with empty set
        favoritesProvider.overrideWith((ref) => FavoritesNotifier(ref)),
      ];
    });

    testWidgets('displays loading indicator while loading hierarchy', (tester) async {
      overrides.add(
        hierarchyStateProvider().overrideWith(() {
          return MockHierarchyState(items: []);
        }),
      );

      await tester.pumpWidget(createTestApp(const HierarchyScreen(), overrides));

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error state when hierarchy fails to load', (tester) async {
      overrides.add(
        hierarchyStateProvider().overrideWith(() {
          return MockHierarchyState(error: Exception('Failed to load hierarchy'));
        }),
      );

      await tester.pumpWidget(createTestApp(const HierarchyScreen(), overrides));

      await tester.pumpAndSettle();

      // Should show error indicator
      expect(find.byIcon(Icons.error_outline), findsWidgets);
    });

    testWidgets('displays empty state when no projects exist', (tester) async {
      overrides.add(
        hierarchyStateProvider().overrideWith(() {
          return MockHierarchyState(items: []);
        }),
      );

      await tester.pumpWidget(createTestApp(const HierarchyScreen(), overrides));

      await tester.pumpAndSettle();

      // Should show empty state icon
      expect(find.byIcon(Icons.folder_outlined), findsWidgets);
    });

    testWidgets('displays hierarchy items when data is loaded', (tester) async {
      final testHierarchy = [
        HierarchyItem(
          id: 'portfolio-1',
          name: 'Test Portfolio',
          type: HierarchyItemType.portfolio,
          children: [
            HierarchyItem(
              id: 'program-1',
              name: 'Test Program',
              type: HierarchyItemType.program,
              portfolioId: 'portfolio-1',
              children: [
                HierarchyItem(
                  id: 'project-1',
                  name: 'Test Project',
                  type: HierarchyItemType.project,
                  portfolioId: 'portfolio-1',
                  programId: 'program-1',
                  children: [],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              ],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      overrides.add(
        hierarchyStateProvider().overrideWith(() {
          return MockHierarchyState(items: testHierarchy);
        }),
      );

      await tester.pumpWidget(createTestApp(const HierarchyScreen(), overrides));

      await tester.pumpAndSettle();

      // Should not show loading indicator when data is loaded
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Should show search field (indicates data view is active)
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('displays search field', (tester) async {
      overrides.add(
        hierarchyStateProvider().overrideWith(() {
          return MockHierarchyState(items: []);
        }),
      );

      await tester.pumpWidget(createTestApp(const HierarchyScreen(), overrides));

      await tester.pumpAndSettle();

      // Should show search field
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search hierarchy...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('displays view mode toggle button', (tester) async {
      overrides.add(
        hierarchyStateProvider().overrideWith(() {
          return MockHierarchyState(items: []);
        }),
      );

      await tester.pumpWidget(createTestApp(const HierarchyScreen(), overrides));

      await tester.pumpAndSettle();

      // Should show view mode toggle
      expect(find.byIcon(Icons.dashboard), findsOneWidget);
    });

    testWidgets('toggles view mode when button is tapped', (tester) async {
      overrides.add(
        hierarchyStateProvider().overrideWith(() {
          return MockHierarchyState(items: []);
        }),
      );

      await tester.pumpWidget(createTestApp(const HierarchyScreen(), overrides));

      await tester.pumpAndSettle();

      // Initially shows dashboard icon (tree view active)
      expect(find.byIcon(Icons.dashboard), findsOneWidget);

      // Tap view mode toggle
      await tester.tap(find.byIcon(Icons.dashboard));
      await tester.pumpAndSettle();

      // Should now show tree icon (cards view active)
      expect(find.byIcon(Icons.account_tree), findsOneWidget);
    });

    testWidgets('displays type filter tabs', (tester) async {
      overrides.add(
        hierarchyStateProvider().overrideWith(() {
          return MockHierarchyState(items: []);
        }),
      );

      await tester.pumpWidget(createTestApp(const HierarchyScreen(), overrides));

      await tester.pumpAndSettle();

      // Should show at least the "All" filter tab
      expect(find.text('All'), findsWidgets);
    });

    testWidgets('displays favorites filter button', (tester) async {
      overrides.add(
        hierarchyStateProvider().overrideWith(() {
          return MockHierarchyState(items: []);
        }),
      );

      await tester.pumpWidget(createTestApp(const HierarchyScreen(), overrides));

      await tester.pumpAndSettle();

      // Should show favorites button
      expect(find.byIcon(Icons.star_border), findsOneWidget);
    });


    testWidgets('can pull to refresh hierarchy', (tester) async {
      overrides.add(
        hierarchyStateProvider().overrideWith(() {
          return MockHierarchyState(items: []);
        }),
      );

      await tester.pumpWidget(createTestApp(const HierarchyScreen(), overrides));

      await tester.pumpAndSettle();

      // Should have RefreshIndicator
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
