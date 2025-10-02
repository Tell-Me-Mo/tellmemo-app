// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TaskModel _$TaskModelFromJson(Map<String, dynamic> json) {
  return _TaskModel.fromJson(json);
}

/// @nodoc
mixin _$TaskModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'project_id')
  String get projectId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get priority => throw _privateConstructorUsedError;
  String? get assignee => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_date')
  String? get dueDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_date')
  String? get completedDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'progress_percentage')
  int get progressPercentage => throw _privateConstructorUsedError;
  @JsonKey(name: 'blocker_description')
  String? get blockerDescription => throw _privateConstructorUsedError;
  @JsonKey(name: 'question_to_ask')
  String? get questionToAsk => throw _privateConstructorUsedError;
  @JsonKey(name: 'ai_generated')
  bool get aiGenerated => throw _privateConstructorUsedError;
  @JsonKey(name: 'ai_confidence')
  double? get aiConfidence => throw _privateConstructorUsedError;
  @JsonKey(name: 'source_content_id')
  String? get sourceContentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'depends_on_risk_id')
  String? get dependsOnRiskId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_date')
  String? get createdDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_updated')
  String? get lastUpdated => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_by')
  String? get updatedBy => throw _privateConstructorUsedError;

  /// Serializes this TaskModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskModelCopyWith<TaskModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskModelCopyWith<$Res> {
  factory $TaskModelCopyWith(TaskModel value, $Res Function(TaskModel) then) =
      _$TaskModelCopyWithImpl<$Res, TaskModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'project_id') String projectId,
    String title,
    String? description,
    String status,
    String priority,
    String? assignee,
    @JsonKey(name: 'due_date') String? dueDate,
    @JsonKey(name: 'completed_date') String? completedDate,
    @JsonKey(name: 'progress_percentage') int progressPercentage,
    @JsonKey(name: 'blocker_description') String? blockerDescription,
    @JsonKey(name: 'question_to_ask') String? questionToAsk,
    @JsonKey(name: 'ai_generated') bool aiGenerated,
    @JsonKey(name: 'ai_confidence') double? aiConfidence,
    @JsonKey(name: 'source_content_id') String? sourceContentId,
    @JsonKey(name: 'depends_on_risk_id') String? dependsOnRiskId,
    @JsonKey(name: 'created_date') String? createdDate,
    @JsonKey(name: 'last_updated') String? lastUpdated,
    @JsonKey(name: 'updated_by') String? updatedBy,
  });
}

/// @nodoc
class _$TaskModelCopyWithImpl<$Res, $Val extends TaskModel>
    implements $TaskModelCopyWith<$Res> {
  _$TaskModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? title = null,
    Object? description = freezed,
    Object? status = null,
    Object? priority = null,
    Object? assignee = freezed,
    Object? dueDate = freezed,
    Object? completedDate = freezed,
    Object? progressPercentage = null,
    Object? blockerDescription = freezed,
    Object? questionToAsk = freezed,
    Object? aiGenerated = null,
    Object? aiConfidence = freezed,
    Object? sourceContentId = freezed,
    Object? dependsOnRiskId = freezed,
    Object? createdDate = freezed,
    Object? lastUpdated = freezed,
    Object? updatedBy = freezed,
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
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as String,
            assignee: freezed == assignee
                ? _value.assignee
                : assignee // ignore: cast_nullable_to_non_nullable
                      as String?,
            dueDate: freezed == dueDate
                ? _value.dueDate
                : dueDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            completedDate: freezed == completedDate
                ? _value.completedDate
                : completedDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            progressPercentage: null == progressPercentage
                ? _value.progressPercentage
                : progressPercentage // ignore: cast_nullable_to_non_nullable
                      as int,
            blockerDescription: freezed == blockerDescription
                ? _value.blockerDescription
                : blockerDescription // ignore: cast_nullable_to_non_nullable
                      as String?,
            questionToAsk: freezed == questionToAsk
                ? _value.questionToAsk
                : questionToAsk // ignore: cast_nullable_to_non_nullable
                      as String?,
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
            dependsOnRiskId: freezed == dependsOnRiskId
                ? _value.dependsOnRiskId
                : dependsOnRiskId // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdDate: freezed == createdDate
                ? _value.createdDate
                : createdDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastUpdated: freezed == lastUpdated
                ? _value.lastUpdated
                : lastUpdated // ignore: cast_nullable_to_non_nullable
                      as String?,
            updatedBy: freezed == updatedBy
                ? _value.updatedBy
                : updatedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TaskModelImplCopyWith<$Res>
    implements $TaskModelCopyWith<$Res> {
  factory _$$TaskModelImplCopyWith(
    _$TaskModelImpl value,
    $Res Function(_$TaskModelImpl) then,
  ) = __$$TaskModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'project_id') String projectId,
    String title,
    String? description,
    String status,
    String priority,
    String? assignee,
    @JsonKey(name: 'due_date') String? dueDate,
    @JsonKey(name: 'completed_date') String? completedDate,
    @JsonKey(name: 'progress_percentage') int progressPercentage,
    @JsonKey(name: 'blocker_description') String? blockerDescription,
    @JsonKey(name: 'question_to_ask') String? questionToAsk,
    @JsonKey(name: 'ai_generated') bool aiGenerated,
    @JsonKey(name: 'ai_confidence') double? aiConfidence,
    @JsonKey(name: 'source_content_id') String? sourceContentId,
    @JsonKey(name: 'depends_on_risk_id') String? dependsOnRiskId,
    @JsonKey(name: 'created_date') String? createdDate,
    @JsonKey(name: 'last_updated') String? lastUpdated,
    @JsonKey(name: 'updated_by') String? updatedBy,
  });
}

/// @nodoc
class __$$TaskModelImplCopyWithImpl<$Res>
    extends _$TaskModelCopyWithImpl<$Res, _$TaskModelImpl>
    implements _$$TaskModelImplCopyWith<$Res> {
  __$$TaskModelImplCopyWithImpl(
    _$TaskModelImpl _value,
    $Res Function(_$TaskModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? title = null,
    Object? description = freezed,
    Object? status = null,
    Object? priority = null,
    Object? assignee = freezed,
    Object? dueDate = freezed,
    Object? completedDate = freezed,
    Object? progressPercentage = null,
    Object? blockerDescription = freezed,
    Object? questionToAsk = freezed,
    Object? aiGenerated = null,
    Object? aiConfidence = freezed,
    Object? sourceContentId = freezed,
    Object? dependsOnRiskId = freezed,
    Object? createdDate = freezed,
    Object? lastUpdated = freezed,
    Object? updatedBy = freezed,
  }) {
    return _then(
      _$TaskModelImpl(
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
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as String,
        assignee: freezed == assignee
            ? _value.assignee
            : assignee // ignore: cast_nullable_to_non_nullable
                  as String?,
        dueDate: freezed == dueDate
            ? _value.dueDate
            : dueDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        completedDate: freezed == completedDate
            ? _value.completedDate
            : completedDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        progressPercentage: null == progressPercentage
            ? _value.progressPercentage
            : progressPercentage // ignore: cast_nullable_to_non_nullable
                  as int,
        blockerDescription: freezed == blockerDescription
            ? _value.blockerDescription
            : blockerDescription // ignore: cast_nullable_to_non_nullable
                  as String?,
        questionToAsk: freezed == questionToAsk
            ? _value.questionToAsk
            : questionToAsk // ignore: cast_nullable_to_non_nullable
                  as String?,
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
        dependsOnRiskId: freezed == dependsOnRiskId
            ? _value.dependsOnRiskId
            : dependsOnRiskId // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdDate: freezed == createdDate
            ? _value.createdDate
            : createdDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastUpdated: freezed == lastUpdated
            ? _value.lastUpdated
            : lastUpdated // ignore: cast_nullable_to_non_nullable
                  as String?,
        updatedBy: freezed == updatedBy
            ? _value.updatedBy
            : updatedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskModelImpl implements _TaskModel {
  const _$TaskModelImpl({
    required this.id,
    @JsonKey(name: 'project_id') required this.projectId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.assignee,
    @JsonKey(name: 'due_date') this.dueDate,
    @JsonKey(name: 'completed_date') this.completedDate,
    @JsonKey(name: 'progress_percentage') required this.progressPercentage,
    @JsonKey(name: 'blocker_description') this.blockerDescription,
    @JsonKey(name: 'question_to_ask') this.questionToAsk,
    @JsonKey(name: 'ai_generated') required this.aiGenerated,
    @JsonKey(name: 'ai_confidence') this.aiConfidence,
    @JsonKey(name: 'source_content_id') this.sourceContentId,
    @JsonKey(name: 'depends_on_risk_id') this.dependsOnRiskId,
    @JsonKey(name: 'created_date') this.createdDate,
    @JsonKey(name: 'last_updated') this.lastUpdated,
    @JsonKey(name: 'updated_by') this.updatedBy,
  });

  factory _$TaskModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'project_id')
  final String projectId;
  @override
  final String title;
  @override
  final String? description;
  @override
  final String status;
  @override
  final String priority;
  @override
  final String? assignee;
  @override
  @JsonKey(name: 'due_date')
  final String? dueDate;
  @override
  @JsonKey(name: 'completed_date')
  final String? completedDate;
  @override
  @JsonKey(name: 'progress_percentage')
  final int progressPercentage;
  @override
  @JsonKey(name: 'blocker_description')
  final String? blockerDescription;
  @override
  @JsonKey(name: 'question_to_ask')
  final String? questionToAsk;
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
  @JsonKey(name: 'depends_on_risk_id')
  final String? dependsOnRiskId;
  @override
  @JsonKey(name: 'created_date')
  final String? createdDate;
  @override
  @JsonKey(name: 'last_updated')
  final String? lastUpdated;
  @override
  @JsonKey(name: 'updated_by')
  final String? updatedBy;

  @override
  String toString() {
    return 'TaskModel(id: $id, projectId: $projectId, title: $title, description: $description, status: $status, priority: $priority, assignee: $assignee, dueDate: $dueDate, completedDate: $completedDate, progressPercentage: $progressPercentage, blockerDescription: $blockerDescription, questionToAsk: $questionToAsk, aiGenerated: $aiGenerated, aiConfidence: $aiConfidence, sourceContentId: $sourceContentId, dependsOnRiskId: $dependsOnRiskId, createdDate: $createdDate, lastUpdated: $lastUpdated, updatedBy: $updatedBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.assignee, assignee) ||
                other.assignee == assignee) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.completedDate, completedDate) ||
                other.completedDate == completedDate) &&
            (identical(other.progressPercentage, progressPercentage) ||
                other.progressPercentage == progressPercentage) &&
            (identical(other.blockerDescription, blockerDescription) ||
                other.blockerDescription == blockerDescription) &&
            (identical(other.questionToAsk, questionToAsk) ||
                other.questionToAsk == questionToAsk) &&
            (identical(other.aiGenerated, aiGenerated) ||
                other.aiGenerated == aiGenerated) &&
            (identical(other.aiConfidence, aiConfidence) ||
                other.aiConfidence == aiConfidence) &&
            (identical(other.sourceContentId, sourceContentId) ||
                other.sourceContentId == sourceContentId) &&
            (identical(other.dependsOnRiskId, dependsOnRiskId) ||
                other.dependsOnRiskId == dependsOnRiskId) &&
            (identical(other.createdDate, createdDate) ||
                other.createdDate == createdDate) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated) &&
            (identical(other.updatedBy, updatedBy) ||
                other.updatedBy == updatedBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    projectId,
    title,
    description,
    status,
    priority,
    assignee,
    dueDate,
    completedDate,
    progressPercentage,
    blockerDescription,
    questionToAsk,
    aiGenerated,
    aiConfidence,
    sourceContentId,
    dependsOnRiskId,
    createdDate,
    lastUpdated,
    updatedBy,
  ]);

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskModelImplCopyWith<_$TaskModelImpl> get copyWith =>
      __$$TaskModelImplCopyWithImpl<_$TaskModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskModelImplToJson(this);
  }
}

abstract class _TaskModel implements TaskModel {
  const factory _TaskModel({
    required final String id,
    @JsonKey(name: 'project_id') required final String projectId,
    required final String title,
    final String? description,
    required final String status,
    required final String priority,
    final String? assignee,
    @JsonKey(name: 'due_date') final String? dueDate,
    @JsonKey(name: 'completed_date') final String? completedDate,
    @JsonKey(name: 'progress_percentage') required final int progressPercentage,
    @JsonKey(name: 'blocker_description') final String? blockerDescription,
    @JsonKey(name: 'question_to_ask') final String? questionToAsk,
    @JsonKey(name: 'ai_generated') required final bool aiGenerated,
    @JsonKey(name: 'ai_confidence') final double? aiConfidence,
    @JsonKey(name: 'source_content_id') final String? sourceContentId,
    @JsonKey(name: 'depends_on_risk_id') final String? dependsOnRiskId,
    @JsonKey(name: 'created_date') final String? createdDate,
    @JsonKey(name: 'last_updated') final String? lastUpdated,
    @JsonKey(name: 'updated_by') final String? updatedBy,
  }) = _$TaskModelImpl;

  factory _TaskModel.fromJson(Map<String, dynamic> json) =
      _$TaskModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'project_id')
  String get projectId;
  @override
  String get title;
  @override
  String? get description;
  @override
  String get status;
  @override
  String get priority;
  @override
  String? get assignee;
  @override
  @JsonKey(name: 'due_date')
  String? get dueDate;
  @override
  @JsonKey(name: 'completed_date')
  String? get completedDate;
  @override
  @JsonKey(name: 'progress_percentage')
  int get progressPercentage;
  @override
  @JsonKey(name: 'blocker_description')
  String? get blockerDescription;
  @override
  @JsonKey(name: 'question_to_ask')
  String? get questionToAsk;
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
  @JsonKey(name: 'depends_on_risk_id')
  String? get dependsOnRiskId;
  @override
  @JsonKey(name: 'created_date')
  String? get createdDate;
  @override
  @JsonKey(name: 'last_updated')
  String? get lastUpdated;
  @override
  @JsonKey(name: 'updated_by')
  String? get updatedBy;

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskModelImplCopyWith<_$TaskModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
