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
  String get contentId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get snippet => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  double get relevanceScore => throw _privateConstructorUsedError;
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
    String contentId,
    String title,
    String snippet,
    DateTime date,
    double relevanceScore,
    String meetingType,
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
    String contentId,
    String title,
    String snippet,
    DateTime date,
    double relevanceScore,
    String meetingType,
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
    required this.contentId,
    required this.title,
    required this.snippet,
    required this.date,
    required this.relevanceScore,
    required this.meetingType,
  });

  factory _$AnswerSourceImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnswerSourceImplFromJson(json);

  @override
  final String contentId;
  @override
  final String title;
  @override
  final String snippet;
  @override
  final DateTime date;
  @override
  final double relevanceScore;
  @override
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
    required final String contentId,
    required final String title,
    required final String snippet,
    required final DateTime date,
    required final double relevanceScore,
    required final String meetingType,
  }) = _$AnswerSourceImpl;

  factory _AnswerSource.fromJson(Map<String, dynamic> json) =
      _$AnswerSourceImpl.fromJson;

  @override
  String get contentId;
  @override
  String get title;
  @override
  String get snippet;
  @override
  DateTime get date;
  @override
  double get relevanceScore;
  @override
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

/// @nodoc
mixin _$ProactiveAssistanceModel {
  ProactiveAssistanceType get type => throw _privateConstructorUsedError;
  AutoAnswerAssistance? get autoAnswer => throw _privateConstructorUsedError;
  ClarificationAssistance? get clarification =>
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
  });

  $AutoAnswerAssistanceCopyWith<$Res>? get autoAnswer;
  $ClarificationAssistanceCopyWith<$Res>? get clarification;
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
  });

  @override
  $AutoAnswerAssistanceCopyWith<$Res>? get autoAnswer;
  @override
  $ClarificationAssistanceCopyWith<$Res>? get clarification;
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
      ),
    );
  }
}

/// @nodoc

class _$ProactiveAssistanceModelImpl implements _ProactiveAssistanceModel {
  const _$ProactiveAssistanceModelImpl({
    required this.type,
    this.autoAnswer,
    this.clarification,
  });

  @override
  final ProactiveAssistanceType type;
  @override
  final AutoAnswerAssistance? autoAnswer;
  @override
  final ClarificationAssistance? clarification;

  @override
  String toString() {
    return 'ProactiveAssistanceModel(type: $type, autoAnswer: $autoAnswer, clarification: $clarification)';
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
                other.clarification == clarification));
  }

  @override
  int get hashCode => Object.hash(runtimeType, type, autoAnswer, clarification);

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

abstract class _ProactiveAssistanceModel implements ProactiveAssistanceModel {
  const factory _ProactiveAssistanceModel({
    required final ProactiveAssistanceType type,
    final AutoAnswerAssistance? autoAnswer,
    final ClarificationAssistance? clarification,
  }) = _$ProactiveAssistanceModelImpl;

  @override
  ProactiveAssistanceType get type;
  @override
  AutoAnswerAssistance? get autoAnswer;
  @override
  ClarificationAssistance? get clarification;

  /// Create a copy of ProactiveAssistanceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProactiveAssistanceModelImplCopyWith<_$ProactiveAssistanceModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
