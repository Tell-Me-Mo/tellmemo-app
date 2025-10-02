// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ContentModel _$ContentModelFromJson(Map<String, dynamic> json) {
  return _ContentModel.fromJson(json);
}

/// @nodoc
mixin _$ContentModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'project_id')
  String get projectId => throw _privateConstructorUsedError;
  @JsonKey(name: 'content_type')
  String get contentType => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  @DateTimeConverterNullable()
  DateTime? get date => throw _privateConstructorUsedError;
  @JsonKey(name: 'uploaded_at')
  @DateTimeConverter()
  DateTime get uploadedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'uploaded_by')
  String? get uploadedBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'chunk_count')
  int get chunkCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'summary_generated')
  bool get summaryGenerated => throw _privateConstructorUsedError;
  @JsonKey(name: 'processed_at')
  @DateTimeConverterNullable()
  DateTime? get processedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'processing_error')
  String? get processingError => throw _privateConstructorUsedError;

  /// Serializes this ContentModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ContentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ContentModelCopyWith<ContentModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContentModelCopyWith<$Res> {
  factory $ContentModelCopyWith(
    ContentModel value,
    $Res Function(ContentModel) then,
  ) = _$ContentModelCopyWithImpl<$Res, ContentModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'project_id') String projectId,
    @JsonKey(name: 'content_type') String contentType,
    String title,
    @DateTimeConverterNullable() DateTime? date,
    @JsonKey(name: 'uploaded_at') @DateTimeConverter() DateTime uploadedAt,
    @JsonKey(name: 'uploaded_by') String? uploadedBy,
    @JsonKey(name: 'chunk_count') int chunkCount,
    @JsonKey(name: 'summary_generated') bool summaryGenerated,
    @JsonKey(name: 'processed_at')
    @DateTimeConverterNullable()
    DateTime? processedAt,
    @JsonKey(name: 'processing_error') String? processingError,
  });
}

/// @nodoc
class _$ContentModelCopyWithImpl<$Res, $Val extends ContentModel>
    implements $ContentModelCopyWith<$Res> {
  _$ContentModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? contentType = null,
    Object? title = null,
    Object? date = freezed,
    Object? uploadedAt = null,
    Object? uploadedBy = freezed,
    Object? chunkCount = null,
    Object? summaryGenerated = null,
    Object? processedAt = freezed,
    Object? processingError = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            projectId: null == projectId
                ? _value.projectId
                : projectId // ignore: cast_nullable_to_non_nullable
                      as String,
            contentType: null == contentType
                ? _value.contentType
                : contentType // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            date: freezed == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            uploadedAt: null == uploadedAt
                ? _value.uploadedAt
                : uploadedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            uploadedBy: freezed == uploadedBy
                ? _value.uploadedBy
                : uploadedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            chunkCount: null == chunkCount
                ? _value.chunkCount
                : chunkCount // ignore: cast_nullable_to_non_nullable
                      as int,
            summaryGenerated: null == summaryGenerated
                ? _value.summaryGenerated
                : summaryGenerated // ignore: cast_nullable_to_non_nullable
                      as bool,
            processedAt: freezed == processedAt
                ? _value.processedAt
                : processedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            processingError: freezed == processingError
                ? _value.processingError
                : processingError // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ContentModelImplCopyWith<$Res>
    implements $ContentModelCopyWith<$Res> {
  factory _$$ContentModelImplCopyWith(
    _$ContentModelImpl value,
    $Res Function(_$ContentModelImpl) then,
  ) = __$$ContentModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'project_id') String projectId,
    @JsonKey(name: 'content_type') String contentType,
    String title,
    @DateTimeConverterNullable() DateTime? date,
    @JsonKey(name: 'uploaded_at') @DateTimeConverter() DateTime uploadedAt,
    @JsonKey(name: 'uploaded_by') String? uploadedBy,
    @JsonKey(name: 'chunk_count') int chunkCount,
    @JsonKey(name: 'summary_generated') bool summaryGenerated,
    @JsonKey(name: 'processed_at')
    @DateTimeConverterNullable()
    DateTime? processedAt,
    @JsonKey(name: 'processing_error') String? processingError,
  });
}

/// @nodoc
class __$$ContentModelImplCopyWithImpl<$Res>
    extends _$ContentModelCopyWithImpl<$Res, _$ContentModelImpl>
    implements _$$ContentModelImplCopyWith<$Res> {
  __$$ContentModelImplCopyWithImpl(
    _$ContentModelImpl _value,
    $Res Function(_$ContentModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? contentType = null,
    Object? title = null,
    Object? date = freezed,
    Object? uploadedAt = null,
    Object? uploadedBy = freezed,
    Object? chunkCount = null,
    Object? summaryGenerated = null,
    Object? processedAt = freezed,
    Object? processingError = freezed,
  }) {
    return _then(
      _$ContentModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        projectId: null == projectId
            ? _value.projectId
            : projectId // ignore: cast_nullable_to_non_nullable
                  as String,
        contentType: null == contentType
            ? _value.contentType
            : contentType // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        date: freezed == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        uploadedAt: null == uploadedAt
            ? _value.uploadedAt
            : uploadedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        uploadedBy: freezed == uploadedBy
            ? _value.uploadedBy
            : uploadedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        chunkCount: null == chunkCount
            ? _value.chunkCount
            : chunkCount // ignore: cast_nullable_to_non_nullable
                  as int,
        summaryGenerated: null == summaryGenerated
            ? _value.summaryGenerated
            : summaryGenerated // ignore: cast_nullable_to_non_nullable
                  as bool,
        processedAt: freezed == processedAt
            ? _value.processedAt
            : processedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        processingError: freezed == processingError
            ? _value.processingError
            : processingError // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ContentModelImpl extends _ContentModel {
  const _$ContentModelImpl({
    required this.id,
    @JsonKey(name: 'project_id') required this.projectId,
    @JsonKey(name: 'content_type') required this.contentType,
    required this.title,
    @DateTimeConverterNullable() this.date,
    @JsonKey(name: 'uploaded_at') @DateTimeConverter() required this.uploadedAt,
    @JsonKey(name: 'uploaded_by') this.uploadedBy,
    @JsonKey(name: 'chunk_count') required this.chunkCount,
    @JsonKey(name: 'summary_generated') required this.summaryGenerated,
    @JsonKey(name: 'processed_at')
    @DateTimeConverterNullable()
    this.processedAt,
    @JsonKey(name: 'processing_error') this.processingError,
  }) : super._();

  factory _$ContentModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ContentModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'project_id')
  final String projectId;
  @override
  @JsonKey(name: 'content_type')
  final String contentType;
  @override
  final String title;
  @override
  @DateTimeConverterNullable()
  final DateTime? date;
  @override
  @JsonKey(name: 'uploaded_at')
  @DateTimeConverter()
  final DateTime uploadedAt;
  @override
  @JsonKey(name: 'uploaded_by')
  final String? uploadedBy;
  @override
  @JsonKey(name: 'chunk_count')
  final int chunkCount;
  @override
  @JsonKey(name: 'summary_generated')
  final bool summaryGenerated;
  @override
  @JsonKey(name: 'processed_at')
  @DateTimeConverterNullable()
  final DateTime? processedAt;
  @override
  @JsonKey(name: 'processing_error')
  final String? processingError;

  @override
  String toString() {
    return 'ContentModel(id: $id, projectId: $projectId, contentType: $contentType, title: $title, date: $date, uploadedAt: $uploadedAt, uploadedBy: $uploadedBy, chunkCount: $chunkCount, summaryGenerated: $summaryGenerated, processedAt: $processedAt, processingError: $processingError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContentModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.contentType, contentType) ||
                other.contentType == contentType) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.uploadedAt, uploadedAt) ||
                other.uploadedAt == uploadedAt) &&
            (identical(other.uploadedBy, uploadedBy) ||
                other.uploadedBy == uploadedBy) &&
            (identical(other.chunkCount, chunkCount) ||
                other.chunkCount == chunkCount) &&
            (identical(other.summaryGenerated, summaryGenerated) ||
                other.summaryGenerated == summaryGenerated) &&
            (identical(other.processedAt, processedAt) ||
                other.processedAt == processedAt) &&
            (identical(other.processingError, processingError) ||
                other.processingError == processingError));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    projectId,
    contentType,
    title,
    date,
    uploadedAt,
    uploadedBy,
    chunkCount,
    summaryGenerated,
    processedAt,
    processingError,
  );

  /// Create a copy of ContentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ContentModelImplCopyWith<_$ContentModelImpl> get copyWith =>
      __$$ContentModelImplCopyWithImpl<_$ContentModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ContentModelImplToJson(this);
  }
}

abstract class _ContentModel extends ContentModel {
  const factory _ContentModel({
    required final String id,
    @JsonKey(name: 'project_id') required final String projectId,
    @JsonKey(name: 'content_type') required final String contentType,
    required final String title,
    @DateTimeConverterNullable() final DateTime? date,
    @JsonKey(name: 'uploaded_at')
    @DateTimeConverter()
    required final DateTime uploadedAt,
    @JsonKey(name: 'uploaded_by') final String? uploadedBy,
    @JsonKey(name: 'chunk_count') required final int chunkCount,
    @JsonKey(name: 'summary_generated') required final bool summaryGenerated,
    @JsonKey(name: 'processed_at')
    @DateTimeConverterNullable()
    final DateTime? processedAt,
    @JsonKey(name: 'processing_error') final String? processingError,
  }) = _$ContentModelImpl;
  const _ContentModel._() : super._();

  factory _ContentModel.fromJson(Map<String, dynamic> json) =
      _$ContentModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'project_id')
  String get projectId;
  @override
  @JsonKey(name: 'content_type')
  String get contentType;
  @override
  String get title;
  @override
  @DateTimeConverterNullable()
  DateTime? get date;
  @override
  @JsonKey(name: 'uploaded_at')
  @DateTimeConverter()
  DateTime get uploadedAt;
  @override
  @JsonKey(name: 'uploaded_by')
  String? get uploadedBy;
  @override
  @JsonKey(name: 'chunk_count')
  int get chunkCount;
  @override
  @JsonKey(name: 'summary_generated')
  bool get summaryGenerated;
  @override
  @JsonKey(name: 'processed_at')
  @DateTimeConverterNullable()
  DateTime? get processedAt;
  @override
  @JsonKey(name: 'processing_error')
  String? get processingError;

  /// Create a copy of ContentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ContentModelImplCopyWith<_$ContentModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
