import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/organization_provider.dart';
import '../../../../core/services/firebase_analytics_service.dart';
import '../../../../core/services/notification_service.dart';

class OrganizationWizardScreen extends ConsumerStatefulWidget {
  const OrganizationWizardScreen({super.key});

  @override
  ConsumerState<OrganizationWizardScreen> createState() => _OrganizationWizardScreenState();
}

class _OrganizationWizardScreenState extends ConsumerState<OrganizationWizardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final wizardState = ref.read(organizationWizardProvider);
    _nameController.text = wizardState.name ?? '';
    _descriptionController.text = wizardState.description ?? '';

    // Log organization creation flow start
    FirebaseAnalyticsService().logOrgCreationScreenViewed(trigger: 'signup_no_org');
    FirebaseAnalyticsService().logOrgCreationStarted();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createOrganization() async {
    if (!_formKey.currentState!.validate()) return;

    final hasDescription = _descriptionController.text.trim().isNotEmpty;

    // Log organization creation attempt
    await FirebaseAnalyticsService().logOrgCreationAttempt(
      memberCount: 0,
      hasDescription: hasDescription,
    );

    setState(() => _isLoading = true);

    try {
      // Update wizard state
      ref.read(organizationWizardProvider.notifier)
        ..updateName(_nameController.text)
        ..updateDescription(_descriptionController.text);

      // Build and send request
      final request = ref.read(organizationWizardProvider.notifier).buildRequest();
      final orgResponse = await ref
          .read(createOrganizationControllerProvider.notifier)
          .createOrganization(request);

      // Log successful organization creation
      await FirebaseAnalyticsService().logOrgCreationSuccess(
        orgId: orgResponse.id,
        memberCount: 0,
        hasDescription: hasDescription,
      );

      if (mounted) {
        // Navigate directly to dashboard without showing snackbar
        context.go('/dashboard');
      }
    } catch (error) {
      // Log organization creation failure
      await FirebaseAnalyticsService().logOrgCreationFailed(
        error: error.toString(),
      );

      setState(() => _isLoading = false);
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Failed to create organization: $error');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768;
    final isMobile = screenWidth <= 768;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32 : 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 800 : (isTablet ? 600 : double.infinity),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(context),
                    const SizedBox(height: 32),

                    // Main Content Card
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Organization Info Section
                          _buildSection(
                            context,
                            title: 'Organization Details',
                            icon: Icons.business_outlined,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTextField(
                                  controller: _nameController,
                                  label: 'Organization Name',
                                  hint: 'Enter your organization name',
                                  icon: Icons.business,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Organization name is required';
                                    }
                                    if (value.trim().length < 2) {
                                      return 'Name must be at least 2 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  controller: _descriptionController,
                                  label: 'Description (Optional)',
                                  hint: 'Briefly describe your organization',
                                  icon: Icons.description_outlined,
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isLoading ? null : () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                title: const Text('Cancel Setup?'),
                                content: const Text(
                                  'Your progress will be lost. Are you sure you want to cancel?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Continue Setup'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Log cancellation
                                      final hadProgress = _nameController.text.isNotEmpty ||
                                          _descriptionController.text.isNotEmpty;
                                      FirebaseAnalyticsService().logOrgCreationCancelled(
                                        hadProgress: hadProgress,
                                      );

                                      Navigator.pop(context);
                                      context.go('/auth/signin');
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: colorScheme.error,
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _isLoading ? null : _createOrganization,
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 24 : 32,
                              vertical: 12,
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Create Organization'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.1),
                    colorScheme.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                Icons.business,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Organization',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set up your workspace in just a few steps',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.error.withValues(alpha: 0.5),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      style: theme.textTheme.bodyMedium,
    );
  }

}