import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/email_digest_preferences.dart';
import '../providers/email_preferences_provider.dart';
import '../../../../core/services/notification_service.dart';

/// Email Digest Preferences Screen
///
/// Allows users to configure their email digest settings including:
/// - Enable/disable digests
/// - Frequency (daily, weekly, monthly)
/// - Content types to include
/// - Portfolio rollup option
class EmailDigestPreferencesScreen extends ConsumerStatefulWidget {
  const EmailDigestPreferencesScreen({super.key});

  @override
  ConsumerState<EmailDigestPreferencesScreen> createState() =>
      _EmailDigestPreferencesScreenState();
}

class _EmailDigestPreferencesScreenState
    extends ConsumerState<EmailDigestPreferencesScreen> {
  @override
  void initState() {
    super.initState();
    // Load preferences on init
    Future.microtask(() {
      ref.read(emailPreferencesControllerProvider.notifier).loadPreferences();
    });
  }

  Future<void> _saveChanges() async {
    await ref.read(emailPreferencesControllerProvider.notifier).savePreferences();

    final state = ref.read(emailPreferencesControllerProvider);
    if (mounted && state.error == null) {
      ref
          .read(notificationServiceProvider.notifier)
          .showSuccess('Email preferences saved successfully');
    }
  }

  Future<void> _discardChanges() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(emailPreferencesControllerProvider.notifier).discardChanges();
      ref
          .read(notificationServiceProvider.notifier)
          .showInfo('Changes discarded');
    }
  }

  Future<void> _sendTestEmail() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Test Email?'),
        content: const Text(
          'This will send a test digest email to your registered email address.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(sendTestDigestProvider.future);
        if (mounted) {
          ref
              .read(notificationServiceProvider.notifier)
              .showSuccess('Test email queued successfully!');
        }
      } catch (e) {
        if (mounted) {
          ref
              .read(notificationServiceProvider.notifier)
              .showError('Failed to send test email: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(emailPreferencesControllerProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isMobile = screenWidth <= 768;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.02),
                  colorScheme.secondary.withValues(alpha: 0.01),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 16,
                  vertical: isMobile ? 12 : 16,
                ),
                child: _buildHeader(context, state),
              ),
            ),
          ),

          // Content
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? _buildErrorState(state.error!)
                    : state.preferences == null
                        ? const Center(child: Text('No preferences available'))
                        : _buildContent(context, state.preferences!),
          ),
        ],
      ),
      floatingActionButton: isMobile && state.hasUnsavedChanges
          ? FloatingActionButton.extended(
              onPressed: _saveChanges,
              backgroundColor: theme.colorScheme.primary,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context, EmailPreferencesState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isMobile = screenWidth <= 768;

    if (isMobile) {
      return Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.email_outlined,
            color: colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email Digest',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                'Preferences',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Back to Profile',
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.email_outlined,
          color: colorScheme.primary,
          size: 28,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email Digest Preferences',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Configure your automated email digest settings',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (isDesktop) ...[
          if (state.hasUnsavedChanges) ...[
            OutlinedButton(
              onPressed: _discardChanges,
              child: const Text('Discard'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Save Changes'),
            ),
          ] else ...[
            OutlinedButton.icon(
              onPressed: _sendTestEmail,
              icon: const Icon(Icons.send_outlined, size: 16),
              label: const Text('Send Test Email'),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading preferences',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref
                    .read(emailPreferencesControllerProvider.notifier)
                    .loadPreferences();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, EmailDigestPreferences prefs) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(emailPreferencesControllerProvider.notifier)
            .loadPreferences();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEnableSection(context, prefs),
                const SizedBox(height: 24),
                if (prefs.enabled) ...[
                  _buildFrequencySection(context, prefs),
                  const SizedBox(height: 24),
                  _buildContentTypesSection(context, prefs),
                  const SizedBox(height: 24),
                  _buildAdditionalOptionsSection(context, prefs),
                  const SizedBox(height: 24),
                  _buildInfoSection(context, prefs),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnableSection(
      BuildContext context, EmailDigestPreferences prefs) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            prefs.enabled ? Icons.notifications_active : Icons.notifications_off,
            color: prefs.enabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email Digest',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prefs.enabled
                      ? 'Receive automated digest emails with project updates'
                      : 'Email digests are currently disabled',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: prefs.enabled,
            onChanged: (_) {
              ref
                  .read(emailPreferencesControllerProvider.notifier)
                  .toggleEnabled();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencySection(
      BuildContext context, EmailDigestPreferences prefs) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 18,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Frequency',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...DigestFrequency.all
              .where((freq) => freq != DigestFrequency.never)
              .map((frequency) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RadioListTile<String>(
                      value: frequency,
                      groupValue: prefs.frequency,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(emailPreferencesControllerProvider.notifier)
                              .updateFrequency(value);
                        }
                      },
                      title: Text(DigestFrequency.displayName(frequency)),
                      subtitle: Text(
                        DigestFrequency.description(frequency),
                        style: theme.textTheme.bodySmall,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildContentTypesSection(
      BuildContext context, EmailDigestPreferences prefs) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.checklist,
                size: 18,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Content to Include',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Choose what information to include in your digest',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ...DigestContentType.all.map((contentType) => CheckboxListTile(
                value: prefs.contentTypes.contains(contentType),
                onChanged: (_) {
                  ref
                      .read(emailPreferencesControllerProvider.notifier)
                      .toggleContentType(contentType);
                },
                title: Text(DigestContentType.displayName(contentType)),
                subtitle: Text(
                  DigestContentType.description(contentType),
                  style: theme.textTheme.bodySmall,
                ),
                contentPadding: EdgeInsets.zero,
              )),
        ],
      ),
    );
  }

  Widget _buildAdditionalOptionsSection(
      BuildContext context, EmailDigestPreferences prefs) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings_outlined,
                size: 18,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Additional Options',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: prefs.includePortfolioRollup,
            onChanged: (_) {
              ref
                  .read(emailPreferencesControllerProvider.notifier)
                  .togglePortfolioRollup();
            },
            title: const Text('Include Portfolio Rollup'),
            subtitle: Text(
              'Show summary statistics across all projects and portfolios',
              style: theme.textTheme.bodySmall,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, EmailDigestPreferences prefs) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Email Digests',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Email digests are sent automatically based on your schedule. You can unsubscribe at any time using the link in any digest email.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                if (prefs.lastSentAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Last sent: ${prefs.lastSentAt}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
