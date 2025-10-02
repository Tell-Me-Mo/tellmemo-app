// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'summary_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SummaryListState {
  bool get isLoading => throw _privateConstructorUsedError;
  List<SummaryModel> get summaries => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  String? get selectedProjectId => throw _privateConstructorUsedError;
  SummaryType? get filterType => throw _privateConstructorUsedError;

  /// Create a copy of SummaryListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SummaryListStateCopyWith<SummaryListState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SummaryListStateCopyWith<$Res> {
  factory $SummaryListStateCopyWith(
    SummaryListState value,
    $Res Function(SummaryListState) then,
  ) = _$SummaryListStateCopyWithImpl<$Res, SummaryListState>;
  @useResult
  $Res call({
    bool isLoading,
    List<SummaryModel> summaries,
    String? error,
    String? selectedProjectId,
    SummaryType? filterType,
  });
}

/// @nodoc
class _$SummaryListStateCopyWithImpl<$Res, $Val extends SummaryListState>
    implements $SummaryListStateCopyWith<$Res> {
  _$SummaryListStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SummaryListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? summaries = null,
    Object? error = freezed,
    Object? selectedProjectId = freezed,
    Object? filterType = freezed,
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
                      as List<SummaryModel>,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
            selectedProjectId: freezed == selectedProjectId
                ? _value.selectedProjectId
                : selectedProjectId // ignore: cast_nullable_to_non_nullable
                      as String?,
            filterType: freezed == filterType
                ? _value.filterType
                : filterType // ignore: cast_nullable_to_non_nullable
                      as SummaryType?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SummaryListStateImplCopyWith<$Res>
    implements $SummaryListStateCopyWith<$Res> {
  factory _$$SummaryListStateImplCopyWith(
    _$SummaryListStateImpl value,
    $Res Function(_$SummaryListStateImpl) then,
  ) = __$$SummaryListStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isLoading,
    List<SummaryModel> summaries,
    String? error,
    String? selectedProjectId,
    SummaryType? filterType,
  });
}

/// @nodoc
class __$$SummaryListStateImplCopyWithImpl<$Res>
    extends _$SummaryListStateCopyWithImpl<$Res, _$SummaryListStateImpl>
    implements _$$SummaryListStateImplCopyWith<$Res> {
  __$$SummaryListStateImplCopyWithImpl(
    _$SummaryListStateImpl _value,
    $Res Function(_$SummaryListStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SummaryListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? summaries = null,
    Object? error = freezed,
    Object? selectedProjectId = freezed,
    Object? filterType = freezed,
  }) {
    return _then(
      _$SummaryListStateImpl(
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        summaries: null == summaries
            ? _value._summaries
            : summaries // ignore: cast_nullable_to_non_nullable
                  as List<SummaryModel>,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        selectedProjectId: freezed == selectedProjectId
            ? _value.selectedProjectId
            : selectedProjectId // ignore: cast_nullable_to_non_nullable
                  as String?,
        filterType: freezed == filterType
            ? _value.filterType
            : filterType // ignore: cast_nullable_to_non_nullable
                  as SummaryType?,
      ),
    );
  }
}

/// @nodoc

class _$SummaryListStateImpl implements _SummaryListState {
  const _$SummaryListStateImpl({
    this.isLoading = false,
    final List<SummaryModel> summaries = const [],
    this.error = null,
    this.selectedProjectId = null,
    this.filterType = null,
  }) : _summaries = summaries;

  @override
  @JsonKey()
  final bool isLoading;
  final List<SummaryModel> _summaries;
  @override
  @JsonKey()
  List<SummaryModel> get summaries {
    if (_summaries is EqualUnmodifiableListView) return _summaries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_summaries);
  }

  @override
  @JsonKey()
  final String? error;
  @override
  @JsonKey()
  final String? selectedProjectId;
  @override
  @JsonKey()
  final SummaryType? filterType;

  @override
  String toString() {
    return 'SummaryListState(isLoading: $isLoading, summaries: $summaries, error: $error, selectedProjectId: $selectedProjectId, filterType: $filterType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SummaryListStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            const DeepCollectionEquality().equals(
              other._summaries,
              _summaries,
            ) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.selectedProjectId, selectedProjectId) ||
                other.selectedProjectId == selectedProjectId) &&
            (identical(other.filterType, filterType) ||
                other.filterType == filterType));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isLoading,
    const DeepCollectionEquality().hash(_summaries),
    error,
    selectedProjectId,
    filterType,
  );

  /// Create a copy of SummaryListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SummaryListStateImplCopyWith<_$SummaryListStateImpl> get copyWith =>
      __$$SummaryListStateImplCopyWithImpl<_$SummaryListStateImpl>(
        this,
        _$identity,
      );
}

abstract class _SummaryListState implements SummaryListState {
  const factory _SummaryListState({
    final bool isLoading,
    final List<SummaryModel> summaries,
    final String? error,
    final String? selectedProjectId,
    final SummaryType? filterType,
  }) = _$SummaryListStateImpl;

  @override
  bool get isLoading;
  @override
  List<SummaryModel> get summaries;
  @override
  String? get error;
  @override
  String? get selectedProjectId;
  @override
  SummaryType? get filterType;

  /// Create a copy of SummaryListState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SummaryListStateImplCopyWith<_$SummaryListStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SummaryDetailState {
  bool get isLoading => throw _privateConstructorUsedError;
  SummaryModel? get summary => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  bool get isExporting => throw _privateConstructorUsedError;

  /// Create a copy of SummaryDetailState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SummaryDetailStateCopyWith<SummaryDetailState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SummaryDetailStateCopyWith<$Res> {
  factory $SummaryDetailStateCopyWith(
    SummaryDetailState value,
    $Res Function(SummaryDetailState) then,
  ) = _$SummaryDetailStateCopyWithImpl<$Res, SummaryDetailState>;
  @useResult
  $Res call({
    bool isLoading,
    SummaryModel? summary,
    String? error,
    bool isExporting,
  });

  $SummaryModelCopyWith<$Res>? get summary;
}

/// @nodoc
class _$SummaryDetailStateCopyWithImpl<$Res, $Val extends SummaryDetailState>
    implements $SummaryDetailStateCopyWith<$Res> {
  _$SummaryDetailStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SummaryDetailState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? summary = freezed,
    Object? error = freezed,
    Object? isExporting = null,
  }) {
    return _then(
      _value.copyWith(
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            summary: freezed == summary
                ? _value.summary
                : summary // ignore: cast_nullable_to_non_nullable
                      as SummaryModel?,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
            isExporting: null == isExporting
                ? _value.isExporting
                : isExporting // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of SummaryDetailState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SummaryModelCopyWith<$Res>? get summary {
    if (_value.summary == null) {
      return null;
    }

    return $SummaryModelCopyWith<$Res>(_value.summary!, (value) {
      return _then(_value.copyWith(summary: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SummaryDetailStateImplCopyWith<$Res>
    implements $SummaryDetailStateCopyWith<$Res> {
  factory _$$SummaryDetailStateImplCopyWith(
    _$SummaryDetailStateImpl value,
    $Res Function(_$SummaryDetailStateImpl) then,
  ) = __$$SummaryDetailStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isLoading,
    SummaryModel? summary,
    String? error,
    bool isExporting,
  });

  @override
  $SummaryModelCopyWith<$Res>? get summary;
}

/// @nodoc
class __$$SummaryDetailStateImplCopyWithImpl<$Res>
    extends _$SummaryDetailStateCopyWithImpl<$Res, _$SummaryDetailStateImpl>
    implements _$$SummaryDetailStateImplCopyWith<$Res> {
  __$$SummaryDetailStateImplCopyWithImpl(
    _$SummaryDetailStateImpl _value,
    $Res Function(_$SummaryDetailStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SummaryDetailState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? summary = freezed,
    Object? error = freezed,
    Object? isExporting = null,
  }) {
    return _then(
      _$SummaryDetailStateImpl(
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        summary: freezed == summary
            ? _value.summary
            : summary // ignore: cast_nullable_to_non_nullable
                  as SummaryModel?,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        isExporting: null == isExporting
            ? _value.isExporting
            : isExporting // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$SummaryDetailStateImpl implements _SummaryDetailState {
  const _$SummaryDetailStateImpl({
    this.isLoading = false,
    this.summary = null,
    this.error = null,
    this.isExporting = false,
  });

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final SummaryModel? summary;
  @override
  @JsonKey()
  final String? error;
  @override
  @JsonKey()
  final bool isExporting;

  @override
  String toString() {
    return 'SummaryDetailState(isLoading: $isLoading, summary: $summary, error: $error, isExporting: $isExporting)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SummaryDetailStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isExporting, isExporting) ||
                other.isExporting == isExporting));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, isLoading, summary, error, isExporting);

  /// Create a copy of SummaryDetailState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SummaryDetailStateImplCopyWith<_$SummaryDetailStateImpl> get copyWith =>
      __$$SummaryDetailStateImplCopyWithImpl<_$SummaryDetailStateImpl>(
        this,
        _$identity,
      );
}

abstract class _SummaryDetailState implements SummaryDetailState {
  const factory _SummaryDetailState({
    final bool isLoading,
    final SummaryModel? summary,
    final String? error,
    final bool isExporting,
  }) = _$SummaryDetailStateImpl;

  @override
  bool get isLoading;
  @override
  SummaryModel? get summary;
  @override
  String? get error;
  @override
  bool get isExporting;

  /// Create a copy of SummaryDetailState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SummaryDetailStateImplCopyWith<_$SummaryDetailStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SummaryGenerationState {
  bool get isGenerating => throw _privateConstructorUsedError;
  SummaryModel? get generatedSummary => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  double get progress => throw _privateConstructorUsedError;

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
    SummaryModel? generatedSummary,
    String? error,
    double progress,
  });

  $SummaryModelCopyWith<$Res>? get generatedSummary;
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
                      as SummaryModel?,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
            progress: null == progress
                ? _value.progress
                : progress // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }

  /// Create a copy of SummaryGenerationState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SummaryModelCopyWith<$Res>? get generatedSummary {
    if (_value.generatedSummary == null) {
      return null;
    }

    return $SummaryModelCopyWith<$Res>(_value.generatedSummary!, (value) {
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
    SummaryModel? generatedSummary,
    String? error,
    double progress,
  });

  @override
  $SummaryModelCopyWith<$Res>? get generatedSummary;
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
                  as SummaryModel?,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        progress: null == progress
            ? _value.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as double,
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
  });

  @override
  @JsonKey()
  final bool isGenerating;
  @override
  @JsonKey()
  final SummaryModel? generatedSummary;
  @override
  @JsonKey()
  final String? error;
  @override
  @JsonKey()
  final double progress;

  @override
  String toString() {
    return 'SummaryGenerationState(isGenerating: $isGenerating, generatedSummary: $generatedSummary, error: $error, progress: $progress)';
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
                other.progress == progress));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, isGenerating, generatedSummary, error, progress);

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
    final SummaryModel? generatedSummary,
    final String? error,
    final double progress,
  }) = _$SummaryGenerationStateImpl;

  @override
  bool get isGenerating;
  @override
  SummaryModel? get generatedSummary;
  @override
  String? get error;
  @override
  double get progress;

  /// Create a copy of SummaryGenerationState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SummaryGenerationStateImplCopyWith<_$SummaryGenerationStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}
