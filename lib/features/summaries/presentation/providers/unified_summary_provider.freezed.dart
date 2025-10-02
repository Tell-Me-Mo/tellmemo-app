// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unified_summary_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$UnifiedSummaryState {
  bool get isLoading => throw _privateConstructorUsedError;
  List<UnifiedSummaryResponse> get summaries =>
      throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  UnifiedSummaryResponse? get selectedSummary =>
      throw _privateConstructorUsedError;

  /// Create a copy of UnifiedSummaryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UnifiedSummaryStateCopyWith<UnifiedSummaryState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UnifiedSummaryStateCopyWith<$Res> {
  factory $UnifiedSummaryStateCopyWith(
    UnifiedSummaryState value,
    $Res Function(UnifiedSummaryState) then,
  ) = _$UnifiedSummaryStateCopyWithImpl<$Res, UnifiedSummaryState>;
  @useResult
  $Res call({
    bool isLoading,
    List<UnifiedSummaryResponse> summaries,
    String? error,
    UnifiedSummaryResponse? selectedSummary,
  });

  $UnifiedSummaryResponseCopyWith<$Res>? get selectedSummary;
}

/// @nodoc
class _$UnifiedSummaryStateCopyWithImpl<$Res, $Val extends UnifiedSummaryState>
    implements $UnifiedSummaryStateCopyWith<$Res> {
  _$UnifiedSummaryStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UnifiedSummaryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? summaries = null,
    Object? error = freezed,
    Object? selectedSummary = freezed,
  }) {
    return _then(
      _value.copyWith(
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            summaries: null == summaries
                ? _value.summaries
                : summaries // ignore: cast_nullable_to_non_nullable
                      as List<UnifiedSummaryResponse>,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
            selectedSummary: freezed == selectedSummary
                ? _value.selectedSummary
                : selectedSummary // ignore: cast_nullable_to_non_nullable
                      as UnifiedSummaryResponse?,
          )
          as $Val,
    );
  }

  /// Create a copy of UnifiedSummaryState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UnifiedSummaryResponseCopyWith<$Res>? get selectedSummary {
    if (_value.selectedSummary == null) {
      return null;
    }

    return $UnifiedSummaryResponseCopyWith<$Res>(_value.selectedSummary!, (
      value,
    ) {
      return _then(_value.copyWith(selectedSummary: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UnifiedSummaryStateImplCopyWith<$Res>
    implements $UnifiedSummaryStateCopyWith<$Res> {
  factory _$$UnifiedSummaryStateImplCopyWith(
    _$UnifiedSummaryStateImpl value,
    $Res Function(_$UnifiedSummaryStateImpl) then,
  ) = __$$UnifiedSummaryStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isLoading,
    List<UnifiedSummaryResponse> summaries,
    String? error,
    UnifiedSummaryResponse? selectedSummary,
  });

  @override
  $UnifiedSummaryResponseCopyWith<$Res>? get selectedSummary;
}

/// @nodoc
class __$$UnifiedSummaryStateImplCopyWithImpl<$Res>
    extends _$UnifiedSummaryStateCopyWithImpl<$Res, _$UnifiedSummaryStateImpl>
    implements _$$UnifiedSummaryStateImplCopyWith<$Res> {
  __$$UnifiedSummaryStateImplCopyWithImpl(
    _$UnifiedSummaryStateImpl _value,
    $Res Function(_$UnifiedSummaryStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UnifiedSummaryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? summaries = null,
    Object? error = freezed,
    Object? selectedSummary = freezed,
  }) {
    return _then(
      _$UnifiedSummaryStateImpl(
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        summaries: null == summaries
            ? _value._summaries
            : summaries // ignore: cast_nullable_to_non_nullable
                  as List<UnifiedSummaryResponse>,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        selectedSummary: freezed == selectedSummary
            ? _value.selectedSummary
            : selectedSummary // ignore: cast_nullable_to_non_nullable
                  as UnifiedSummaryResponse?,
      ),
    );
  }
}

/// @nodoc

class _$UnifiedSummaryStateImpl implements _UnifiedSummaryState {
  const _$UnifiedSummaryStateImpl({
    this.isLoading = false,
    final List<UnifiedSummaryResponse> summaries = const [],
    this.error = null,
    this.selectedSummary = null,
  }) : _summaries = summaries;

  @override
  @JsonKey()
  final bool isLoading;
  final List<UnifiedSummaryResponse> _summaries;
  @override
  @JsonKey()
  List<UnifiedSummaryResponse> get summaries {
    if (_summaries is EqualUnmodifiableListView) return _summaries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_summaries);
  }

  @override
  @JsonKey()
  final String? error;
  @override
  @JsonKey()
  final UnifiedSummaryResponse? selectedSummary;

  @override
  String toString() {
    return 'UnifiedSummaryState(isLoading: $isLoading, summaries: $summaries, error: $error, selectedSummary: $selectedSummary)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnifiedSummaryStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            const DeepCollectionEquality().equals(
              other._summaries,
              _summaries,
            ) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.selectedSummary, selectedSummary) ||
                other.selectedSummary == selectedSummary));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isLoading,
    const DeepCollectionEquality().hash(_summaries),
    error,
    selectedSummary,
  );

  /// Create a copy of UnifiedSummaryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnifiedSummaryStateImplCopyWith<_$UnifiedSummaryStateImpl> get copyWith =>
      __$$UnifiedSummaryStateImplCopyWithImpl<_$UnifiedSummaryStateImpl>(
        this,
        _$identity,
      );
}

abstract class _UnifiedSummaryState implements UnifiedSummaryState {
  const factory _UnifiedSummaryState({
    final bool isLoading,
    final List<UnifiedSummaryResponse> summaries,
    final String? error,
    final UnifiedSummaryResponse? selectedSummary,
  }) = _$UnifiedSummaryStateImpl;

  @override
  bool get isLoading;
  @override
  List<UnifiedSummaryResponse> get summaries;
  @override
  String? get error;
  @override
  UnifiedSummaryResponse? get selectedSummary;

  /// Create a copy of UnifiedSummaryState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnifiedSummaryStateImplCopyWith<_$UnifiedSummaryStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SummaryGenerationState {
  bool get isGenerating => throw _privateConstructorUsedError;
  UnifiedSummaryResponse? get generatedSummary =>
      throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  double get progress => throw _privateConstructorUsedError;
  String? get jobId => throw _privateConstructorUsedError;

  /// Create a copy of SummaryGenerationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SummaryGenerationStateCopyWith<SummaryGenerationState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SummaryGenerationStateCopyWith<$Res> {
  factory $SummaryGenerationStateCopyWith(
    SummaryGenerationState value,
    $Res Function(SummaryGenerationState) then,
  ) = _$SummaryGenerationStateCopyWithImpl<$Res, SummaryGenerationState>;
  @useResult
  $Res call({
    bool isGenerating,
    UnifiedSummaryResponse? generatedSummary,
    String? error,
    double progress,
    String? jobId,
  });

  $UnifiedSummaryResponseCopyWith<$Res>? get generatedSummary;
}

/// @nodoc
class _$SummaryGenerationStateCopyWithImpl<
  $Res,
  $Val extends SummaryGenerationState
>
    implements $SummaryGenerationStateCopyWith<$Res> {
  _$SummaryGenerationStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SummaryGenerationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isGenerating = null,
    Object? generatedSummary = freezed,
    Object? error = freezed,
    Object? progress = null,
    Object? jobId = freezed,
  }) {
    return _then(
      _value.copyWith(
            isGenerating: null == isGenerating
                ? _value.isGenerating
                : isGenerating // ignore: cast_nullable_to_non_nullable
                      as bool,
            generatedSummary: freezed == generatedSummary
                ? _value.generatedSummary
                : generatedSummary // ignore: cast_nullable_to_non_nullable
                      as UnifiedSummaryResponse?,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
            progress: null == progress
                ? _value.progress
                : progress // ignore: cast_nullable_to_non_nullable
                      as double,
            jobId: freezed == jobId
                ? _value.jobId
                : jobId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of SummaryGenerationState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UnifiedSummaryResponseCopyWith<$Res>? get generatedSummary {
    if (_value.generatedSummary == null) {
      return null;
    }

    return $UnifiedSummaryResponseCopyWith<$Res>(_value.generatedSummary!, (
      value,
    ) {
      return _then(_value.copyWith(generatedSummary: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SummaryGenerationStateImplCopyWith<$Res>
    implements $SummaryGenerationStateCopyWith<$Res> {
  factory _$$SummaryGenerationStateImplCopyWith(
    _$SummaryGenerationStateImpl value,
    $Res Function(_$SummaryGenerationStateImpl) then,
  ) = __$$SummaryGenerationStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isGenerating,
    UnifiedSummaryResponse? generatedSummary,
    String? error,
    double progress,
    String? jobId,
  });

  @override
  $UnifiedSummaryResponseCopyWith<$Res>? get generatedSummary;
}

/// @nodoc
class __$$SummaryGenerationStateImplCopyWithImpl<$Res>
    extends
        _$SummaryGenerationStateCopyWithImpl<$Res, _$SummaryGenerationStateImpl>
    implements _$$SummaryGenerationStateImplCopyWith<$Res> {
  __$$SummaryGenerationStateImplCopyWithImpl(
    _$SummaryGenerationStateImpl _value,
    $Res Function(_$SummaryGenerationStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SummaryGenerationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isGenerating = null,
    Object? generatedSummary = freezed,
    Object? error = freezed,
    Object? progress = null,
    Object? jobId = freezed,
  }) {
    return _then(
      _$SummaryGenerationStateImpl(
        isGenerating: null == isGenerating
            ? _value.isGenerating
            : isGenerating // ignore: cast_nullable_to_non_nullable
                  as bool,
        generatedSummary: freezed == generatedSummary
            ? _value.generatedSummary
            : generatedSummary // ignore: cast_nullable_to_non_nullable
                  as UnifiedSummaryResponse?,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        progress: null == progress
            ? _value.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as double,
        jobId: freezed == jobId
            ? _value.jobId
            : jobId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$SummaryGenerationStateImpl implements _SummaryGenerationState {
  const _$SummaryGenerationStateImpl({
    this.isGenerating = false,
    this.generatedSummary = null,
    this.error = null,
    this.progress = 0.0,
    this.jobId = null,
  });

  @override
  @JsonKey()
  final bool isGenerating;
  @override
  @JsonKey()
  final UnifiedSummaryResponse? generatedSummary;
  @override
  @JsonKey()
  final String? error;
  @override
  @JsonKey()
  final double progress;
  @override
  @JsonKey()
  final String? jobId;

  @override
  String toString() {
    return 'SummaryGenerationState(isGenerating: $isGenerating, generatedSummary: $generatedSummary, error: $error, progress: $progress, jobId: $jobId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SummaryGenerationStateImpl &&
            (identical(other.isGenerating, isGenerating) ||
                other.isGenerating == isGenerating) &&
            (identical(other.generatedSummary, generatedSummary) ||
                other.generatedSummary == generatedSummary) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.jobId, jobId) || other.jobId == jobId));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isGenerating,
    generatedSummary,
    error,
    progress,
    jobId,
  );

  /// Create a copy of SummaryGenerationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SummaryGenerationStateImplCopyWith<_$SummaryGenerationStateImpl>
  get copyWith =>
      __$$SummaryGenerationStateImplCopyWithImpl<_$SummaryGenerationStateImpl>(
        this,
        _$identity,
      );
}

abstract class _SummaryGenerationState implements SummaryGenerationState {
  const factory _SummaryGenerationState({
    final bool isGenerating,
    final UnifiedSummaryResponse? generatedSummary,
    final String? error,
    final double progress,
    final String? jobId,
  }) = _$SummaryGenerationStateImpl;

  @override
  bool get isGenerating;
  @override
  UnifiedSummaryResponse? get generatedSummary;
  @override
  String? get error;
  @override
  double get progress;
  @override
  String? get jobId;

  /// Create a copy of SummaryGenerationState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SummaryGenerationStateImplCopyWith<_$SummaryGenerationStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}
