// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'summary_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ActionItem _$ActionItemFromJson(Map<String, dynamic> json) {
  return _ActionItem.fromJson(json);
}

/// @nodoc
mixin _$ActionItem {
  String get description => throw _privateConstructorUsedError;
  String get urgency => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_date')
  String? get dueDate => throw _privateConstructorUsedError;
  String? get assignee => throw _privateConstructorUsedError;
  List<String> get dependencies => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'follow_up_required')
  bool get followUpRequired => throw _privateConstructorUsedError;

  /// Serializes this ActionItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ActionItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActionItemCopyWith<ActionItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActionItemCopyWith<$Res> {
  factory $ActionItemCopyWith(
    ActionItem value,
    $Res Function(ActionItem) then,
  ) = _$ActionItemCopyWithImpl<$Res, ActionItem>;
  @useResult
  $Res call({
    String description,
    String urgency,
    @JsonKey(name: 'due_date') String? dueDate,
    String? assignee,
    List<String> dependencies,
    String status,
    @JsonKey(name: 'follow_up_required') bool followUpRequired,
  });
}

/// @nodoc
class _$ActionItemCopyWithImpl<$Res, $Val extends ActionItem>
    implements $ActionItemCopyWith<$Res> {
  _$ActionItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActionItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? description = null,
    Object? urgency = null,
    Object? dueDate = freezed,
    Object? assignee = freezed,
    Object? dependencies = null,
    Object? status = null,
    Object? followUpRequired = null,
  }) {
    return _then(
      _value.copyWith(
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            urgency: null == urgency
                ? _value.urgency
                : urgency // ignore: cast_nullable_to_non_nullable
                      as String,
            dueDate: freezed == dueDate
                ? _value.dueDate
                : dueDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            assignee: freezed == assignee
                ? _value.assignee
                : assignee // ignore: cast_nullable_to_non_nullable
                      as String?,
            dependencies: null == dependencies
                ? _value.dependencies
                : dependencies // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            followUpRequired: null == followUpRequired
                ? _value.followUpRequired
                : followUpRequired // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ActionItemImplCopyWith<$Res>
    implements $ActionItemCopyWith<$Res> {
  factory _$$ActionItemImplCopyWith(
    _$ActionItemImpl value,
    $Res Function(_$ActionItemImpl) then,
  ) = __$$ActionItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String description,
    String urgency,
    @JsonKey(name: 'due_date') String? dueDate,
    String? assignee,
    List<String> dependencies,
    String status,
    @JsonKey(name: 'follow_up_required') bool followUpRequired,
  });
}

/// @nodoc
class __$$ActionItemImplCopyWithImpl<$Res>
    extends _$ActionItemCopyWithImpl<$Res, _$ActionItemImpl>
    implements _$$ActionItemImplCopyWith<$Res> {
  __$$ActionItemImplCopyWithImpl(
    _$ActionItemImpl _value,
    $Res Function(_$ActionItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ActionItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? description = null,
    Object? urgency = null,
    Object? dueDate = freezed,
    Object? assignee = freezed,
    Object? dependencies = null,
    Object? status = null,
    Object? followUpRequired = null,
  }) {
    return _then(
      _$ActionItemImpl(
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        urgency: null == urgency
            ? _value.urgency
            : urgency // ignore: cast_nullable_to_non_nullable
                  as String,
        dueDate: freezed == dueDate
            ? _value.dueDate
            : dueDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        assignee: freezed == assignee
            ? _value.assignee
            : assignee // ignore: cast_nullable_to_non_nullable
                  as String?,
        dependencies: null == dependencies
            ? _value._dependencies
            : dependencies // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        followUpRequired: null == followUpRequired
            ? _value.followUpRequired
            : followUpRequired // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ActionItemImpl implements _ActionItem {
  const _$ActionItemImpl({
    required this.description,
    this.urgency = 'medium',
    @JsonKey(name: 'due_date') this.dueDate,
    this.assignee,
    final List<String> dependencies = const [],
    this.status = 'not_started',
    @JsonKey(name: 'follow_up_required') this.followUpRequired = false,
  }) : _dependencies = dependencies;

  factory _$ActionItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ActionItemImplFromJson(json);

  @override
  final String description;
  @override
  @JsonKey()
  final String urgency;
  @override
  @JsonKey(name: 'due_date')
  final String? dueDate;
  @override
  final String? assignee;
  final List<String> _dependencies;
  @override
  @JsonKey()
  List<String> get dependencies {
    if (_dependencies is EqualUnmodifiableListView) return _dependencies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dependencies);
  }

  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'follow_up_required')
  final bool followUpRequired;

  @override
  String toString() {
    return 'ActionItem(description: $description, urgency: $urgency, dueDate: $dueDate, assignee: $assignee, dependencies: $dependencies, status: $status, followUpRequired: $followUpRequired)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActionItemImpl &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.urgency, urgency) || other.urgency == urgency) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.assignee, assignee) ||
                other.assignee == assignee) &&
            const DeepCollectionEquality().equals(
              other._dependencies,
              _dependencies,
            ) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.followUpRequired, followUpRequired) ||
                other.followUpRequired == followUpRequired));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    description,
    urgency,
    dueDate,
    assignee,
    const DeepCollectionEquality().hash(_dependencies),
    status,
    followUpRequired,
  );

  /// Create a copy of ActionItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActionItemImplCopyWith<_$ActionItemImpl> get copyWith =>
      __$$ActionItemImplCopyWithImpl<_$ActionItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ActionItemImplToJson(this);
  }
}

abstract class _ActionItem implements ActionItem {
  const factory _ActionItem({
    required final String description,
    final String urgency,
    @JsonKey(name: 'due_date') final String? dueDate,
    final String? assignee,
    final List<String> dependencies,
    final String status,
    @JsonKey(name: 'follow_up_required') final bool followUpRequired,
  }) = _$ActionItemImpl;

  factory _ActionItem.fromJson(Map<String, dynamic> json) =
      _$ActionItemImpl.fromJson;

  @override
  String get description;
  @override
  String get urgency;
  @override
  @JsonKey(name: 'due_date')
  String? get dueDate;
  @override
  String? get assignee;
  @override
  List<String> get dependencies;
  @override
  String get status;
  @override
  @JsonKey(name: 'follow_up_required')
  bool get followUpRequired;

  /// Create a copy of ActionItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActionItemImplCopyWith<_$ActionItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Decision _$DecisionFromJson(Map<String, dynamic> json) {
  return _Decision.fromJson(json);
}

/// @nodoc
mixin _$Decision {
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'importance_score')
  String get importanceScore => throw _privateConstructorUsedError;
  @JsonKey(name: 'decision_type')
  String get decisionType => throw _privateConstructorUsedError;
  @JsonKey(name: 'stakeholders_affected')
  List<String> get stakeholdersAffected => throw _privateConstructorUsedError;
  String? get rationale => throw _privateConstructorUsedError;

  /// Serializes this Decision to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Decision
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DecisionCopyWith<Decision> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DecisionCopyWith<$Res> {
  factory $DecisionCopyWith(Decision value, $Res Function(Decision) then) =
      _$DecisionCopyWithImpl<$Res, Decision>;
  @useResult
  $Res call({
    String description,
    @JsonKey(name: 'importance_score') String importanceScore,
    @JsonKey(name: 'decision_type') String decisionType,
    @JsonKey(name: 'stakeholders_affected') List<String> stakeholdersAffected,
    String? rationale,
  });
}

/// @nodoc
class _$DecisionCopyWithImpl<$Res, $Val extends Decision>
    implements $DecisionCopyWith<$Res> {
  _$DecisionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Decision
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? description = null,
    Object? importanceScore = null,
    Object? decisionType = null,
    Object? stakeholdersAffected = null,
    Object? rationale = freezed,
  }) {
    return _then(
      _value.copyWith(
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            importanceScore: null == importanceScore
                ? _value.importanceScore
                : importanceScore // ignore: cast_nullable_to_non_nullable
                      as String,
            decisionType: null == decisionType
                ? _value.decisionType
                : decisionType // ignore: cast_nullable_to_non_nullable
                      as String,
            stakeholdersAffected: null == stakeholdersAffected
                ? _value.stakeholdersAffected
                : stakeholdersAffected // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            rationale: freezed == rationale
                ? _value.rationale
                : rationale // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DecisionImplCopyWith<$Res>
    implements $DecisionCopyWith<$Res> {
  factory _$$DecisionImplCopyWith(
    _$DecisionImpl value,
    $Res Function(_$DecisionImpl) then,
  ) = __$$DecisionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String description,
    @JsonKey(name: 'importance_score') String importanceScore,
    @JsonKey(name: 'decision_type') String decisionType,
    @JsonKey(name: 'stakeholders_affected') List<String> stakeholdersAffected,
    String? rationale,
  });
}

/// @nodoc
class __$$DecisionImplCopyWithImpl<$Res>
    extends _$DecisionCopyWithImpl<$Res, _$DecisionImpl>
    implements _$$DecisionImplCopyWith<$Res> {
  __$$DecisionImplCopyWithImpl(
    _$DecisionImpl _value,
    $Res Function(_$DecisionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Decision
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? description = null,
    Object? importanceScore = null,
    Object? decisionType = null,
    Object? stakeholdersAffected = null,
    Object? rationale = freezed,
  }) {
    return _then(
      _$DecisionImpl(
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        importanceScore: null == importanceScore
            ? _value.importanceScore
            : importanceScore // ignore: cast_nullable_to_non_nullable
                  as String,
        decisionType: null == decisionType
            ? _value.decisionType
            : decisionType // ignore: cast_nullable_to_non_nullable
                  as String,
        stakeholdersAffected: null == stakeholdersAffected
            ? _value._stakeholdersAffected
            : stakeholdersAffected // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        rationale: freezed == rationale
            ? _value.rationale
            : rationale // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DecisionImpl implements _Decision {
  const _$DecisionImpl({
    required this.description,
    @JsonKey(name: 'importance_score') this.importanceScore = 'medium',
    @JsonKey(name: 'decision_type') this.decisionType = 'operational',
    @JsonKey(name: 'stakeholders_affected')
    final List<String> stakeholdersAffected = const [],
    this.rationale,
  }) : _stakeholdersAffected = stakeholdersAffected;

  factory _$DecisionImpl.fromJson(Map<String, dynamic> json) =>
      _$$DecisionImplFromJson(json);

  @override
  final String description;
  @override
  @JsonKey(name: 'importance_score')
  final String importanceScore;
  @override
  @JsonKey(name: 'decision_type')
  final String decisionType;
  final List<String> _stakeholdersAffected;
  @override
  @JsonKey(name: 'stakeholders_affected')
  List<String> get stakeholdersAffected {
    if (_stakeholdersAffected is EqualUnmodifiableListView)
      return _stakeholdersAffected;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stakeholdersAffected);
  }

  @override
  final String? rationale;

  @override
  String toString() {
    return 'Decision(description: $description, importanceScore: $importanceScore, decisionType: $decisionType, stakeholdersAffected: $stakeholdersAffected, rationale: $rationale)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DecisionImpl &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.importanceScore, importanceScore) ||
                other.importanceScore == importanceScore) &&
            (identical(other.decisionType, decisionType) ||
                other.decisionType == decisionType) &&
            const DeepCollectionEquality().equals(
              other._stakeholdersAffected,
              _stakeholdersAffected,
            ) &&
            (identical(other.rationale, rationale) ||
                other.rationale == rationale));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    description,
    importanceScore,
    decisionType,
    const DeepCollectionEquality().hash(_stakeholdersAffected),
    rationale,
  );

  /// Create a copy of Decision
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DecisionImplCopyWith<_$DecisionImpl> get copyWith =>
      __$$DecisionImplCopyWithImpl<_$DecisionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DecisionImplToJson(this);
  }
}

abstract class _Decision implements Decision {
  const factory _Decision({
    required final String description,
    @JsonKey(name: 'importance_score') final String importanceScore,
    @JsonKey(name: 'decision_type') final String decisionType,
    @JsonKey(name: 'stakeholders_affected')
    final List<String> stakeholdersAffected,
    final String? rationale,
  }) = _$DecisionImpl;

  factory _Decision.fromJson(Map<String, dynamic> json) =
      _$DecisionImpl.fromJson;

  @override
  String get description;
  @override
  @JsonKey(name: 'importance_score')
  String get importanceScore;
  @override
  @JsonKey(name: 'decision_type')
  String get decisionType;
  @override
  @JsonKey(name: 'stakeholders_affected')
  List<String> get stakeholdersAffected;
  @override
  String? get rationale;

  /// Create a copy of Decision
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DecisionImplCopyWith<_$DecisionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AgendaItem _$AgendaItemFromJson(Map<String, dynamic> json) {
  return _AgendaItem.fromJson(json);
}

/// @nodoc
mixin _$AgendaItem {
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get priority => throw _privateConstructorUsedError;
  @JsonKey(name: 'estimated_time')
  int get estimatedTime => throw _privateConstructorUsedError;
  String? get presenter => throw _privateConstructorUsedError;
  @JsonKey(name: 'related_action_items')
  List<String> get relatedActionItems => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;

  /// Serializes this AgendaItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AgendaItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AgendaItemCopyWith<AgendaItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AgendaItemCopyWith<$Res> {
  factory $AgendaItemCopyWith(
    AgendaItem value,
    $Res Function(AgendaItem) then,
  ) = _$AgendaItemCopyWithImpl<$Res, AgendaItem>;
  @useResult
  $Res call({
    String title,
    String description,
    String priority,
    @JsonKey(name: 'estimated_time') int estimatedTime,
    String? presenter,
    @JsonKey(name: 'related_action_items') List<String> relatedActionItems,
    String category,
  });
}

/// @nodoc
class _$AgendaItemCopyWithImpl<$Res, $Val extends AgendaItem>
    implements $AgendaItemCopyWith<$Res> {
  _$AgendaItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AgendaItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? description = null,
    Object? priority = null,
    Object? estimatedTime = null,
    Object? presenter = freezed,
    Object? relatedActionItems = null,
    Object? category = null,
  }) {
    return _then(
      _value.copyWith(
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as String,
            estimatedTime: null == estimatedTime
                ? _value.estimatedTime
                : estimatedTime // ignore: cast_nullable_to_non_nullable
                      as int,
            presenter: freezed == presenter
                ? _value.presenter
                : presenter // ignore: cast_nullable_to_non_nullable
                      as String?,
            relatedActionItems: null == relatedActionItems
                ? _value.relatedActionItems
                : relatedActionItems // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AgendaItemImplCopyWith<$Res>
    implements $AgendaItemCopyWith<$Res> {
  factory _$$AgendaItemImplCopyWith(
    _$AgendaItemImpl value,
    $Res Function(_$AgendaItemImpl) then,
  ) = __$$AgendaItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String title,
    String description,
    String priority,
    @JsonKey(name: 'estimated_time') int estimatedTime,
    String? presenter,
    @JsonKey(name: 'related_action_items') List<String> relatedActionItems,
    String category,
  });
}

/// @nodoc
class __$$AgendaItemImplCopyWithImpl<$Res>
    extends _$AgendaItemCopyWithImpl<$Res, _$AgendaItemImpl>
    implements _$$AgendaItemImplCopyWith<$Res> {
  __$$AgendaItemImplCopyWithImpl(
    _$AgendaItemImpl _value,
    $Res Function(_$AgendaItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AgendaItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? description = null,
    Object? priority = null,
    Object? estimatedTime = null,
    Object? presenter = freezed,
    Object? relatedActionItems = null,
    Object? category = null,
  }) {
    return _then(
      _$AgendaItemImpl(
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as String,
        estimatedTime: null == estimatedTime
            ? _value.estimatedTime
            : estimatedTime // ignore: cast_nullable_to_non_nullable
                  as int,
        presenter: freezed == presenter
            ? _value.presenter
            : presenter // ignore: cast_nullable_to_non_nullable
                  as String?,
        relatedActionItems: null == relatedActionItems
            ? _value._relatedActionItems
            : relatedActionItems // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AgendaItemImpl implements _AgendaItem {
  const _$AgendaItemImpl({
    required this.title,
    required this.description,
    this.priority = 'medium',
    @JsonKey(name: 'estimated_time') this.estimatedTime = 15,
    this.presenter,
    @JsonKey(name: 'related_action_items')
    final List<String> relatedActionItems = const [],
    this.category = 'discussion',
  }) : _relatedActionItems = relatedActionItems;

  factory _$AgendaItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$AgendaItemImplFromJson(json);

  @override
  final String title;
  @override
  final String description;
  @override
  @JsonKey()
  final String priority;
  @override
  @JsonKey(name: 'estimated_time')
  final int estimatedTime;
  @override
  final String? presenter;
  final List<String> _relatedActionItems;
  @override
  @JsonKey(name: 'related_action_items')
  List<String> get relatedActionItems {
    if (_relatedActionItems is EqualUnmodifiableListView)
      return _relatedActionItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_relatedActionItems);
  }

  @override
  @JsonKey()
  final String category;

  @override
  String toString() {
    return 'AgendaItem(title: $title, description: $description, priority: $priority, estimatedTime: $estimatedTime, presenter: $presenter, relatedActionItems: $relatedActionItems, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AgendaItemImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.estimatedTime, estimatedTime) ||
                other.estimatedTime == estimatedTime) &&
            (identical(other.presenter, presenter) ||
                other.presenter == presenter) &&
            const DeepCollectionEquality().equals(
              other._relatedActionItems,
              _relatedActionItems,
            ) &&
            (identical(other.category, category) ||
                other.category == category));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    title,
    description,
    priority,
    estimatedTime,
    presenter,
    const DeepCollectionEquality().hash(_relatedActionItems),
    category,
  );

  /// Create a copy of AgendaItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AgendaItemImplCopyWith<_$AgendaItemImpl> get copyWith =>
      __$$AgendaItemImplCopyWithImpl<_$AgendaItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AgendaItemImplToJson(this);
  }
}

abstract class _AgendaItem implements AgendaItem {
  const factory _AgendaItem({
    required final String title,
    required final String description,
    final String priority,
    @JsonKey(name: 'estimated_time') final int estimatedTime,
    final String? presenter,
    @JsonKey(name: 'related_action_items')
    final List<String> relatedActionItems,
    final String category,
  }) = _$AgendaItemImpl;

  factory _AgendaItem.fromJson(Map<String, dynamic> json) =
      _$AgendaItemImpl.fromJson;

  @override
  String get title;
  @override
  String get description;
  @override
  String get priority;
  @override
  @JsonKey(name: 'estimated_time')
  int get estimatedTime;
  @override
  String? get presenter;
  @override
  @JsonKey(name: 'related_action_items')
  List<String> get relatedActionItems;
  @override
  String get category;

  /// Create a copy of AgendaItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AgendaItemImplCopyWith<_$AgendaItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UnansweredQuestion _$UnansweredQuestionFromJson(Map<String, dynamic> json) {
  return _UnansweredQuestion.fromJson(json);
}

/// @nodoc
mixin _$UnansweredQuestion {
  String get question => throw _privateConstructorUsedError;
  String get context => throw _privateConstructorUsedError;
  String get urgency => throw _privateConstructorUsedError;
  @JsonKey(name: 'raised_by')
  String? get raisedBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'topic_area')
  String? get topicArea => throw _privateConstructorUsedError;

  /// Serializes this UnansweredQuestion to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UnansweredQuestion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UnansweredQuestionCopyWith<UnansweredQuestion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UnansweredQuestionCopyWith<$Res> {
  factory $UnansweredQuestionCopyWith(
    UnansweredQuestion value,
    $Res Function(UnansweredQuestion) then,
  ) = _$UnansweredQuestionCopyWithImpl<$Res, UnansweredQuestion>;
  @useResult
  $Res call({
    String question,
    String context,
    String urgency,
    @JsonKey(name: 'raised_by') String? raisedBy,
    @JsonKey(name: 'topic_area') String? topicArea,
  });
}

/// @nodoc
class _$UnansweredQuestionCopyWithImpl<$Res, $Val extends UnansweredQuestion>
    implements $UnansweredQuestionCopyWith<$Res> {
  _$UnansweredQuestionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UnansweredQuestion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? question = null,
    Object? context = null,
    Object? urgency = null,
    Object? raisedBy = freezed,
    Object? topicArea = freezed,
  }) {
    return _then(
      _value.copyWith(
            question: null == question
                ? _value.question
                : question // ignore: cast_nullable_to_non_nullable
                      as String,
            context: null == context
                ? _value.context
                : context // ignore: cast_nullable_to_non_nullable
                      as String,
            urgency: null == urgency
                ? _value.urgency
                : urgency // ignore: cast_nullable_to_non_nullable
                      as String,
            raisedBy: freezed == raisedBy
                ? _value.raisedBy
                : raisedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            topicArea: freezed == topicArea
                ? _value.topicArea
                : topicArea // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UnansweredQuestionImplCopyWith<$Res>
    implements $UnansweredQuestionCopyWith<$Res> {
  factory _$$UnansweredQuestionImplCopyWith(
    _$UnansweredQuestionImpl value,
    $Res Function(_$UnansweredQuestionImpl) then,
  ) = __$$UnansweredQuestionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String question,
    String context,
    String urgency,
    @JsonKey(name: 'raised_by') String? raisedBy,
    @JsonKey(name: 'topic_area') String? topicArea,
  });
}

/// @nodoc
class __$$UnansweredQuestionImplCopyWithImpl<$Res>
    extends _$UnansweredQuestionCopyWithImpl<$Res, _$UnansweredQuestionImpl>
    implements _$$UnansweredQuestionImplCopyWith<$Res> {
  __$$UnansweredQuestionImplCopyWithImpl(
    _$UnansweredQuestionImpl _value,
    $Res Function(_$UnansweredQuestionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UnansweredQuestion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? question = null,
    Object? context = null,
    Object? urgency = null,
    Object? raisedBy = freezed,
    Object? topicArea = freezed,
  }) {
    return _then(
      _$UnansweredQuestionImpl(
        question: null == question
            ? _value.question
            : question // ignore: cast_nullable_to_non_nullable
                  as String,
        context: null == context
            ? _value.context
            : context // ignore: cast_nullable_to_non_nullable
                  as String,
        urgency: null == urgency
            ? _value.urgency
            : urgency // ignore: cast_nullable_to_non_nullable
                  as String,
        raisedBy: freezed == raisedBy
            ? _value.raisedBy
            : raisedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        topicArea: freezed == topicArea
            ? _value.topicArea
            : topicArea // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UnansweredQuestionImpl implements _UnansweredQuestion {
  const _$UnansweredQuestionImpl({
    required this.question,
    required this.context,
    this.urgency = 'medium',
    @JsonKey(name: 'raised_by') this.raisedBy,
    @JsonKey(name: 'topic_area') this.topicArea,
  });

  factory _$UnansweredQuestionImpl.fromJson(Map<String, dynamic> json) =>
      _$$UnansweredQuestionImplFromJson(json);

  @override
  final String question;
  @override
  final String context;
  @override
  @JsonKey()
  final String urgency;
  @override
  @JsonKey(name: 'raised_by')
  final String? raisedBy;
  @override
  @JsonKey(name: 'topic_area')
  final String? topicArea;

  @override
  String toString() {
    return 'UnansweredQuestion(question: $question, context: $context, urgency: $urgency, raisedBy: $raisedBy, topicArea: $topicArea)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnansweredQuestionImpl &&
            (identical(other.question, question) ||
                other.question == question) &&
            (identical(other.context, context) || other.context == context) &&
            (identical(other.urgency, urgency) || other.urgency == urgency) &&
            (identical(other.raisedBy, raisedBy) ||
                other.raisedBy == raisedBy) &&
            (identical(other.topicArea, topicArea) ||
                other.topicArea == topicArea));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, question, context, urgency, raisedBy, topicArea);

  /// Create a copy of UnansweredQuestion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnansweredQuestionImplCopyWith<_$UnansweredQuestionImpl> get copyWith =>
      __$$UnansweredQuestionImplCopyWithImpl<_$UnansweredQuestionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UnansweredQuestionImplToJson(this);
  }
}

abstract class _UnansweredQuestion implements UnansweredQuestion {
  const factory _UnansweredQuestion({
    required final String question,
    required final String context,
    final String urgency,
    @JsonKey(name: 'raised_by') final String? raisedBy,
    @JsonKey(name: 'topic_area') final String? topicArea,
  }) = _$UnansweredQuestionImpl;

  factory _UnansweredQuestion.fromJson(Map<String, dynamic> json) =
      _$UnansweredQuestionImpl.fromJson;

  @override
  String get question;
  @override
  String get context;
  @override
  String get urgency;
  @override
  @JsonKey(name: 'raised_by')
  String? get raisedBy;
  @override
  @JsonKey(name: 'topic_area')
  String? get topicArea;

  /// Create a copy of UnansweredQuestion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnansweredQuestionImplCopyWith<_$UnansweredQuestionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EffectivenessScore _$EffectivenessScoreFromJson(Map<String, dynamic> json) {
  return _EffectivenessScore.fromJson(json);
}

/// @nodoc
mixin _$EffectivenessScore {
  double get overall => throw _privateConstructorUsedError;
  @JsonKey(name: 'agenda_coverage')
  double get agendaCoverage => throw _privateConstructorUsedError;
  @JsonKey(name: 'decision_velocity')
  double get decisionVelocity => throw _privateConstructorUsedError;
  @JsonKey(name: 'time_efficiency')
  double get timeEfficiency => throw _privateConstructorUsedError;
  @JsonKey(name: 'participation_balance')
  double get participationBalance => throw _privateConstructorUsedError;
  @JsonKey(name: 'clarity_score')
  double get clarityScore => throw _privateConstructorUsedError;

  /// Serializes this EffectivenessScore to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EffectivenessScore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EffectivenessScoreCopyWith<EffectivenessScore> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EffectivenessScoreCopyWith<$Res> {
  factory $EffectivenessScoreCopyWith(
    EffectivenessScore value,
    $Res Function(EffectivenessScore) then,
  ) = _$EffectivenessScoreCopyWithImpl<$Res, EffectivenessScore>;
  @useResult
  $Res call({
    double overall,
    @JsonKey(name: 'agenda_coverage') double agendaCoverage,
    @JsonKey(name: 'decision_velocity') double decisionVelocity,
    @JsonKey(name: 'time_efficiency') double timeEfficiency,
    @JsonKey(name: 'participation_balance') double participationBalance,
    @JsonKey(name: 'clarity_score') double clarityScore,
  });
}

/// @nodoc
class _$EffectivenessScoreCopyWithImpl<$Res, $Val extends EffectivenessScore>
    implements $EffectivenessScoreCopyWith<$Res> {
  _$EffectivenessScoreCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EffectivenessScore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? overall = null,
    Object? agendaCoverage = null,
    Object? decisionVelocity = null,
    Object? timeEfficiency = null,
    Object? participationBalance = null,
    Object? clarityScore = null,
  }) {
    return _then(
      _value.copyWith(
            overall: null == overall
                ? _value.overall
                : overall // ignore: cast_nullable_to_non_nullable
                      as double,
            agendaCoverage: null == agendaCoverage
                ? _value.agendaCoverage
                : agendaCoverage // ignore: cast_nullable_to_non_nullable
                      as double,
            decisionVelocity: null == decisionVelocity
                ? _value.decisionVelocity
                : decisionVelocity // ignore: cast_nullable_to_non_nullable
                      as double,
            timeEfficiency: null == timeEfficiency
                ? _value.timeEfficiency
                : timeEfficiency // ignore: cast_nullable_to_non_nullable
                      as double,
            participationBalance: null == participationBalance
                ? _value.participationBalance
                : participationBalance // ignore: cast_nullable_to_non_nullable
                      as double,
            clarityScore: null == clarityScore
                ? _value.clarityScore
                : clarityScore // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EffectivenessScoreImplCopyWith<$Res>
    implements $EffectivenessScoreCopyWith<$Res> {
  factory _$$EffectivenessScoreImplCopyWith(
    _$EffectivenessScoreImpl value,
    $Res Function(_$EffectivenessScoreImpl) then,
  ) = __$$EffectivenessScoreImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double overall,
    @JsonKey(name: 'agenda_coverage') double agendaCoverage,
    @JsonKey(name: 'decision_velocity') double decisionVelocity,
    @JsonKey(name: 'time_efficiency') double timeEfficiency,
    @JsonKey(name: 'participation_balance') double participationBalance,
    @JsonKey(name: 'clarity_score') double clarityScore,
  });
}

/// @nodoc
class __$$EffectivenessScoreImplCopyWithImpl<$Res>
    extends _$EffectivenessScoreCopyWithImpl<$Res, _$EffectivenessScoreImpl>
    implements _$$EffectivenessScoreImplCopyWith<$Res> {
  __$$EffectivenessScoreImplCopyWithImpl(
    _$EffectivenessScoreImpl _value,
    $Res Function(_$EffectivenessScoreImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EffectivenessScore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? overall = null,
    Object? agendaCoverage = null,
    Object? decisionVelocity = null,
    Object? timeEfficiency = null,
    Object? participationBalance = null,
    Object? clarityScore = null,
  }) {
    return _then(
      _$EffectivenessScoreImpl(
        overall: null == overall
            ? _value.overall
            : overall // ignore: cast_nullable_to_non_nullable
                  as double,
        agendaCoverage: null == agendaCoverage
            ? _value.agendaCoverage
            : agendaCoverage // ignore: cast_nullable_to_non_nullable
                  as double,
        decisionVelocity: null == decisionVelocity
            ? _value.decisionVelocity
            : decisionVelocity // ignore: cast_nullable_to_non_nullable
                  as double,
        timeEfficiency: null == timeEfficiency
            ? _value.timeEfficiency
            : timeEfficiency // ignore: cast_nullable_to_non_nullable
                  as double,
        participationBalance: null == participationBalance
            ? _value.participationBalance
            : participationBalance // ignore: cast_nullable_to_non_nullable
                  as double,
        clarityScore: null == clarityScore
            ? _value.clarityScore
            : clarityScore // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EffectivenessScoreImpl implements _EffectivenessScore {
  const _$EffectivenessScoreImpl({
    this.overall = 0.0,
    @JsonKey(name: 'agenda_coverage') this.agendaCoverage = 0.0,
    @JsonKey(name: 'decision_velocity') this.decisionVelocity = 0.0,
    @JsonKey(name: 'time_efficiency') this.timeEfficiency = 0.0,
    @JsonKey(name: 'participation_balance') this.participationBalance = 0.0,
    @JsonKey(name: 'clarity_score') this.clarityScore = 0.0,
  });

  factory _$EffectivenessScoreImpl.fromJson(Map<String, dynamic> json) =>
      _$$EffectivenessScoreImplFromJson(json);

  @override
  @JsonKey()
  final double overall;
  @override
  @JsonKey(name: 'agenda_coverage')
  final double agendaCoverage;
  @override
  @JsonKey(name: 'decision_velocity')
  final double decisionVelocity;
  @override
  @JsonKey(name: 'time_efficiency')
  final double timeEfficiency;
  @override
  @JsonKey(name: 'participation_balance')
  final double participationBalance;
  @override
  @JsonKey(name: 'clarity_score')
  final double clarityScore;

  @override
  String toString() {
    return 'EffectivenessScore(overall: $overall, agendaCoverage: $agendaCoverage, decisionVelocity: $decisionVelocity, timeEfficiency: $timeEfficiency, participationBalance: $participationBalance, clarityScore: $clarityScore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EffectivenessScoreImpl &&
            (identical(other.overall, overall) || other.overall == overall) &&
            (identical(other.agendaCoverage, agendaCoverage) ||
                other.agendaCoverage == agendaCoverage) &&
            (identical(other.decisionVelocity, decisionVelocity) ||
                other.decisionVelocity == decisionVelocity) &&
            (identical(other.timeEfficiency, timeEfficiency) ||
                other.timeEfficiency == timeEfficiency) &&
            (identical(other.participationBalance, participationBalance) ||
                other.participationBalance == participationBalance) &&
            (identical(other.clarityScore, clarityScore) ||
                other.clarityScore == clarityScore));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    overall,
    agendaCoverage,
    decisionVelocity,
    timeEfficiency,
    participationBalance,
    clarityScore,
  );

  /// Create a copy of EffectivenessScore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EffectivenessScoreImplCopyWith<_$EffectivenessScoreImpl> get copyWith =>
      __$$EffectivenessScoreImplCopyWithImpl<_$EffectivenessScoreImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$EffectivenessScoreImplToJson(this);
  }
}

abstract class _EffectivenessScore implements EffectivenessScore {
  const factory _EffectivenessScore({
    final double overall,
    @JsonKey(name: 'agenda_coverage') final double agendaCoverage,
    @JsonKey(name: 'decision_velocity') final double decisionVelocity,
    @JsonKey(name: 'time_efficiency') final double timeEfficiency,
    @JsonKey(name: 'participation_balance') final double participationBalance,
    @JsonKey(name: 'clarity_score') final double clarityScore,
  }) = _$EffectivenessScoreImpl;

  factory _EffectivenessScore.fromJson(Map<String, dynamic> json) =
      _$EffectivenessScoreImpl.fromJson;

  @override
  double get overall;
  @override
  @JsonKey(name: 'agenda_coverage')
  double get agendaCoverage;
  @override
  @JsonKey(name: 'decision_velocity')
  double get decisionVelocity;
  @override
  @JsonKey(name: 'time_efficiency')
  double get timeEfficiency;
  @override
  @JsonKey(name: 'participation_balance')
  double get participationBalance;
  @override
  @JsonKey(name: 'clarity_score')
  double get clarityScore;

  /// Create a copy of EffectivenessScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EffectivenessScoreImplCopyWith<_$EffectivenessScoreImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ImprovementSuggestion _$ImprovementSuggestionFromJson(
  Map<String, dynamic> json,
) {
  return _ImprovementSuggestion.fromJson(json);
}

/// @nodoc
mixin _$ImprovementSuggestion {
  String get suggestion => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String get priority => throw _privateConstructorUsedError;
  @JsonKey(name: 'expected_impact')
  String? get expectedImpact => throw _privateConstructorUsedError;

  /// Serializes this ImprovementSuggestion to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ImprovementSuggestion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ImprovementSuggestionCopyWith<ImprovementSuggestion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImprovementSuggestionCopyWith<$Res> {
  factory $ImprovementSuggestionCopyWith(
    ImprovementSuggestion value,
    $Res Function(ImprovementSuggestion) then,
  ) = _$ImprovementSuggestionCopyWithImpl<$Res, ImprovementSuggestion>;
  @useResult
  $Res call({
    String suggestion,
    String category,
    String priority,
    @JsonKey(name: 'expected_impact') String? expectedImpact,
  });
}

/// @nodoc
class _$ImprovementSuggestionCopyWithImpl<
  $Res,
  $Val extends ImprovementSuggestion
>
    implements $ImprovementSuggestionCopyWith<$Res> {
  _$ImprovementSuggestionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ImprovementSuggestion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? suggestion = null,
    Object? category = null,
    Object? priority = null,
    Object? expectedImpact = freezed,
  }) {
    return _then(
      _value.copyWith(
            suggestion: null == suggestion
                ? _value.suggestion
                : suggestion // ignore: cast_nullable_to_non_nullable
                      as String,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as String,
            expectedImpact: freezed == expectedImpact
                ? _value.expectedImpact
                : expectedImpact // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ImprovementSuggestionImplCopyWith<$Res>
    implements $ImprovementSuggestionCopyWith<$Res> {
  factory _$$ImprovementSuggestionImplCopyWith(
    _$ImprovementSuggestionImpl value,
    $Res Function(_$ImprovementSuggestionImpl) then,
  ) = __$$ImprovementSuggestionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String suggestion,
    String category,
    String priority,
    @JsonKey(name: 'expected_impact') String? expectedImpact,
  });
}

/// @nodoc
class __$$ImprovementSuggestionImplCopyWithImpl<$Res>
    extends
        _$ImprovementSuggestionCopyWithImpl<$Res, _$ImprovementSuggestionImpl>
    implements _$$ImprovementSuggestionImplCopyWith<$Res> {
  __$$ImprovementSuggestionImplCopyWithImpl(
    _$ImprovementSuggestionImpl _value,
    $Res Function(_$ImprovementSuggestionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ImprovementSuggestion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? suggestion = null,
    Object? category = null,
    Object? priority = null,
    Object? expectedImpact = freezed,
  }) {
    return _then(
      _$ImprovementSuggestionImpl(
        suggestion: null == suggestion
            ? _value.suggestion
            : suggestion // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as String,
        expectedImpact: freezed == expectedImpact
            ? _value.expectedImpact
            : expectedImpact // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ImprovementSuggestionImpl implements _ImprovementSuggestion {
  const _$ImprovementSuggestionImpl({
    required this.suggestion,
    this.category = 'general',
    this.priority = 'medium',
    @JsonKey(name: 'expected_impact') this.expectedImpact,
  });

  factory _$ImprovementSuggestionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ImprovementSuggestionImplFromJson(json);

  @override
  final String suggestion;
  @override
  @JsonKey()
  final String category;
  @override
  @JsonKey()
  final String priority;
  @override
  @JsonKey(name: 'expected_impact')
  final String? expectedImpact;

  @override
  String toString() {
    return 'ImprovementSuggestion(suggestion: $suggestion, category: $category, priority: $priority, expectedImpact: $expectedImpact)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImprovementSuggestionImpl &&
            (identical(other.suggestion, suggestion) ||
                other.suggestion == suggestion) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.expectedImpact, expectedImpact) ||
                other.expectedImpact == expectedImpact));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, suggestion, category, priority, expectedImpact);

  /// Create a copy of ImprovementSuggestion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImprovementSuggestionImplCopyWith<_$ImprovementSuggestionImpl>
  get copyWith =>
      __$$ImprovementSuggestionImplCopyWithImpl<_$ImprovementSuggestionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ImprovementSuggestionImplToJson(this);
  }
}

abstract class _ImprovementSuggestion implements ImprovementSuggestion {
  const factory _ImprovementSuggestion({
    required final String suggestion,
    final String category,
    final String priority,
    @JsonKey(name: 'expected_impact') final String? expectedImpact,
  }) = _$ImprovementSuggestionImpl;

  factory _ImprovementSuggestion.fromJson(Map<String, dynamic> json) =
      _$ImprovementSuggestionImpl.fromJson;

  @override
  String get suggestion;
  @override
  String get category;
  @override
  String get priority;
  @override
  @JsonKey(name: 'expected_impact')
  String? get expectedImpact;

  /// Create a copy of ImprovementSuggestion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImprovementSuggestionImplCopyWith<_$ImprovementSuggestionImpl>
  get copyWith => throw _privateConstructorUsedError;
}

LessonLearned _$LessonLearnedFromJson(Map<String, dynamic> json) {
  return _LessonLearned.fromJson(json);
}

/// @nodoc
mixin _$LessonLearned {
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  @JsonKey(name: 'lesson_type')
  String get lessonType => throw _privateConstructorUsedError;
  String get impact => throw _privateConstructorUsedError;
  String? get recommendation => throw _privateConstructorUsedError;
  String? get context => throw _privateConstructorUsedError;

  /// Serializes this LessonLearned to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LessonLearned
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LessonLearnedCopyWith<LessonLearned> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LessonLearnedCopyWith<$Res> {
  factory $LessonLearnedCopyWith(
    LessonLearned value,
    $Res Function(LessonLearned) then,
  ) = _$LessonLearnedCopyWithImpl<$Res, LessonLearned>;
  @useResult
  $Res call({
    String title,
    String description,
    String category,
    @JsonKey(name: 'lesson_type') String lessonType,
    String impact,
    String? recommendation,
    String? context,
  });
}

/// @nodoc
class _$LessonLearnedCopyWithImpl<$Res, $Val extends LessonLearned>
    implements $LessonLearnedCopyWith<$Res> {
  _$LessonLearnedCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LessonLearned
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? description = null,
    Object? category = null,
    Object? lessonType = null,
    Object? impact = null,
    Object? recommendation = freezed,
    Object? context = freezed,
  }) {
    return _then(
      _value.copyWith(
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            lessonType: null == lessonType
                ? _value.lessonType
                : lessonType // ignore: cast_nullable_to_non_nullable
                      as String,
            impact: null == impact
                ? _value.impact
                : impact // ignore: cast_nullable_to_non_nullable
                      as String,
            recommendation: freezed == recommendation
                ? _value.recommendation
                : recommendation // ignore: cast_nullable_to_non_nullable
                      as String?,
            context: freezed == context
                ? _value.context
                : context // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LessonLearnedImplCopyWith<$Res>
    implements $LessonLearnedCopyWith<$Res> {
  factory _$$LessonLearnedImplCopyWith(
    _$LessonLearnedImpl value,
    $Res Function(_$LessonLearnedImpl) then,
  ) = __$$LessonLearnedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String title,
    String description,
    String category,
    @JsonKey(name: 'lesson_type') String lessonType,
    String impact,
    String? recommendation,
    String? context,
  });
}

/// @nodoc
class __$$LessonLearnedImplCopyWithImpl<$Res>
    extends _$LessonLearnedCopyWithImpl<$Res, _$LessonLearnedImpl>
    implements _$$LessonLearnedImplCopyWith<$Res> {
  __$$LessonLearnedImplCopyWithImpl(
    _$LessonLearnedImpl _value,
    $Res Function(_$LessonLearnedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LessonLearned
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? description = null,
    Object? category = null,
    Object? lessonType = null,
    Object? impact = null,
    Object? recommendation = freezed,
    Object? context = freezed,
  }) {
    return _then(
      _$LessonLearnedImpl(
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        lessonType: null == lessonType
            ? _value.lessonType
            : lessonType // ignore: cast_nullable_to_non_nullable
                  as String,
        impact: null == impact
            ? _value.impact
            : impact // ignore: cast_nullable_to_non_nullable
                  as String,
        recommendation: freezed == recommendation
            ? _value.recommendation
            : recommendation // ignore: cast_nullable_to_non_nullable
                  as String?,
        context: freezed == context
            ? _value.context
            : context // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LessonLearnedImpl implements _LessonLearned {
  const _$LessonLearnedImpl({
    required this.title,
    required this.description,
    this.category = 'other',
    @JsonKey(name: 'lesson_type') this.lessonType = 'improvement',
    this.impact = 'medium',
    this.recommendation,
    this.context,
  });

  factory _$LessonLearnedImpl.fromJson(Map<String, dynamic> json) =>
      _$$LessonLearnedImplFromJson(json);

  @override
  final String title;
  @override
  final String description;
  @override
  @JsonKey()
  final String category;
  @override
  @JsonKey(name: 'lesson_type')
  final String lessonType;
  @override
  @JsonKey()
  final String impact;
  @override
  final String? recommendation;
  @override
  final String? context;

  @override
  String toString() {
    return 'LessonLearned(title: $title, description: $description, category: $category, lessonType: $lessonType, impact: $impact, recommendation: $recommendation, context: $context)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LessonLearnedImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.lessonType, lessonType) ||
                other.lessonType == lessonType) &&
            (identical(other.impact, impact) || other.impact == impact) &&
            (identical(other.recommendation, recommendation) ||
                other.recommendation == recommendation) &&
            (identical(other.context, context) || other.context == context));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    title,
    description,
    category,
    lessonType,
    impact,
    recommendation,
    context,
  );

  /// Create a copy of LessonLearned
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LessonLearnedImplCopyWith<_$LessonLearnedImpl> get copyWith =>
      __$$LessonLearnedImplCopyWithImpl<_$LessonLearnedImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LessonLearnedImplToJson(this);
  }
}

abstract class _LessonLearned implements LessonLearned {
  const factory _LessonLearned({
    required final String title,
    required final String description,
    final String category,
    @JsonKey(name: 'lesson_type') final String lessonType,
    final String impact,
    final String? recommendation,
    final String? context,
  }) = _$LessonLearnedImpl;

  factory _LessonLearned.fromJson(Map<String, dynamic> json) =
      _$LessonLearnedImpl.fromJson;

  @override
  String get title;
  @override
  String get description;
  @override
  String get category;
  @override
  @JsonKey(name: 'lesson_type')
  String get lessonType;
  @override
  String get impact;
  @override
  String? get recommendation;
  @override
  String? get context;

  /// Create a copy of LessonLearned
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LessonLearnedImplCopyWith<_$LessonLearnedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CommunicationInsights _$CommunicationInsightsFromJson(
  Map<String, dynamic> json,
) {
  return _CommunicationInsights.fromJson(json);
}

/// @nodoc
mixin _$CommunicationInsights {
  @JsonKey(name: 'unanswered_questions', fromJson: _unansweredQuestionsFromJson)
  List<UnansweredQuestion> get unansweredQuestions =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'effectiveness_score', fromJson: _effectivenessScoreFromJson)
  EffectivenessScore? get effectivenessScore =>
      throw _privateConstructorUsedError;
  @JsonKey(
    name: 'improvement_suggestions',
    fromJson: _improvementSuggestionsFromJson,
  )
  List<ImprovementSuggestion> get improvementSuggestions =>
      throw _privateConstructorUsedError;

  /// Serializes this CommunicationInsights to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CommunicationInsights
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommunicationInsightsCopyWith<CommunicationInsights> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommunicationInsightsCopyWith<$Res> {
  factory $CommunicationInsightsCopyWith(
    CommunicationInsights value,
    $Res Function(CommunicationInsights) then,
  ) = _$CommunicationInsightsCopyWithImpl<$Res, CommunicationInsights>;
  @useResult
  $Res call({
    @JsonKey(
      name: 'unanswered_questions',
      fromJson: _unansweredQuestionsFromJson,
    )
    List<UnansweredQuestion> unansweredQuestions,
    @JsonKey(name: 'effectiveness_score', fromJson: _effectivenessScoreFromJson)
    EffectivenessScore? effectivenessScore,
    @JsonKey(
      name: 'improvement_suggestions',
      fromJson: _improvementSuggestionsFromJson,
    )
    List<ImprovementSuggestion> improvementSuggestions,
  });

  $EffectivenessScoreCopyWith<$Res>? get effectivenessScore;
}

/// @nodoc
class _$CommunicationInsightsCopyWithImpl<
  $Res,
  $Val extends CommunicationInsights
>
    implements $CommunicationInsightsCopyWith<$Res> {
  _$CommunicationInsightsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CommunicationInsights
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? unansweredQuestions = null,
    Object? effectivenessScore = freezed,
    Object? improvementSuggestions = null,
  }) {
    return _then(
      _value.copyWith(
            unansweredQuestions: null == unansweredQuestions
                ? _value.unansweredQuestions
                : unansweredQuestions // ignore: cast_nullable_to_non_nullable
                      as List<UnansweredQuestion>,
            effectivenessScore: freezed == effectivenessScore
                ? _value.effectivenessScore
                : effectivenessScore // ignore: cast_nullable_to_non_nullable
                      as EffectivenessScore?,
            improvementSuggestions: null == improvementSuggestions
                ? _value.improvementSuggestions
                : improvementSuggestions // ignore: cast_nullable_to_non_nullable
                      as List<ImprovementSuggestion>,
          )
          as $Val,
    );
  }

  /// Create a copy of CommunicationInsights
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EffectivenessScoreCopyWith<$Res>? get effectivenessScore {
    if (_value.effectivenessScore == null) {
      return null;
    }

    return $EffectivenessScoreCopyWith<$Res>(_value.effectivenessScore!, (
      value,
    ) {
      return _then(_value.copyWith(effectivenessScore: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CommunicationInsightsImplCopyWith<$Res>
    implements $CommunicationInsightsCopyWith<$Res> {
  factory _$$CommunicationInsightsImplCopyWith(
    _$CommunicationInsightsImpl value,
    $Res Function(_$CommunicationInsightsImpl) then,
  ) = __$$CommunicationInsightsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(
      name: 'unanswered_questions',
      fromJson: _unansweredQuestionsFromJson,
    )
    List<UnansweredQuestion> unansweredQuestions,
    @JsonKey(name: 'effectiveness_score', fromJson: _effectivenessScoreFromJson)
    EffectivenessScore? effectivenessScore,
    @JsonKey(
      name: 'improvement_suggestions',
      fromJson: _improvementSuggestionsFromJson,
    )
    List<ImprovementSuggestion> improvementSuggestions,
  });

  @override
  $EffectivenessScoreCopyWith<$Res>? get effectivenessScore;
}

/// @nodoc
class __$$CommunicationInsightsImplCopyWithImpl<$Res>
    extends
        _$CommunicationInsightsCopyWithImpl<$Res, _$CommunicationInsightsImpl>
    implements _$$CommunicationInsightsImplCopyWith<$Res> {
  __$$CommunicationInsightsImplCopyWithImpl(
    _$CommunicationInsightsImpl _value,
    $Res Function(_$CommunicationInsightsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CommunicationInsights
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? unansweredQuestions = null,
    Object? effectivenessScore = freezed,
    Object? improvementSuggestions = null,
  }) {
    return _then(
      _$CommunicationInsightsImpl(
        unansweredQuestions: null == unansweredQuestions
            ? _value._unansweredQuestions
            : unansweredQuestions // ignore: cast_nullable_to_non_nullable
                  as List<UnansweredQuestion>,
        effectivenessScore: freezed == effectivenessScore
            ? _value.effectivenessScore
            : effectivenessScore // ignore: cast_nullable_to_non_nullable
                  as EffectivenessScore?,
        improvementSuggestions: null == improvementSuggestions
            ? _value._improvementSuggestions
            : improvementSuggestions // ignore: cast_nullable_to_non_nullable
                  as List<ImprovementSuggestion>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CommunicationInsightsImpl implements _CommunicationInsights {
  const _$CommunicationInsightsImpl({
    @JsonKey(
      name: 'unanswered_questions',
      fromJson: _unansweredQuestionsFromJson,
    )
    final List<UnansweredQuestion> unansweredQuestions = const [],
    @JsonKey(name: 'effectiveness_score', fromJson: _effectivenessScoreFromJson)
    this.effectivenessScore,
    @JsonKey(
      name: 'improvement_suggestions',
      fromJson: _improvementSuggestionsFromJson,
    )
    final List<ImprovementSuggestion> improvementSuggestions = const [],
  }) : _unansweredQuestions = unansweredQuestions,
       _improvementSuggestions = improvementSuggestions;

  factory _$CommunicationInsightsImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommunicationInsightsImplFromJson(json);

  final List<UnansweredQuestion> _unansweredQuestions;
  @override
  @JsonKey(name: 'unanswered_questions', fromJson: _unansweredQuestionsFromJson)
  List<UnansweredQuestion> get unansweredQuestions {
    if (_unansweredQuestions is EqualUnmodifiableListView)
      return _unansweredQuestions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_unansweredQuestions);
  }

  @override
  @JsonKey(name: 'effectiveness_score', fromJson: _effectivenessScoreFromJson)
  final EffectivenessScore? effectivenessScore;
  final List<ImprovementSuggestion> _improvementSuggestions;
  @override
  @JsonKey(
    name: 'improvement_suggestions',
    fromJson: _improvementSuggestionsFromJson,
  )
  List<ImprovementSuggestion> get improvementSuggestions {
    if (_improvementSuggestions is EqualUnmodifiableListView)
      return _improvementSuggestions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_improvementSuggestions);
  }

  @override
  String toString() {
    return 'CommunicationInsights(unansweredQuestions: $unansweredQuestions, effectivenessScore: $effectivenessScore, improvementSuggestions: $improvementSuggestions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommunicationInsightsImpl &&
            const DeepCollectionEquality().equals(
              other._unansweredQuestions,
              _unansweredQuestions,
            ) &&
            (identical(other.effectivenessScore, effectivenessScore) ||
                other.effectivenessScore == effectivenessScore) &&
            const DeepCollectionEquality().equals(
              other._improvementSuggestions,
              _improvementSuggestions,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_unansweredQuestions),
    effectivenessScore,
    const DeepCollectionEquality().hash(_improvementSuggestions),
  );

  /// Create a copy of CommunicationInsights
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CommunicationInsightsImplCopyWith<_$CommunicationInsightsImpl>
  get copyWith =>
      __$$CommunicationInsightsImplCopyWithImpl<_$CommunicationInsightsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CommunicationInsightsImplToJson(this);
  }
}

abstract class _CommunicationInsights implements CommunicationInsights {
  const factory _CommunicationInsights({
    @JsonKey(
      name: 'unanswered_questions',
      fromJson: _unansweredQuestionsFromJson,
    )
    final List<UnansweredQuestion> unansweredQuestions,
    @JsonKey(name: 'effectiveness_score', fromJson: _effectivenessScoreFromJson)
    final EffectivenessScore? effectivenessScore,
    @JsonKey(
      name: 'improvement_suggestions',
      fromJson: _improvementSuggestionsFromJson,
    )
    final List<ImprovementSuggestion> improvementSuggestions,
  }) = _$CommunicationInsightsImpl;

  factory _CommunicationInsights.fromJson(Map<String, dynamic> json) =
      _$CommunicationInsightsImpl.fromJson;

  @override
  @JsonKey(name: 'unanswered_questions', fromJson: _unansweredQuestionsFromJson)
  List<UnansweredQuestion> get unansweredQuestions;
  @override
  @JsonKey(name: 'effectiveness_score', fromJson: _effectivenessScoreFromJson)
  EffectivenessScore? get effectivenessScore;
  @override
  @JsonKey(
    name: 'improvement_suggestions',
    fromJson: _improvementSuggestionsFromJson,
  )
  List<ImprovementSuggestion> get improvementSuggestions;

  /// Create a copy of CommunicationInsights
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommunicationInsightsImplCopyWith<_$CommunicationInsightsImpl>
  get copyWith => throw _privateConstructorUsedError;
}

SummaryModel _$SummaryModelFromJson(Map<String, dynamic> json) {
  return _SummaryModel.fromJson(json);
}

/// @nodoc
mixin _$SummaryModel {
  @JsonKey(name: 'summary_id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'project_id')
  String? get projectId => throw _privateConstructorUsedError;
  @JsonKey(name: 'content_id')
  String? get contentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'summary_type')
  SummaryType get summaryType => throw _privateConstructorUsedError;
  String get subject => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  @JsonKey(name: 'key_points')
  List<String>? get keyPoints => throw _privateConstructorUsedError;
  @JsonKey(name: 'decisions', fromJson: _decisionsFromJson)
  List<Decision>? get decisions => throw _privateConstructorUsedError;
  @JsonKey(name: 'action_items', fromJson: _actionItemsFromJson)
  List<ActionItem>? get actionItems => throw _privateConstructorUsedError;
  @JsonKey(name: 'lessons_learned', fromJson: _lessonsLearnedFromJson)
  List<LessonLearned>? get lessonsLearned => throw _privateConstructorUsedError;
  @JsonKey(name: 'sentiment_analysis')
  Map<String, dynamic>? get sentimentAnalysis =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'risks')
  List<Map<String, dynamic>>? get risks => throw _privateConstructorUsedError;
  @JsonKey(name: 'blockers')
  List<Map<String, dynamic>>? get blockers =>
      throw _privateConstructorUsedError;
  @JsonKey(
    name: 'communication_insights',
    fromJson: _communicationInsightsFromJson,
  )
  CommunicationInsights? get communicationInsights =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'cross_meeting_insights')
  Map<String, dynamic>? get crossMeetingInsights =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'next_meeting_agenda', fromJson: _agendaItemsFromJson)
  List<AgendaItem>? get nextMeetingAgenda => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  @DateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_by')
  String? get createdBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_range_start')
  @DateTimeConverterNullable()
  DateTime? get dateRangeStart => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_range_end')
  @DateTimeConverterNullable()
  DateTime? get dateRangeEnd => throw _privateConstructorUsedError;
  @JsonKey(name: 'token_count')
  int? get tokenCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'generation_time_ms')
  int? get generationTimeMs => throw _privateConstructorUsedError;
  @JsonKey(name: 'llm_cost')
  double? get llmCost => throw _privateConstructorUsedError;
  String get format => throw _privateConstructorUsedError;

  /// Serializes this SummaryModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SummaryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SummaryModelCopyWith<SummaryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SummaryModelCopyWith<$Res> {
  factory $SummaryModelCopyWith(
    SummaryModel value,
    $Res Function(SummaryModel) then,
  ) = _$SummaryModelCopyWithImpl<$Res, SummaryModel>;
  @useResult
  $Res call({
    @JsonKey(name: 'summary_id') String id,
    @JsonKey(name: 'project_id') String? projectId,
    @JsonKey(name: 'content_id') String? contentId,
    @JsonKey(name: 'summary_type') SummaryType summaryType,
    String subject,
    String body,
    @JsonKey(name: 'key_points') List<String>? keyPoints,
    @JsonKey(name: 'decisions', fromJson: _decisionsFromJson)
    List<Decision>? decisions,
    @JsonKey(name: 'action_items', fromJson: _actionItemsFromJson)
    List<ActionItem>? actionItems,
    @JsonKey(name: 'lessons_learned', fromJson: _lessonsLearnedFromJson)
    List<LessonLearned>? lessonsLearned,
    @JsonKey(name: 'sentiment_analysis')
    Map<String, dynamic>? sentimentAnalysis,
    @JsonKey(name: 'risks') List<Map<String, dynamic>>? risks,
    @JsonKey(name: 'blockers') List<Map<String, dynamic>>? blockers,
    @JsonKey(
      name: 'communication_insights',
      fromJson: _communicationInsightsFromJson,
    )
    CommunicationInsights? communicationInsights,
    @JsonKey(name: 'cross_meeting_insights')
    Map<String, dynamic>? crossMeetingInsights,
    @JsonKey(name: 'next_meeting_agenda', fromJson: _agendaItemsFromJson)
    List<AgendaItem>? nextMeetingAgenda,
    @JsonKey(name: 'created_at') @DateTimeConverter() DateTime createdAt,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'date_range_start')
    @DateTimeConverterNullable()
    DateTime? dateRangeStart,
    @JsonKey(name: 'date_range_end')
    @DateTimeConverterNullable()
    DateTime? dateRangeEnd,
    @JsonKey(name: 'token_count') int? tokenCount,
    @JsonKey(name: 'generation_time_ms') int? generationTimeMs,
    @JsonKey(name: 'llm_cost') double? llmCost,
    String format,
  });

  $CommunicationInsightsCopyWith<$Res>? get communicationInsights;
}

/// @nodoc
class _$SummaryModelCopyWithImpl<$Res, $Val extends SummaryModel>
    implements $SummaryModelCopyWith<$Res> {
  _$SummaryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SummaryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = freezed,
    Object? contentId = freezed,
    Object? summaryType = null,
    Object? subject = null,
    Object? body = null,
    Object? keyPoints = freezed,
    Object? decisions = freezed,
    Object? actionItems = freezed,
    Object? lessonsLearned = freezed,
    Object? sentimentAnalysis = freezed,
    Object? risks = freezed,
    Object? blockers = freezed,
    Object? communicationInsights = freezed,
    Object? crossMeetingInsights = freezed,
    Object? nextMeetingAgenda = freezed,
    Object? createdAt = null,
    Object? createdBy = freezed,
    Object? dateRangeStart = freezed,
    Object? dateRangeEnd = freezed,
    Object? tokenCount = freezed,
    Object? generationTimeMs = freezed,
    Object? llmCost = freezed,
    Object? format = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            projectId: freezed == projectId
                ? _value.projectId
                : projectId // ignore: cast_nullable_to_non_nullable
                      as String?,
            contentId: freezed == contentId
                ? _value.contentId
                : contentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            summaryType: null == summaryType
                ? _value.summaryType
                : summaryType // ignore: cast_nullable_to_non_nullable
                      as SummaryType,
            subject: null == subject
                ? _value.subject
                : subject // ignore: cast_nullable_to_non_nullable
                      as String,
            body: null == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                      as String,
            keyPoints: freezed == keyPoints
                ? _value.keyPoints
                : keyPoints // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            decisions: freezed == decisions
                ? _value.decisions
                : decisions // ignore: cast_nullable_to_non_nullable
                      as List<Decision>?,
            actionItems: freezed == actionItems
                ? _value.actionItems
                : actionItems // ignore: cast_nullable_to_non_nullable
                      as List<ActionItem>?,
            lessonsLearned: freezed == lessonsLearned
                ? _value.lessonsLearned
                : lessonsLearned // ignore: cast_nullable_to_non_nullable
                      as List<LessonLearned>?,
            sentimentAnalysis: freezed == sentimentAnalysis
                ? _value.sentimentAnalysis
                : sentimentAnalysis // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            risks: freezed == risks
                ? _value.risks
                : risks // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>?,
            blockers: freezed == blockers
                ? _value.blockers
                : blockers // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>?,
            communicationInsights: freezed == communicationInsights
                ? _value.communicationInsights
                : communicationInsights // ignore: cast_nullable_to_non_nullable
                      as CommunicationInsights?,
            crossMeetingInsights: freezed == crossMeetingInsights
                ? _value.crossMeetingInsights
                : crossMeetingInsights // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            nextMeetingAgenda: freezed == nextMeetingAgenda
                ? _value.nextMeetingAgenda
                : nextMeetingAgenda // ignore: cast_nullable_to_non_nullable
                      as List<AgendaItem>?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            createdBy: freezed == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            dateRangeStart: freezed == dateRangeStart
                ? _value.dateRangeStart
                : dateRangeStart // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            dateRangeEnd: freezed == dateRangeEnd
                ? _value.dateRangeEnd
                : dateRangeEnd // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            tokenCount: freezed == tokenCount
                ? _value.tokenCount
                : tokenCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            generationTimeMs: freezed == generationTimeMs
                ? _value.generationTimeMs
                : generationTimeMs // ignore: cast_nullable_to_non_nullable
                      as int?,
            llmCost: freezed == llmCost
                ? _value.llmCost
                : llmCost // ignore: cast_nullable_to_non_nullable
                      as double?,
            format: null == format
                ? _value.format
                : format // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }

  /// Create a copy of SummaryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CommunicationInsightsCopyWith<$Res>? get communicationInsights {
    if (_value.communicationInsights == null) {
      return null;
    }

    return $CommunicationInsightsCopyWith<$Res>(_value.communicationInsights!, (
      value,
    ) {
      return _then(_value.copyWith(communicationInsights: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SummaryModelImplCopyWith<$Res>
    implements $SummaryModelCopyWith<$Res> {
  factory _$$SummaryModelImplCopyWith(
    _$SummaryModelImpl value,
    $Res Function(_$SummaryModelImpl) then,
  ) = __$$SummaryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'summary_id') String id,
    @JsonKey(name: 'project_id') String? projectId,
    @JsonKey(name: 'content_id') String? contentId,
    @JsonKey(name: 'summary_type') SummaryType summaryType,
    String subject,
    String body,
    @JsonKey(name: 'key_points') List<String>? keyPoints,
    @JsonKey(name: 'decisions', fromJson: _decisionsFromJson)
    List<Decision>? decisions,
    @JsonKey(name: 'action_items', fromJson: _actionItemsFromJson)
    List<ActionItem>? actionItems,
    @JsonKey(name: 'lessons_learned', fromJson: _lessonsLearnedFromJson)
    List<LessonLearned>? lessonsLearned,
    @JsonKey(name: 'sentiment_analysis')
    Map<String, dynamic>? sentimentAnalysis,
    @JsonKey(name: 'risks') List<Map<String, dynamic>>? risks,
    @JsonKey(name: 'blockers') List<Map<String, dynamic>>? blockers,
    @JsonKey(
      name: 'communication_insights',
      fromJson: _communicationInsightsFromJson,
    )
    CommunicationInsights? communicationInsights,
    @JsonKey(name: 'cross_meeting_insights')
    Map<String, dynamic>? crossMeetingInsights,
    @JsonKey(name: 'next_meeting_agenda', fromJson: _agendaItemsFromJson)
    List<AgendaItem>? nextMeetingAgenda,
    @JsonKey(name: 'created_at') @DateTimeConverter() DateTime createdAt,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'date_range_start')
    @DateTimeConverterNullable()
    DateTime? dateRangeStart,
    @JsonKey(name: 'date_range_end')
    @DateTimeConverterNullable()
    DateTime? dateRangeEnd,
    @JsonKey(name: 'token_count') int? tokenCount,
    @JsonKey(name: 'generation_time_ms') int? generationTimeMs,
    @JsonKey(name: 'llm_cost') double? llmCost,
    String format,
  });

  @override
  $CommunicationInsightsCopyWith<$Res>? get communicationInsights;
}

/// @nodoc
class __$$SummaryModelImplCopyWithImpl<$Res>
    extends _$SummaryModelCopyWithImpl<$Res, _$SummaryModelImpl>
    implements _$$SummaryModelImplCopyWith<$Res> {
  __$$SummaryModelImplCopyWithImpl(
    _$SummaryModelImpl _value,
    $Res Function(_$SummaryModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SummaryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = freezed,
    Object? contentId = freezed,
    Object? summaryType = null,
    Object? subject = null,
    Object? body = null,
    Object? keyPoints = freezed,
    Object? decisions = freezed,
    Object? actionItems = freezed,
    Object? lessonsLearned = freezed,
    Object? sentimentAnalysis = freezed,
    Object? risks = freezed,
    Object? blockers = freezed,
    Object? communicationInsights = freezed,
    Object? crossMeetingInsights = freezed,
    Object? nextMeetingAgenda = freezed,
    Object? createdAt = null,
    Object? createdBy = freezed,
    Object? dateRangeStart = freezed,
    Object? dateRangeEnd = freezed,
    Object? tokenCount = freezed,
    Object? generationTimeMs = freezed,
    Object? llmCost = freezed,
    Object? format = null,
  }) {
    return _then(
      _$SummaryModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        projectId: freezed == projectId
            ? _value.projectId
            : projectId // ignore: cast_nullable_to_non_nullable
                  as String?,
        contentId: freezed == contentId
            ? _value.contentId
            : contentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        summaryType: null == summaryType
            ? _value.summaryType
            : summaryType // ignore: cast_nullable_to_non_nullable
                  as SummaryType,
        subject: null == subject
            ? _value.subject
            : subject // ignore: cast_nullable_to_non_nullable
                  as String,
        body: null == body
            ? _value.body
            : body // ignore: cast_nullable_to_non_nullable
                  as String,
        keyPoints: freezed == keyPoints
            ? _value._keyPoints
            : keyPoints // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        decisions: freezed == decisions
            ? _value._decisions
            : decisions // ignore: cast_nullable_to_non_nullable
                  as List<Decision>?,
        actionItems: freezed == actionItems
            ? _value._actionItems
            : actionItems // ignore: cast_nullable_to_non_nullable
                  as List<ActionItem>?,
        lessonsLearned: freezed == lessonsLearned
            ? _value._lessonsLearned
            : lessonsLearned // ignore: cast_nullable_to_non_nullable
                  as List<LessonLearned>?,
        sentimentAnalysis: freezed == sentimentAnalysis
            ? _value._sentimentAnalysis
            : sentimentAnalysis // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        risks: freezed == risks
            ? _value._risks
            : risks // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>?,
        blockers: freezed == blockers
            ? _value._blockers
            : blockers // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>?,
        communicationInsights: freezed == communicationInsights
            ? _value.communicationInsights
            : communicationInsights // ignore: cast_nullable_to_non_nullable
                  as CommunicationInsights?,
        crossMeetingInsights: freezed == crossMeetingInsights
            ? _value._crossMeetingInsights
            : crossMeetingInsights // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        nextMeetingAgenda: freezed == nextMeetingAgenda
            ? _value._nextMeetingAgenda
            : nextMeetingAgenda // ignore: cast_nullable_to_non_nullable
                  as List<AgendaItem>?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        createdBy: freezed == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        dateRangeStart: freezed == dateRangeStart
            ? _value.dateRangeStart
            : dateRangeStart // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        dateRangeEnd: freezed == dateRangeEnd
            ? _value.dateRangeEnd
            : dateRangeEnd // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        tokenCount: freezed == tokenCount
            ? _value.tokenCount
            : tokenCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        generationTimeMs: freezed == generationTimeMs
            ? _value.generationTimeMs
            : generationTimeMs // ignore: cast_nullable_to_non_nullable
                  as int?,
        llmCost: freezed == llmCost
            ? _value.llmCost
            : llmCost // ignore: cast_nullable_to_non_nullable
                  as double?,
        format: null == format
            ? _value.format
            : format // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SummaryModelImpl extends _SummaryModel {
  const _$SummaryModelImpl({
    @JsonKey(name: 'summary_id') required this.id,
    @JsonKey(name: 'project_id') this.projectId,
    @JsonKey(name: 'content_id') this.contentId,
    @JsonKey(name: 'summary_type') required this.summaryType,
    required this.subject,
    required this.body,
    @JsonKey(name: 'key_points') final List<String>? keyPoints,
    @JsonKey(name: 'decisions', fromJson: _decisionsFromJson)
    final List<Decision>? decisions,
    @JsonKey(name: 'action_items', fromJson: _actionItemsFromJson)
    final List<ActionItem>? actionItems,
    @JsonKey(name: 'lessons_learned', fromJson: _lessonsLearnedFromJson)
    final List<LessonLearned>? lessonsLearned,
    @JsonKey(name: 'sentiment_analysis')
    final Map<String, dynamic>? sentimentAnalysis,
    @JsonKey(name: 'risks') final List<Map<String, dynamic>>? risks,
    @JsonKey(name: 'blockers') final List<Map<String, dynamic>>? blockers,
    @JsonKey(
      name: 'communication_insights',
      fromJson: _communicationInsightsFromJson,
    )
    this.communicationInsights,
    @JsonKey(name: 'cross_meeting_insights')
    final Map<String, dynamic>? crossMeetingInsights,
    @JsonKey(name: 'next_meeting_agenda', fromJson: _agendaItemsFromJson)
    final List<AgendaItem>? nextMeetingAgenda,
    @JsonKey(name: 'created_at') @DateTimeConverter() required this.createdAt,
    @JsonKey(name: 'created_by') this.createdBy,
    @JsonKey(name: 'date_range_start')
    @DateTimeConverterNullable()
    this.dateRangeStart,
    @JsonKey(name: 'date_range_end')
    @DateTimeConverterNullable()
    this.dateRangeEnd,
    @JsonKey(name: 'token_count') this.tokenCount,
    @JsonKey(name: 'generation_time_ms') this.generationTimeMs,
    @JsonKey(name: 'llm_cost') this.llmCost,
    this.format = 'general',
  }) : _keyPoints = keyPoints,
       _decisions = decisions,
       _actionItems = actionItems,
       _lessonsLearned = lessonsLearned,
       _sentimentAnalysis = sentimentAnalysis,
       _risks = risks,
       _blockers = blockers,
       _crossMeetingInsights = crossMeetingInsights,
       _nextMeetingAgenda = nextMeetingAgenda,
       super._();

  factory _$SummaryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SummaryModelImplFromJson(json);

  @override
  @JsonKey(name: 'summary_id')
  final String id;
  @override
  @JsonKey(name: 'project_id')
  final String? projectId;
  @override
  @JsonKey(name: 'content_id')
  final String? contentId;
  @override
  @JsonKey(name: 'summary_type')
  final SummaryType summaryType;
  @override
  final String subject;
  @override
  final String body;
  final List<String>? _keyPoints;
  @override
  @JsonKey(name: 'key_points')
  List<String>? get keyPoints {
    final value = _keyPoints;
    if (value == null) return null;
    if (_keyPoints is EqualUnmodifiableListView) return _keyPoints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<Decision>? _decisions;
  @override
  @JsonKey(name: 'decisions', fromJson: _decisionsFromJson)
  List<Decision>? get decisions {
    final value = _decisions;
    if (value == null) return null;
    if (_decisions is EqualUnmodifiableListView) return _decisions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<ActionItem>? _actionItems;
  @override
  @JsonKey(name: 'action_items', fromJson: _actionItemsFromJson)
  List<ActionItem>? get actionItems {
    final value = _actionItems;
    if (value == null) return null;
    if (_actionItems is EqualUnmodifiableListView) return _actionItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<LessonLearned>? _lessonsLearned;
  @override
  @JsonKey(name: 'lessons_learned', fromJson: _lessonsLearnedFromJson)
  List<LessonLearned>? get lessonsLearned {
    final value = _lessonsLearned;
    if (value == null) return null;
    if (_lessonsLearned is EqualUnmodifiableListView) return _lessonsLearned;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, dynamic>? _sentimentAnalysis;
  @override
  @JsonKey(name: 'sentiment_analysis')
  Map<String, dynamic>? get sentimentAnalysis {
    final value = _sentimentAnalysis;
    if (value == null) return null;
    if (_sentimentAnalysis is EqualUnmodifiableMapView)
      return _sentimentAnalysis;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final List<Map<String, dynamic>>? _risks;
  @override
  @JsonKey(name: 'risks')
  List<Map<String, dynamic>>? get risks {
    final value = _risks;
    if (value == null) return null;
    if (_risks is EqualUnmodifiableListView) return _risks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<Map<String, dynamic>>? _blockers;
  @override
  @JsonKey(name: 'blockers')
  List<Map<String, dynamic>>? get blockers {
    final value = _blockers;
    if (value == null) return null;
    if (_blockers is EqualUnmodifiableListView) return _blockers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(
    name: 'communication_insights',
    fromJson: _communicationInsightsFromJson,
  )
  final CommunicationInsights? communicationInsights;
  final Map<String, dynamic>? _crossMeetingInsights;
  @override
  @JsonKey(name: 'cross_meeting_insights')
  Map<String, dynamic>? get crossMeetingInsights {
    final value = _crossMeetingInsights;
    if (value == null) return null;
    if (_crossMeetingInsights is EqualUnmodifiableMapView)
      return _crossMeetingInsights;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final List<AgendaItem>? _nextMeetingAgenda;
  @override
  @JsonKey(name: 'next_meeting_agenda', fromJson: _agendaItemsFromJson)
  List<AgendaItem>? get nextMeetingAgenda {
    final value = _nextMeetingAgenda;
    if (value == null) return null;
    if (_nextMeetingAgenda is EqualUnmodifiableListView)
      return _nextMeetingAgenda;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'created_at')
  @DateTimeConverter()
  final DateTime createdAt;
  @override
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @override
  @JsonKey(name: 'date_range_start')
  @DateTimeConverterNullable()
  final DateTime? dateRangeStart;
  @override
  @JsonKey(name: 'date_range_end')
  @DateTimeConverterNullable()
  final DateTime? dateRangeEnd;
  @override
  @JsonKey(name: 'token_count')
  final int? tokenCount;
  @override
  @JsonKey(name: 'generation_time_ms')
  final int? generationTimeMs;
  @override
  @JsonKey(name: 'llm_cost')
  final double? llmCost;
  @override
  @JsonKey()
  final String format;

  @override
  String toString() {
    return 'SummaryModel(id: $id, projectId: $projectId, contentId: $contentId, summaryType: $summaryType, subject: $subject, body: $body, keyPoints: $keyPoints, decisions: $decisions, actionItems: $actionItems, lessonsLearned: $lessonsLearned, sentimentAnalysis: $sentimentAnalysis, risks: $risks, blockers: $blockers, communicationInsights: $communicationInsights, crossMeetingInsights: $crossMeetingInsights, nextMeetingAgenda: $nextMeetingAgenda, createdAt: $createdAt, createdBy: $createdBy, dateRangeStart: $dateRangeStart, dateRangeEnd: $dateRangeEnd, tokenCount: $tokenCount, generationTimeMs: $generationTimeMs, llmCost: $llmCost, format: $format)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SummaryModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.contentId, contentId) ||
                other.contentId == contentId) &&
            (identical(other.summaryType, summaryType) ||
                other.summaryType == summaryType) &&
            (identical(other.subject, subject) || other.subject == subject) &&
            (identical(other.body, body) || other.body == body) &&
            const DeepCollectionEquality().equals(
              other._keyPoints,
              _keyPoints,
            ) &&
            const DeepCollectionEquality().equals(
              other._decisions,
              _decisions,
            ) &&
            const DeepCollectionEquality().equals(
              other._actionItems,
              _actionItems,
            ) &&
            const DeepCollectionEquality().equals(
              other._lessonsLearned,
              _lessonsLearned,
            ) &&
            const DeepCollectionEquality().equals(
              other._sentimentAnalysis,
              _sentimentAnalysis,
            ) &&
            const DeepCollectionEquality().equals(other._risks, _risks) &&
            const DeepCollectionEquality().equals(other._blockers, _blockers) &&
            (identical(other.communicationInsights, communicationInsights) ||
                other.communicationInsights == communicationInsights) &&
            const DeepCollectionEquality().equals(
              other._crossMeetingInsights,
              _crossMeetingInsights,
            ) &&
            const DeepCollectionEquality().equals(
              other._nextMeetingAgenda,
              _nextMeetingAgenda,
            ) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.dateRangeStart, dateRangeStart) ||
                other.dateRangeStart == dateRangeStart) &&
            (identical(other.dateRangeEnd, dateRangeEnd) ||
                other.dateRangeEnd == dateRangeEnd) &&
            (identical(other.tokenCount, tokenCount) ||
                other.tokenCount == tokenCount) &&
            (identical(other.generationTimeMs, generationTimeMs) ||
                other.generationTimeMs == generationTimeMs) &&
            (identical(other.llmCost, llmCost) || other.llmCost == llmCost) &&
            (identical(other.format, format) || other.format == format));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    projectId,
    contentId,
    summaryType,
    subject,
    body,
    const DeepCollectionEquality().hash(_keyPoints),
    const DeepCollectionEquality().hash(_decisions),
    const DeepCollectionEquality().hash(_actionItems),
    const DeepCollectionEquality().hash(_lessonsLearned),
    const DeepCollectionEquality().hash(_sentimentAnalysis),
    const DeepCollectionEquality().hash(_risks),
    const DeepCollectionEquality().hash(_blockers),
    communicationInsights,
    const DeepCollectionEquality().hash(_crossMeetingInsights),
    const DeepCollectionEquality().hash(_nextMeetingAgenda),
    createdAt,
    createdBy,
    dateRangeStart,
    dateRangeEnd,
    tokenCount,
    generationTimeMs,
    llmCost,
    format,
  ]);

  /// Create a copy of SummaryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SummaryModelImplCopyWith<_$SummaryModelImpl> get copyWith =>
      __$$SummaryModelImplCopyWithImpl<_$SummaryModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SummaryModelImplToJson(this);
  }
}

abstract class _SummaryModel extends SummaryModel {
  const factory _SummaryModel({
    @JsonKey(name: 'summary_id') required final String id,
    @JsonKey(name: 'project_id') final String? projectId,
    @JsonKey(name: 'content_id') final String? contentId,
    @JsonKey(name: 'summary_type') required final SummaryType summaryType,
    required final String subject,
    required final String body,
    @JsonKey(name: 'key_points') final List<String>? keyPoints,
    @JsonKey(name: 'decisions', fromJson: _decisionsFromJson)
    final List<Decision>? decisions,
    @JsonKey(name: 'action_items', fromJson: _actionItemsFromJson)
    final List<ActionItem>? actionItems,
    @JsonKey(name: 'lessons_learned', fromJson: _lessonsLearnedFromJson)
    final List<LessonLearned>? lessonsLearned,
    @JsonKey(name: 'sentiment_analysis')
    final Map<String, dynamic>? sentimentAnalysis,
    @JsonKey(name: 'risks') final List<Map<String, dynamic>>? risks,
    @JsonKey(name: 'blockers') final List<Map<String, dynamic>>? blockers,
    @JsonKey(
      name: 'communication_insights',
      fromJson: _communicationInsightsFromJson,
    )
    final CommunicationInsights? communicationInsights,
    @JsonKey(name: 'cross_meeting_insights')
    final Map<String, dynamic>? crossMeetingInsights,
    @JsonKey(name: 'next_meeting_agenda', fromJson: _agendaItemsFromJson)
    final List<AgendaItem>? nextMeetingAgenda,
    @JsonKey(name: 'created_at')
    @DateTimeConverter()
    required final DateTime createdAt,
    @JsonKey(name: 'created_by') final String? createdBy,
    @JsonKey(name: 'date_range_start')
    @DateTimeConverterNullable()
    final DateTime? dateRangeStart,
    @JsonKey(name: 'date_range_end')
    @DateTimeConverterNullable()
    final DateTime? dateRangeEnd,
    @JsonKey(name: 'token_count') final int? tokenCount,
    @JsonKey(name: 'generation_time_ms') final int? generationTimeMs,
    @JsonKey(name: 'llm_cost') final double? llmCost,
    final String format,
  }) = _$SummaryModelImpl;
  const _SummaryModel._() : super._();

  factory _SummaryModel.fromJson(Map<String, dynamic> json) =
      _$SummaryModelImpl.fromJson;

  @override
  @JsonKey(name: 'summary_id')
  String get id;
  @override
  @JsonKey(name: 'project_id')
  String? get projectId;
  @override
  @JsonKey(name: 'content_id')
  String? get contentId;
  @override
  @JsonKey(name: 'summary_type')
  SummaryType get summaryType;
  @override
  String get subject;
  @override
  String get body;
  @override
  @JsonKey(name: 'key_points')
  List<String>? get keyPoints;
  @override
  @JsonKey(name: 'decisions', fromJson: _decisionsFromJson)
  List<Decision>? get decisions;
  @override
  @JsonKey(name: 'action_items', fromJson: _actionItemsFromJson)
  List<ActionItem>? get actionItems;
  @override
  @JsonKey(name: 'lessons_learned', fromJson: _lessonsLearnedFromJson)
  List<LessonLearned>? get lessonsLearned;
  @override
  @JsonKey(name: 'sentiment_analysis')
  Map<String, dynamic>? get sentimentAnalysis;
  @override
  @JsonKey(name: 'risks')
  List<Map<String, dynamic>>? get risks;
  @override
  @JsonKey(name: 'blockers')
  List<Map<String, dynamic>>? get blockers;
  @override
  @JsonKey(
    name: 'communication_insights',
    fromJson: _communicationInsightsFromJson,
  )
  CommunicationInsights? get communicationInsights;
  @override
  @JsonKey(name: 'cross_meeting_insights')
  Map<String, dynamic>? get crossMeetingInsights;
  @override
  @JsonKey(name: 'next_meeting_agenda', fromJson: _agendaItemsFromJson)
  List<AgendaItem>? get nextMeetingAgenda;
  @override
  @JsonKey(name: 'created_at')
  @DateTimeConverter()
  DateTime get createdAt;
  @override
  @JsonKey(name: 'created_by')
  String? get createdBy;
  @override
  @JsonKey(name: 'date_range_start')
  @DateTimeConverterNullable()
  DateTime? get dateRangeStart;
  @override
  @JsonKey(name: 'date_range_end')
  @DateTimeConverterNullable()
  DateTime? get dateRangeEnd;
  @override
  @JsonKey(name: 'token_count')
  int? get tokenCount;
  @override
  @JsonKey(name: 'generation_time_ms')
  int? get generationTimeMs;
  @override
  @JsonKey(name: 'llm_cost')
  double? get llmCost;
  @override
  String get format;

  /// Create a copy of SummaryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SummaryModelImplCopyWith<_$SummaryModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SummaryRequest _$SummaryRequestFromJson(Map<String, dynamic> json) {
  return _SummaryRequest.fromJson(json);
}

/// @nodoc
mixin _$SummaryRequest {
  @JsonKey(name: 'type')
  String get type => throw _privateConstructorUsedError;
  @JsonKey(name: 'content_id')
  String? get contentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_range_start')
  DateTime? get dateRangeStart => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_range_end')
  DateTime? get dateRangeEnd => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_by')
  String? get createdBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'format')
  String get format => throw _privateConstructorUsedError;

  /// Serializes this SummaryRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SummaryRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SummaryRequestCopyWith<SummaryRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SummaryRequestCopyWith<$Res> {
  factory $SummaryRequestCopyWith(
    SummaryRequest value,
    $Res Function(SummaryRequest) then,
  ) = _$SummaryRequestCopyWithImpl<$Res, SummaryRequest>;
  @useResult
  $Res call({
    @JsonKey(name: 'type') String type,
    @JsonKey(name: 'content_id') String? contentId,
    @JsonKey(name: 'date_range_start') DateTime? dateRangeStart,
    @JsonKey(name: 'date_range_end') DateTime? dateRangeEnd,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'format') String format,
  });
}

/// @nodoc
class _$SummaryRequestCopyWithImpl<$Res, $Val extends SummaryRequest>
    implements $SummaryRequestCopyWith<$Res> {
  _$SummaryRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SummaryRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? contentId = freezed,
    Object? dateRangeStart = freezed,
    Object? dateRangeEnd = freezed,
    Object? createdBy = freezed,
    Object? format = null,
  }) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            contentId: freezed == contentId
                ? _value.contentId
                : contentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            dateRangeStart: freezed == dateRangeStart
                ? _value.dateRangeStart
                : dateRangeStart // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            dateRangeEnd: freezed == dateRangeEnd
                ? _value.dateRangeEnd
                : dateRangeEnd // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdBy: freezed == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            format: null == format
                ? _value.format
                : format // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SummaryRequestImplCopyWith<$Res>
    implements $SummaryRequestCopyWith<$Res> {
  factory _$$SummaryRequestImplCopyWith(
    _$SummaryRequestImpl value,
    $Res Function(_$SummaryRequestImpl) then,
  ) = __$$SummaryRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'type') String type,
    @JsonKey(name: 'content_id') String? contentId,
    @JsonKey(name: 'date_range_start') DateTime? dateRangeStart,
    @JsonKey(name: 'date_range_end') DateTime? dateRangeEnd,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'format') String format,
  });
}

/// @nodoc
class __$$SummaryRequestImplCopyWithImpl<$Res>
    extends _$SummaryRequestCopyWithImpl<$Res, _$SummaryRequestImpl>
    implements _$$SummaryRequestImplCopyWith<$Res> {
  __$$SummaryRequestImplCopyWithImpl(
    _$SummaryRequestImpl _value,
    $Res Function(_$SummaryRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SummaryRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? contentId = freezed,
    Object? dateRangeStart = freezed,
    Object? dateRangeEnd = freezed,
    Object? createdBy = freezed,
    Object? format = null,
  }) {
    return _then(
      _$SummaryRequestImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        contentId: freezed == contentId
            ? _value.contentId
            : contentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        dateRangeStart: freezed == dateRangeStart
            ? _value.dateRangeStart
            : dateRangeStart // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        dateRangeEnd: freezed == dateRangeEnd
            ? _value.dateRangeEnd
            : dateRangeEnd // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdBy: freezed == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        format: null == format
            ? _value.format
            : format // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SummaryRequestImpl implements _SummaryRequest {
  const _$SummaryRequestImpl({
    @JsonKey(name: 'type') required this.type,
    @JsonKey(name: 'content_id') this.contentId,
    @JsonKey(name: 'date_range_start') this.dateRangeStart,
    @JsonKey(name: 'date_range_end') this.dateRangeEnd,
    @JsonKey(name: 'created_by') this.createdBy,
    @JsonKey(name: 'format') this.format = 'general',
  });

  factory _$SummaryRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$SummaryRequestImplFromJson(json);

  @override
  @JsonKey(name: 'type')
  final String type;
  @override
  @JsonKey(name: 'content_id')
  final String? contentId;
  @override
  @JsonKey(name: 'date_range_start')
  final DateTime? dateRangeStart;
  @override
  @JsonKey(name: 'date_range_end')
  final DateTime? dateRangeEnd;
  @override
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @override
  @JsonKey(name: 'format')
  final String format;

  @override
  String toString() {
    return 'SummaryRequest(type: $type, contentId: $contentId, dateRangeStart: $dateRangeStart, dateRangeEnd: $dateRangeEnd, createdBy: $createdBy, format: $format)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SummaryRequestImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.contentId, contentId) ||
                other.contentId == contentId) &&
            (identical(other.dateRangeStart, dateRangeStart) ||
                other.dateRangeStart == dateRangeStart) &&
            (identical(other.dateRangeEnd, dateRangeEnd) ||
                other.dateRangeEnd == dateRangeEnd) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.format, format) || other.format == format));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    type,
    contentId,
    dateRangeStart,
    dateRangeEnd,
    createdBy,
    format,
  );

  /// Create a copy of SummaryRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SummaryRequestImplCopyWith<_$SummaryRequestImpl> get copyWith =>
      __$$SummaryRequestImplCopyWithImpl<_$SummaryRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SummaryRequestImplToJson(this);
  }
}

abstract class _SummaryRequest implements SummaryRequest {
  const factory _SummaryRequest({
    @JsonKey(name: 'type') required final String type,
    @JsonKey(name: 'content_id') final String? contentId,
    @JsonKey(name: 'date_range_start') final DateTime? dateRangeStart,
    @JsonKey(name: 'date_range_end') final DateTime? dateRangeEnd,
    @JsonKey(name: 'created_by') final String? createdBy,
    @JsonKey(name: 'format') final String format,
  }) = _$SummaryRequestImpl;

  factory _SummaryRequest.fromJson(Map<String, dynamic> json) =
      _$SummaryRequestImpl.fromJson;

  @override
  @JsonKey(name: 'type')
  String get type;
  @override
  @JsonKey(name: 'content_id')
  String? get contentId;
  @override
  @JsonKey(name: 'date_range_start')
  DateTime? get dateRangeStart;
  @override
  @JsonKey(name: 'date_range_end')
  DateTime? get dateRangeEnd;
  @override
  @JsonKey(name: 'created_by')
  String? get createdBy;
  @override
  @JsonKey(name: 'format')
  String get format;

  /// Create a copy of SummaryRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SummaryRequestImplCopyWith<_$SummaryRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SummariesResponse _$SummariesResponseFromJson(Map<String, dynamic> json) {
  return _SummariesResponse.fromJson(json);
}

/// @nodoc
mixin _$SummariesResponse {
  List<SummaryModel> get summaries => throw _privateConstructorUsedError;
  int? get total => throw _privateConstructorUsedError;

  /// Serializes this SummariesResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SummariesResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SummariesResponseCopyWith<SummariesResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SummariesResponseCopyWith<$Res> {
  factory $SummariesResponseCopyWith(
    SummariesResponse value,
    $Res Function(SummariesResponse) then,
  ) = _$SummariesResponseCopyWithImpl<$Res, SummariesResponse>;
  @useResult
  $Res call({List<SummaryModel> summaries, int? total});
}

/// @nodoc
class _$SummariesResponseCopyWithImpl<$Res, $Val extends SummariesResponse>
    implements $SummariesResponseCopyWith<$Res> {
  _$SummariesResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SummariesResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? summaries = null, Object? total = freezed}) {
    return _then(
      _value.copyWith(
            summaries: null == summaries
                ? _value.summaries
                : summaries // ignore: cast_nullable_to_non_nullable
                      as List<SummaryModel>,
            total: freezed == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SummariesResponseImplCopyWith<$Res>
    implements $SummariesResponseCopyWith<$Res> {
  factory _$$SummariesResponseImplCopyWith(
    _$SummariesResponseImpl value,
    $Res Function(_$SummariesResponseImpl) then,
  ) = __$$SummariesResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<SummaryModel> summaries, int? total});
}

/// @nodoc
class __$$SummariesResponseImplCopyWithImpl<$Res>
    extends _$SummariesResponseCopyWithImpl<$Res, _$SummariesResponseImpl>
    implements _$$SummariesResponseImplCopyWith<$Res> {
  __$$SummariesResponseImplCopyWithImpl(
    _$SummariesResponseImpl _value,
    $Res Function(_$SummariesResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SummariesResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? summaries = null, Object? total = freezed}) {
    return _then(
      _$SummariesResponseImpl(
        summaries: null == summaries
            ? _value._summaries
            : summaries // ignore: cast_nullable_to_non_nullable
                  as List<SummaryModel>,
        total: freezed == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SummariesResponseImpl implements _SummariesResponse {
  const _$SummariesResponseImpl({
    required final List<SummaryModel> summaries,
    this.total,
  }) : _summaries = summaries;

  factory _$SummariesResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$SummariesResponseImplFromJson(json);

  final List<SummaryModel> _summaries;
  @override
  List<SummaryModel> get summaries {
    if (_summaries is EqualUnmodifiableListView) return _summaries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_summaries);
  }

  @override
  final int? total;

  @override
  String toString() {
    return 'SummariesResponse(summaries: $summaries, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SummariesResponseImpl &&
            const DeepCollectionEquality().equals(
              other._summaries,
              _summaries,
            ) &&
            (identical(other.total, total) || other.total == total));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_summaries),
    total,
  );

  /// Create a copy of SummariesResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SummariesResponseImplCopyWith<_$SummariesResponseImpl> get copyWith =>
      __$$SummariesResponseImplCopyWithImpl<_$SummariesResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SummariesResponseImplToJson(this);
  }
}

abstract class _SummariesResponse implements SummariesResponse {
  const factory _SummariesResponse({
    required final List<SummaryModel> summaries,
    final int? total,
  }) = _$SummariesResponseImpl;

  factory _SummariesResponse.fromJson(Map<String, dynamic> json) =
      _$SummariesResponseImpl.fromJson;

  @override
  List<SummaryModel> get summaries;
  @override
  int? get total;

  /// Create a copy of SummariesResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SummariesResponseImplCopyWith<_$SummariesResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
