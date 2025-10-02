import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/integration.dart';
import '../providers/integrations_provider.dart';

class FirefliesConfigDialog extends ConsumerStatefulWidget {
  final Integration integration;

  const FirefliesConfigDialog({
    super.key,
    required this.integration,
  });

  @override
  ConsumerState<FirefliesConfigDialog> createState() => _FirefliesConfigDialogState();
}

class _FirefliesConfigDialogState extends ConsumerState<FirefliesConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();

  bool _isLoading = false;
  bool _isTesting = false;
  bool _obscureApiKey = true;
  bool _autoRecordMeetings = true;
  bool _transcribeMeetings = true;
  bool _generateSummaries = true;

  @override
  void initState() {
    super.initState();
    _loadExistingConfiguration();
  }

  void _loadExistingConfiguration() {
    if (widget.integration.status == IntegrationStatus.connected &&
        widget.integration.configuration != null) {
      final config = widget.integration.configuration!;
      _autoRecordMeetings = config['autoRecord'] ?? true;
      _transcribeMeetings = config['transcribe'] ?? true;
      _generateSummaries = config['generateSummaries'] ?? true;
      // Don't load API key for security
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (_apiKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an API key'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isTesting = true;
    });

    try {
      final response = await DioClient.instance.post(
        '/api/integrations/fireflies/test',
        data: {
          'api_key': _apiKeyController.text.trim(),
          'webhook_secret': null,
          'auto_sync': _autoRecordMeetings,
          'selected_project': null,
          'custom_settings': {
            'autoRecord': _autoRecordMeetings,
            'transcribe': _transcribeMeetings,
            'generateSummaries': _generateSummaries,
          },
        },
      );

      if (mounted) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Connection successful!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Connection failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection test failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  Future<void> _saveConfiguration() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final config = {
          'apiKey': _apiKeyController.text.trim(),
          'autoRecord': _autoRecordMeetings,
          'transcribe': _transcribeMeetings,
          'generateSummaries': _generateSummaries,
          'webhookSecret': null,
        };

        await ref
            .read(integrationsProvider.notifier)
            .connectIntegration(widget.integration.id, config);

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fireflies.ai connected successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save configuration: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade600,
                              Colors.orange.shade400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Configure Fireflies.ai',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Automatically transcribe and analyze meetings',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // API Key Section
                  Text(
                    'API Configuration',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // API Key Input
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.15),
                      ),
                    ),
                    child: TextFormField(
                      controller: _apiKeyController,
                      obscureText: _obscureApiKey,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'API Key',
                        hintText: 'Enter your Fireflies API key',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        prefixIcon: Icon(
                          Icons.key,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _obscureApiKey
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureApiKey = !_obscureApiKey;
                                });
                              },
                            ),
                            if (_isTesting)
                              const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            else
                              TextButton(
                                onPressed: _testConnection,
                                child: const Text('Test'),
                              ),
                          ],
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your Fireflies API key';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'You can find your API key in Fireflies Settings → Developer → API Key',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Meeting Settings
                  Text(
                    'Meeting Settings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Settings Cards
                  _buildSettingCard(
                    theme: theme,
                    icon: Icons.fiber_manual_record,
                    iconColor: Colors.red,
                    title: 'Auto-record meetings',
                    subtitle: 'Automatically join and record scheduled meetings',
                    value: _autoRecordMeetings,
                    onChanged: (value) {
                      setState(() {
                        _autoRecordMeetings = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildSettingCard(
                    theme: theme,
                    icon: Icons.text_fields,
                    iconColor: Colors.blue,
                    title: 'Transcribe meetings',
                    subtitle: 'Generate text transcripts of your meetings',
                    value: _transcribeMeetings,
                    onChanged: (value) {
                      setState(() {
                        _transcribeMeetings = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildSettingCard(
                    theme: theme,
                    icon: Icons.summarize,
                    iconColor: Colors.green,
                    title: 'Generate summaries',
                    subtitle: 'Create AI-powered meeting summaries and action items',
                    value: _generateSummaries,
                    onChanged: (value) {
                      setState(() {
                        _generateSummaries = value;
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _isLoading ? null : _saveConfiguration,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Connect Fireflies'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
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
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}