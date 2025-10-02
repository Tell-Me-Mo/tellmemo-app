// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'risk_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RiskModel _$RiskModelFromJson(Map<String, dynamic> json) {
  return _RiskModel.fromJson(json);
}

/// @nodoc
mixin _$RiskModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'project_id')
  String get projectId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get severity => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get mitigation => throw _privateConstructorUsedError;
  String? get impact => throw _privateConstructorUsedError;
  double? get probability => throw _privateConstructorUsedError;
  @JsonKey(name: 'ai_generated')
  bool get aiGenerated => throw _privateConstructorUsedError;
  @JsonKey(name: 'ai_confidence')
  double? get aiConfidence => throw _privateConstructorUsedError;
  @JsonKey(name: 'source_content_id')
  String? get sourceContentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'identified_date')
  String? get identifiedDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'resolved_date')
  String? get resolvedDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_updated')
  String? get lastUpdated => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_by')
  String? get updatedBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'assigned_to')
  String? get assignedTo => throw _privateConstructorUsedError;
  @JsonKey(name: 'assigned_to_email')
  String? get assignedToEmail => throw _privateConstructorUsedError;

  /// Serializes this RiskModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RiskModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RiskModelCopyWith<RiskModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RiskModelCopyWith<$Res> {
  factory $RiskModelCopyWith(RiskModel value, $Res Function(RiskModel) then) =
      _$RiskModelCopyWithImpl<$Res, RiskModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'project_id') String projectId,
    String title,
    String description,
    String severity,
    String status,
    String? mitigation,
    String? impact,
    double? probability,
    @JsonKey(name: 'ai_generated') bool aiGenerated,
    @JsonKey(name: 'ai_confidence') double? aiConfidence,
    @JsonKey(name: 'source_content_id') String? sourceContentId,
    @JsonKey(name: 'identified_date') String? identifiedDate,
    @JsonKey(name: 'resolved_date') String? resolvedDate,
    @JsonKey(name: 'last_updated') String? lastUpdated,
    @JsonKey(name: 'updated_by') String? updatedBy,
    @JsonKey(name: 'assigned_to') String? assignedTo,
    @JsonKey(name: 'assigned_to_email') String? assignedToEmail,
  });
}

/// @nodoc
class _$RiskModelCopyWithImpl<$Res, $Val extends RiskModel>
    implements $RiskModelCopyWith<$Res> {
  _$RiskModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RiskModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? title = null,
    Object? description = null,
    Object? severity = null,
    Object? status = null,
    Object? mitigation = freezed,
    Object? impact = freezed,
    Object? probability = freezed,
    Object? aiGenerated = null,
    Object? aiConfidence = freezed,
    Object? sourceContentId = freezed,
    Object? identifiedDate = freezed,
    Object? resolvedDate = freezed,
    Object? lastUpdated = freezed,
    Object? updatedBy = freezed,
    Object? assignedTo = freezed,
    Object? assignedToEmail = freezed,
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
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            severity: null == severity
                ? _value.severity
                : severity // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            mitigation: freezed == mitigation
                ? _value.mitigation
                : mitigation // ignore: cast_nullable_to_non_nullable
                      as String?,
            impact: freezed == impact
                ? _value.impact
                : impact // ignore: cast_nullable_to_non_nullable
                      as String?,
            probability: freezed == probability
                ? _value.probability
                : probability // ignore: cast_nullable_to_non_nullable
                      as double?,
            aiGenerated: null == aiGenerated
                ? _value.aiGenerated
                : aiGenerated // ignore: cast_nullable_to_non_nullable
                      as bool,
            aiConfidence: freezed == aiConfidence
                ? _value.aiConfidence
                : aiConfidence // ignore: cast_nullable_to_non_nullable
                      as double?,
            sourceContentId: freezed == sourceContentId
                ? _value.sourceContentId
                : sourceContentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            identifiedDate: freezed == identifiedDate
                ? _value.identifiedDate
                : identifiedDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            resolvedDate: freezed == resolvedDate
                ? _value.resolvedDate
                : resolvedDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastUpdated: freezed == lastUpdated
                ? _value.lastUpdated
                : lastUpdated // ignore: cast_nullable_to_non_nullable
                      as String?,
            updatedBy: freezed == updatedBy
                ? _value.updatedBy
                : updatedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            assignedTo: freezed == assignedTo
                ? _value.assignedTo
                : assignedTo // ignore: cast_nullable_to_non_nullable
                      as String?,
            assignedToEmail: freezed == assignedToEmail
                ? _value.assignedToEmail
                : assignedToEmail // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RiskModelImplCopyWith<$Res>
    implements $RiskModelCopyWith<$Res> {
  factory _$$RiskModelImplCopyWith(
    _$RiskModelImpl value,
    $Res Function(_$RiskModelImpl) then,
  ) = __$$RiskModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'project_id') String projectId,
    String title,
    String description,
    String severity,
    String status,
    String? mitigation,
    String? impact,
    double? probability,
    @JsonKey(name: 'ai_generated') bool aiGenerated,
    @JsonKey(name: 'ai_confidence') double? aiConfidence,
    @JsonKey(name: 'source_content_id') String? sourceContentId,
    @JsonKey(name: 'identified_date') String? identifiedDate,
    @JsonKey(name: 'resolved_date') String? resolvedDate,
    @JsonKey(name: 'last_updated') String? lastUpdated,
    @JsonKey(name: 'updated_by') String? updatedBy,
    @JsonKey(name: 'assigned_to') String? assignedTo,
    @JsonKey(name: 'assigned_to_email') String? assignedToEmail,
  });
}

/// @nodoc
class __$$RiskModelImplCopyWithImpl<$Res>
    extends _$RiskModelCopyWithImpl<$Res, _$RiskModelImpl>
    implements _$$RiskModelImplCopyWith<$Res> {
  __$$RiskModelImplCopyWithImpl(
    _$RiskModelImpl _value,
    $Res Function(_$RiskModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RiskModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? title = null,
    Object? description = null,
    Object? severity = null,
    Object? status = null,
    Object? mitigation = freezed,
    Object? impact = freezed,
    Object? probability = freezed,
    Object? aiGenerated = null,
    Object? aiConfidence = freezed,
    Object? sourceContentId = freezed,
    Object? identifiedDate = freezed,
    Object? resolvedDate = freezed,
    Object? lastUpdated = freezed,
    Object? updatedBy = freezed,
    Object? assignedTo = freezed,
    Object? assignedToEmail = freezed,
  }) {
    return _then(
      _$RiskModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        projectId: null == projectId
            ? _value.projectId
            : projectId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        severity: null == severity
            ? _value.severity
            : severity // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        mitigation: freezed == mitigation
            ? _value.mitigation
            : mitigation // ignore: cast_nullable_to_non_nullable
                  as String?,
        impact: freezed == impact
            ? _value.impact
            : impact // ignore: cast_nullable_to_non_nullable
                  as String?,
        probability: freezed == probability
            ? _value.probability
            : probability // ignore: cast_nullable_to_non_nullable
                  as double?,
        aiGenerated: null == aiGenerated
            ? _value.aiGenerated
            : aiGenerated // ignore: cast_nullable_to_non_nullable
                  as bool,
        aiConfidence: freezed == aiConfidence
            ? _value.aiConfidence
            : aiConfidence // ignore: cast_nullable_to_non_nullable
                  as double?,
        sourceContentId: freezed == sourceContentId
            ? _value.sourceContentId
            : sourceContentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        identifiedDate: freezed == identifiedDate
            ? _value.identifiedDate
            : identifiedDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        resolvedDate: freezed == resolvedDate
            ? _value.resolvedDate
            : resolvedDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastUpdated: freezed == lastUpdated
            ? _value.lastUpdated
            : lastUpdated // ignore: cast_nullable_to_non_nullable
                  as String?,
        updatedBy: freezed == updatedBy
            ? _value.updatedBy
            : updatedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        assignedTo: freezed == assignedTo
            ? _value.assignedTo
            : assignedTo // ignore: cast_nullable_to_non_nullable
                  as String?,
        assignedToEmail: freezed == assignedToEmail
            ? _value.assignedToEmail
            : assignedToEmail // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RiskModelImpl implements _RiskModel {
  const _$RiskModelImpl({
    required this.id,
    @JsonKey(name: 'project_id') required this.projectId,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    this.mitigation,
    this.impact,
    this.probability,
    @JsonKey(name: 'ai_generated') required this.aiGenerated,
    @JsonKey(name: 'ai_confidence') this.aiConfidence,
    @JsonKey(name: 'source_content_id') this.sourceContentId,
    @JsonKey(name: 'identified_date') this.identifiedDate,
    @JsonKey(name: 'resolved_date') this.resolvedDate,
    @JsonKey(name: 'last_updated') this.lastUpdated,
    @JsonKey(name: 'updated_by') this.updatedBy,
    @JsonKey(name: 'assigned_to') this.assignedTo,
    @JsonKey(name: 'assigned_to_email') this.assignedToEmail,
  });

  factory _$RiskModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$RiskModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'project_id')
  final String projectId;
  @override
  final String title;
  @override
  final String description;
  @override
  final String severity;
  @override
  final String status;
  @override
  final String? mitigation;
  @override
  final String? impact;
  @override
  final double? probability;
  @override
  @JsonKey(name: 'ai_generated')
  final bool aiGenerated;
  @override
  @JsonKey(name: 'ai_confidence')
  final double? aiConfidence;
  @override
  @JsonKey(name: 'source_content_id')
  final String? sourceContentId;
  @override
  @JsonKey(name: 'identified_date')
  final String? identifiedDate;
  @override
  @JsonKey(name: 'resolved_date')
  final String? resolvedDate;
  @override
  @JsonKey(name: 'last_updated')
  final String? lastUpdated;
  @override
  @JsonKey(name: 'updated_by')
  final String? updatedBy;
  @override
  @JsonKey(name: 'assigned_to')
  final String? assignedTo;
  @override
  @JsonKey(name: 'assigned_to_email')
  final String? assignedToEmail;

  @override
  String toString() {
    return 'RiskModel(id: $id, projectId: $projectId, title: $title, description: $description, severity: $severity, status: $status, mitigation: $mitigation, impact: $impact, probability: $probability, aiGenerated: $aiGenerated, aiConfidence: $aiConfidence, sourceContentId: $sourceContentId, identifiedDate: $identifiedDate, resolvedDate: $resolvedDate, lastUpdated: $lastUpdated, updatedBy: $updatedBy, assignedTo: $assignedTo, assignedToEmail: $assignedToEmail)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RiskModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.mitigation, mitigation) ||
                other.mitigation == mitigation) &&
            (identical(other.impact, impact) || other.impact == impact) &&
            (identical(other.probability, probability) ||
                other.probability == probability) &&
            (identical(other.aiGenerated, aiGenerated) ||
                other.aiGenerated == aiGenerated) &&
            (identical(other.aiConfidence, aiConfidence) ||
                other.aiConfidence == aiConfidence) &&
            (identical(other.sourceContentId, sourceContentId) ||
                other.sourceContentId == sourceContentId) &&
            (identical(other.identifiedDate, identifiedDate) ||
                other.identifiedDate == identifiedDate) &&
            (identical(other.resolvedDate, resolvedDate) ||
                other.resolvedDate == resolvedDate) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated) &&
            (identical(other.updatedBy, updatedBy) ||
                other.updatedBy == updatedBy) &&
            (identical(other.assignedTo, assignedTo) ||
                other.assignedTo == assignedTo) &&
            (identical(other.assignedToEmail, assignedToEmail) ||
                other.assignedToEmail == assignedToEmail));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    projectId,
    title,
    description,
    severity,
    status,
    mitigation,
    impact,
    probability,
    aiGenerated,
    aiConfidence,
    sourceContentId,
    identifiedDate,
    resolvedDate,
    lastUpdated,
    updatedBy,
    assignedTo,
    assignedToEmail,
  );

  /// Create a copy of RiskModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RiskModelImplCopyWith<_$RiskModelImpl> get copyWith =>
      __$$RiskModelImplCopyWithImpl<_$RiskModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RiskModelImplToJson(this);
  }
}

abstract class _RiskModel implements RiskModel {
  const factory _RiskModel({
    required final String id,
    @JsonKey(name: 'project_id') required final String projectId,
    required final String title,
    required final String description,
    required final String severity,
    required final String status,
    final String? mitigation,
    final String? impact,
    final double? probability,
    @JsonKey(name: 'ai_generated') required final bool aiGenerated,
    @JsonKey(name: 'ai_confidence') final double? aiConfidence,
    @JsonKey(name: 'source_content_id') final String? sourceContentId,
    @JsonKey(name: 'identified_date') final String? identifiedDate,
    @JsonKey(name: 'resolved_date') final String? resolvedDate,
    @JsonKey(name: 'last_updated') final String? lastUpdated,
    @JsonKey(name: 'updated_by') final String? updatedBy,
    @JsonKey(name: 'assigned_to') final String? assignedTo,
    @JsonKey(name: 'assigned_to_email') final String? assignedToEmail,
  }) = _$RiskModelImpl;

  factory _RiskModel.fromJson(Map<String, dynamic> json) =
      _$RiskModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'project_id')
  String get projectId;
  @override
  String get title;
  @override
  String get description;
  @override
  String get severity;
  @override
  String get status;
  @override
  String? get mitigation;
  @override
  String? get impact;
  @override
  double? get probability;
  @override
  @JsonKey(name: 'ai_generated')
  bool get aiGenerated;
  @override
  @JsonKey(name: 'ai_confidence')
  double? get aiConfidence;
  @override
  @JsonKey(name: 'source_content_id')
  String? get sourceContentId;
  @override
  @JsonKey(name: 'identified_date')
  String? get identifiedDate;
  @override
  @JsonKey(name: 'resolved_date')
  String? get resolvedDate;
  @override
  @JsonKey(name: 'last_updated')
  String? get lastUpdated;
  @override
  @JsonKey(name: 'updated_by')
  String? get updatedBy;
  @override
  @JsonKey(name: 'assigned_to')
  String? get assignedTo;
  @override
  @JsonKey(name: 'assigned_to_email')
  String? get assignedToEmail;

  /// Create a copy of RiskModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RiskModelImplCopyWith<_$RiskModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
