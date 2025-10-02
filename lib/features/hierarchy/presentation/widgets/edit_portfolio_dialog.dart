import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/hierarchy_providers.dart';
import '../../domain/entities/portfolio.dart';

// Dialog constants matching create dialog
class _DialogConstants {
  static const double borderRadius = 12.0;
  static const double largeBorderRadius = 20.0;
  static const double padding = 20.0;
  static const double smallPadding = 16.0;
  static const double tinyPadding = 12.0;
  static const double spacing = 16.0;
  static const double smallSpacing = 8.0;
  static const double tinySpacing = 4.0;

  // Opacity values
  static const double highOpacity = 0.3;
  static const double mediumOpacity = 0.2;
  static const double lowOpacity = 0.1;
  static const double minimalOpacity = 0.05;
}

class EditPortfolioDialog extends ConsumerStatefulWidget {
  final String portfolioId;

  const EditPortfolioDialog({
    super.key,
    required this.portfolioId,
  });

  @override
  ConsumerState<EditPortfolioDialog> createState() => _EditPortfolioDialogState();
}

class _EditPortfolioDialogState extends ConsumerState<EditPortfolioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ownerController = TextEditingController();
  final _riskSummaryController = TextEditingController();
  HealthStatus _healthStatus = HealthStatus.notSet;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _ownerController.dispose();
    _riskSummaryController.dispose();
    super.dispose();
  }

  Future<void> _updatePortfolio() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(portfolioListProvider.notifier).updatePortfolio(
        portfolioId: widget.portfolioId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        owner: _ownerController.text.trim().isEmpty
            ? null
            : _ownerController.text.trim(),
        healthStatus: _healthStatus,
        riskSummary: _riskSummaryController.text.trim().isEmpty
            ? null
            : _riskSummaryController.text.trim(),
      );

      if (mounted) {
        // Invalidate to refresh the UI
        ref.invalidate(portfolioProvider(widget.portfolioId));
        ref.invalidate(hierarchyStateProvider);

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Portfolio updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          String errorMsg = e.toString();
          if (errorMsg.contains('already exists')) {
            _errorMessage = 'A portfolio with this name already exists. Please choose a different name.';
          } else if (errorMsg.contains('409')) {
            _errorMessage = 'This portfolio name is already taken. Please choose another name.';
          } else {
            _errorMessage = 'Failed to update portfolio. Please try again.';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final portfolioAsync = ref.watch(portfolioProvider(widget.portfolioId));

    return portfolioAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => AlertDialog(
        title: const Text('Error'),
        content: Text('Failed to load portfolio: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
      data: (portfolio) {
        if (portfolio == null) {
          Navigator.of(context).pop();
          return const SizedBox.shrink();
        }

        if (!_isInitialized) {
          _nameController.text = portfolio.name;
          _descriptionController.text = portfolio.description ?? '';
          _ownerController.text = portfolio.owner ?? '';
          _riskSummaryController.text = portfolio.riskSummary ?? '';
          _healthStatus = portfolio.healthStatus;
          _isInitialized = true;
        }

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_DialogConstants.largeBorderRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 500,
              maxHeight: 650,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _DialogHeader(
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _DialogConstants.padding,
                      vertical: _DialogConstants.padding,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Portfolio Name Field
                          _StyledFormField(
                            controller: _nameController,
                            label: 'Portfolio Name',
                            hint: 'Enter portfolio name',
                            icon: Icons.business_center,
                            colorScheme: colorScheme,
                            enabled: !_isLoading,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a portfolio name';
                              }
                              if (value.trim().length < 3) {
                                return 'Portfolio name must be at least 3 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: _DialogConstants.spacing),

                          // Portfolio Description Field
                          _StyledFormField(
                            controller: _descriptionController,
                            label: 'Description (Optional)',
                            hint: 'Enter portfolio description',
                            icon: Icons.description,
                            colorScheme: colorScheme,
                            enabled: !_isLoading,
                            maxLines: 3,
                          ),
                          const SizedBox(height: _DialogConstants.spacing),

                          // Owner Field
                          _StyledFormField(
                            controller: _ownerController,
                            label: 'Portfolio Owner (Optional)',
                            hint: 'Enter portfolio owner name',
                            icon: Icons.person,
                            colorScheme: colorScheme,
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: _DialogConstants.spacing),

                          // Health Status Dropdown
                          _HealthStatusDropdown(
                            value: _healthStatus,
                            colorScheme: colorScheme,
                            enabled: !_isLoading,
                            onChanged: (status) {
                              if (status != null) {
                                setState(() => _healthStatus = status);
                              }
                            },
                          ),
                          const SizedBox(height: _DialogConstants.spacing),

                          // Risk Summary Field
                          _StyledFormField(
                            controller: _riskSummaryController,
                            label: 'Risk Summary (Optional)',
                            hint: 'Describe any risks or concerns',
                            icon: Icons.warning_amber,
                            colorScheme: colorScheme,
                            enabled: !_isLoading,
                            maxLines: 3,
                          ),

                          // Error Message
                          if (_errorMessage != null) ...[
                            const SizedBox(height: _DialogConstants.spacing),
                            Container(
                              padding: const EdgeInsets.all(_DialogConstants.tinyPadding),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer.withValues(
                                  alpha: _DialogConstants.mediumOpacity,
                                ),
                                borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
                                border: Border.all(
                                  color: colorScheme.error.withValues(
                                    alpha: _DialogConstants.highOpacity,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: colorScheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: _DialogConstants.smallSpacing),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: colorScheme.onErrorContainer,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Progress Indicator
                          if (_isLoading) ...[
                            const SizedBox(height: _DialogConstants.spacing),
                            const LinearProgressIndicator(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // Actions
                _DialogActions(
                  isLoading: _isLoading,
                  colorScheme: colorScheme,
                  onCancel: () => Navigator.of(context).pop(),
                  onSubmit: _updatePortfolio,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Dialog Header Component
class _DialogHeader extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _DialogHeader({
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_DialogConstants.padding),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: _DialogConstants.highOpacity),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_DialogConstants.largeBorderRadius),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: _DialogConstants.lowOpacity),
              borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.purple,
              size: 24,
            ),
          ),
          const SizedBox(width: _DialogConstants.spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Portfolio',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Update portfolio information and settings',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: _DialogConstants.highOpacity,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Styled Form Field Component
class _StyledFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final ColorScheme colorScheme;
  final bool enabled;
  final bool autofocus;
  final int? maxLines;
  final String? Function(String?)? validator;

  const _StyledFormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.colorScheme,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      maxLines: maxLines,
      validator: validator,
      textCapitalization: maxLines == 1 ? TextCapitalization.words : TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(
          icon,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: _DialogConstants.mediumOpacity),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: _DialogConstants.mediumOpacity),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: _DialogConstants.lowOpacity),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: _DialogConstants.smallPadding,
          vertical: 14,
        ),
      ),
    );
  }
}

// Health Status Dropdown Component
class _HealthStatusDropdown extends StatelessWidget {
  final HealthStatus value;
  final ColorScheme colorScheme;
  final bool enabled;
  final Function(HealthStatus?) onChanged;

  const _HealthStatusDropdown({
    required this.value,
    required this.colorScheme,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<HealthStatus>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Health Status',
        prefixIcon: Icon(
          Icons.favorite,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: _DialogConstants.mediumOpacity),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: _DialogConstants.mediumOpacity),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: _DialogConstants.lowOpacity),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: _DialogConstants.smallPadding,
          vertical: 14,
        ),
      ),
      items: HealthStatus.values.map((status) {
        IconData icon;
        Color? color;
        String label;

        switch (status) {
          case HealthStatus.green:
            icon = Icons.check_circle;
            color = Colors.green;
            label = 'Healthy';
            break;
          case HealthStatus.amber:
            icon = Icons.warning;
            color = Colors.amber;
            label = 'At Risk';
            break;
          case HealthStatus.red:
            icon = Icons.error;
            color = Colors.red;
            label = 'Critical';
            break;
          case HealthStatus.notSet:
            icon = Icons.help_outline;
            color = Colors.grey;
            label = 'Not Set';
            break;
        }

        return DropdownMenuItem(
          value: status,
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }
}

// Dialog Actions Component
class _DialogActions extends StatelessWidget {
  final bool isLoading;
  final ColorScheme colorScheme;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const _DialogActions({
    required this.isLoading,
    required this.colorScheme,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_DialogConstants.padding),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: _DialogConstants.minimalOpacity),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(_DialogConstants.largeBorderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: isLoading ? null : onCancel,
            child: const Text('Cancel'),
          ),
          const SizedBox(width: _DialogConstants.smallSpacing),
          FilledButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Update Portfolio'),
          ),
        ],
      ),
    );
  }
}