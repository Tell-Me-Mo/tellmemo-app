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

LiveInsightModel _$LiveInsightModelFromJson(Map<String, dynamic> json) {
  return _LiveInsightModel.fromJson(json);
}

/// @nodoc
mixin _$LiveInsightModel {
  String get insightId => throw _privateConstructorUsedError;
  LiveInsightType get type => throw _privateConstructorUsedError;
  LiveInsightPriority get priority => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  String get context => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  String? get assignedTo => throw _privateConstructorUsedError;
  String? get dueDate => throw _privateConstructorUsedError;
  double get confidenceScore => throw _privateConstructorUsedError;
  int? get sourceChunkIndex => throw _privateConstructorUsedError;
  List<String>? get relatedContentIds => throw _privateConstructorUsedError;
  List<double>? get similarityScores => throw _privateConstructorUsedError;
  String? get contradictsContentId => throw _privateConstructorUsedError;
  String? get contradictionExplanation => throw _privateConstructorUsedError;

  /// Serializes this LiveInsightModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LiveInsightModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LiveInsightModelCopyWith<LiveInsightModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LiveInsightModelCopyWith<$Res> {
  factory $LiveInsightModelCopyWith(
    LiveInsightModel value,
    $Res Function(LiveInsightModel) then,
  ) = _$LiveInsightModelCopyWithImpl<$Res, LiveInsightModel>;
  @useResult
  $Res call({
    String insightId,
    LiveInsightType type,
    LiveInsightPriority priority,
    String content,
    String context,
    DateTime timestamp,
    String? assignedTo,
    String? dueDate,
    double confidenceScore,
    int? sourceChunkIndex,
    List<String>? relatedContentIds,
    List<double>? similarityScores,
    String? contradictsContentId,
    String? contradictionExplanation,
  });
}

/// @nodoc
class _$LiveInsightModelCopyWithImpl<$Res, $Val extends LiveInsightModel>
    implements $LiveInsightModelCopyWith<$Res> {
  _$LiveInsightModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LiveInsightModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? insightId = null,
    Object? type = null,
    Object? priority = null,
    Object? content = null,
    Object? context = null,
    Object? timestamp = null,
    Object? assignedTo = freezed,
    Object? dueDate = freezed,
    Object? confidenceScore = null,
    Object? sourceChunkIndex = freezed,
    Object? relatedContentIds = freezed,
    Object? similarityScores = freezed,
    Object? contradictsContentId = freezed,
    Object? contradictionExplanation = freezed,
  }) {
    return _then(
      _value.copyWith(
            insightId: null == insightId
                ? _value.insightId
                : insightId // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as LiveInsightType,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as LiveInsightPriority,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            context: null == context
                ? _value.context
                : context // ignore: cast_nullable_to_non_nullable
                      as String,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            assignedTo: freezed == assignedTo
                ? _value.assignedTo
                : assignedTo // ignore: cast_nullable_to_non_nullable
                      as String?,
            dueDate: freezed == dueDate
                ? _value.dueDate
                : dueDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            confidenceScore: null == confidenceScore
                ? _value.confidenceScore
                : confidenceScore // ignore: cast_nullable_to_non_nullable
                      as double,
            sourceChunkIndex: freezed == sourceChunkIndex
                ? _value.sourceChunkIndex
                : sourceChunkIndex // ignore: cast_nullable_to_non_nullable
                      as int?,
            relatedContentIds: freezed == relatedContentIds
                ? _value.relatedContentIds
                : relatedContentIds // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            similarityScores: freezed == similarityScores
                ? _value.similarityScores
                : similarityScores // ignore: cast_nullable_to_non_nullable
                      as List<double>?,
            contradictsContentId: freezed == contradictsContentId
                ? _value.contradictsContentId
                : contradictsContentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            contradictionExplanation: freezed == contradictionExplanation
                ? _value.contradictionExplanation
                : contradictionExplanation // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LiveInsightModelImplCopyWith<$Res>
    implements $LiveInsightModelCopyWith<$Res> {
  factory _$$LiveInsightModelImplCopyWith(
    _$LiveInsightModelImpl value,
    $Res Function(_$LiveInsightModelImpl) then,
  ) = __$$LiveInsightModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String insightId,
    LiveInsightType type,
    LiveInsightPriority priority,
    String content,
    String context,
    DateTime timestamp,
    String? assignedTo,
    String? dueDate,
    double confidenceScore,
    int? sourceChunkIndex,
    List<String>? relatedContentIds,
    List<double>? similarityScores,
    String? contradictsContentId,
    String? contradictionExplanation,
  });
}

/// @nodoc
class __$$LiveInsightModelImplCopyWithImpl<$Res>
    extends _$LiveInsightModelCopyWithImpl<$Res, _$LiveInsightModelImpl>
    implements _$$LiveInsightModelImplCopyWith<$Res> {
  __$$LiveInsightModelImplCopyWithImpl(
    _$LiveInsightModelImpl _value,
    $Res Function(_$LiveInsightModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LiveInsightModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? insightId = null,
    Object? type = null,
    Object? priority = null,
    Object? content = null,
    Object? context = null,
    Object? timestamp = null,
    Object? assignedTo = freezed,
    Object? dueDate = freezed,
    Object? confidenceScore = null,
    Object? sourceChunkIndex = freezed,
    Object? relatedContentIds = freezed,
    Object? similarityScores = freezed,
    Object? contradictsContentId = freezed,
    Object? contradictionExplanation = freezed,
  }) {
    return _then(
      _$LiveInsightModelImpl(
        insightId: null == insightId
            ? _value.insightId
            : insightId // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as LiveInsightType,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as LiveInsightPriority,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        context: null == context
            ? _value.context
            : context // ignore: cast_nullable_to_non_nullable
                  as String,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        assignedTo: freezed == assignedTo
            ? _value.assignedTo
            : assignedTo // ignore: cast_nullable_to_non_nullable
                  as String?,
        dueDate: freezed == dueDate
            ? _value.dueDate
            : dueDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        confidenceScore: null == confidenceScore
            ? _value.confidenceScore
            : confidenceScore // ignore: cast_nullable_to_non_nullable
                  as double,
        sourceChunkIndex: freezed == sourceChunkIndex
            ? _value.sourceChunkIndex
            : sourceChunkIndex // ignore: cast_nullable_to_non_nullable
                  as int?,
        relatedContentIds: freezed == relatedContentIds
            ? _value._relatedContentIds
            : relatedContentIds // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        similarityScores: freezed == similarityScores
            ? _value._similarityScores
            : similarityScores // ignore: cast_nullable_to_non_nullable
                  as List<double>?,
        contradictsContentId: freezed == contradictsContentId
            ? _value.contradictsContentId
            : contradictsContentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        contradictionExplanation: freezed == contradictionExplanation
            ? _value.contradictionExplanation
            : contradictionExplanation // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LiveInsightModelImpl implements _LiveInsightModel {
  const _$LiveInsightModelImpl({
    required this.insightId,
    required this.type,
    required this.priority,
    required this.content,
    required this.context,
    required this.timestamp,
    this.assignedTo,
    this.dueDate,
    this.confidenceScore = 0.0,
    this.sourceChunkIndex,
    final List<String>? relatedContentIds,
    final List<double>? similarityScores,
    this.contradictsContentId,
    this.contradictionExplanation,
  }) : _relatedContentIds = relatedContentIds,
       _similarityScores = similarityScores;

  factory _$LiveInsightModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LiveInsightModelImplFromJson(json);

  @override
  final String insightId;
  @override
  final LiveInsightType type;
  @override
  final LiveInsightPriority priority;
  @override
  final String content;
  @override
  final String context;
  @override
  final DateTime timestamp;
  @override
  final String? assignedTo;
  @override
  final String? dueDate;
  @override
  @JsonKey()
  final double confidenceScore;
  @override
  final int? sourceChunkIndex;
  final List<String>? _relatedContentIds;
  @override
  List<String>? get relatedContentIds {
    final value = _relatedContentIds;
    if (value == null) return null;
    if (_relatedContentIds is EqualUnmodifiableListView)
      return _relatedContentIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<double>? _similarityScores;
  @override
  List<double>? get similarityScores {
    final value = _similarityScores;
    if (value == null) return null;
    if (_similarityScores is EqualUnmodifiableListView)
      return _similarityScores;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? contradictsContentId;
  @override
  final String? contradictionExplanation;

  @override
  String toString() {
    return 'LiveInsightModel(insightId: $insightId, type: $type, priority: $priority, content: $content, context: $context, timestamp: $timestamp, assignedTo: $assignedTo, dueDate: $dueDate, confidenceScore: $confidenceScore, sourceChunkIndex: $sourceChunkIndex, relatedContentIds: $relatedContentIds, similarityScores: $similarityScores, contradictsContentId: $contradictsContentId, contradictionExplanation: $contradictionExplanation)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LiveInsightModelImpl &&
            (identical(other.insightId, insightId) ||
                other.insightId == insightId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.context, context) || other.context == context) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.assignedTo, assignedTo) ||
                other.assignedTo == assignedTo) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.confidenceScore, confidenceScore) ||
                other.confidenceScore == confidenceScore) &&
            (identical(other.sourceChunkIndex, sourceChunkIndex) ||
                other.sourceChunkIndex == sourceChunkIndex) &&
            const DeepCollectionEquality().equals(
              other._relatedContentIds,
              _relatedContentIds,
            ) &&
            const DeepCollectionEquality().equals(
              other._similarityScores,
              _similarityScores,
            ) &&
            (identical(other.contradictsContentId, contradictsContentId) ||
                other.contradictsContentId == contradictsContentId) &&
            (identical(
                  other.contradictionExplanation,
                  contradictionExplanation,
                ) ||
                other.contradictionExplanation == contradictionExplanation));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    insightId,
    type,
    priority,
    content,
    context,
    timestamp,
    assignedTo,
    dueDate,
    confidenceScore,
    sourceChunkIndex,
    const DeepCollectionEquality().hash(_relatedContentIds),
    const DeepCollectionEquality().hash(_similarityScores),
    contradictsContentId,
    contradictionExplanation,
  );

  /// Create a copy of LiveInsightModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LiveInsightModelImplCopyWith<_$LiveInsightModelImpl> get copyWith =>
      __$$LiveInsightModelImplCopyWithImpl<_$LiveInsightModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$LiveInsightModelImplToJson(this);
  }
}

abstract class _LiveInsightModel implements LiveInsightModel {
  const factory _LiveInsightModel({
    required final String insightId,
    required final LiveInsightType type,
    required final LiveInsightPriority priority,
    required final String content,
    required final String context,
    required final DateTime timestamp,
    final String? assignedTo,
    final String? dueDate,
    final double confidenceScore,
    final int? sourceChunkIndex,
    final List<String>? relatedContentIds,
    final List<double>? similarityScores,
    final String? contradictsContentId,
    final String? contradictionExplanation,
  }) = _$LiveInsightModelImpl;

  factory _LiveInsightModel.fromJson(Map<String, dynamic> json) =
      _$LiveInsightModelImpl.fromJson;

  @override
  String get insightId;
  @override
  LiveInsightType get type;
  @override
  LiveInsightPriority get priority;
  @override
  String get content;
  @override
  String get context;
  @override
  DateTime get timestamp;
  @override
  String? get assignedTo;
  @override
  String? get dueDate;
  @override
  double get confidenceScore;
  @override
  int? get sourceChunkIndex;
  @override
  List<String>? get relatedContentIds;
  @override
  List<double>? get similarityScores;
  @override
  String? get contradictsContentId;
  @override
  String? get contradictionExplanation;

  /// Create a copy of LiveInsightModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LiveInsightModelImplCopyWith<_$LiveInsightModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$LiveInsightMessage {
  LiveInsightMessageType get type => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  String? get sessionId => throw _privateConstructorUsedError;
  String? get projectId => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;
  Map<String, dynamic>? get data => throw _privateConstructorUsedError;

  /// Create a copy of LiveInsightMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LiveInsightMessageCopyWith<LiveInsightMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LiveInsightMessageCopyWith<$Res> {
  factory $LiveInsightMessageCopyWith(
    LiveInsightMessage value,
    $Res Function(LiveInsightMessage) then,
  ) = _$LiveInsightMessageCopyWithImpl<$Res, LiveInsightMessage>;
  @useResult
  $Res call({
    LiveInsightMessageType type,
    DateTime timestamp,
    String? sessionId,
    String? projectId,
    String? message,
    Map<String, dynamic>? data,
  });
}

/// @nodoc
class _$LiveInsightMessageCopyWithImpl<$Res, $Val extends LiveInsightMessage>
    implements $LiveInsightMessageCopyWith<$Res> {
  _$LiveInsightMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LiveInsightMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? timestamp = null,
    Object? sessionId = freezed,
    Object? projectId = freezed,
    Object? message = freezed,
    Object? data = freezed,
  }) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as LiveInsightMessageType,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            sessionId: freezed == sessionId
                ? _value.sessionId
                : sessionId // ignore: cast_nullable_to_non_nullable
                      as String?,
            projectId: freezed == projectId
                ? _value.projectId
                : projectId // ignore: cast_nullable_to_non_nullable
                      as String?,
            message: freezed == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String?,
            data: freezed == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LiveInsightMessageImplCopyWith<$Res>
    implements $LiveInsightMessageCopyWith<$Res> {
  factory _$$LiveInsightMessageImplCopyWith(
    _$LiveInsightMessageImpl value,
    $Res Function(_$LiveInsightMessageImpl) then,
  ) = __$$LiveInsightMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    LiveInsightMessageType type,
    DateTime timestamp,
    String? sessionId,
    String? projectId,
    String? message,
    Map<String, dynamic>? data,
  });
}

/// @nodoc
class __$$LiveInsightMessageImplCopyWithImpl<$Res>
    extends _$LiveInsightMessageCopyWithImpl<$Res, _$LiveInsightMessageImpl>
    implements _$$LiveInsightMessageImplCopyWith<$Res> {
  __$$LiveInsightMessageImplCopyWithImpl(
    _$LiveInsightMessageImpl _value,
    $Res Function(_$LiveInsightMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LiveInsightMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? timestamp = null,
    Object? sessionId = freezed,
    Object? projectId = freezed,
    Object? message = freezed,
    Object? data = freezed,
  }) {
    return _then(
      _$LiveInsightMessageImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as LiveInsightMessageType,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        sessionId: freezed == sessionId
            ? _value.sessionId
            : sessionId // ignore: cast_nullable_to_non_nullable
                  as String?,
        projectId: freezed == projectId
            ? _value.projectId
            : projectId // ignore: cast_nullable_to_non_nullable
                  as String?,
        message: freezed == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
        data: freezed == data
            ? _value._data
            : data // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc

class _$LiveInsightMessageImpl implements _LiveInsightMessage {
  const _$LiveInsightMessageImpl({
    required this.type,
    required this.timestamp,
    this.sessionId,
    this.projectId,
    this.message,
    final Map<String, dynamic>? data,
  }) : _data = data;

  @override
  final LiveInsightMessageType type;
  @override
  final DateTime timestamp;
  @override
  final String? sessionId;
  @override
  final String? projectId;
  @override
  final String? message;
  final Map<String, dynamic>? _data;
  @override
  Map<String, dynamic>? get data {
    final value = _data;
    if (value == null) return null;
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'LiveInsightMessage(type: $type, timestamp: $timestamp, sessionId: $sessionId, projectId: $projectId, message: $message, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LiveInsightMessageImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(other._data, _data));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    type,
    timestamp,
    sessionId,
    projectId,
    message,
    const DeepCollectionEquality().hash(_data),
  );

  /// Create a copy of LiveInsightMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LiveInsightMessageImplCopyWith<_$LiveInsightMessageImpl> get copyWith =>
      __$$LiveInsightMessageImplCopyWithImpl<_$LiveInsightMessageImpl>(
        this,
        _$identity,
      );
}

abstract class _LiveInsightMessage implements LiveInsightMessage {
  const factory _LiveInsightMessage({
    required final LiveInsightMessageType type,
    required final DateTime timestamp,
    final String? sessionId,
    final String? projectId,
    final String? message,
    final Map<String, dynamic>? data,
  }) = _$LiveInsightMessageImpl;

  @override
  LiveInsightMessageType get type;
  @override
  DateTime get timestamp;
  @override
  String? get sessionId;
  @override
  String? get projectId;
  @override
  String? get message;
  @override
  Map<String, dynamic>? get data;

  /// Create a copy of LiveInsightMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LiveInsightMessageImplCopyWith<_$LiveInsightMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TranscriptChunk _$TranscriptChunkFromJson(Map<String, dynamic> json) {
  return _TranscriptChunk.fromJson(json);
}

/// @nodoc
mixin _$TranscriptChunk {
  int get chunkIndex => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  String? get speaker => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Serializes this TranscriptChunk to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TranscriptChunk
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TranscriptChunkCopyWith<TranscriptChunk> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TranscriptChunkCopyWith<$Res> {
  factory $TranscriptChunkCopyWith(
    TranscriptChunk value,
    $Res Function(TranscriptChunk) then,
  ) = _$TranscriptChunkCopyWithImpl<$Res, TranscriptChunk>;
  @useResult
  $Res call({int chunkIndex, String text, String? speaker, DateTime timestamp});
}

/// @nodoc
class _$TranscriptChunkCopyWithImpl<$Res, $Val extends TranscriptChunk>
    implements $TranscriptChunkCopyWith<$Res> {
  _$TranscriptChunkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TranscriptChunk
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chunkIndex = null,
    Object? text = null,
    Object? speaker = freezed,
    Object? timestamp = null,
  }) {
    return _then(
      _value.copyWith(
            chunkIndex: null == chunkIndex
                ? _value.chunkIndex
                : chunkIndex // ignore: cast_nullable_to_non_nullable
                      as int,
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TranscriptChunkImplCopyWith<$Res>
    implements $TranscriptChunkCopyWith<$Res> {
  factory _$$TranscriptChunkImplCopyWith(
    _$TranscriptChunkImpl value,
    $Res Function(_$TranscriptChunkImpl) then,
  ) = __$$TranscriptChunkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int chunkIndex, String text, String? speaker, DateTime timestamp});
}

/// @nodoc
class __$$TranscriptChunkImplCopyWithImpl<$Res>
    extends _$TranscriptChunkCopyWithImpl<$Res, _$TranscriptChunkImpl>
    implements _$$TranscriptChunkImplCopyWith<$Res> {
  __$$TranscriptChunkImplCopyWithImpl(
    _$TranscriptChunkImpl _value,
    $Res Function(_$TranscriptChunkImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TranscriptChunk
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chunkIndex = null,
    Object? text = null,
    Object? speaker = freezed,
    Object? timestamp = null,
  }) {
    return _then(
      _$TranscriptChunkImpl(
        chunkIndex: null == chunkIndex
            ? _value.chunkIndex
            : chunkIndex // ignore: cast_nullable_to_non_nullable
                  as int,
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
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TranscriptChunkImpl implements _TranscriptChunk {
  const _$TranscriptChunkImpl({
    required this.chunkIndex,
    required this.text,
    this.speaker,
    required this.timestamp,
  });

  factory _$TranscriptChunkImpl.fromJson(Map<String, dynamic> json) =>
      _$$TranscriptChunkImplFromJson(json);

  @override
  final int chunkIndex;
  @override
  final String text;
  @override
  final String? speaker;
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'TranscriptChunk(chunkIndex: $chunkIndex, text: $text, speaker: $speaker, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TranscriptChunkImpl &&
            (identical(other.chunkIndex, chunkIndex) ||
                other.chunkIndex == chunkIndex) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.speaker, speaker) || other.speaker == speaker) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, chunkIndex, text, speaker, timestamp);

  /// Create a copy of TranscriptChunk
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TranscriptChunkImplCopyWith<_$TranscriptChunkImpl> get copyWith =>
      __$$TranscriptChunkImplCopyWithImpl<_$TranscriptChunkImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TranscriptChunkImplToJson(this);
  }
}

abstract class _TranscriptChunk implements TranscriptChunk {
  const factory _TranscriptChunk({
    required final int chunkIndex,
    required final String text,
    final String? speaker,
    required final DateTime timestamp,
  }) = _$TranscriptChunkImpl;

  factory _TranscriptChunk.fromJson(Map<String, dynamic> json) =
      _$TranscriptChunkImpl.fromJson;

  @override
  int get chunkIndex;
  @override
  String get text;
  @override
  String? get speaker;
  @override
  DateTime get timestamp;

  /// Create a copy of TranscriptChunk
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TranscriptChunkImplCopyWith<_$TranscriptChunkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$InsightsExtractionResult {
  int get chunkIndex => throw _privateConstructorUsedError;
  List<LiveInsightModel> get insights => throw _privateConstructorUsedError;
  int get totalInsights => throw _privateConstructorUsedError;
  int get processingTimeMs => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Create a copy of InsightsExtractionResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InsightsExtractionResultCopyWith<InsightsExtractionResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InsightsExtractionResultCopyWith<$Res> {
  factory $InsightsExtractionResultCopyWith(
    InsightsExtractionResult value,
    $Res Function(InsightsExtractionResult) then,
  ) = _$InsightsExtractionResultCopyWithImpl<$Res, InsightsExtractionResult>;
  @useResult
  $Res call({
    int chunkIndex,
    List<LiveInsightModel> insights,
    int totalInsights,
    int processingTimeMs,
    DateTime timestamp,
  });
}

/// @nodoc
class _$InsightsExtractionResultCopyWithImpl<
  $Res,
  $Val extends InsightsExtractionResult
>
    implements $InsightsExtractionResultCopyWith<$Res> {
  _$InsightsExtractionResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InsightsExtractionResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chunkIndex = null,
    Object? insights = null,
    Object? totalInsights = null,
    Object? processingTimeMs = null,
    Object? timestamp = null,
  }) {
    return _then(
      _value.copyWith(
            chunkIndex: null == chunkIndex
                ? _value.chunkIndex
                : chunkIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            insights: null == insights
                ? _value.insights
                : insights // ignore: cast_nullable_to_non_nullable
                      as List<LiveInsightModel>,
            totalInsights: null == totalInsights
                ? _value.totalInsights
                : totalInsights // ignore: cast_nullable_to_non_nullable
                      as int,
            processingTimeMs: null == processingTimeMs
                ? _value.processingTimeMs
                : processingTimeMs // ignore: cast_nullable_to_non_nullable
                      as int,
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
abstract class _$$InsightsExtractionResultImplCopyWith<$Res>
    implements $InsightsExtractionResultCopyWith<$Res> {
  factory _$$InsightsExtractionResultImplCopyWith(
    _$InsightsExtractionResultImpl value,
    $Res Function(_$InsightsExtractionResultImpl) then,
  ) = __$$InsightsExtractionResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int chunkIndex,
    List<LiveInsightModel> insights,
    int totalInsights,
    int processingTimeMs,
    DateTime timestamp,
  });
}

/// @nodoc
class __$$InsightsExtractionResultImplCopyWithImpl<$Res>
    extends
        _$InsightsExtractionResultCopyWithImpl<
          $Res,
          _$InsightsExtractionResultImpl
        >
    implements _$$InsightsExtractionResultImplCopyWith<$Res> {
  __$$InsightsExtractionResultImplCopyWithImpl(
    _$InsightsExtractionResultImpl _value,
    $Res Function(_$InsightsExtractionResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InsightsExtractionResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chunkIndex = null,
    Object? insights = null,
    Object? totalInsights = null,
    Object? processingTimeMs = null,
    Object? timestamp = null,
  }) {
    return _then(
      _$InsightsExtractionResultImpl(
        chunkIndex: null == chunkIndex
            ? _value.chunkIndex
            : chunkIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        insights: null == insights
            ? _value._insights
            : insights // ignore: cast_nullable_to_non_nullable
                  as List<LiveInsightModel>,
        totalInsights: null == totalInsights
            ? _value.totalInsights
            : totalInsights // ignore: cast_nullable_to_non_nullable
                  as int,
        processingTimeMs: null == processingTimeMs
            ? _value.processingTimeMs
            : processingTimeMs // ignore: cast_nullable_to_non_nullable
                  as int,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$InsightsExtractionResultImpl implements _InsightsExtractionResult {
  const _$InsightsExtractionResultImpl({
    required this.chunkIndex,
    required final List<LiveInsightModel> insights,
    required this.totalInsights,
    required this.processingTimeMs,
    required this.timestamp,
  }) : _insights = insights;

  @override
  final int chunkIndex;
  final List<LiveInsightModel> _insights;
  @override
  List<LiveInsightModel> get insights {
    if (_insights is EqualUnmodifiableListView) return _insights;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_insights);
  }

  @override
  final int totalInsights;
  @override
  final int processingTimeMs;
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'InsightsExtractionResult(chunkIndex: $chunkIndex, insights: $insights, totalInsights: $totalInsights, processingTimeMs: $processingTimeMs, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InsightsExtractionResultImpl &&
            (identical(other.chunkIndex, chunkIndex) ||
                other.chunkIndex == chunkIndex) &&
            const DeepCollectionEquality().equals(other._insights, _insights) &&
            (identical(other.totalInsights, totalInsights) ||
                other.totalInsights == totalInsights) &&
            (identical(other.processingTimeMs, processingTimeMs) ||
                other.processingTimeMs == processingTimeMs) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    chunkIndex,
    const DeepCollectionEquality().hash(_insights),
    totalInsights,
    processingTimeMs,
    timestamp,
  );

  /// Create a copy of InsightsExtractionResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InsightsExtractionResultImplCopyWith<_$InsightsExtractionResultImpl>
  get copyWith =>
      __$$InsightsExtractionResultImplCopyWithImpl<
        _$InsightsExtractionResultImpl
      >(this, _$identity);
}

abstract class _InsightsExtractionResult implements InsightsExtractionResult {
  const factory _InsightsExtractionResult({
    required final int chunkIndex,
    required final List<LiveInsightModel> insights,
    required final int totalInsights,
    required final int processingTimeMs,
    required final DateTime timestamp,
  }) = _$InsightsExtractionResultImpl;

  @override
  int get chunkIndex;
  @override
  List<LiveInsightModel> get insights;
  @override
  int get totalInsights;
  @override
  int get processingTimeMs;
  @override
  DateTime get timestamp;

  /// Create a copy of InsightsExtractionResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InsightsExtractionResultImplCopyWith<_$InsightsExtractionResultImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SessionMetrics {
  double get sessionDurationSeconds => throw _privateConstructorUsedError;
  int get chunksProcessed => throw _privateConstructorUsedError;
  int get totalInsights => throw _privateConstructorUsedError;
  Map<String, int> get insightsByType => throw _privateConstructorUsedError;
  double get avgProcessingTimeMs => throw _privateConstructorUsedError;
  double get avgTranscriptionTimeMs => throw _privateConstructorUsedError;

  /// Create a copy of SessionMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SessionMetricsCopyWith<SessionMetrics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionMetricsCopyWith<$Res> {
  factory $SessionMetricsCopyWith(
    SessionMetrics value,
    $Res Function(SessionMetrics) then,
  ) = _$SessionMetricsCopyWithImpl<$Res, SessionMetrics>;
  @useResult
  $Res call({
    double sessionDurationSeconds,
    int chunksProcessed,
    int totalInsights,
    Map<String, int> insightsByType,
    double avgProcessingTimeMs,
    double avgTranscriptionTimeMs,
  });
}

/// @nodoc
class _$SessionMetricsCopyWithImpl<$Res, $Val extends SessionMetrics>
    implements $SessionMetricsCopyWith<$Res> {
  _$SessionMetricsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SessionMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionDurationSeconds = null,
    Object? chunksProcessed = null,
    Object? totalInsights = null,
    Object? insightsByType = null,
    Object? avgProcessingTimeMs = null,
    Object? avgTranscriptionTimeMs = null,
  }) {
    return _then(
      _value.copyWith(
            sessionDurationSeconds: null == sessionDurationSeconds
                ? _value.sessionDurationSeconds
                : sessionDurationSeconds // ignore: cast_nullable_to_non_nullable
                      as double,
            chunksProcessed: null == chunksProcessed
                ? _value.chunksProcessed
                : chunksProcessed // ignore: cast_nullable_to_non_nullable
                      as int,
            totalInsights: null == totalInsights
                ? _value.totalInsights
                : totalInsights // ignore: cast_nullable_to_non_nullable
                      as int,
            insightsByType: null == insightsByType
                ? _value.insightsByType
                : insightsByType // ignore: cast_nullable_to_non_nullable
                      as Map<String, int>,
            avgProcessingTimeMs: null == avgProcessingTimeMs
                ? _value.avgProcessingTimeMs
                : avgProcessingTimeMs // ignore: cast_nullable_to_non_nullable
                      as double,
            avgTranscriptionTimeMs: null == avgTranscriptionTimeMs
                ? _value.avgTranscriptionTimeMs
                : avgTranscriptionTimeMs // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SessionMetricsImplCopyWith<$Res>
    implements $SessionMetricsCopyWith<$Res> {
  factory _$$SessionMetricsImplCopyWith(
    _$SessionMetricsImpl value,
    $Res Function(_$SessionMetricsImpl) then,
  ) = __$$SessionMetricsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double sessionDurationSeconds,
    int chunksProcessed,
    int totalInsights,
    Map<String, int> insightsByType,
    double avgProcessingTimeMs,
    double avgTranscriptionTimeMs,
  });
}

/// @nodoc
class __$$SessionMetricsImplCopyWithImpl<$Res>
    extends _$SessionMetricsCopyWithImpl<$Res, _$SessionMetricsImpl>
    implements _$$SessionMetricsImplCopyWith<$Res> {
  __$$SessionMetricsImplCopyWithImpl(
    _$SessionMetricsImpl _value,
    $Res Function(_$SessionMetricsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SessionMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionDurationSeconds = null,
    Object? chunksProcessed = null,
    Object? totalInsights = null,
    Object? insightsByType = null,
    Object? avgProcessingTimeMs = null,
    Object? avgTranscriptionTimeMs = null,
  }) {
    return _then(
      _$SessionMetricsImpl(
        sessionDurationSeconds: null == sessionDurationSeconds
            ? _value.sessionDurationSeconds
            : sessionDurationSeconds // ignore: cast_nullable_to_non_nullable
                  as double,
        chunksProcessed: null == chunksProcessed
            ? _value.chunksProcessed
            : chunksProcessed // ignore: cast_nullable_to_non_nullable
                  as int,
        totalInsights: null == totalInsights
            ? _value.totalInsights
            : totalInsights // ignore: cast_nullable_to_non_nullable
                  as int,
        insightsByType: null == insightsByType
            ? _value._insightsByType
            : insightsByType // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
        avgProcessingTimeMs: null == avgProcessingTimeMs
            ? _value.avgProcessingTimeMs
            : avgProcessingTimeMs // ignore: cast_nullable_to_non_nullable
                  as double,
        avgTranscriptionTimeMs: null == avgTranscriptionTimeMs
            ? _value.avgTranscriptionTimeMs
            : avgTranscriptionTimeMs // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class _$SessionMetricsImpl implements _SessionMetrics {
  const _$SessionMetricsImpl({
    required this.sessionDurationSeconds,
    required this.chunksProcessed,
    required this.totalInsights,
    required final Map<String, int> insightsByType,
    required this.avgProcessingTimeMs,
    required this.avgTranscriptionTimeMs,
  }) : _insightsByType = insightsByType;

  @override
  final double sessionDurationSeconds;
  @override
  final int chunksProcessed;
  @override
  final int totalInsights;
  final Map<String, int> _insightsByType;
  @override
  Map<String, int> get insightsByType {
    if (_insightsByType is EqualUnmodifiableMapView) return _insightsByType;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_insightsByType);
  }

  @override
  final double avgProcessingTimeMs;
  @override
  final double avgTranscriptionTimeMs;

  @override
  String toString() {
    return 'SessionMetrics(sessionDurationSeconds: $sessionDurationSeconds, chunksProcessed: $chunksProcessed, totalInsights: $totalInsights, insightsByType: $insightsByType, avgProcessingTimeMs: $avgProcessingTimeMs, avgTranscriptionTimeMs: $avgTranscriptionTimeMs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionMetricsImpl &&
            (identical(other.sessionDurationSeconds, sessionDurationSeconds) ||
                other.sessionDurationSeconds == sessionDurationSeconds) &&
            (identical(other.chunksProcessed, chunksProcessed) ||
                other.chunksProcessed == chunksProcessed) &&
            (identical(other.totalInsights, totalInsights) ||
                other.totalInsights == totalInsights) &&
            const DeepCollectionEquality().equals(
              other._insightsByType,
              _insightsByType,
            ) &&
            (identical(other.avgProcessingTimeMs, avgProcessingTimeMs) ||
                other.avgProcessingTimeMs == avgProcessingTimeMs) &&
            (identical(other.avgTranscriptionTimeMs, avgTranscriptionTimeMs) ||
                other.avgTranscriptionTimeMs == avgTranscriptionTimeMs));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    sessionDurationSeconds,
    chunksProcessed,
    totalInsights,
    const DeepCollectionEquality().hash(_insightsByType),
    avgProcessingTimeMs,
    avgTranscriptionTimeMs,
  );

  /// Create a copy of SessionMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionMetricsImplCopyWith<_$SessionMetricsImpl> get copyWith =>
      __$$SessionMetricsImplCopyWithImpl<_$SessionMetricsImpl>(
        this,
        _$identity,
      );
}

abstract class _SessionMetrics implements SessionMetrics {
  const factory _SessionMetrics({
    required final double sessionDurationSeconds,
    required final int chunksProcessed,
    required final int totalInsights,
    required final Map<String, int> insightsByType,
    required final double avgProcessingTimeMs,
    required final double avgTranscriptionTimeMs,
  }) = _$SessionMetricsImpl;

  @override
  double get sessionDurationSeconds;
  @override
  int get chunksProcessed;
  @override
  int get totalInsights;
  @override
  Map<String, int> get insightsByType;
  @override
  double get avgProcessingTimeMs;
  @override
  double get avgTranscriptionTimeMs;

  /// Create a copy of SessionMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SessionMetricsImplCopyWith<_$SessionMetricsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SessionFinalizedResult {
  String get sessionId => throw _privateConstructorUsedError;
  int get totalInsights => throw _privateConstructorUsedError;
  Map<String, List<LiveInsightModel>> get insightsByType =>
      throw _privateConstructorUsedError;
  List<LiveInsightModel> get allInsights => throw _privateConstructorUsedError;
  SessionMetrics get metrics => throw _privateConstructorUsedError;

  /// Create a copy of SessionFinalizedResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SessionFinalizedResultCopyWith<SessionFinalizedResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionFinalizedResultCopyWith<$Res> {
  factory $SessionFinalizedResultCopyWith(
    SessionFinalizedResult value,
    $Res Function(SessionFinalizedResult) then,
  ) = _$SessionFinalizedResultCopyWithImpl<$Res, SessionFinalizedResult>;
  @useResult
  $Res call({
    String sessionId,
    int totalInsights,
    Map<String, List<LiveInsightModel>> insightsByType,
    List<LiveInsightModel> allInsights,
    SessionMetrics metrics,
  });

  $SessionMetricsCopyWith<$Res> get metrics;
}

/// @nodoc
class _$SessionFinalizedResultCopyWithImpl<
  $Res,
  $Val extends SessionFinalizedResult
>
    implements $SessionFinalizedResultCopyWith<$Res> {
  _$SessionFinalizedResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SessionFinalizedResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? totalInsights = null,
    Object? insightsByType = null,
    Object? allInsights = null,
    Object? metrics = null,
  }) {
    return _then(
      _value.copyWith(
            sessionId: null == sessionId
                ? _value.sessionId
                : sessionId // ignore: cast_nullable_to_non_nullable
                      as String,
            totalInsights: null == totalInsights
                ? _value.totalInsights
                : totalInsights // ignore: cast_nullable_to_non_nullable
                      as int,
            insightsByType: null == insightsByType
                ? _value.insightsByType
                : insightsByType // ignore: cast_nullable_to_non_nullable
                      as Map<String, List<LiveInsightModel>>,
            allInsights: null == allInsights
                ? _value.allInsights
                : allInsights // ignore: cast_nullable_to_non_nullable
                      as List<LiveInsightModel>,
            metrics: null == metrics
                ? _value.metrics
                : metrics // ignore: cast_nullable_to_non_nullable
                      as SessionMetrics,
          )
          as $Val,
    );
  }

  /// Create a copy of SessionFinalizedResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SessionMetricsCopyWith<$Res> get metrics {
    return $SessionMetricsCopyWith<$Res>(_value.metrics, (value) {
      return _then(_value.copyWith(metrics: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SessionFinalizedResultImplCopyWith<$Res>
    implements $SessionFinalizedResultCopyWith<$Res> {
  factory _$$SessionFinalizedResultImplCopyWith(
    _$SessionFinalizedResultImpl value,
    $Res Function(_$SessionFinalizedResultImpl) then,
  ) = __$$SessionFinalizedResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String sessionId,
    int totalInsights,
    Map<String, List<LiveInsightModel>> insightsByType,
    List<LiveInsightModel> allInsights,
    SessionMetrics metrics,
  });

  @override
  $SessionMetricsCopyWith<$Res> get metrics;
}

/// @nodoc
class __$$SessionFinalizedResultImplCopyWithImpl<$Res>
    extends
        _$SessionFinalizedResultCopyWithImpl<$Res, _$SessionFinalizedResultImpl>
    implements _$$SessionFinalizedResultImplCopyWith<$Res> {
  __$$SessionFinalizedResultImplCopyWithImpl(
    _$SessionFinalizedResultImpl _value,
    $Res Function(_$SessionFinalizedResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SessionFinalizedResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? totalInsights = null,
    Object? insightsByType = null,
    Object? allInsights = null,
    Object? metrics = null,
  }) {
    return _then(
      _$SessionFinalizedResultImpl(
        sessionId: null == sessionId
            ? _value.sessionId
            : sessionId // ignore: cast_nullable_to_non_nullable
                  as String,
        totalInsights: null == totalInsights
            ? _value.totalInsights
            : totalInsights // ignore: cast_nullable_to_non_nullable
                  as int,
        insightsByType: null == insightsByType
            ? _value._insightsByType
            : insightsByType // ignore: cast_nullable_to_non_nullable
                  as Map<String, List<LiveInsightModel>>,
        allInsights: null == allInsights
            ? _value._allInsights
            : allInsights // ignore: cast_nullable_to_non_nullable
                  as List<LiveInsightModel>,
        metrics: null == metrics
            ? _value.metrics
            : metrics // ignore: cast_nullable_to_non_nullable
                  as SessionMetrics,
      ),
    );
  }
}

/// @nodoc

class _$SessionFinalizedResultImpl implements _SessionFinalizedResult {
  const _$SessionFinalizedResultImpl({
    required this.sessionId,
    required this.totalInsights,
    required final Map<String, List<LiveInsightModel>> insightsByType,
    required final List<LiveInsightModel> allInsights,
    required this.metrics,
  }) : _insightsByType = insightsByType,
       _allInsights = allInsights;

  @override
  final String sessionId;
  @override
  final int totalInsights;
  final Map<String, List<LiveInsightModel>> _insightsByType;
  @override
  Map<String, List<LiveInsightModel>> get insightsByType {
    if (_insightsByType is EqualUnmodifiableMapView) return _insightsByType;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_insightsByType);
  }

  final List<LiveInsightModel> _allInsights;
  @override
  List<LiveInsightModel> get allInsights {
    if (_allInsights is EqualUnmodifiableListView) return _allInsights;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allInsights);
  }

  @override
  final SessionMetrics metrics;

  @override
  String toString() {
    return 'SessionFinalizedResult(sessionId: $sessionId, totalInsights: $totalInsights, insightsByType: $insightsByType, allInsights: $allInsights, metrics: $metrics)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionFinalizedResultImpl &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.totalInsights, totalInsights) ||
                other.totalInsights == totalInsights) &&
            const DeepCollectionEquality().equals(
              other._insightsByType,
              _insightsByType,
            ) &&
            const DeepCollectionEquality().equals(
              other._allInsights,
              _allInsights,
            ) &&
            (identical(other.metrics, metrics) || other.metrics == metrics));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    sessionId,
    totalInsights,
    const DeepCollectionEquality().hash(_insightsByType),
    const DeepCollectionEquality().hash(_allInsights),
    metrics,
  );

  /// Create a copy of SessionFinalizedResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionFinalizedResultImplCopyWith<_$SessionFinalizedResultImpl>
  get copyWith =>
      __$$SessionFinalizedResultImplCopyWithImpl<_$SessionFinalizedResultImpl>(
        this,
        _$identity,
      );
}

abstract class _SessionFinalizedResult implements SessionFinalizedResult {
  const factory _SessionFinalizedResult({
    required final String sessionId,
    required final int totalInsights,
    required final Map<String, List<LiveInsightModel>> insightsByType,
    required final List<LiveInsightModel> allInsights,
    required final SessionMetrics metrics,
  }) = _$SessionFinalizedResultImpl;

  @override
  String get sessionId;
  @override
  int get totalInsights;
  @override
  Map<String, List<LiveInsightModel>> get insightsByType;
  @override
  List<LiveInsightModel> get allInsights;
  @override
  SessionMetrics get metrics;

  /// Create a copy of SessionFinalizedResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SessionFinalizedResultImplCopyWith<_$SessionFinalizedResultImpl>
  get copyWith => throw _privateConstructorUsedError;
}
