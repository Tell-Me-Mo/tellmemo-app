// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transcript_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TranscriptModel _$TranscriptModelFromJson(Map<String, dynamic> json) {
  return _TranscriptModel.fromJson(json);
}

/// @nodoc
mixin _$TranscriptModel {
  /// Unique identifier for this transcript segment
  String get id => throw _privateConstructorUsedError;

  /// The transcribed text
  String get text => throw _privateConstructorUsedError;

  /// Timestamp when this segment was spoken
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Transcription state (partial or final)
  TranscriptionState get state => throw _privateConstructorUsedError;

  /// Confidence score from transcription service (0.0 - 1.0)
  double? get confidence => throw _privateConstructorUsedError;

  /// Start time in milliseconds from beginning of recording
  int? get startMs => throw _privateConstructorUsedError;

  /// End time in milliseconds from beginning of recording
  int? get endMs => throw _privateConstructorUsedError;

  /// Serializes this TranscriptModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TranscriptModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TranscriptModelCopyWith<TranscriptModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TranscriptModelCopyWith<$Res> {
  factory $TranscriptModelCopyWith(
    TranscriptModel value,
    $Res Function(TranscriptModel) then,
  ) = _$TranscriptModelCopyWithImpl<$Res, TranscriptModel>;
  @useResult
  $Res call({
    String id,
    String text,
    DateTime timestamp,
    TranscriptionState state,
    double? confidence,
    int? startMs,
    int? endMs,
  });
}

/// @nodoc
class _$TranscriptModelCopyWithImpl<$Res, $Val extends TranscriptModel>
    implements $TranscriptModelCopyWith<$Res> {
  _$TranscriptModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TranscriptModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? timestamp = null,
    Object? state = null,
    Object? confidence = freezed,
    Object? startMs = freezed,
    Object? endMs = freezed,
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
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            state: null == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                      as TranscriptionState,
            confidence: freezed == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double?,
            startMs: freezed == startMs
                ? _value.startMs
                : startMs // ignore: cast_nullable_to_non_nullable
                      as int?,
            endMs: freezed == endMs
                ? _value.endMs
                : endMs // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TranscriptModelImplCopyWith<$Res>
    implements $TranscriptModelCopyWith<$Res> {
  factory _$$TranscriptModelImplCopyWith(
    _$TranscriptModelImpl value,
    $Res Function(_$TranscriptModelImpl) then,
  ) = __$$TranscriptModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String text,
    DateTime timestamp,
    TranscriptionState state,
    double? confidence,
    int? startMs,
    int? endMs,
  });
}

/// @nodoc
class __$$TranscriptModelImplCopyWithImpl<$Res>
    extends _$TranscriptModelCopyWithImpl<$Res, _$TranscriptModelImpl>
    implements _$$TranscriptModelImplCopyWith<$Res> {
  __$$TranscriptModelImplCopyWithImpl(
    _$TranscriptModelImpl _value,
    $Res Function(_$TranscriptModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TranscriptModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? timestamp = null,
    Object? state = null,
    Object? confidence = freezed,
    Object? startMs = freezed,
    Object? endMs = freezed,
  }) {
    return _then(
      _$TranscriptModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        state: null == state
            ? _value.state
            : state // ignore: cast_nullable_to_non_nullable
                  as TranscriptionState,
        confidence: freezed == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double?,
        startMs: freezed == startMs
            ? _value.startMs
            : startMs // ignore: cast_nullable_to_non_nullable
                  as int?,
        endMs: freezed == endMs
            ? _value.endMs
            : endMs // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TranscriptModelImpl implements _TranscriptModel {
  const _$TranscriptModelImpl({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.state,
    this.confidence,
    this.startMs,
    this.endMs,
  });

  factory _$TranscriptModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TranscriptModelImplFromJson(json);

  /// Unique identifier for this transcript segment
  @override
  final String id;

  /// The transcribed text
  @override
  final String text;

  /// Timestamp when this segment was spoken
  @override
  final DateTime timestamp;

  /// Transcription state (partial or final)
  @override
  final TranscriptionState state;

  /// Confidence score from transcription service (0.0 - 1.0)
  @override
  final double? confidence;

  /// Start time in milliseconds from beginning of recording
  @override
  final int? startMs;

  /// End time in milliseconds from beginning of recording
  @override
  final int? endMs;

  @override
  String toString() {
    return 'TranscriptModel(id: $id, text: $text, timestamp: $timestamp, state: $state, confidence: $confidence, startMs: $startMs, endMs: $endMs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TranscriptModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.startMs, startMs) || other.startMs == startMs) &&
            (identical(other.endMs, endMs) || other.endMs == endMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    text,
    timestamp,
    state,
    confidence,
    startMs,
    endMs,
  );

  /// Create a copy of TranscriptModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TranscriptModelImplCopyWith<_$TranscriptModelImpl> get copyWith =>
      __$$TranscriptModelImplCopyWithImpl<_$TranscriptModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TranscriptModelImplToJson(this);
  }
}

abstract class _TranscriptModel implements TranscriptModel {
  const factory _TranscriptModel({
    required final String id,
    required final String text,
    required final DateTime timestamp,
    required final TranscriptionState state,
    final double? confidence,
    final int? startMs,
    final int? endMs,
  }) = _$TranscriptModelImpl;

  factory _TranscriptModel.fromJson(Map<String, dynamic> json) =
      _$TranscriptModelImpl.fromJson;

  /// Unique identifier for this transcript segment
  @override
  String get id;

  /// The transcribed text
  @override
  String get text;

  /// Timestamp when this segment was spoken
  @override
  DateTime get timestamp;

  /// Transcription state (partial or final)
  @override
  TranscriptionState get state;

  /// Confidence score from transcription service (0.0 - 1.0)
  @override
  double? get confidence;

  /// Start time in milliseconds from beginning of recording
  @override
  int? get startMs;

  /// End time in milliseconds from beginning of recording
  @override
  int? get endMs;

  /// Create a copy of TranscriptModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TranscriptModelImplCopyWith<_$TranscriptModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
