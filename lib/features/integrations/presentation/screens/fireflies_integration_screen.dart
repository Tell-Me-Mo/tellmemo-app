import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/datetime_utils.dart';
import '../../domain/models/integration.dart';
import '../providers/integrations_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../providers/fireflies_provider.dart' as fireflies;

class FirefliesIntegrationScreen extends ConsumerStatefulWidget {
  const FirefliesIntegrationScreen({super.key});

  @override
  ConsumerState<FirefliesIntegrationScreen> createState() =>
      _FirefliesIntegrationScreenState();
}

class _FirefliesIntegrationScreenState
    extends ConsumerState<FirefliesIntegrationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _apiKeyController = TextEditingController();
  final _webhookSecretController = TextEditingController();
  bool _autoSync = true;
  bool _isConnecting = false;
  String? _selectedProject;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiKeyController.dispose();
    _webhookSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final integration = ref.watch(fireflies.firefliesIntegrationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.mic, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Fireflies.ai Integration'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Setup', icon: Icon(Icons.settings)),
            Tab(text: 'Webhook', icon: Icon(Icons.webhook)),
            Tab(text: 'Activity', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: integration.when(
        data: (data) => TabBarView(
          controller: _tabController,
          children: [
            _buildSetupTab(context, theme, isDesktop, data),
            _buildWebhookTab(context, theme, isDesktop, data),
            _buildActivityTab(context, theme, isDesktop, data),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading integration: $error'),
        ),
      ),
    );
  }

  Widget _buildSetupTab(BuildContext context, ThemeData theme, bool isDesktop,
      Integration? integration) {
    final isConnected = integration?.status == IntegrationStatus.connected;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(theme, integration),
              const SizedBox(height: 24),
              _buildConnectionCard(theme, isConnected),
              const SizedBox(height: 24),
              _buildSettingsCard(theme, isConnected),
              const SizedBox(height: 24),
              _buildFeaturesCard(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, Integration? integration) {
    final isConnected = integration?.status == IntegrationStatus.connected;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isConnected ? Colors.green : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConnected ? 'Connected' : 'Not Connected',
                        style: theme.textTheme.headlineSmall,
                      ),
                      if (isConnected && integration?.connectedAt != null)
                        Text(
                          'Connected since ${DateTimeUtils.formatTimeAgo(integration!.connectedAt!)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isConnected)
                  TextButton.icon(
                    onPressed: _handleDisconnect,
                    icon: const Icon(Icons.link_off),
                    label: const Text('Disconnect'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
              ],
            ),
            if (isConnected && integration?.lastSyncAt != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sync, size: 20, 
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                      const SizedBox(width: 8),
                      Text(
                        'Last sync: ${DateTimeUtils.formatTimeAgo(integration!.lastSyncAt!)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _handleSync,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Sync Now'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(ThemeData theme, bool isConnected) {
    if (isConnected) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connect Your Account',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your Fireflies API key',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: _showApiKeyHelp,
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _webhookSecretController,
              decoration: InputDecoration(
                labelText: 'Webhook Secret (Optional)',
                hintText: 'Enter webhook secret for secure callbacks',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isConnecting ? null : _handleConnect,
                icon: _isConnecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link),
                label: Text(_isConnecting ? 'Connecting...' : 'Connect to Fireflies'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(ThemeData theme, bool isConnected) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto-sync transcripts'),
              subtitle: const Text('Automatically import new meeting transcripts'),
              value: _autoSync,
              onChanged: isConnected
                  ? (value) {
                      setState(() {
                        _autoSync = value;
                      });
                      _updateSettings();
                    }
                  : null,
            ),
            const Divider(),
            ListTile(
              title: const Text('Default Project'),
              subtitle: Text(_selectedProject ?? 'All Projects'),
              trailing: const Icon(Icons.arrow_drop_down),
              enabled: isConnected,
              onTap: isConnected ? _selectProject : null,
            ),
            const Divider(),
            ListTile(
              title: const Text('Sync Frequency'),
              subtitle: const Text('Every 30 minutes'),
              trailing: const Icon(Icons.schedule),
              enabled: isConnected,
              onTap: isConnected ? _configureSyncFrequency : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesCard(ThemeData theme) {
    final features = [
      {
        'icon': Icons.mic,
        'title': 'Automatic Transcription',
        'description': 'Transcribe meetings in real-time with high accuracy',
      },
      {
        'icon': Icons.summarize,
        'title': 'Meeting Summaries',
        'description': 'Generate AI-powered summaries and key takeaways',
      },
      {
        'icon': Icons.task_alt,
        'title': 'Action Items',
        'description': 'Extract and track action items from meetings',
      },
      {
        'icon': Icons.search,
        'title': 'Searchable Archive',
        'description': 'Search across all your meeting transcripts',
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Features',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature['title'] as String,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          feature['description'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildWebhookTab(BuildContext context, ThemeData theme, bool isDesktop,
      Integration? integration) {
    final webhookUrl = 'https://api.pmmaster.app/webhooks/fireflies/${integration?.id ?? 'YOUR_INTEGRATION_ID'}';
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Webhook Configuration',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Configure this webhook URL in your Fireflies account to automatically receive meeting transcripts:',
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                webhookUrl,
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: webhookUrl));
                                ref.read(notificationServiceProvider.notifier).showSuccess('Webhook URL copied to clipboard');
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Setup Instructions',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _buildInstructionStep('1', 'Go to your Fireflies dashboard'),
                      _buildInstructionStep('2', 'Navigate to Settings → Integrations'),
                      _buildInstructionStep('3', 'Select "Webhooks" from the list'),
                      _buildInstructionStep('4', 'Click "Add Webhook"'),
                      _buildInstructionStep('5', 'Paste the webhook URL above'),
                      _buildInstructionStep('6', 'Select events to trigger (recommended: "Meeting Completed")'),
                      _buildInstructionStep('7', 'Save the webhook configuration'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Webhook Events',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      DataTable(
                        columns: const [
                          DataColumn(label: Text('Event')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: [
                          DataRow(cells: [
                            const DataCell(Text('Meeting Started')),
                            DataCell(Chip(
                              label: const Text('Disabled'),
                              backgroundColor: Colors.grey.withValues(alpha: 0.2),
                            )),
                            const DataCell(Text('Real-time notifications')),
                          ]),
                          DataRow(cells: [
                            const DataCell(Text('Meeting Completed')),
                            DataCell(Chip(
                              label: const Text('Enabled'),
                              backgroundColor: Colors.green.withValues(alpha: 0.2),
                            )),
                            const DataCell(Text('Import transcript')),
                          ]),
                          DataRow(cells: [
                            const DataCell(Text('Transcript Ready')),
                            DataCell(Chip(
                              label: const Text('Enabled'),
                              backgroundColor: Colors.green.withValues(alpha: 0.2),
                            )),
                            const DataCell(Text('Process content')),
                          ]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTab(BuildContext context, ThemeData theme, bool isDesktop,
      Integration? integration) {
    final activities = ref.watch(fireflies.firefliesActivityProvider);
    
    return activities.when(
      data: (data) {
        if (data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No activity yet',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Activity will appear here once you connect and start syncing',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(isDesktop ? 32 : 16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final activity = data[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: _getActivityIcon(activity['type']),
                title: Text(activity['title']),
                subtitle: Text(activity['description']),
                trailing: Text(
                  DateTimeUtils.formatTimeAgo(activity['timestamp']),
                  style: theme.textTheme.bodySmall,
                ),
                onTap: () => _viewActivityDetails(activity),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading activity: $error'),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _getActivityIcon(String type) {
    switch (type) {
      case 'sync':
        return const Icon(Icons.sync, color: Colors.blue);
      case 'import':
        return const Icon(Icons.download, color: Colors.green);
      case 'error':
        return const Icon(Icons.error, color: Colors.red);
      case 'connect':
        return const Icon(Icons.link, color: Colors.purple);
      default:
        return const Icon(Icons.info, color: Colors.grey);
    }
  }

  void _handleConnect() async {
    if (_apiKeyController.text.isEmpty) {
      ref.read(notificationServiceProvider.notifier).showSuccess('Please enter your API key');
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    try {
      await ref.read(integrationsProvider.notifier).connectIntegration(
        'fireflies',
        {
          'apiKey': _apiKeyController.text,
          'webhookSecret': _webhookSecretController.text,
          'autoSync': _autoSync,
          'selectedProject': _selectedProject,
        },
      );

      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showSuccess('Successfully connected to Fireflies!');
        _apiKeyController.clear();
        _webhookSecretController.clear();
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showInfo('Failed to connect: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  void _handleDisconnect() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Fireflies?'),
        content: const Text(
          'Are you sure you want to disconnect Fireflies? You can reconnect at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(integrationsProvider.notifier).disconnectIntegration('fireflies');
      ref.read(notificationServiceProvider.notifier).showSuccess('Fireflies disconnected');
    }
  }

  void _handleSync() async {
    // TODO: Implement sync functionality
    ref.read(notificationServiceProvider.notifier).showSuccess('Syncing with Fireflies...');
  }

  void _updateSettings() {
    // TODO: Update settings on backend
  }

  void _selectProject() {
    // TODO: Show project selection dialog
  }

  void _configureSyncFrequency() {
    // TODO: Show sync frequency configuration dialog
  }

  void _showApiKeyHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to get your API Key'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Log in to your Fireflies account'),
              SizedBox(height: 8),
              Text('2. Go to Settings → API'),
              SizedBox(height: 8),
              Text('3. Click "Generate API Key"'),
              SizedBox(height: 8),
              Text('4. Copy the key and paste it here'),
              SizedBox(height: 16),
              Text(
                'Note: Keep your API key secure and never share it publicly.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _viewActivityDetails(Map<String, dynamic> activity) {
    // TODO: Navigate to activity details
  }

}