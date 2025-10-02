// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'integration.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Integration _$IntegrationFromJson(Map<String, dynamic> json) {
  return _Integration.fromJson(json);
}

/// @nodoc
mixin _$Integration {
  String get id => throw _privateConstructorUsedError;
  IntegrationType get type => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get iconUrl => throw _privateConstructorUsedError;
  IntegrationStatus get status => throw _privateConstructorUsedError;
  Map<String, dynamic>? get configuration => throw _privateConstructorUsedError;
  DateTime? get connectedAt => throw _privateConstructorUsedError;
  DateTime? get lastSyncAt => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  /// Serializes this Integration to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Integration
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IntegrationCopyWith<Integration> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IntegrationCopyWith<$Res> {
  factory $IntegrationCopyWith(
    Integration value,
    $Res Function(Integration) then,
  ) = _$IntegrationCopyWithImpl<$Res, Integration>;
  @useResult
  $Res call({
    String id,
    IntegrationType type,
    String name,
    String description,
    String iconUrl,
    IntegrationStatus status,
    Map<String, dynamic>? configuration,
    DateTime? connectedAt,
    DateTime? lastSyncAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  });
}

/// @nodoc
class _$IntegrationCopyWithImpl<$Res, $Val extends Integration>
    implements $IntegrationCopyWith<$Res> {
  _$IntegrationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Integration
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? name = null,
    Object? description = null,
    Object? iconUrl = null,
    Object? status = null,
    Object? configuration = freezed,
    Object? connectedAt = freezed,
    Object? lastSyncAt = freezed,
    Object? errorMessage = freezed,
    Object? metadata = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as IntegrationType,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            iconUrl: null == iconUrl
                ? _value.iconUrl
                : iconUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as IntegrationStatus,
            configuration: freezed == configuration
                ? _value.configuration
                : configuration // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            connectedAt: freezed == connectedAt
                ? _value.connectedAt
                : connectedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            lastSyncAt: freezed == lastSyncAt
                ? _value.lastSyncAt
                : lastSyncAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
            metadata: freezed == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$IntegrationImplCopyWith<$Res>
    implements $IntegrationCopyWith<$Res> {
  factory _$$IntegrationImplCopyWith(
    _$IntegrationImpl value,
    $Res Function(_$IntegrationImpl) then,
  ) = __$$IntegrationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    IntegrationType type,
    String name,
    String description,
    String iconUrl,
    IntegrationStatus status,
    Map<String, dynamic>? configuration,
    DateTime? connectedAt,
    DateTime? lastSyncAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  });
}

/// @nodoc
class __$$IntegrationImplCopyWithImpl<$Res>
    extends _$IntegrationCopyWithImpl<$Res, _$IntegrationImpl>
    implements _$$IntegrationImplCopyWith<$Res> {
  __$$IntegrationImplCopyWithImpl(
    _$IntegrationImpl _value,
    $Res Function(_$IntegrationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Integration
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? name = null,
    Object? description = null,
    Object? iconUrl = null,
    Object? status = null,
    Object? configuration = freezed,
    Object? connectedAt = freezed,
    Object? lastSyncAt = freezed,
    Object? errorMessage = freezed,
    Object? metadata = freezed,
  }) {
    return _then(
      _$IntegrationImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as IntegrationType,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        iconUrl: null == iconUrl
            ? _value.iconUrl
            : iconUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as IntegrationStatus,
        configuration: freezed == configuration
            ? _value._configuration
            : configuration // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        connectedAt: freezed == connectedAt
            ? _value.connectedAt
            : connectedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastSyncAt: freezed == lastSyncAt
            ? _value.lastSyncAt
            : lastSyncAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        metadata: freezed == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$IntegrationImpl implements _Integration {
  const _$IntegrationImpl({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.status,
    final Map<String, dynamic>? configuration,
    this.connectedAt,
    this.lastSyncAt,
    this.errorMessage,
    final Map<String, dynamic>? metadata,
  }) : _configuration = configuration,
       _metadata = metadata;

  factory _$IntegrationImpl.fromJson(Map<String, dynamic> json) =>
      _$$IntegrationImplFromJson(json);

  @override
  final String id;
  @override
  final IntegrationType type;
  @override
  final String name;
  @override
  final String description;
  @override
  final String iconUrl;
  @override
  final IntegrationStatus status;
  final Map<String, dynamic>? _configuration;
  @override
  Map<String, dynamic>? get configuration {
    final value = _configuration;
    if (value == null) return null;
    if (_configuration is EqualUnmodifiableMapView) return _configuration;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final DateTime? connectedAt;
  @override
  final DateTime? lastSyncAt;
  @override
  final String? errorMessage;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'Integration(id: $id, type: $type, name: $name, description: $description, iconUrl: $iconUrl, status: $status, configuration: $configuration, connectedAt: $connectedAt, lastSyncAt: $lastSyncAt, errorMessage: $errorMessage, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IntegrationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(
              other._configuration,
              _configuration,
            ) &&
            (identical(other.connectedAt, connectedAt) ||
                other.connectedAt == connectedAt) &&
            (identical(other.lastSyncAt, lastSyncAt) ||
                other.lastSyncAt == lastSyncAt) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    type,
    name,
    description,
    iconUrl,
    status,
    const DeepCollectionEquality().hash(_configuration),
    connectedAt,
    lastSyncAt,
    errorMessage,
    const DeepCollectionEquality().hash(_metadata),
  );

  /// Create a copy of Integration
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IntegrationImplCopyWith<_$IntegrationImpl> get copyWith =>
      __$$IntegrationImplCopyWithImpl<_$IntegrationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IntegrationImplToJson(this);
  }
}

abstract class _Integration implements Integration {
  const factory _Integration({
    required final String id,
    required final IntegrationType type,
    required final String name,
    required final String description,
    required final String iconUrl,
    required final IntegrationStatus status,
    final Map<String, dynamic>? configuration,
    final DateTime? connectedAt,
    final DateTime? lastSyncAt,
    final String? errorMessage,
    final Map<String, dynamic>? metadata,
  }) = _$IntegrationImpl;

  factory _Integration.fromJson(Map<String, dynamic> json) =
      _$IntegrationImpl.fromJson;

  @override
  String get id;
  @override
  IntegrationType get type;
  @override
  String get name;
  @override
  String get description;
  @override
  String get iconUrl;
  @override
  IntegrationStatus get status;
  @override
  Map<String, dynamic>? get configuration;
  @override
  DateTime? get connectedAt;
  @override
  DateTime? get lastSyncAt;
  @override
  String? get errorMessage;
  @override
  Map<String, dynamic>? get metadata;

  /// Create a copy of Integration
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IntegrationImplCopyWith<_$IntegrationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

IntegrationConfig _$IntegrationConfigFromJson(Map<String, dynamic> json) {
  return _IntegrationConfig.fromJson(json);
}

/// @nodoc
mixin _$IntegrationConfig {
  String get integrationId => throw _privateConstructorUsedError;
  IntegrationType get type => throw _privateConstructorUsedError;
  String? get apiKey => throw _privateConstructorUsedError;
  String? get apiSecret => throw _privateConstructorUsedError;
  String? get webhookUrl => throw _privateConstructorUsedError;
  String? get webhookSecret => throw _privateConstructorUsedError;
  Map<String, String>? get customSettings => throw _privateConstructorUsedError;
  bool? get autoSync => throw _privateConstructorUsedError;
  int? get syncIntervalMinutes => throw _privateConstructorUsedError;
  List<String>? get allowedProjects => throw _privateConstructorUsedError;

  /// Serializes this IntegrationConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IntegrationConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IntegrationConfigCopyWith<IntegrationConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IntegrationConfigCopyWith<$Res> {
  factory $IntegrationConfigCopyWith(
    IntegrationConfig value,
    $Res Function(IntegrationConfig) then,
  ) = _$IntegrationConfigCopyWithImpl<$Res, IntegrationConfig>;
  @useResult
  $Res call({
    String integrationId,
    IntegrationType type,
    String? apiKey,
    String? apiSecret,
    String? webhookUrl,
    String? webhookSecret,
    Map<String, String>? customSettings,
    bool? autoSync,
    int? syncIntervalMinutes,
    List<String>? allowedProjects,
  });
}

/// @nodoc
class _$IntegrationConfigCopyWithImpl<$Res, $Val extends IntegrationConfig>
    implements $IntegrationConfigCopyWith<$Res> {
  _$IntegrationConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IntegrationConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? integrationId = null,
    Object? type = null,
    Object? apiKey = freezed,
    Object? apiSecret = freezed,
    Object? webhookUrl = freezed,
    Object? webhookSecret = freezed,
    Object? customSettings = freezed,
    Object? autoSync = freezed,
    Object? syncIntervalMinutes = freezed,
    Object? allowedProjects = freezed,
  }) {
    return _then(
      _value.copyWith(
            integrationId: null == integrationId
                ? _value.integrationId
                : integrationId // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as IntegrationType,
            apiKey: freezed == apiKey
                ? _value.apiKey
                : apiKey // ignore: cast_nullable_to_non_nullable
                      as String?,
            apiSecret: freezed == apiSecret
                ? _value.apiSecret
                : apiSecret // ignore: cast_nullable_to_non_nullable
                      as String?,
            webhookUrl: freezed == webhookUrl
                ? _value.webhookUrl
                : webhookUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            webhookSecret: freezed == webhookSecret
                ? _value.webhookSecret
                : webhookSecret // ignore: cast_nullable_to_non_nullable
                      as String?,
            customSettings: freezed == customSettings
                ? _value.customSettings
                : customSettings // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>?,
            autoSync: freezed == autoSync
                ? _value.autoSync
                : autoSync // ignore: cast_nullable_to_non_nullable
                      as bool?,
            syncIntervalMinutes: freezed == syncIntervalMinutes
                ? _value.syncIntervalMinutes
                : syncIntervalMinutes // ignore: cast_nullable_to_non_nullable
                      as int?,
            allowedProjects: freezed == allowedProjects
                ? _value.allowedProjects
                : allowedProjects // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$IntegrationConfigImplCopyWith<$Res>
    implements $IntegrationConfigCopyWith<$Res> {
  factory _$$IntegrationConfigImplCopyWith(
    _$IntegrationConfigImpl value,
    $Res Function(_$IntegrationConfigImpl) then,
  ) = __$$IntegrationConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String integrationId,
    IntegrationType type,
    String? apiKey,
    String? apiSecret,
    String? webhookUrl,
    String? webhookSecret,
    Map<String, String>? customSettings,
    bool? autoSync,
    int? syncIntervalMinutes,
    List<String>? allowedProjects,
  });
}

/// @nodoc
class __$$IntegrationConfigImplCopyWithImpl<$Res>
    extends _$IntegrationConfigCopyWithImpl<$Res, _$IntegrationConfigImpl>
    implements _$$IntegrationConfigImplCopyWith<$Res> {
  __$$IntegrationConfigImplCopyWithImpl(
    _$IntegrationConfigImpl _value,
    $Res Function(_$IntegrationConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of IntegrationConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? integrationId = null,
    Object? type = null,
    Object? apiKey = freezed,
    Object? apiSecret = freezed,
    Object? webhookUrl = freezed,
    Object? webhookSecret = freezed,
    Object? customSettings = freezed,
    Object? autoSync = freezed,
    Object? syncIntervalMinutes = freezed,
    Object? allowedProjects = freezed,
  }) {
    return _then(
      _$IntegrationConfigImpl(
        integrationId: null == integrationId
            ? _value.integrationId
            : integrationId // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as IntegrationType,
        apiKey: freezed == apiKey
            ? _value.apiKey
            : apiKey // ignore: cast_nullable_to_non_nullable
                  as String?,
        apiSecret: freezed == apiSecret
            ? _value.apiSecret
            : apiSecret // ignore: cast_nullable_to_non_nullable
                  as String?,
        webhookUrl: freezed == webhookUrl
            ? _value.webhookUrl
            : webhookUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        webhookSecret: freezed == webhookSecret
            ? _value.webhookSecret
            : webhookSecret // ignore: cast_nullable_to_non_nullable
                  as String?,
        customSettings: freezed == customSettings
            ? _value._customSettings
            : customSettings // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>?,
        autoSync: freezed == autoSync
            ? _value.autoSync
            : autoSync // ignore: cast_nullable_to_non_nullable
                  as bool?,
        syncIntervalMinutes: freezed == syncIntervalMinutes
            ? _value.syncIntervalMinutes
            : syncIntervalMinutes // ignore: cast_nullable_to_non_nullable
                  as int?,
        allowedProjects: freezed == allowedProjects
            ? _value._allowedProjects
            : allowedProjects // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$IntegrationConfigImpl implements _IntegrationConfig {
  const _$IntegrationConfigImpl({
    required this.integrationId,
    required this.type,
    this.apiKey,
    this.apiSecret,
    this.webhookUrl,
    this.webhookSecret,
    final Map<String, String>? customSettings,
    this.autoSync,
    this.syncIntervalMinutes,
    final List<String>? allowedProjects,
  }) : _customSettings = customSettings,
       _allowedProjects = allowedProjects;

  factory _$IntegrationConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$IntegrationConfigImplFromJson(json);

  @override
  final String integrationId;
  @override
  final IntegrationType type;
  @override
  final String? apiKey;
  @override
  final String? apiSecret;
  @override
  final String? webhookUrl;
  @override
  final String? webhookSecret;
  final Map<String, String>? _customSettings;
  @override
  Map<String, String>? get customSettings {
    final value = _customSettings;
    if (value == null) return null;
    if (_customSettings is EqualUnmodifiableMapView) return _customSettings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final bool? autoSync;
  @override
  final int? syncIntervalMinutes;
  final List<String>? _allowedProjects;
  @override
  List<String>? get allowedProjects {
    final value = _allowedProjects;
    if (value == null) return null;
    if (_allowedProjects is EqualUnmodifiableListView) return _allowedProjects;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'IntegrationConfig(integrationId: $integrationId, type: $type, apiKey: $apiKey, apiSecret: $apiSecret, webhookUrl: $webhookUrl, webhookSecret: $webhookSecret, customSettings: $customSettings, autoSync: $autoSync, syncIntervalMinutes: $syncIntervalMinutes, allowedProjects: $allowedProjects)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IntegrationConfigImpl &&
            (identical(other.integrationId, integrationId) ||
                other.integrationId == integrationId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.apiKey, apiKey) || other.apiKey == apiKey) &&
            (identical(other.apiSecret, apiSecret) ||
                other.apiSecret == apiSecret) &&
            (identical(other.webhookUrl, webhookUrl) ||
                other.webhookUrl == webhookUrl) &&
            (identical(other.webhookSecret, webhookSecret) ||
                other.webhookSecret == webhookSecret) &&
            const DeepCollectionEquality().equals(
              other._customSettings,
              _customSettings,
            ) &&
            (identical(other.autoSync, autoSync) ||
                other.autoSync == autoSync) &&
            (identical(other.syncIntervalMinutes, syncIntervalMinutes) ||
                other.syncIntervalMinutes == syncIntervalMinutes) &&
            const DeepCollectionEquality().equals(
              other._allowedProjects,
              _allowedProjects,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    integrationId,
    type,
    apiKey,
    apiSecret,
    webhookUrl,
    webhookSecret,
    const DeepCollectionEquality().hash(_customSettings),
    autoSync,
    syncIntervalMinutes,
    const DeepCollectionEquality().hash(_allowedProjects),
  );

  /// Create a copy of IntegrationConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IntegrationConfigImplCopyWith<_$IntegrationConfigImpl> get copyWith =>
      __$$IntegrationConfigImplCopyWithImpl<_$IntegrationConfigImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$IntegrationConfigImplToJson(this);
  }
}

abstract class _IntegrationConfig implements IntegrationConfig {
  const factory _IntegrationConfig({
    required final String integrationId,
    required final IntegrationType type,
    final String? apiKey,
    final String? apiSecret,
    final String? webhookUrl,
    final String? webhookSecret,
    final Map<String, String>? customSettings,
    final bool? autoSync,
    final int? syncIntervalMinutes,
    final List<String>? allowedProjects,
  }) = _$IntegrationConfigImpl;

  factory _IntegrationConfig.fromJson(Map<String, dynamic> json) =
      _$IntegrationConfigImpl.fromJson;

  @override
  String get integrationId;
  @override
  IntegrationType get type;
  @override
  String? get apiKey;
  @override
  String? get apiSecret;
  @override
  String? get webhookUrl;
  @override
  String? get webhookSecret;
  @override
  Map<String, String>? get customSettings;
  @override
  bool? get autoSync;
  @override
  int? get syncIntervalMinutes;
  @override
  List<String>? get allowedProjects;

  /// Create a copy of IntegrationConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IntegrationConfigImplCopyWith<_$IntegrationConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FirefliesData _$FirefliesDataFromJson(Map<String, dynamic> json) {
  return _FirefliesData.fromJson(json);
}

/// @nodoc
mixin _$FirefliesData {
  String get transcriptId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get transcript => throw _privateConstructorUsedError;
  DateTime get meetingDate => throw _privateConstructorUsedError;
  int get duration => throw _privateConstructorUsedError;
  List<String>? get participants => throw _privateConstructorUsedError;
  String? get meetingUrl => throw _privateConstructorUsedError;
  String? get recordingUrl => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  /// Serializes this FirefliesData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FirefliesData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FirefliesDataCopyWith<FirefliesData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FirefliesDataCopyWith<$Res> {
  factory $FirefliesDataCopyWith(
    FirefliesData value,
    $Res Function(FirefliesData) then,
  ) = _$FirefliesDataCopyWithImpl<$Res, FirefliesData>;
  @useResult
  $Res call({
    String transcriptId,
    String title,
    String transcript,
    DateTime meetingDate,
    int duration,
    List<String>? participants,
    String? meetingUrl,
    String? recordingUrl,
    Map<String, dynamic>? metadata,
  });
}

/// @nodoc
class _$FirefliesDataCopyWithImpl<$Res, $Val extends FirefliesData>
    implements $FirefliesDataCopyWith<$Res> {
  _$FirefliesDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FirefliesData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transcriptId = null,
    Object? title = null,
    Object? transcript = null,
    Object? meetingDate = null,
    Object? duration = null,
    Object? participants = freezed,
    Object? meetingUrl = freezed,
    Object? recordingUrl = freezed,
    Object? metadata = freezed,
  }) {
    return _then(
      _value.copyWith(
            transcriptId: null == transcriptId
                ? _value.transcriptId
                : transcriptId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            transcript: null == transcript
                ? _value.transcript
                : transcript // ignore: cast_nullable_to_non_nullable
                      as String,
            meetingDate: null == meetingDate
                ? _value.meetingDate
                : meetingDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            duration: null == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                      as int,
            participants: freezed == participants
                ? _value.participants
                : participants // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            meetingUrl: freezed == meetingUrl
                ? _value.meetingUrl
                : meetingUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            recordingUrl: freezed == recordingUrl
                ? _value.recordingUrl
                : recordingUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            metadata: freezed == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FirefliesDataImplCopyWith<$Res>
    implements $FirefliesDataCopyWith<$Res> {
  factory _$$FirefliesDataImplCopyWith(
    _$FirefliesDataImpl value,
    $Res Function(_$FirefliesDataImpl) then,
  ) = __$$FirefliesDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String transcriptId,
    String title,
    String transcript,
    DateTime meetingDate,
    int duration,
    List<String>? participants,
    String? meetingUrl,
    String? recordingUrl,
    Map<String, dynamic>? metadata,
  });
}

/// @nodoc
class __$$FirefliesDataImplCopyWithImpl<$Res>
    extends _$FirefliesDataCopyWithImpl<$Res, _$FirefliesDataImpl>
    implements _$$FirefliesDataImplCopyWith<$Res> {
  __$$FirefliesDataImplCopyWithImpl(
    _$FirefliesDataImpl _value,
    $Res Function(_$FirefliesDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FirefliesData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transcriptId = null,
    Object? title = null,
    Object? transcript = null,
    Object? meetingDate = null,
    Object? duration = null,
    Object? participants = freezed,
    Object? meetingUrl = freezed,
    Object? recordingUrl = freezed,
    Object? metadata = freezed,
  }) {
    return _then(
      _$FirefliesDataImpl(
        transcriptId: null == transcriptId
            ? _value.transcriptId
            : transcriptId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        transcript: null == transcript
            ? _value.transcript
            : transcript // ignore: cast_nullable_to_non_nullable
                  as String,
        meetingDate: null == meetingDate
            ? _value.meetingDate
            : meetingDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        duration: null == duration
            ? _value.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as int,
        participants: freezed == participants
            ? _value._participants
            : participants // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        meetingUrl: freezed == meetingUrl
            ? _value.meetingUrl
            : meetingUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        recordingUrl: freezed == recordingUrl
            ? _value.recordingUrl
            : recordingUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        metadata: freezed == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FirefliesDataImpl implements _FirefliesData {
  const _$FirefliesDataImpl({
    required this.transcriptId,
    required this.title,
    required this.transcript,
    required this.meetingDate,
    required this.duration,
    final List<String>? participants,
    this.meetingUrl,
    this.recordingUrl,
    final Map<String, dynamic>? metadata,
  }) : _participants = participants,
       _metadata = metadata;

  factory _$FirefliesDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$FirefliesDataImplFromJson(json);

  @override
  final String transcriptId;
  @override
  final String title;
  @override
  final String transcript;
  @override
  final DateTime meetingDate;
  @override
  final int duration;
  final List<String>? _participants;
  @override
  List<String>? get participants {
    final value = _participants;
    if (value == null) return null;
    if (_participants is EqualUnmodifiableListView) return _participants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? meetingUrl;
  @override
  final String? recordingUrl;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'FirefliesData(transcriptId: $transcriptId, title: $title, transcript: $transcript, meetingDate: $meetingDate, duration: $duration, participants: $participants, meetingUrl: $meetingUrl, recordingUrl: $recordingUrl, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FirefliesDataImpl &&
            (identical(other.transcriptId, transcriptId) ||
                other.transcriptId == transcriptId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.transcript, transcript) ||
                other.transcript == transcript) &&
            (identical(other.meetingDate, meetingDate) ||
                other.meetingDate == meetingDate) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            const DeepCollectionEquality().equals(
              other._participants,
              _participants,
            ) &&
            (identical(other.meetingUrl, meetingUrl) ||
                other.meetingUrl == meetingUrl) &&
            (identical(other.recordingUrl, recordingUrl) ||
                other.recordingUrl == recordingUrl) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    transcriptId,
    title,
    transcript,
    meetingDate,
    duration,
    const DeepCollectionEquality().hash(_participants),
    meetingUrl,
    recordingUrl,
    const DeepCollectionEquality().hash(_metadata),
  );

  /// Create a copy of FirefliesData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FirefliesDataImplCopyWith<_$FirefliesDataImpl> get copyWith =>
      __$$FirefliesDataImplCopyWithImpl<_$FirefliesDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FirefliesDataImplToJson(this);
  }
}

abstract class _FirefliesData implements FirefliesData {
  const factory _FirefliesData({
    required final String transcriptId,
    required final String title,
    required final String transcript,
    required final DateTime meetingDate,
    required final int duration,
    final List<String>? participants,
    final String? meetingUrl,
    final String? recordingUrl,
    final Map<String, dynamic>? metadata,
  }) = _$FirefliesDataImpl;

  factory _FirefliesData.fromJson(Map<String, dynamic> json) =
      _$FirefliesDataImpl.fromJson;

  @override
  String get transcriptId;
  @override
  String get title;
  @override
  String get transcript;
  @override
  DateTime get meetingDate;
  @override
  int get duration;
  @override
  List<String>? get participants;
  @override
  String? get meetingUrl;
  @override
  String? get recordingUrl;
  @override
  Map<String, dynamic>? get metadata;

  /// Create a copy of FirefliesData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FirefliesDataImplCopyWith<_$FirefliesDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
