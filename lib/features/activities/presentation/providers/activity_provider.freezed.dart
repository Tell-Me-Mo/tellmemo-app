// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activity_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ActivityState {
  List<Activity> get activities => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isPolling => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  ActivityType? get filterType => throw _privateConstructorUsedError;
  int get pollingInterval => throw _privateConstructorUsedError;

  /// Create a copy of ActivityState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActivityStateCopyWith<ActivityState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActivityStateCopyWith<$Res> {
  factory $ActivityStateCopyWith(
    ActivityState value,
    $Res Function(ActivityState) then,
  ) = _$ActivityStateCopyWithImpl<$Res, ActivityState>;
  @useResult
  $Res call({
    List<Activity> activities,
    bool isLoading,
    bool isPolling,
    String? error,
    ActivityType? filterType,
    int pollingInterval,
  });
}

/// @nodoc
class _$ActivityStateCopyWithImpl<$Res, $Val extends ActivityState>
    implements $ActivityStateCopyWith<$Res> {
  _$ActivityStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActivityState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activities = null,
    Object? isLoading = null,
    Object? isPolling = null,
    Object? error = freezed,
    Object? filterType = freezed,
    Object? pollingInterval = null,
  }) {
    return _then(
      _value.copyWith(
            activities: null == activities
                ? _value.activities
                : activities // ignore: cast_nullable_to_non_nullable
                      as List<Activity>,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            isPolling: null == isPolling
                ? _value.isPolling
                : isPolling // ignore: cast_nullable_to_non_nullable
                      as bool,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
            filterType: freezed == filterType
                ? _value.filterType
                : filterType // ignore: cast_nullable_to_non_nullable
                      as ActivityType?,
            pollingInterval: null == pollingInterval
                ? _value.pollingInterval
                : pollingInterval // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ActivityStateImplCopyWith<$Res>
    implements $ActivityStateCopyWith<$Res> {
  factory _$$ActivityStateImplCopyWith(
    _$ActivityStateImpl value,
    $Res Function(_$ActivityStateImpl) then,
  ) = __$$ActivityStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Activity> activities,
    bool isLoading,
    bool isPolling,
    String? error,
    ActivityType? filterType,
    int pollingInterval,
  });
}

/// @nodoc
class __$$ActivityStateImplCopyWithImpl<$Res>
    extends _$ActivityStateCopyWithImpl<$Res, _$ActivityStateImpl>
    implements _$$ActivityStateImplCopyWith<$Res> {
  __$$ActivityStateImplCopyWithImpl(
    _$ActivityStateImpl _value,
    $Res Function(_$ActivityStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ActivityState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activities = null,
    Object? isLoading = null,
    Object? isPolling = null,
    Object? error = freezed,
    Object? filterType = freezed,
    Object? pollingInterval = null,
  }) {
    return _then(
      _$ActivityStateImpl(
        activities: null == activities
            ? _value._activities
            : activities // ignore: cast_nullable_to_non_nullable
                  as List<Activity>,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        isPolling: null == isPolling
            ? _value.isPolling
            : isPolling // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        filterType: freezed == filterType
            ? _value.filterType
            : filterType // ignore: cast_nullable_to_non_nullable
                  as ActivityType?,
        pollingInterval: null == pollingInterval
            ? _value.pollingInterval
            : pollingInterval // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$ActivityStateImpl implements _ActivityState {
  const _$ActivityStateImpl({
    final List<Activity> activities = const [],
    this.isLoading = false,
    this.isPolling = false,
    this.error,
    this.filterType,
    this.pollingInterval = 30,
  }) : _activities = activities;

  final List<Activity> _activities;
  @override
  @JsonKey()
  List<Activity> get activities {
    if (_activities is EqualUnmodifiableListView) return _activities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_activities);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isPolling;
  @override
  final String? error;
  @override
  final ActivityType? filterType;
  @override
  @JsonKey()
  final int pollingInterval;

  @override
  String toString() {
    return 'ActivityState(activities: $activities, isLoading: $isLoading, isPolling: $isPolling, error: $error, filterType: $filterType, pollingInterval: $pollingInterval)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActivityStateImpl &&
            const DeepCollectionEquality().equals(
              other._activities,
              _activities,
            ) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isPolling, isPolling) ||
                other.isPolling == isPolling) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.filterType, filterType) ||
                other.filterType == filterType) &&
            (identical(other.pollingInterval, pollingInterval) ||
                other.pollingInterval == pollingInterval));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_activities),
    isLoading,
    isPolling,
    error,
    filterType,
    pollingInterval,
  );

  /// Create a copy of ActivityState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActivityStateImplCopyWith<_$ActivityStateImpl> get copyWith =>
      __$$ActivityStateImplCopyWithImpl<_$ActivityStateImpl>(this, _$identity);
}

abstract class _ActivityState implements ActivityState {
  const factory _ActivityState({
    final List<Activity> activities,
    final bool isLoading,
    final bool isPolling,
    final String? error,
    final ActivityType? filterType,
    final int pollingInterval,
  }) = _$ActivityStateImpl;

  @override
  List<Activity> get activities;
  @override
  bool get isLoading;
  @override
  bool get isPolling;
  @override
  String? get error;
  @override
  ActivityType? get filterType;
  @override
  int get pollingInterval;

  /// Create a copy of ActivityState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActivityStateImplCopyWith<_$ActivityStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
