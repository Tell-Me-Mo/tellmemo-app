import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/live_insights_settings.dart';
import '../providers/live_insights_settings_provider.dart';

/// Dialog for configuring Live Insights and Proactive Assistance settings
class LiveInsightsSettingsDialog extends ConsumerWidget {
  const LiveInsightsSettingsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(liveInsightsSettingsSyncProvider);
    final notifierAsync = ref.watch(liveInsightsSettingsNotifierAsyncProvider);

    // If notifier is not yet loaded, show loading state
    if (!notifierAsync.hasValue) {
      return const Dialog(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(48.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final notifier = notifierAsync.value!;

    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context, notifier),

            const Divider(height: 1),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick toggles
                    _buildQuickToggles(settings, notifier),

                    const SizedBox(height: 32),

                    // Phase toggles
                    _buildPhaseToggles(settings, notifier),

                    const SizedBox(height: 24),

                    // Bulk actions
                    _buildBulkActions(notifier),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // Footer
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LiveInsightsSettingsNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const Icon(Icons.settings, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Insights Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Customize which AI assistance features you want to see',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => notifier.resetToDefaults(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reset to Defaults'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickToggles(LiveInsightsSettings settings, LiveInsightsSettingsNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Quiet Mode
        SwitchListTile(
          value: settings.quietMode,
          onChanged: (_) => notifier.toggleQuietMode(),
          title: const Row(
            children: [
              Icon(Icons.volume_off, size: 20),
              SizedBox(width: 8),
              Text('Quiet Mode'),
            ],
          ),
          subtitle: const Text(
            'Only show critical alerts (conflicts and action item quality)',
            style: TextStyle(fontSize: 12),
          ),
          contentPadding: EdgeInsets.zero,
        ),

        const Divider(),

        // Show Collapsed Items
        SwitchListTile(
          value: settings.showCollapsedItems,
          onChanged: (_) => notifier.toggleShowCollapsedItems(),
          title: const Row(
            children: [
              Icon(Icons.expand_more, size: 20),
              SizedBox(width: 8),
              Text('Show Medium Confidence Items'),
            ],
          ),
          subtitle: const Text(
            'Display items with medium confidence in collapsed state',
            style: TextStyle(fontSize: 12),
          ),
          contentPadding: EdgeInsets.zero,
        ),

        const Divider(),

        // Auto-expand high confidence
        SwitchListTile(
          value: settings.autoExpandHighConfidence,
          onChanged: (_) => notifier.toggleAutoExpandHighConfidence(),
          title: const Row(
            children: [
              Icon(Icons.unfold_more, size: 20),
              SizedBox(width: 8),
              Text('Auto-Expand High Confidence'),
            ],
          ),
          subtitle: const Text(
            'Automatically expand items with high confidence scores',
            style: TextStyle(fontSize: 12),
          ),
          contentPadding: EdgeInsets.zero,
        ),

        const Divider(),

        // Enable Feedback
        SwitchListTile(
          value: settings.enableFeedback,
          onChanged: (_) => notifier.toggleEnableFeedback(),
          title: const Row(
            children: [
              Icon(Icons.thumb_up_outlined, size: 20),
              SizedBox(width: 8),
              Text('Enable Feedback Collection'),
            ],
          ),
          subtitle: const Text(
            'Show thumbs up/down buttons to help improve AI accuracy',
            style: TextStyle(fontSize: 12),
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildPhaseToggles(LiveInsightsSettings settings, LiveInsightsSettingsNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Assistance Features',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose which AI features to enable during meetings',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        ...LiveInsightsSettings.allPhases.map((phase) {
          final isEnabled = settings.enabledPhases.contains(phase);
          final priority = LiveInsightsSettings.getPriorityForType(phase);
          final label = LiveInsightsSettings.getLabelForType(phase);
          final description = LiveInsightsSettings.getDescriptionForType(phase);
          final icon = LiveInsightsSettings.getIconForType(phase);

          return Column(
            children: [
              CheckboxListTile(
                value: isEnabled,
                onChanged: (_) => notifier.togglePhase(phase),
                title: Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(label)),
                    _buildPriorityBadge(priority),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(left: 28, top: 4),
                  child: Text(
                    description,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const Divider(height: 1),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPriorityBadge(AssistancePriority priority) {
    final color = switch (priority) {
      AssistancePriority.critical => Colors.red,
      AssistancePriority.important => Colors.orange,
      AssistancePriority.informational => Colors.blue,
    };

    final label = switch (priority) {
      AssistancePriority.critical => 'Critical',
      AssistancePriority.important => 'Important',
      AssistancePriority.informational => 'Info',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBulkActions(LiveInsightsSettingsNotifier notifier) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => notifier.enableAllPhases(),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Enable All'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => notifier.disableAllPhases(),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Disable All'),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Button to open settings dialog
class LiveInsightsSettingsButton extends StatelessWidget {
  const LiveInsightsSettingsButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.tune),
      tooltip: 'Live Insights Settings',
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const LiveInsightsSettingsDialog(),
        );
      },
    );
  }
}
