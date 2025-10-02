// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'query_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$QueryState {
  bool get isLoading => throw _privateConstructorUsedError;
  List<ConversationItem> get conversation => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  List<String> get queryHistory => throw _privateConstructorUsedError;
  String? get pendingQuestion => throw _privateConstructorUsedError;
  List<ConversationSession> get sessions => throw _privateConstructorUsedError;
  String? get activeSessionId => throw _privateConstructorUsedError;
  String? get activeConversationId =>
      throw _privateConstructorUsedError; // Backend conversation ID for RAG context
  String? get currentEntityId =>
      throw _privateConstructorUsedError; // Entity ID (e.g., 'organization', uuid)
  String? get currentEntityType =>
      throw _privateConstructorUsedError; // 'organization', 'portfolio', 'program', 'project'
  String? get currentContextId => throw _privateConstructorUsedError;

  /// Create a copy of QueryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QueryStateCopyWith<QueryState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QueryStateCopyWith<$Res> {
  factory $QueryStateCopyWith(
    QueryState value,
    $Res Function(QueryState) then,
  ) = _$QueryStateCopyWithImpl<$Res, QueryState>;
  @useResult
  $Res call({
    bool isLoading,
    List<ConversationItem> conversation,
    String? error,
    List<String> queryHistory,
    String? pendingQuestion,
    List<ConversationSession> sessions,
    String? activeSessionId,
    String? activeConversationId,
    String? currentEntityId,
    String? currentEntityType,
    String? currentContextId,
  });
}

/// @nodoc
class _$QueryStateCopyWithImpl<$Res, $Val extends QueryState>
    implements $QueryStateCopyWith<$Res> {
  _$QueryStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QueryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? conversation = null,
    Object? error = freezed,
    Object? queryHistory = null,
    Object? pendingQuestion = freezed,
    Object? sessions = null,
    Object? activeSessionId = freezed,
    Object? activeConversationId = freezed,
    Object? currentEntityId = freezed,
    Object? currentEntityType = freezed,
    Object? currentContextId = freezed,
  }) {
    return _then(
      _value.copyWith(
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            conversation: null == conversation
                ? _value.conversation
                : conversation // ignore: cast_nullable_to_non_nullable
                      as List<ConversationItem>,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
            queryHistory: null == queryHistory
                ? _value.queryHistory
                : queryHistory // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            pendingQuestion: freezed == pendingQuestion
                ? _value.pendingQuestion
                : pendingQuestion // ignore: cast_nullable_to_non_nullable
                      as String?,
            sessions: null == sessions
                ? _value.sessions
                : sessions // ignore: cast_nullable_to_non_nullable
                      as List<ConversationSession>,
            activeSessionId: freezed == activeSessionId
                ? _value.activeSessionId
                : activeSessionId // ignore: cast_nullable_to_non_nullable
                      as String?,
            activeConversationId: freezed == activeConversationId
                ? _value.activeConversationId
                : activeConversationId // ignore: cast_nullable_to_non_nullable
                      as String?,
            currentEntityId: freezed == currentEntityId
                ? _value.currentEntityId
                : currentEntityId // ignore: cast_nullable_to_non_nullable
                      as String?,
            currentEntityType: freezed == currentEntityType
                ? _value.currentEntityType
                : currentEntityType // ignore: cast_nullable_to_non_nullable
                      as String?,
            currentContextId: freezed == currentContextId
                ? _value.currentContextId
                : currentContextId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$QueryStateImplCopyWith<$Res>
    implements $QueryStateCopyWith<$Res> {
  factory _$$QueryStateImplCopyWith(
    _$QueryStateImpl value,
    $Res Function(_$QueryStateImpl) then,
  ) = __$$QueryStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isLoading,
    List<ConversationItem> conversation,
    String? error,
    List<String> queryHistory,
    String? pendingQuestion,
    List<ConversationSession> sessions,
    String? activeSessionId,
    String? activeConversationId,
    String? currentEntityId,
    String? currentEntityType,
    String? currentContextId,
  });
}

/// @nodoc
class __$$QueryStateImplCopyWithImpl<$Res>
    extends _$QueryStateCopyWithImpl<$Res, _$QueryStateImpl>
    implements _$$QueryStateImplCopyWith<$Res> {
  __$$QueryStateImplCopyWithImpl(
    _$QueryStateImpl _value,
    $Res Function(_$QueryStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QueryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? conversation = null,
    Object? error = freezed,
    Object? queryHistory = null,
    Object? pendingQuestion = freezed,
    Object? sessions = null,
    Object? activeSessionId = freezed,
    Object? activeConversationId = freezed,
    Object? currentEntityId = freezed,
    Object? currentEntityType = freezed,
    Object? currentContextId = freezed,
  }) {
    return _then(
      _$QueryStateImpl(
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        conversation: null == conversation
            ? _value._conversation
            : conversation // ignore: cast_nullable_to_non_nullable
                  as List<ConversationItem>,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        queryHistory: null == queryHistory
            ? _value._queryHistory
            : queryHistory // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        pendingQuestion: freezed == pendingQuestion
            ? _value.pendingQuestion
            : pendingQuestion // ignore: cast_nullable_to_non_nullable
                  as String?,
        sessions: null == sessions
            ? _value._sessions
            : sessions // ignore: cast_nullable_to_non_nullable
                  as List<ConversationSession>,
        activeSessionId: freezed == activeSessionId
            ? _value.activeSessionId
            : activeSessionId // ignore: cast_nullable_to_non_nullable
                  as String?,
        activeConversationId: freezed == activeConversationId
            ? _value.activeConversationId
            : activeConversationId // ignore: cast_nullable_to_non_nullable
                  as String?,
        currentEntityId: freezed == currentEntityId
            ? _value.currentEntityId
            : currentEntityId // ignore: cast_nullable_to_non_nullable
                  as String?,
        currentEntityType: freezed == currentEntityType
            ? _value.currentEntityType
            : currentEntityType // ignore: cast_nullable_to_non_nullable
                  as String?,
        currentContextId: freezed == currentContextId
            ? _value.currentContextId
            : currentContextId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$QueryStateImpl implements _QueryState {
  const _$QueryStateImpl({
    this.isLoading = false,
    final List<ConversationItem> conversation = const [],
    this.error = null,
    final List<String> queryHistory = const [],
    this.pendingQuestion = null,
    final List<ConversationSession> sessions = const [],
    this.activeSessionId = null,
    this.activeConversationId = null,
    this.currentEntityId = null,
    this.currentEntityType = null,
    this.currentContextId = null,
  }) : _conversation = conversation,
       _queryHistory = queryHistory,
       _sessions = sessions;

  @override
  @JsonKey()
  final bool isLoading;
  final List<ConversationItem> _conversation;
  @override
  @JsonKey()
  List<ConversationItem> get conversation {
    if (_conversation is EqualUnmodifiableListView) return _conversation;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_conversation);
  }

  @override
  @JsonKey()
  final String? error;
  final List<String> _queryHistory;
  @override
  @JsonKey()
  List<String> get queryHistory {
    if (_queryHistory is EqualUnmodifiableListView) return _queryHistory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_queryHistory);
  }

  @override
  @JsonKey()
  final String? pendingQuestion;
  final List<ConversationSession> _sessions;
  @override
  @JsonKey()
  List<ConversationSession> get sessions {
    if (_sessions is EqualUnmodifiableListView) return _sessions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sessions);
  }

  @override
  @JsonKey()
  final String? activeSessionId;
  @override
  @JsonKey()
  final String? activeConversationId;
  // Backend conversation ID for RAG context
  @override
  @JsonKey()
  final String? currentEntityId;
  // Entity ID (e.g., 'organization', uuid)
  @override
  @JsonKey()
  final String? currentEntityType;
  // 'organization', 'portfolio', 'program', 'project'
  @override
  @JsonKey()
  final String? currentContextId;

  @override
  String toString() {
    return 'QueryState(isLoading: $isLoading, conversation: $conversation, error: $error, queryHistory: $queryHistory, pendingQuestion: $pendingQuestion, sessions: $sessions, activeSessionId: $activeSessionId, activeConversationId: $activeConversationId, currentEntityId: $currentEntityId, currentEntityType: $currentEntityType, currentContextId: $currentContextId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QueryStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            const DeepCollectionEquality().equals(
              other._conversation,
              _conversation,
            ) &&
            (identical(other.error, error) || other.error == error) &&
            const DeepCollectionEquality().equals(
              other._queryHistory,
              _queryHistory,
            ) &&
            (identical(other.pendingQuestion, pendingQuestion) ||
                other.pendingQuestion == pendingQuestion) &&
            const DeepCollectionEquality().equals(other._sessions, _sessions) &&
            (identical(other.activeSessionId, activeSessionId) ||
                other.activeSessionId == activeSessionId) &&
            (identical(other.activeConversationId, activeConversationId) ||
                other.activeConversationId == activeConversationId) &&
            (identical(other.currentEntityId, currentEntityId) ||
                other.currentEntityId == currentEntityId) &&
            (identical(other.currentEntityType, currentEntityType) ||
                other.currentEntityType == currentEntityType) &&
            (identical(other.currentContextId, currentContextId) ||
                other.currentContextId == currentContextId));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isLoading,
    const DeepCollectionEquality().hash(_conversation),
    error,
    const DeepCollectionEquality().hash(_queryHistory),
    pendingQuestion,
    const DeepCollectionEquality().hash(_sessions),
    activeSessionId,
    activeConversationId,
    currentEntityId,
    currentEntityType,
    currentContextId,
  );

  /// Create a copy of QueryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QueryStateImplCopyWith<_$QueryStateImpl> get copyWith =>
      __$$QueryStateImplCopyWithImpl<_$QueryStateImpl>(this, _$identity);
}

abstract class _QueryState implements QueryState {
  const factory _QueryState({
    final bool isLoading,
    final List<ConversationItem> conversation,
    final String? error,
    final List<String> queryHistory,
    final String? pendingQuestion,
    final List<ConversationSession> sessions,
    final String? activeSessionId,
    final String? activeConversationId,
    final String? currentEntityId,
    final String? currentEntityType,
    final String? currentContextId,
  }) = _$QueryStateImpl;

  @override
  bool get isLoading;
  @override
  List<ConversationItem> get conversation;
  @override
  String? get error;
  @override
  List<String> get queryHistory;
  @override
  String? get pendingQuestion;
  @override
  List<ConversationSession> get sessions;
  @override
  String? get activeSessionId;
  @override
  String? get activeConversationId; // Backend conversation ID for RAG context
  @override
  String? get currentEntityId; // Entity ID (e.g., 'organization', uuid)
  @override
  String? get currentEntityType; // 'organization', 'portfolio', 'program', 'project'
  @override
  String? get currentContextId;

  /// Create a copy of QueryState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QueryStateImplCopyWith<_$QueryStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ConversationItem {
  String get question => throw _privateConstructorUsedError;
  String get answer => throw _privateConstructorUsedError;
  List<String> get sources => throw _privateConstructorUsedError;
  double get confidence => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  bool get isAnswerPending => throw _privateConstructorUsedError;

  /// Create a copy of ConversationItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConversationItemCopyWith<ConversationItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationItemCopyWith<$Res> {
  factory $ConversationItemCopyWith(
    ConversationItem value,
    $Res Function(ConversationItem) then,
  ) = _$ConversationItemCopyWithImpl<$Res, ConversationItem>;
  @useResult
  $Res call({
    String question,
    String answer,
    List<String> sources,
    double confidence,
    DateTime timestamp,
    bool isAnswerPending,
  });
}

/// @nodoc
class _$ConversationItemCopyWithImpl<$Res, $Val extends ConversationItem>
    implements $ConversationItemCopyWith<$Res> {
  _$ConversationItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConversationItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? question = null,
    Object? answer = null,
    Object? sources = null,
    Object? confidence = null,
    Object? timestamp = null,
    Object? isAnswerPending = null,
  }) {
    return _then(
      _value.copyWith(
            question: null == question
                ? _value.question
                : question // ignore: cast_nullable_to_non_nullable
                      as String,
            answer: null == answer
                ? _value.answer
                : answer // ignore: cast_nullable_to_non_nullable
                      as String,
            sources: null == sources
                ? _value.sources
                : sources // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            isAnswerPending: null == isAnswerPending
                ? _value.isAnswerPending
                : isAnswerPending // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ConversationItemImplCopyWith<$Res>
    implements $ConversationItemCopyWith<$Res> {
  factory _$$ConversationItemImplCopyWith(
    _$ConversationItemImpl value,
    $Res Function(_$ConversationItemImpl) then,
  ) = __$$ConversationItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String question,
    String answer,
    List<String> sources,
    double confidence,
    DateTime timestamp,
    bool isAnswerPending,
  });
}

/// @nodoc
class __$$ConversationItemImplCopyWithImpl<$Res>
    extends _$ConversationItemCopyWithImpl<$Res, _$ConversationItemImpl>
    implements _$$ConversationItemImplCopyWith<$Res> {
  __$$ConversationItemImplCopyWithImpl(
    _$ConversationItemImpl _value,
    $Res Function(_$ConversationItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConversationItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? question = null,
    Object? answer = null,
    Object? sources = null,
    Object? confidence = null,
    Object? timestamp = null,
    Object? isAnswerPending = null,
  }) {
    return _then(
      _$ConversationItemImpl(
        question: null == question
            ? _value.question
            : question // ignore: cast_nullable_to_non_nullable
                  as String,
        answer: null == answer
            ? _value.answer
            : answer // ignore: cast_nullable_to_non_nullable
                  as String,
        sources: null == sources
            ? _value._sources
            : sources // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        isAnswerPending: null == isAnswerPending
            ? _value.isAnswerPending
            : isAnswerPending // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$ConversationItemImpl implements _ConversationItem {
  const _$ConversationItemImpl({
    required this.question,
    required this.answer,
    required final List<String> sources,
    required this.confidence,
    required this.timestamp,
    this.isAnswerPending = false,
  }) : _sources = sources;

  @override
  final String question;
  @override
  final String answer;
  final List<String> _sources;
  @override
  List<String> get sources {
    if (_sources is EqualUnmodifiableListView) return _sources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sources);
  }

  @override
  final double confidence;
  @override
  final DateTime timestamp;
  @override
  @JsonKey()
  final bool isAnswerPending;

  @override
  String toString() {
    return 'ConversationItem(question: $question, answer: $answer, sources: $sources, confidence: $confidence, timestamp: $timestamp, isAnswerPending: $isAnswerPending)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationItemImpl &&
            (identical(other.question, question) ||
                other.question == question) &&
            (identical(other.answer, answer) || other.answer == answer) &&
            const DeepCollectionEquality().equals(other._sources, _sources) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.isAnswerPending, isAnswerPending) ||
                other.isAnswerPending == isAnswerPending));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    question,
    answer,
    const DeepCollectionEquality().hash(_sources),
    confidence,
    timestamp,
    isAnswerPending,
  );

  /// Create a copy of ConversationItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationItemImplCopyWith<_$ConversationItemImpl> get copyWith =>
      __$$ConversationItemImplCopyWithImpl<_$ConversationItemImpl>(
        this,
        _$identity,
      );
}

abstract class _ConversationItem implements ConversationItem {
  const factory _ConversationItem({
    required final String question,
    required final String answer,
    required final List<String> sources,
    required final double confidence,
    required final DateTime timestamp,
    final bool isAnswerPending,
  }) = _$ConversationItemImpl;

  @override
  String get question;
  @override
  String get answer;
  @override
  List<String> get sources;
  @override
  double get confidence;
  @override
  DateTime get timestamp;
  @override
  bool get isAnswerPending;

  /// Create a copy of ConversationItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConversationItemImplCopyWith<_$ConversationItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ConversationSession {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  List<ConversationItem> get items => throw _privateConstructorUsedError;
  DateTime? get lastAccessedAt => throw _privateConstructorUsedError;

  /// Create a copy of ConversationSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConversationSessionCopyWith<ConversationSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationSessionCopyWith<$Res> {
  factory $ConversationSessionCopyWith(
    ConversationSession value,
    $Res Function(ConversationSession) then,
  ) = _$ConversationSessionCopyWithImpl<$Res, ConversationSession>;
  @useResult
  $Res call({
    String id,
    String title,
    DateTime createdAt,
    List<ConversationItem> items,
    DateTime? lastAccessedAt,
  });
}

/// @nodoc
class _$ConversationSessionCopyWithImpl<$Res, $Val extends ConversationSession>
    implements $ConversationSessionCopyWith<$Res> {
  _$ConversationSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConversationSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? createdAt = null,
    Object? items = null,
    Object? lastAccessedAt = freezed,
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
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<ConversationItem>,
            lastAccessedAt: freezed == lastAccessedAt
                ? _value.lastAccessedAt
                : lastAccessedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ConversationSessionImplCopyWith<$Res>
    implements $ConversationSessionCopyWith<$Res> {
  factory _$$ConversationSessionImplCopyWith(
    _$ConversationSessionImpl value,
    $Res Function(_$ConversationSessionImpl) then,
  ) = __$$ConversationSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    DateTime createdAt,
    List<ConversationItem> items,
    DateTime? lastAccessedAt,
  });
}

/// @nodoc
class __$$ConversationSessionImplCopyWithImpl<$Res>
    extends _$ConversationSessionCopyWithImpl<$Res, _$ConversationSessionImpl>
    implements _$$ConversationSessionImplCopyWith<$Res> {
  __$$ConversationSessionImplCopyWithImpl(
    _$ConversationSessionImpl _value,
    $Res Function(_$ConversationSessionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConversationSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? createdAt = null,
    Object? items = null,
    Object? lastAccessedAt = freezed,
  }) {
    return _then(
      _$ConversationSessionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<ConversationItem>,
        lastAccessedAt: freezed == lastAccessedAt
            ? _value.lastAccessedAt
            : lastAccessedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$ConversationSessionImpl implements _ConversationSession {
  const _$ConversationSessionImpl({
    required this.id,
    required this.title,
    required this.createdAt,
    required final List<ConversationItem> items,
    this.lastAccessedAt,
  }) : _items = items;

  @override
  final String id;
  @override
  final String title;
  @override
  final DateTime createdAt;
  final List<ConversationItem> _items;
  @override
  List<ConversationItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final DateTime? lastAccessedAt;

  @override
  String toString() {
    return 'ConversationSession(id: $id, title: $title, createdAt: $createdAt, items: $items, lastAccessedAt: $lastAccessedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationSessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.lastAccessedAt, lastAccessedAt) ||
                other.lastAccessedAt == lastAccessedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    createdAt,
    const DeepCollectionEquality().hash(_items),
    lastAccessedAt,
  );

  /// Create a copy of ConversationSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationSessionImplCopyWith<_$ConversationSessionImpl> get copyWith =>
      __$$ConversationSessionImplCopyWithImpl<_$ConversationSessionImpl>(
        this,
        _$identity,
      );
}

abstract class _ConversationSession implements ConversationSession {
  const factory _ConversationSession({
    required final String id,
    required final String title,
    required final DateTime createdAt,
    required final List<ConversationItem> items,
    final DateTime? lastAccessedAt,
  }) = _$ConversationSessionImpl;

  @override
  String get id;
  @override
  String get title;
  @override
  DateTime get createdAt;
  @override
  List<ConversationItem> get items;
  @override
  DateTime? get lastAccessedAt;

  /// Create a copy of ConversationSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConversationSessionImplCopyWith<_$ConversationSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
