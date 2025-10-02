import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/hierarchy_providers.dart';
import '../../domain/entities/portfolio.dart';

// Dialog constants matching upload document dialog
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

class CreatePortfolioDialog extends ConsumerStatefulWidget {
  final Function(Portfolio)? onPortfolioCreated;

  const CreatePortfolioDialog({
    super.key,
    this.onPortfolioCreated,
  });

  @override
  ConsumerState<CreatePortfolioDialog> createState() => _CreatePortfolioDialogState();
}

class _CreatePortfolioDialogState extends ConsumerState<CreatePortfolioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createPortfolio() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('[CreatePortfolioDialog] Starting portfolio creation');
      print('[CreatePortfolioDialog] Name: ${_nameController.text.trim()}');
      print('[CreatePortfolioDialog] Description: ${_descriptionController.text.trim()}');

      final portfolio = await ref.read(portfolioListProvider.notifier).createPortfolio(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      print('[CreatePortfolioDialog] Portfolio created successfully: ${portfolio.name}');

      if (mounted) {
        // Invalidate hierarchy state to refresh the UI
        ref.invalidate(hierarchyStateProvider);
        ref.invalidate(portfolioListProvider);

        Navigator.of(context).pop();
        widget.onPortfolioCreated?.call(portfolio);
      }
    } catch (e, stackTrace) {
      print('[CreatePortfolioDialog] Error creating portfolio: $e');
      print('[CreatePortfolioDialog] Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isLoading = false;
          String errorMsg = e.toString();
          if (errorMsg.contains('already exists')) {
            _errorMessage = 'A portfolio with this name already exists. Please choose a different name.';
          } else if (errorMsg.contains('409')) {
            _errorMessage = 'This portfolio name is already taken. Please choose another name.';
          } else {
            _errorMessage = 'Failed to create portfolio. Please try again.';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_DialogConstants.largeBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 550,
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
                        autofocus: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a portfolio name';
                          }
                          if (value.trim().length < 3) {
                            return 'Portfolio name must be at least 3 characters';
                          }
                          if (value.trim().length > 100) {
                            return 'Portfolio name must be less than 100 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: _DialogConstants.spacing),

                      // Description Field
                      _StyledFormField(
                        controller: _descriptionController,
                        label: 'Description (Optional)',
                        hint: 'Enter portfolio description',
                        icon: Icons.description,
                        colorScheme: colorScheme,
                        enabled: !_isLoading,
                        maxLines: 3,
                        validator: (value) {
                          if (value != null && value.trim().length > 500) {
                            return 'Description must be less than 500 characters';
                          }
                          return null;
                        },
                      ),

                      // Error Message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: _DialogConstants.spacing),
                        Container(
                          padding: const EdgeInsets.all(_DialogConstants.spacing),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer.withValues(alpha: _DialogConstants.mediumOpacity),
                            borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
                            border: Border.all(
                              color: colorScheme.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 20,
                                color: colorScheme.error,
                              ),
                              const SizedBox(width: _DialogConstants.tinyPadding),
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
              onSubmit: _createPortfolio,
            ),
          ],
        ),
      ),
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
              color: Colors.blue.withValues(alpha: _DialogConstants.lowOpacity),
              borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
            ),
            child: const Icon(
              Icons.add_business,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: _DialogConstants.spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Portfolio',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Create a new portfolio to organize programs',
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
        color: colorScheme.surfaceContainerHighest.withValues(alpha: _DialogConstants.highOpacity),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(_DialogConstants.largeBorderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: isLoading ? null : onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: _DialogConstants.padding,
                vertical: _DialogConstants.spacing,
              ),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: _DialogConstants.tinyPadding),
          FilledButton.icon(
            onPressed: isLoading ? null : onSubmit,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add),
            label: Text(isLoading ? 'Creating...' : 'Create'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: _DialogConstants.tinyPadding,
              ),
            ),
          ),
        ],
      ),
    );
  }
}