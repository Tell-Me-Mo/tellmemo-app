import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../providers/hierarchy_providers.dart';
import '../../../../app/router/routes.dart';

// Dialog constants matching upload and record dialogs
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

class CreateProjectDialogFromHierarchy extends ConsumerStatefulWidget {
  final String? preselectedPortfolioId;
  final String? preselectedProgramId;

  const CreateProjectDialogFromHierarchy({
    super.key,
    this.preselectedPortfolioId,
    this.preselectedProgramId,
  });

  @override
  ConsumerState<CreateProjectDialogFromHierarchy> createState() => _CreateProjectDialogFromHierarchyState();
}

class _CreateProjectDialogFromHierarchyState extends ConsumerState<CreateProjectDialogFromHierarchy> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedPortfolioId;
  String? _selectedProgramId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedPortfolioId = widget.preselectedPortfolioId;
    _selectedProgramId = widget.preselectedProgramId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final createdProject = await ref.read(projectsListProvider.notifier).createProject(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        createdBy: 'user@example.com',
        portfolioId: _selectedPortfolioId,
        programId: _selectedProgramId,
      );

      if (mounted) {
        Navigator.of(context).pop();

        // Navigate to project details screen
        context.go(AppRoutes.projectDetailPath(createdProject.id));
      }
    } catch (e) {
      print('CreateProjectDialog: Caught error: $e');
      print('CreateProjectDialog: Error type: ${e.runtimeType}');

      if (mounted) {
        setState(() {
          _isLoading = false;
          String? errorMessage = _extractErrorMessage(e);
          print('CreateProjectDialog: Extracted error message: $errorMessage');

          if (errorMessage != null && (errorMessage.toLowerCase().contains('already exists') || errorMessage.toLowerCase().contains('name') && errorMessage.toLowerCase().contains('exists'))) {
            _errorMessage = 'A project with this name already exists. Please choose a different name.';
            print('CreateProjectDialog: Set duplicate name error message');
          } else if (e is DioException && e.response?.statusCode == 409) {
            _errorMessage = 'This project name is already taken. Please choose another name.';
            print('CreateProjectDialog: Set 409 error message');
          } else if (errorMessage != null && errorMessage.isNotEmpty) {
            _errorMessage = errorMessage;
            print('CreateProjectDialog: Set extracted error message: $errorMessage');
          } else {
            _errorMessage = 'Failed to create project. Please try again.';
            print('CreateProjectDialog: Set fallback error message');
          }
          print('CreateProjectDialog: Final _errorMessage: $_errorMessage');
        });
      }
    }
  }

  Widget _buildProgramSection(WidgetRef ref, ColorScheme colorScheme, List<dynamic> programs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Program (Optional)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: _DialogConstants.tinyPadding),
        _StyledDropdownField(
          value: _selectedProgramId,
          hint: 'No Program',
          icon: Icons.category,
          colorScheme: colorScheme,
          enabled: !_isLoading,
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('No Program'),
            ),
            ...programs.map((program) => DropdownMenuItem<String>(
              value: program.id,
              child: Text(program.name),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedProgramId = value;
            });
          },
        ),
      ],
    );
  }

  String? _extractErrorMessage(dynamic error) {
    print('_extractErrorMessage: Processing error: $error');
    print('_extractErrorMessage: Error type: ${error.runtimeType}');

    if (error is DioException) {
      print('_extractErrorMessage: DioException detected');
      print('_extractErrorMessage: Status code: ${error.response?.statusCode}');
      print('_extractErrorMessage: Response data: ${error.response?.data}');

      // Handle DioException with response data
      if (error.response?.data != null) {
        final data = error.response!.data;
        print('_extractErrorMessage: Data type: ${data.runtimeType}');

        if (data is Map<String, dynamic>) {
          // Extract 'detail' field from error response
          final detail = data['detail'] as String?;
          print('_extractErrorMessage: Extracted detail: $detail');
          return detail;
        } else if (data is String) {
          print('_extractErrorMessage: Data is string: $data');
          return data;
        }
      }
      // Fallback to error message
      print('_extractErrorMessage: Using error message: ${error.message}');
      return error.message;
    }
    // For other types of errors
    final errorString = error.toString();
    print('_extractErrorMessage: Converting to string: $errorString');
    return errorString;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(_DialogConstants.largeBorderRadius),
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
                      // Project Name Field with Label
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Name',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: _DialogConstants.tinyPadding),
                          _StyledFormField(
                            controller: _nameController,
                            hint: 'Enter project name',
                            icon: Icons.folder,
                            colorScheme: colorScheme,
                            enabled: !_isLoading,
                            autofocus: true,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a project name';
                              }
                              if (value.trim().length < 3) {
                                return 'Project name must be at least 3 characters';
                              }
                              if (value.trim().length > 100) {
                                return 'Project name must be less than 100 characters';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: _DialogConstants.spacing),

                      // Portfolio Selection (only if not creating from program and portfolios exist)
                      if (widget.preselectedProgramId == null)
                        Consumer(
                          builder: (context, ref, child) {
                            final portfoliosAsync = ref.watch(portfolioListProvider);
                            return portfoliosAsync.when(
                              data: (portfolios) {
                                // Don't show portfolio section if no portfolios exist
                                if (portfolios.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Portfolio (Optional)',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: _DialogConstants.tinyPadding),
                                    _StyledDropdownField(
                                      value: _selectedPortfolioId,
                                      hint: 'No Portfolio',
                                      icon: Icons.business_center,
                                      colorScheme: colorScheme,
                                      enabled: !_isLoading,
                                      items: [
                                        const DropdownMenuItem<String>(
                                          value: null,
                                          child: Text('No Portfolio'),
                                        ),
                                        ...portfolios.map((portfolio) => DropdownMenuItem<String>(
                                          value: portfolio.id,
                                          child: Text(portfolio.name),
                                        )),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedPortfolioId = value;
                                          // Reset program if portfolio changed
                                          if (value != widget.preselectedPortfolioId) {
                                            _selectedProgramId = null;
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                );
                              },
                              loading: () => const LinearProgressIndicator(),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          },
                        ),

                      // Program Selection
                      Consumer(
                        builder: (context, ref, child) {
                          // Case 1: Creating from preselected program
                          if (widget.preselectedProgramId != null) {
                            final programsAsync = ref.watch(programListProvider(portfolioId: null));
                            return programsAsync.when(
                              data: (programs) {
                                final selectedProgram = programs.firstWhere(
                                  (p) => p.id == widget.preselectedProgramId,
                                  orElse: () => throw Exception('Program not found'),
                                );
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: _DialogConstants.spacing),
                                    Text(
                                      'Program (Optional)',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: _DialogConstants.tinyPadding),
                                    _StyledDropdownField(
                                      value: _selectedProgramId,
                                      hint: selectedProgram.name,
                                      icon: Icons.category,
                                      colorScheme: colorScheme,
                                      enabled: false, // Readonly when preselected
                                      items: [
                                        DropdownMenuItem<String>(
                                          value: selectedProgram.id,
                                          child: Text(selectedProgram.name),
                                        ),
                                      ],
                                      onChanged: null,
                                    ),
                                  ],
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          }

                          // Case 2: Portfolio is selected (not preselected from portfolio)
                          if (_selectedPortfolioId != null && widget.preselectedPortfolioId == null) {
                            final programsAsync = ref.watch(programListProvider(portfolioId: _selectedPortfolioId));
                            return programsAsync.when(
                              data: (programs) {
                                // Don't show program dropdown if no programs exist for this portfolio
                                if (programs.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: _DialogConstants.spacing),
                                    _buildProgramSection(ref, colorScheme, programs),
                                  ],
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          }

                          // Case 3: No portfolio selected, check if any programs exist in system
                          if (_selectedPortfolioId == null && widget.preselectedPortfolioId == null) {
                            final allProgramsAsync = ref.watch(programListProvider(portfolioId: null));
                            return allProgramsAsync.when(
                              data: (allPrograms) {
                                if (allPrograms.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: _DialogConstants.spacing),
                                    _buildProgramSection(ref, colorScheme, allPrograms),
                                  ],
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),

                      const SizedBox(height: _DialogConstants.spacing),

                      // Description Field with Label
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description (Optional)',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: _DialogConstants.tinyPadding),
                          _StyledFormField(
                            controller: _descriptionController,
                            hint: 'Enter project description',
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
                        ],
                      ),

                      // Error Message
                      if (_errorMessage != null) ...[
                        // DEBUG: Log that error message widget is being rendered
                        () {
                          print('CreateProjectDialog: Rendering error message widget with: $_errorMessage');
                          return const SizedBox.shrink();
                        }(),
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
          onSubmit: _handleSubmit,
        ),
      ],
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
              Icons.create_new_folder,
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
                  'Create New Project',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Set up a new project to organize your content',
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
  final String hint;
  final IconData icon;
  final ColorScheme colorScheme;
  final bool enabled;
  final bool autofocus;
  final int? maxLines;
  final String? Function(String?)? validator;

  const _StyledFormField({
    required this.controller,
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

// Styled Dropdown Field Component
class _StyledDropdownField extends StatelessWidget {
  final String? value;
  final String hint;
  final IconData icon;
  final ColorScheme colorScheme;
  final bool enabled;
  final List<DropdownMenuItem<String>> items;
  final void Function(String?)? onChanged;

  const _StyledDropdownField({
    required this.value,
    required this.hint,
    required this.icon,
    required this.colorScheme,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      isExpanded: true,
      decoration: InputDecoration(
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
            label: Text(isLoading ? 'Creating...' : 'Create Project'),
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