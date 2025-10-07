import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pm_master_v2/app/router/routes.dart';
import 'package:pm_master_v2/app/router/app_router.dart';

void main() {
  group('AppRouter Navigation', () {
    testWidgets('navigates to dashboard route', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: AppRoutes.dashboardName,
            builder: (context, state) => const Scaffold(
              body: Text('Dashboard'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.go(AppRoutes.dashboard);
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('navigates to documents route', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: AppRoutes.documents,
            name: AppRoutes.documentsName,
            builder: (context, state) => const Scaffold(
              body: Text('Documents'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.go(AppRoutes.documents);
      await tester.pumpAndSettle();

      expect(find.text('Documents'), findsOneWidget);
    });

    testWidgets('navigates to summaries route', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: AppRoutes.summaries,
            name: AppRoutes.summariesName,
            builder: (context, state) => const Scaffold(
              body: Text('Summaries'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.go(AppRoutes.summaries);
      await tester.pumpAndSettle();

      expect(find.text('Summaries'), findsOneWidget);
    });
  });

  group('Route Parameters', () {
    testWidgets('extracts project ID from path parameters', (tester) async {
      String? capturedProjectId;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/hierarchy/project/:id',
            builder: (context, state) {
              capturedProjectId = state.pathParameters['id'];
              return Scaffold(
                body: Text('Project: $capturedProjectId'),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.go('/hierarchy/project/project-123');
      await tester.pumpAndSettle();

      expect(capturedProjectId, 'project-123');
      expect(find.text('Project: project-123'), findsOneWidget);
    });

    testWidgets('extracts summary ID from path parameters', (tester) async {
      String? capturedSummaryId;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/summaries/:id',
            builder: (context, state) {
              capturedSummaryId = state.pathParameters['id'];
              return Scaffold(
                body: Text('Summary: $capturedSummaryId'),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.go('/summaries/summary-456');
      await tester.pumpAndSettle();

      expect(capturedSummaryId, 'summary-456');
      expect(find.text('Summary: summary-456'), findsOneWidget);
    });

    testWidgets('handles UUID path parameters', (tester) async {
      const uuid = '550e8400-e29b-41d4-a716-446655440000';
      String? capturedId;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/documents/:id',
            builder: (context, state) {
              capturedId = state.pathParameters['id'];
              return Scaffold(
                body: Text('Document: $capturedId'),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.go('/documents/$uuid');
      await tester.pumpAndSettle();

      expect(capturedId, uuid);
    });
  });

  group('Query Parameters (Deep Linking)', () {
    testWidgets('extracts single query parameter', (tester) async {
      String? capturedProject;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/risks',
            builder: (context, state) {
              capturedProject = state.uri.queryParameters['project'];
              return Scaffold(
                body: Text('Project: ${capturedProject ?? "none"}'),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.go('/risks?project=project-123');
      await tester.pumpAndSettle();

      expect(capturedProject, 'project-123');
      expect(find.text('Project: project-123'), findsOneWidget);
    });

    testWidgets('extracts multiple query parameters', (tester) async {
      String? capturedFrom;
      String? capturedParentName;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/summaries/:id',
            builder: (context, state) {
              capturedFrom = state.uri.queryParameters['from'];
              capturedParentName = state.uri.queryParameters['parentName'];
              return Scaffold(
                body: Text('From: $capturedFrom, Parent: $capturedParentName'),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.go('/summaries/sum-123?from=dashboard&parentName=TestProject');
      await tester.pumpAndSettle();

      expect(capturedFrom, 'dashboard');
      expect(capturedParentName, 'TestProject');
    });

    testWidgets('handles email query parameter for auth routes', (tester) async {
      String? capturedEmail;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/auth',
            builder: (context, state) => const Scaffold(
              body: Text('Auth'),
            ),
            routes: [
              GoRoute(
                path: 'signup',
                builder: (context, state) {
                  capturedEmail = state.uri.queryParameters['email'];
                  return Scaffold(
                    body: Text('Email: ${capturedEmail ?? "none"}'),
                  );
                },
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.go('/auth/signup?email=test@example.com');
      await tester.pumpAndSettle();

      expect(capturedEmail, 'test@example.com');
    });

    testWidgets('handles query parameters with special characters', (tester) async {
      String? capturedValue;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/test',
            builder: (context, state) {
              capturedValue = state.uri.queryParameters['value'];
              return Scaffold(
                body: Text('Value: ${capturedValue ?? "none"}'),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.go('/test?value=hello%20world');
      await tester.pumpAndSettle();

      expect(capturedValue, 'hello world');
    });
  });

  group('Nested Routes', () {
    testWidgets('navigates to nested profile route', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const Scaffold(
              body: Text('Profile'),
            ),
            routes: [
              GoRoute(
                path: 'change-password',
                builder: (context, state) => const Scaffold(
                  body: Text('Change Password'),
                ),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.go('/profile/change-password');
      await tester.pumpAndSettle();

      expect(find.text('Change Password'), findsOneWidget);
    });

    testWidgets('navigates to nested project route', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/hierarchy/project/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'];
              return Scaffold(body: Text('Project $id'));
            },
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final id = state.pathParameters['id'];
                  return Scaffold(body: Text('Edit Project $id'));
                },
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.go('/hierarchy/project/proj-123/edit');
      await tester.pumpAndSettle();

      expect(find.text('Edit Project proj-123'), findsOneWidget);
    });
  });

  group('Error Handling', () {
    testWidgets('shows error screen for invalid route', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Text('Home'),
            ),
          ),
        ],
        errorBuilder: (context, state) => ErrorScreen(error: state.error),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.go('/nonexistent-route');
      await tester.pumpAndSettle();

      expect(find.byType(ErrorScreen), findsOneWidget);
      expect(find.text('Something went wrong!'), findsOneWidget);
    });

    testWidgets('ErrorScreen is used as error builder', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Text('Home'),
            ),
          ),
        ],
        errorBuilder: (context, state) => ErrorScreen(error: state.error),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Trigger a navigation to an invalid route
      router.go('/this-does-not-exist');
      await tester.pumpAndSettle();

      // ErrorScreen should be displayed
      expect(find.byType(ErrorScreen), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });
  });

  group('Browser Navigation Simulation', () {
    testWidgets('maintains navigation history', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Text('Home'),
            ),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const Scaffold(
              body: Text('Dashboard'),
            ),
          ),
          GoRoute(
            path: '/documents',
            builder: (context, state) => const Scaffold(
              body: Text('Documents'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Start at home
      expect(find.text('Home'), findsOneWidget);

      // Navigate forward using push (adds to history stack)
      router.push('/dashboard');
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsOneWidget);

      router.push('/documents');
      await tester.pumpAndSettle();
      expect(find.text('Documents'), findsOneWidget);

      // Navigate back (simulates browser back button)
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsOneWidget);

      // Navigate back again
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('can navigate using goNamed with route names', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const Scaffold(
              body: Text('Home'),
            ),
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            name: AppRoutes.dashboardName,
            builder: (context, state) => const Scaffold(
              body: Text('Dashboard'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.goNamed(AppRoutes.dashboardName);
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('preserves query parameters during navigation', (tester) async {
      String? lastQueryParam;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/screen1',
            builder: (context, state) {
              lastQueryParam = state.uri.queryParameters['id'];
              return Scaffold(body: Text('Screen1: ${lastQueryParam ?? "none"}'));
            },
          ),
          GoRoute(
            path: '/screen2',
            builder: (context, state) {
              lastQueryParam = state.uri.queryParameters['id'];
              return Scaffold(body: Text('Screen2: ${lastQueryParam ?? "none"}'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.go('/screen1?id=test-123');
      await tester.pumpAndSettle();
      expect(lastQueryParam, 'test-123');

      router.go('/screen2?id=test-456');
      await tester.pumpAndSettle();
      expect(lastQueryParam, 'test-456');
    });
  });
}
