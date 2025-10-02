import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/responsive.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../app/router/routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../organizations/presentation/providers/organization_provider.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is authenticated
    final authState = ref.watch(authControllerProvider);
    final orgState = ref.watch(currentOrganizationProvider);

    // Show loading screen for authenticated users while org state loads
    // This prevents the landing page content from flashing
    if (authState.value != null) {
      // Navigate to dashboard when organization is loaded
      if (orgState.hasValue) {
        // Use addPostFrameCallback to navigate after build is complete
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go(AppRoutes.dashboard);
          }
        });
      }

      // User is authenticated, show loading while waiting for redirect
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
                orgState.isLoading ? 'Loading organization...' : 'Redirecting...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Show regular landing page for unauthenticated users
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            child: _buildCleanWelcomeContent(context, isMobile: true),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      child: Padding(
        padding: const EdgeInsets.all(LayoutConstants.tabletPadding),
        child: _buildCleanWelcomeContent(context, isMobile: false),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: LayoutConstants.desktopPadding),
            child: _buildCleanWelcomeContent(context, isMobile: false, isDesktop: true),
          ),
        ),
      ),
    );
  }

  Widget _buildCleanWelcomeContent(BuildContext context,
      {required bool isMobile, bool isDesktop = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          mainAxisAlignment: isMobile ? MainAxisAlignment.start : MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isMobile) const SizedBox(height: 16),
            // Logo and Branding
            _buildCompactHeroSection(context, isMobile: isMobile),
            SizedBox(height: isMobile ? 16 : 40),

            // Title and Description
            Text(
              'Welcome to TellMeMo',
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: isMobile ? 26 : (isDesktop ? 40 : 32),
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 8 : 12),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 48),
              child: Text(
                'Enterprise Portfolio & Project Intelligence Platform',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: isMobile ? 15 : 18,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: isMobile ? 24 : 48),

            // Action Buttons
            _buildCleanActionButtons(context, isMobile: isMobile),
            SizedBox(height: isMobile ? 24 : 56),

            // Compact Features
            _buildCompactFeatures(context, isMobile: isMobile, isDesktop: isDesktop),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeroSection(BuildContext context, {required bool isMobile}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: isMobile ? 80 : 100,
      height: isMobile ? 80 : 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.account_tree,
        size: isMobile ? 40 : 50,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCleanActionButtons(BuildContext context, {required bool isMobile}) {
    return SizedBox(
      width: isMobile ? double.infinity : null,
      child: FilledButton.icon(
        onPressed: () => context.go(AppRoutes.dashboard),
        icon: const Icon(Icons.rocket_launch, size: 20),
        label: const Text('Go to Dashboard'),
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 28,
            vertical: isMobile ? 14 : 16,
          ),
          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: isMobile ? 15 : 16,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: Size(isMobile ? double.infinity : 200, isMobile ? 48 : 52),
        ),
      ),
    );
  }

  Widget _buildCompactFeatures(BuildContext context,
      {required bool isMobile, required bool isDesktop}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final features = [
      _CompactFeature(
        icon: Icons.account_tree,
        title: 'Portfolio Management',
        description: 'Organize hierarchically',
        color: Colors.blue,
      ),
      _CompactFeature(
        icon: Icons.psychology,
        title: 'AI Meeting Intelligence',
        description: 'Extract insights automatically',
        color: Colors.green,
      ),
      _CompactFeature(
        icon: Icons.auto_awesome,
        title: 'Smart Summaries',
        description: 'Generate reports',
        color: Colors.orange,
      ),
      _CompactFeature(
        icon: Icons.insights,
        title: 'Cross-Project Analytics',
        description: 'Track all progress',
        color: Colors.purple,
      ),
    ];

    if (isMobile) {
      // Mobile: Clean vertical list
      return Column(
        children: [
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.outline.withValues(alpha: 0),
                  colorScheme.outline.withValues(alpha: 0.2),
                  colorScheme.outline.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMobileFeatureCard(context, feature),
          )),
          const SizedBox(height: 8),
        ],
      );
    }

    // Desktop/Tablet: Horizontal row
    return Container(
      constraints: BoxConstraints(maxWidth: isDesktop ? 900 : 700),
      child: Column(
        children: [
          Text(
            'Key Features',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: features
                .map((feature) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _buildCompactFeatureCard(context, feature, isMobile: false),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFeatureCard(BuildContext context, _CompactFeature feature) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              feature.icon,
              color: feature.color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFeatureCard(BuildContext context, _CompactFeature feature,
      {required bool isMobile}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              feature.icon,
              color: feature.color,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            feature.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            feature.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 12,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

}

class _CompactFeature {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _CompactFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}