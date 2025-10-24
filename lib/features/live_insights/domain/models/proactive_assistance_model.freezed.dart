// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'proactive_assistance_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AnswerSource _$AnswerSourceFromJson(Map<String, dynamic> json) {
  return _AnswerSource.fromJson(json);
}

/// @nodoc
mixin _$AnswerSource {
  @JsonKey(name: 'content_id')
  String get contentId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get snippet => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  @JsonKey(name: 'relevance_score')
  double get relevanceScore => throw _privateConstructorUsedError;
  @JsonKey(name: 'meeting_type')
  String get meetingType => throw _privateConstructorUsedError;

  /// Serializes this AnswerSource to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AnswerSource
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AnswerSourceCopyWith<AnswerSource> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnswerSourceCopyWith<$Res> {
  factory $AnswerSourceCopyWith(
    AnswerSource value,
    $Res Function(AnswerSource) then,
  ) = _$AnswerSourceCopyWithImpl<$Res, AnswerSource>;
  @useResult
  $Res call({
    @JsonKey(name: 'content_id') String contentId,
    String title,
    String snippet,
    DateTime date,
    @JsonKey(name: 'relevance_score') double relevanceScore,
    @JsonKey(name: 'meeting_type') String meetingType,
  });
}

/// @nodoc
class _$AnswerSourceCopyWithImpl<$Res, $Val extends AnswerSource>
    implements $AnswerSourceCopyWith<$Res> {
  _$AnswerSourceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AnswerSource
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contentId = null,
    Object? title = null,
    Object? snippet = null,
    Object? date = null,
    Object? relevanceScore = null,
    Object? meetingType = null,
  }) {
    return _then(
      _value.copyWith(
            contentId: null == contentId
                ? _value.contentId
                : contentId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            snippet: null == snippet
                ? _value.snippet
                : snippet // ignore: cast_nullable_to_non_nullable
                      as String,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            relevanceScore: null == relevanceScore
                ? _value.relevanceScore
                : relevanceScore // ignore: cast_nullable_to_non_nullable
                      as double,
            meetingType: null == meetingType
                ? _value.meetingType
                : meetingType // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AnswerSourceImplCopyWith<$Res>
    implements $AnswerSourceCopyWith<$Res> {
  factory _$$AnswerSourceImplCopyWith(
    _$AnswerSourceImpl value,
    $Res Function(_$AnswerSourceImpl) then,
  ) = __$$AnswerSourceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'content_id') String contentId,
    String title,
    String snippet,
    DateTime date,
    @JsonKey(name: 'relevance_score') double relevanceScore,
    @JsonKey(name: 'meeting_type') String meetingType,
  });
}

/// @nodoc
class __$$AnswerSourceImplCopyWithImpl<$Res>
    extends _$AnswerSourceCopyWithImpl<$Res, _$AnswerSourceImpl>
    implements _$$AnswerSourceImplCopyWith<$Res> {
  __$$AnswerSourceImplCopyWithImpl(
    _$AnswerSourceImpl _value,
    $Res Function(_$AnswerSourceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AnswerSource
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contentId = null,
    Object? title = null,
    Object? snippet = null,
    Object? date = null,
    Object? relevanceScore = null,
    Object? meetingType = null,
  }) {
    return _then(
      _$AnswerSourceImpl(
        contentId: null == contentId
            ? _value.contentId
            : contentId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        snippet: null == snippet
            ? _value.snippet
            : snippet // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        relevanceScore: null == relevanceScore
            ? _value.relevanceScore
            : relevanceScore // ignore: cast_nullable_to_non_nullable
                  as double,
        meetingType: null == meetingType
            ? _value.meetingType
            : meetingType // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AnswerSourceImpl implements _AnswerSource {
  const _$AnswerSourceImpl({
    @JsonKey(name: 'content_id') required this.contentId,
    required this.title,
    required this.snippet,
    required this.date,
    @JsonKey(name: 'relevance_score') required this.relevanceScore,
    @JsonKey(name: 'meeting_type') required this.meetingType,
  });

  factory _$AnswerSourceImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnswerSourceImplFromJson(json);

  @override
  @JsonKey(name: 'content_id')
  final String contentId;
  @override
  final String title;
  @override
  final String snippet;
  @override
  final DateTime date;
  @override
  @JsonKey(name: 'relevance_score')
  final double relevanceScore;
  @override
  @JsonKey(name: 'meeting_type')
  final String meetingType;

  @override
  String toString() {
    return 'AnswerSource(contentId: $contentId, title: $title, snippet: $snippet, date: $date, relevanceScore: $relevanceScore, meetingType: $meetingType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnswerSourceImpl &&
            (identical(other.contentId, contentId) ||
                other.contentId == contentId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.snippet, snippet) || other.snippet == snippet) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.relevanceScore, relevanceScore) ||
                other.relevanceScore == relevanceScore) &&
            (identical(other.meetingType, meetingType) ||
                other.meetingType == meetingType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    contentId,
    title,
    snippet,
    date,
    relevanceScore,
    meetingType,
  );

  /// Create a copy of AnswerSource
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnswerSourceImplCopyWith<_$AnswerSourceImpl> get copyWith =>
      __$$AnswerSourceImplCopyWithImpl<_$AnswerSourceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AnswerSourceImplToJson(this);
  }
}

abstract class _AnswerSource implements AnswerSource {
  const factory _AnswerSource({
    @JsonKey(name: 'content_id') required final String contentId,
    required final String title,
    required final String snippet,
    required final DateTime date,
    @JsonKey(name: 'relevance_score') required final double relevanceScore,
    @JsonKey(name: 'meeting_type') required final String meetingType,
  }) = _$AnswerSourceImpl;

  factory _AnswerSource.fromJson(Map<String, dynamic> json) =
      _$AnswerSourceImpl.fromJson;

  @override
  @JsonKey(name: 'content_id')
  String get contentId;
  @override
  String get title;
  @override
  String get snippet;
  @override
  DateTime get date;
  @override
  @JsonKey(name: 'relevance_score')
  double get relevanceScore;
  @override
  @JsonKey(name: 'meeting_type')
  String get meetingType;

  /// Create a copy of AnswerSource
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnswerSourceImplCopyWith<_$AnswerSourceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AutoAnswerAssistance _$AutoAnswerAssistanceFromJson(Map<String, dynamic> json) {
  return _AutoAnswerAssistance.fromJson(json);
}

/// @nodoc
mixin _$AutoAnswerAssistance {
  @JsonKey(name: 'insight_id')
  String get insightId => throw _privateConstructorUsedError;
  String get question => throw _privateConstructorUsedError;
  String get answer => throw _privateConstructorUsedError;
  double get confidence => throw _privateConstructorUsedError;
  List<AnswerSource> get sources => throw _privateConstructorUsedError;
  String get reasoning => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Serializes this AutoAnswerAssistance to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AutoAnswerAssistance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AutoAnswerAssistanceCopyWith<AutoAnswerAssistance> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AutoAnswerAssistanceCopyWith<$Res> {
  factory $AutoAnswerAssistanceCopyWith(
    AutoAnswerAssistance value,
    $Res Function(AutoAnswerAssistance) then,
  ) = _$AutoAnswerAssistanceCopyWithImpl<$Res, AutoAnswerAssistance>;
  @useResult
  $Res call({
    @JsonKey(name: 'insight_id') String insightId,
    String question,
    String answer,
    double confidence,
    List<AnswerSource> sources,
    String reasoning,
    DateTime timestamp,
  });
}

/// @nodoc
class _$AutoAnswerAssistanceCopyWithImpl<
  $Res,
  $Val extends AutoAnswerAssistance
>
    implements $AutoAnswerAssistanceCopyWith<$Res> {
  _$AutoAnswerAssistanceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AutoAnswerAssistance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? insightId = null,
    Object? question = null,
    Object? answer = null,
    Object? confidence = null,
    Object? sources = null,
    Object? reasoning = null,
    Object? timestamp = null,
  }) {
    return _then(
      _value.copyWith(
            insightId: null == insightId
                ? _value.insightId
                : insightId // ignore: cast_nullable_to_non_nullable
                      as String,
            question: null == question
                ? _value.question
                : question // ignore: cast_nullable_to_non_nullable
                      as String,
            answer: null == answer
                ? _value.answer
                : answer // ignore: cast_nullable_to_non_nullable
                      as String,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
            sources: null == sources
                ? _value.sources
                : sources // ignore: cast_nullable_to_non_nullable
                      as List<AnswerSource>,
            reasoning: null == reasoning
                ? _value.reasoning
                : reasoning // ignore: cast_nullable_to_non_nullable
                      as String,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AutoAnswerAssistanceImplCopyWith<$Res>
    implements $AutoAnswerAssistanceCopyWith<$Res> {
  factory _$$AutoAnswerAssistanceImplCopyWith(
    _$AutoAnswerAssistanceImpl value,
    $Res Function(_$AutoAnswerAssistanceImpl) then,
  ) = __$$AutoAnswerAssistanceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'insight_id') String insightId,
    String question,
    String answer,
    double confidence,
    List<AnswerSource> sources,
    String reasoning,
    DateTime timestamp,
  });
}

/// @nodoc
class __$$AutoAnswerAssistanceImplCopyWithImpl<$Res>
    extends _$AutoAnswerAssistanceCopyWithImpl<$Res, _$AutoAnswerAssistanceImpl>
    implements _$$AutoAnswerAssistanceImplCopyWith<$Res> {
  __$$AutoAnswerAssistanceImplCopyWithImpl(
    _$AutoAnswerAssistanceImpl _value,
    $Res Function(_$AutoAnswerAssistanceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AutoAnswerAssistance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? insightId = null,
    Object? question = null,
    Object? answer = null,
    Object? confidence = null,
    Object? sources = null,
    Object? reasoning = null,
    Object? timestamp = null,
  }) {
    return _then(
      _$AutoAnswerAssistanceImpl(
        insightId: null == insightId
            ? _value.insightId
            : insightId // ignore: cast_nullable_to_non_nullable
                  as String,
        question: null == question
            ? _value.question
            : question // ignore: cast_nullable_to_non_nullable
                  as String,
        answer: null == answer
            ? _value.answer
            : answer // ignore: cast_nullable_to_non_nullable
                  as String,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
        sources: null == sources
            ? _value._sources
            : sources // ignore: cast_nullable_to_non_nullable
                  as List<AnswerSource>,
        reasoning: null == reasoning
            ? _value.reasoning
            : reasoning // ignore: cast_nullable_to_non_nullable
                  as String,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AutoAnswerAssistanceImpl implements _AutoAnswerAssistance {
  const _$AutoAnswerAssistanceImpl({
    @JsonKey(name: 'insight_id') required this.insightId,
    required this.question,
    required this.answer,
    required this.confidence,
    required final List<AnswerSource> sources,
    required this.reasoning,
    required this.timestamp,
  }) : _sources = sources;

  factory _$AutoAnswerAssistanceImpl.fromJson(Map<String, dynamic> json) =>
      _$$AutoAnswerAssistanceImplFromJson(json);

  @override
  @JsonKey(name: 'insight_id')
  final String insightId;
  @override
  final String question;
  @override
  final String answer;
  @override
  final double confidence;
  final List<AnswerSource> _sources;
  @override
  List<AnswerSource> get sources {
    if (_sources is EqualUnmodifiableListView) return _sources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sources);
  }

  @override
  final String reasoning;
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'AutoAnswerAssistance(insightId: $insightId, question: $question, answer: $answer, confidence: $confidence, sources: $sources, reasoning: $reasoning, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AutoAnswerAssistanceImpl &&
            (identical(other.insightId, insightId) ||
                other.insightId == insightId) &&
            (identical(other.question, question) ||
                other.question == question) &&
            (identical(other.answer, answer) || other.answer == answer) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            const DeepCollectionEquality().equals(other._sources, _sources) &&
            (identical(other.reasoning, reasoning) ||
                other.reasoning == reasoning) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    insightId,
    question,
    answer,
    confidence,
    const DeepCollectionEquality().hash(_sources),
    reasoning,
    timestamp,
  );

  /// Create a copy of AutoAnswerAssistance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AutoAnswerAssistanceImplCopyWith<_$AutoAnswerAssistanceImpl>
  get copyWith =>
      __$$AutoAnswerAssistanceImplCopyWithImpl<_$AutoAnswerAssistanceImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AutoAnswerAssistanceImplToJson(this);
  }
}

abstract class _AutoAnswerAssistance implements AutoAnswerAssistance {
  const factory _AutoAnswerAssistance({
    @JsonKey(name: 'insight_id') required final String insightId,
    required final String question,
    required final String answer,
    required final double confidence,
    required final List<AnswerSource> sources,
    required final String reasoning,
    required final DateTime timestamp,
  }) = _$AutoAnswerAssistanceImpl;

  factory _AutoAnswerAssistance.fromJson(Map<String, dynamic> json) =
      _$AutoAnswerAssistanceImpl.fromJson;

  @override
  @JsonKey(name: 'insight_id')
  String get insightId;
  @override
  String get question;
  @override
  String get answer;
  @override
  double get confidence;
  @override
  List<AnswerSource> get sources;
  @override
  String get reasoning;
  @override
  DateTime get timestamp;

  /// Create a copy of AutoAnswerAssistance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AutoAnswerAssistanceImplCopyWith<_$AutoAnswerAssistanceImpl>
  get copyWith => throw _privateConstructorUsedError;
}

ClarificationAssistance _$ClarificationAssistanceFromJson(
  Map<String, dynamic> json,
) {
  return _ClarificationAssistance.fromJson(json);
}

/// @nodoc
mixin _$ClarificationAssistance {
  @JsonKey(name: 'insight_id')
  String get insightId => throw _privateConstructorUsedError;
  String get statement => throw _privateConstructorUsedError;
  @JsonKey(name: 'vagueness_type')
  String get vaguenessType => throw _privateConstructorUsedError; // 'time', 'assignment', 'detail', 'scope'
  @JsonKey(name: 'suggested_questions')
  List<String> get suggestedQuestions => throw _privateConstructorUsedError;
  double get confidence => throw _privateConstructorUsedError;
  String get reasoning => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Serializes this ClarificationAssistance to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClarificationAssistance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClarificationAssistanceCopyWith<ClarificationAssistance> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClarificationAssistanceCopyWith<$Res> {
  factory $ClarificationAssistanceCopyWith(
    ClarificationAssistance value,
    $Res Function(ClarificationAssistance) then,
  ) = _$ClarificationAssistanceCopyWithImpl<$Res, ClarificationAssistance>;
  @useResult
  $Res call({
    @JsonKey(name: 'insight_id') String insightId,
    String statement,
    @JsonKey(name: 'vagueness_type') String vaguenessType,
    @JsonKey(name: 'suggested_questions') List<String> suggestedQuestions,
    double confidence,
    String reasoning,
    DateTime timestamp,
  });
}

/// @nodoc
class _$ClarificationAssistanceCopyWithImpl<
  $Res,
  $Val extends ClarificationAssistance
>
    implements $ClarificationAssistanceCopyWith<$Res> {
  _$ClarificationAssistanceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClarificationAssistance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? insightId = null,
    Object? statement = null,
    Object? vaguenessType = null,
    Object? suggestedQuestions = null,
    Object? confidence = null,
    Object? reasoning = null,
    Object? timestamp = null,
  }) {
    return _then(
      _value.copyWith(
            insightId: null == insightId
                ? _value.insightId
                : insightId // ignore: cast_nullable_to_non_nullable
                      as String,
            statement: null == statement
                ? _value.statement
                : statement // ignore: cast_nullable_to_non_nullable
                      as String,
            vaguenessType: null == vaguenessType
                ? _value.vaguenessType
                : vaguenessType // ignore: cast_nullable_to_non_nullable
                      as String,
            suggestedQuestions: null == suggestedQuestions
                ? _value.suggestedQuestions
                : suggestedQuestions // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
            reasoning: null == reasoning
                ? _value.reasoning
                : reasoning // ignore: cast_nullable_to_non_nullable
                      as String,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ClarificationAssistanceImplCopyWith<$Res>
    implements $ClarificationAssistanceCopyWith<$Res> {
  factory _$$ClarificationAssistanceImplCopyWith(
    _$ClarificationAssistanceImpl value,
    $Res Function(_$ClarificationAssistanceImpl) then,
  ) = __$$ClarificationAssistanceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'insight_id') String insightId,
    String statement,
    @JsonKey(name: 'vagueness_type') String vaguenessType,
    @JsonKey(name: 'suggested_questions') List<String> suggestedQuestions,
    double confidence,
    String reasoning,
    DateTime timestamp,
  });
}

/// @nodoc
class __$$ClarificationAssistanceImplCopyWithImpl<$Res>
    extends
        _$ClarificationAssistanceCopyWithImpl<
          $Res,
          _$ClarificationAssistanceImpl
        >
    implements _$$ClarificationAssistanceImplCopyWith<$Res> {
  __$$ClarificationAssistanceImplCopyWithImpl(
    _$ClarificationAssistanceImpl _value,
    $Res Function(_$ClarificationAssistanceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ClarificationAssistance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? insightId = null,
    Object? statement = null,
    Object? vaguenessType = null,
    Object? suggestedQuestions = null,
    Object? confidence = null,
    Object? reasoning = null,
    Object? timestamp = null,
  }) {
    return _then(
      _$ClarificationAssistanceImpl(
        insightId: null == insightId
            ? _value.insightId
            : insightId // ignore: cast_nullable_to_non_nullable
                  as String,
        statement: null == statement
            ? _value.statement
            : statement // ignore: cast_nullable_to_non_nullable
                  as String,
        vaguenessType: null == vaguenessType
            ? _value.vaguenessType
            : vaguenessType // ignore: cast_nullable_to_non_nullable
                  as String,
        suggestedQuestions: null == suggestedQuestions
            ? _value._suggestedQuestions
            : suggestedQuestions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
        reasoning: null == reasoning
            ? _value.reasoning
            : reasoning // ignore: cast_nullable_to_non_nullable
                  as String,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ClarificationAssistanceImpl implements _ClarificationAssistance {
  const _$ClarificationAssistanceImpl({
    @JsonKey(name: 'insight_id') required this.insightId,
    required this.statement,
    @JsonKey(name: 'vagueness_type') required this.vaguenessType,
    @JsonKey(name: 'suggested_questions')
    required final List<String> suggestedQuestions,
    required this.confidence,
    required this.reasoning,
    required this.timestamp,
  }) : _suggestedQuestions = suggestedQuestions;

  factory _$ClarificationAssistanceImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClarificationAssistanceImplFromJson(json);

  @override
  @JsonKey(name: 'insight_id')
  final String insightId;
  @override
  final String statement;
  @override
  @JsonKey(name: 'vagueness_type')
  final String vaguenessType;
  // 'time', 'assignment', 'detail', 'scope'
  final List<String> _suggestedQuestions;
  // 'time', 'assignment', 'detail', 'scope'
  @override
  @JsonKey(name: 'suggested_questions')
  List<String> get suggestedQuestions {
    if (_suggestedQuestions is EqualUnmodifiableListView)
      return _suggestedQuestions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_suggestedQuestions);
  }

  @override
  final double confidence;
  @override
  final String reasoning;
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'ClarificationAssistance(insightId: $insightId, statement: $statement, vaguenessType: $vaguenessType, suggestedQuestions: $suggestedQuestions, confidence: $confidence, reasoning: $reasoning, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClarificationAssistanceImpl &&
            (identical(other.insightId, insightId) ||
                other.insightId == insightId) &&
            (identical(other.statement, statement) ||
                other.statement == statement) &&
            (identical(other.vaguenessType, vaguenessType) ||
                other.vaguenessType == vaguenessType) &&
            const DeepCollectionEquality().equals(
              other._suggestedQuestions,
              _suggestedQuestions,
            ) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.reasoning, reasoning) ||
                other.reasoning == reasoning) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    insightId,
    statement,
    vaguenessType,
    const DeepCollectionEquality().hash(_suggestedQuestions),
    confidence,
    reasoning,
    timestamp,
  );

  /// Create a copy of ClarificationAssistance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClarificationAssistanceImplCopyWith<_$ClarificationAssistanceImpl>
  get copyWith =>
      __$$ClarificationAssistanceImplCopyWithImpl<
        _$ClarificationAssistanceImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClarificationAssistanceImplToJson(this);
  }
}

abstract class _ClarificationAssistance implements ClarificationAssistance {
  const factory _ClarificationAssistance({
    @JsonKey(name: 'insight_id') required final String insightId,
    required final String statement,
    @JsonKey(name: 'vagueness_type') required final String vaguenessType,
    @JsonKey(name: 'suggested_questions')
    required final List<String> suggestedQuestions,
    required final double confidence,
    required final String reasoning,
    required final DateTime timestamp,
  }) = _$ClarificationAssistanceImpl;

  factory _ClarificationAssistance.fromJson(Map<String, dynamic> json) =
      _$ClarificationAssistanceImpl.fromJson;

  @override
  @JsonKey(name: 'insight_id')
  String get insightId;
  @override
  String get statement;
  @override
  @JsonKey(name: 'vagueness_type')
  String get vaguenessType; // 'time', 'assignment', 'detail', 'scope'
  @override
  @JsonKey(name: 'suggested_questions')
  List<String> get suggestedQuestions;
  @override
  double get confidence;
  @override
  String get reasoning;
  @override
  DateTime get timestamp;

  /// Create a copy of ClarificationAssistance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClarificationAssistanceImplCopyWith<_$ClarificationAssistanceImpl>
  get copyWith => throw _privateConstructorUsedError;
}

ConflictAssistance _$ConflictAssistanceFromJson(Map<String, dynamic> json) {
  return _ConflictAssistance.fromJson(json);
}

/// @nodoc
mixin _$ConflictAssistance {
  @JsonKey(name: 'insight_id')
  String get insightId => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_statement')
  String get currentStatement => throw _privateConstructorUsedError;
  @JsonKey(name: 'conflicting_content_id')
  String get conflictingContentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'conflicting_title')
  String get conflictingTitle => throw _privateConstructorUsedError;
  @JsonKey(name: 'conflicting_snippet')
  String get conflictingSnippet => throw _privateConstructorUsedError;
  @JsonKey(name: 'conflicting_date')
  DateTime get conflictingDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'conflict_severity')
  String get conflictSeverity => throw _privateConstructorUsedError; // 'high', 'medium', 'low'
  double get confidence => throw _privateConstructorUsedError;
  String get reasoning => throw _privateConstructorUsedError;
  @JsonKey(name: 'resolution_suggestions')
  List<String> get resolutionSuggestions => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Serializes this ConflictAssistance to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConflictAssistance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConflictAssistanceCopyWith<ConflictAssistance> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConflictAssistanceCopyWith<$Res> {
  factory $ConflictAssistanceCopyWith(
    ConflictAssistance value,
    $Res Function(ConflictAssistance) then,
  ) = _$ConflictAssistanceCopyWithImpl<$Res, ConflictAssistance>;
  @useResult
  $Res call({
    @JsonKey(name: 'insight_id') String insightId,
    @JsonKey(name: 'current_statement') String currentStatement,
    @JsonKey(name: 'conflicting_content_id') String conflictingContentId,
    @JsonKey(name: 'conflicting_title') String conflictingTitle,
    @JsonKey(name: 'conflicting_snippet') String conflictingSnippet,
    @JsonKey(name: 'conflicting_date') DateTime conflictingDate,
    @JsonKey(name: 'conflict_severity') String conflictSeverity,
    double confidence,
    String reasoning,
    @JsonKey(name: 'resolution_suggestions') List<String> resolutionSuggestions,
    DateTime timestamp,
  });
}

/// @nodoc
class _$ConflictAssistanceCopyWithImpl<$Res, $Val extends ConflictAssistance>
    implements $ConflictAssistanceCopyWith<$Res> {
  _$ConflictAssistanceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConflictAssistance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? insightId = null,
    Object? currentStatement = null,
    Object? conflictingContentId = null,
    Object? conflictingTitle = null,
    Object? conflictingSnippet = null,
    Object? conflictingDate = null,
    Object? conflictSeverity = null,
    Object? confidence = null,
    Object? reasoning = null,
    Object? resolutionSuggestions = null,
    Object? timestamp = null,
  }) {
    return _then(
      _value.copyWith(
            insightId: null == insightId
                ? _value.insightId
                : insightId // ignore: cast_nullable_to_non_nullable
                      as String,
            currentStatement: null == currentStatement
                ? _value.currentStatement
                : currentStatement // ignore: cast_nullable_to_non_nullable
                      as String,
            conflictingContentId: null == conflictingContentId
                ? _value.conflictingContentId
                : conflictingContentId // ignore: cast_nullable_to_non_nullable
                      as String,
            conflictingTitle: null == conflictingTitle
                ? _value.conflictingTitle
                : conflictingTitle // ignore: cast_nullable_to_non_nullable
                      as String,
            conflictingSnippet: null == conflictingSnippet
                ? _value.conflictingSnippet
                : conflictingSnippet // ignore: cast_nullable_to_non_nullable
                      as String,
            conflictingDate: null == conflictingDate
                ? _value.conflictingDate
                : conflictingDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            conflictSeverity: null == conflictSeverity
                ? _value.conflictSeverity
                : conflictSeverity // ignore: cast_nullable_to_non_nullable
                      as String,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
            reasoning: null == reasoning
                ? _value.reasoning
                : reasoning // ignore: cast_nullable_to_non_nullable
                      as String,
            resolutionSuggestions: null == resolutionSuggestions
                ? _value.resolutionSuggestions
                : resolutionSuggestions // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ConflictAssistanceImplCopyWith<$Res>
    implements $ConflictAssistanceCopyWith<$Res> {
  factory _$$ConflictAssistanceImplCopyWith(
    _$ConflictAssistanceImpl value,
    $Res Function(_$ConflictAssistanceImpl) then,
  ) = __$$ConflictAssistanceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'insight_id') String insightId,
    @JsonKey(name: 'current_statement') String currentStatement,
    @JsonKey(name: 'conflicting_content_id') String conflictingContentId,
    @JsonKey(name: 'conflicting_title') String conflictingTitle,
    @JsonKey(name: 'conflicting_snippet') String conflictingSnippet,
    @JsonKey(name: 'conflicting_date') DateTime conflictingDate,
    @JsonKey(name: 'conflict_severity') String conflictSeverity,
    double confidence,
    String reasoning,
    @JsonKey(name: 'resolution_suggestions') List<String> resolutionSuggestions,
    DateTime timestamp,
  });
}

/// @nodoc
class __$$ConflictAssistanceImplCopyWithImpl<$Res>
    extends _$ConflictAssistanceCopyWithImpl<$Res, _$ConflictAssistanceImpl>
    implements _$$ConflictAssistanceImplCopyWith<$Res> {
  __$$ConflictAssistanceImplCopyWithImpl(
    _$ConflictAssistanceImpl _value,
    $Res Function(_$ConflictAssistanceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConflictAssistance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? insightId = null,
    Object? currentStatement = null,
    Object? conflictingContentId = null,
    Object? conflictingTitle = null,
    Object? conflictingSnippet = null,
    Object? conflictingDate = null,
    Object? conflictSeverity = null,
    Object? confidence = null,
    Object? reasoning = null,
    Object? resolutionSuggestions = null,
    Object? timestamp = null,
  }) {
    return _then(
      _$ConflictAssistanceImpl(
        insightId: null == insightId
            ? _value.insightId
            : insightId // ignore: cast_nullable_to_non_nullable
                  as String,
        currentStatement: null == currentStatement
            ? _value.currentStatement
            : currentStatement // ignore: cast_nullable_to_non_nullable
                  as String,
        conflictingContentId: null == conflictingContentId
            ? _value.conflictingContentId
            : conflictingContentId // ignore: cast_nullable_to_non_nullable
                  as String,
        conflictingTitle: null == conflictingTitle
            ? _value.conflictingTitle
            : conflictingTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        conflictingSnippet: null == conflictingSnippet
            ? _value.conflictingSnippet
            : conflictingSnippet // ignore: cast_nullable_to_non_nullable
                  as String,
        conflictingDate: null == conflictingDate
            ? _value.conflictingDate
            : conflictingDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        conflictSeverity: null == conflictSeverity
            ? _value.conflictSeverity
            : conflictSeverity // ignore: cast_nullable_to_non_nullable
                  as String,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
        reasoning: null == reasoning
            ? _value.reasoning
            : reasoning // ignore: cast_nullable_to_non_nullable
                  as String,
        resolutionSuggestions: null == resolutionSuggestions
            ? _value._resolutionSuggestions
            : resolutionSuggestions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ConflictAssistanceImpl implements _ConflictAssistance {
  const _$ConflictAssistanceImpl({
    @JsonKey(name: 'insight_id') required this.insightId,
    @JsonKey(name: 'current_statement') required this.currentStatement,
    @JsonKey(name: 'conflicting_content_id') required this.conflictingContentId,
    @JsonKey(name: 'conflicting_title') required this.conflictingTitle,
    @JsonKey(name: 'conflicting_snippet') required this.conflictingSnippet,
    @JsonKey(name: 'conflicting_date') required this.conflictingDate,
    @JsonKey(name: 'conflict_severity') required this.conflictSeverity,
    required this.confidence,
    required this.reasoning,
    @JsonKey(name: 'resolution_suggestions')
    required final List<String> resolutionSuggestions,
    required this.timestamp,
  }) : _resolutionSuggestions = resolutionSuggestions;

  factory _$ConflictAssistanceImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConflictAssistanceImplFromJson(json);

  @override
  @JsonKey(name: 'insight_id')
  final String insightId;
  @override
  @JsonKey(name: 'current_statement')
  final String currentStatement;
  @override
  @JsonKey(name: 'conflicting_content_id')
  final String conflictingContentId;
  @override
  @JsonKey(name: 'conflicting_title')
  final String conflictingTitle;
  @override
  @JsonKey(name: 'conflicting_snippet')
  final String conflictingSnippet;
  @override
  @JsonKey(name: 'conflicting_date')
  final DateTime conflictingDate;
  @override
  @JsonKey(name: 'conflict_severity')
  final String conflictSeverity;
  // 'high', 'medium', 'low'
  @override
  final double confidence;
  @override
  final String reasoning;
  final List<String> _resolutionSuggestions;
  @override
  @JsonKey(name: 'resolution_suggestions')
  List<String> get resolutionSuggestions {
    if (_resolutionSuggestions is EqualUnmodifiableListView)
      return _resolutionSuggestions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_resolutionSuggestions);
  }

  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'ConflictAssistance(insightId: $insightId, currentStatement: $currentStatement, conflictingContentId: $conflictingContentId, conflictingTitle: $conflictingTitle, conflictingSnippet: $conflictingSnippet, conflictingDate: $conflictingDate, conflictSeverity: $conflictSeverity, confidence: $confidence, reasoning: $reasoning, resolutionSuggestions: $resolutionSuggestions, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConflictAssistanceImpl &&
            (identical(other.insightId, insightId) ||
                other.insightId == insightId) &&
            (identical(other.currentStatement, currentStatement) ||
                other.currentStatement == currentStatement) &&
            (identical(other.conflictingContentId, conflictingContentId) ||
                other.conflictingContentId == conflictingContentId) &&
            (identical(other.conflictingTitle, conflictingTitle) ||
                other.conflictingTitle == conflictingTitle) &&
            (identical(other.conflictingSnippet, conflictingSnippet) ||
                other.conflictingSnippet == conflictingSnippet) &&
            (identical(other.conflictingDate, conflictingDate) ||
                other.conflictingDate == conflictingDate) &&
            (identical(other.conflictSeverity, conflictSeverity) ||
                other.conflictSeverity == conflictSeverity) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.reasoning, reasoning) ||
                other.reasoning == reasoning) &&
            const DeepCollectionEquality().equals(
              other._resolutionSuggestions,
              _resolutionSuggestions,
            ) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    insightId,
    currentStatement,
    conflictingContentId,
    conflictingTitle,
    conflictingSnippet,
    conflictingDate,
    conflictSeverity,
    confidence,
    reasoning,
    const DeepCollectionEquality().hash(_resolutionSuggestions),
    timestamp,
  );

  /// Create a copy of ConflictAssistance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConflictAssistanceImplCopyWith<_$ConflictAssistanceImpl> get copyWith =>
      __$$ConflictAssistanceImplCopyWithImpl<_$ConflictAssistanceImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ConflictAssistanceImplToJson(this);
  }
}

abstract class _ConflictAssistance implements ConflictAssistance {
  const factory _ConflictAssistance({
    @JsonKey(name: 'insight_id') required final String insightId,
    @JsonKey(name: 'current_statement') required final String currentStatement,
    @JsonKey(name: 'conflicting_content_id')
    required final String conflictingContentId,
    @JsonKey(name: 'conflicting_title') required final String conflictingTitle,
    @JsonKey(name: 'conflicting_snippet')
    required final String conflictingSnippet,
    @JsonKey(name: 'conflicting_date') required final DateTime conflictingDate,
    @JsonKey(name: 'conflict_severity') required final String conflictSeverity,
    required final double confidence,
    required final String reasoning,
    @JsonKey(name: 'resolution_suggestions')
    required final List<String> resolutionSuggestions,
    required final DateTime timestamp,
  }) = _$ConflictAssistanceImpl;

  factory _ConflictAssistance.fromJson(Map<String, dynamic> json) =
      _$ConflictAssistanceImpl.fromJson;

  @override
  @JsonKey(name: 'insight_id')
  String get insightId;
  @override
  @JsonKey(name: 'current_statement')
  String get currentStatement;
  @override
  @JsonKey(name: 'conflicting_content_id')
  String get conflictingContentId;
  @override
  @JsonKey(name: 'conflicting_title')
  String get conflictingTitle;
  @override
  @JsonKey(name: 'conflicting_snippet')
  String get conflictingSnippet;
  @override
  @JsonKey(name: 'conflicting_date')
  DateTime get conflictingDate;
  @override
  @JsonKey(name: 'conflict_severity')
  String get conflictSeverity; // 'high', 'medium', 'low'
  @override
  double get confidence;
  @override
  String get reasoning;
  @override
  @JsonKey(name: 'resolution_suggestions')
  List<String> get resolutionSuggestions;
  @override
  DateTime get timestamp;

  /// Create a copy of ConflictAssistance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConflictAssistanceImplCopyWith<_$ConflictAssistanceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

QualityIssue _$QualityIssueFromJson(Map<String, dynamic> json) {
  return _QualityIssue.fromJson(json);
}

/// @nodoc
mixin _$QualityIssue {
  String get field =>
      throw _privateConstructorUsedError; // 'owner', 'deadline', 'description', 'success_criteria'
  String get severity =>
      throw _privateConstructorUsedError; // 'critical', 'important', 'suggestion'
  String get message => throw _privateConstructorUsedError;
  @JsonKey(name: 'suggested_fix')
  String? get suggestedFix => throw _privateConstructorUsedError;

  /// Serializes this QualityIssue to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QualityIssue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QualityIssueCopyWith<QualityIssue> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QualityIssueCopyWith<$Res> {
  factory $QualityIssueCopyWith(
    QualityIssue value,
    $Res Function(QualityIssue) then,
  ) = _$QualityIssueCopyWithImpl<$Res, QualityIssue>;
  @useResult
  $Res call({
    String field,
    String severity,
    String message,
    @JsonKey(name: 'suggested_fix') String? suggestedFix,
  });
}

/// @nodoc
class _$QualityIssueCopyWithImpl<$Res, $Val extends QualityIssue>
    implements $QualityIssueCopyWith<$Res> {
  _$QualityIssueCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QualityIssue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field = null,
    Object? severity = null,
    Object? message = null,
    Object? suggestedFix = freezed,
  }) {
    return _then(
      _value.copyWith(
            field: null == field
                ? _value.field
                : field // ignore: cast_nullable_to_non_nullable
                      as String,
            severity: null == severity
                ? _value.severity
                : severity // ignore: cast_nullable_to_non_nullable
                      as String,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            suggestedFix: freezed == suggestedFix
                ? _value.suggestedFix
                : suggestedFix // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$QualityIssueImplCopyWith<$Res>
    implements $QualityIssueCopyWith<$Res> {
  factory _$$QualityIssueImplCopyWith(
    _$QualityIssueImpl value,
    $Res Function(_$QualityIssueImpl) then,
  ) = __$$QualityIssueImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String field,
    String severity,
    String message,
    @JsonKey(name: 'suggested_fix') String? suggestedFix,
  });
}

/// @nodoc
class __$$QualityIssueImplCopyWithImpl<$Res>
    extends _$QualityIssueCopyWithImpl<$Res, _$QualityIssueImpl>
    implements _$$QualityIssueImplCopyWith<$Res> {
  __$$QualityIssueImplCopyWithImpl(
    _$QualityIssueImpl _value,
    $Res Function(_$QualityIssueImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QualityIssue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field = null,
    Object? severity = null,
    Object? message = null,
    Object? suggestedFix = freezed,
  }) {
    return _then(
      _$QualityIssueImpl(
        field: null == field
            ? _value.field
            : field // ignore: cast_nullable_to_non_nullable
                  as String,
        severity: null == severity
            ? _value.severity
            : severity // ignore: cast_nullable_to_non_nullable
                  as String,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        suggestedFix: freezed == suggestedFix
            ? _value.suggestedFix
            : suggestedFix // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$QualityIssueImpl implements _QualityIssue {
  const _$QualityIssueImpl({
    required this.field,
    required this.severity,
    required this.message,
    @JsonKey(name: 'suggested_fix') this.suggestedFix,
  });

  factory _$QualityIssueImpl.fromJson(Map<String, dynamic> json) =>
      _$$QualityIssueImplFromJson(json);

  @override
  final String field;
  // 'owner', 'deadline', 'description', 'success_criteria'
  @override
  final String severity;
  // 'critical', 'important', 'suggestion'
  @override
  final String message;
  @override
  @JsonKey(name: 'suggested_fix')
  final String? suggestedFix;

  @override
  String toString() {
    return 'QualityIssue(field: $field, severity: $severity, message: $message, suggestedFix: $suggestedFix)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QualityIssueImpl &&
            (identical(other.field, field) || other.field == field) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.suggestedFix, suggestedFix) ||
                other.suggestedFix == suggestedFix));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, field, severity, message, suggestedFix);

  /// Create a copy of QualityIssue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QualityIssueImplCopyWith<_$QualityIssueImpl> get copyWith =>
      __$$QualityIssueImplCopyWithImpl<_$QualityIssueImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QualityIssueImplToJson(this);
  }
}

abstract class _QualityIssue implements QualityIssue {
  const factory _QualityIssue({
    required final String field,
    required final String severity,
    required final String message,
    @JsonKey(name: 'suggested_fix') final String? suggestedFix,
  }) = _$QualityIssueImpl;

  factory _QualityIssue.fromJson(Map<String, dynamic> json) =
      _$QualityIssueImpl.fromJson;

  @override
  String get field; // 'owner', 'deadline', 'description', 'success_criteria'
  @override
  String get severity; // 'critical', 'important', 'suggestion'
  @override
  String get message;
  @override
  @JsonKey(name: 'suggested_fix')
  String? get suggestedFix;

  /// Create a copy of QualityIssue
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QualityIssueImplCopyWith<_$QualityIssueImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ActionItemQualityAssistance _$ActionItemQualityAssistanceFromJson(
  Map<String, dynamic> json,
) {
  return _ActionItemQualityAssistance.fromJson(json);
}

/// @nodoc
mixin _$ActionItemQualityAssistance {
  @JsonKey(name: 'insight_id')
  String get insightId => throw _privateConstructorUsedError;
  @JsonKey(name: 'action_item')
  String get actionItem => throw _privateConstructorUsedError;
  @JsonKey(name: 'completeness_score')
  double get completenessScore => throw _privateConstructorUsedError;
  List<QualityIssue> get issues => throw _privateConstructorUsedError;
  @JsonKey(name: 'improved_version')
  String? get improvedVersion => throw _privateConstructorUsedError;
  DateTime get timestamp =>
      throw _privateConstructorUsedError; // Merged clarification data (optional, added Oct 2025 for deduplication)
  @JsonKey(name: 'clarification_suggestions')
  List<String>? get clarificationSuggestions =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'vagueness_type')
  String? get vaguenessType => throw _privateConstructorUsedError;
  @JsonKey(name: 'vagueness_confidence')
  double? get vaguenessConfidence => throw _privateConstructorUsedError;
  @JsonKey(name: 'combined_reasoning')
  String? get combinedReasoning => throw _privateConstructorUsedError;

  /// Serializes this ActionItemQualityAssistance to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ActionItemQualityAssistance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActionItemQualityAssistanceCopyWith<ActionItemQualityAssistance>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActionItemQualityAssistanceCopyWith<$Res> {
  factory $ActionItemQualityAssistanceCopyWith(
    ActionItemQualityAssistance value,
    $Res Function(ActionItemQualityAssistance) then,
  ) =
      _$ActionItemQualityAssistanceCopyWithImpl<
        $Res,
        ActionItemQualityAssistance
      >;
  @useResult
  $Res call({
    @JsonKey(name: 'insight_id') String insightId,
    @JsonKey(name: 'action_item') String actionItem,
    @JsonKey(name: 'completeness_score') double completenessScore,
    List<QualityIssue> issues,
    @JsonKey(name: 'improved_version') String? improvedVersion,
    DateTime timestamp,
    @JsonKey(name: 'clarification_suggestions')
    List<String>? clarificationSuggestions,
    @JsonKey(name: 'vagueness_type') String? vaguenessType,
    @JsonKey(name: 'vagueness_confidence') double? vaguenessConfidence,
    @JsonKey(name: 'combined_reasoning') String? combinedReasoning,
  });
}

/// @nodoc
class _$ActionItemQualityAssistanceCopyWithImpl<
  $Res,
  $Val extends ActionItemQualityAssistance
>
    implements $ActionItemQualityAssistanceCopyWith<$Res> {
  _$ActionItemQualityAssistanceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActionItemQualityAssistance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? insightId = null,
    Object? actionItem = null,
    Object? completenessScore = null,
    Object? issues = null,
    Object? improvedVersion = freezed,
    Object? timestamp = null,
    Object? clarificationSuggestions = freezed,
    Object? vaguenessType = freezed,
    Object? vaguenessConfidence = freezed,
    Object? combinedReasoning = freezed,
  }) {
    return _then(
      _value.copyWith(
            insightId: null == insightId
                ? _value.insightId
                : insightId // ignore: cast_nullable_to_non_nullable
                      as String,
            actionItem: null == actionItem
                ? _value.actionItem
                : actionItem // ignore: cast_nullable_to_non_nullable
                      as String,
            completenessScore: null == completenessScore
                ? _value.completenessScore
                : completenessScore // ignore: cast_nullable_to_non_nullable
                      as double,
            issues: null == issues
                ? _value.issues
                : issues // ignore: cast_nullable_to_non_nullable
                      as List<QualityIssue>,
            improvedVersion: freezed == improvedVersion
                ? _value.improvedVersion
                : improvedVersion // ignore: cast_nullable_to_non_nullable
                      as String?,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            clarificationSuggestions: freezed == clarificationSuggestions
                ? _value.clarificationSuggestions
                : clarificationSuggestions // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            vaguenessType: freezed == vaguenessType
                ? _value.vaguenessType
                : vaguenessType // ignore: cast_nullable_to_non_nullable
                      as String?,
            vaguenessConfidence: freezed == vaguenessConfidence
                ? _value.vaguenessConfidence
                : vaguenessConfidence // ignore: cast_nullable_to_non_nullable
                      as double?,
            combinedReasoning: freezed == combinedReasoning
                ? _value.combinedReasoning
                : combinedReasoning // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ActionItemQualityAssistanceImplCopyWith<$Res>
    implements $ActionItemQualityAssistanceCopyWith<$Res> {
  factory _$$ActionItemQualityAssistanceImplCopyWith(
    _$ActionItemQualityAssistanceImpl value,
    $Res Function(_$ActionItemQualityAssistanceImpl) then,
  ) = __$$ActionItemQualityAssistanceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'insight_id') String insightId,
    @JsonKey(name: 'action_item') String actionItem,
    @JsonKey(name: 'completeness_score') double completenessScore,
    List<QualityIssue> issues,
    @JsonKey(name: 'improved_version') String? improvedVersion,
    DateTime timestamp,
    @JsonKey(name: 'clarification_suggestions')
    List<String>? clarificationSuggestions,
    @JsonKey(name: 'vagueness_type') String? vaguenessType,
    @JsonKey(name: 'vagueness_confidence') double? vaguenessConfidence,
    @JsonKey(name: 'combined_reasoning') String? combinedReasoning,
  });
}

/// @nodoc
class __$$ActionItemQualityAssistanceImplCopyWithImpl<$Res>
    extends
        _$ActionItemQualityAssistanceCopyWithImpl<
          $Res,
          _$ActionItemQualityAssistanceImpl
        >
    implements _$$ActionItemQualityAssistanceImplCopyWith<$Res> {
  __$$ActionItemQualityAssistanceImplCopyWithImpl(
    _$ActionItemQualityAssistanceImpl _value,
    $Res Function(_$ActionItemQualityAssistanceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ActionItemQualityAssistance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? insightId = null,
    Object? actionItem = null,
    Object? completenessScore = null,
    Object? issues = null,
    Object? improvedVersion = freezed,
    Object? timestamp = null,
    Object? clarificationSuggestions = freezed,
    Object? vaguenessType = freezed,
    Object? vaguenessConfidence = freezed,
    Object? combinedReasoning = freezed,
  }) {
    return _then(
      _$ActionItemQualityAssistanceImpl(
        insightId: null == insightId
            ? _value.insightId
            : insightId // ignore: cast_nullable_to_non_nullable
                  as String,
        actionItem: null == actionItem
            ? _value.actionItem
            : actionItem // ignore: cast_nullable_to_non_nullable
                  as String,
        completenessScore: null == completenessScore
            ? _value.completenessScore
            : completenessScore // ignore: cast_nullable_to_non_nullable
                  as double,
        issues: null == issues
            ? _value._issues
            : issues // ignore: cast_nullable_to_non_nullable
                  as List<QualityIssue>,
        improvedVersion: freezed == improvedVersion
            ? _value.improvedVersion
            : improvedVersion // ignore: cast_nullable_to_non_nullable
                  as String?,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        clarificationSuggestions: freezed == clarificationSuggestions
            ? _value._clarificationSuggestions
            : clarificationSuggestions // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        vaguenessType: freezed == vaguenessType
            ? _value.vaguenessType
            : vaguenessType // ignore: cast_nullable_to_non_nullable
                  as String?,
        vaguenessConfidence: freezed == vaguenessConfidence
            ? _value.vaguenessConfidence
            : vaguenessConfidence // ignore: cast_nullable_to_non_nullable
                  as double?,
        combinedReasoning: freezed == combinedReasoning
            ? _value.combinedReasoning
            : combinedReasoning // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ActionItemQualityAssistanceImpl
    implements _ActionItemQualityAssistance {
  const _$ActionItemQualityAssistanceImpl({
    @JsonKey(name: 'insight_id') required this.insightId,
    @JsonKey(name: 'action_item') required this.actionItem,
    @JsonKey(name: 'completeness_score') required this.completenessScore,
    required final List<QualityIssue> issues,
    @JsonKey(name: 'improved_version') this.improvedVersion,
    required this.timestamp,
    @JsonKey(name: 'clarification_suggestions')
    final List<String>? clarificationSuggestions,
    @JsonKey(name: 'vagueness_type') this.vaguenessType,
    @JsonKey(name: 'vagueness_confidence') this.vaguenessConfidence,
    @JsonKey(name: 'combined_reasoning') this.combinedReasoning,
  }) : _issues = issues,
       _clarificationSuggestions = clarificationSuggestions;

  factory _$ActionItemQualityAssistanceImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$ActionItemQualityAssistanceImplFromJson(json);

  @override
  @JsonKey(name: 'insight_id')
  final String insightId;
  @override
  @JsonKey(name: 'action_item')
  final String actionItem;
  @override
  @JsonKey(name: 'completeness_score')
  final double completenessScore;
  final List<QualityIssue> _issues;
  @override
  List<QualityIssue> get issues {
    if (_issues is EqualUnmodifiableListView) return _issues;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_issues);
  }

  @override
  @JsonKey(name: 'improved_version')
  final String? improvedVersion;
  @override
  final DateTime timestamp;
  // Merged clarification data (optional, added Oct 2025 for deduplication)
  final List<String>? _clarificationSuggestions;
  // Merged clarification data (optional, added Oct 2025 for deduplication)
  @override
  @JsonKey(name: 'clarification_suggestions')
  List<String>? get clarificationSuggestions {
    final value = _clarificationSuggestions;
    if (value == null) return null;
    if (_clarificationSuggestions is EqualUnmodifiableListView)
      return _clarificationSuggestions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'vagueness_type')
  final String? vaguenessType;
  @override
  @JsonKey(name: 'vagueness_confidence')
  final double? vaguenessConfidence;
  @override
  @JsonKey(name: 'combined_reasoning')
  final String? combinedReasoning;

  @override
  String toString() {
    return 'ActionItemQualityAssistance(insightId: $insightId, actionItem: $actionItem, completenessScore: $completenessScore, issues: $issues, improvedVersion: $improvedVersion, timestamp: $timestamp, clarificationSuggestions: $clarificationSuggestions, vaguenessType: $vaguenessType, vaguenessConfidence: $vaguenessConfidence, combinedReasoning: $combinedReasoning)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActionItemQualityAssistanceImpl &&
            (identical(other.insightId, insightId) ||
                other.insightId == insightId) &&
            (identical(other.actionItem, actionItem) ||
                other.actionItem == actionItem) &&
            (identical(other.completenessScore, completenessScore) ||
                other.completenessScore == completenessScore) &&
            const DeepCollectionEquality().equals(other._issues, _issues) &&
            (identical(other.improvedVersion, improvedVersion) ||
                other.improvedVersion == improvedVersion) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            const DeepCollectionEquality().equals(
              other._clarificationSuggestions,
              _clarificationSuggestions,
            ) &&
            (identical(other.vaguenessType, vaguenessType) ||
                other.vaguenessType == vaguenessType) &&
            (identical(other.vaguenessConfidence, vaguenessConfidence) ||
                other.vaguenessConfidence == vaguenessConfidence) &&
            (identical(other.combinedReasoning, combinedReasoning) ||
                other.combinedReasoning == combinedReasoning));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    insightId,
    actionItem,
    completenessScore,
    const DeepCollectionEquality().hash(_issues),
    improvedVersion,
    timestamp,
    const DeepCollectionEquality().hash(_clarificationSuggestions),
    vaguenessType,
    vaguenessConfidence,
    combinedReasoning,
  );

  /// Create a copy of ActionItemQualityAssistance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActionItemQualityAssistanceImplCopyWith<_$ActionItemQualityAssistanceImpl>
  get copyWith =>
      __$$ActionItemQualityAssistanceImplCopyWithImpl<
        _$ActionItemQualityAssistanceImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ActionItemQualityAssistanceImplToJson(this);
  }
}

abstract class _ActionItemQualityAssistance
    implements ActionItemQualityAssistance {
  const factory _ActionItemQualityAssistance({
    @JsonKey(name: 'insight_id') required final String insightId,
    @JsonKey(name: 'action_item') required final String actionItem,
    @JsonKey(name: 'completeness_score')
    required final double completenessScore,
    required final List<QualityIssue> issues,
    @JsonKey(name: 'improved_version') final String? improvedVersion,
    required final DateTime timestamp,
    @JsonKey(name: 'clarification_suggestions')
    final List<String>? clarificationSuggestions,
    @JsonKey(name: 'vagueness_type') final String? vaguenessType,
    @JsonKey(name: 'vagueness_confidence') final double? vaguenessConfidence,
    @JsonKey(name: 'combined_reasoning') final String? combinedReasoning,
  }) = _$ActionItemQualityAssistanceImpl;

  factory _ActionItemQualityAssistance.fromJson(Map<String, dynamic> json) =
      _$ActionItemQualityAssistanceImpl.fromJson;

  @override
  @JsonKey(name: 'insight_id')
  String get insightId;
  @override
  @JsonKey(name: 'action_item')
  String get actionItem;
  @override
  @JsonKey(name: 'completeness_score')
  double get completenessScore;
  @override
  List<QualityIssue> get issues;
  @override
  @JsonKey(name: 'improved_version')
  String? get improvedVersion;
  @override
  DateTime get timestamp; // Merged clarification data (optional, added Oct 2025 for deduplication)
  @override
  @JsonKey(name: 'clarification_suggestions')
  List<String>? get clarificationSuggestions;
  @override
  @JsonKey(name: 'vagueness_type')
  String? get vaguenessType;
  @override
  @JsonKey(name: 'vagueness_confidence')
  double? get vaguenessConfidence;
  @override
  @JsonKey(name: 'combined_reasoning')
  String? get combinedReasoning;

  /// Create a copy of ActionItemQualityAssistance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActionItemQualityAssistanceImplCopyWith<_$ActionItemQualityAssistanceImpl>
  get copyWith => throw _privateConstructorUsedError;
}

FollowUpSuggestionAssistance _$FollowUpSuggestionAssistanceFromJson(
  Map<String, dynamic> json,
) {
  return _FollowUpSuggestionAssistance.fromJson(json);
}

/// @nodoc
mixin _$FollowUpSuggestionAssistance {
  @JsonKey(name: 'insight_id')
  String get insightId => throw _privateConstructorUsedError;
  String get topic => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;
  @JsonKey(name: 'related_content_id')
  String get relatedContentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'related_title')
  String get relatedTitle => throw _privateConstructorUsedError;
  @JsonKey(name: 'related_date')
  DateTime get relatedDate => throw _privateConstructorUsedError;
  String get urgency =>
      throw _privateConstructorUsedError; // 'high', 'medium', 'low'
  @JsonKey(name: 'context_snippet')
  String get contextSnippet => throw _privateConstructorUsedError;
  double get confidence => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Serializes this FollowUpSuggestionAssistance to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FollowUpSuggestionAssistance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FollowUpSuggestionAssistanceCopyWith<FollowUpSuggestionAssistance>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FollowUpSuggestionAssistanceCopyWith<$Res> {
  factory $FollowUpSuggestionAssistanceCopyWith(
    FollowUpSuggestionAssistance value,
    $Res Function(FollowUpSuggestionAssistance) then,
  ) =
      _$FollowUpSuggestionAssistanceCopyWithImpl<
        $Res,
        FollowUpSuggestionAssistance
      >;
  @useResult
  $Res call({
    @JsonKey(name: 'insight_id') String insightId,
    String topic,
    String reason,
    @JsonKey(name: 'related_content_id') String relatedContentId,
    @JsonKey(name: 'related_title') String relatedTitle,
    @JsonKey(name: 'related_date') DateTime relatedDate,
    String urgency,
    @JsonKey(name: 'context_snippet') String contextSnippet,
    double confidence,
    DateTime timestamp,
  });
}

/// @nodoc
class _$FollowUpSuggestionAssistanceCopyWithImpl<
  $Res,
  $Val extends FollowUpSuggestionAssistance
>
    implements $FollowUpSuggestionAssistanceCopyWith<$Res> {
  _$FollowUpSuggestionAssistanceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FollowUpSuggestionAssistance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? insightId = null,
    Object? topic = null,
    Object? reason = null,
    Object? relatedContentId = null,
    Object? relatedTitle = null,
    Object? relatedDate = null,
    Object? urgency = null,
    Object? contextSnippet = null,
    Object? confidence = null,
    Object? timestamp = null,
  }) {
    return _then(
      _value.copyWith(
            insightId: null == insightId
                ? _value.insightId
                : insightId // ignore: cast_nullable_to_non_nullable
                      as String,
            topic: null == topic
                ? _value.topic
                : topic // ignore: cast_nullable_to_non_nullable
                      as String,
            reason: null == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String,
            relatedContentId: null == relatedContentId
                ? _value.relatedContentId
                : relatedContentId // ignore: cast_nullable_to_non_nullable
                      as String,
            relatedTitle: null == relatedTitle
                ? _value.relatedTitle
                : relatedTitle // ignore: cast_nullable_to_non_nullable
                      as String,
            relatedDate: null == relatedDate
                ? _value.relatedDate
                : relatedDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            urgency: null == urgency
                ? _value.urgency
                : urgency // ignore: cast_nullable_to_non_nullable
                      as String,
            contextSnippet: null == contextSnippet
                ? _value.contextSnippet
                : contextSnippet // ignore: cast_nullable_to_non_nullable
                      as String,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FollowUpSuggestionAssistanceImplCopyWith<$Res>
    implements $FollowUpSuggestionAssistanceCopyWith<$Res> {
  factory _$$FollowUpSuggestionAssistanceImplCopyWith(
    _$FollowUpSuggestionAssistanceImpl value,
    $Res Function(_$FollowUpSuggestionAssistanceImpl) then,
  ) = __$$FollowUpSuggestionAssistanceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'insight_id') String insightId,
    String topic,
    String reason,
    @JsonKey(name: 'related_content_id') String relatedContentId,
    @JsonKey(name: 'related_title') String relatedTitle,
    @JsonKey(name: 'related_date') DateTime relatedDate,
    String urgency,
    @JsonKey(name: 'context_snippet') String contextSnippet,
    double confidence,
    DateTime timestamp,
  });
}

/// @nodoc
class __$$FollowUpSuggestionAssistanceImplCopyWithImpl<$Res>
    extends
        _$FollowUpSuggestionAssistanceCopyWithImpl<
          $Res,
          _$FollowUpSuggestionAssistanceImpl
        >
    implements _$$FollowUpSuggestionAssistanceImplCopyWith<$Res> {
  __$$FollowUpSuggestionAssistanceImplCopyWithImpl(
    _$FollowUpSuggestionAssistanceImpl _value,
    $Res Function(_$FollowUpSuggestionAssistanceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FollowUpSuggestionAssistance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? insightId = null,
    Object? topic = null,
    Object? reason = null,
    Object? relatedContentId = null,
    Object? relatedTitle = null,
    Object? relatedDate = null,
    Object? urgency = null,
    Object? contextSnippet = null,
    Object? confidence = null,
    Object? timestamp = null,
  }) {
    return _then(
      _$FollowUpSuggestionAssistanceImpl(
        insightId: null == insightId
            ? _value.insightId
            : insightId // ignore: cast_nullable_to_non_nullable
                  as String,
        topic: null == topic
            ? _value.topic
            : topic // ignore: cast_nullable_to_non_nullable
                  as String,
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String,
        relatedContentId: null == relatedContentId
            ? _value.relatedContentId
            : relatedContentId // ignore: cast_nullable_to_non_nullable
                  as String,
        relatedTitle: null == relatedTitle
            ? _value.relatedTitle
            : relatedTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        relatedDate: null == relatedDate
            ? _value.relatedDate
            : relatedDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        urgency: null == urgency
            ? _value.urgency
            : urgency // ignore: cast_nullable_to_non_nullable
                  as String,
        contextSnippet: null == contextSnippet
            ? _value.contextSnippet
            : contextSnippet // ignore: cast_nullable_to_non_nullable
                  as String,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FollowUpSuggestionAssistanceImpl
    implements _FollowUpSuggestionAssistance {
  const _$FollowUpSuggestionAssistanceImpl({
    @JsonKey(name: 'insight_id') required this.insightId,
    required this.topic,
    required this.reason,
    @JsonKey(name: 'related_content_id') required this.relatedContentId,
    @JsonKey(name: 'related_title') required this.relatedTitle,
    @JsonKey(name: 'related_date') required this.relatedDate,
    required this.urgency,
    @JsonKey(name: 'context_snippet') required this.contextSnippet,
    required this.confidence,
    required this.timestamp,
  });

  factory _$FollowUpSuggestionAssistanceImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$FollowUpSuggestionAssistanceImplFromJson(json);

  @override
  @JsonKey(name: 'insight_id')
  final String insightId;
  @override
  final String topic;
  @override
  final String reason;
  @override
  @JsonKey(name: 'related_content_id')
  final String relatedContentId;
  @override
  @JsonKey(name: 'related_title')
  final String relatedTitle;
  @override
  @JsonKey(name: 'related_date')
  final DateTime relatedDate;
  @override
  final String urgency;
  // 'high', 'medium', 'low'
  @override
  @JsonKey(name: 'context_snippet')
  final String contextSnippet;
  @override
  final double confidence;
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'FollowUpSuggestionAssistance(insightId: $insightId, topic: $topic, reason: $reason, relatedContentId: $relatedContentId, relatedTitle: $relatedTitle, relatedDate: $relatedDate, urgency: $urgency, contextSnippet: $contextSnippet, confidence: $confidence, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FollowUpSuggestionAssistanceImpl &&
            (identical(other.insightId, insightId) ||
                other.insightId == insightId) &&
            (identical(other.topic, topic) || other.topic == topic) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.relatedContentId, relatedContentId) ||
                other.relatedContentId == relatedContentId) &&
            (identical(other.relatedTitle, relatedTitle) ||
                other.relatedTitle == relatedTitle) &&
            (identical(other.relatedDate, relatedDate) ||
                other.relatedDate == relatedDate) &&
            (identical(other.urgency, urgency) || other.urgency == urgency) &&
            (identical(other.contextSnippet, contextSnippet) ||
                other.contextSnippet == contextSnippet) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    insightId,
    topic,
    reason,
    relatedContentId,
    relatedTitle,
    relatedDate,
    urgency,
    contextSnippet,
    confidence,
    timestamp,
  );

  /// Create a copy of FollowUpSuggestionAssistance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FollowUpSuggestionAssistanceImplCopyWith<
    _$FollowUpSuggestionAssistanceImpl
  >
  get copyWith =>
      __$$FollowUpSuggestionAssistanceImplCopyWithImpl<
        _$FollowUpSuggestionAssistanceImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FollowUpSuggestionAssistanceImplToJson(this);
  }
}

abstract class _FollowUpSuggestionAssistance
    implements FollowUpSuggestionAssistance {
  const factory _FollowUpSuggestionAssistance({
    @JsonKey(name: 'insight_id') required final String insightId,
    required final String topic,
    required final String reason,
    @JsonKey(name: 'related_content_id') required final String relatedContentId,
    @JsonKey(name: 'related_title') required final String relatedTitle,
    @JsonKey(name: 'related_date') required final DateTime relatedDate,
    required final String urgency,
    @JsonKey(name: 'context_snippet') required final String contextSnippet,
    required final double confidence,
    required final DateTime timestamp,
  }) = _$FollowUpSuggestionAssistanceImpl;

  factory _FollowUpSuggestionAssistance.fromJson(Map<String, dynamic> json) =
      _$FollowUpSuggestionAssistanceImpl.fromJson;

  @override
  @JsonKey(name: 'insight_id')
  String get insightId;
  @override
  String get topic;
  @override
  String get reason;
  @override
  @JsonKey(name: 'related_content_id')
  String get relatedContentId;
  @override
  @JsonKey(name: 'related_title')
  String get relatedTitle;
  @override
  @JsonKey(name: 'related_date')
  DateTime get relatedDate;
  @override
  String get urgency; // 'high', 'medium', 'low'
  @override
  @JsonKey(name: 'context_snippet')
  String get contextSnippet;
  @override
  double get confidence;
  @override
  DateTime get timestamp;

  /// Create a copy of FollowUpSuggestionAssistance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FollowUpSuggestionAssistanceImplCopyWith<
    _$FollowUpSuggestionAssistanceImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ProactiveAssistanceModel {
  ProactiveAssistanceType get type => throw _privateConstructorUsedError;
  AutoAnswerAssistance? get autoAnswer => throw _privateConstructorUsedError;
  ClarificationAssistance? get clarification =>
      throw _privateConstructorUsedError;
  ConflictAssistance? get conflict => throw _privateConstructorUsedError;
  ActionItemQualityAssistance? get actionItemQuality =>
      throw _privateConstructorUsedError;
  FollowUpSuggestionAssistance? get followUpSuggestion =>
      throw _privateConstructorUsedError;

  /// Create a copy of ProactiveAssistanceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProactiveAssistanceModelCopyWith<ProactiveAssistanceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProactiveAssistanceModelCopyWith<$Res> {
  factory $ProactiveAssistanceModelCopyWith(
    ProactiveAssistanceModel value,
    $Res Function(ProactiveAssistanceModel) then,
  ) = _$ProactiveAssistanceModelCopyWithImpl<$Res, ProactiveAssistanceModel>;
  @useResult
  $Res call({
    ProactiveAssistanceType type,
    AutoAnswerAssistance? autoAnswer,
    ClarificationAssistance? clarification,
    ConflictAssistance? conflict,
    ActionItemQualityAssistance? actionItemQuality,
    FollowUpSuggestionAssistance? followUpSuggestion,
  });

  $AutoAnswerAssistanceCopyWith<$Res>? get autoAnswer;
  $ClarificationAssistanceCopyWith<$Res>? get clarification;
  $ConflictAssistanceCopyWith<$Res>? get conflict;
  $ActionItemQualityAssistanceCopyWith<$Res>? get actionItemQuality;
  $FollowUpSuggestionAssistanceCopyWith<$Res>? get followUpSuggestion;
}

/// @nodoc
class _$ProactiveAssistanceModelCopyWithImpl<
  $Res,
  $Val extends ProactiveAssistanceModel
>
    implements $ProactiveAssistanceModelCopyWith<$Res> {
  _$ProactiveAssistanceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProactiveAssistanceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? autoAnswer = freezed,
    Object? clarification = freezed,
    Object? conflict = freezed,
    Object? actionItemQuality = freezed,
    Object? followUpSuggestion = freezed,
  }) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as ProactiveAssistanceType,
            autoAnswer: freezed == autoAnswer
                ? _value.autoAnswer
                : autoAnswer // ignore: cast_nullable_to_non_nullable
                      as AutoAnswerAssistance?,
            clarification: freezed == clarification
                ? _value.clarification
                : clarification // ignore: cast_nullable_to_non_nullable
                      as ClarificationAssistance?,
            conflict: freezed == conflict
                ? _value.conflict
                : conflict // ignore: cast_nullable_to_non_nullable
                      as ConflictAssistance?,
            actionItemQuality: freezed == actionItemQuality
                ? _value.actionItemQuality
                : actionItemQuality // ignore: cast_nullable_to_non_nullable
                      as ActionItemQualityAssistance?,
            followUpSuggestion: freezed == followUpSuggestion
                ? _value.followUpSuggestion
                : followUpSuggestion // ignore: cast_nullable_to_non_nullable
                      as FollowUpSuggestionAssistance?,
          )
          as $Val,
    );
  }

  /// Create a copy of ProactiveAssistanceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AutoAnswerAssistanceCopyWith<$Res>? get autoAnswer {
    if (_value.autoAnswer == null) {
      return null;
    }

    return $AutoAnswerAssistanceCopyWith<$Res>(_value.autoAnswer!, (value) {
      return _then(_value.copyWith(autoAnswer: value) as $Val);
    });
  }

  /// Create a copy of ProactiveAssistanceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ClarificationAssistanceCopyWith<$Res>? get clarification {
    if (_value.clarification == null) {
      return null;
    }

    return $ClarificationAssistanceCopyWith<$Res>(_value.clarification!, (
      value,
    ) {
      return _then(_value.copyWith(clarification: value) as $Val);
    });
  }

  /// Create a copy of ProactiveAssistanceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ConflictAssistanceCopyWith<$Res>? get conflict {
    if (_value.conflict == null) {
      return null;
    }

    return $ConflictAssistanceCopyWith<$Res>(_value.conflict!, (value) {
      return _then(_value.copyWith(conflict: value) as $Val);
    });
  }

  /// Create a copy of ProactiveAssistanceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ActionItemQualityAssistanceCopyWith<$Res>? get actionItemQuality {
    if (_value.actionItemQuality == null) {
      return null;
    }

    return $ActionItemQualityAssistanceCopyWith<$Res>(
      _value.actionItemQuality!,
      (value) {
        return _then(_value.copyWith(actionItemQuality: value) as $Val);
      },
    );
  }

  /// Create a copy of ProactiveAssistanceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FollowUpSuggestionAssistanceCopyWith<$Res>? get followUpSuggestion {
    if (_value.followUpSuggestion == null) {
      return null;
    }

    return $FollowUpSuggestionAssistanceCopyWith<$Res>(
      _value.followUpSuggestion!,
      (value) {
        return _then(_value.copyWith(followUpSuggestion: value) as $Val);
      },
    );
  }
}

/// @nodoc
abstract class _$$ProactiveAssistanceModelImplCopyWith<$Res>
    implements $ProactiveAssistanceModelCopyWith<$Res> {
  factory _$$ProactiveAssistanceModelImplCopyWith(
    _$ProactiveAssistanceModelImpl value,
    $Res Function(_$ProactiveAssistanceModelImpl) then,
  ) = __$$ProactiveAssistanceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    ProactiveAssistanceType type,
    AutoAnswerAssistance? autoAnswer,
    ClarificationAssistance? clarification,
    ConflictAssistance? conflict,
    ActionItemQualityAssistance? actionItemQuality,
    FollowUpSuggestionAssistance? followUpSuggestion,
  });

  @override
  $AutoAnswerAssistanceCopyWith<$Res>? get autoAnswer;
  @override
  $ClarificationAssistanceCopyWith<$Res>? get clarification;
  @override
  $ConflictAssistanceCopyWith<$Res>? get conflict;
  @override
  $ActionItemQualityAssistanceCopyWith<$Res>? get actionItemQuality;
  @override
  $FollowUpSuggestionAssistanceCopyWith<$Res>? get followUpSuggestion;
}

/// @nodoc
class __$$ProactiveAssistanceModelImplCopyWithImpl<$Res>
    extends
        _$ProactiveAssistanceModelCopyWithImpl<
          $Res,
          _$ProactiveAssistanceModelImpl
        >
    implements _$$ProactiveAssistanceModelImplCopyWith<$Res> {
  __$$ProactiveAssistanceModelImplCopyWithImpl(
    _$ProactiveAssistanceModelImpl _value,
    $Res Function(_$ProactiveAssistanceModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProactiveAssistanceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? autoAnswer = freezed,
    Object? clarification = freezed,
    Object? conflict = freezed,
    Object? actionItemQuality = freezed,
    Object? followUpSuggestion = freezed,
  }) {
    return _then(
      _$ProactiveAssistanceModelImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as ProactiveAssistanceType,
        autoAnswer: freezed == autoAnswer
            ? _value.autoAnswer
            : autoAnswer // ignore: cast_nullable_to_non_nullable
                  as AutoAnswerAssistance?,
        clarification: freezed == clarification
            ? _value.clarification
            : clarification // ignore: cast_nullable_to_non_nullable
                  as ClarificationAssistance?,
        conflict: freezed == conflict
            ? _value.conflict
            : conflict // ignore: cast_nullable_to_non_nullable
                  as ConflictAssistance?,
        actionItemQuality: freezed == actionItemQuality
            ? _value.actionItemQuality
            : actionItemQuality // ignore: cast_nullable_to_non_nullable
                  as ActionItemQualityAssistance?,
        followUpSuggestion: freezed == followUpSuggestion
            ? _value.followUpSuggestion
            : followUpSuggestion // ignore: cast_nullable_to_non_nullable
                  as FollowUpSuggestionAssistance?,
      ),
    );
  }
}

/// @nodoc

class _$ProactiveAssistanceModelImpl extends _ProactiveAssistanceModel {
  const _$ProactiveAssistanceModelImpl({
    required this.type,
    this.autoAnswer,
    this.clarification,
    this.conflict,
    this.actionItemQuality,
    this.followUpSuggestion,
  }) : super._();

  @override
  final ProactiveAssistanceType type;
  @override
  final AutoAnswerAssistance? autoAnswer;
  @override
  final ClarificationAssistance? clarification;
  @override
  final ConflictAssistance? conflict;
  @override
  final ActionItemQualityAssistance? actionItemQuality;
  @override
  final FollowUpSuggestionAssistance? followUpSuggestion;

  @override
  String toString() {
    return 'ProactiveAssistanceModel(type: $type, autoAnswer: $autoAnswer, clarification: $clarification, conflict: $conflict, actionItemQuality: $actionItemQuality, followUpSuggestion: $followUpSuggestion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProactiveAssistanceModelImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.autoAnswer, autoAnswer) ||
                other.autoAnswer == autoAnswer) &&
            (identical(other.clarification, clarification) ||
                other.clarification == clarification) &&
            (identical(other.conflict, conflict) ||
                other.conflict == conflict) &&
            (identical(other.actionItemQuality, actionItemQuality) ||
                other.actionItemQuality == actionItemQuality) &&
            (identical(other.followUpSuggestion, followUpSuggestion) ||
                other.followUpSuggestion == followUpSuggestion));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    type,
    autoAnswer,
    clarification,
    conflict,
    actionItemQuality,
    followUpSuggestion,
  );

  /// Create a copy of ProactiveAssistanceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProactiveAssistanceModelImplCopyWith<_$ProactiveAssistanceModelImpl>
  get copyWith =>
      __$$ProactiveAssistanceModelImplCopyWithImpl<
        _$ProactiveAssistanceModelImpl
      >(this, _$identity);
}

abstract class _ProactiveAssistanceModel extends ProactiveAssistanceModel {
  const factory _ProactiveAssistanceModel({
    required final ProactiveAssistanceType type,
    final AutoAnswerAssistance? autoAnswer,
    final ClarificationAssistance? clarification,
    final ConflictAssistance? conflict,
    final ActionItemQualityAssistance? actionItemQuality,
    final FollowUpSuggestionAssistance? followUpSuggestion,
  }) = _$ProactiveAssistanceModelImpl;
  const _ProactiveAssistanceModel._() : super._();

  @override
  ProactiveAssistanceType get type;
  @override
  AutoAnswerAssistance? get autoAnswer;
  @override
  ClarificationAssistance? get clarification;
  @override
  ConflictAssistance? get conflict;
  @override
  ActionItemQualityAssistance? get actionItemQuality;
  @override
  FollowUpSuggestionAssistance? get followUpSuggestion;

  /// Create a copy of ProactiveAssistanceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProactiveAssistanceModelImplCopyWith<_$ProactiveAssistanceModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
