import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/integration.dart';
import '../providers/integrations_provider.dart';
import 'transcription_connection_dialog.dart';
import 'ai_brain_config_dialog.dart';
import 'fireflies_config_dialog.dart';
import '../../../../core/services/notification_service.dart';

class IntegrationConfigDialog extends ConsumerStatefulWidget {
  final Integration integration;
  
  const IntegrationConfigDialog({
    super.key,
    required this.integration,
  });

  static Future<void> show(BuildContext context, Integration integration) {
    // Use custom dialog for AI Brain integration
    if (integration.type == IntegrationType.aiBrain) {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AIBrainConfigDialog(),
      );
    }

    // Use custom dialog for Fireflies integration
    if (integration.type == IntegrationType.fireflies) {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => FirefliesConfigDialog(integration: integration),
      );
    }

    // Use custom dialog for transcription integration
    if (integration.type == IntegrationType.transcription) {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => TranscriptionConnectionDialog(integration: integration),
      );
    }

    // Default handling for other integrations
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      // For mobile, use full screen route
      return Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => IntegrationConfigDialog(integration: integration),
        ),
      );
    } else {
      // For desktop and tablet, use dialog
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => IntegrationConfigDialog(integration: integration),
      );
    }
  }

  @override
  ConsumerState<IntegrationConfigDialog> createState() => _IntegrationConfigDialogState();
}

class _IntegrationConfigDialogState extends ConsumerState<IntegrationConfigDialog> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;
  bool _autoRecordMeetings = true;
  bool _transcribeMeetings = true;
  bool _showApiKey = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load existing configuration
    if (widget.integration.configuration != null) {
      _apiKeyController.text = widget.integration.configuration!['apiKey'] ?? '';
      _autoRecordMeetings = widget.integration.configuration!['autoRecord'] ?? true;
      _transcribeMeetings = widget.integration.configuration!['transcribe'] ?? true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    
    // Responsive sizing based on screen size
    final isDesktop = screenSize.width >= 1200;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    final isMobile = screenSize.width < 600;
    
    // Adaptive dialog dimensions
    late double dialogWidth;
    late double dialogHeight;
    late double maxHeight;
    
    if (isDesktop) {
      dialogWidth = 720;
      dialogHeight = screenSize.height * 0.75;
      maxHeight = 600;
    } else if (isTablet) {
      dialogWidth = screenSize.width * 0.85;
      dialogHeight = screenSize.height * 0.8;
      maxHeight = 550;
    } else {
      // Mobile - full screen dialog
      dialogWidth = screenSize.width;
      dialogHeight = screenSize.height;
      maxHeight = screenSize.height;
    }
    
    // For mobile, use full screen dialog
    if (isMobile) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(theme, isMobile: true),
              if (widget.integration.status != IntegrationStatus.connected)
                _buildTabBar(theme, isMobile: true),
              Expanded(
                child: widget.integration.status != IntegrationStatus.connected
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSetupTab(theme, isMobile: true),
                        _buildActivityTab(theme, isMobile: true),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildSetupTab(theme, isMobile: true),
                          _buildActivityTab(theme, isMobile: true),
                        ],
                      ),
                    ),
              ),
              _buildFooter(theme, isMobile: true),
            ],
          ),
        ),
      );
    }
    
    // Desktop and Tablet dialog
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: maxHeight,
          minHeight: 400,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            _buildHeader(theme),
            if (widget.integration.status != IntegrationStatus.connected)
              _buildTabBar(theme),
            Expanded(
              child: widget.integration.status != IntegrationStatus.connected
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSetupTab(theme),
                      _buildActivityTab(theme),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildSetupTab(theme),
                        _buildActivityTab(theme),
                      ],
                    ),
                  ),
            ),
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, {bool isMobile = false}) {
    final isConnected = widget.integration.status == IntegrationStatus.connected;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: isMobile ? BorderRadius.zero : const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange.withValues(alpha: 0.2),
                      Colors.deepOrange.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.mic,
                  size: isMobile ? 28 : 32,
                  color: Colors.orange,
                ),
              ),
              SizedBox(width: isMobile ? 16 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.integration.name,
                      style: (isMobile ? theme.textTheme.headlineSmall : theme.textTheme.headlineMedium)?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.integration.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
              ),
            ],
          ),
          if (isConnected) ...[
            const SizedBox(height: 20),
            _buildConnectionStatus(theme, isMobile),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(ThemeData theme, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 20,
        vertical: isMobile ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Connected',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '• Your Fireflies integration is active',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, {bool isMobile = false}) {
    return Container(
      height: isMobile ? 48 : 56,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(
            icon: Icon(Icons.settings_outlined, size: isMobile ? 18 : 20),
            text: 'Setup',
            iconMargin: const EdgeInsets.only(bottom: 4),
          ),
          Tab(
            icon: Icon(Icons.history_outlined, size: isMobile ? 18 : 20),
            text: 'Activity',
            iconMargin: const EdgeInsets.only(bottom: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupTab(ThemeData theme, {bool isMobile = false}) {
    final isConnected = widget.integration.status == IntegrationStatus.connected;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isConnected) ...[
            _buildConnectionBanner(theme, isMobile),
            SizedBox(height: isMobile ? 24 : 32),
          ],
          
          Text(
            'API Configuration',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: TextFormField(
              controller: _apiKeyController,
              obscureText: !_showApiKey,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your Fireflies API key',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: Icon(
                  Icons.key_outlined,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showApiKey ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  onPressed: () => setState(() => _showApiKey = !_showApiKey),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),
            ),
          ),
          
          SizedBox(height: isMobile ? 32 : 40),
          
          Text(
            'Meeting Settings',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          
          _buildSettingCard(
            theme,
            icon: Icons.fiber_manual_record,
            iconColor: Colors.red,
            title: 'Auto-record meetings',
            subtitle: 'Automatically start recording when joining meetings',
            value: _autoRecordMeetings,
            onChanged: (value) => setState(() => _autoRecordMeetings = value),
            isMobile: isMobile,
          ),
          
          const SizedBox(height: 12),
          
          _buildSettingCard(
            theme,
            icon: Icons.text_fields_outlined,
            iconColor: Colors.blue,
            title: 'Transcribe meetings',
            subtitle: 'Generate transcripts for all recorded meetings',
            value: _transcribeMeetings,
            onChanged: (value) => setState(() => _transcribeMeetings = value),
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionBanner(ThemeData theme, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.info_outline,
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
                  'Not Connected',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure your API key to connect',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(
    ThemeData theme, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: theme.colorScheme.primary,
            activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab(ThemeData theme, {bool isMobile = false}) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          
          _buildActivityItem(
            theme,
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            title: 'Connected to Fireflies',
            time: '2 hours ago',
            isMobile: isMobile,
          ),
          _buildActivityItem(
            theme,
            icon: Icons.fiber_manual_record,
            iconColor: Colors.orange,
            title: 'Meeting recorded',
            time: '5 hours ago',
            isMobile: isMobile,
          ),
          _buildActivityItem(
            theme,
            icon: Icons.text_snippet_outlined,
            iconColor: Colors.purple,
            title: 'Transcript generated',
            time: '5 hours ago',
            isMobile: isMobile,
          ),
          _buildActivityItem(
            theme,
            icon: Icons.summarize_outlined,
            iconColor: Colors.indigo,
            title: 'Meeting summary created',
            time: '6 hours ago',
            isMobile: isMobile,
          ),
          _buildActivityItem(
            theme,
            icon: Icons.sync,
            iconColor: Colors.blue,
            title: 'Data synchronized',
            time: '1 day ago',
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    ThemeData theme, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
    required bool isMobile,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, {bool isMobile = false}) {
    final isConnected = widget.integration.status == IntegrationStatus.connected;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        borderRadius: isMobile ? BorderRadius.zero : const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 24,
                vertical: isMobile ? 12 : 14,
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _isLoading ? null : _handleSave,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 32,
                vertical: isMobile ? 12 : 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : Text(
                  isConnected ? 'Save Changes' : 'Connect',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Update integration configuration
      final updatedIntegration = widget.integration.copyWith(
        status: IntegrationStatus.connected,
        configuration: {
          'apiKey': _apiKeyController.text,
          'autoRecord': _autoRecordMeetings,
          'transcribe': _transcribeMeetings,
        },
        lastSyncAt: DateTime.now(),
      );
      
      // Update provider
      ref.read(integrationsProvider.notifier).updateIntegration(updatedIntegration);
      
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showSuccess('${widget.integration.name} configured successfully');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Failed to configure: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}