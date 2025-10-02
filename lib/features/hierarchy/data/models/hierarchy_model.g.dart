// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hierarchy_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HierarchyResponseImpl _$$HierarchyResponseImplFromJson(
  Map<String, dynamic> json,
) => _$HierarchyResponseImpl(
  hierarchy: (json['hierarchy'] as List<dynamic>)
      .map((e) => HierarchyNodeModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  includeArchived: json['include_archived'] as bool? ?? false,
  totalPortfolios: (json['total_portfolios'] as num?)?.toInt() ?? 0,
  hasOrphanedItems: json['has_orphaned_items'] as bool? ?? false,
);

Map<String, dynamic> _$$HierarchyResponseImplToJson(
  _$HierarchyResponseImpl instance,
) => <String, dynamic>{
  'hierarchy': instance.hierarchy,
  'include_archived': instance.includeArchived,
  'total_portfolios': instance.totalPortfolios,
  'has_orphaned_items': instance.hasOrphanedItems,
};

_$HierarchyNodeModelImpl _$$HierarchyNodeModelImplFromJson(
  Map<String, dynamic> json,
) => _$HierarchyNodeModelImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  type: json['type'] as String,
  portfolioId: json['portfolio_id'] as String?,
  programId: json['program_id'] as String?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  status: json['status'] as String?,
  memberCount: (json['member_count'] as num?)?.toInt(),
  children:
      (json['children'] as List<dynamic>?)
          ?.map((e) => HierarchyNodeModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  programs:
      (json['programs'] as List<dynamic>?)
          ?.map((e) => HierarchyNodeModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  directProjects:
      (json['direct_projects'] as List<dynamic>?)
          ?.map((e) => HierarchyNodeModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  projects:
      (json['projects'] as List<dynamic>?)
          ?.map((e) => HierarchyNodeModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$HierarchyNodeModelImplToJson(
  _$HierarchyNodeModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'type': instance.type,
  'portfolio_id': instance.portfolioId,
  'program_id': instance.programId,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'status': instance.status,
  'member_count': instance.memberCount,
  'children': instance.children,
  'programs': instance.programs,
  'direct_projects': instance.directProjects,
  'projects': instance.projects,
};

_$MoveItemRequestImpl _$$MoveItemRequestImplFromJson(
  Map<String, dynamic> json,
) => _$MoveItemRequestImpl(
  itemId: json['item_id'] as String,
  itemType: json['item_type'] as String,
  targetParentId: json['target_parent_id'] as String?,
  targetParentType: json['target_parent_type'] as String?,
);

Map<String, dynamic> _$$MoveItemRequestImplToJson(
  _$MoveItemRequestImpl instance,
) => <String, dynamic>{
  'item_id': instance.itemId,
  'item_type': instance.itemType,
  'target_parent_id': instance.targetParentId,
  'target_parent_type': instance.targetParentType,
};

_$BulkMoveRequestImpl _$$BulkMoveRequestImplFromJson(
  Map<String, dynamic> json,
) => _$BulkMoveRequestImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => MoveItemData.fromJson(e as Map<String, dynamic>))
      .toList(),
  targetParentId: json['target_parent_id'] as String?,
  targetParentType: json['target_parent_type'] as String?,
);

Map<String, dynamic> _$$BulkMoveRequestImplToJson(
  _$BulkMoveRequestImpl instance,
) => <String, dynamic>{
  'items': instance.items,
  'target_parent_id': instance.targetParentId,
  'target_parent_type': instance.targetParentType,
};

_$MoveItemDataImpl _$$MoveItemDataImplFromJson(Map<String, dynamic> json) =>
    _$MoveItemDataImpl(id: json['id'] as String, type: json['type'] as String);

Map<String, dynamic> _$$MoveItemDataImplToJson(_$MoveItemDataImpl instance) =>
    <String, dynamic>{'id': instance.id, 'type': instance.type};

_$MoveItemResponseImpl _$$MoveItemResponseImplFromJson(
  Map<String, dynamic> json,
) => _$MoveItemResponseImpl(
  success: json['success'] as bool,
  message: json['message'] as String,
  item: HierarchyNodeModel.fromJson(json['item'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$MoveItemResponseImplToJson(
  _$MoveItemResponseImpl instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'item': instance.item,
};

_$BulkMoveResponseImpl _$$BulkMoveResponseImplFromJson(
  Map<String, dynamic> json,
) => _$BulkMoveResponseImpl(
  message: json['message'] as String,
  results: BulkMoveResults.fromJson(json['results'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$BulkMoveResponseImplToJson(
  _$BulkMoveResponseImpl instance,
) => <String, dynamic>{
  'message': instance.message,
  'results': instance.results,
};

_$BulkMoveResultsImpl _$$BulkMoveResultsImplFromJson(
  Map<String, dynamic> json,
) => _$BulkMoveResultsImpl(
  successCount: (json['success_count'] as num).toInt(),
  errorCount: (json['error_count'] as num).toInt(),
  errors:
      (json['errors'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      const [],
  movedItems:
      (json['moved_items'] as List<dynamic>?)
          ?.map((e) => HierarchyNodeModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$BulkMoveResultsImplToJson(
  _$BulkMoveResultsImpl instance,
) => <String, dynamic>{
  'success_count': instance.successCount,
  'error_count': instance.errorCount,
  'errors': instance.errors,
  'moved_items': instance.movedItems,
};

_$BulkDeleteRequestImpl _$$BulkDeleteRequestImplFromJson(
  Map<String, dynamic> json,
) => _$BulkDeleteRequestImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => MoveItemData.fromJson(e as Map<String, dynamic>))
      .toList(),
  deleteChildren: json['delete_children'] as bool,
  reassignToId: json['reassign_to_id'] as String?,
  reassignToType: json['reassign_to_type'] as String?,
);

Map<String, dynamic> _$$BulkDeleteRequestImplToJson(
  _$BulkDeleteRequestImpl instance,
) => <String, dynamic>{
  'items': instance.items,
  'delete_children': instance.deleteChildren,
  'reassign_to_id': instance.reassignToId,
  'reassign_to_type': instance.reassignToType,
};

_$BulkDeleteResponseImpl _$$BulkDeleteResponseImplFromJson(
  Map<String, dynamic> json,
) => _$BulkDeleteResponseImpl(
  message: json['message'] as String,
  results: BulkDeleteResults.fromJson(json['results'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$BulkDeleteResponseImplToJson(
  _$BulkDeleteResponseImpl instance,
) => <String, dynamic>{
  'message': instance.message,
  'results': instance.results,
};

_$BulkDeleteResultsImpl _$$BulkDeleteResultsImplFromJson(
  Map<String, dynamic> json,
) => _$BulkDeleteResultsImpl(
  deletedCount: (json['deleted_count'] as num).toInt(),
  reassignedCount: (json['reassigned_count'] as num?)?.toInt(),
  errorCount: (json['error_count'] as num).toInt(),
  errors:
      (json['errors'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      const [],
);

Map<String, dynamic> _$$BulkDeleteResultsImplToJson(
  _$BulkDeleteResultsImpl instance,
) => <String, dynamic>{
  'deleted_count': instance.deletedCount,
  'reassigned_count': instance.reassignedCount,
  'error_count': instance.errorCount,
  'errors': instance.errors,
};
