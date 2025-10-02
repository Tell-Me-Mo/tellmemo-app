// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_organization_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CreateOrganizationRequest _$CreateOrganizationRequestFromJson(
  Map<String, dynamic> json,
) {
  return _CreateOrganizationRequest.fromJson(json);
}

/// @nodoc
mixin _$CreateOrganizationRequest {
  String get name => throw _privateConstructorUsedError;
  String? get slug => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'logo_url')
  String? get logoUrl => throw _privateConstructorUsedError;
  Map<String, dynamic> get settings => throw _privateConstructorUsedError;

  /// Serializes this CreateOrganizationRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreateOrganizationRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreateOrganizationRequestCopyWith<CreateOrganizationRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateOrganizationRequestCopyWith<$Res> {
  factory $CreateOrganizationRequestCopyWith(
    CreateOrganizationRequest value,
    $Res Function(CreateOrganizationRequest) then,
  ) = _$CreateOrganizationRequestCopyWithImpl<$Res, CreateOrganizationRequest>;
  @useResult
  $Res call({
    String name,
    String? slug,
    String? description,
    @JsonKey(name: 'logo_url') String? logoUrl,
    Map<String, dynamic> settings,
  });
}

/// @nodoc
class _$CreateOrganizationRequestCopyWithImpl<
  $Res,
  $Val extends CreateOrganizationRequest
>
    implements $CreateOrganizationRequestCopyWith<$Res> {
  _$CreateOrganizationRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreateOrganizationRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? slug = freezed,
    Object? description = freezed,
    Object? logoUrl = freezed,
    Object? settings = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            slug: freezed == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            logoUrl: freezed == logoUrl
                ? _value.logoUrl
                : logoUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            settings: null == settings
                ? _value.settings
                : settings // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreateOrganizationRequestImplCopyWith<$Res>
    implements $CreateOrganizationRequestCopyWith<$Res> {
  factory _$$CreateOrganizationRequestImplCopyWith(
    _$CreateOrganizationRequestImpl value,
    $Res Function(_$CreateOrganizationRequestImpl) then,
  ) = __$$CreateOrganizationRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String? slug,
    String? description,
    @JsonKey(name: 'logo_url') String? logoUrl,
    Map<String, dynamic> settings,
  });
}

/// @nodoc
class __$$CreateOrganizationRequestImplCopyWithImpl<$Res>
    extends
        _$CreateOrganizationRequestCopyWithImpl<
          $Res,
          _$CreateOrganizationRequestImpl
        >
    implements _$$CreateOrganizationRequestImplCopyWith<$Res> {
  __$$CreateOrganizationRequestImplCopyWithImpl(
    _$CreateOrganizationRequestImpl _value,
    $Res Function(_$CreateOrganizationRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreateOrganizationRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? slug = freezed,
    Object? description = freezed,
    Object? logoUrl = freezed,
    Object? settings = null,
  }) {
    return _then(
      _$CreateOrganizationRequestImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        slug: freezed == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        logoUrl: freezed == logoUrl
            ? _value.logoUrl
            : logoUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        settings: null == settings
            ? _value._settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreateOrganizationRequestImpl implements _CreateOrganizationRequest {
  const _$CreateOrganizationRequestImpl({
    required this.name,
    this.slug,
    this.description,
    @JsonKey(name: 'logo_url') this.logoUrl,
    final Map<String, dynamic> settings = const {},
  }) : _settings = settings;

  factory _$CreateOrganizationRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreateOrganizationRequestImplFromJson(json);

  @override
  final String name;
  @override
  final String? slug;
  @override
  final String? description;
  @override
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  final Map<String, dynamic> _settings;
  @override
  @JsonKey()
  Map<String, dynamic> get settings {
    if (_settings is EqualUnmodifiableMapView) return _settings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_settings);
  }

  @override
  String toString() {
    return 'CreateOrganizationRequest(name: $name, slug: $slug, description: $description, logoUrl: $logoUrl, settings: $settings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateOrganizationRequestImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            const DeepCollectionEquality().equals(other._settings, _settings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    slug,
    description,
    logoUrl,
    const DeepCollectionEquality().hash(_settings),
  );

  /// Create a copy of CreateOrganizationRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateOrganizationRequestImplCopyWith<_$CreateOrganizationRequestImpl>
  get copyWith =>
      __$$CreateOrganizationRequestImplCopyWithImpl<
        _$CreateOrganizationRequestImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateOrganizationRequestImplToJson(this);
  }
}

abstract class _CreateOrganizationRequest implements CreateOrganizationRequest {
  const factory _CreateOrganizationRequest({
    required final String name,
    final String? slug,
    final String? description,
    @JsonKey(name: 'logo_url') final String? logoUrl,
    final Map<String, dynamic> settings,
  }) = _$CreateOrganizationRequestImpl;

  factory _CreateOrganizationRequest.fromJson(Map<String, dynamic> json) =
      _$CreateOrganizationRequestImpl.fromJson;

  @override
  String get name;
  @override
  String? get slug;
  @override
  String? get description;
  @override
  @JsonKey(name: 'logo_url')
  String? get logoUrl;
  @override
  Map<String, dynamic> get settings;

  /// Create a copy of CreateOrganizationRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateOrganizationRequestImplCopyWith<_$CreateOrganizationRequestImpl>
  get copyWith => throw _privateConstructorUsedError;
}
