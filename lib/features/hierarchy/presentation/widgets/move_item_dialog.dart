import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/hierarchy_providers.dart';
import '../../domain/entities/hierarchy_item.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/utils/animation_utils.dart';
import '../../../../core/services/notification_service.dart';

class MoveItemDialog extends ConsumerStatefulWidget {
  final String itemId;
  final String itemName;
  final HierarchyItemType itemType;
  final String? currentParentId;
  
  const MoveItemDialog({
    super.key,
    required this.itemId,
    required this.itemName,
    required this.itemType,
    this.currentParentId,
  });

  @override
  ConsumerState<MoveItemDialog> createState() => _MoveItemDialogState();
}

class _MoveItemDialogState extends ConsumerState<MoveItemDialog> 
    with SingleTickerProviderStateMixin {
  String? _selectedTargetId;
  HierarchyItemType? _selectedTargetType;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: UIConstants.normalAnimation,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: UIConstants.defaultCurve,
    );
    _animationController.forward();
    
    // Initialize with current parent if exists, but in the proper format
    if (widget.currentParentId != null) {
      // Don't set initial value - let user select
      _selectedTargetId = null;
      _selectedTargetType = null;
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hierarchyAsync = ref.watch(hierarchyStateProvider());
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _fadeAnimation,
        child: AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.drive_file_move_outline,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: LayoutConstants.spacingSm),
          const Text('Move Item'),
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
                  const TextSpan(text: 'Move '),
                  TextSpan(
                    text: '"${widget.itemName}"',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' to:'),
                ],
              ),
            ),
            const SizedBox(height: LayoutConstants.spacingMd),
            
            // Target selection
            hierarchyAsync.when(
              data: (hierarchy) {
                final validTargets = _getValidTargets(hierarchy);
                
                if (validTargets.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(LayoutConstants.spacingMd),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(LayoutConstants.borderRadiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: LayoutConstants.spacingSm),
                        Expanded(
                          child: Text(
                            'No valid targets available for this item',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                // Build dropdown items first
                final dropdownItems = <DropdownMenuItem<String>>[
                  const DropdownMenuItem<String>(
                    value: 'root',
                    child: Text('Top Level (No Parent)'),
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
                ];
                
                // Store dropdown value separately from the actual IDs
                String? dropdownValue;
                if (_selectedTargetId != null && _selectedTargetType != null) {
                  // Format the value correctly for existing selection
                  final formattedValue = '${_selectedTargetId}:${_selectedTargetType!.name}';
                  // Only use the value if it exists in the dropdown items
                  if (dropdownItems.any((item) => item.value == formattedValue)) {
                    dropdownValue = formattedValue;
                  }
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: dropdownValue,
                      decoration: const InputDecoration(
                        labelText: 'Select Target',
                        prefixIcon: Icon(Icons.folder_open),
                        border: OutlineInputBorder(),
                      ),
                      items: dropdownItems,
                      onChanged: _isLoading ? null : (value) {
                        setState(() {
                          if (value == 'root') {
                            _selectedTargetId = null;
                            _selectedTargetType = null;
                          } else if (value != null) {
                            final parts = value.split(':');
                            _selectedTargetId = parts[0];
                            _selectedTargetType = _parseItemType(parts[1]);
                          } else {
                            _selectedTargetId = null;
                            _selectedTargetType = null;
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null && widget.currentParentId == null) {
                          return 'Item is already at the top level';
                        }
                        if (value != null && value != 'root') {
                          final parts = value.split(':');
                          if (parts[0] == widget.currentParentId) {
                            return 'Item is already in this location';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: LayoutConstants.spacingMd),
                    
                    // Information about the move
                    Container(
                      padding: const EdgeInsets.all(LayoutConstants.spacingMd),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(LayoutConstants.borderRadiusMd),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: LayoutConstants.spacingSm),
                          Expanded(
                            child: Text(
                              _getMoveDescription(),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Text(
                'Failed to load hierarchy: ${error.toString()}',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isLoading || (_selectedTargetId == null && _selectedTargetType == null && widget.currentParentId == null)
              ? null
              : _handleMove,
          icon: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.drive_file_move),
          label: Text(_isLoading ? 'Moving...' : 'Move'),
        ),
      ],
    ),
      ),
    );
  }
  
  List<HierarchyItem> _getValidTargets(List<HierarchyItem> hierarchy) {
    final List<HierarchyItem> targets = [];
    final Set<String> addedIds = {}; // Track added IDs to avoid duplicates
    
    void addValidTargets(List<HierarchyItem> items) {
      for (final item in items) {
        // Can't move item to itself or its descendants
        if (item.id == widget.itemId) {
          continue;
        }
        
        // Check if this is a valid target based on item types
        if (_isValidTarget(item) && !addedIds.contains(item.id)) {
          targets.add(item);
          addedIds.add(item.id);
        }
        
        // Recursively add children as potential targets
        if (item.children.isNotEmpty) {
          addValidTargets(item.children);
        }
      }
    }
    
    addValidTargets(hierarchy);
    return targets;
  }
  
  bool _isValidTarget(HierarchyItem target) {
    // Don't allow moving to current parent
    if (target.id == widget.currentParentId) {
      return false;
    }

    // Define valid parent-child relationships
    switch (widget.itemType) {
      case HierarchyItemType.portfolio:
        // Portfolios can only be at root level
        return false;
      case HierarchyItemType.program:
        // Programs can be under portfolios or root
        return target.type == HierarchyItemType.portfolio;
      case HierarchyItemType.project:
        // Projects can be under programs, portfolios, or root
        return target.type == HierarchyItemType.program ||
               target.type == HierarchyItemType.portfolio;
    }
  }
  
  String _getMoveDescription() {
    if (_selectedTargetId == null) {
      return 'This will move the ${widget.itemType.name} to the top level with no parent.';
    }
    
    String targetTypeName = _selectedTargetType?.name ?? 'location';
    return 'This will move the ${widget.itemType.name} and all its children to the selected $targetTypeName.';
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
  
  Future<void> _handleMove() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await ref.read(hierarchyStateProvider().notifier).moveItem(
        itemId: widget.itemId,
        itemType: widget.itemType.name,
        targetParentId: _selectedTargetId,
        targetParentType: _selectedTargetType?.name,
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        ref.read(notificationServiceProvider.notifier).showSuccess('${widget.itemName} moved successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ref.read(notificationServiceProvider.notifier).showError('Failed to move item: ${e.toString()}');
      }
    }
  }
}