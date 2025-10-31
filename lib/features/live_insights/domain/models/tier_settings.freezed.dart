// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tier_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TierSettings _$TierSettingsFromJson(Map<String, dynamic> json) {
  return _TierSettings.fromJson(json);
}

/// @nodoc
mixin _$TierSettings {
  // Tier enablement settings
  bool get ragEnabled => throw _privateConstructorUsedError;
  bool get meetingContextEnabled => throw _privateConstructorUsedError;
  bool get liveConversationEnabled => throw _privateConstructorUsedError;
  bool get gptGeneratedEnabled =>
      throw _privateConstructorUsedError; // Section visibility settings
  bool get showQuestionsSection => throw _privateConstructorUsedError;
  bool get showActionsSection => throw _privateConstructorUsedError;

  /// Serializes this TierSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TierSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TierSettingsCopyWith<TierSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TierSettingsCopyWith<$Res> {
  factory $TierSettingsCopyWith(
    TierSettings value,
    $Res Function(TierSettings) then,
  ) = _$TierSettingsCopyWithImpl<$Res, TierSettings>;
  @useResult
  $Res call({
    bool ragEnabled,
    bool meetingContextEnabled,
    bool liveConversationEnabled,
    bool gptGeneratedEnabled,
    bool showQuestionsSection,
    bool showActionsSection,
  });
}

/// @nodoc
class _$TierSettingsCopyWithImpl<$Res, $Val extends TierSettings>
    implements $TierSettingsCopyWith<$Res> {
  _$TierSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TierSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ragEnabled = null,
    Object? meetingContextEnabled = null,
    Object? liveConversationEnabled = null,
    Object? gptGeneratedEnabled = null,
    Object? showQuestionsSection = null,
    Object? showActionsSection = null,
  }) {
    return _then(
      _value.copyWith(
            ragEnabled: null == ragEnabled
                ? _value.ragEnabled
                : ragEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            meetingContextEnabled: null == meetingContextEnabled
                ? _value.meetingContextEnabled
                : meetingContextEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            liveConversationEnabled: null == liveConversationEnabled
                ? _value.liveConversationEnabled
                : liveConversationEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            gptGeneratedEnabled: null == gptGeneratedEnabled
                ? _value.gptGeneratedEnabled
                : gptGeneratedEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            showQuestionsSection: null == showQuestionsSection
                ? _value.showQuestionsSection
                : showQuestionsSection // ignore: cast_nullable_to_non_nullable
                      as bool,
            showActionsSection: null == showActionsSection
                ? _value.showActionsSection
                : showActionsSection // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TierSettingsImplCopyWith<$Res>
    implements $TierSettingsCopyWith<$Res> {
  factory _$$TierSettingsImplCopyWith(
    _$TierSettingsImpl value,
    $Res Function(_$TierSettingsImpl) then,
  ) = __$$TierSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool ragEnabled,
    bool meetingContextEnabled,
    bool liveConversationEnabled,
    bool gptGeneratedEnabled,
    bool showQuestionsSection,
    bool showActionsSection,
  });
}

/// @nodoc
class __$$TierSettingsImplCopyWithImpl<$Res>
    extends _$TierSettingsCopyWithImpl<$Res, _$TierSettingsImpl>
    implements _$$TierSettingsImplCopyWith<$Res> {
  __$$TierSettingsImplCopyWithImpl(
    _$TierSettingsImpl _value,
    $Res Function(_$TierSettingsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TierSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ragEnabled = null,
    Object? meetingContextEnabled = null,
    Object? liveConversationEnabled = null,
    Object? gptGeneratedEnabled = null,
    Object? showQuestionsSection = null,
    Object? showActionsSection = null,
  }) {
    return _then(
      _$TierSettingsImpl(
        ragEnabled: null == ragEnabled
            ? _value.ragEnabled
            : ragEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        meetingContextEnabled: null == meetingContextEnabled
            ? _value.meetingContextEnabled
            : meetingContextEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        liveConversationEnabled: null == liveConversationEnabled
            ? _value.liveConversationEnabled
            : liveConversationEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        gptGeneratedEnabled: null == gptGeneratedEnabled
            ? _value.gptGeneratedEnabled
            : gptGeneratedEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        showQuestionsSection: null == showQuestionsSection
            ? _value.showQuestionsSection
            : showQuestionsSection // ignore: cast_nullable_to_non_nullable
                  as bool,
        showActionsSection: null == showActionsSection
            ? _value.showActionsSection
            : showActionsSection // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TierSettingsImpl with DiagnosticableTreeMixin implements _TierSettings {
  const _$TierSettingsImpl({
    this.ragEnabled = true,
    this.meetingContextEnabled = true,
    this.liveConversationEnabled = true,
    this.gptGeneratedEnabled = true,
    this.showQuestionsSection = true,
    this.showActionsSection = true,
  });

  factory _$TierSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$TierSettingsImplFromJson(json);

  // Tier enablement settings
  @override
  @JsonKey()
  final bool ragEnabled;
  @override
  @JsonKey()
  final bool meetingContextEnabled;
  @override
  @JsonKey()
  final bool liveConversationEnabled;
  @override
  @JsonKey()
  final bool gptGeneratedEnabled;
  // Section visibility settings
  @override
  @JsonKey()
  final bool showQuestionsSection;
  @override
  @JsonKey()
  final bool showActionsSection;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'TierSettings(ragEnabled: $ragEnabled, meetingContextEnabled: $meetingContextEnabled, liveConversationEnabled: $liveConversationEnabled, gptGeneratedEnabled: $gptGeneratedEnabled, showQuestionsSection: $showQuestionsSection, showActionsSection: $showActionsSection)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'TierSettings'))
      ..add(DiagnosticsProperty('ragEnabled', ragEnabled))
      ..add(DiagnosticsProperty('meetingContextEnabled', meetingContextEnabled))
      ..add(
        DiagnosticsProperty('liveConversationEnabled', liveConversationEnabled),
      )
      ..add(DiagnosticsProperty('gptGeneratedEnabled', gptGeneratedEnabled))
      ..add(DiagnosticsProperty('showQuestionsSection', showQuestionsSection))
      ..add(DiagnosticsProperty('showActionsSection', showActionsSection));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TierSettingsImpl &&
            (identical(other.ragEnabled, ragEnabled) ||
                other.ragEnabled == ragEnabled) &&
            (identical(other.meetingContextEnabled, meetingContextEnabled) ||
                other.meetingContextEnabled == meetingContextEnabled) &&
            (identical(
                  other.liveConversationEnabled,
                  liveConversationEnabled,
                ) ||
                other.liveConversationEnabled == liveConversationEnabled) &&
            (identical(other.gptGeneratedEnabled, gptGeneratedEnabled) ||
                other.gptGeneratedEnabled == gptGeneratedEnabled) &&
            (identical(other.showQuestionsSection, showQuestionsSection) ||
                other.showQuestionsSection == showQuestionsSection) &&
            (identical(other.showActionsSection, showActionsSection) ||
                other.showActionsSection == showActionsSection));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    ragEnabled,
    meetingContextEnabled,
    liveConversationEnabled,
    gptGeneratedEnabled,
    showQuestionsSection,
    showActionsSection,
  );

  /// Create a copy of TierSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TierSettingsImplCopyWith<_$TierSettingsImpl> get copyWith =>
      __$$TierSettingsImplCopyWithImpl<_$TierSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TierSettingsImplToJson(this);
  }
}

abstract class _TierSettings implements TierSettings {
  const factory _TierSettings({
    final bool ragEnabled,
    final bool meetingContextEnabled,
    final bool liveConversationEnabled,
    final bool gptGeneratedEnabled,
    final bool showQuestionsSection,
    final bool showActionsSection,
  }) = _$TierSettingsImpl;

  factory _TierSettings.fromJson(Map<String, dynamic> json) =
      _$TierSettingsImpl.fromJson;

  // Tier enablement settings
  @override
  bool get ragEnabled;
  @override
  bool get meetingContextEnabled;
  @override
  bool get liveConversationEnabled;
  @override
  bool get gptGeneratedEnabled; // Section visibility settings
  @override
  bool get showQuestionsSection;
  @override
  bool get showActionsSection;

  /// Create a copy of TierSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TierSettingsImplCopyWith<_$TierSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
