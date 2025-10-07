import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/hierarchy_providers.dart';

// Dialog constants matching create dialog
class _DialogConstants {
  static const double borderRadius = 12.0;
  static const double largeBorderRadius = 20.0;
  static const double padding = 20.0;
  static const double smallPadding = 16.0;
  static const double tinyPadding = 12.0;
  static const double spacing = 16.0;
  static const double smallSpacing = 8.0;

  // Opacity values
  static const double highOpacity = 0.3;
  static const double mediumOpacity = 0.2;
  static const double lowOpacity = 0.1;
  static const double minimalOpacity = 0.05;
}

class EditProgramDialog extends ConsumerStatefulWidget {
  final String programId;

  const EditProgramDialog({
    super.key,
    required this.programId,
  });

  @override
  ConsumerState<EditProgramDialog> createState() => _EditProgramDialogState();
}

class _EditProgramDialogState extends ConsumerState<EditProgramDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedPortfolioId;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateProgram() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(programListProvider(portfolioId: _selectedPortfolioId).notifier).updateProgram(
        programId: widget.programId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        portfolioId: _selectedPortfolioId,
      );

      if (mounted) {
        // Invalidate to refresh the UI
        ref.invalidate(programProvider(widget.programId));
        ref.invalidate(hierarchyStateProvider);

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Program updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          String errorMsg = e.toString();
          if (errorMsg.contains('already exists')) {
            _errorMessage = 'A program with this name already exists. Please choose a different name.';
          } else if (errorMsg.contains('409')) {
            _errorMessage = 'This program name is already taken. Please choose another name.';
          } else {
            _errorMessage = 'Failed to update program. Please try again.';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final programAsync = ref.watch(programProvider(widget.programId));
    final portfoliosAsync = ref.watch(portfolioListProvider);

    return programAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => AlertDialog(
        title: const Text('Error'),
        content: Text('Failed to load program: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
      data: (program) {
        if (program == null) {
          Navigator.of(context).pop();
          return const SizedBox.shrink();
        }

        if (!_isInitialized) {
          _nameController.text = program.name;
          _descriptionController.text = program.description ?? '';
          _selectedPortfolioId = program.portfolioId;
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
                          // Program Name Field
                          _StyledFormField(
                            controller: _nameController,
                            label: 'Program Name',
                            hint: 'Enter program name',
                            icon: Icons.folder,
                            colorScheme: colorScheme,
                            enabled: !_isLoading,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a program name';
                              }
                              if (value.trim().length < 3) {
                                return 'Program name must be at least 3 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: _DialogConstants.spacing),

                          // Portfolio Dropdown
                          portfoliosAsync.when(
                            data: (portfolios) => _StyledDropdown(
                              value: _selectedPortfolioId,
                              label: 'Portfolio',
                              icon: Icons.business_center,
                              colorScheme: colorScheme,
                              enabled: !_isLoading,
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('No Portfolio (Standalone)'),
                                ),
                                ...portfolios.map((portfolio) => DropdownMenuItem<String>(
                                  value: portfolio.id,
                                  child: Text(portfolio.name),
                                )),
                              ],
                              onChanged: (value) => setState(() => _selectedPortfolioId = value),
                            ),
                            loading: () => const LinearProgressIndicator(),
                            error: (_, __) => const Text('Failed to load portfolios'),
                          ),
                          const SizedBox(height: _DialogConstants.spacing),

                          // Program Description Field
                          _StyledFormField(
                            controller: _descriptionController,
                            label: 'Description (Optional)',
                            hint: 'Enter program description',
                            icon: Icons.description,
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
                  onSubmit: _updateProgram,
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
              color: Colors.blue.withValues(alpha: _DialogConstants.lowOpacity),
              borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
            ),
            child: const Icon(
              Icons.edit,
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
                  'Edit Program',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Update program information and settings',
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

// Styled Dropdown Component
class _StyledDropdown extends StatelessWidget {
  final String? value;
  final String label;
  final IconData icon;
  final ColorScheme colorScheme;
  final bool enabled;
  final List<DropdownMenuItem<String>> items;
  final Function(String?) onChanged;

  const _StyledDropdown({
    required this.value,
    required this.label,
    required this.icon,
    required this.colorScheme,
    required this.enabled,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
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
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: _DialogConstants.lowOpacity),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: _DialogConstants.smallPadding,
          vertical: 14,
        ),
      ),
      items: items,
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
                : const Text('Update Program'),
          ),
        ],
      ),
    );
  }
}