// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content_status_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ContentStatusModel _$ContentStatusModelFromJson(Map<String, dynamic> json) {
  return _ContentStatusModel.fromJson(json);
}

/// @nodoc
mixin _$ContentStatusModel {
  @JsonKey(name: 'content_id')
  String get contentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'project_id')
  String get projectId => throw _privateConstructorUsedError;
  ProcessingStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'processing_message')
  String? get processingMessage => throw _privateConstructorUsedError;
  @JsonKey(name: 'progress_percentage')
  int get progressPercentage => throw _privateConstructorUsedError;
  @JsonKey(name: 'chunk_count')
  int get chunkCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'summary_generated')
  bool get summaryGenerated => throw _privateConstructorUsedError;
  @JsonKey(name: 'summary_id')
  String? get summaryId => throw _privateConstructorUsedError;
  @JsonKey(name: 'error_message')
  String? get errorMessage => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'estimated_completion')
  DateTime? get estimatedCompletion => throw _privateConstructorUsedError;

  /// Serializes this ContentStatusModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ContentStatusModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ContentStatusModelCopyWith<ContentStatusModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContentStatusModelCopyWith<$Res> {
  factory $ContentStatusModelCopyWith(
    ContentStatusModel value,
    $Res Function(ContentStatusModel) then,
  ) = _$ContentStatusModelCopyWithImpl<$Res, ContentStatusModel>;
  @useResult
  $Res call({
    @JsonKey(name: 'content_id') String contentId,
    @JsonKey(name: 'project_id') String projectId,
    ProcessingStatus status,
    @JsonKey(name: 'processing_message') String? processingMessage,
    @JsonKey(name: 'progress_percentage') int progressPercentage,
    @JsonKey(name: 'chunk_count') int chunkCount,
    @JsonKey(name: 'summary_generated') bool summaryGenerated,
    @JsonKey(name: 'summary_id') String? summaryId,
    @JsonKey(name: 'error_message') String? errorMessage,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime updatedAt,
    @JsonKey(name: 'estimated_completion') DateTime? estimatedCompletion,
  });
}

/// @nodoc
class _$ContentStatusModelCopyWithImpl<$Res, $Val extends ContentStatusModel>
    implements $ContentStatusModelCopyWith<$Res> {
  _$ContentStatusModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContentStatusModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contentId = null,
    Object? projectId = null,
    Object? status = null,
    Object? processingMessage = freezed,
    Object? progressPercentage = null,
    Object? chunkCount = null,
    Object? summaryGenerated = null,
    Object? summaryId = freezed,
    Object? errorMessage = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? estimatedCompletion = freezed,
  }) {
    return _then(
      _value.copyWith(
            contentId: null == contentId
                ? _value.contentId
                : contentId // ignore: cast_nullable_to_non_nullable
                      as String,
            projectId: null == projectId
                ? _value.projectId
                : projectId // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ProcessingStatus,
            processingMessage: freezed == processingMessage
                ? _value.processingMessage
                : processingMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
            progressPercentage: null == progressPercentage
                ? _value.progressPercentage
                : progressPercentage // ignore: cast_nullable_to_non_nullable
                      as int,
            chunkCount: null == chunkCount
                ? _value.chunkCount
                : chunkCount // ignore: cast_nullable_to_non_nullable
                      as int,
            summaryGenerated: null == summaryGenerated
                ? _value.summaryGenerated
                : summaryGenerated // ignore: cast_nullable_to_non_nullable
                      as bool,
            summaryId: freezed == summaryId
                ? _value.summaryId
                : summaryId // ignore: cast_nullable_to_non_nullable
                      as String?,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            estimatedCompletion: freezed == estimatedCompletion
                ? _value.estimatedCompletion
                : estimatedCompletion // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ContentStatusModelImplCopyWith<$Res>
    implements $ContentStatusModelCopyWith<$Res> {
  factory _$$ContentStatusModelImplCopyWith(
    _$ContentStatusModelImpl value,
    $Res Function(_$ContentStatusModelImpl) then,
  ) = __$$ContentStatusModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'content_id') String contentId,
    @JsonKey(name: 'project_id') String projectId,
    ProcessingStatus status,
    @JsonKey(name: 'processing_message') String? processingMessage,
    @JsonKey(name: 'progress_percentage') int progressPercentage,
    @JsonKey(name: 'chunk_count') int chunkCount,
    @JsonKey(name: 'summary_generated') bool summaryGenerated,
    @JsonKey(name: 'summary_id') String? summaryId,
    @JsonKey(name: 'error_message') String? errorMessage,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime updatedAt,
    @JsonKey(name: 'estimated_completion') DateTime? estimatedCompletion,
  });
}

/// @nodoc
class __$$ContentStatusModelImplCopyWithImpl<$Res>
    extends _$ContentStatusModelCopyWithImpl<$Res, _$ContentStatusModelImpl>
    implements _$$ContentStatusModelImplCopyWith<$Res> {
  __$$ContentStatusModelImplCopyWithImpl(
    _$ContentStatusModelImpl _value,
    $Res Function(_$ContentStatusModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentStatusModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contentId = null,
    Object? projectId = null,
    Object? status = null,
    Object? processingMessage = freezed,
    Object? progressPercentage = null,
    Object? chunkCount = null,
    Object? summaryGenerated = null,
    Object? summaryId = freezed,
    Object? errorMessage = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? estimatedCompletion = freezed,
  }) {
    return _then(
      _$ContentStatusModelImpl(
        contentId: null == contentId
            ? _value.contentId
            : contentId // ignore: cast_nullable_to_non_nullable
                  as String,
        projectId: null == projectId
            ? _value.projectId
            : projectId // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ProcessingStatus,
        processingMessage: freezed == processingMessage
            ? _value.processingMessage
            : processingMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        progressPercentage: null == progressPercentage
            ? _value.progressPercentage
            : progressPercentage // ignore: cast_nullable_to_non_nullable
                  as int,
        chunkCount: null == chunkCount
            ? _value.chunkCount
            : chunkCount // ignore: cast_nullable_to_non_nullable
                  as int,
        summaryGenerated: null == summaryGenerated
            ? _value.summaryGenerated
            : summaryGenerated // ignore: cast_nullable_to_non_nullable
                  as bool,
        summaryId: freezed == summaryId
            ? _value.summaryId
            : summaryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        estimatedCompletion: freezed == estimatedCompletion
            ? _value.estimatedCompletion
            : estimatedCompletion // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ContentStatusModelImpl extends _ContentStatusModel {
  const _$ContentStatusModelImpl({
    @JsonKey(name: 'content_id') required this.contentId,
    @JsonKey(name: 'project_id') required this.projectId,
    required this.status,
    @JsonKey(name: 'processing_message') this.processingMessage,
    @JsonKey(name: 'progress_percentage') this.progressPercentage = 0,
    @JsonKey(name: 'chunk_count') this.chunkCount = 0,
    @JsonKey(name: 'summary_generated') this.summaryGenerated = false,
    @JsonKey(name: 'summary_id') this.summaryId,
    @JsonKey(name: 'error_message') this.errorMessage,
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'updated_at') required this.updatedAt,
    @JsonKey(name: 'estimated_completion') this.estimatedCompletion,
  }) : super._();

  factory _$ContentStatusModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ContentStatusModelImplFromJson(json);

  @override
  @JsonKey(name: 'content_id')
  final String contentId;
  @override
  @JsonKey(name: 'project_id')
  final String projectId;
  @override
  final ProcessingStatus status;
  @override
  @JsonKey(name: 'processing_message')
  final String? processingMessage;
  @override
  @JsonKey(name: 'progress_percentage')
  final int progressPercentage;
  @override
  @JsonKey(name: 'chunk_count')
  final int chunkCount;
  @override
  @JsonKey(name: 'summary_generated')
  final bool summaryGenerated;
  @override
  @JsonKey(name: 'summary_id')
  final String? summaryId;
  @override
  @JsonKey(name: 'error_message')
  final String? errorMessage;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @override
  @JsonKey(name: 'estimated_completion')
  final DateTime? estimatedCompletion;

  @override
  String toString() {
    return 'ContentStatusModel(contentId: $contentId, projectId: $projectId, status: $status, processingMessage: $processingMessage, progressPercentage: $progressPercentage, chunkCount: $chunkCount, summaryGenerated: $summaryGenerated, summaryId: $summaryId, errorMessage: $errorMessage, createdAt: $createdAt, updatedAt: $updatedAt, estimatedCompletion: $estimatedCompletion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContentStatusModelImpl &&
            (identical(other.contentId, contentId) ||
                other.contentId == contentId) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.processingMessage, processingMessage) ||
                other.processingMessage == processingMessage) &&
            (identical(other.progressPercentage, progressPercentage) ||
                other.progressPercentage == progressPercentage) &&
            (identical(other.chunkCount, chunkCount) ||
                other.chunkCount == chunkCount) &&
            (identical(other.summaryGenerated, summaryGenerated) ||
                other.summaryGenerated == summaryGenerated) &&
            (identical(other.summaryId, summaryId) ||
                other.summaryId == summaryId) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.estimatedCompletion, estimatedCompletion) ||
                other.estimatedCompletion == estimatedCompletion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    contentId,
    projectId,
    status,
    processingMessage,
    progressPercentage,
    chunkCount,
    summaryGenerated,
    summaryId,
    errorMessage,
    createdAt,
    updatedAt,
    estimatedCompletion,
  );

  /// Create a copy of ContentStatusModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ContentStatusModelImplCopyWith<_$ContentStatusModelImpl> get copyWith =>
      __$$ContentStatusModelImplCopyWithImpl<_$ContentStatusModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ContentStatusModelImplToJson(this);
  }
}

abstract class _ContentStatusModel extends ContentStatusModel {
  const factory _ContentStatusModel({
    @JsonKey(name: 'content_id') required final String contentId,
    @JsonKey(name: 'project_id') required final String projectId,
    required final ProcessingStatus status,
    @JsonKey(name: 'processing_message') final String? processingMessage,
    @JsonKey(name: 'progress_percentage') final int progressPercentage,
    @JsonKey(name: 'chunk_count') final int chunkCount,
    @JsonKey(name: 'summary_generated') final bool summaryGenerated,
    @JsonKey(name: 'summary_id') final String? summaryId,
    @JsonKey(name: 'error_message') final String? errorMessage,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
    @JsonKey(name: 'updated_at') required final DateTime updatedAt,
    @JsonKey(name: 'estimated_completion') final DateTime? estimatedCompletion,
  }) = _$ContentStatusModelImpl;
  const _ContentStatusModel._() : super._();

  factory _ContentStatusModel.fromJson(Map<String, dynamic> json) =
      _$ContentStatusModelImpl.fromJson;

  @override
  @JsonKey(name: 'content_id')
  String get contentId;
  @override
  @JsonKey(name: 'project_id')
  String get projectId;
  @override
  ProcessingStatus get status;
  @override
  @JsonKey(name: 'processing_message')
  String? get processingMessage;
  @override
  @JsonKey(name: 'progress_percentage')
  int get progressPercentage;
  @override
  @JsonKey(name: 'chunk_count')
  int get chunkCount;
  @override
  @JsonKey(name: 'summary_generated')
  bool get summaryGenerated;
  @override
  @JsonKey(name: 'summary_id')
  String? get summaryId;
  @override
  @JsonKey(name: 'error_message')
  String? get errorMessage;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;
  @override
  @JsonKey(name: 'estimated_completion')
  DateTime? get estimatedCompletion;

  /// Create a copy of ContentStatusModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ContentStatusModelImplCopyWith<_$ContentStatusModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
