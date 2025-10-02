import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
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

class MoveProjectDialog extends ConsumerStatefulWidget {
  final String projectId;

  const MoveProjectDialog({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<MoveProjectDialog> createState() => _MoveProjectDialogState();
}

enum MoveDestinationType {
  standalone,
  portfolio,
  program,
}

class _MoveProjectDialogState extends ConsumerState<MoveProjectDialog> {
  MoveDestinationType? _selectedDestinationType;
  String? _selectedPortfolioId;
  String? _selectedProgramId;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  String? _currentPortfolioId;
  String? _currentProgramId;

  Future<void> _moveProject() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Determine the portfolio and program IDs based on destination type
      String? portfolioId;
      String? programId;

      switch (_selectedDestinationType) {
        case MoveDestinationType.standalone:
          // Both null for standalone
          portfolioId = null;
          programId = null;
          break;
        case MoveDestinationType.portfolio:
          // Only portfolio ID set
          portfolioId = _selectedPortfolioId;
          programId = null;
          break;
        case MoveDestinationType.program:
          // Both IDs set
          portfolioId = _selectedPortfolioId;
          programId = _selectedProgramId;
          break;
        case null:
          return; // No destination selected
      }

      // Update project with new portfolio and program IDs
      await ref.read(projectsListProvider.notifier).updateProject(
        widget.projectId,
        {
          'portfolio_id': portfolioId,
          'program_id': programId,
        },
      );

      if (mounted) {
        // Invalidate to refresh the UI
        ref.invalidate(projectDetailProvider(widget.projectId));
        ref.invalidate(hierarchyStateProvider);

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to move project. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final projectAsync = ref.watch(projectDetailProvider(widget.projectId));
    final portfoliosAsync = ref.watch(portfolioListProvider);

    return projectAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => AlertDialog(
        title: const Text('Error'),
        content: Text('Failed to load project: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
      data: (project) {
        if (project == null) {
          Navigator.of(context).pop();
          return const SizedBox.shrink();
        }

        if (!_isInitialized) {
          _currentPortfolioId = project.portfolioId;
          _currentProgramId = project.programId;
          _selectedPortfolioId = project.portfolioId;
          _selectedProgramId = project.programId;

          // Determine initial destination type
          if (project.programId != null) {
            _selectedDestinationType = MoveDestinationType.program;
          } else if (project.portfolioId != null) {
            _selectedDestinationType = MoveDestinationType.portfolio;
          } else {
            _selectedDestinationType = MoveDestinationType.standalone;
          }

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
                  projectName: project.name,
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
                        // Step 1: Choose destination type
                        Text(
                          'Step 1: Choose Destination Type',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: _DialogConstants.spacing),
                        Row(
                          children: [
                            Expanded(
                              child: _DestinationTypeButton(
                                icon: Icons.folder,
                                label: 'Standalone',
                                color: Colors.orange,
                                isSelected: _selectedDestinationType == MoveDestinationType.standalone,
                                onTap: () {
                                  setState(() {
                                    _selectedDestinationType = MoveDestinationType.standalone;
                                    _selectedPortfolioId = null;
                                    _selectedProgramId = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: _DialogConstants.smallSpacing),
                            Expanded(
                              child: _DestinationTypeButton(
                                icon: Icons.business_center,
                                label: 'Portfolio',
                                color: Colors.purple,
                                isSelected: _selectedDestinationType == MoveDestinationType.portfolio,
                                onTap: () {
                                  setState(() {
                                    _selectedDestinationType = MoveDestinationType.portfolio;
                                    _selectedProgramId = null;
                                    // Set default portfolio if none selected
                                    _selectedPortfolioId ??= portfoliosAsync.value?.firstOrNull?.id;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: _DialogConstants.smallSpacing),
                            Expanded(
                              child: _DestinationTypeButton(
                                icon: Icons.folder_special,
                                label: 'Program',
                                color: Colors.blue,
                                isSelected: _selectedDestinationType == MoveDestinationType.program,
                                onTap: () {
                                  setState(() {
                                    _selectedDestinationType = MoveDestinationType.program;
                                    // Reset selections - user will pick program directly
                                    _selectedProgramId = null;
                                    _selectedPortfolioId = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        // Step 2: Select specific destination
                        if (_selectedDestinationType == MoveDestinationType.portfolio ||
                            _selectedDestinationType == MoveDestinationType.program) ...[
                          const SizedBox(height: _DialogConstants.spacing * 1.5),
                          const Divider(),
                          const SizedBox(height: _DialogConstants.spacing),
                          Text(
                            'Step 2: Select ${_selectedDestinationType == MoveDestinationType.portfolio ? "Portfolio" : "Program"}',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: _DialogConstants.spacing),
                        ],

                        // Portfolio Selection (if portfolio destination only)
                        if (_selectedDestinationType == MoveDestinationType.portfolio)
                          portfoliosAsync.when(
                            data: (portfolios) => _StyledDropdown(
                              value: _selectedPortfolioId,
                              label: 'Select Portfolio',
                              icon: Icons.business_center,
                              colorScheme: colorScheme,
                              enabled: !_isLoading,
                              items: [
                                if (_selectedProgramId == null)
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('No Portfolio'),
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
                              onChanged: (value) {
                                setState(() {
                                  _selectedPortfolioId = value;
                                  // Reset program if portfolio changed
                                  if (value != _currentPortfolioId) {
                                    _selectedProgramId = null;
                                  }
                                });
                              },
                            ),
                            loading: () => const LinearProgressIndicator(),
                            error: (_, __) => const Text('Failed to load portfolios'),
                          ),

                        // Program Selection (if program destination is selected)
                        if (_selectedDestinationType == MoveDestinationType.program) ...[
                          Consumer(
                            builder: (context, ref, child) {
                              // Get all programs from all portfolios
                              final allProgramsAsync = ref.watch(programListProvider(portfolioId: null));
                              return allProgramsAsync.when(
                                data: (programs) => programs.isEmpty
                                  ? Container(
                                      padding: const EdgeInsets.all(_DialogConstants.smallPadding),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
                                      ),
                                      child: Text(
                                        'No programs available',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : _StyledDropdown(
                                      value: _selectedProgramId,
                                      label: 'Select Program',
                                      icon: Icons.folder_special,
                                      colorScheme: colorScheme,
                                      enabled: !_isLoading,
                                      items: programs.map((program) => DropdownMenuItem<String>(
                                        value: program.id,
                                        child: Text(
                                          program.id == _currentProgramId
                                            ? '(Current) ${program.name}'
                                            : program.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedProgramId = value;
                                          // Automatically set the portfolio based on the selected program
                                          if (value != null) {
                                            final selectedProgram = programs.firstWhere((p) => p.id == value);
                                            _selectedPortfolioId = selectedProgram.portfolioId;
                                          }
                                        });
                                      },
                                    ),
                                loading: () => const LinearProgressIndicator(),
                                error: (_, __) => const SizedBox.shrink(),
                              );
                            },
                          ),
                        ],

                        // Info Message about destination
                        if (_hasLocationChanged()) ...[
                          const SizedBox(height: _DialogConstants.spacing),
                          _buildInfoMessage(colorScheme, textTheme),
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
                  canMove: _selectedDestinationType != null &&
                           _hasLocationChanged() &&
                           (_selectedDestinationType == MoveDestinationType.standalone ||
                            (_selectedDestinationType == MoveDestinationType.portfolio && _selectedPortfolioId != null) ||
                            (_selectedDestinationType == MoveDestinationType.program && _selectedProgramId != null)),
                  colorScheme: colorScheme,
                  onCancel: () => Navigator.of(context).pop(),
                  onSubmit: _moveProject,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _hasLocationChanged() {
    // Check if destination type changed
    MoveDestinationType currentType;
    if (_currentProgramId != null) {
      currentType = MoveDestinationType.program;
    } else if (_currentPortfolioId != null) {
      currentType = MoveDestinationType.portfolio;
    } else {
      currentType = MoveDestinationType.standalone;
    }

    if (_selectedDestinationType != currentType) {
      return true;
    }

    // Check if specific selection changed
    return _selectedPortfolioId != _currentPortfolioId ||
           _selectedProgramId != _currentProgramId;
  }

  Widget _buildInfoMessage(ColorScheme colorScheme, TextTheme textTheme) {
    String message;
    IconData icon;
    Color color;

    switch (_selectedDestinationType) {
      case MoveDestinationType.program:
        if (_selectedProgramId != null) {
          message = 'Project will be moved to the selected program';
        } else {
          message = 'Select a program to move the project to';
        }
        icon = Icons.folder_special;
        color = Colors.blue;
        break;
      case MoveDestinationType.portfolio:
        if (_selectedPortfolioId != null) {
          message = 'Project will be moved directly to the portfolio (not in any program)';
        } else {
          message = 'Select a portfolio to move the project to';
        }
        icon = Icons.business_center;
        color = Colors.purple;
        break;
      case MoveDestinationType.standalone:
        message = 'Project will become standalone (not in any portfolio or program)';
        icon = Icons.folder;
        color = Colors.orange;
        break;
      case null:
        message = 'Select a destination type above';
        icon = Icons.help_outline;
        color = colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.all(_DialogConstants.tinyPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _DialogConstants.lowOpacity),
        borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
        border: Border.all(
          color: color.withValues(alpha: _DialogConstants.highOpacity),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: _DialogConstants.smallSpacing),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

// Destination Type Button Component
class _DestinationTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _DestinationTypeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(_DialogConstants.tinyPadding),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: _DialogConstants.mediumOpacity)
              : colorScheme.surfaceContainerHighest.withValues(alpha: _DialogConstants.lowOpacity),
          borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
          border: Border.all(
            color: isSelected
                ? color
                : colorScheme.outline.withValues(alpha: _DialogConstants.mediumOpacity),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : colorScheme.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: isSelected ? color : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
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
  final String projectName;

  const _DialogHeader({
    required this.colorScheme,
    required this.textTheme,
    required this.projectName,
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
              color: Colors.green.withValues(alpha: _DialogConstants.lowOpacity),
              borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
            ),
            child: const Icon(
              Icons.drive_file_move,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: _DialogConstants.spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Move Project',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Moving "$projectName"',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
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

// Styled Dropdown Component (reused from other dialogs)
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
            label: Text(isLoading ? 'Moving...' : 'Move Project'),
          ),
        ],
      ),
    );
  }
}