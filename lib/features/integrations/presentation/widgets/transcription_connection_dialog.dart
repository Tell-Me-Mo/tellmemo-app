import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/integration.dart';
import '../providers/integrations_provider.dart';

class TranscriptionConnectionDialog extends ConsumerStatefulWidget {
  final Integration integration;

  const TranscriptionConnectionDialog({
    super.key,
    required this.integration,
  });

  @override
  ConsumerState<TranscriptionConnectionDialog> createState() =>
      _TranscriptionConnectionDialogState();
}

class _TranscriptionConnectionDialogState
    extends ConsumerState<TranscriptionConnectionDialog> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  String _serviceType = 'whisper'; // Default to local Whisper
  final _apiKeyController = TextEditingController();
  final _organizationController = TextEditingController();
  bool _isConnecting = false;
  bool _autoSync = true;
  bool _obscureApiKey = true;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadExistingConfiguration();
  }

  void _loadExistingConfiguration() {
    // Load existing configuration if integration is connected
    if (widget.integration.status == IntegrationStatus.connected &&
        widget.integration.configuration != null) {
      final config = widget.integration.configuration!;

      // Load auto-sync setting (check both snake_case and camelCase)
      _autoSync = config['auto_sync'] ?? config['autoSync'] ?? true;

      // Load custom settings (check both snake_case and camelCase)
      final customSettings = config['custom_settings'] ?? config['customSettings'] ?? {};

      // Load service type
      _serviceType = customSettings['service_type'] ?? 'whisper';

      // Load Salad-specific settings if using Salad
      if (_serviceType == 'salad') {
        // Note: API key is encrypted on backend, we won't show it
        // But we can show organization name
        _organizationController.text = customSettings['organization_name'] ?? '';
      }

      // Force UI update after loading
      setState(() {});
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (_serviceType == 'salad' && _apiKeyController.text.isEmpty) {
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
      // Prepare test configuration
      final apiKey = _serviceType == 'salad'
          ? _apiKeyController.text.trim()
          : 'local_whisper';

      final response = await DioClient.instance.post(
        '/api/v1/integrations/transcription/test',
        data: {
          'api_key': apiKey,
          'webhook_secret': null,
          'auto_sync': _autoSync,
          'selected_project': null,
          'custom_settings': {
            'service_type': _serviceType,
            'organization_name': _organizationController.text.trim(),
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

  Future<void> _connect() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isConnecting = true;
      });

      try {
        // Prepare configuration with camelCase keys for the service
        Map<String, dynamic> config = {
          'autoSync': _autoSync,
          'selectedProject': null, // null means all projects
        };

        // Add service-specific configuration
        if (_serviceType == 'salad') {
          // For Salad, we need the API key
          // If updating and no new key provided, use a placeholder
          final apiKey = _apiKeyController.text.trim();
          if (apiKey.isEmpty && widget.integration.status == IntegrationStatus.connected) {
            // Keep existing key - send a special marker
            config['apiKey'] = 'KEEP_EXISTING_KEY';
          } else {
            config['apiKey'] = apiKey;
          }
          config['webhookSecret'] = null;
          config['customSettings'] = {
            'organization_name': _organizationController.text.trim(),
            'service_type': 'salad',
          };
        } else {
          // For Whisper, we don't need an API key but backend expects a string
          config['apiKey'] = 'local_whisper'; // Placeholder for local service
          config['webhookSecret'] = null;
          config['customSettings'] = {
            'service_type': 'whisper',
          };
        }

        // Connect the integration
        await ref
            .read(integrationsProvider.notifier)
            .connectIntegration(widget.integration.id, config);

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _serviceType == 'whisper'
                    ? 'Local Whisper transcription configured successfully!'
                    : 'Salad API transcription configured successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to configure transcription: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isConnecting = false;
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
                              Colors.teal.shade600,
                              Colors.teal.shade400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.transcribe,
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
                              'Configure Transcription',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Choose between local AI or cloud transcription',
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

                  // Service Type Selection
                  Text(
                    'Transcription Service',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _ServiceCard(
                          service: 'whisper',
                          name: 'Local Whisper',
                          description: 'Private, on-device processing',
                          icon: Icons.computer,
                          iconColor: Colors.blue,
                          isSelected: _serviceType == 'whisper',
                          onTap: () {
                            setState(() {
                              _serviceType = 'whisper';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ServiceCard(
                          service: 'salad',
                          name: 'Salad Cloud',
                          description: 'Scalable cloud processing',
                          icon: Icons.cloud,
                          iconColor: Colors.green,
                          isSelected: _serviceType == 'salad',
                          onTap: () {
                            setState(() {
                              _serviceType = 'salad';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Salad API Configuration (only shown for Salad)
                  if (_serviceType == 'salad') ...[
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
                          labelText: 'Salad API Key',
                          hintText: widget.integration.status == IntegrationStatus.connected
                              ? 'Leave blank to keep existing key'
                              : 'Enter your Salad API key',
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
                          // Only require API key if not already connected or if changing it
                          if (_serviceType == 'salad' &&
                              widget.integration.status != IntegrationStatus.connected &&
                              (value == null || value.isEmpty)) {
                            return 'API Key is required for Salad';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Organization Name
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.15),
                        ),
                      ),
                      child: TextFormField(
                        controller: _organizationController,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: 'Organization Name',
                          hintText: 'Your Salad organization name',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: Icon(
                            Icons.business,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        validator: (value) {
                          if (_serviceType == 'salad' && (value == null || value.isEmpty)) {
                            return 'Organization name is required for Salad';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Processing Settings
                  Text(
                    'Processing Settings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
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
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.sync,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Auto-process recordings',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Automatically transcribe uploaded audio files',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _autoSync,
                          onChanged: (value) {
                            setState(() {
                              _autoSync = value;
                            });
                          },
                          activeThumbColor: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Information Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _serviceType == 'whisper'
                                ? 'Local Whisper provides fast, private transcription using OpenAI\'s Whisper large-v3-turbo model. Audio never leaves your infrastructure. Requires ~2GB RAM.'
                                : 'Salad Cloud offers scalable transcription on distributed GPUs. Audio files are securely processed in the cloud. Get your API key at salad.com.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                        onPressed: _isConnecting ? null : _connect,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.teal.shade600,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isConnecting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_serviceType == 'whisper'
                                ? 'Configure Whisper'
                                : 'Connect Salad API'),
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
}

// Service selection card widget (similar to AI Brain's provider cards)
class _ServiceCard extends StatelessWidget {
  final String service;
  final String name;
  final String description;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service,
    required this.name,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    iconColor.withValues(alpha: 0.1),
                    iconColor.withValues(alpha: 0.05),
                  ],
                )
              : null,
          color: isSelected ? null : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? iconColor.withValues(alpha: 0.5)
                : colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? iconColor : colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? iconColor : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}