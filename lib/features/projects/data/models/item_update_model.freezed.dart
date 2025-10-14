// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_update_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ItemUpdateModel _$ItemUpdateModelFromJson(Map<String, dynamic> json) {
  return _ItemUpdateModel.fromJson(json);
}

/// @nodoc
mixin _$ItemUpdateModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_id')
  String get itemId => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_type')
  String get itemType => throw _privateConstructorUsedError;
  @JsonKey(name: 'project_id')
  String get projectId => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  @JsonKey(name: 'author_name')
  String get authorName => throw _privateConstructorUsedError;
  @JsonKey(name: 'author_email')
  String? get authorEmail => throw _privateConstructorUsedError;
  String get timestamp => throw _privateConstructorUsedError;
  @JsonKey(name: 'update_type')
  String get updateType => throw _privateConstructorUsedError;

  /// Serializes this ItemUpdateModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ItemUpdateModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItemUpdateModelCopyWith<ItemUpdateModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemUpdateModelCopyWith<$Res> {
  factory $ItemUpdateModelCopyWith(
    ItemUpdateModel value,
    $Res Function(ItemUpdateModel) then,
  ) = _$ItemUpdateModelCopyWithImpl<$Res, ItemUpdateModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'item_id') String itemId,
    @JsonKey(name: 'item_type') String itemType,
    @JsonKey(name: 'project_id') String projectId,
    String content,
    @JsonKey(name: 'author_name') String authorName,
    @JsonKey(name: 'author_email') String? authorEmail,
    String timestamp,
    @JsonKey(name: 'update_type') String updateType,
  });
}

/// @nodoc
class _$ItemUpdateModelCopyWithImpl<$Res, $Val extends ItemUpdateModel>
    implements $ItemUpdateModelCopyWith<$Res> {
  _$ItemUpdateModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItemUpdateModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? itemId = null,
    Object? itemType = null,
    Object? projectId = null,
    Object? content = null,
    Object? authorName = null,
    Object? authorEmail = freezed,
    Object? timestamp = null,
    Object? updateType = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            itemId: null == itemId
                ? _value.itemId
                : itemId // ignore: cast_nullable_to_non_nullable
                      as String,
            itemType: null == itemType
                ? _value.itemType
                : itemType // ignore: cast_nullable_to_non_nullable
                      as String,
            projectId: null == projectId
                ? _value.projectId
                : projectId // ignore: cast_nullable_to_non_nullable
                      as String,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            authorName: null == authorName
                ? _value.authorName
                : authorName // ignore: cast_nullable_to_non_nullable
                      as String,
            authorEmail: freezed == authorEmail
                ? _value.authorEmail
                : authorEmail // ignore: cast_nullable_to_non_nullable
                      as String?,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as String,
            updateType: null == updateType
                ? _value.updateType
                : updateType // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ItemUpdateModelImplCopyWith<$Res>
    implements $ItemUpdateModelCopyWith<$Res> {
  factory _$$ItemUpdateModelImplCopyWith(
    _$ItemUpdateModelImpl value,
    $Res Function(_$ItemUpdateModelImpl) then,
  ) = __$$ItemUpdateModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'item_id') String itemId,
    @JsonKey(name: 'item_type') String itemType,
    @JsonKey(name: 'project_id') String projectId,
    String content,
    @JsonKey(name: 'author_name') String authorName,
    @JsonKey(name: 'author_email') String? authorEmail,
    String timestamp,
    @JsonKey(name: 'update_type') String updateType,
  });
}

/// @nodoc
class __$$ItemUpdateModelImplCopyWithImpl<$Res>
    extends _$ItemUpdateModelCopyWithImpl<$Res, _$ItemUpdateModelImpl>
    implements _$$ItemUpdateModelImplCopyWith<$Res> {
  __$$ItemUpdateModelImplCopyWithImpl(
    _$ItemUpdateModelImpl _value,
    $Res Function(_$ItemUpdateModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ItemUpdateModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? itemId = null,
    Object? itemType = null,
    Object? projectId = null,
    Object? content = null,
    Object? authorName = null,
    Object? authorEmail = freezed,
    Object? timestamp = null,
    Object? updateType = null,
  }) {
    return _then(
      _$ItemUpdateModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        itemId: null == itemId
            ? _value.itemId
            : itemId // ignore: cast_nullable_to_non_nullable
                  as String,
        itemType: null == itemType
            ? _value.itemType
            : itemType // ignore: cast_nullable_to_non_nullable
                  as String,
        projectId: null == projectId
            ? _value.projectId
            : projectId // ignore: cast_nullable_to_non_nullable
                  as String,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        authorName: null == authorName
            ? _value.authorName
            : authorName // ignore: cast_nullable_to_non_nullable
                  as String,
        authorEmail: freezed == authorEmail
            ? _value.authorEmail
            : authorEmail // ignore: cast_nullable_to_non_nullable
                  as String?,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as String,
        updateType: null == updateType
            ? _value.updateType
            : updateType // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ItemUpdateModelImpl implements _ItemUpdateModel {
  const _$ItemUpdateModelImpl({
    required this.id,
    @JsonKey(name: 'item_id') required this.itemId,
    @JsonKey(name: 'item_type') required this.itemType,
    @JsonKey(name: 'project_id') required this.projectId,
    required this.content,
    @JsonKey(name: 'author_name') required this.authorName,
    @JsonKey(name: 'author_email') this.authorEmail,
    required this.timestamp,
    @JsonKey(name: 'update_type') required this.updateType,
  });

  factory _$ItemUpdateModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItemUpdateModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'item_id')
  final String itemId;
  @override
  @JsonKey(name: 'item_type')
  final String itemType;
  @override
  @JsonKey(name: 'project_id')
  final String projectId;
  @override
  final String content;
  @override
  @JsonKey(name: 'author_name')
  final String authorName;
  @override
  @JsonKey(name: 'author_email')
  final String? authorEmail;
  @override
  final String timestamp;
  @override
  @JsonKey(name: 'update_type')
  final String updateType;

  @override
  String toString() {
    return 'ItemUpdateModel(id: $id, itemId: $itemId, itemType: $itemType, projectId: $projectId, content: $content, authorName: $authorName, authorEmail: $authorEmail, timestamp: $timestamp, updateType: $updateType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItemUpdateModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.itemType, itemType) ||
                other.itemType == itemType) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.authorName, authorName) ||
                other.authorName == authorName) &&
            (identical(other.authorEmail, authorEmail) ||
                other.authorEmail == authorEmail) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.updateType, updateType) ||
                other.updateType == updateType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    itemId,
    itemType,
    projectId,
    content,
    authorName,
    authorEmail,
    timestamp,
    updateType,
  );

  /// Create a copy of ItemUpdateModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItemUpdateModelImplCopyWith<_$ItemUpdateModelImpl> get copyWith =>
      __$$ItemUpdateModelImplCopyWithImpl<_$ItemUpdateModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ItemUpdateModelImplToJson(this);
  }
}

abstract class _ItemUpdateModel implements ItemUpdateModel {
  const factory _ItemUpdateModel({
    required final String id,
    @JsonKey(name: 'item_id') required final String itemId,
    @JsonKey(name: 'item_type') required final String itemType,
    @JsonKey(name: 'project_id') required final String projectId,
    required final String content,
    @JsonKey(name: 'author_name') required final String authorName,
    @JsonKey(name: 'author_email') final String? authorEmail,
    required final String timestamp,
    @JsonKey(name: 'update_type') required final String updateType,
  }) = _$ItemUpdateModelImpl;

  factory _ItemUpdateModel.fromJson(Map<String, dynamic> json) =
      _$ItemUpdateModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'item_id')
  String get itemId;
  @override
  @JsonKey(name: 'item_type')
  String get itemType;
  @override
  @JsonKey(name: 'project_id')
  String get projectId;
  @override
  String get content;
  @override
  @JsonKey(name: 'author_name')
  String get authorName;
  @override
  @JsonKey(name: 'author_email')
  String? get authorEmail;
  @override
  String get timestamp;
  @override
  @JsonKey(name: 'update_type')
  String get updateType;

  /// Create a copy of ItemUpdateModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItemUpdateModelImplCopyWith<_$ItemUpdateModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
