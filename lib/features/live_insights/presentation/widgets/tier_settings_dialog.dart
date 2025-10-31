import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/tier_settings.dart';
import '../providers/tier_settings_provider.dart';

/// Dialog for configuring answer discovery tiers
class TierSettingsDialog extends ConsumerWidget {
  const TierSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settingsAsync = ref.watch(tierSettingsNotifierProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Settings',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configure which tiers are used and which sections to display',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Settings content
            Flexible(
              child: settingsAsync.when(
                data: (settings) => _buildSettingsContent(
                  context,
                  ref,
                  settings,
                  theme,
                  colorScheme,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error loading settings: $error'),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Footer actions
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    WidgetRef ref,
    TierSettings settings,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Visibility Settings
          Text(
            'Display Sections',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingTile(
            icon: Icons.help_outline,
            title: 'Questions',
            description: 'Show detected questions and their answers',
            enabled: settings.showQuestionsSection,
            onToggle: (value) => ref.read(tierSettingsNotifierProvider.notifier).updateSettings(
              settings.copyWith(showQuestionsSection: value),
            ),
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          _buildSettingTile(
            icon: Icons.task_alt,
            title: 'Action Items',
            description: 'Show tracked action items and commitments',
            enabled: settings.showActionsSection,
            onToggle: (value) => ref.read(tierSettingsNotifierProvider.notifier).updateSettings(
              settings.copyWith(showActionsSection: value),
            ),
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 24),

          // Divider
          Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 24),

          // Answer Discovery Tiers
          Text(
            'Answer Discovery Tiers',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingTile(
            icon: Icons.search,
            title: 'Tier 1: Document Search (RAG)',
            description: 'Search through uploaded documents and meeting transcripts',
            enabled: settings.ragEnabled,
            onToggle: (value) => ref.read(tierSettingsNotifierProvider.notifier).toggleTier(AnswerTier.rag, value),
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          _buildSettingTile(
            icon: Icons.history,
            title: 'Tier 2: Meeting Context',
            description: 'Look for answers earlier in the current meeting',
            enabled: settings.meetingContextEnabled,
            onToggle: (value) => ref.read(tierSettingsNotifierProvider.notifier).toggleTier(AnswerTier.meetingContext, value),
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          _buildSettingTile(
            icon: Icons.auto_awesome,
            title: 'Tier 3: AI-Generated',
            description: 'Generate answers using AI when not found elsewhere',
            enabled: settings.gptGeneratedEnabled,
            onToggle: (value) => ref.read(tierSettingsNotifierProvider.notifier).toggleTier(AnswerTier.gptGenerated, value),
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          _buildSettingTile(
            icon: Icons.hearing,
            title: 'Tier 4: Live Monitoring',
            description: 'Monitor live conversation for answers',
            enabled: settings.liveConversationEnabled,
            onToggle: (value) => ref.read(tierSettingsNotifierProvider.notifier).toggleTier(AnswerTier.liveConversation, value),
            theme: theme,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  /// Unified setting tile with consistent design
  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String description,
    required bool enabled,
    required void Function(bool) onToggle,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onToggle(!enabled),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Icon(
                  icon,
                  color: enabled
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 24,
                ),
                const SizedBox(width: 16),
                // Setting info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Toggle switch
                Switch(
                  value: enabled,
                  onChanged: onToggle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
