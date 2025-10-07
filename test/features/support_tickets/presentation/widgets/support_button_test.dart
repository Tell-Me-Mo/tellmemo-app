import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pm_master_v2/features/support_tickets/presentation/widgets/support_button.dart';

void main() {
  group('SupportButton', () {
    late GoRouter router;
    String? lastRoute;

    setUp(() {
      lastRoute = null;
      router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: SupportButton(),
            ),
          ),
          GoRoute(
            path: '/support-tickets',
            builder: (context, state) {
              lastRoute = '/support-tickets';
              return const Scaffold(body: Text('Support Tickets'));
            },
          ),
        ],
      );
    });

    testWidgets('renders with help icon', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('has Support tooltip', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      final iconButton = find.byType(IconButton);
      expect(iconButton, findsOneWidget);

      // Verify tooltip exists
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('navigates to support tickets screen on tap', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(lastRoute, '/support-tickets');
      expect(find.text('Support Tickets'), findsOneWidget);
    });

    testWidgets('has badge widget', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      expect(find.byType(Badge), findsOneWidget);
    });

    testWidgets('badge is not visible by default', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      final badge = tester.widget<Badge>(find.byType(Badge));
      expect(badge.isLabelVisible, false);
    });
  });

  group('SupportButtonExpanded', () {
    late GoRouter router;
    String? lastRoute;

    setUp(() {
      lastRoute = null;
      router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: SupportButtonExpanded(),
            ),
          ),
          GoRoute(
            path: '/support-tickets',
            builder: (context, state) {
              lastRoute = '/support-tickets';
              return const Scaffold(body: Text('Support Tickets'));
            },
          ),
        ],
      );
    });

    testWidgets('renders in collapsed mode by default', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      expect(find.text('Support'), findsNothing);
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('renders in expanded mode when isExpanded is true', (tester) async {
      router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: SupportButtonExpanded(isExpanded: true),
            ),
          ),
          GoRoute(
            path: '/support-tickets',
            builder: (context, state) {
              lastRoute = '/support-tickets';
              return const Scaffold(body: Text('Support Tickets'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      expect(find.text('Support'), findsOneWidget);
      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('navigates to support tickets screen on tap (collapsed)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(lastRoute, '/support-tickets');
      expect(find.text('Support Tickets'), findsOneWidget);
    });

    testWidgets('navigates to support tickets screen on tap (expanded)', (tester) async {
      router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: SupportButtonExpanded(isExpanded: true),
            ),
          ),
          GoRoute(
            path: '/support-tickets',
            builder: (context, state) {
              lastRoute = '/support-tickets';
              return const Scaffold(body: Text('Support Tickets'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(lastRoute, '/support-tickets');
      expect(find.text('Support Tickets'), findsOneWidget);
    });

    testWidgets('has rounded border radius', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('applies different padding based on expansion state', (tester) async {
      // Test collapsed padding
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      Container container = tester.widget<Container>(
        find.descendant(
          of: find.byType(InkWell),
          matching: find.byType(Container),
        ),
      );
      expect(container.padding, const EdgeInsets.all(8));

      // Test expanded padding
      router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: SupportButtonExpanded(isExpanded: true),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      container = tester.widget<Container>(
        find.descendant(
          of: find.byType(InkWell),
          matching: find.byType(Container),
        ),
      );
      expect(container.padding, const EdgeInsets.all(12));
    });
  });
}
