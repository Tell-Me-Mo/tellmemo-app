import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/hierarchy_providers.dart';
import '../../domain/entities/hierarchy_item.dart';
import '../../domain/entities/portfolio.dart';
import '../../domain/entities/program.dart';
import '../../../../core/constants/layout_constants.dart';

class DeleteConfirmationDialog extends ConsumerStatefulWidget {
  final String itemId;
  final String itemName;
  final HierarchyItemType itemType;
  
  const DeleteConfirmationDialog({
    super.key,
    required this.itemId,
    required this.itemName,
    required this.itemType,
  });

  @override
  ConsumerState<DeleteConfirmationDialog> createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends ConsumerState<DeleteConfirmationDialog> {
  String? _reassignToId;
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Get list of possible reassignment targets based on item type
    final reassignTargetsAsync = widget.itemType == HierarchyItemType.portfolio
        ? ref.watch(portfolioListProvider)
        : widget.itemType == HierarchyItemType.program
            ? ref.watch(programListProvider())
            : null;
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: LayoutConstants.spacingSm),
          const Text('Confirm Delete'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  const TextSpan(text: 'Are you sure you want to delete '),
                  TextSpan(
                    text: '"${widget.itemName}"',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: LayoutConstants.spacingMd),
            
            // Warning about children
            if (widget.itemType != HierarchyItemType.project) ...[
              Container(
                padding: const EdgeInsets.all(LayoutConstants.spacingMd),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(LayoutConstants.borderRadiusMd),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: LayoutConstants.spacingSm),
                    Expanded(
                      child: Text(
                        _getWarningMessage(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LayoutConstants.spacingMd),
              
              // Reassignment option
              if (reassignTargetsAsync != null)
                reassignTargetsAsync.when(
                  data: (targets) {
                    // Filter out the current item based on type
                    final availableTargets = widget.itemType == HierarchyItemType.portfolio
                        ? (targets as List<Portfolio>)
                            .where((target) => target.id != widget.itemId)
                            .toList()
                        : (targets as List<Program>)
                            .where((target) => target.id != widget.itemId)
                            .toList();
                    
                    if (availableTargets.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reassign child items to:',
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(height: LayoutConstants.spacingSm),
                        DropdownButtonFormField<String>(
                          initialValue: _reassignToId,
                          decoration: InputDecoration(
                            hintText: 'Select ${widget.itemType == HierarchyItemType.portfolio ? 'portfolio' : 'program'} (optional)',
                            prefixIcon: Icon(
                              widget.itemType == HierarchyItemType.portfolio
                                  ? Icons.business_center
                                  : Icons.category,
                            ),
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Delete all children'),
                            ),
                            ...availableTargets.map((target) {
                              final id = widget.itemType == HierarchyItemType.portfolio
                                  ? (target as Portfolio).id
                                  : (target as Program).id;
                              final name = widget.itemType == HierarchyItemType.portfolio
                                  ? (target as Portfolio).name
                                  : (target as Program).name;
                              return DropdownMenuItem<String>(
                                value: id,
                                child: Text(name),
                              );
                            }),
                          ],
                          onChanged: _isLoading ? null : (value) {
                            setState(() {
                              _reassignToId = value;
                            });
                          },
                        ),
                      ],
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _handleDelete,
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
  
  String _getWarningMessage() {
    switch (widget.itemType) {
      case HierarchyItemType.portfolio:
        return 'This will delete the portfolio and all its programs and projects unless you reassign them to another portfolio.';
      case HierarchyItemType.program:
        return 'This will delete the program and all its projects unless you reassign them to another program.';
      case HierarchyItemType.project:
        return 'This will permanently delete the project and all its associated data.';
    }
  }
  
  Future<void> _handleDelete() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      switch (widget.itemType) {
        case HierarchyItemType.portfolio:
        case HierarchyItemType.program:
        case HierarchyItemType.project:
          // Use bulk delete for single item to support reassignment
          await ref.read(hierarchyStateProvider().notifier).bulkDeleteItems(
            items: [
              {
                'id': widget.itemId,
                'type': widget.itemType.name,
              }
            ],
            deleteChildren: _reassignToId == null,
            reassignToId: _reassignToId,
            reassignToType: _getReassignToType(),
          );
          break;
      }
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getItemTypeName()} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh hierarchy
        ref.invalidate(hierarchyStateProvider());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete ${_getItemTypeName()}: ${e.toString()}'),
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

  String? _getReassignToType() {
    if (_reassignToId == null) return null;

    // The reassign type should match the item type being deleted
    // (reassigning children to same type of parent)
    switch (widget.itemType) {
      case HierarchyItemType.portfolio:
        return 'portfolio';
      case HierarchyItemType.program:
        return 'program';
      case HierarchyItemType.project:
        return null; // Projects don't have children to reassign
    }
  }
}