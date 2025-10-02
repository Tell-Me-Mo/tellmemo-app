// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) {
  return _AppNotification.fromJson(json);
}

/// @nodoc
mixin _$AppNotification {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;
  NotificationType get type => throw _privateConstructorUsedError;
  NotificationPriority get priority => throw _privateConstructorUsedError;
  NotificationPosition get position => throw _privateConstructorUsedError;
  int get durationMs => throw _privateConstructorUsedError;
  bool get persistent => throw _privateConstructorUsedError;
  bool get isRead => throw _privateConstructorUsedError;
  String? get actionLabel => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  VoidCallback? get onAction => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  VoidCallback? get onDismiss => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  IconData? get icon => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;
  bool get showInCenter => throw _privateConstructorUsedError;
  bool get showAsToast => throw _privateConstructorUsedError;

  /// Serializes this AppNotification to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppNotification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppNotificationCopyWith<AppNotification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppNotificationCopyWith<$Res> {
  factory $AppNotificationCopyWith(
    AppNotification value,
    $Res Function(AppNotification) then,
  ) = _$AppNotificationCopyWithImpl<$Res, AppNotification>;
  @useResult
  $Res call({
    String id,
    String title,
    String? message,
    NotificationType type,
    NotificationPriority priority,
    NotificationPosition position,
    int durationMs,
    bool persistent,
    bool isRead,
    String? actionLabel,
    @JsonKey(includeFromJson: false, includeToJson: false)
    VoidCallback? onAction,
    @JsonKey(includeFromJson: false, includeToJson: false)
    VoidCallback? onDismiss,
    @JsonKey(includeFromJson: false, includeToJson: false) IconData? icon,
    String? avatarUrl,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool showInCenter,
    bool showAsToast,
  });
}

/// @nodoc
class _$AppNotificationCopyWithImpl<$Res, $Val extends AppNotification>
    implements $AppNotificationCopyWith<$Res> {
  _$AppNotificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppNotification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? message = freezed,
    Object? type = null,
    Object? priority = null,
    Object? position = null,
    Object? durationMs = null,
    Object? persistent = null,
    Object? isRead = null,
    Object? actionLabel = freezed,
    Object? onAction = freezed,
    Object? onDismiss = freezed,
    Object? icon = freezed,
    Object? avatarUrl = freezed,
    Object? imageUrl = freezed,
    Object? metadata = freezed,
    Object? createdAt = freezed,
    Object? expiresAt = freezed,
    Object? showInCenter = null,
    Object? showAsToast = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            message: freezed == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as NotificationType,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as NotificationPriority,
            position: null == position
                ? _value.position
                : position // ignore: cast_nullable_to_non_nullable
                      as NotificationPosition,
            durationMs: null == durationMs
                ? _value.durationMs
                : durationMs // ignore: cast_nullable_to_non_nullable
                      as int,
            persistent: null == persistent
                ? _value.persistent
                : persistent // ignore: cast_nullable_to_non_nullable
                      as bool,
            isRead: null == isRead
                ? _value.isRead
                : isRead // ignore: cast_nullable_to_non_nullable
                      as bool,
            actionLabel: freezed == actionLabel
                ? _value.actionLabel
                : actionLabel // ignore: cast_nullable_to_non_nullable
                      as String?,
            onAction: freezed == onAction
                ? _value.onAction
                : onAction // ignore: cast_nullable_to_non_nullable
                      as VoidCallback?,
            onDismiss: freezed == onDismiss
                ? _value.onDismiss
                : onDismiss // ignore: cast_nullable_to_non_nullable
                      as VoidCallback?,
            icon: freezed == icon
                ? _value.icon
                : icon // ignore: cast_nullable_to_non_nullable
                      as IconData?,
            avatarUrl: freezed == avatarUrl
                ? _value.avatarUrl
                : avatarUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            metadata: freezed == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            expiresAt: freezed == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            showInCenter: null == showInCenter
                ? _value.showInCenter
                : showInCenter // ignore: cast_nullable_to_non_nullable
                      as bool,
            showAsToast: null == showAsToast
                ? _value.showAsToast
                : showAsToast // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppNotificationImplCopyWith<$Res>
    implements $AppNotificationCopyWith<$Res> {
  factory _$$AppNotificationImplCopyWith(
    _$AppNotificationImpl value,
    $Res Function(_$AppNotificationImpl) then,
  ) = __$$AppNotificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String? message,
    NotificationType type,
    NotificationPriority priority,
    NotificationPosition position,
    int durationMs,
    bool persistent,
    bool isRead,
    String? actionLabel,
    @JsonKey(includeFromJson: false, includeToJson: false)
    VoidCallback? onAction,
    @JsonKey(includeFromJson: false, includeToJson: false)
    VoidCallback? onDismiss,
    @JsonKey(includeFromJson: false, includeToJson: false) IconData? icon,
    String? avatarUrl,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool showInCenter,
    bool showAsToast,
  });
}

/// @nodoc
class __$$AppNotificationImplCopyWithImpl<$Res>
    extends _$AppNotificationCopyWithImpl<$Res, _$AppNotificationImpl>
    implements _$$AppNotificationImplCopyWith<$Res> {
  __$$AppNotificationImplCopyWithImpl(
    _$AppNotificationImpl _value,
    $Res Function(_$AppNotificationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppNotification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? message = freezed,
    Object? type = null,
    Object? priority = null,
    Object? position = null,
    Object? durationMs = null,
    Object? persistent = null,
    Object? isRead = null,
    Object? actionLabel = freezed,
    Object? onAction = freezed,
    Object? onDismiss = freezed,
    Object? icon = freezed,
    Object? avatarUrl = freezed,
    Object? imageUrl = freezed,
    Object? metadata = freezed,
    Object? createdAt = freezed,
    Object? expiresAt = freezed,
    Object? showInCenter = null,
    Object? showAsToast = null,
  }) {
    return _then(
      _$AppNotificationImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        message: freezed == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as NotificationType,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as NotificationPriority,
        position: null == position
            ? _value.position
            : position // ignore: cast_nullable_to_non_nullable
                  as NotificationPosition,
        durationMs: null == durationMs
            ? _value.durationMs
            : durationMs // ignore: cast_nullable_to_non_nullable
                  as int,
        persistent: null == persistent
            ? _value.persistent
            : persistent // ignore: cast_nullable_to_non_nullable
                  as bool,
        isRead: null == isRead
            ? _value.isRead
            : isRead // ignore: cast_nullable_to_non_nullable
                  as bool,
        actionLabel: freezed == actionLabel
            ? _value.actionLabel
            : actionLabel // ignore: cast_nullable_to_non_nullable
                  as String?,
        onAction: freezed == onAction
            ? _value.onAction
            : onAction // ignore: cast_nullable_to_non_nullable
                  as VoidCallback?,
        onDismiss: freezed == onDismiss
            ? _value.onDismiss
            : onDismiss // ignore: cast_nullable_to_non_nullable
                  as VoidCallback?,
        icon: freezed == icon
            ? _value.icon
            : icon // ignore: cast_nullable_to_non_nullable
                  as IconData?,
        avatarUrl: freezed == avatarUrl
            ? _value.avatarUrl
            : avatarUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        metadata: freezed == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        expiresAt: freezed == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        showInCenter: null == showInCenter
            ? _value.showInCenter
            : showInCenter // ignore: cast_nullable_to_non_nullable
                  as bool,
        showAsToast: null == showAsToast
            ? _value.showAsToast
            : showAsToast // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AppNotificationImpl implements _AppNotification {
  const _$AppNotificationImpl({
    required this.id,
    required this.title,
    this.message,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.position = NotificationPosition.topRight,
    this.durationMs = 4000,
    this.persistent = false,
    this.isRead = false,
    this.actionLabel,
    @JsonKey(includeFromJson: false, includeToJson: false) this.onAction,
    @JsonKey(includeFromJson: false, includeToJson: false) this.onDismiss,
    @JsonKey(includeFromJson: false, includeToJson: false) this.icon,
    this.avatarUrl,
    this.imageUrl,
    final Map<String, dynamic>? metadata,
    this.createdAt,
    this.expiresAt,
    this.showInCenter = true,
    this.showAsToast = true,
  }) : _metadata = metadata;

  factory _$AppNotificationImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppNotificationImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String? message;
  @override
  final NotificationType type;
  @override
  @JsonKey()
  final NotificationPriority priority;
  @override
  @JsonKey()
  final NotificationPosition position;
  @override
  @JsonKey()
  final int durationMs;
  @override
  @JsonKey()
  final bool persistent;
  @override
  @JsonKey()
  final bool isRead;
  @override
  final String? actionLabel;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final VoidCallback? onAction;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final VoidCallback? onDismiss;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final IconData? icon;
  @override
  final String? avatarUrl;
  @override
  final String? imageUrl;
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
  final DateTime? createdAt;
  @override
  final DateTime? expiresAt;
  @override
  @JsonKey()
  final bool showInCenter;
  @override
  @JsonKey()
  final bool showAsToast;

  @override
  String toString() {
    return 'AppNotification(id: $id, title: $title, message: $message, type: $type, priority: $priority, position: $position, durationMs: $durationMs, persistent: $persistent, isRead: $isRead, actionLabel: $actionLabel, onAction: $onAction, onDismiss: $onDismiss, icon: $icon, avatarUrl: $avatarUrl, imageUrl: $imageUrl, metadata: $metadata, createdAt: $createdAt, expiresAt: $expiresAt, showInCenter: $showInCenter, showAsToast: $showAsToast)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppNotificationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            (identical(other.persistent, persistent) ||
                other.persistent == persistent) &&
            (identical(other.isRead, isRead) || other.isRead == isRead) &&
            (identical(other.actionLabel, actionLabel) ||
                other.actionLabel == actionLabel) &&
            (identical(other.onAction, onAction) ||
                other.onAction == onAction) &&
            (identical(other.onDismiss, onDismiss) ||
                other.onDismiss == onDismiss) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.showInCenter, showInCenter) ||
                other.showInCenter == showInCenter) &&
            (identical(other.showAsToast, showAsToast) ||
                other.showAsToast == showAsToast));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    title,
    message,
    type,
    priority,
    position,
    durationMs,
    persistent,
    isRead,
    actionLabel,
    onAction,
    onDismiss,
    icon,
    avatarUrl,
    imageUrl,
    const DeepCollectionEquality().hash(_metadata),
    createdAt,
    expiresAt,
    showInCenter,
    showAsToast,
  ]);

  /// Create a copy of AppNotification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppNotificationImplCopyWith<_$AppNotificationImpl> get copyWith =>
      __$$AppNotificationImplCopyWithImpl<_$AppNotificationImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AppNotificationImplToJson(this);
  }
}

abstract class _AppNotification implements AppNotification {
  const factory _AppNotification({
    required final String id,
    required final String title,
    final String? message,
    required final NotificationType type,
    final NotificationPriority priority,
    final NotificationPosition position,
    final int durationMs,
    final bool persistent,
    final bool isRead,
    final String? actionLabel,
    @JsonKey(includeFromJson: false, includeToJson: false)
    final VoidCallback? onAction,
    @JsonKey(includeFromJson: false, includeToJson: false)
    final VoidCallback? onDismiss,
    @JsonKey(includeFromJson: false, includeToJson: false) final IconData? icon,
    final String? avatarUrl,
    final String? imageUrl,
    final Map<String, dynamic>? metadata,
    final DateTime? createdAt,
    final DateTime? expiresAt,
    final bool showInCenter,
    final bool showAsToast,
  }) = _$AppNotificationImpl;

  factory _AppNotification.fromJson(Map<String, dynamic> json) =
      _$AppNotificationImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String? get message;
  @override
  NotificationType get type;
  @override
  NotificationPriority get priority;
  @override
  NotificationPosition get position;
  @override
  int get durationMs;
  @override
  bool get persistent;
  @override
  bool get isRead;
  @override
  String? get actionLabel;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  VoidCallback? get onAction;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  VoidCallback? get onDismiss;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  IconData? get icon;
  @override
  String? get avatarUrl;
  @override
  String? get imageUrl;
  @override
  Map<String, dynamic>? get metadata;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get expiresAt;
  @override
  bool get showInCenter;
  @override
  bool get showAsToast;

  /// Create a copy of AppNotification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppNotificationImplCopyWith<_$AppNotificationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
