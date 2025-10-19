// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'historical_insights_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$HistoricalInsightsState {
  List<LiveInsightModel> get insights => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get hasMore => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  String? get sessionId => throw _privateConstructorUsedError;
  LiveInsightType? get filterType => throw _privateConstructorUsedError;
  LiveInsightPriority? get filterPriority => throw _privateConstructorUsedError;
  int get limit => throw _privateConstructorUsedError;
  int get offset => throw _privateConstructorUsedError;

  /// Create a copy of HistoricalInsightsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HistoricalInsightsStateCopyWith<HistoricalInsightsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HistoricalInsightsStateCopyWith<$Res> {
  factory $HistoricalInsightsStateCopyWith(
    HistoricalInsightsState value,
    $Res Function(HistoricalInsightsState) then,
  ) = _$HistoricalInsightsStateCopyWithImpl<$Res, HistoricalInsightsState>;
  @useResult
  $Res call({
    List<LiveInsightModel> insights,
    int total,
    bool isLoading,
    bool hasMore,
    String? error,
    String? sessionId,
    LiveInsightType? filterType,
    LiveInsightPriority? filterPriority,
    int limit,
    int offset,
  });
}

/// @nodoc
class _$HistoricalInsightsStateCopyWithImpl<
  $Res,
  $Val extends HistoricalInsightsState
>
    implements $HistoricalInsightsStateCopyWith<$Res> {
  _$HistoricalInsightsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HistoricalInsightsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? insights = null,
    Object? total = null,
    Object? isLoading = null,
    Object? hasMore = null,
    Object? error = freezed,
    Object? sessionId = freezed,
    Object? filterType = freezed,
    Object? filterPriority = freezed,
    Object? limit = null,
    Object? offset = null,
  }) {
    return _then(
      _value.copyWith(
            insights: null == insights
                ? _value.insights
                : insights // ignore: cast_nullable_to_non_nullable
                      as List<LiveInsightModel>,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as int,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasMore: null == hasMore
                ? _value.hasMore
                : hasMore // ignore: cast_nullable_to_non_nullable
                      as bool,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
            sessionId: freezed == sessionId
                ? _value.sessionId
                : sessionId // ignore: cast_nullable_to_non_nullable
                      as String?,
            filterType: freezed == filterType
                ? _value.filterType
                : filterType // ignore: cast_nullable_to_non_nullable
                      as LiveInsightType?,
            filterPriority: freezed == filterPriority
                ? _value.filterPriority
                : filterPriority // ignore: cast_nullable_to_non_nullable
                      as LiveInsightPriority?,
            limit: null == limit
                ? _value.limit
                : limit // ignore: cast_nullable_to_non_nullable
                      as int,
            offset: null == offset
                ? _value.offset
                : offset // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HistoricalInsightsStateImplCopyWith<$Res>
    implements $HistoricalInsightsStateCopyWith<$Res> {
  factory _$$HistoricalInsightsStateImplCopyWith(
    _$HistoricalInsightsStateImpl value,
    $Res Function(_$HistoricalInsightsStateImpl) then,
  ) = __$$HistoricalInsightsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<LiveInsightModel> insights,
    int total,
    bool isLoading,
    bool hasMore,
    String? error,
    String? sessionId,
    LiveInsightType? filterType,
    LiveInsightPriority? filterPriority,
    int limit,
    int offset,
  });
}

/// @nodoc
class __$$HistoricalInsightsStateImplCopyWithImpl<$Res>
    extends
        _$HistoricalInsightsStateCopyWithImpl<
          $Res,
          _$HistoricalInsightsStateImpl
        >
    implements _$$HistoricalInsightsStateImplCopyWith<$Res> {
  __$$HistoricalInsightsStateImplCopyWithImpl(
    _$HistoricalInsightsStateImpl _value,
    $Res Function(_$HistoricalInsightsStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HistoricalInsightsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? insights = null,
    Object? total = null,
    Object? isLoading = null,
    Object? hasMore = null,
    Object? error = freezed,
    Object? sessionId = freezed,
    Object? filterType = freezed,
    Object? filterPriority = freezed,
    Object? limit = null,
    Object? offset = null,
  }) {
    return _then(
      _$HistoricalInsightsStateImpl(
        insights: null == insights
            ? _value._insights
            : insights // ignore: cast_nullable_to_non_nullable
                  as List<LiveInsightModel>,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as int,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasMore: null == hasMore
            ? _value.hasMore
            : hasMore // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        sessionId: freezed == sessionId
            ? _value.sessionId
            : sessionId // ignore: cast_nullable_to_non_nullable
                  as String?,
        filterType: freezed == filterType
            ? _value.filterType
            : filterType // ignore: cast_nullable_to_non_nullable
                  as LiveInsightType?,
        filterPriority: freezed == filterPriority
            ? _value.filterPriority
            : filterPriority // ignore: cast_nullable_to_non_nullable
                  as LiveInsightPriority?,
        limit: null == limit
            ? _value.limit
            : limit // ignore: cast_nullable_to_non_nullable
                  as int,
        offset: null == offset
            ? _value.offset
            : offset // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$HistoricalInsightsStateImpl implements _HistoricalInsightsState {
  const _$HistoricalInsightsStateImpl({
    final List<LiveInsightModel> insights = const [],
    this.total = 0,
    this.isLoading = false,
    this.hasMore = false,
    this.error,
    this.sessionId,
    this.filterType,
    this.filterPriority,
    this.limit = 100,
    this.offset = 0,
  }) : _insights = insights;

  final List<LiveInsightModel> _insights;
  @override
  @JsonKey()
  List<LiveInsightModel> get insights {
    if (_insights is EqualUnmodifiableListView) return _insights;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_insights);
  }

  @override
  @JsonKey()
  final int total;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool hasMore;
  @override
  final String? error;
  @override
  final String? sessionId;
  @override
  final LiveInsightType? filterType;
  @override
  final LiveInsightPriority? filterPriority;
  @override
  @JsonKey()
  final int limit;
  @override
  @JsonKey()
  final int offset;

  @override
  String toString() {
    return 'HistoricalInsightsState(insights: $insights, total: $total, isLoading: $isLoading, hasMore: $hasMore, error: $error, sessionId: $sessionId, filterType: $filterType, filterPriority: $filterPriority, limit: $limit, offset: $offset)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HistoricalInsightsStateImpl &&
            const DeepCollectionEquality().equals(other._insights, _insights) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.filterType, filterType) ||
                other.filterType == filterType) &&
            (identical(other.filterPriority, filterPriority) ||
                other.filterPriority == filterPriority) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.offset, offset) || other.offset == offset));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_insights),
    total,
    isLoading,
    hasMore,
    error,
    sessionId,
    filterType,
    filterPriority,
    limit,
    offset,
  );

  /// Create a copy of HistoricalInsightsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HistoricalInsightsStateImplCopyWith<_$HistoricalInsightsStateImpl>
  get copyWith =>
      __$$HistoricalInsightsStateImplCopyWithImpl<
        _$HistoricalInsightsStateImpl
      >(this, _$identity);
}

abstract class _HistoricalInsightsState implements HistoricalInsightsState {
  const factory _HistoricalInsightsState({
    final List<LiveInsightModel> insights,
    final int total,
    final bool isLoading,
    final bool hasMore,
    final String? error,
    final String? sessionId,
    final LiveInsightType? filterType,
    final LiveInsightPriority? filterPriority,
    final int limit,
    final int offset,
  }) = _$HistoricalInsightsStateImpl;

  @override
  List<LiveInsightModel> get insights;
  @override
  int get total;
  @override
  bool get isLoading;
  @override
  bool get hasMore;
  @override
  String? get error;
  @override
  String? get sessionId;
  @override
  LiveInsightType? get filterType;
  @override
  LiveInsightPriority? get filterPriority;
  @override
  int get limit;
  @override
  int get offset;

  /// Create a copy of HistoricalInsightsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HistoricalInsightsStateImplCopyWith<_$HistoricalInsightsStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}
