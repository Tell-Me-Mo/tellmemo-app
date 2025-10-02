// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content_status_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ContentStatusState {
  bool get isPolling => throw _privateConstructorUsedError;
  ContentStatusModel? get status => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  Timer? get pollingTimer => throw _privateConstructorUsedError;

  /// Create a copy of ContentStatusState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ContentStatusStateCopyWith<ContentStatusState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContentStatusStateCopyWith<$Res> {
  factory $ContentStatusStateCopyWith(
    ContentStatusState value,
    $Res Function(ContentStatusState) then,
  ) = _$ContentStatusStateCopyWithImpl<$Res, ContentStatusState>;
  @useResult
  $Res call({
    bool isPolling,
    ContentStatusModel? status,
    String? error,
    Timer? pollingTimer,
  });

  $ContentStatusModelCopyWith<$Res>? get status;
}

/// @nodoc
class _$ContentStatusStateCopyWithImpl<$Res, $Val extends ContentStatusState>
    implements $ContentStatusStateCopyWith<$Res> {
  _$ContentStatusStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContentStatusState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isPolling = null,
    Object? status = freezed,
    Object? error = freezed,
    Object? pollingTimer = freezed,
  }) {
    return _then(
      _value.copyWith(
            isPolling: null == isPolling
                ? _value.isPolling
                : isPolling // ignore: cast_nullable_to_non_nullable
                      as bool,
            status: freezed == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ContentStatusModel?,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
            pollingTimer: freezed == pollingTimer
                ? _value.pollingTimer
                : pollingTimer // ignore: cast_nullable_to_non_nullable
                      as Timer?,
          )
          as $Val,
    );
  }

  /// Create a copy of ContentStatusState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ContentStatusModelCopyWith<$Res>? get status {
    if (_value.status == null) {
      return null;
    }

    return $ContentStatusModelCopyWith<$Res>(_value.status!, (value) {
      return _then(_value.copyWith(status: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ContentStatusStateImplCopyWith<$Res>
    implements $ContentStatusStateCopyWith<$Res> {
  factory _$$ContentStatusStateImplCopyWith(
    _$ContentStatusStateImpl value,
    $Res Function(_$ContentStatusStateImpl) then,
  ) = __$$ContentStatusStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isPolling,
    ContentStatusModel? status,
    String? error,
    Timer? pollingTimer,
  });

  @override
  $ContentStatusModelCopyWith<$Res>? get status;
}

/// @nodoc
class __$$ContentStatusStateImplCopyWithImpl<$Res>
    extends _$ContentStatusStateCopyWithImpl<$Res, _$ContentStatusStateImpl>
    implements _$$ContentStatusStateImplCopyWith<$Res> {
  __$$ContentStatusStateImplCopyWithImpl(
    _$ContentStatusStateImpl _value,
    $Res Function(_$ContentStatusStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentStatusState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isPolling = null,
    Object? status = freezed,
    Object? error = freezed,
    Object? pollingTimer = freezed,
  }) {
    return _then(
      _$ContentStatusStateImpl(
        isPolling: null == isPolling
            ? _value.isPolling
            : isPolling // ignore: cast_nullable_to_non_nullable
                  as bool,
        status: freezed == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ContentStatusModel?,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        pollingTimer: freezed == pollingTimer
            ? _value.pollingTimer
            : pollingTimer // ignore: cast_nullable_to_non_nullable
                  as Timer?,
      ),
    );
  }
}

/// @nodoc

class _$ContentStatusStateImpl implements _ContentStatusState {
  const _$ContentStatusStateImpl({
    this.isPolling = false,
    this.status = null,
    this.error = null,
    this.pollingTimer = null,
  });

  @override
  @JsonKey()
  final bool isPolling;
  @override
  @JsonKey()
  final ContentStatusModel? status;
  @override
  @JsonKey()
  final String? error;
  @override
  @JsonKey()
  final Timer? pollingTimer;

  @override
  String toString() {
    return 'ContentStatusState(isPolling: $isPolling, status: $status, error: $error, pollingTimer: $pollingTimer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContentStatusStateImpl &&
            (identical(other.isPolling, isPolling) ||
                other.isPolling == isPolling) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.pollingTimer, pollingTimer) ||
                other.pollingTimer == pollingTimer));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, isPolling, status, error, pollingTimer);

  /// Create a copy of ContentStatusState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ContentStatusStateImplCopyWith<_$ContentStatusStateImpl> get copyWith =>
      __$$ContentStatusStateImplCopyWithImpl<_$ContentStatusStateImpl>(
        this,
        _$identity,
      );
}

abstract class _ContentStatusState implements ContentStatusState {
  const factory _ContentStatusState({
    final bool isPolling,
    final ContentStatusModel? status,
    final String? error,
    final Timer? pollingTimer,
  }) = _$ContentStatusStateImpl;

  @override
  bool get isPolling;
  @override
  ContentStatusModel? get status;
  @override
  String? get error;
  @override
  Timer? get pollingTimer;

  /// Create a copy of ContentStatusState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ContentStatusStateImplCopyWith<_$ContentStatusStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
