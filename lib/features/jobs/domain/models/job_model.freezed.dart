// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

JobModel _$JobModelFromJson(Map<String, dynamic> json) {
  return _JobModel.fromJson(json);
}

/// @nodoc
mixin _$JobModel {
  String get jobId => throw _privateConstructorUsedError;
  String get projectId => throw _privateConstructorUsedError;
  JobType get jobType => throw _privateConstructorUsedError;
  JobStatus get status => throw _privateConstructorUsedError;
  double get progress => throw _privateConstructorUsedError;
  int get totalSteps => throw _privateConstructorUsedError;
  int get currentStep => throw _privateConstructorUsedError;
  String? get stepDescription => throw _privateConstructorUsedError;
  String? get filename => throw _privateConstructorUsedError;
  int? get fileSize => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  Map<String, dynamic>? get result => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  /// Serializes this JobModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of JobModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JobModelCopyWith<JobModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JobModelCopyWith<$Res> {
  factory $JobModelCopyWith(JobModel value, $Res Function(JobModel) then) =
      _$JobModelCopyWithImpl<$Res, JobModel>;
  @useResult
  $Res call({
    String jobId,
    String projectId,
    JobType jobType,
    JobStatus status,
    double progress,
    int totalSteps,
    int currentStep,
    String? stepDescription,
    String? filename,
    int? fileSize,
    String? errorMessage,
    Map<String, dynamic>? result,
    DateTime createdAt,
    DateTime updatedAt,
    DateTime? completedAt,
    Map<String, dynamic> metadata,
  });
}

/// @nodoc
class _$JobModelCopyWithImpl<$Res, $Val extends JobModel>
    implements $JobModelCopyWith<$Res> {
  _$JobModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JobModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? jobId = null,
    Object? projectId = null,
    Object? jobType = null,
    Object? status = null,
    Object? progress = null,
    Object? totalSteps = null,
    Object? currentStep = null,
    Object? stepDescription = freezed,
    Object? filename = freezed,
    Object? fileSize = freezed,
    Object? errorMessage = freezed,
    Object? result = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? completedAt = freezed,
    Object? metadata = null,
  }) {
    return _then(
      _value.copyWith(
            jobId: null == jobId
                ? _value.jobId
                : jobId // ignore: cast_nullable_to_non_nullable
                      as String,
            projectId: null == projectId
                ? _value.projectId
                : projectId // ignore: cast_nullable_to_non_nullable
                      as String,
            jobType: null == jobType
                ? _value.jobType
                : jobType // ignore: cast_nullable_to_non_nullable
                      as JobType,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as JobStatus,
            progress: null == progress
                ? _value.progress
                : progress // ignore: cast_nullable_to_non_nullable
                      as double,
            totalSteps: null == totalSteps
                ? _value.totalSteps
                : totalSteps // ignore: cast_nullable_to_non_nullable
                      as int,
            currentStep: null == currentStep
                ? _value.currentStep
                : currentStep // ignore: cast_nullable_to_non_nullable
                      as int,
            stepDescription: freezed == stepDescription
                ? _value.stepDescription
                : stepDescription // ignore: cast_nullable_to_non_nullable
                      as String?,
            filename: freezed == filename
                ? _value.filename
                : filename // ignore: cast_nullable_to_non_nullable
                      as String?,
            fileSize: freezed == fileSize
                ? _value.fileSize
                : fileSize // ignore: cast_nullable_to_non_nullable
                      as int?,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
            result: freezed == result
                ? _value.result
                : result // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            metadata: null == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$JobModelImplCopyWith<$Res>
    implements $JobModelCopyWith<$Res> {
  factory _$$JobModelImplCopyWith(
    _$JobModelImpl value,
    $Res Function(_$JobModelImpl) then,
  ) = __$$JobModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String jobId,
    String projectId,
    JobType jobType,
    JobStatus status,
    double progress,
    int totalSteps,
    int currentStep,
    String? stepDescription,
    String? filename,
    int? fileSize,
    String? errorMessage,
    Map<String, dynamic>? result,
    DateTime createdAt,
    DateTime updatedAt,
    DateTime? completedAt,
    Map<String, dynamic> metadata,
  });
}

/// @nodoc
class __$$JobModelImplCopyWithImpl<$Res>
    extends _$JobModelCopyWithImpl<$Res, _$JobModelImpl>
    implements _$$JobModelImplCopyWith<$Res> {
  __$$JobModelImplCopyWithImpl(
    _$JobModelImpl _value,
    $Res Function(_$JobModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of JobModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? jobId = null,
    Object? projectId = null,
    Object? jobType = null,
    Object? status = null,
    Object? progress = null,
    Object? totalSteps = null,
    Object? currentStep = null,
    Object? stepDescription = freezed,
    Object? filename = freezed,
    Object? fileSize = freezed,
    Object? errorMessage = freezed,
    Object? result = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? completedAt = freezed,
    Object? metadata = null,
  }) {
    return _then(
      _$JobModelImpl(
        jobId: null == jobId
            ? _value.jobId
            : jobId // ignore: cast_nullable_to_non_nullable
                  as String,
        projectId: null == projectId
            ? _value.projectId
            : projectId // ignore: cast_nullable_to_non_nullable
                  as String,
        jobType: null == jobType
            ? _value.jobType
            : jobType // ignore: cast_nullable_to_non_nullable
                  as JobType,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as JobStatus,
        progress: null == progress
            ? _value.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as double,
        totalSteps: null == totalSteps
            ? _value.totalSteps
            : totalSteps // ignore: cast_nullable_to_non_nullable
                  as int,
        currentStep: null == currentStep
            ? _value.currentStep
            : currentStep // ignore: cast_nullable_to_non_nullable
                  as int,
        stepDescription: freezed == stepDescription
            ? _value.stepDescription
            : stepDescription // ignore: cast_nullable_to_non_nullable
                  as String?,
        filename: freezed == filename
            ? _value.filename
            : filename // ignore: cast_nullable_to_non_nullable
                  as String?,
        fileSize: freezed == fileSize
            ? _value.fileSize
            : fileSize // ignore: cast_nullable_to_non_nullable
                  as int?,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        result: freezed == result
            ? _value._result
            : result // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        metadata: null == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$JobModelImpl extends _JobModel {
  const _$JobModelImpl({
    required this.jobId,
    required this.projectId,
    required this.jobType,
    required this.status,
    this.progress = 0.0,
    this.totalSteps = 1,
    this.currentStep = 0,
    this.stepDescription,
    this.filename,
    this.fileSize,
    this.errorMessage,
    final Map<String, dynamic>? result,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    final Map<String, dynamic> metadata = const {},
  }) : _result = result,
       _metadata = metadata,
       super._();

  factory _$JobModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$JobModelImplFromJson(json);

  @override
  final String jobId;
  @override
  final String projectId;
  @override
  final JobType jobType;
  @override
  final JobStatus status;
  @override
  @JsonKey()
  final double progress;
  @override
  @JsonKey()
  final int totalSteps;
  @override
  @JsonKey()
  final int currentStep;
  @override
  final String? stepDescription;
  @override
  final String? filename;
  @override
  final int? fileSize;
  @override
  final String? errorMessage;
  final Map<String, dynamic>? _result;
  @override
  Map<String, dynamic>? get result {
    final value = _result;
    if (value == null) return null;
    if (_result is EqualUnmodifiableMapView) return _result;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final DateTime? completedAt;
  final Map<String, dynamic> _metadata;
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  String toString() {
    return 'JobModel(jobId: $jobId, projectId: $projectId, jobType: $jobType, status: $status, progress: $progress, totalSteps: $totalSteps, currentStep: $currentStep, stepDescription: $stepDescription, filename: $filename, fileSize: $fileSize, errorMessage: $errorMessage, result: $result, createdAt: $createdAt, updatedAt: $updatedAt, completedAt: $completedAt, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JobModelImpl &&
            (identical(other.jobId, jobId) || other.jobId == jobId) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.jobType, jobType) || other.jobType == jobType) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.totalSteps, totalSteps) ||
                other.totalSteps == totalSteps) &&
            (identical(other.currentStep, currentStep) ||
                other.currentStep == currentStep) &&
            (identical(other.stepDescription, stepDescription) ||
                other.stepDescription == stepDescription) &&
            (identical(other.filename, filename) ||
                other.filename == filename) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            const DeepCollectionEquality().equals(other._result, _result) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    jobId,
    projectId,
    jobType,
    status,
    progress,
    totalSteps,
    currentStep,
    stepDescription,
    filename,
    fileSize,
    errorMessage,
    const DeepCollectionEquality().hash(_result),
    createdAt,
    updatedAt,
    completedAt,
    const DeepCollectionEquality().hash(_metadata),
  );

  /// Create a copy of JobModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JobModelImplCopyWith<_$JobModelImpl> get copyWith =>
      __$$JobModelImplCopyWithImpl<_$JobModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JobModelImplToJson(this);
  }
}

abstract class _JobModel extends JobModel {
  const factory _JobModel({
    required final String jobId,
    required final String projectId,
    required final JobType jobType,
    required final JobStatus status,
    final double progress,
    final int totalSteps,
    final int currentStep,
    final String? stepDescription,
    final String? filename,
    final int? fileSize,
    final String? errorMessage,
    final Map<String, dynamic>? result,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final DateTime? completedAt,
    final Map<String, dynamic> metadata,
  }) = _$JobModelImpl;
  const _JobModel._() : super._();

  factory _JobModel.fromJson(Map<String, dynamic> json) =
      _$JobModelImpl.fromJson;

  @override
  String get jobId;
  @override
  String get projectId;
  @override
  JobType get jobType;
  @override
  JobStatus get status;
  @override
  double get progress;
  @override
  int get totalSteps;
  @override
  int get currentStep;
  @override
  String? get stepDescription;
  @override
  String? get filename;
  @override
  int? get fileSize;
  @override
  String? get errorMessage;
  @override
  Map<String, dynamic>? get result;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  DateTime? get completedAt;
  @override
  Map<String, dynamic> get metadata;

  /// Create a copy of JobModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JobModelImplCopyWith<_$JobModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
