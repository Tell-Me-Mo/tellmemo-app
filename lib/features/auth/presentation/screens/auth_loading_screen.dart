import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../organizations/presentation/providers/organization_provider.dart';

/// A loading screen that shows while determining authentication and organization status
/// This prevents screen flashing during initial auth check
class AuthLoadingScreen extends ConsumerStatefulWidget {
  const AuthLoadingScreen({super.key});

  @override
  ConsumerState<AuthLoadingScreen> createState() => _AuthLoadingScreenState();
}

class _AuthLoadingScreenState extends ConsumerState<AuthLoadingScreen> {
  bool _hasNavigated = false;

  @override
  Widget build(BuildContext context) {
    // Watch auth and org state to trigger rebuilds
    ref.watch(authControllerProvider);
    ref.watch(currentOrganizationProvider);

    // Handle navigation based on auth and org state
    ref.listen(authControllerProvider, (previous, next) {
      _handleNavigation();
    });

    ref.listen(currentOrganizationProvider, (previous, next) {
      _handleNavigation();
    });

    // Try to navigate immediately if states are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNavigation();
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.dashboard_rounded,
                size: 64,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 32),
            // Loading indicator
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'TellMeMo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation() {
    // Prevent multiple navigations
    if (_hasNavigated || !mounted) return;

    final authState = ref.read(authControllerProvider);
    final orgState = ref.read(currentOrganizationProvider);

    // If auth is still loading, wait
    if (authState.isLoading) return;

    // User is not authenticated - go to sign in
    if (authState.value == null) {
      _hasNavigated = true;
      context.go('/auth/signin');
      return;
    }

    // User is authenticated, but org is still loading - wait
    if (orgState.isLoading) return;

    // User is authenticated but has no organization - go to org creation
    if (orgState.value == null && !orgState.hasError) {
      _hasNavigated = true;
      context.go('/organization/create');
      return;
    }

    // User is authenticated and has organization (or org errored) - go to dashboard
    _hasNavigated = true;
    context.go('/dashboard');
  }
}