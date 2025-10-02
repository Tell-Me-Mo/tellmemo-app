import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/hierarchy_providers.dart';
import '../../domain/entities/hierarchy_item.dart';
import '../../data/services/hierarchy_api_service_extensions.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../projects/presentation/providers/projects_provider.dart';

class EnhancedDeleteDialog extends ConsumerStatefulWidget {
  final String itemId;
  final String itemName;
  final HierarchyItemType itemType;

  const EnhancedDeleteDialog({
    super.key,
    required this.itemId,
    required this.itemName,
    required this.itemType,
  });

  @override
  ConsumerState<EnhancedDeleteDialog> createState() =>
      _EnhancedDeleteDialogState();
}

class _EnhancedDeleteDialogState
    extends ConsumerState<EnhancedDeleteDialog> {
  bool _cascadeDelete = false;
  bool _isLoading = false;
  Map<String, dynamic>? _deletionImpact;
  bool _loadingImpact = true;

  @override
  void initState() {
    super.initState();
    _loadDeletionImpact();
  }

  Future<void> _loadDeletionImpact() async {
    try {
      setState(() => _loadingImpact = true);

      // Get deletion impact from API
      final impact = await ref
          .read(hierarchyApiServiceProvider)
          .getDeletionImpact(widget.itemId, widget.itemType);

      if (mounted) {
        setState(() {
          _deletionImpact = impact;
          _loadingImpact = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingImpact = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: LayoutConstants.spacingSm),
          Text('Delete ${widget.itemName}'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: _loadingImpact
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main question
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium,
                      children: [
                        const TextSpan(
                            text: 'Are you sure you want to delete '),
                        TextSpan(
                          text: '"${widget.itemName}"',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: '?'),
                      ],
                    ),
                  ),
                  const SizedBox(height: LayoutConstants.spacingMd),

                  // Show affected entities
                  if (_deletionImpact != null) ...[
                    _buildAffectedEntitiesSection(theme),
                    const SizedBox(height: LayoutConstants.spacingMd),
                  ],

                  // Deletion options
                  _buildDeletionOptions(theme),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isLoading || _loadingImpact ? null : _handleDelete,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          icon: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onError,
                  ),
                )
              : const Icon(Icons.delete),
          label: Text(_isLoading ? 'Deleting...' : 'Delete'),
        ),
      ],
    );
  }

  Widget _buildAffectedEntitiesSection(ThemeData theme) {
    final hasAffectedEntities = _hasAffectedEntities();

    if (!hasAffectedEntities) {
      return Container(
        padding: const EdgeInsets.all(LayoutConstants.spacingMd),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(LayoutConstants.borderRadiusMd),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: LayoutConstants.spacingSm),
            Expanded(
              child: Text(
                'No dependent items. This ${_getItemTypeName()} can be safely deleted.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(LayoutConstants.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(LayoutConstants.borderRadiusMd),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_outlined,
                size: 20,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: LayoutConstants.spacingSm),
              Text(
                'This ${_getItemTypeName()} contains:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: LayoutConstants.spacingSm),
          ..._buildAffectedList(theme),
        ],
      ),
    );
  }

  List<Widget> _buildAffectedList(ThemeData theme) {
    final widgets = <Widget>[];

    if (widget.itemType == HierarchyItemType.portfolio) {
      final programs = _deletionImpact?['affected_programs'] as List? ?? [];
      final projects = _deletionImpact?['affected_projects'] as List? ?? [];

      if (programs.isNotEmpty) {
        widgets.add(_buildAffectedItem(
          icon: Icons.category,
          label: '${programs.length} Program${programs.length > 1 ? 's' : ''}',
          items: programs
              .take(3)
              .map((p) => p['name'] as String)
              .toList(),
          hasMore: programs.length > 3,
          theme: theme,
        ));
      }

      if (projects.isNotEmpty) {
        if (widgets.isNotEmpty) {
          widgets.add(const SizedBox(height: LayoutConstants.spacingXs));
        }
        widgets.add(_buildAffectedItem(
          icon: Icons.folder,
          label: '${projects.length} Project${projects.length > 1 ? 's' : ''}',
          items: projects
              .take(3)
              .map((p) => p['name'] as String)
              .toList(),
          hasMore: projects.length > 3,
          theme: theme,
        ));
      }
    } else if (widget.itemType == HierarchyItemType.program) {
      final projects = _deletionImpact?['affected_projects'] as List? ?? [];

      if (projects.isNotEmpty) {
        widgets.add(_buildAffectedItem(
          icon: Icons.folder,
          label: '${projects.length} Project${projects.length > 1 ? 's' : ''}',
          items: projects
              .take(3)
              .map((p) => p['name'] as String)
              .toList(),
          hasMore: projects.length > 3,
          theme: theme,
        ));
      }
    }

    return widgets;
  }

  Widget _buildAffectedItem({
    required IconData icon,
    required String label,
    required List<String> items,
    required bool hasMore,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onErrorContainer),
        const SizedBox(width: LayoutConstants.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              ...items.map((name) => Padding(
                    padding: const EdgeInsets.only(left: LayoutConstants.spacingMd),
                    child: Text(
                      '• $name',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  )),
              if (hasMore)
                Padding(
                  padding: const EdgeInsets.only(left: LayoutConstants.spacingMd),
                  child: Text(
                    '... and more',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.6),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeletionOptions(ThemeData theme) {
    if (!_hasAffectedEntities()) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(LayoutConstants.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(LayoutConstants.borderRadiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose deletion option:',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: LayoutConstants.spacingSm),
          RadioListTile<bool>(
            value: false,
            groupValue: _cascadeDelete,
            onChanged: _isLoading
                ? null
                : (value) {
                    setState(() {
                      _cascadeDelete = value ?? false;
                    });
                  },
            title: Text(
              'Make items standalone',
              style: theme.textTheme.bodyMedium,
            ),
            subtitle: Text(
              _getStandaloneDescription(),
              style: theme.textTheme.bodySmall,
            ),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<bool>(
            value: true,
            groupValue: _cascadeDelete,
            onChanged: _isLoading
                ? null
                : (value) {
                    setState(() {
                      _cascadeDelete = value ?? true;
                    });
                  },
            title: Text(
              'Delete all items',
              style: theme.textTheme.bodyMedium,
            ),
            subtitle: Text(
              _getCascadeDescription(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  String _getStandaloneDescription() {
    if (widget.itemType == HierarchyItemType.portfolio) {
      return 'Programs and projects will become standalone items without a portfolio';
    } else if (widget.itemType == HierarchyItemType.program) {
      return 'Projects will become standalone items without a program';
    }
    return '';
  }

  String _getCascadeDescription() {
    if (widget.itemType == HierarchyItemType.portfolio) {
      return 'Permanently delete all programs and projects in this portfolio';
    } else if (widget.itemType == HierarchyItemType.program) {
      return 'Permanently delete all projects in this program';
    }
    return '';
  }

  bool _hasAffectedEntities() {
    if (_deletionImpact == null) return false;

    if (widget.itemType == HierarchyItemType.portfolio) {
      final programs = _deletionImpact!['affected_programs'] as List? ?? [];
      final projects = _deletionImpact!['affected_projects'] as List? ?? [];
      return programs.isNotEmpty || projects.isNotEmpty;
    } else if (widget.itemType == HierarchyItemType.program) {
      final projects = _deletionImpact!['affected_projects'] as List? ?? [];
      return projects.isNotEmpty;
    }

    return false;
  }

  Future<void> _handleDelete() async {
    setState(() {
      _isLoading = true;
    });

    try {
      switch (widget.itemType) {
        case HierarchyItemType.portfolio:
          await ref.read(portfolioListProvider.notifier).deletePortfolio(
                portfolioId: widget.itemId,
                cascadeDelete: _cascadeDelete,
              );
          break;
        case HierarchyItemType.program:
          await ref.read(programListProvider().notifier).deleteProgram(
                programId: widget.itemId,
                cascadeDelete: _cascadeDelete,
              );
          break;
        case HierarchyItemType.project:
          // Projects don't have cascade option
          await ref.read(projectsListProvider.notifier).deleteProject(
                widget.itemId,
              );
          break;
      }

      if (mounted) {
        Navigator.of(context).pop();

        final message = _cascadeDelete && _hasAffectedEntities()
            ? '${_getItemTypeName()} and all related items deleted successfully'
            : '${_getItemTypeName()} deleted successfully';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh hierarchy
        ref.invalidate(hierarchyStateProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to delete ${_getItemTypeName()}: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _getItemTypeName() {
    switch (widget.itemType) {
      case HierarchyItemType.portfolio:
        return 'Portfolio';
      case HierarchyItemType.program:
        return 'Program';
      case HierarchyItemType.project:
        return 'Project';
    }
  }
}