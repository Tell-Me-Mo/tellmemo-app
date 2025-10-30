// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_insight_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TierResult _$TierResultFromJson(Map<String, dynamic> json) {
  return _TierResult.fromJson(json);
}

/// @nodoc
mixin _$TierResult {
  /// Which tier this result is from
  TierType get tierType => throw _privateConstructorUsedError;

  /// The answer or document content
  String get content => throw _privateConstructorUsedError;

  /// Confidence score (0.0 - 1.0)
  double get confidence => throw _privateConstructorUsedError;

  /// Additional metadata (document URL, timestamp, etc.)
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  /// Source identifier (document name, timestamp, etc.)
  String? get source => throw _privateConstructorUsedError;

  /// Timestamp when this result was found
  @DateTimeConverter()
  DateTime get foundAt => throw _privateConstructorUsedError;

  /// Serializes this TierResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TierResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TierResultCopyWith<TierResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TierResultCopyWith<$Res> {
  factory $TierResultCopyWith(
    TierResult value,
    $Res Function(TierResult) then,
  ) = _$TierResultCopyWithImpl<$Res, TierResult>;
  @useResult
  $Res call({
    TierType tierType,
    String content,
    double confidence,
    Map<String, dynamic> metadata,
    String? source,
    @DateTimeConverter() DateTime foundAt,
  });
}

/// @nodoc
class _$TierResultCopyWithImpl<$Res, $Val extends TierResult>
    implements $TierResultCopyWith<$Res> {
  _$TierResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TierResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tierType = null,
    Object? content = null,
    Object? confidence = null,
    Object? metadata = null,
    Object? source = freezed,
    Object? foundAt = null,
  }) {
    return _then(
      _value.copyWith(
            tierType: null == tierType
                ? _value.tierType
                : tierType // ignore: cast_nullable_to_non_nullable
                      as TierType,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
            metadata: null == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            source: freezed == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String?,
            foundAt: null == foundAt
                ? _value.foundAt
                : foundAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TierResultImplCopyWith<$Res>
    implements $TierResultCopyWith<$Res> {
  factory _$$TierResultImplCopyWith(
    _$TierResultImpl value,
    $Res Function(_$TierResultImpl) then,
  ) = __$$TierResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    TierType tierType,
    String content,
    double confidence,
    Map<String, dynamic> metadata,
    String? source,
    @DateTimeConverter() DateTime foundAt,
  });
}

/// @nodoc
class __$$TierResultImplCopyWithImpl<$Res>
    extends _$TierResultCopyWithImpl<$Res, _$TierResultImpl>
    implements _$$TierResultImplCopyWith<$Res> {
  __$$TierResultImplCopyWithImpl(
    _$TierResultImpl _value,
    $Res Function(_$TierResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TierResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tierType = null,
    Object? content = null,
    Object? confidence = null,
    Object? metadata = null,
    Object? source = freezed,
    Object? foundAt = null,
  }) {
    return _then(
      _$TierResultImpl(
        tierType: null == tierType
            ? _value.tierType
            : tierType // ignore: cast_nullable_to_non_nullable
                  as TierType,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
        metadata: null == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        source: freezed == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String?,
        foundAt: null == foundAt
            ? _value.foundAt
            : foundAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TierResultImpl implements _TierResult {
  const _$TierResultImpl({
    required this.tierType,
    required this.content,
    required this.confidence,
    final Map<String, dynamic> metadata = const {},
    this.source,
    @DateTimeConverter() required this.foundAt,
  }) : _metadata = metadata;

  factory _$TierResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$TierResultImplFromJson(json);

  /// Which tier this result is from
  @override
  final TierType tierType;

  /// The answer or document content
  @override
  final String content;

  /// Confidence score (0.0 - 1.0)
  @override
  final double confidence;

  /// Additional metadata (document URL, timestamp, etc.)
  final Map<String, dynamic> _metadata;

  /// Additional metadata (document URL, timestamp, etc.)
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  /// Source identifier (document name, timestamp, etc.)
  @override
  final String? source;

  /// Timestamp when this result was found
  @override
  @DateTimeConverter()
  final DateTime foundAt;

  @override
  String toString() {
    return 'TierResult(tierType: $tierType, content: $content, confidence: $confidence, metadata: $metadata, source: $source, foundAt: $foundAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TierResultImpl &&
            (identical(other.tierType, tierType) ||
                other.tierType == tierType) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.foundAt, foundAt) || other.foundAt == foundAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    tierType,
    content,
    confidence,
    const DeepCollectionEquality().hash(_metadata),
    source,
    foundAt,
  );

  /// Create a copy of TierResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TierResultImplCopyWith<_$TierResultImpl> get copyWith =>
      __$$TierResultImplCopyWithImpl<_$TierResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TierResultImplToJson(this);
  }
}

abstract class _TierResult implements TierResult {
  const factory _TierResult({
    required final TierType tierType,
    required final String content,
    required final double confidence,
    final Map<String, dynamic> metadata,
    final String? source,
    @DateTimeConverter() required final DateTime foundAt,
  }) = _$TierResultImpl;

  factory _TierResult.fromJson(Map<String, dynamic> json) =
      _$TierResultImpl.fromJson;

  /// Which tier this result is from
  @override
  TierType get tierType;

  /// The answer or document content
  @override
  String get content;

  /// Confidence score (0.0 - 1.0)
  @override
  double get confidence;

  /// Additional metadata (document URL, timestamp, etc.)
  @override
  Map<String, dynamic> get metadata;

  /// Source identifier (document name, timestamp, etc.)
  @override
  String? get source;

  /// Timestamp when this result was found
  @override
  @DateTimeConverter()
  DateTime get foundAt;

  /// Create a copy of TierResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TierResultImplCopyWith<_$TierResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LiveQuestion _$LiveQuestionFromJson(Map<String, dynamic> json) {
  return _LiveQuestion.fromJson(json);
}

/// @nodoc
mixin _$LiveQuestion {
  /// Unique identifier for this question
  String get id => throw _privateConstructorUsedError;

  /// The question text as spoken
  String get text => throw _privateConstructorUsedError;

  /// Speaker who asked the question
  String? get speaker => throw _privateConstructorUsedError;

  /// Timestamp when question was detected
  @DateTimeConverter()
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Current status of the question
  InsightStatus get status => throw _privateConstructorUsedError;

  /// Results from all four answer discovery tiers
  List<TierResult> get tierResults => throw _privateConstructorUsedError;

  /// Primary answer source (if answered)
  @JsonKey(name: 'answer_source')
  AnswerSource? get answerSource => throw _privateConstructorUsedError;

  /// Question category
  String get category => throw _privateConstructorUsedError;

  /// Confidence score of question detection (0.0 - 1.0)
  double get confidence => throw _privateConstructorUsedError;

  /// Additional metadata (context, related questions, etc.)
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  /// Timestamp when question was answered (if applicable)
  @DateTimeConverterNullable()
  DateTime? get answeredAt => throw _privateConstructorUsedError;

  /// Serializes this LiveQuestion to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LiveQuestion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LiveQuestionCopyWith<LiveQuestion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LiveQuestionCopyWith<$Res> {
  factory $LiveQuestionCopyWith(
    LiveQuestion value,
    $Res Function(LiveQuestion) then,
  ) = _$LiveQuestionCopyWithImpl<$Res, LiveQuestion>;
  @useResult
  $Res call({
    String id,
    String text,
    String? speaker,
    @DateTimeConverter() DateTime timestamp,
    InsightStatus status,
    List<TierResult> tierResults,
    @JsonKey(name: 'answer_source') AnswerSource? answerSource,
    String category,
    double confidence,
    Map<String, dynamic> metadata,
    @DateTimeConverterNullable() DateTime? answeredAt,
  });
}

/// @nodoc
class _$LiveQuestionCopyWithImpl<$Res, $Val extends LiveQuestion>
    implements $LiveQuestionCopyWith<$Res> {
  _$LiveQuestionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LiveQuestion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? speaker = freezed,
    Object? timestamp = null,
    Object? status = null,
    Object? tierResults = null,
    Object? answerSource = freezed,
    Object? category = null,
    Object? confidence = null,
    Object? metadata = null,
    Object? answeredAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
            speaker: freezed == speaker
                ? _value.speaker
                : speaker // ignore: cast_nullable_to_non_nullable
                      as String?,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as InsightStatus,
            tierResults: null == tierResults
                ? _value.tierResults
                : tierResults // ignore: cast_nullable_to_non_nullable
                      as List<TierResult>,
            answerSource: freezed == answerSource
                ? _value.answerSource
                : answerSource // ignore: cast_nullable_to_non_nullable
                      as AnswerSource?,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
            metadata: null == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            answeredAt: freezed == answeredAt
                ? _value.answeredAt
                : answeredAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LiveQuestionImplCopyWith<$Res>
    implements $LiveQuestionCopyWith<$Res> {
  factory _$$LiveQuestionImplCopyWith(
    _$LiveQuestionImpl value,
    $Res Function(_$LiveQuestionImpl) then,
  ) = __$$LiveQuestionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String text,
    String? speaker,
    @DateTimeConverter() DateTime timestamp,
    InsightStatus status,
    List<TierResult> tierResults,
    @JsonKey(name: 'answer_source') AnswerSource? answerSource,
    String category,
    double confidence,
    Map<String, dynamic> metadata,
    @DateTimeConverterNullable() DateTime? answeredAt,
  });
}

/// @nodoc
class __$$LiveQuestionImplCopyWithImpl<$Res>
    extends _$LiveQuestionCopyWithImpl<$Res, _$LiveQuestionImpl>
    implements _$$LiveQuestionImplCopyWith<$Res> {
  __$$LiveQuestionImplCopyWithImpl(
    _$LiveQuestionImpl _value,
    $Res Function(_$LiveQuestionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LiveQuestion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? speaker = freezed,
    Object? timestamp = null,
    Object? status = null,
    Object? tierResults = null,
    Object? answerSource = freezed,
    Object? category = null,
    Object? confidence = null,
    Object? metadata = null,
    Object? answeredAt = freezed,
  }) {
    return _then(
      _$LiveQuestionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        speaker: freezed == speaker
            ? _value.speaker
            : speaker // ignore: cast_nullable_to_non_nullable
                  as String?,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as InsightStatus,
        tierResults: null == tierResults
            ? _value._tierResults
            : tierResults // ignore: cast_nullable_to_non_nullable
                  as List<TierResult>,
        answerSource: freezed == answerSource
            ? _value.answerSource
            : answerSource // ignore: cast_nullable_to_non_nullable
                  as AnswerSource?,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
        metadata: null == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        answeredAt: freezed == answeredAt
            ? _value.answeredAt
            : answeredAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LiveQuestionImpl extends _LiveQuestion {
  const _$LiveQuestionImpl({
    required this.id,
    required this.text,
    this.speaker,
    @DateTimeConverter() required this.timestamp,
    required this.status,
    final List<TierResult> tierResults = const [],
    @JsonKey(name: 'answer_source') this.answerSource,
    this.category = 'factual',
    this.confidence = 0.0,
    final Map<String, dynamic> metadata = const {},
    @DateTimeConverterNullable() this.answeredAt,
  }) : _tierResults = tierResults,
       _metadata = metadata,
       super._();

  factory _$LiveQuestionImpl.fromJson(Map<String, dynamic> json) =>
      _$$LiveQuestionImplFromJson(json);

  /// Unique identifier for this question
  @override
  final String id;

  /// The question text as spoken
  @override
  final String text;

  /// Speaker who asked the question
  @override
  final String? speaker;

  /// Timestamp when question was detected
  @override
  @DateTimeConverter()
  final DateTime timestamp;

  /// Current status of the question
  @override
  final InsightStatus status;

  /// Results from all four answer discovery tiers
  final List<TierResult> _tierResults;

  /// Results from all four answer discovery tiers
  @override
  @JsonKey()
  List<TierResult> get tierResults {
    if (_tierResults is EqualUnmodifiableListView) return _tierResults;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tierResults);
  }

  /// Primary answer source (if answered)
  @override
  @JsonKey(name: 'answer_source')
  final AnswerSource? answerSource;

  /// Question category
  @override
  @JsonKey()
  final String category;

  /// Confidence score of question detection (0.0 - 1.0)
  @override
  @JsonKey()
  final double confidence;

  /// Additional metadata (context, related questions, etc.)
  final Map<String, dynamic> _metadata;

  /// Additional metadata (context, related questions, etc.)
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  /// Timestamp when question was answered (if applicable)
  @override
  @DateTimeConverterNullable()
  final DateTime? answeredAt;

  @override
  String toString() {
    return 'LiveQuestion(id: $id, text: $text, speaker: $speaker, timestamp: $timestamp, status: $status, tierResults: $tierResults, answerSource: $answerSource, category: $category, confidence: $confidence, metadata: $metadata, answeredAt: $answeredAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LiveQuestionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.speaker, speaker) || other.speaker == speaker) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(
              other._tierResults,
              _tierResults,
            ) &&
            (identical(other.answerSource, answerSource) ||
                other.answerSource == answerSource) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.answeredAt, answeredAt) ||
                other.answeredAt == answeredAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    text,
    speaker,
    timestamp,
    status,
    const DeepCollectionEquality().hash(_tierResults),
    answerSource,
    category,
    confidence,
    const DeepCollectionEquality().hash(_metadata),
    answeredAt,
  );

  /// Create a copy of LiveQuestion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LiveQuestionImplCopyWith<_$LiveQuestionImpl> get copyWith =>
      __$$LiveQuestionImplCopyWithImpl<_$LiveQuestionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LiveQuestionImplToJson(this);
  }
}

abstract class _LiveQuestion extends LiveQuestion {
  const factory _LiveQuestion({
    required final String id,
    required final String text,
    final String? speaker,
    @DateTimeConverter() required final DateTime timestamp,
    required final InsightStatus status,
    final List<TierResult> tierResults,
    @JsonKey(name: 'answer_source') final AnswerSource? answerSource,
    final String category,
    final double confidence,
    final Map<String, dynamic> metadata,
    @DateTimeConverterNullable() final DateTime? answeredAt,
  }) = _$LiveQuestionImpl;
  const _LiveQuestion._() : super._();

  factory _LiveQuestion.fromJson(Map<String, dynamic> json) =
      _$LiveQuestionImpl.fromJson;

  /// Unique identifier for this question
  @override
  String get id;

  /// The question text as spoken
  @override
  String get text;

  /// Speaker who asked the question
  @override
  String? get speaker;

  /// Timestamp when question was detected
  @override
  @DateTimeConverter()
  DateTime get timestamp;

  /// Current status of the question
  @override
  InsightStatus get status;

  /// Results from all four answer discovery tiers
  @override
  List<TierResult> get tierResults;

  /// Primary answer source (if answered)
  @override
  @JsonKey(name: 'answer_source')
  AnswerSource? get answerSource;

  /// Question category
  @override
  String get category;

  /// Confidence score of question detection (0.0 - 1.0)
  @override
  double get confidence;

  /// Additional metadata (context, related questions, etc.)
  @override
  Map<String, dynamic> get metadata;

  /// Timestamp when question was answered (if applicable)
  @override
  @DateTimeConverterNullable()
  DateTime? get answeredAt;

  /// Create a copy of LiveQuestion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LiveQuestionImplCopyWith<_$LiveQuestionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LiveAction _$LiveActionFromJson(Map<String, dynamic> json) {
  return _LiveAction.fromJson(json);
}

/// @nodoc
mixin _$LiveAction {
  /// Unique identifier for this action
  String get id => throw _privateConstructorUsedError;

  /// Action description
  String get description => throw _privateConstructorUsedError;

  /// Assigned owner (if specified)
  String? get owner => throw _privateConstructorUsedError;

  /// Deadline (if specified)
  @DateTimeConverterNullable()
  DateTime? get deadline => throw _privateConstructorUsedError;

  /// Completeness score (0.0 - 1.0)
  double get completenessScore => throw _privateConstructorUsedError;

  /// Current status of the action
  InsightStatus get status => throw _privateConstructorUsedError;

  /// Speaker who mentioned the action
  String? get speaker => throw _privateConstructorUsedError;

  /// Timestamp when action was detected
  @DateTimeConverter()
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Confidence score of action detection (0.0 - 1.0)
  double get confidence => throw _privateConstructorUsedError;

  /// Additional metadata (dependencies, context, etc.)
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  /// Timestamp when action was marked complete (if applicable)
  @DateTimeConverterNullable()
  DateTime? get completedAt => throw _privateConstructorUsedError;

  /// Serializes this LiveAction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LiveAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LiveActionCopyWith<LiveAction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LiveActionCopyWith<$Res> {
  factory $LiveActionCopyWith(
    LiveAction value,
    $Res Function(LiveAction) then,
  ) = _$LiveActionCopyWithImpl<$Res, LiveAction>;
  @useResult
  $Res call({
    String id,
    String description,
    String? owner,
    @DateTimeConverterNullable() DateTime? deadline,
    double completenessScore,
    InsightStatus status,
    String? speaker,
    @DateTimeConverter() DateTime timestamp,
    double confidence,
    Map<String, dynamic> metadata,
    @DateTimeConverterNullable() DateTime? completedAt,
  });
}

/// @nodoc
class _$LiveActionCopyWithImpl<$Res, $Val extends LiveAction>
    implements $LiveActionCopyWith<$Res> {
  _$LiveActionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LiveAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? description = null,
    Object? owner = freezed,
    Object? deadline = freezed,
    Object? completenessScore = null,
    Object? status = null,
    Object? speaker = freezed,
    Object? timestamp = null,
    Object? confidence = null,
    Object? metadata = null,
    Object? completedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            owner: freezed == owner
                ? _value.owner
                : owner // ignore: cast_nullable_to_non_nullable
                      as String?,
            deadline: freezed == deadline
                ? _value.deadline
                : deadline // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            completenessScore: null == completenessScore
                ? _value.completenessScore
                : completenessScore // ignore: cast_nullable_to_non_nullable
                      as double,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as InsightStatus,
            speaker: freezed == speaker
                ? _value.speaker
                : speaker // ignore: cast_nullable_to_non_nullable
                      as String?,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
            metadata: null == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LiveActionImplCopyWith<$Res>
    implements $LiveActionCopyWith<$Res> {
  factory _$$LiveActionImplCopyWith(
    _$LiveActionImpl value,
    $Res Function(_$LiveActionImpl) then,
  ) = __$$LiveActionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String description,
    String? owner,
    @DateTimeConverterNullable() DateTime? deadline,
    double completenessScore,
    InsightStatus status,
    String? speaker,
    @DateTimeConverter() DateTime timestamp,
    double confidence,
    Map<String, dynamic> metadata,
    @DateTimeConverterNullable() DateTime? completedAt,
  });
}

/// @nodoc
class __$$LiveActionImplCopyWithImpl<$Res>
    extends _$LiveActionCopyWithImpl<$Res, _$LiveActionImpl>
    implements _$$LiveActionImplCopyWith<$Res> {
  __$$LiveActionImplCopyWithImpl(
    _$LiveActionImpl _value,
    $Res Function(_$LiveActionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LiveAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? description = null,
    Object? owner = freezed,
    Object? deadline = freezed,
    Object? completenessScore = null,
    Object? status = null,
    Object? speaker = freezed,
    Object? timestamp = null,
    Object? confidence = null,
    Object? metadata = null,
    Object? completedAt = freezed,
  }) {
    return _then(
      _$LiveActionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        owner: freezed == owner
            ? _value.owner
            : owner // ignore: cast_nullable_to_non_nullable
                  as String?,
        deadline: freezed == deadline
            ? _value.deadline
            : deadline // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        completenessScore: null == completenessScore
            ? _value.completenessScore
            : completenessScore // ignore: cast_nullable_to_non_nullable
                  as double,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as InsightStatus,
        speaker: freezed == speaker
            ? _value.speaker
            : speaker // ignore: cast_nullable_to_non_nullable
                  as String?,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
        metadata: null == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LiveActionImpl extends _LiveAction {
  const _$LiveActionImpl({
    required this.id,
    required this.description,
    this.owner,
    @DateTimeConverterNullable() this.deadline,
    this.completenessScore = 0.4,
    this.status = InsightStatus.tracked,
    this.speaker,
    @DateTimeConverter() required this.timestamp,
    this.confidence = 0.0,
    final Map<String, dynamic> metadata = const {},
    @DateTimeConverterNullable() this.completedAt,
  }) : _metadata = metadata,
       super._();

  factory _$LiveActionImpl.fromJson(Map<String, dynamic> json) =>
      _$$LiveActionImplFromJson(json);

  /// Unique identifier for this action
  @override
  final String id;

  /// Action description
  @override
  final String description;

  /// Assigned owner (if specified)
  @override
  final String? owner;

  /// Deadline (if specified)
  @override
  @DateTimeConverterNullable()
  final DateTime? deadline;

  /// Completeness score (0.0 - 1.0)
  @override
  @JsonKey()
  final double completenessScore;

  /// Current status of the action
  @override
  @JsonKey()
  final InsightStatus status;

  /// Speaker who mentioned the action
  @override
  final String? speaker;

  /// Timestamp when action was detected
  @override
  @DateTimeConverter()
  final DateTime timestamp;

  /// Confidence score of action detection (0.0 - 1.0)
  @override
  @JsonKey()
  final double confidence;

  /// Additional metadata (dependencies, context, etc.)
  final Map<String, dynamic> _metadata;

  /// Additional metadata (dependencies, context, etc.)
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  /// Timestamp when action was marked complete (if applicable)
  @override
  @DateTimeConverterNullable()
  final DateTime? completedAt;

  @override
  String toString() {
    return 'LiveAction(id: $id, description: $description, owner: $owner, deadline: $deadline, completenessScore: $completenessScore, status: $status, speaker: $speaker, timestamp: $timestamp, confidence: $confidence, metadata: $metadata, completedAt: $completedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LiveActionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.owner, owner) || other.owner == owner) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline) &&
            (identical(other.completenessScore, completenessScore) ||
                other.completenessScore == completenessScore) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.speaker, speaker) || other.speaker == speaker) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    description,
    owner,
    deadline,
    completenessScore,
    status,
    speaker,
    timestamp,
    confidence,
    const DeepCollectionEquality().hash(_metadata),
    completedAt,
  );

  /// Create a copy of LiveAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LiveActionImplCopyWith<_$LiveActionImpl> get copyWith =>
      __$$LiveActionImplCopyWithImpl<_$LiveActionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LiveActionImplToJson(this);
  }
}

abstract class _LiveAction extends LiveAction {
  const factory _LiveAction({
    required final String id,
    required final String description,
    final String? owner,
    @DateTimeConverterNullable() final DateTime? deadline,
    final double completenessScore,
    final InsightStatus status,
    final String? speaker,
    @DateTimeConverter() required final DateTime timestamp,
    final double confidence,
    final Map<String, dynamic> metadata,
    @DateTimeConverterNullable() final DateTime? completedAt,
  }) = _$LiveActionImpl;
  const _LiveAction._() : super._();

  factory _LiveAction.fromJson(Map<String, dynamic> json) =
      _$LiveActionImpl.fromJson;

  /// Unique identifier for this action
  @override
  String get id;

  /// Action description
  @override
  String get description;

  /// Assigned owner (if specified)
  @override
  String? get owner;

  /// Deadline (if specified)
  @override
  @DateTimeConverterNullable()
  DateTime? get deadline;

  /// Completeness score (0.0 - 1.0)
  @override
  double get completenessScore;

  /// Current status of the action
  @override
  InsightStatus get status;

  /// Speaker who mentioned the action
  @override
  String? get speaker;

  /// Timestamp when action was detected
  @override
  @DateTimeConverter()
  DateTime get timestamp;

  /// Confidence score of action detection (0.0 - 1.0)
  @override
  double get confidence;

  /// Additional metadata (dependencies, context, etc.)
  @override
  Map<String, dynamic> get metadata;

  /// Timestamp when action was marked complete (if applicable)
  @override
  @DateTimeConverterNullable()
  DateTime? get completedAt;

  /// Create a copy of LiveAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LiveActionImplCopyWith<_$LiveActionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TranscriptSegment _$TranscriptSegmentFromJson(Map<String, dynamic> json) {
  return _TranscriptSegment.fromJson(json);
}

/// @nodoc
mixin _$TranscriptSegment {
  /// Unique identifier for this transcript segment
  String get id => throw _privateConstructorUsedError;

  /// The transcribed text
  String get text => throw _privateConstructorUsedError;

  /// Speaker who spoke this segment
  String? get speaker => throw _privateConstructorUsedError;

  /// Start timestamp of this segment
  @DateTimeConverter()
  DateTime get startTime => throw _privateConstructorUsedError;

  /// End timestamp of this segment
  @DateTimeConverterNullable()
  DateTime? get endTime => throw _privateConstructorUsedError;

  /// Whether this is a final (stable) transcript or partial (in-progress)
  bool get isFinal => throw _privateConstructorUsedError;

  /// Confidence score of transcription (0.0 - 1.0)
  double get confidence => throw _privateConstructorUsedError;

  /// Additional metadata (audio_level, etc.)
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  /// Serializes this TranscriptSegment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TranscriptSegment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TranscriptSegmentCopyWith<TranscriptSegment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TranscriptSegmentCopyWith<$Res> {
  factory $TranscriptSegmentCopyWith(
    TranscriptSegment value,
    $Res Function(TranscriptSegment) then,
  ) = _$TranscriptSegmentCopyWithImpl<$Res, TranscriptSegment>;
  @useResult
  $Res call({
    String id,
    String text,
    String? speaker,
    @DateTimeConverter() DateTime startTime,
    @DateTimeConverterNullable() DateTime? endTime,
    bool isFinal,
    double confidence,
    Map<String, dynamic> metadata,
  });
}

/// @nodoc
class _$TranscriptSegmentCopyWithImpl<$Res, $Val extends TranscriptSegment>
    implements $TranscriptSegmentCopyWith<$Res> {
  _$TranscriptSegmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TranscriptSegment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? speaker = freezed,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? isFinal = null,
    Object? confidence = null,
    Object? metadata = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
            speaker: freezed == speaker
                ? _value.speaker
                : speaker // ignore: cast_nullable_to_non_nullable
                      as String?,
            startTime: null == startTime
                ? _value.startTime
                : startTime // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            endTime: freezed == endTime
                ? _value.endTime
                : endTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            isFinal: null == isFinal
                ? _value.isFinal
                : isFinal // ignore: cast_nullable_to_non_nullable
                      as bool,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
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
abstract class _$$TranscriptSegmentImplCopyWith<$Res>
    implements $TranscriptSegmentCopyWith<$Res> {
  factory _$$TranscriptSegmentImplCopyWith(
    _$TranscriptSegmentImpl value,
    $Res Function(_$TranscriptSegmentImpl) then,
  ) = __$$TranscriptSegmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String text,
    String? speaker,
    @DateTimeConverter() DateTime startTime,
    @DateTimeConverterNullable() DateTime? endTime,
    bool isFinal,
    double confidence,
    Map<String, dynamic> metadata,
  });
}

/// @nodoc
class __$$TranscriptSegmentImplCopyWithImpl<$Res>
    extends _$TranscriptSegmentCopyWithImpl<$Res, _$TranscriptSegmentImpl>
    implements _$$TranscriptSegmentImplCopyWith<$Res> {
  __$$TranscriptSegmentImplCopyWithImpl(
    _$TranscriptSegmentImpl _value,
    $Res Function(_$TranscriptSegmentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TranscriptSegment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? speaker = freezed,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? isFinal = null,
    Object? confidence = null,
    Object? metadata = null,
  }) {
    return _then(
      _$TranscriptSegmentImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        speaker: freezed == speaker
            ? _value.speaker
            : speaker // ignore: cast_nullable_to_non_nullable
                  as String?,
        startTime: null == startTime
            ? _value.startTime
            : startTime // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endTime: freezed == endTime
            ? _value.endTime
            : endTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isFinal: null == isFinal
            ? _value.isFinal
            : isFinal // ignore: cast_nullable_to_non_nullable
                  as bool,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
        metadata: null == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TranscriptSegmentImpl extends _TranscriptSegment {
  const _$TranscriptSegmentImpl({
    required this.id,
    required this.text,
    this.speaker,
    @DateTimeConverter() required this.startTime,
    @DateTimeConverterNullable() this.endTime,
    this.isFinal = false,
    this.confidence = 0.0,
    final Map<String, dynamic> metadata = const {},
  }) : _metadata = metadata,
       super._();

  factory _$TranscriptSegmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$TranscriptSegmentImplFromJson(json);

  /// Unique identifier for this transcript segment
  @override
  final String id;

  /// The transcribed text
  @override
  final String text;

  /// Speaker who spoke this segment
  @override
  final String? speaker;

  /// Start timestamp of this segment
  @override
  @DateTimeConverter()
  final DateTime startTime;

  /// End timestamp of this segment
  @override
  @DateTimeConverterNullable()
  final DateTime? endTime;

  /// Whether this is a final (stable) transcript or partial (in-progress)
  @override
  @JsonKey()
  final bool isFinal;

  /// Confidence score of transcription (0.0 - 1.0)
  @override
  @JsonKey()
  final double confidence;

  /// Additional metadata (audio_level, etc.)
  final Map<String, dynamic> _metadata;

  /// Additional metadata (audio_level, etc.)
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  String toString() {
    return 'TranscriptSegment(id: $id, text: $text, speaker: $speaker, startTime: $startTime, endTime: $endTime, isFinal: $isFinal, confidence: $confidence, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TranscriptSegmentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.speaker, speaker) || other.speaker == speaker) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.isFinal, isFinal) || other.isFinal == isFinal) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    text,
    speaker,
    startTime,
    endTime,
    isFinal,
    confidence,
    const DeepCollectionEquality().hash(_metadata),
  );

  /// Create a copy of TranscriptSegment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TranscriptSegmentImplCopyWith<_$TranscriptSegmentImpl> get copyWith =>
      __$$TranscriptSegmentImplCopyWithImpl<_$TranscriptSegmentImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TranscriptSegmentImplToJson(this);
  }
}

abstract class _TranscriptSegment extends TranscriptSegment {
  const factory _TranscriptSegment({
    required final String id,
    required final String text,
    final String? speaker,
    @DateTimeConverter() required final DateTime startTime,
    @DateTimeConverterNullable() final DateTime? endTime,
    final bool isFinal,
    final double confidence,
    final Map<String, dynamic> metadata,
  }) = _$TranscriptSegmentImpl;
  const _TranscriptSegment._() : super._();

  factory _TranscriptSegment.fromJson(Map<String, dynamic> json) =
      _$TranscriptSegmentImpl.fromJson;

  /// Unique identifier for this transcript segment
  @override
  String get id;

  /// The transcribed text
  @override
  String get text;

  /// Speaker who spoke this segment
  @override
  String? get speaker;

  /// Start timestamp of this segment
  @override
  @DateTimeConverter()
  DateTime get startTime;

  /// End timestamp of this segment
  @override
  @DateTimeConverterNullable()
  DateTime? get endTime;

  /// Whether this is a final (stable) transcript or partial (in-progress)
  @override
  bool get isFinal;

  /// Confidence score of transcription (0.0 - 1.0)
  @override
  double get confidence;

  /// Additional metadata (audio_level, etc.)
  @override
  Map<String, dynamic> get metadata;

  /// Create a copy of TranscriptSegment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TranscriptSegmentImplCopyWith<_$TranscriptSegmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
