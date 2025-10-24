// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_insights_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LiveInsightsSettings _$LiveInsightsSettingsFromJson(Map<String, dynamic> json) {
  return _LiveInsightsSettings.fromJson(json);
}

/// @nodoc
mixin _$LiveInsightsSettings {
  /// Set of enabled proactive assistance types (AI suggestions)
  Set<ProactiveAssistanceType> get enabledPhases =>
      throw _privateConstructorUsedError;

  /// Set of enabled insight types (extracted data)
  Set<LiveInsightType> get enabledInsightTypes =>
      throw _privateConstructorUsedError;

  /// Quiet mode - only show critical alerts
  bool get quietMode => throw _privateConstructorUsedError;

  /// Show collapsed items by default (medium confidence)
  bool get showCollapsedItems => throw _privateConstructorUsedError;

  /// Enable feedback collection
  bool get enableFeedback => throw _privateConstructorUsedError;

  /// Auto-expand high confidence items
  bool get autoExpandHighConfidence => throw _privateConstructorUsedError;

  /// Serializes this LiveInsightsSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LiveInsightsSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LiveInsightsSettingsCopyWith<LiveInsightsSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LiveInsightsSettingsCopyWith<$Res> {
  factory $LiveInsightsSettingsCopyWith(
    LiveInsightsSettings value,
    $Res Function(LiveInsightsSettings) then,
  ) = _$LiveInsightsSettingsCopyWithImpl<$Res, LiveInsightsSettings>;
  @useResult
  $Res call({
    Set<ProactiveAssistanceType> enabledPhases,
    Set<LiveInsightType> enabledInsightTypes,
    bool quietMode,
    bool showCollapsedItems,
    bool enableFeedback,
    bool autoExpandHighConfidence,
  });
}

/// @nodoc
class _$LiveInsightsSettingsCopyWithImpl<
  $Res,
  $Val extends LiveInsightsSettings
>
    implements $LiveInsightsSettingsCopyWith<$Res> {
  _$LiveInsightsSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LiveInsightsSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabledPhases = null,
    Object? enabledInsightTypes = null,
    Object? quietMode = null,
    Object? showCollapsedItems = null,
    Object? enableFeedback = null,
    Object? autoExpandHighConfidence = null,
  }) {
    return _then(
      _value.copyWith(
            enabledPhases: null == enabledPhases
                ? _value.enabledPhases
                : enabledPhases // ignore: cast_nullable_to_non_nullable
                      as Set<ProactiveAssistanceType>,
            enabledInsightTypes: null == enabledInsightTypes
                ? _value.enabledInsightTypes
                : enabledInsightTypes // ignore: cast_nullable_to_non_nullable
                      as Set<LiveInsightType>,
            quietMode: null == quietMode
                ? _value.quietMode
                : quietMode // ignore: cast_nullable_to_non_nullable
                      as bool,
            showCollapsedItems: null == showCollapsedItems
                ? _value.showCollapsedItems
                : showCollapsedItems // ignore: cast_nullable_to_non_nullable
                      as bool,
            enableFeedback: null == enableFeedback
                ? _value.enableFeedback
                : enableFeedback // ignore: cast_nullable_to_non_nullable
                      as bool,
            autoExpandHighConfidence: null == autoExpandHighConfidence
                ? _value.autoExpandHighConfidence
                : autoExpandHighConfidence // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LiveInsightsSettingsImplCopyWith<$Res>
    implements $LiveInsightsSettingsCopyWith<$Res> {
  factory _$$LiveInsightsSettingsImplCopyWith(
    _$LiveInsightsSettingsImpl value,
    $Res Function(_$LiveInsightsSettingsImpl) then,
  ) = __$$LiveInsightsSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Set<ProactiveAssistanceType> enabledPhases,
    Set<LiveInsightType> enabledInsightTypes,
    bool quietMode,
    bool showCollapsedItems,
    bool enableFeedback,
    bool autoExpandHighConfidence,
  });
}

/// @nodoc
class __$$LiveInsightsSettingsImplCopyWithImpl<$Res>
    extends _$LiveInsightsSettingsCopyWithImpl<$Res, _$LiveInsightsSettingsImpl>
    implements _$$LiveInsightsSettingsImplCopyWith<$Res> {
  __$$LiveInsightsSettingsImplCopyWithImpl(
    _$LiveInsightsSettingsImpl _value,
    $Res Function(_$LiveInsightsSettingsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LiveInsightsSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabledPhases = null,
    Object? enabledInsightTypes = null,
    Object? quietMode = null,
    Object? showCollapsedItems = null,
    Object? enableFeedback = null,
    Object? autoExpandHighConfidence = null,
  }) {
    return _then(
      _$LiveInsightsSettingsImpl(
        enabledPhases: null == enabledPhases
            ? _value._enabledPhases
            : enabledPhases // ignore: cast_nullable_to_non_nullable
                  as Set<ProactiveAssistanceType>,
        enabledInsightTypes: null == enabledInsightTypes
            ? _value._enabledInsightTypes
            : enabledInsightTypes // ignore: cast_nullable_to_non_nullable
                  as Set<LiveInsightType>,
        quietMode: null == quietMode
            ? _value.quietMode
            : quietMode // ignore: cast_nullable_to_non_nullable
                  as bool,
        showCollapsedItems: null == showCollapsedItems
            ? _value.showCollapsedItems
            : showCollapsedItems // ignore: cast_nullable_to_non_nullable
                  as bool,
        enableFeedback: null == enableFeedback
            ? _value.enableFeedback
            : enableFeedback // ignore: cast_nullable_to_non_nullable
                  as bool,
        autoExpandHighConfidence: null == autoExpandHighConfidence
            ? _value.autoExpandHighConfidence
            : autoExpandHighConfidence // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LiveInsightsSettingsImpl extends _LiveInsightsSettings {
  const _$LiveInsightsSettingsImpl({
    final Set<ProactiveAssistanceType> enabledPhases = const {
      ProactiveAssistanceType.autoAnswer,
      ProactiveAssistanceType.conflictDetected,
      ProactiveAssistanceType.incompleteActionItem,
    },
    final Set<LiveInsightType> enabledInsightTypes = const {
      LiveInsightType.decision,
      LiveInsightType.risk,
    },
    this.quietMode = false,
    this.showCollapsedItems = true,
    this.enableFeedback = true,
    this.autoExpandHighConfidence = true,
  }) : _enabledPhases = enabledPhases,
       _enabledInsightTypes = enabledInsightTypes,
       super._();

  factory _$LiveInsightsSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$LiveInsightsSettingsImplFromJson(json);

  /// Set of enabled proactive assistance types (AI suggestions)
  final Set<ProactiveAssistanceType> _enabledPhases;

  /// Set of enabled proactive assistance types (AI suggestions)
  @override
  @JsonKey()
  Set<ProactiveAssistanceType> get enabledPhases {
    if (_enabledPhases is EqualUnmodifiableSetView) return _enabledPhases;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_enabledPhases);
  }

  /// Set of enabled insight types (extracted data)
  final Set<LiveInsightType> _enabledInsightTypes;

  /// Set of enabled insight types (extracted data)
  @override
  @JsonKey()
  Set<LiveInsightType> get enabledInsightTypes {
    if (_enabledInsightTypes is EqualUnmodifiableSetView)
      return _enabledInsightTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_enabledInsightTypes);
  }

  /// Quiet mode - only show critical alerts
  @override
  @JsonKey()
  final bool quietMode;

  /// Show collapsed items by default (medium confidence)
  @override
  @JsonKey()
  final bool showCollapsedItems;

  /// Enable feedback collection
  @override
  @JsonKey()
  final bool enableFeedback;

  /// Auto-expand high confidence items
  @override
  @JsonKey()
  final bool autoExpandHighConfidence;

  @override
  String toString() {
    return 'LiveInsightsSettings(enabledPhases: $enabledPhases, enabledInsightTypes: $enabledInsightTypes, quietMode: $quietMode, showCollapsedItems: $showCollapsedItems, enableFeedback: $enableFeedback, autoExpandHighConfidence: $autoExpandHighConfidence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LiveInsightsSettingsImpl &&
            const DeepCollectionEquality().equals(
              other._enabledPhases,
              _enabledPhases,
            ) &&
            const DeepCollectionEquality().equals(
              other._enabledInsightTypes,
              _enabledInsightTypes,
            ) &&
            (identical(other.quietMode, quietMode) ||
                other.quietMode == quietMode) &&
            (identical(other.showCollapsedItems, showCollapsedItems) ||
                other.showCollapsedItems == showCollapsedItems) &&
            (identical(other.enableFeedback, enableFeedback) ||
                other.enableFeedback == enableFeedback) &&
            (identical(
                  other.autoExpandHighConfidence,
                  autoExpandHighConfidence,
                ) ||
                other.autoExpandHighConfidence == autoExpandHighConfidence));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_enabledPhases),
    const DeepCollectionEquality().hash(_enabledInsightTypes),
    quietMode,
    showCollapsedItems,
    enableFeedback,
    autoExpandHighConfidence,
  );

  /// Create a copy of LiveInsightsSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LiveInsightsSettingsImplCopyWith<_$LiveInsightsSettingsImpl>
  get copyWith =>
      __$$LiveInsightsSettingsImplCopyWithImpl<_$LiveInsightsSettingsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$LiveInsightsSettingsImplToJson(this);
  }
}

abstract class _LiveInsightsSettings extends LiveInsightsSettings {
  const factory _LiveInsightsSettings({
    final Set<ProactiveAssistanceType> enabledPhases,
    final Set<LiveInsightType> enabledInsightTypes,
    final bool quietMode,
    final bool showCollapsedItems,
    final bool enableFeedback,
    final bool autoExpandHighConfidence,
  }) = _$LiveInsightsSettingsImpl;
  const _LiveInsightsSettings._() : super._();

  factory _LiveInsightsSettings.fromJson(Map<String, dynamic> json) =
      _$LiveInsightsSettingsImpl.fromJson;

  /// Set of enabled proactive assistance types (AI suggestions)
  @override
  Set<ProactiveAssistanceType> get enabledPhases;

  /// Set of enabled insight types (extracted data)
  @override
  Set<LiveInsightType> get enabledInsightTypes;

  /// Quiet mode - only show critical alerts
  @override
  bool get quietMode;

  /// Show collapsed items by default (medium confidence)
  @override
  bool get showCollapsedItems;

  /// Enable feedback collection
  @override
  bool get enableFeedback;

  /// Auto-expand high confidence items
  @override
  bool get autoExpandHighConfidence;

  /// Create a copy of LiveInsightsSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LiveInsightsSettingsImplCopyWith<_$LiveInsightsSettingsImpl>
  get copyWith => throw _privateConstructorUsedError;
}
