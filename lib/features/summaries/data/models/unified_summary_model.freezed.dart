// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unified_summary_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UnifiedSummaryRequest _$UnifiedSummaryRequestFromJson(
  Map<String, dynamic> json,
) {
  return _UnifiedSummaryRequest.fromJson(json);
}

/// @nodoc
mixin _$UnifiedSummaryRequest {
  @JsonKey(name: 'entity_type')
  EntityType get entityType => throw _privateConstructorUsedError;
  @JsonKey(name: 'entity_id')
  String get entityId => throw _privateConstructorUsedError;
  @JsonKey(name: 'summary_type')
  SummaryType get summaryType => throw _privateConstructorUsedError;
  @JsonKey(name: 'content_id')
  String? get contentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_range_start')
  @DateTimeConverterNullable()
  DateTime? get dateRangeStart => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_range_end')
  @DateTimeConverterNullable()
  DateTime? get dateRangeEnd => throw _privateConstructorUsedError;
  String get format => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_by')
  String? get createdBy => throw _privateConstructorUsedError;

  /// Serializes this UnifiedSummaryRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UnifiedSummaryRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UnifiedSummaryRequestCopyWith<UnifiedSummaryRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UnifiedSummaryRequestCopyWith<$Res> {
  factory $UnifiedSummaryRequestCopyWith(
    UnifiedSummaryRequest value,
    $Res Function(UnifiedSummaryRequest) then,
  ) = _$UnifiedSummaryRequestCopyWithImpl<$Res, UnifiedSummaryRequest>;
  @useResult
  $Res call({
    @JsonKey(name: 'entity_type') EntityType entityType,
    @JsonKey(name: 'entity_id') String entityId,
    @JsonKey(name: 'summary_type') SummaryType summaryType,
    @JsonKey(name: 'content_id') String? contentId,
    @JsonKey(name: 'date_range_start')
    @DateTimeConverterNullable()
    DateTime? dateRangeStart,
    @JsonKey(name: 'date_range_end')
    @DateTimeConverterNullable()
    DateTime? dateRangeEnd,
    String format,
    @JsonKey(name: 'created_by') String? createdBy,
  });
}

/// @nodoc
class _$UnifiedSummaryRequestCopyWithImpl<
  $Res,
  $Val extends UnifiedSummaryRequest
>
    implements $UnifiedSummaryRequestCopyWith<$Res> {
  _$UnifiedSummaryRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UnifiedSummaryRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? entityType = null,
    Object? entityId = null,
    Object? summaryType = null,
    Object? contentId = freezed,
    Object? dateRangeStart = freezed,
    Object? dateRangeEnd = freezed,
    Object? format = null,
    Object? createdBy = freezed,
  }) {
    return _then(
      _value.copyWith(
            entityType: null == entityType
                ? _value.entityType
                : entityType // ignore: cast_nullable_to_non_nullable
                      as EntityType,
            entityId: null == entityId
                ? _value.entityId
                : entityId // ignore: cast_nullable_to_non_nullable
                      as String,
            summaryType: null == summaryType
                ? _value.summaryType
                : summaryType // ignore: cast_nullable_to_non_nullable
                      as SummaryType,
            contentId: freezed == contentId
                ? _value.contentId
                : contentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            dateRangeStart: freezed == dateRangeStart
                ? _value.dateRangeStart
                : dateRangeStart // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            dateRangeEnd: freezed == dateRangeEnd
                ? _value.dateRangeEnd
                : dateRangeEnd // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            format: null == format
                ? _value.format
                : format // ignore: cast_nullable_to_non_nullable
                      as String,
            createdBy: freezed == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UnifiedSummaryRequestImplCopyWith<$Res>
    implements $UnifiedSummaryRequestCopyWith<$Res> {
  factory _$$UnifiedSummaryRequestImplCopyWith(
    _$UnifiedSummaryRequestImpl value,
    $Res Function(_$UnifiedSummaryRequestImpl) then,
  ) = __$$UnifiedSummaryRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'entity_type') EntityType entityType,
    @JsonKey(name: 'entity_id') String entityId,
    @JsonKey(name: 'summary_type') SummaryType summaryType,
    @JsonKey(name: 'content_id') String? contentId,
    @JsonKey(name: 'date_range_start')
    @DateTimeConverterNullable()
    DateTime? dateRangeStart,
    @JsonKey(name: 'date_range_end')
    @DateTimeConverterNullable()
    DateTime? dateRangeEnd,
    String format,
    @JsonKey(name: 'created_by') String? createdBy,
  });
}

/// @nodoc
class __$$UnifiedSummaryRequestImplCopyWithImpl<$Res>
    extends
        _$UnifiedSummaryRequestCopyWithImpl<$Res, _$UnifiedSummaryRequestImpl>
    implements _$$UnifiedSummaryRequestImplCopyWith<$Res> {
  __$$UnifiedSummaryRequestImplCopyWithImpl(
    _$UnifiedSummaryRequestImpl _value,
    $Res Function(_$UnifiedSummaryRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UnifiedSummaryRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? entityType = null,
    Object? entityId = null,
    Object? summaryType = null,
    Object? contentId = freezed,
    Object? dateRangeStart = freezed,
    Object? dateRangeEnd = freezed,
    Object? format = null,
    Object? createdBy = freezed,
  }) {
    return _then(
      _$UnifiedSummaryRequestImpl(
        entityType: null == entityType
            ? _value.entityType
            : entityType // ignore: cast_nullable_to_non_nullable
                  as EntityType,
        entityId: null == entityId
            ? _value.entityId
            : entityId // ignore: cast_nullable_to_non_nullable
                  as String,
        summaryType: null == summaryType
            ? _value.summaryType
            : summaryType // ignore: cast_nullable_to_non_nullable
                  as SummaryType,
        contentId: freezed == contentId
            ? _value.contentId
            : contentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        dateRangeStart: freezed == dateRangeStart
            ? _value.dateRangeStart
            : dateRangeStart // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        dateRangeEnd: freezed == dateRangeEnd
            ? _value.dateRangeEnd
            : dateRangeEnd // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        format: null == format
            ? _value.format
            : format // ignore: cast_nullable_to_non_nullable
                  as String,
        createdBy: freezed == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UnifiedSummaryRequestImpl implements _UnifiedSummaryRequest {
  const _$UnifiedSummaryRequestImpl({
    @JsonKey(name: 'entity_type') required this.entityType,
    @JsonKey(name: 'entity_id') required this.entityId,
    @JsonKey(name: 'summary_type') required this.summaryType,
    @JsonKey(name: 'content_id') this.contentId,
    @JsonKey(name: 'date_range_start')
    @DateTimeConverterNullable()
    this.dateRangeStart,
    @JsonKey(name: 'date_range_end')
    @DateTimeConverterNullable()
    this.dateRangeEnd,
    this.format = 'general',
    @JsonKey(name: 'created_by') this.createdBy,
  });

  factory _$UnifiedSummaryRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$UnifiedSummaryRequestImplFromJson(json);

  @override
  @JsonKey(name: 'entity_type')
  final EntityType entityType;
  @override
  @JsonKey(name: 'entity_id')
  final String entityId;
  @override
  @JsonKey(name: 'summary_type')
  final SummaryType summaryType;
  @override
  @JsonKey(name: 'content_id')
  final String? contentId;
  @override
  @JsonKey(name: 'date_range_start')
  @DateTimeConverterNullable()
  final DateTime? dateRangeStart;
  @override
  @JsonKey(name: 'date_range_end')
  @DateTimeConverterNullable()
  final DateTime? dateRangeEnd;
  @override
  @JsonKey()
  final String format;
  @override
  @JsonKey(name: 'created_by')
  final String? createdBy;

  @override
  String toString() {
    return 'UnifiedSummaryRequest(entityType: $entityType, entityId: $entityId, summaryType: $summaryType, contentId: $contentId, dateRangeStart: $dateRangeStart, dateRangeEnd: $dateRangeEnd, format: $format, createdBy: $createdBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnifiedSummaryRequestImpl &&
            (identical(other.entityType, entityType) ||
                other.entityType == entityType) &&
            (identical(other.entityId, entityId) ||
                other.entityId == entityId) &&
            (identical(other.summaryType, summaryType) ||
                other.summaryType == summaryType) &&
            (identical(other.contentId, contentId) ||
                other.contentId == contentId) &&
            (identical(other.dateRangeStart, dateRangeStart) ||
                other.dateRangeStart == dateRangeStart) &&
            (identical(other.dateRangeEnd, dateRangeEnd) ||
                other.dateRangeEnd == dateRangeEnd) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    entityType,
    entityId,
    summaryType,
    contentId,
    dateRangeStart,
    dateRangeEnd,
    format,
    createdBy,
  );

  /// Create a copy of UnifiedSummaryRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnifiedSummaryRequestImplCopyWith<_$UnifiedSummaryRequestImpl>
  get copyWith =>
      __$$UnifiedSummaryRequestImplCopyWithImpl<_$UnifiedSummaryRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UnifiedSummaryRequestImplToJson(this);
  }
}

abstract class _UnifiedSummaryRequest implements UnifiedSummaryRequest {
  const factory _UnifiedSummaryRequest({
    @JsonKey(name: 'entity_type') required final EntityType entityType,
    @JsonKey(name: 'entity_id') required final String entityId,
    @JsonKey(name: 'summary_type') required final SummaryType summaryType,
    @JsonKey(name: 'content_id') final String? contentId,
    @JsonKey(name: 'date_range_start')
    @DateTimeConverterNullable()
    final DateTime? dateRangeStart,
    @JsonKey(name: 'date_range_end')
    @DateTimeConverterNullable()
    final DateTime? dateRangeEnd,
    final String format,
    @JsonKey(name: 'created_by') final String? createdBy,
  }) = _$UnifiedSummaryRequestImpl;

  factory _UnifiedSummaryRequest.fromJson(Map<String, dynamic> json) =
      _$UnifiedSummaryRequestImpl.fromJson;

  @override
  @JsonKey(name: 'entity_type')
  EntityType get entityType;
  @override
  @JsonKey(name: 'entity_id')
  String get entityId;
  @override
  @JsonKey(name: 'summary_type')
  SummaryType get summaryType;
  @override
  @JsonKey(name: 'content_id')
  String? get contentId;
  @override
  @JsonKey(name: 'date_range_start')
  @DateTimeConverterNullable()
  DateTime? get dateRangeStart;
  @override
  @JsonKey(name: 'date_range_end')
  @DateTimeConverterNullable()
  DateTime? get dateRangeEnd;
  @override
  String get format;
  @override
  @JsonKey(name: 'created_by')
  String? get createdBy;

  /// Create a copy of UnifiedSummaryRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnifiedSummaryRequestImplCopyWith<_$UnifiedSummaryRequestImpl>
  get copyWith => throw _privateConstructorUsedError;
}

UnifiedSummaryResponse _$UnifiedSummaryResponseFromJson(
  Map<String, dynamic> json,
) {
  return _UnifiedSummaryResponse.fromJson(json);
}

/// @nodoc
mixin _$UnifiedSummaryResponse {
  @JsonKey(name: 'summary_id')
  String get summaryId => throw _privateConstructorUsedError;
  @JsonKey(name: 'entity_type')
  String get entityType => throw _privateConstructorUsedError;
  @JsonKey(name: 'entity_id')
  String get entityId => throw _privateConstructorUsedError;
  @JsonKey(name: 'entity_name')
  String get entityName => throw _privateConstructorUsedError;
  @JsonKey(name: 'content_id')
  String? get contentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'summary_type')
  String get summaryType => throw _privateConstructorUsedError;
  String get subject => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  @JsonKey(name: 'key_points')
  List<String>? get keyPoints => throw _privateConstructorUsedError;
  @JsonKey(name: 'decisions', fromJson: _decisionsFromJson)
  List<Decision>? get decisions => throw _privateConstructorUsedError;
  @JsonKey(name: 'action_items', fromJson: _actionItemsFromJson)
  List<ActionItem>? get actionItems => throw _privateConstructorUsedError;
  @JsonKey(name: 'sentiment_analysis')
  Map<String, dynamic>? get sentimentAnalysis =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'risks')
  List<Map<String, dynamic>>? get risks => throw _privateConstructorUsedError;
  @JsonKey(name: 'blockers')
  List<Map<String, dynamic>>? get blockers =>
      throw _privateConstructorUsedError;
  @JsonKey(
    name: 'communication_insights',
    fromJson: _communicationInsightsFromJson,
  )
  CommunicationInsights? get communicationInsights =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'next_meeting_agenda', fromJson: _agendaItemsFromJson)
  List<AgendaItem>? get nextMeetingAgenda => throw _privateConstructorUsedError;
  String get format => throw _privateConstructorUsedError;
  @JsonKey(name: 'token_count')
  int? get tokenCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'generation_time_ms')
  int? get generationTimeMs => throw _privateConstructorUsedError;
  @JsonKey(name: 'llm_cost')
  double? get llmCost => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  @DateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_by')
  String? get createdBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_range_start')
  @DateTimeConverterNullable()
  DateTime? get dateRangeStart => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_range_end')
  @DateTimeConverterNullable()
  DateTime? get dateRangeEnd => throw _privateConstructorUsedError;

  /// Serializes this UnifiedSummaryResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UnifiedSummaryResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UnifiedSummaryResponseCopyWith<UnifiedSummaryResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UnifiedSummaryResponseCopyWith<$Res> {
  factory $UnifiedSummaryResponseCopyWith(
    UnifiedSummaryResponse value,
    $Res Function(UnifiedSummaryResponse) then,
  ) = _$UnifiedSummaryResponseCopyWithImpl<$Res, UnifiedSummaryResponse>;
  @useResult
  $Res call({
    @JsonKey(name: 'summary_id') String summaryId,
    @JsonKey(name: 'entity_type') String entityType,
    @JsonKey(name: 'entity_id') String entityId,
    @JsonKey(name: 'entity_name') String entityName,
    @JsonKey(name: 'content_id') String? contentId,
    @JsonKey(name: 'summary_type') String summaryType,
    String subject,
    String body,
    @JsonKey(name: 'key_points') List<String>? keyPoints,
    @JsonKey(name: 'decisions', fromJson: _decisionsFromJson)
    List<Decision>? decisions,
    @JsonKey(name: 'action_items', fromJson: _actionItemsFromJson)
    List<ActionItem>? actionItems,
    @JsonKey(name: 'sentiment_analysis')
    Map<String, dynamic>? sentimentAnalysis,
    @JsonKey(name: 'risks') List<Map<String, dynamic>>? risks,
    @JsonKey(name: 'blockers') List<Map<String, dynamic>>? blockers,
    @JsonKey(
      name: 'communication_insights',
      fromJson: _communicationInsightsFromJson,
    )
    CommunicationInsights? communicationInsights,
    @JsonKey(name: 'next_meeting_agenda', fromJson: _agendaItemsFromJson)
    List<AgendaItem>? nextMeetingAgenda,
    String format,
    @JsonKey(name: 'token_count') int? tokenCount,
    @JsonKey(name: 'generation_time_ms') int? generationTimeMs,
    @JsonKey(name: 'llm_cost') double? llmCost,
    @JsonKey(name: 'created_at') @DateTimeConverter() DateTime createdAt,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'date_range_start')
    @DateTimeConverterNullable()
    DateTime? dateRangeStart,
    @JsonKey(name: 'date_range_end')
    @DateTimeConverterNullable()
    DateTime? dateRangeEnd,
  });

  $CommunicationInsightsCopyWith<$Res>? get communicationInsights;
}

/// @nodoc
class _$UnifiedSummaryResponseCopyWithImpl<
  $Res,
  $Val extends UnifiedSummaryResponse
>
    implements $UnifiedSummaryResponseCopyWith<$Res> {
  _$UnifiedSummaryResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UnifiedSummaryResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? summaryId = null,
    Object? entityType = null,
    Object? entityId = null,
    Object? entityName = null,
    Object? contentId = freezed,
    Object? summaryType = null,
    Object? subject = null,
    Object? body = null,
    Object? keyPoints = freezed,
    Object? decisions = freezed,
    Object? actionItems = freezed,
    Object? sentimentAnalysis = freezed,
    Object? risks = freezed,
    Object? blockers = freezed,
    Object? communicationInsights = freezed,
    Object? nextMeetingAgenda = freezed,
    Object? format = null,
    Object? tokenCount = freezed,
    Object? generationTimeMs = freezed,
    Object? llmCost = freezed,
    Object? createdAt = null,
    Object? createdBy = freezed,
    Object? dateRangeStart = freezed,
    Object? dateRangeEnd = freezed,
  }) {
    return _then(
      _value.copyWith(
            summaryId: null == summaryId
                ? _value.summaryId
                : summaryId // ignore: cast_nullable_to_non_nullable
                      as String,
            entityType: null == entityType
                ? _value.entityType
                : entityType // ignore: cast_nullable_to_non_nullable
                      as String,
            entityId: null == entityId
                ? _value.entityId
                : entityId // ignore: cast_nullable_to_non_nullable
                      as String,
            entityName: null == entityName
                ? _value.entityName
                : entityName // ignore: cast_nullable_to_non_nullable
                      as String,
            contentId: freezed == contentId
                ? _value.contentId
                : contentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            summaryType: null == summaryType
                ? _value.summaryType
                : summaryType // ignore: cast_nullable_to_non_nullable
                      as String,
            subject: null == subject
                ? _value.subject
                : subject // ignore: cast_nullable_to_non_nullable
                      as String,
            body: null == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                      as String,
            keyPoints: freezed == keyPoints
                ? _value.keyPoints
                : keyPoints // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            decisions: freezed == decisions
                ? _value.decisions
                : decisions // ignore: cast_nullable_to_non_nullable
                      as List<Decision>?,
            actionItems: freezed == actionItems
                ? _value.actionItems
                : actionItems // ignore: cast_nullable_to_non_nullable
                      as List<ActionItem>?,
            sentimentAnalysis: freezed == sentimentAnalysis
                ? _value.sentimentAnalysis
                : sentimentAnalysis // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            risks: freezed == risks
                ? _value.risks
                : risks // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>?,
            blockers: freezed == blockers
                ? _value.blockers
                : blockers // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>?,
            communicationInsights: freezed == communicationInsights
                ? _value.communicationInsights
                : communicationInsights // ignore: cast_nullable_to_non_nullable
                      as CommunicationInsights?,
            nextMeetingAgenda: freezed == nextMeetingAgenda
                ? _value.nextMeetingAgenda
                : nextMeetingAgenda // ignore: cast_nullable_to_non_nullable
                      as List<AgendaItem>?,
            format: null == format
                ? _value.format
                : format // ignore: cast_nullable_to_non_nullable
                      as String,
            tokenCount: freezed == tokenCount
                ? _value.tokenCount
                : tokenCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            generationTimeMs: freezed == generationTimeMs
                ? _value.generationTimeMs
                : generationTimeMs // ignore: cast_nullable_to_non_nullable
                      as int?,
            llmCost: freezed == llmCost
                ? _value.llmCost
                : llmCost // ignore: cast_nullable_to_non_nullable
                      as double?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            createdBy: freezed == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            dateRangeStart: freezed == dateRangeStart
                ? _value.dateRangeStart
                : dateRangeStart // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            dateRangeEnd: freezed == dateRangeEnd
                ? _value.dateRangeEnd
                : dateRangeEnd // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of UnifiedSummaryResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CommunicationInsightsCopyWith<$Res>? get communicationInsights {
    if (_value.communicationInsights == null) {
      return null;
    }

    return $CommunicationInsightsCopyWith<$Res>(_value.communicationInsights!, (
      value,
    ) {
      return _then(_value.copyWith(communicationInsights: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UnifiedSummaryResponseImplCopyWith<$Res>
    implements $UnifiedSummaryResponseCopyWith<$Res> {
  factory _$$UnifiedSummaryResponseImplCopyWith(
    _$UnifiedSummaryResponseImpl value,
    $Res Function(_$UnifiedSummaryResponseImpl) then,
  ) = __$$UnifiedSummaryResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'summary_id') String summaryId,
    @JsonKey(name: 'entity_type') String entityType,
    @JsonKey(name: 'entity_id') String entityId,
    @JsonKey(name: 'entity_name') String entityName,
    @JsonKey(name: 'content_id') String? contentId,
    @JsonKey(name: 'summary_type') String summaryType,
    String subject,
    String body,
    @JsonKey(name: 'key_points') List<String>? keyPoints,
    @JsonKey(name: 'decisions', fromJson: _decisionsFromJson)
    List<Decision>? decisions,
    @JsonKey(name: 'action_items', fromJson: _actionItemsFromJson)
    List<ActionItem>? actionItems,
    @JsonKey(name: 'sentiment_analysis')
    Map<String, dynamic>? sentimentAnalysis,
    @JsonKey(name: 'risks') List<Map<String, dynamic>>? risks,
    @JsonKey(name: 'blockers') List<Map<String, dynamic>>? blockers,
    @JsonKey(
      name: 'communication_insights',
      fromJson: _communicationInsightsFromJson,
    )
    CommunicationInsights? communicationInsights,
    @JsonKey(name: 'next_meeting_agenda', fromJson: _agendaItemsFromJson)
    List<AgendaItem>? nextMeetingAgenda,
    String format,
    @JsonKey(name: 'token_count') int? tokenCount,
    @JsonKey(name: 'generation_time_ms') int? generationTimeMs,
    @JsonKey(name: 'llm_cost') double? llmCost,
    @JsonKey(name: 'created_at') @DateTimeConverter() DateTime createdAt,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'date_range_start')
    @DateTimeConverterNullable()
    DateTime? dateRangeStart,
    @JsonKey(name: 'date_range_end')
    @DateTimeConverterNullable()
    DateTime? dateRangeEnd,
  });

  @override
  $CommunicationInsightsCopyWith<$Res>? get communicationInsights;
}

/// @nodoc
class __$$UnifiedSummaryResponseImplCopyWithImpl<$Res>
    extends
        _$UnifiedSummaryResponseCopyWithImpl<$Res, _$UnifiedSummaryResponseImpl>
    implements _$$UnifiedSummaryResponseImplCopyWith<$Res> {
  __$$UnifiedSummaryResponseImplCopyWithImpl(
    _$UnifiedSummaryResponseImpl _value,
    $Res Function(_$UnifiedSummaryResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UnifiedSummaryResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? summaryId = null,
    Object? entityType = null,
    Object? entityId = null,
    Object? entityName = null,
    Object? contentId = freezed,
    Object? summaryType = null,
    Object? subject = null,
    Object? body = null,
    Object? keyPoints = freezed,
    Object? decisions = freezed,
    Object? actionItems = freezed,
    Object? sentimentAnalysis = freezed,
    Object? risks = freezed,
    Object? blockers = freezed,
    Object? communicationInsights = freezed,
    Object? nextMeetingAgenda = freezed,
    Object? format = null,
    Object? tokenCount = freezed,
    Object? generationTimeMs = freezed,
    Object? llmCost = freezed,
    Object? createdAt = null,
    Object? createdBy = freezed,
    Object? dateRangeStart = freezed,
    Object? dateRangeEnd = freezed,
  }) {
    return _then(
      _$UnifiedSummaryResponseImpl(
        summaryId: null == summaryId
            ? _value.summaryId
            : summaryId // ignore: cast_nullable_to_non_nullable
                  as String,
        entityType: null == entityType
            ? _value.entityType
            : entityType // ignore: cast_nullable_to_non_nullable
                  as String,
        entityId: null == entityId
            ? _value.entityId
            : entityId // ignore: cast_nullable_to_non_nullable
                  as String,
        entityName: null == entityName
            ? _value.entityName
            : entityName // ignore: cast_nullable_to_non_nullable
                  as String,
        contentId: freezed == contentId
            ? _value.contentId
            : contentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        summaryType: null == summaryType
            ? _value.summaryType
            : summaryType // ignore: cast_nullable_to_non_nullable
                  as String,
        subject: null == subject
            ? _value.subject
            : subject // ignore: cast_nullable_to_non_nullable
                  as String,
        body: null == body
            ? _value.body
            : body // ignore: cast_nullable_to_non_nullable
                  as String,
        keyPoints: freezed == keyPoints
            ? _value._keyPoints
            : keyPoints // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        decisions: freezed == decisions
            ? _value._decisions
            : decisions // ignore: cast_nullable_to_non_nullable
                  as List<Decision>?,
        actionItems: freezed == actionItems
            ? _value._actionItems
            : actionItems // ignore: cast_nullable_to_non_nullable
                  as List<ActionItem>?,
        sentimentAnalysis: freezed == sentimentAnalysis
            ? _value._sentimentAnalysis
            : sentimentAnalysis // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        risks: freezed == risks
            ? _value._risks
            : risks // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>?,
        blockers: freezed == blockers
            ? _value._blockers
            : blockers // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>?,
        communicationInsights: freezed == communicationInsights
            ? _value.communicationInsights
            : communicationInsights // ignore: cast_nullable_to_non_nullable
                  as CommunicationInsights?,
        nextMeetingAgenda: freezed == nextMeetingAgenda
            ? _value._nextMeetingAgenda
            : nextMeetingAgenda // ignore: cast_nullable_to_non_nullable
                  as List<AgendaItem>?,
        format: null == format
            ? _value.format
            : format // ignore: cast_nullable_to_non_nullable
                  as String,
        tokenCount: freezed == tokenCount
            ? _value.tokenCount
            : tokenCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        generationTimeMs: freezed == generationTimeMs
            ? _value.generationTimeMs
            : generationTimeMs // ignore: cast_nullable_to_non_nullable
                  as int?,
        llmCost: freezed == llmCost
            ? _value.llmCost
            : llmCost // ignore: cast_nullable_to_non_nullable
                  as double?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        createdBy: freezed == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        dateRangeStart: freezed == dateRangeStart
            ? _value.dateRangeStart
            : dateRangeStart // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        dateRangeEnd: freezed == dateRangeEnd
            ? _value.dateRangeEnd
            : dateRangeEnd // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UnifiedSummaryResponseImpl extends _UnifiedSummaryResponse {
  const _$UnifiedSummaryResponseImpl({
    @JsonKey(name: 'summary_id') required this.summaryId,
    @JsonKey(name: 'entity_type') required this.entityType,
    @JsonKey(name: 'entity_id') required this.entityId,
    @JsonKey(name: 'entity_name') required this.entityName,
    @JsonKey(name: 'content_id') this.contentId,
    @JsonKey(name: 'summary_type') required this.summaryType,
    required this.subject,
    required this.body,
    @JsonKey(name: 'key_points') final List<String>? keyPoints,
    @JsonKey(name: 'decisions', fromJson: _decisionsFromJson)
    final List<Decision>? decisions,
    @JsonKey(name: 'action_items', fromJson: _actionItemsFromJson)
    final List<ActionItem>? actionItems,
    @JsonKey(name: 'sentiment_analysis')
    final Map<String, dynamic>? sentimentAnalysis,
    @JsonKey(name: 'risks') final List<Map<String, dynamic>>? risks,
    @JsonKey(name: 'blockers') final List<Map<String, dynamic>>? blockers,
    @JsonKey(
      name: 'communication_insights',
      fromJson: _communicationInsightsFromJson,
    )
    this.communicationInsights,
    @JsonKey(name: 'next_meeting_agenda', fromJson: _agendaItemsFromJson)
    final List<AgendaItem>? nextMeetingAgenda,
    this.format = 'general',
    @JsonKey(name: 'token_count') this.tokenCount,
    @JsonKey(name: 'generation_time_ms') this.generationTimeMs,
    @JsonKey(name: 'llm_cost') this.llmCost,
    @JsonKey(name: 'created_at') @DateTimeConverter() required this.createdAt,
    @JsonKey(name: 'created_by') this.createdBy,
    @JsonKey(name: 'date_range_start')
    @DateTimeConverterNullable()
    this.dateRangeStart,
    @JsonKey(name: 'date_range_end')
    @DateTimeConverterNullable()
    this.dateRangeEnd,
  }) : _keyPoints = keyPoints,
       _decisions = decisions,
       _actionItems = actionItems,
       _sentimentAnalysis = sentimentAnalysis,
       _risks = risks,
       _blockers = blockers,
       _nextMeetingAgenda = nextMeetingAgenda,
       super._();

  factory _$UnifiedSummaryResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$UnifiedSummaryResponseImplFromJson(json);

  @override
  @JsonKey(name: 'summary_id')
  final String summaryId;
  @override
  @JsonKey(name: 'entity_type')
  final String entityType;
  @override
  @JsonKey(name: 'entity_id')
  final String entityId;
  @override
  @JsonKey(name: 'entity_name')
  final String entityName;
  @override
  @JsonKey(name: 'content_id')
  final String? contentId;
  @override
  @JsonKey(name: 'summary_type')
  final String summaryType;
  @override
  final String subject;
  @override
  final String body;
  final List<String>? _keyPoints;
  @override
  @JsonKey(name: 'key_points')
  List<String>? get keyPoints {
    final value = _keyPoints;
    if (value == null) return null;
    if (_keyPoints is EqualUnmodifiableListView) return _keyPoints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<Decision>? _decisions;
  @override
  @JsonKey(name: 'decisions', fromJson: _decisionsFromJson)
  List<Decision>? get decisions {
    final value = _decisions;
    if (value == null) return null;
    if (_decisions is EqualUnmodifiableListView) return _decisions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<ActionItem>? _actionItems;
  @override
  @JsonKey(name: 'action_items', fromJson: _actionItemsFromJson)
  List<ActionItem>? get actionItems {
    final value = _actionItems;
    if (value == null) return null;
    if (_actionItems is EqualUnmodifiableListView) return _actionItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, dynamic>? _sentimentAnalysis;
  @override
  @JsonKey(name: 'sentiment_analysis')
  Map<String, dynamic>? get sentimentAnalysis {
    final value = _sentimentAnalysis;
    if (value == null) return null;
    if (_sentimentAnalysis is EqualUnmodifiableMapView)
      return _sentimentAnalysis;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final List<Map<String, dynamic>>? _risks;
  @override
  @JsonKey(name: 'risks')
  List<Map<String, dynamic>>? get risks {
    final value = _risks;
    if (value == null) return null;
    if (_risks is EqualUnmodifiableListView) return _risks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<Map<String, dynamic>>? _blockers;
  @override
  @JsonKey(name: 'blockers')
  List<Map<String, dynamic>>? get blockers {
    final value = _blockers;
    if (value == null) return null;
    if (_blockers is EqualUnmodifiableListView) return _blockers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(
    name: 'communication_insights',
    fromJson: _communicationInsightsFromJson,
  )
  final CommunicationInsights? communicationInsights;
  final List<AgendaItem>? _nextMeetingAgenda;
  @override
  @JsonKey(name: 'next_meeting_agenda', fromJson: _agendaItemsFromJson)
  List<AgendaItem>? get nextMeetingAgenda {
    final value = _nextMeetingAgenda;
    if (value == null) return null;
    if (_nextMeetingAgenda is EqualUnmodifiableListView)
      return _nextMeetingAgenda;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey()
  final String format;
  @override
  @JsonKey(name: 'token_count')
  final int? tokenCount;
  @override
  @JsonKey(name: 'generation_time_ms')
  final int? generationTimeMs;
  @override
  @JsonKey(name: 'llm_cost')
  final double? llmCost;
  @override
  @JsonKey(name: 'created_at')
  @DateTimeConverter()
  final DateTime createdAt;
  @override
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @override
  @JsonKey(name: 'date_range_start')
  @DateTimeConverterNullable()
  final DateTime? dateRangeStart;
  @override
  @JsonKey(name: 'date_range_end')
  @DateTimeConverterNullable()
  final DateTime? dateRangeEnd;

  @override
  String toString() {
    return 'UnifiedSummaryResponse(summaryId: $summaryId, entityType: $entityType, entityId: $entityId, entityName: $entityName, contentId: $contentId, summaryType: $summaryType, subject: $subject, body: $body, keyPoints: $keyPoints, decisions: $decisions, actionItems: $actionItems, sentimentAnalysis: $sentimentAnalysis, risks: $risks, blockers: $blockers, communicationInsights: $communicationInsights, nextMeetingAgenda: $nextMeetingAgenda, format: $format, tokenCount: $tokenCount, generationTimeMs: $generationTimeMs, llmCost: $llmCost, createdAt: $createdAt, createdBy: $createdBy, dateRangeStart: $dateRangeStart, dateRangeEnd: $dateRangeEnd)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnifiedSummaryResponseImpl &&
            (identical(other.summaryId, summaryId) ||
                other.summaryId == summaryId) &&
            (identical(other.entityType, entityType) ||
                other.entityType == entityType) &&
            (identical(other.entityId, entityId) ||
                other.entityId == entityId) &&
            (identical(other.entityName, entityName) ||
                other.entityName == entityName) &&
            (identical(other.contentId, contentId) ||
                other.contentId == contentId) &&
            (identical(other.summaryType, summaryType) ||
                other.summaryType == summaryType) &&
            (identical(other.subject, subject) || other.subject == subject) &&
            (identical(other.body, body) || other.body == body) &&
            const DeepCollectionEquality().equals(
              other._keyPoints,
              _keyPoints,
            ) &&
            const DeepCollectionEquality().equals(
              other._decisions,
              _decisions,
            ) &&
            const DeepCollectionEquality().equals(
              other._actionItems,
              _actionItems,
            ) &&
            const DeepCollectionEquality().equals(
              other._sentimentAnalysis,
              _sentimentAnalysis,
            ) &&
            const DeepCollectionEquality().equals(other._risks, _risks) &&
            const DeepCollectionEquality().equals(other._blockers, _blockers) &&
            (identical(other.communicationInsights, communicationInsights) ||
                other.communicationInsights == communicationInsights) &&
            const DeepCollectionEquality().equals(
              other._nextMeetingAgenda,
              _nextMeetingAgenda,
            ) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.tokenCount, tokenCount) ||
                other.tokenCount == tokenCount) &&
            (identical(other.generationTimeMs, generationTimeMs) ||
                other.generationTimeMs == generationTimeMs) &&
            (identical(other.llmCost, llmCost) || other.llmCost == llmCost) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.dateRangeStart, dateRangeStart) ||
                other.dateRangeStart == dateRangeStart) &&
            (identical(other.dateRangeEnd, dateRangeEnd) ||
                other.dateRangeEnd == dateRangeEnd));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    summaryId,
    entityType,
    entityId,
    entityName,
    contentId,
    summaryType,
    subject,
    body,
    const DeepCollectionEquality().hash(_keyPoints),
    const DeepCollectionEquality().hash(_decisions),
    const DeepCollectionEquality().hash(_actionItems),
    const DeepCollectionEquality().hash(_sentimentAnalysis),
    const DeepCollectionEquality().hash(_risks),
    const DeepCollectionEquality().hash(_blockers),
    communicationInsights,
    const DeepCollectionEquality().hash(_nextMeetingAgenda),
    format,
    tokenCount,
    generationTimeMs,
    llmCost,
    createdAt,
    createdBy,
    dateRangeStart,
    dateRangeEnd,
  ]);

  /// Create a copy of UnifiedSummaryResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnifiedSummaryResponseImplCopyWith<_$UnifiedSummaryResponseImpl>
  get copyWith =>
      __$$UnifiedSummaryResponseImplCopyWithImpl<_$UnifiedSummaryResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UnifiedSummaryResponseImplToJson(this);
  }
}

abstract class _UnifiedSummaryResponse extends UnifiedSummaryResponse {
  const factory _UnifiedSummaryResponse({
    @JsonKey(name: 'summary_id') required final String summaryId,
    @JsonKey(name: 'entity_type') required final String entityType,
    @JsonKey(name: 'entity_id') required final String entityId,
    @JsonKey(name: 'entity_name') required final String entityName,
    @JsonKey(name: 'content_id') final String? contentId,
    @JsonKey(name: 'summary_type') required final String summaryType,
    required final String subject,
    required final String body,
    @JsonKey(name: 'key_points') final List<String>? keyPoints,
    @JsonKey(name: 'decisions', fromJson: _decisionsFromJson)
    final List<Decision>? decisions,
    @JsonKey(name: 'action_items', fromJson: _actionItemsFromJson)
    final List<ActionItem>? actionItems,
    @JsonKey(name: 'sentiment_analysis')
    final Map<String, dynamic>? sentimentAnalysis,
    @JsonKey(name: 'risks') final List<Map<String, dynamic>>? risks,
    @JsonKey(name: 'blockers') final List<Map<String, dynamic>>? blockers,
    @JsonKey(
      name: 'communication_insights',
      fromJson: _communicationInsightsFromJson,
    )
    final CommunicationInsights? communicationInsights,
    @JsonKey(name: 'next_meeting_agenda', fromJson: _agendaItemsFromJson)
    final List<AgendaItem>? nextMeetingAgenda,
    final String format,
    @JsonKey(name: 'token_count') final int? tokenCount,
    @JsonKey(name: 'generation_time_ms') final int? generationTimeMs,
    @JsonKey(name: 'llm_cost') final double? llmCost,
    @JsonKey(name: 'created_at')
    @DateTimeConverter()
    required final DateTime createdAt,
    @JsonKey(name: 'created_by') final String? createdBy,
    @JsonKey(name: 'date_range_start')
    @DateTimeConverterNullable()
    final DateTime? dateRangeStart,
    @JsonKey(name: 'date_range_end')
    @DateTimeConverterNullable()
    final DateTime? dateRangeEnd,
  }) = _$UnifiedSummaryResponseImpl;
  const _UnifiedSummaryResponse._() : super._();

  factory _UnifiedSummaryResponse.fromJson(Map<String, dynamic> json) =
      _$UnifiedSummaryResponseImpl.fromJson;

  @override
  @JsonKey(name: 'summary_id')
  String get summaryId;
  @override
  @JsonKey(name: 'entity_type')
  String get entityType;
  @override
  @JsonKey(name: 'entity_id')
  String get entityId;
  @override
  @JsonKey(name: 'entity_name')
  String get entityName;
  @override
  @JsonKey(name: 'content_id')
  String? get contentId;
  @override
  @JsonKey(name: 'summary_type')
  String get summaryType;
  @override
  String get subject;
  @override
  String get body;
  @override
  @JsonKey(name: 'key_points')
  List<String>? get keyPoints;
  @override
  @JsonKey(name: 'decisions', fromJson: _decisionsFromJson)
  List<Decision>? get decisions;
  @override
  @JsonKey(name: 'action_items', fromJson: _actionItemsFromJson)
  List<ActionItem>? get actionItems;
  @override
  @JsonKey(name: 'sentiment_analysis')
  Map<String, dynamic>? get sentimentAnalysis;
  @override
  @JsonKey(name: 'risks')
  List<Map<String, dynamic>>? get risks;
  @override
  @JsonKey(name: 'blockers')
  List<Map<String, dynamic>>? get blockers;
  @override
  @JsonKey(
    name: 'communication_insights',
    fromJson: _communicationInsightsFromJson,
  )
  CommunicationInsights? get communicationInsights;
  @override
  @JsonKey(name: 'next_meeting_agenda', fromJson: _agendaItemsFromJson)
  List<AgendaItem>? get nextMeetingAgenda;
  @override
  String get format;
  @override
  @JsonKey(name: 'token_count')
  int? get tokenCount;
  @override
  @JsonKey(name: 'generation_time_ms')
  int? get generationTimeMs;
  @override
  @JsonKey(name: 'llm_cost')
  double? get llmCost;
  @override
  @JsonKey(name: 'created_at')
  @DateTimeConverter()
  DateTime get createdAt;
  @override
  @JsonKey(name: 'created_by')
  String? get createdBy;
  @override
  @JsonKey(name: 'date_range_start')
  @DateTimeConverterNullable()
  DateTime? get dateRangeStart;
  @override
  @JsonKey(name: 'date_range_end')
  @DateTimeConverterNullable()
  DateTime? get dateRangeEnd;

  /// Create a copy of UnifiedSummaryResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnifiedSummaryResponseImplCopyWith<_$UnifiedSummaryResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}

SummaryFilters _$SummaryFiltersFromJson(Map<String, dynamic> json) {
  return _SummaryFilters.fromJson(json);
}

/// @nodoc
mixin _$SummaryFilters {
  @JsonKey(name: 'entity_type')
  String? get entityType => throw _privateConstructorUsedError;
  @JsonKey(name: 'entity_id')
  String? get entityId => throw _privateConstructorUsedError;
  @JsonKey(name: 'summary_type')
  String? get summaryType => throw _privateConstructorUsedError;
  String? get format => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_after')
  DateTime? get createdAfter => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_before')
  DateTime? get createdBefore => throw _privateConstructorUsedError;
  int get limit => throw _privateConstructorUsedError;
  int get offset => throw _privateConstructorUsedError;

  /// Serializes this SummaryFilters to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SummaryFilters
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SummaryFiltersCopyWith<SummaryFilters> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SummaryFiltersCopyWith<$Res> {
  factory $SummaryFiltersCopyWith(
    SummaryFilters value,
    $Res Function(SummaryFilters) then,
  ) = _$SummaryFiltersCopyWithImpl<$Res, SummaryFilters>;
  @useResult
  $Res call({
    @JsonKey(name: 'entity_type') String? entityType,
    @JsonKey(name: 'entity_id') String? entityId,
    @JsonKey(name: 'summary_type') String? summaryType,
    String? format,
    @JsonKey(name: 'created_after') DateTime? createdAfter,
    @JsonKey(name: 'created_before') DateTime? createdBefore,
    int limit,
    int offset,
  });
}

/// @nodoc
class _$SummaryFiltersCopyWithImpl<$Res, $Val extends SummaryFilters>
    implements $SummaryFiltersCopyWith<$Res> {
  _$SummaryFiltersCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SummaryFilters
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? entityType = freezed,
    Object? entityId = freezed,
    Object? summaryType = freezed,
    Object? format = freezed,
    Object? createdAfter = freezed,
    Object? createdBefore = freezed,
    Object? limit = null,
    Object? offset = null,
  }) {
    return _then(
      _value.copyWith(
            entityType: freezed == entityType
                ? _value.entityType
                : entityType // ignore: cast_nullable_to_non_nullable
                      as String?,
            entityId: freezed == entityId
                ? _value.entityId
                : entityId // ignore: cast_nullable_to_non_nullable
                      as String?,
            summaryType: freezed == summaryType
                ? _value.summaryType
                : summaryType // ignore: cast_nullable_to_non_nullable
                      as String?,
            format: freezed == format
                ? _value.format
                : format // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAfter: freezed == createdAfter
                ? _value.createdAfter
                : createdAfter // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdBefore: freezed == createdBefore
                ? _value.createdBefore
                : createdBefore // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
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
abstract class _$$SummaryFiltersImplCopyWith<$Res>
    implements $SummaryFiltersCopyWith<$Res> {
  factory _$$SummaryFiltersImplCopyWith(
    _$SummaryFiltersImpl value,
    $Res Function(_$SummaryFiltersImpl) then,
  ) = __$$SummaryFiltersImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'entity_type') String? entityType,
    @JsonKey(name: 'entity_id') String? entityId,
    @JsonKey(name: 'summary_type') String? summaryType,
    String? format,
    @JsonKey(name: 'created_after') DateTime? createdAfter,
    @JsonKey(name: 'created_before') DateTime? createdBefore,
    int limit,
    int offset,
  });
}

/// @nodoc
class __$$SummaryFiltersImplCopyWithImpl<$Res>
    extends _$SummaryFiltersCopyWithImpl<$Res, _$SummaryFiltersImpl>
    implements _$$SummaryFiltersImplCopyWith<$Res> {
  __$$SummaryFiltersImplCopyWithImpl(
    _$SummaryFiltersImpl _value,
    $Res Function(_$SummaryFiltersImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SummaryFilters
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? entityType = freezed,
    Object? entityId = freezed,
    Object? summaryType = freezed,
    Object? format = freezed,
    Object? createdAfter = freezed,
    Object? createdBefore = freezed,
    Object? limit = null,
    Object? offset = null,
  }) {
    return _then(
      _$SummaryFiltersImpl(
        entityType: freezed == entityType
            ? _value.entityType
            : entityType // ignore: cast_nullable_to_non_nullable
                  as String?,
        entityId: freezed == entityId
            ? _value.entityId
            : entityId // ignore: cast_nullable_to_non_nullable
                  as String?,
        summaryType: freezed == summaryType
            ? _value.summaryType
            : summaryType // ignore: cast_nullable_to_non_nullable
                  as String?,
        format: freezed == format
            ? _value.format
            : format // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAfter: freezed == createdAfter
            ? _value.createdAfter
            : createdAfter // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdBefore: freezed == createdBefore
            ? _value.createdBefore
            : createdBefore // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
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
@JsonSerializable()
class _$SummaryFiltersImpl implements _SummaryFilters {
  const _$SummaryFiltersImpl({
    @JsonKey(name: 'entity_type') this.entityType,
    @JsonKey(name: 'entity_id') this.entityId,
    @JsonKey(name: 'summary_type') this.summaryType,
    this.format,
    @JsonKey(name: 'created_after') this.createdAfter,
    @JsonKey(name: 'created_before') this.createdBefore,
    this.limit = 100,
    this.offset = 0,
  });

  factory _$SummaryFiltersImpl.fromJson(Map<String, dynamic> json) =>
      _$$SummaryFiltersImplFromJson(json);

  @override
  @JsonKey(name: 'entity_type')
  final String? entityType;
  @override
  @JsonKey(name: 'entity_id')
  final String? entityId;
  @override
  @JsonKey(name: 'summary_type')
  final String? summaryType;
  @override
  final String? format;
  @override
  @JsonKey(name: 'created_after')
  final DateTime? createdAfter;
  @override
  @JsonKey(name: 'created_before')
  final DateTime? createdBefore;
  @override
  @JsonKey()
  final int limit;
  @override
  @JsonKey()
  final int offset;

  @override
  String toString() {
    return 'SummaryFilters(entityType: $entityType, entityId: $entityId, summaryType: $summaryType, format: $format, createdAfter: $createdAfter, createdBefore: $createdBefore, limit: $limit, offset: $offset)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SummaryFiltersImpl &&
            (identical(other.entityType, entityType) ||
                other.entityType == entityType) &&
            (identical(other.entityId, entityId) ||
                other.entityId == entityId) &&
            (identical(other.summaryType, summaryType) ||
                other.summaryType == summaryType) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.createdAfter, createdAfter) ||
                other.createdAfter == createdAfter) &&
            (identical(other.createdBefore, createdBefore) ||
                other.createdBefore == createdBefore) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.offset, offset) || other.offset == offset));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    entityType,
    entityId,
    summaryType,
    format,
    createdAfter,
    createdBefore,
    limit,
    offset,
  );

  /// Create a copy of SummaryFilters
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SummaryFiltersImplCopyWith<_$SummaryFiltersImpl> get copyWith =>
      __$$SummaryFiltersImplCopyWithImpl<_$SummaryFiltersImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SummaryFiltersImplToJson(this);
  }
}

abstract class _SummaryFilters implements SummaryFilters {
  const factory _SummaryFilters({
    @JsonKey(name: 'entity_type') final String? entityType,
    @JsonKey(name: 'entity_id') final String? entityId,
    @JsonKey(name: 'summary_type') final String? summaryType,
    final String? format,
    @JsonKey(name: 'created_after') final DateTime? createdAfter,
    @JsonKey(name: 'created_before') final DateTime? createdBefore,
    final int limit,
    final int offset,
  }) = _$SummaryFiltersImpl;

  factory _SummaryFilters.fromJson(Map<String, dynamic> json) =
      _$SummaryFiltersImpl.fromJson;

  @override
  @JsonKey(name: 'entity_type')
  String? get entityType;
  @override
  @JsonKey(name: 'entity_id')
  String? get entityId;
  @override
  @JsonKey(name: 'summary_type')
  String? get summaryType;
  @override
  String? get format;
  @override
  @JsonKey(name: 'created_after')
  DateTime? get createdAfter;
  @override
  @JsonKey(name: 'created_before')
  DateTime? get createdBefore;
  @override
  int get limit;
  @override
  int get offset;

  /// Create a copy of SummaryFilters
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SummaryFiltersImplCopyWith<_$SummaryFiltersImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
