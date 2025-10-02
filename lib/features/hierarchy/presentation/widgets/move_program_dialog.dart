import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/hierarchy_providers.dart';

// Dialog constants matching other dialogs
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

class MoveProgramDialog extends ConsumerStatefulWidget {
  final String programId;

  const MoveProgramDialog({
    super.key,
    required this.programId,
  });

  @override
  ConsumerState<MoveProgramDialog> createState() => _MoveProgramDialogState();
}

class _MoveProgramDialogState extends ConsumerState<MoveProgramDialog> {
  String? _selectedPortfolioId;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  String? _currentPortfolioId;

  Future<void> _moveProgram() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get the current program data
      final program = ref.read(programProvider(widget.programId)).value;
      if (program == null) return;

      // Update program with new portfolio ID (or null for standalone)
      // Pass the current name and description to ensure they're not cleared
      await ref.read(programListProvider(portfolioId: _currentPortfolioId).notifier).updateProgram(
        programId: widget.programId,
        name: program.name,
        description: program.description,
        portfolioId: _selectedPortfolioId,
      );

      if (mounted) {
        // Invalidate to refresh the UI
        ref.invalidate(programProvider(widget.programId));
        ref.invalidate(hierarchyStateProvider);

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to move program. Please try again.';
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
          _currentPortfolioId = program.portfolioId;
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
              maxHeight: 450,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _DialogHeader(
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  programName: program.name,
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _DialogConstants.padding,
                      vertical: _DialogConstants.padding,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        // Portfolio Selection
                        portfoliosAsync.when(
                          data: (portfolios) {
                            return _StyledDropdown(
                              value: _selectedPortfolioId,
                              label: 'Select Destination',
                              icon: Icons.business_center,
                              colorScheme: colorScheme,
                              enabled: !_isLoading,
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Standalone (No Portfolio)'),
                                ),
                                ...portfolios.map((portfolio) => DropdownMenuItem<String>(
                                  value: portfolio.id,
                                  child: Text(
                                    portfolio.id == _currentPortfolioId
                                      ? '(Current) ${portfolio.name}'
                                      : portfolio.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                              ],
                              onChanged: (value) => setState(() => _selectedPortfolioId = value),
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const Text('Failed to load portfolios'),
                        ),

                        // Warning Message if moving to standalone
                        if (_selectedPortfolioId == null && _currentPortfolioId != null) ...[
                          const SizedBox(height: _DialogConstants.spacing),
                          Container(
                            padding: const EdgeInsets.all(_DialogConstants.tinyPadding),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: _DialogConstants.lowOpacity),
                              borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: _DialogConstants.highOpacity),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: _DialogConstants.smallSpacing),
                                Expanded(
                                  child: Text(
                                    'Moving to standalone will remove this program from its current portfolio.',
                                    style: textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

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
                // Actions
                _DialogActions(
                  isLoading: _isLoading,
                  canMove: _selectedPortfolioId != _currentPortfolioId,
                  colorScheme: colorScheme,
                  onCancel: () => Navigator.of(context).pop(),
                  onSubmit: _moveProgram,
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
  final String programName;

  const _DialogHeader({
    required this.colorScheme,
    required this.textTheme,
    required this.programName,
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
              Icons.drive_file_move,
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
                  'Move Program',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Moving "$programName"',
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
      initialValue: value,
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
  final bool canMove;
  final ColorScheme colorScheme;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const _DialogActions({
    required this.isLoading,
    required this.canMove,
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
          FilledButton.icon(
            onPressed: (isLoading || !canMove) ? null : onSubmit,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.drive_file_move, size: 18),
            label: Text(isLoading ? 'Moving...' : 'Move Program'),
          ),
        ],
      ),
    );
  }
}