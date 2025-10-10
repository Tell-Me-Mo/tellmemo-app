import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/hierarchy_item.dart';
import '../providers/hierarchy_providers.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../core/services/notification_service.dart';

class BulkDeleteDialog extends ConsumerStatefulWidget {
  final List<HierarchyItem> itemsToDelete;
  
  const BulkDeleteDialog({
    super.key,
    required this.itemsToDelete,
  });

  @override
  ConsumerState<BulkDeleteDialog> createState() => _BulkDeleteDialogState();
}

class _BulkDeleteDialogState extends ConsumerState<BulkDeleteDialog> {
  bool _isLoading = false;
  bool _deleteChildren = true; // By default, delete all children
  String? _reassignToId;
  HierarchyItemType? _reassignToType;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hierarchyAsync = ref.watch(hierarchyStateProvider());
    
    // Calculate total items affected
    int totalItemsAffected = _calculateTotalAffected();
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.delete_forever,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: LayoutConstants.spacingSm),
          Text(
            widget.itemsToDelete.length == 1 
              ? 'Delete Item' 
              : 'Delete ${widget.itemsToDelete.length} Items',
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning message
            Container(
              padding: const EdgeInsets.all(LayoutConstants.spacingMd),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(LayoutConstants.borderRadiusMd),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: LayoutConstants.spacingSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This action cannot be undone!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: LayoutConstants.spacingXs),
                        Text(
                          widget.itemsToDelete.length == 1
                            ? 'You are about to delete "${widget.itemsToDelete.first.name}"'
                            : 'You are about to delete ${widget.itemsToDelete.length} items',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                        if (totalItemsAffected > widget.itemsToDelete.length) ...[
                          const SizedBox(height: LayoutConstants.spacingXs),
                          Text(
                            'This will affect $totalItemsAffected total items (including children)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: LayoutConstants.spacingLg),
            
            // Items to delete list
            Text(
              'Items to be deleted:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: LayoutConstants.spacingSm),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(LayoutConstants.borderRadiusSm),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.itemsToDelete.length,
                itemBuilder: (context, index) {
                  final item = widget.itemsToDelete[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      _getIconForType(item.type),
                      size: 20,
                      color: _getColorForType(item.type, theme),
                    ),
                    title: Text(
                      item.name,
                      style: theme.textTheme.bodyMedium,
                    ),
                    subtitle: item.children.isNotEmpty
                      ? Text(
                          '${item.children.length} child item(s)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        )
                      : null,
                  );
                },
              ),
            ),
            const SizedBox(height: LayoutConstants.spacingLg),
            
            // Child items handling options
            if (_hasChildItems()) ...[
              Text(
                'What should happen to child items?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: LayoutConstants.spacingSm),
              RadioListTile<bool>(
                value: true,
                groupValue: _deleteChildren,
                onChanged: _isLoading ? null : (value) {
                  setState(() {
                    _deleteChildren = value ?? true;
                    _reassignToId = null;
                    _reassignToType = null;
                  });
                },
                title: const Text('Delete all child items'),
                subtitle: Text(
                  'All nested items will be permanently deleted',
                  style: theme.textTheme.bodySmall,
                ),
                dense: true,
              ),
              RadioListTile<bool>(
                value: false,
                groupValue: _deleteChildren,
                onChanged: _isLoading ? null : (value) {
                  setState(() {
                    _deleteChildren = value ?? true;
                  });
                },
                title: const Text('Reassign child items'),
                subtitle: Text(
                  'Move child items to another parent or make them standalone',
                  style: theme.textTheme.bodySmall,
                ),
                dense: true,
              ),
              
              // Reassignment target selection
              if (!_deleteChildren) ...[
                const SizedBox(height: LayoutConstants.spacingMd),
                hierarchyAsync.when(
                  data: (hierarchy) {
                    final validTargets = _getValidReassignmentTargets(hierarchy);
                    
                    return DropdownButtonFormField<String>(
                      value: _reassignToId != null 
                        ? '${_reassignToId}:${_reassignToType?.name ?? ''}' 
                        : 'standalone',
                      decoration: const InputDecoration(
                        labelText: 'Reassign to',
                        prefixIcon: Icon(Icons.folder_special),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: 'standalone',
                          child: Text('Make Standalone (No Parent)'),
                        ),
                        ...validTargets.map((target) => DropdownMenuItem<String>(
                          value: '${target.id}:${target.type.name}',
                          child: Row(
                            children: [
                              Icon(
                                _getIconForType(target.type),
                                size: 16,
                                color: _getColorForType(target.type, theme),
                              ),
                              const SizedBox(width: 8),
                              Text(target.name),
                            ],
                          ),
                        )),
                      ],
                      onChanged: _isLoading ? null : (value) {
                        setState(() {
                          if (value == 'standalone') {
                            _reassignToId = null;
                            _reassignToType = null;
                          } else if (value != null) {
                            final parts = value.split(':');
                            _reassignToId = parts[0];
                            _reassignToType = _parseItemType(parts[1]);
                          }
                        });
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => Text(
                    'Failed to load reassignment targets',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
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
              : const Icon(Icons.delete_forever),
          label: Text(_isLoading ? 'Deleting...' : 'Delete'),
        ),
      ],
    );
  }
  
  int _calculateTotalAffected() {
    int total = widget.itemsToDelete.length;
    
    void countChildren(List<HierarchyItem> items) {
      for (final item in items) {
        total += item.children.length;
        if (item.children.isNotEmpty) {
          countChildren(item.children);
        }
      }
    }
    
    countChildren(widget.itemsToDelete);
    return total;
  }
  
  bool _hasChildItems() {
    return widget.itemsToDelete.any((item) => item.children.isNotEmpty);
  }
  
  List<HierarchyItem> _getValidReassignmentTargets(List<HierarchyItem> hierarchy) {
    final List<HierarchyItem> targets = [];
    final deletedIds = widget.itemsToDelete.map((item) => item.id).toSet();
    
    void addValidTargets(List<HierarchyItem> items) {
      for (final item in items) {
        // Can't reassign to items being deleted or their children
        if (!deletedIds.contains(item.id) && !_isChildOfDeleted(item.id)) {
          targets.add(item);
        }
        
        if (item.children.isNotEmpty) {
          addValidTargets(item.children);
        }
      }
    }
    
    addValidTargets(hierarchy);
    return targets;
  }
  
  bool _isChildOfDeleted(String itemId) {
    bool isChild(List<HierarchyItem> items) {
      for (final item in items) {
        if (item.children.any((child) => child.id == itemId)) {
          return true;
        }
        if (isChild(item.children)) {
          return true;
        }
      }
      return false;
    }
    
    return isChild(widget.itemsToDelete);
  }
  
  IconData _getIconForType(HierarchyItemType type) {
    switch (type) {
      case HierarchyItemType.portfolio:
        return Icons.business_center;
      case HierarchyItemType.program:
        return Icons.category;
      case HierarchyItemType.project:
        return Icons.folder;
    }
  }
  
  Color _getColorForType(HierarchyItemType type, ThemeData theme) {
    switch (type) {
      case HierarchyItemType.portfolio:
        return theme.colorScheme.primary;
      case HierarchyItemType.program:
        return theme.colorScheme.tertiary;
      case HierarchyItemType.project:
        return theme.colorScheme.secondary;
    }
  }
  
  HierarchyItemType _parseItemType(String type) {
    switch (type) {
      case 'portfolio':
        return HierarchyItemType.portfolio;
      case 'program':
        return HierarchyItemType.program;
      case 'project':
        return HierarchyItemType.project;
      default:
        return HierarchyItemType.project;
    }
  }
  
  Future<void> _handleDelete() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Prepare items data for bulk delete
      final itemsData = widget.itemsToDelete.map((item) => {
        'id': item.id,
        'type': item.type.name,
      }).toList();
      
      // Call bulk delete API
      final result = await ref.read(hierarchyStateProvider().notifier).bulkDeleteItems(
        items: itemsData,
        deleteChildren: _deleteChildren,
        reassignToId: _reassignToId,
        reassignToType: _reassignToType?.name,
      );
      
      if (mounted) {
        Navigator.of(context).pop(true);
        ref.read(notificationServiceProvider.notifier).showSuccess(
          'Successfully deleted ${result['deleted_count']} item(s)',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ref.read(notificationServiceProvider.notifier).showError('Failed to delete items: ${e.toString()}');
      }
    }
  }
}