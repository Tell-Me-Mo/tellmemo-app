import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../providers/integrations_provider.dart';

class AIBrainConfigDialog extends ConsumerStatefulWidget {
  const AIBrainConfigDialog({super.key});

  @override
  ConsumerState<AIBrainConfigDialog> createState() => _AIBrainConfigDialogState();
}

class _AIBrainConfigDialogState extends ConsumerState<AIBrainConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();

  String _selectedProvider = 'claude';
  String _selectedModel = 'claude-3-5-haiku-latest';
  bool _isLoading = false;
  bool _isTesting = false;
  bool _obscureApiKey = true;

  final Map<String, List<ModelInfo>> _providerModels = {
    'claude': [
      ModelInfo('claude-opus-4-1-20250805', 'Claude Opus 4.1', 'Most capable model, best for coding & reasoning'),
      ModelInfo('claude-opus-4-20250522', 'Claude Opus 4', 'Powerful model, excellent for complex tasks'),
      ModelInfo('claude-sonnet-4-20250522', 'Claude Sonnet 4', 'Balanced performance with deep thinking'),
      ModelInfo('claude-3-5-sonnet-latest', 'Claude 3.5 Sonnet', 'Previous gen, still highly capable'),
      ModelInfo('claude-3-5-haiku-latest', 'Claude 3.5 Haiku', 'Fast and efficient for simpler tasks'),
    ],
    'openai': [
      ModelInfo('gpt-4o', 'GPT-4o', 'Flagship model with vision capabilities'),
      ModelInfo('gpt-4o-mini', 'GPT-4o Mini', 'Smaller, faster version of GPT-4o'),
      ModelInfo('gpt-4-turbo', 'GPT-4 Turbo', 'Latest GPT-4 with 128k context'),
      ModelInfo('gpt-3.5-turbo', 'GPT-3.5 Turbo', 'Fast and cost-effective for simple tasks'),
    ],
  };

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
    });

    try {
      final response = await DioClient.instance.post(
        '/api/integrations/ai_brain/test',
        data: {
          'api_key': _apiKeyController.text.trim(),
          'custom_settings': {
            'provider': _selectedProvider,
            'model': _selectedModel,
          },
        },
      );

      if (mounted) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Configuration test successful'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Configuration test failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: $e'),
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await DioClient.instance.post(
        '/api/integrations/ai_brain/connect',
        data: {
          'api_key': _apiKeyController.text.trim(),
          'auto_sync': false,
          'custom_settings': {
            'provider': _selectedProvider,
            'model': _selectedModel,
            'set_as_default': true,
          },
        },
      );

      // Refresh the integrations list
      ref.invalidate(integrationsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI Brain configuration saved successfully'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: isMobile
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 24)
        : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.all(24),
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
                        padding: EdgeInsets.all(isMobile ? 10 : 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: isMobile ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: isMobile ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Configure AI Brain',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 18 : null,
                              ),
                            ),
                            if (!isMobile)
                              Text(
                                'Choose your AI provider and model',
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
                        padding: isMobile ? const EdgeInsets.all(8) : null,
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 20 : 32),

                  // Provider Selection
                  Text(
                    'AI Provider',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 14 : null,
                    ),
                  ),
                  SizedBox(height: isMobile ? 8 : 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ProviderCard(
                          provider: 'claude',
                          name: isMobile ? 'Claude' : 'Anthropic Claude',
                          description: 'Advanced reasoning and analysis',
                          isSelected: _selectedProvider == 'claude',
                          isMobile: isMobile,
                          onTap: () {
                            setState(() {
                              _selectedProvider = 'claude';
                              _selectedModel = _providerModels['claude']!.first.id;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ProviderCard(
                          provider: 'openai',
                          name: 'OpenAI',
                          description: 'GPT models with vision support',
                          isSelected: _selectedProvider == 'openai',
                          isMobile: isMobile,
                          onTap: () {
                            setState(() {
                              _selectedProvider = 'openai';
                              _selectedModel = _providerModels['openai']!.first.id;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 16 : 24),

                  // Model Selection
                  Text(
                    'Model',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 14 : null,
                    ),
                  ),
                  SizedBox(height: isMobile ? 8 : 12),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.15),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedModel,
                      isExpanded: true,
                      isDense: false,
                      itemHeight: null,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: InputBorder.none,
                      ),
                      items: _providerModels[_selectedProvider]!.map((model) {
                        return DropdownMenuItem(
                          value: model.id,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  model.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  model.description,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedModel = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // API Key Input
                  Text(
                    'API Key',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 14 : null,
                    ),
                  ),
                  SizedBox(height: isMobile ? 8 : 12),
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
                      decoration: InputDecoration(
                        hintText: _selectedProvider == 'claude'
                          ? 'sk-ant-api...'
                          : 'sk-...',
                        prefixIcon: const Icon(Icons.key),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(_obscureApiKey ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _obscureApiKey = !_obscureApiKey;
                                });
                              },
                            ),
                            if (!_isTesting)
                              TextButton(
                                onPressed: _testConfiguration,
                                child: const Text('Test'),
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                          ],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'API Key is required';
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
                        size: 16,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedProvider == 'claude'
                            ? 'Get your API key from console.anthropic.com'
                            : 'Get your API key from platform.openai.com',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 20 : 32),

                  // Action Buttons
                  isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton(
                            onPressed: _isLoading ? null : _saveConfiguration,
                            child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Save Configuration'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: _isLoading ? null : _saveConfiguration,
                            child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Save Configuration'),
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

class _ProviderCard extends StatelessWidget {
  final String provider;
  final String name;
  final String description;
  final bool isSelected;
  final bool isMobile;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.provider,
    required this.name,
    required this.description,
    required this.isSelected,
    required this.isMobile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          border: Border.all(
            color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  provider == 'claude' ? Icons.auto_awesome : Icons.smart_toy,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                  size: isMobile ? 18 : 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 13 : 14,
                      color: isSelected ? colorScheme.primary : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class ModelInfo {
  final String id;
  final String name;
  final String description;

  ModelInfo(this.id, this.name, this.description);
}