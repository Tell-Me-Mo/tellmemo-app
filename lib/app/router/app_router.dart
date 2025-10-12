import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes.dart';
import 'responsive_shell.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../core/services/firebase_analytics_service.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen_v2.dart';
import '../../features/documents/presentation/screens/documents_screen.dart';
import '../../features/summaries/presentation/screens/summaries_screen.dart';
import '../../features/summaries/presentation/screens/summary_detail_screen.dart';
import '../../features/landing/presentation/screens/landing_screen.dart';
import '../../features/projects/presentation/screens/simplified_project_details_screen.dart';
import '../../features/integrations/presentation/screens/integrations_screen.dart';
import '../../features/integrations/presentation/screens/fireflies_integration_screen.dart';
import '../../features/hierarchy/presentation/screens/hierarchy_screen.dart';
import '../../features/hierarchy/presentation/screens/portfolio_detail_screen.dart';
import '../../features/hierarchy/presentation/screens/program_detail_screen.dart';
import '../../features/auth/presentation/screens/signin_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/password_reset_screen.dart';
import '../../features/organizations/presentation/screens/organization_wizard_screen.dart';
import '../../features/organizations/presentation/screens/organization_settings_screen.dart';
import '../../features/organizations/presentation/screens/member_management_screen.dart';
import '../../features/profile/presentation/screens/user_profile_screen.dart';
import '../../features/profile/presentation/screens/change_password_screen.dart';
import '../../features/email_preferences/presentation/screens/email_digest_preferences_screen.dart';
import '../../features/risks/presentation/screens/risks_aggregation_screen_v2.dart';
import '../../features/tasks/presentation/screens/tasks_screen_v2.dart';
import '../../features/lessons_learned/presentation/screens/lessons_learned_screen_v2.dart';
import '../../features/support_tickets/presentation/screens/support_tickets_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter goRouter(Ref ref) {
  // Only add Firebase Analytics observer if initialized
  final analyticsService = FirebaseAnalyticsService();
  final observers = <NavigatorObserver>[];
  if (analyticsService.isInitialized && analyticsService.observer != null) {
    observers.add(analyticsService.observer!);
  }

  return GoRouter(
    initialLocation: AppRoutes.landing,
    debugLogDiagnostics: true,
    observers: observers,
    redirect: (context, state) {
      // Simple redirect logic without complex state management
      final authState = ref.read(authControllerProvider);
      final isAuthenticated = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isLandingRoute = state.matchedLocation == '/';

      // If not authenticated and trying to access protected routes
      if (!isAuthenticated && !isAuthRoute && !isLandingRoute && !state.matchedLocation.startsWith('/organization/create')) {
        return '/auth/signin';
      }

      // If authenticated and on auth/landing routes, let them stay there
      // The screens will handle their own navigation after loading data

      return null;
    },
    routes: [
      // Landing page (outside shell)
      GoRoute(
        path: AppRoutes.landing,
        name: AppRoutes.landingName,
        builder: (context, state) => const LandingScreen(),
      ),

      // Organization creation wizard (outside shell - needs to be accessible without org context)
      GoRoute(
        path: '/organization/create',
        name: 'organization-create',
        builder: (context, state) => const OrganizationWizardScreen(),
      ),

      // Auth routes (outside shell)
      GoRoute(
        path: '/auth',
        redirect: (context, state) {
          // Only redirect the base /auth path, not sub-routes
          if (state.uri.path == '/auth') {
            return '/auth/signin';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: 'signin',
            name: 'signin',
            builder: (context, state) => const SignInScreen(),
          ),
          GoRoute(
            path: 'signup',
            name: 'signup',
            builder: (context, state) {
              final email = state.uri.queryParameters['email'];
              return SignUpScreen(initialEmail: email);
            },
          ),
          GoRoute(
            path: 'forgot-password',
            name: 'forgot-password',
            builder: (context, state) {
              final email = state.uri.queryParameters['email'];
              return ForgotPasswordScreen(initialEmail: email);
            },
          ),
          GoRoute(
            path: 'reset-password',
            name: 'reset-password',
            builder: (context, state) {
              final token = state.uri.queryParameters['token'];
              return PasswordResetScreen(token: token);
            },
          ),
        ],
      ),

      // Shell route that wraps main screens with navigation
      ShellRoute(
        builder: (context, state, child) => ResponsiveShell(child: child),
        routes: [
          // Dashboard
          GoRoute(
            path: AppRoutes.dashboard,
            name: AppRoutes.dashboardName,
            builder: (context, state) => const DashboardScreenV2(),
          ),

          // Hierarchy
          GoRoute(
            path: '/hierarchy',
            name: 'hierarchy',
            builder: (context, state) => const HierarchyScreen(),
            routes: [
              // Portfolio detail
              GoRoute(
                path: 'portfolio/:id',
                name: 'portfolio-detail',
                builder: (context, state) {
                  final portfolioId = state.pathParameters['id']!;
                  return PortfolioDetailScreen(portfolioId: portfolioId);
                },
              ),
              // Program detail
              GoRoute(
                path: 'program/:id',
                name: 'program-detail',
                builder: (context, state) {
                  final programId = state.pathParameters['id']!;
                  return ProgramDetailScreen(programId: programId);
                },
              ),
              // Project detail (moved from /projects)
              GoRoute(
                path: 'project/:id',
                name: AppRoutes.projectDetailName,
                builder: (context, state) {
                  final projectId = state.pathParameters['id']!;
                  return SimplifiedProjectDetailsScreen(projectId: projectId);
                },
                routes: [
                  // Edit project
                  GoRoute(
                    path: 'edit',
                    name: AppRoutes.editProjectName,
                    builder: (context, state) {
                      final projectId = state.pathParameters['id']!;
                      return EditProjectPlaceholder(projectId: projectId);
                    },
                  ),
                  // Project summaries
                  GoRoute(
                    path: 'summaries',
                    name: AppRoutes.projectSummariesName,
                    builder: (context, state) {
                      // Now redirects to main summaries with project filter
                      // The summaries screen handles project filtering internally
                      return const SummariesScreen();
                    },
                  ),
                ],
              ),
            ],
          ),

          // Projects - Redirect to hierarchy
          GoRoute(
            path: AppRoutes.projects,
            name: AppRoutes.projectsName,
            redirect: (context, state) {
              // Check if there's a project ID in the path
              final segments = state.uri.pathSegments;
              if (segments.length >= 2 && segments[0] == 'projects') {
                final projectId = segments[1];
                // Redirect to the new hierarchy/project route
                if (segments.length == 2) {
                  return '/hierarchy/project/$projectId';
                } else if (segments.length > 2) {
                  // Handle sub-routes like edit, upload, query, summaries
                  final subRoute = segments.sublist(2).join('/');
                  return '/hierarchy/project/$projectId/$subRoute';
                }
              }
              // Default redirect to hierarchy
              return '/hierarchy';
            },
          ),

          // Documents
          GoRoute(
            path: AppRoutes.documents,
            name: AppRoutes.documentsName,
            builder: (context, state) => const DocumentsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: AppRoutes.documentDetailName,
                builder: (context, state) {
                  final documentId = state.pathParameters['id']!;
                  return DocumentDetailPlaceholder(documentId: documentId);
                },
              ),
            ],
          ),

          // Summaries
          GoRoute(
            path: AppRoutes.summaries,
            name: AppRoutes.summariesName,
            builder: (context, state) => const SummariesScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: AppRoutes.summaryDetailName,
                builder: (context, state) {
                  final summaryId = state.pathParameters['id']!;
                  // Get navigation context from query parameters if available
                  final fromRoute = state.uri.queryParameters['from'];
                  final parentName = state.uri.queryParameters['parentName'];

                  return SummaryDetailScreen(
                    summaryId: summaryId,
                    fromRoute: fromRoute,
                    parentEntityName: parentName,
                  );
                },
              ),
            ],
          ),

          // Risks - Main risk management route
          GoRoute(
            path: '/risks',
            name: 'risks',
            builder: (context, state) {
              final projectId = state.uri.queryParameters['project'];
              final from = state.uri.queryParameters['from'];
              return RisksAggregationScreenV2(
                projectId: projectId,
                fromRoute: from,
              );
            },
          ),

          // Tasks - Aggregated tasks from all projects
          GoRoute(
            path: '/tasks',
            name: 'tasks',
            builder: (context, state) {
              final projectId = state.uri.queryParameters['project'];
              final from = state.uri.queryParameters['from'];
              return TasksScreenV2(
                projectId: projectId,
                fromRoute: from,
              );
            },
          ),

          // Lessons Learned - Aggregated lessons from all projects
          GoRoute(
            path: '/lessons',
            name: 'lessons',
            builder: (context, state) {
              final projectId = state.uri.queryParameters['project'];
              final from = state.uri.queryParameters['from'];
              return LessonsLearnedScreenV2(
                projectId: projectId,
                fromRoute: from,
              );
            },
          ),

          // Support Tickets
          GoRoute(
            path: '/support-tickets',
            name: 'support-tickets',
            builder: (context, state) => const SupportTicketsScreen(),
          ),

          // Integrations
          GoRoute(
            path: AppRoutes.integrations,
            name: AppRoutes.integrationsName,
            builder: (context, state) => const IntegrationsScreen(),
            routes: [
              GoRoute(
                path: 'risks',
                name: 'risks-aggregation',
                builder: (context, state) => const RisksAggregationScreenV2(),
              ),
              GoRoute(
                path: 'fireflies',
                name: 'fireflies-integration',
                builder: (context, state) => const FirefliesIntegrationScreen(),
              ),
              GoRoute(
                path: ':id',
                name: AppRoutes.integrationDetailName,
                builder: (context, state) {
                  final integrationId = state.pathParameters['id']!;
                  return IntegrationDetailPlaceholder(integrationId: integrationId);
                },
              ),
            ],
          ),

          // Profile Management
          GoRoute(
            path: AppRoutes.profile,
            name: AppRoutes.profileName,
            builder: (context, state) => const UserProfileScreen(),
            routes: [
              GoRoute(
                path: 'change-password',
                name: AppRoutes.changePasswordName,
                builder: (context, state) => const ChangePasswordScreen(),
              ),
              GoRoute(
                path: 'email-preferences',
                name: AppRoutes.emailPreferencesName,
                builder: (context, state) => const EmailDigestPreferencesScreen(),
              ),
            ],
          ),

          // Organization Management (inside shell for proper protection)
          GoRoute(
            path: '/organization/settings',
            name: 'organization-settings',
            builder: (context, state) => const OrganizationSettingsScreen(),
          ),

          GoRoute(
            path: '/organization/members',
            name: 'organization-members',
            builder: (context, state) => const MemberManagementScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
}

// Placeholder screens for routes (to be implemented later)
class EditProjectPlaceholder extends StatelessWidget {
  final String projectId;

  const EditProjectPlaceholder({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Project $projectId')),
      body: Center(
        child: Text('Edit Project for ID: $projectId'),
      ),
    );
  }
}

class CreateProjectPlaceholder extends StatelessWidget {
  const CreateProjectPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Project')),
      body: const Center(
        child: Text('Create New Project Form'),
      ),
    );
  }
}

class DocumentDetailPlaceholder extends StatelessWidget {
  final String documentId;

  const DocumentDetailPlaceholder({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Document $documentId')),
      body: Center(
        child: Text('Document Detail for ID: $documentId'),
      ),
    );
  }
}

class IntegrationDetailPlaceholder extends StatelessWidget {
  final String integrationId;

  const IntegrationDetailPlaceholder({super.key, required this.integrationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Integration $integrationId')),
      body: Center(
        child: Text('Integration Detail for ID: $integrationId'),
      ),
    );
  }
}


class ErrorScreen extends StatelessWidget {
  final Exception? error;

  const ErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Something went wrong!'),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}