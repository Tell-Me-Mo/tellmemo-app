import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/organization_provider.dart';
import '../../../../core/services/firebase_analytics_service.dart';

class OrganizationWizardScreen extends ConsumerStatefulWidget {
  const OrganizationWizardScreen({super.key});

  @override
  ConsumerState<OrganizationWizardScreen> createState() => _OrganizationWizardScreenState();
}

class _OrganizationWizardScreenState extends ConsumerState<OrganizationWizardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _invitedEmails = [];
  final _emailController = TextEditingController();
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
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _createOrganization() async {
    if (!_formKey.currentState!.validate()) return;

    final memberCount = _invitedEmails.length;
    final hasDescription = _descriptionController.text.trim().isNotEmpty;

    // Log organization creation attempt
    await FirebaseAnalyticsService().logOrgCreationAttempt(
      memberCount: memberCount,
      hasDescription: hasDescription,
    );

    setState(() => _isLoading = true);

    try {
      // Update wizard state
      ref.read(organizationWizardProvider.notifier)
        ..updateName(_nameController.text)
        ..updateDescription(_descriptionController.text);

      // Add invited emails
      for (final email in _invitedEmails) {
        ref.read(organizationWizardProvider.notifier).addInvitedEmail(email);
      }

      // Build and send request
      final request = ref.read(organizationWizardProvider.notifier).buildRequest();
      final orgResponse = await ref
          .read(createOrganizationControllerProvider.notifier)
          .createOrganization(request);

      // Log successful organization creation
      await FirebaseAnalyticsService().logOrgCreationSuccess(
        orgId: orgResponse.id,
        memberCount: memberCount,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create organization: $error'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _addEmail() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty && _isValidEmail(email) && !_invitedEmails.contains(email)) {
      setState(() {
        _invitedEmails.add(email);
        _emailController.clear();
      });

      // Log member invitation
      FirebaseAnalyticsService().logOrgMemberInvited(
        emailCount: _invitedEmails.length,
      );
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
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

                          // Divider before Team Members Section
                          Container(
                            height: 1,
                            color: colorScheme.outline.withValues(alpha: 0.08),
                          ),

                          // Team Members Section
                          _buildSection(
                            context,
                            title: 'Invite Team Members (Optional)',
                            icon: Icons.people_outline,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _emailController,
                                        label: 'Email Address',
                                        hint: 'colleague@example.com',
                                        icon: Icons.email_outlined,
                                        onFieldSubmitted: (_) => _addEmail(),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    FilledButton.tonal(
                                      onPressed: _addEmail,
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 20,
                                        ),
                                      ),
                                      child: const Text('Add'),
                                    ),
                                  ],
                                ),
                                if (_invitedEmails.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: colorScheme.outline.withValues(alpha: 0.08),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: _invitedEmails.map((email) =>
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.person_outline,
                                                size: 16,
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  email,
                                                  style: theme.textTheme.bodyMedium,
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: colorScheme.error,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _invitedEmails.remove(email);
                                                  });
                                                  // Log member removal
                                                  FirebaseAnalyticsService().logOrgMemberRemoved(
                                                    remainingCount: _invitedEmails.length,
                                                  );
                                                },
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ).toList(),
                                    ),
                                  ),
                                ],
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
                                          _descriptionController.text.isNotEmpty ||
                                          _invitedEmails.isNotEmpty;
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