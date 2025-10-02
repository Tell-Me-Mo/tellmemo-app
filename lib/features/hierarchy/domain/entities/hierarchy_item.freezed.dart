// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hierarchy_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$HierarchyItem {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  HierarchyItemType get type => throw _privateConstructorUsedError;
  String? get portfolioId => throw _privateConstructorUsedError;
  String? get programId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  List<HierarchyItem> get children => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  /// Create a copy of HierarchyItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HierarchyItemCopyWith<HierarchyItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HierarchyItemCopyWith<$Res> {
  factory $HierarchyItemCopyWith(
    HierarchyItem value,
    $Res Function(HierarchyItem) then,
  ) = _$HierarchyItemCopyWithImpl<$Res, HierarchyItem>;
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    HierarchyItemType type,
    String? portfolioId,
    String? programId,
    DateTime createdAt,
    DateTime updatedAt,
    List<HierarchyItem> children,
    Map<String, dynamic>? metadata,
  });
}

/// @nodoc
class _$HierarchyItemCopyWithImpl<$Res, $Val extends HierarchyItem>
    implements $HierarchyItemCopyWith<$Res> {
  _$HierarchyItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HierarchyItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? type = null,
    Object? portfolioId = freezed,
    Object? programId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? children = null,
    Object? metadata = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as HierarchyItemType,
            portfolioId: freezed == portfolioId
                ? _value.portfolioId
                : portfolioId // ignore: cast_nullable_to_non_nullable
                      as String?,
            programId: freezed == programId
                ? _value.programId
                : programId // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            children: null == children
                ? _value.children
                : children // ignore: cast_nullable_to_non_nullable
                      as List<HierarchyItem>,
            metadata: freezed == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HierarchyItemImplCopyWith<$Res>
    implements $HierarchyItemCopyWith<$Res> {
  factory _$$HierarchyItemImplCopyWith(
    _$HierarchyItemImpl value,
    $Res Function(_$HierarchyItemImpl) then,
  ) = __$$HierarchyItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    HierarchyItemType type,
    String? portfolioId,
    String? programId,
    DateTime createdAt,
    DateTime updatedAt,
    List<HierarchyItem> children,
    Map<String, dynamic>? metadata,
  });
}

/// @nodoc
class __$$HierarchyItemImplCopyWithImpl<$Res>
    extends _$HierarchyItemCopyWithImpl<$Res, _$HierarchyItemImpl>
    implements _$$HierarchyItemImplCopyWith<$Res> {
  __$$HierarchyItemImplCopyWithImpl(
    _$HierarchyItemImpl _value,
    $Res Function(_$HierarchyItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HierarchyItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? type = null,
    Object? portfolioId = freezed,
    Object? programId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? children = null,
    Object? metadata = freezed,
  }) {
    return _then(
      _$HierarchyItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as HierarchyItemType,
        portfolioId: freezed == portfolioId
            ? _value.portfolioId
            : portfolioId // ignore: cast_nullable_to_non_nullable
                  as String?,
        programId: freezed == programId
            ? _value.programId
            : programId // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        children: null == children
            ? _value._children
            : children // ignore: cast_nullable_to_non_nullable
                  as List<HierarchyItem>,
        metadata: freezed == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc

class _$HierarchyItemImpl extends _HierarchyItem {
  const _$HierarchyItemImpl({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.portfolioId,
    this.programId,
    required this.createdAt,
    required this.updatedAt,
    final List<HierarchyItem> children = const [],
    final Map<String, dynamic>? metadata,
  }) : _children = children,
       _metadata = metadata,
       super._();

  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  final HierarchyItemType type;
  @override
  final String? portfolioId;
  @override
  final String? programId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  final List<HierarchyItem> _children;
  @override
  @JsonKey()
  List<HierarchyItem> get children {
    if (_children is EqualUnmodifiableListView) return _children;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_children);
  }

  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'HierarchyItem(id: $id, name: $name, description: $description, type: $type, portfolioId: $portfolioId, programId: $programId, createdAt: $createdAt, updatedAt: $updatedAt, children: $children, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HierarchyItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.portfolioId, portfolioId) ||
                other.portfolioId == portfolioId) &&
            (identical(other.programId, programId) ||
                other.programId == programId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other._children, _children) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    type,
    portfolioId,
    programId,
    createdAt,
    updatedAt,
    const DeepCollectionEquality().hash(_children),
    const DeepCollectionEquality().hash(_metadata),
  );

  /// Create a copy of HierarchyItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HierarchyItemImplCopyWith<_$HierarchyItemImpl> get copyWith =>
      __$$HierarchyItemImplCopyWithImpl<_$HierarchyItemImpl>(this, _$identity);
}

abstract class _HierarchyItem extends HierarchyItem {
  const factory _HierarchyItem({
    required final String id,
    required final String name,
    final String? description,
    required final HierarchyItemType type,
    final String? portfolioId,
    final String? programId,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final List<HierarchyItem> children,
    final Map<String, dynamic>? metadata,
  }) = _$HierarchyItemImpl;
  const _HierarchyItem._() : super._();

  @override
  String get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  HierarchyItemType get type;
  @override
  String? get portfolioId;
  @override
  String? get programId;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  List<HierarchyItem> get children;
  @override
  Map<String, dynamic>? get metadata;

  /// Create a copy of HierarchyItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HierarchyItemImplCopyWith<_$HierarchyItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$HierarchyBreadcrumb {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  HierarchyItemType get type => throw _privateConstructorUsedError;

  /// Create a copy of HierarchyBreadcrumb
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HierarchyBreadcrumbCopyWith<HierarchyBreadcrumb> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HierarchyBreadcrumbCopyWith<$Res> {
  factory $HierarchyBreadcrumbCopyWith(
    HierarchyBreadcrumb value,
    $Res Function(HierarchyBreadcrumb) then,
  ) = _$HierarchyBreadcrumbCopyWithImpl<$Res, HierarchyBreadcrumb>;
  @useResult
  $Res call({String id, String name, HierarchyItemType type});
}

/// @nodoc
class _$HierarchyBreadcrumbCopyWithImpl<$Res, $Val extends HierarchyBreadcrumb>
    implements $HierarchyBreadcrumbCopyWith<$Res> {
  _$HierarchyBreadcrumbCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HierarchyBreadcrumb
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? type = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as HierarchyItemType,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HierarchyBreadcrumbImplCopyWith<$Res>
    implements $HierarchyBreadcrumbCopyWith<$Res> {
  factory _$$HierarchyBreadcrumbImplCopyWith(
    _$HierarchyBreadcrumbImpl value,
    $Res Function(_$HierarchyBreadcrumbImpl) then,
  ) = __$$HierarchyBreadcrumbImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, HierarchyItemType type});
}

/// @nodoc
class __$$HierarchyBreadcrumbImplCopyWithImpl<$Res>
    extends _$HierarchyBreadcrumbCopyWithImpl<$Res, _$HierarchyBreadcrumbImpl>
    implements _$$HierarchyBreadcrumbImplCopyWith<$Res> {
  __$$HierarchyBreadcrumbImplCopyWithImpl(
    _$HierarchyBreadcrumbImpl _value,
    $Res Function(_$HierarchyBreadcrumbImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HierarchyBreadcrumb
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? type = null}) {
    return _then(
      _$HierarchyBreadcrumbImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as HierarchyItemType,
      ),
    );
  }
}

/// @nodoc

class _$HierarchyBreadcrumbImpl implements _HierarchyBreadcrumb {
  const _$HierarchyBreadcrumbImpl({
    required this.id,
    required this.name,
    required this.type,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final HierarchyItemType type;

  @override
  String toString() {
    return 'HierarchyBreadcrumb(id: $id, name: $name, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HierarchyBreadcrumbImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, name, type);

  /// Create a copy of HierarchyBreadcrumb
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HierarchyBreadcrumbImplCopyWith<_$HierarchyBreadcrumbImpl> get copyWith =>
      __$$HierarchyBreadcrumbImplCopyWithImpl<_$HierarchyBreadcrumbImpl>(
        this,
        _$identity,
      );
}

abstract class _HierarchyBreadcrumb implements HierarchyBreadcrumb {
  const factory _HierarchyBreadcrumb({
    required final String id,
    required final String name,
    required final HierarchyItemType type,
  }) = _$HierarchyBreadcrumbImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  HierarchyItemType get type;

  /// Create a copy of HierarchyBreadcrumb
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HierarchyBreadcrumbImplCopyWith<_$HierarchyBreadcrumbImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$HierarchyStatistics {
  int get portfolioCount => throw _privateConstructorUsedError;
  int get programCount => throw _privateConstructorUsedError;
  int get projectCount => throw _privateConstructorUsedError;
  int get standaloneCount => throw _privateConstructorUsedError;
  int get totalCount => throw _privateConstructorUsedError;

  /// Create a copy of HierarchyStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HierarchyStatisticsCopyWith<HierarchyStatistics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HierarchyStatisticsCopyWith<$Res> {
  factory $HierarchyStatisticsCopyWith(
    HierarchyStatistics value,
    $Res Function(HierarchyStatistics) then,
  ) = _$HierarchyStatisticsCopyWithImpl<$Res, HierarchyStatistics>;
  @useResult
  $Res call({
    int portfolioCount,
    int programCount,
    int projectCount,
    int standaloneCount,
    int totalCount,
  });
}

/// @nodoc
class _$HierarchyStatisticsCopyWithImpl<$Res, $Val extends HierarchyStatistics>
    implements $HierarchyStatisticsCopyWith<$Res> {
  _$HierarchyStatisticsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HierarchyStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? portfolioCount = null,
    Object? programCount = null,
    Object? projectCount = null,
    Object? standaloneCount = null,
    Object? totalCount = null,
  }) {
    return _then(
      _value.copyWith(
            portfolioCount: null == portfolioCount
                ? _value.portfolioCount
                : portfolioCount // ignore: cast_nullable_to_non_nullable
                      as int,
            programCount: null == programCount
                ? _value.programCount
                : programCount // ignore: cast_nullable_to_non_nullable
                      as int,
            projectCount: null == projectCount
                ? _value.projectCount
                : projectCount // ignore: cast_nullable_to_non_nullable
                      as int,
            standaloneCount: null == standaloneCount
                ? _value.standaloneCount
                : standaloneCount // ignore: cast_nullable_to_non_nullable
                      as int,
            totalCount: null == totalCount
                ? _value.totalCount
                : totalCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HierarchyStatisticsImplCopyWith<$Res>
    implements $HierarchyStatisticsCopyWith<$Res> {
  factory _$$HierarchyStatisticsImplCopyWith(
    _$HierarchyStatisticsImpl value,
    $Res Function(_$HierarchyStatisticsImpl) then,
  ) = __$$HierarchyStatisticsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int portfolioCount,
    int programCount,
    int projectCount,
    int standaloneCount,
    int totalCount,
  });
}

/// @nodoc
class __$$HierarchyStatisticsImplCopyWithImpl<$Res>
    extends _$HierarchyStatisticsCopyWithImpl<$Res, _$HierarchyStatisticsImpl>
    implements _$$HierarchyStatisticsImplCopyWith<$Res> {
  __$$HierarchyStatisticsImplCopyWithImpl(
    _$HierarchyStatisticsImpl _value,
    $Res Function(_$HierarchyStatisticsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HierarchyStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? portfolioCount = null,
    Object? programCount = null,
    Object? projectCount = null,
    Object? standaloneCount = null,
    Object? totalCount = null,
  }) {
    return _then(
      _$HierarchyStatisticsImpl(
        portfolioCount: null == portfolioCount
            ? _value.portfolioCount
            : portfolioCount // ignore: cast_nullable_to_non_nullable
                  as int,
        programCount: null == programCount
            ? _value.programCount
            : programCount // ignore: cast_nullable_to_non_nullable
                  as int,
        projectCount: null == projectCount
            ? _value.projectCount
            : projectCount // ignore: cast_nullable_to_non_nullable
                  as int,
        standaloneCount: null == standaloneCount
            ? _value.standaloneCount
            : standaloneCount // ignore: cast_nullable_to_non_nullable
                  as int,
        totalCount: null == totalCount
            ? _value.totalCount
            : totalCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$HierarchyStatisticsImpl implements _HierarchyStatistics {
  const _$HierarchyStatisticsImpl({
    required this.portfolioCount,
    required this.programCount,
    required this.projectCount,
    required this.standaloneCount,
    required this.totalCount,
  });

  @override
  final int portfolioCount;
  @override
  final int programCount;
  @override
  final int projectCount;
  @override
  final int standaloneCount;
  @override
  final int totalCount;

  @override
  String toString() {
    return 'HierarchyStatistics(portfolioCount: $portfolioCount, programCount: $programCount, projectCount: $projectCount, standaloneCount: $standaloneCount, totalCount: $totalCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HierarchyStatisticsImpl &&
            (identical(other.portfolioCount, portfolioCount) ||
                other.portfolioCount == portfolioCount) &&
            (identical(other.programCount, programCount) ||
                other.programCount == programCount) &&
            (identical(other.projectCount, projectCount) ||
                other.projectCount == projectCount) &&
            (identical(other.standaloneCount, standaloneCount) ||
                other.standaloneCount == standaloneCount) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    portfolioCount,
    programCount,
    projectCount,
    standaloneCount,
    totalCount,
  );

  /// Create a copy of HierarchyStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HierarchyStatisticsImplCopyWith<_$HierarchyStatisticsImpl> get copyWith =>
      __$$HierarchyStatisticsImplCopyWithImpl<_$HierarchyStatisticsImpl>(
        this,
        _$identity,
      );
}

abstract class _HierarchyStatistics implements HierarchyStatistics {
  const factory _HierarchyStatistics({
    required final int portfolioCount,
    required final int programCount,
    required final int projectCount,
    required final int standaloneCount,
    required final int totalCount,
  }) = _$HierarchyStatisticsImpl;

  @override
  int get portfolioCount;
  @override
  int get programCount;
  @override
  int get projectCount;
  @override
  int get standaloneCount;
  @override
  int get totalCount;

  /// Create a copy of HierarchyStatistics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HierarchyStatisticsImplCopyWith<_$HierarchyStatisticsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
