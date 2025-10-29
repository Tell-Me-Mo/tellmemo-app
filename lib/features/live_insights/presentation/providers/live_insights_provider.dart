import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/live_insight_model.dart';
import '../../domain/services/live_insights_websocket_service.dart';

part 'live_insights_provider.g.dart';

/// Provider for LiveInsightsWebSocketService (keepAlive)
/// Manages persistent WebSocket connection for live meeting insights
@Riverpod(keepAlive: true)
LiveInsightsWebSocketService liveInsightsWebSocketService(Ref ref) {
  final service = LiveInsightsWebSocketService();

  ref.onDispose(() {
    debugPrint('[LiveInsightsProvider] Disposing WebSocket service');
    service.dispose();
  });

  return service;
}

/// Provider for tracking live questions during a meeting
/// Maintains a map of questions by ID for efficient updates
@riverpod
class LiveQuestionsTracker extends _$LiveQuestionsTracker {
  final Map<String, LiveQuestion> _questions = {};
  StreamSubscription<LiveQuestion>? _questionSubscription;

  @override
  Future<List<LiveQuestion>> build() async {
    final service = ref.watch(liveInsightsWebSocketServiceProvider);

    // Subscribe to question updates
    _questionSubscription?.cancel();
    _questionSubscription = service.questionUpdates.listen(
      (question) {
        _handleQuestionUpdate(question);
      },
      onError: (error) {
        debugPrint('[LiveQuestionsTracker] Stream error: $error');
      },
    );

    // Cleanup on dispose
    ref.onDispose(() {
      debugPrint('[LiveQuestionsTracker] Disposing subscription');
      _questionSubscription?.cancel();
    });

    return _questions.values.toList();
  }

  /// Handle question update from WebSocket
  void _handleQuestionUpdate(LiveQuestion question) {
    debugPrint(
        '[LiveQuestionsTracker] Received question update: ${question.id} - ${question.status} - tierResults count: ${question.tierResults.length}');

    // DEBUG: Log tier results details
    if (question.tierResults.isNotEmpty) {
      debugPrint('[LiveQuestionsTracker] Tier results details:');
      for (var i = 0; i < question.tierResults.length; i++) {
        final tr = question.tierResults[i];
        debugPrint('  [$i] tierType=${tr.tierType}, content="${tr.content.substring(0, tr.content.length > 50 ? 50 : tr.content.length)}...", confidence=${tr.confidence}');
      }
    } else {
      debugPrint('[LiveQuestionsTracker] WARNING: No tier results in question update!');
    }

    // Check if question was dismissed by user (skip if dismissed)
    final dismissedState = ref.read(dismissedInsightsProvider);
    dismissedState.whenData((dismissed) {
      if (dismissed['questions']?.contains(question.id) == true) {
        debugPrint(
            '[LiveQuestionsTracker] Skipping dismissed question: ${question.id}');
        return;
      }

      // Merge with existing question to accumulate tier results
      final existingQuestion = _questions[question.id];
      if (existingQuestion != null) {
        // Merge tier results (avoid duplicates based on tierType and content)
        final mergedTierResults = <TierResult>[...existingQuestion.tierResults];

        for (final newResult in question.tierResults) {
          // Check if this tier result already exists
          final isDuplicate = mergedTierResults.any((existing) =>
              existing.tierType == newResult.tierType &&
              existing.content == newResult.content);

          if (!isDuplicate) {
            mergedTierResults.add(newResult);
            debugPrint('[LiveQuestionsTracker] Adding new tier result: ${newResult.tierType}');
          }
        }

        // Create merged question with accumulated tier results
        _questions[question.id] = question.copyWith(
          tierResults: mergedTierResults,
        );

        debugPrint('[LiveQuestionsTracker] Merged question ${question.id}: total tierResults = ${mergedTierResults.length}');
      } else {
        // First time seeing this question - add as is
        _questions[question.id] = question;
        debugPrint('[LiveQuestionsTracker] New question ${question.id}: tierResults = ${question.tierResults.length}');
      }

      // Update state with new list
      _updateState();
    });

    // If state not loaded yet, add question anyway (will be filtered later)
    if (!dismissedState.hasValue) {
      final existingQuestion = _questions[question.id];
      if (existingQuestion != null) {
        // Merge tier results
        final mergedTierResults = <TierResult>[...existingQuestion.tierResults];

        for (final newResult in question.tierResults) {
          final isDuplicate = mergedTierResults.any((existing) =>
              existing.tierType == newResult.tierType &&
              existing.content == newResult.content);

          if (!isDuplicate) {
            mergedTierResults.add(newResult);
          }
        }

        _questions[question.id] = question.copyWith(
          tierResults: mergedTierResults,
        );
      } else {
        _questions[question.id] = question;
      }
      _updateState();
    }
  }

  /// Update provider state with current questions list
  void _updateState() {
    // Sort by timestamp (newest first)
    final sortedQuestions = _questions.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    state = AsyncValue.data(sortedQuestions);
  }

  /// Mark question as answered (user feedback)
  Future<void> markAsAnswered(String questionId) async {
    final service = ref.read(liveInsightsWebSocketServiceProvider);
    await service.markQuestionAsAnswered(questionId);

    // Optimistically update local state
    final question = _questions[questionId];
    if (question != null) {
      _questions[questionId] = question.copyWith(
        status: InsightStatus.answered,
        answerSource: AnswerSource.userProvided,
      );
      _updateState();
    }
  }

  /// Mark question as needs follow-up (user feedback)
  Future<void> markNeedsFollowUp(String questionId) async {
    final service = ref.read(liveInsightsWebSocketServiceProvider);
    await service.markQuestionNeedsFollowUp(questionId);
  }

  /// Dismiss question (user feedback)
  Future<void> dismissQuestion(String questionId) async {
    final service = ref.read(liveInsightsWebSocketServiceProvider);
    await service.dismissQuestion(questionId);

    // Remove from local state
    _questions.remove(questionId);
    _updateState();
  }

  /// Clear all questions (e.g., on meeting end)
  void clearAll() {
    _questions.clear();
    _updateState();
  }

  /// Get question by ID
  LiveQuestion? getQuestion(String questionId) {
    return _questions[questionId];
  }

  /// Get questions by status
  List<LiveQuestion> getQuestionsByStatus(InsightStatus status) {
    return _questions.values
        .where((q) => q.status == status)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}

/// Provider for tracking live actions during a meeting
/// Maintains a map of actions by ID for efficient updates
@riverpod
class LiveActionsTracker extends _$LiveActionsTracker {
  final Map<String, LiveAction> _actions = {};
  StreamSubscription<LiveAction>? _actionSubscription;

  @override
  Future<List<LiveAction>> build() async {
    final service = ref.watch(liveInsightsWebSocketServiceProvider);

    // Subscribe to action updates
    _actionSubscription?.cancel();
    _actionSubscription = service.actionUpdates.listen(
      (action) {
        _handleActionUpdate(action);
      },
      onError: (error) {
        debugPrint('[LiveActionsTracker] Stream error: $error');
      },
    );

    // Cleanup on dispose
    ref.onDispose(() {
      debugPrint('[LiveActionsTracker] Disposing subscription');
      _actionSubscription?.cancel();
    });

    return _actions.values.toList();
  }

  /// Handle action update from WebSocket
  void _handleActionUpdate(LiveAction action) {
    debugPrint(
        '[LiveActionsTracker] Received action update: ${action.id} - ${action.status} (completeness: ${action.completenessScore})');

    // Check if action was dismissed by user (skip if dismissed)
    final dismissedState = ref.read(dismissedInsightsProvider);
    dismissedState.whenData((dismissed) {
      if (dismissed['actions']?.contains(action.id) == true) {
        debugPrint(
            '[LiveActionsTracker] Skipping dismissed action: ${action.id}');
        return;
      }

      // Update or add action to map
      _actions[action.id] = action;

      // Update state with new list
      _updateState();
    });

    // If state not loaded yet, add action anyway (will be filtered later)
    if (!dismissedState.hasValue) {
      _actions[action.id] = action;
      _updateState();
    }
  }

  /// Update provider state with current actions list
  void _updateState() {
    // Sort by timestamp (newest first)
    final sortedActions = _actions.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    state = AsyncValue.data(sortedActions);
  }

  /// Assign action to owner with deadline (user feedback)
  Future<void> assignAction(
      String actionId, String owner, DateTime? deadline) async {
    final service = ref.read(liveInsightsWebSocketServiceProvider);
    await service.assignAction(actionId, owner, deadline);

    // Optimistically update local state
    final action = _actions[actionId];
    if (action != null) {
      _actions[actionId] = action.copyWith(
        owner: owner,
        deadline: deadline,
        completenessScore:
            _calculateCompleteness(action.description, owner, deadline),
      );
      _updateState();
    }
  }

  /// Mark action as complete (user feedback)
  Future<void> markComplete(String actionId) async {
    final service = ref.read(liveInsightsWebSocketServiceProvider);
    await service.markActionComplete(actionId);

    // Optimistically update local state
    final action = _actions[actionId];
    if (action != null) {
      _actions[actionId] = action.copyWith(
        status: InsightStatus.complete,
      );
      _updateState();
    }
  }

  /// Dismiss action (user feedback)
  Future<void> dismissAction(String actionId) async {
    final service = ref.read(liveInsightsWebSocketServiceProvider);
    await service.dismissAction(actionId);

    // Remove from local state
    _actions.remove(actionId);
    _updateState();
  }

  /// Calculate action completeness score
  /// Based on HLD: description 40%, owner 30%, deadline 30%
  double _calculateCompleteness(
      String description, String? owner, DateTime? deadline) {
    double score = 0.4; // Description always present

    if (owner != null && owner.isNotEmpty) {
      score += 0.3;
    }

    if (deadline != null) {
      score += 0.3;
    }

    return score;
  }

  /// Clear all actions (e.g., on meeting end)
  void clearAll() {
    _actions.clear();
    _updateState();
  }

  /// Get action by ID
  LiveAction? getAction(String actionId) {
    return _actions[actionId];
  }

  /// Get actions by status
  List<LiveAction> getActionsByStatus(InsightStatus status) {
    return _actions.values
        .where((a) => a.status == status)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get incomplete actions (completeness < 1.0)
  List<LiveAction> getIncompleteActions() {
    return _actions.values
        .where((a) => a.completenessScore < 1.0 && a.status != InsightStatus.complete)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}

/// Provider for tracking live transcriptions during a meeting
@riverpod
class LiveTranscriptionsTracker extends _$LiveTranscriptionsTracker {
  final List<TranscriptSegment> _transcriptions = [];
  StreamSubscription<TranscriptSegment>? _transcriptionSubscription;
  static const int _maxTranscriptions = 100; // Keep last 100 segments

  @override
  Future<List<TranscriptSegment>> build() async {
    final service = ref.watch(liveInsightsWebSocketServiceProvider);

    // Subscribe to transcription updates
    _transcriptionSubscription?.cancel();
    _transcriptionSubscription = service.transcriptionUpdates.listen(
      (transcription) {
        _handleTranscriptionUpdate(transcription);
      },
      onError: (error) {
        debugPrint('[LiveTranscriptionsTracker] Stream error: $error');
      },
    );

    // Cleanup on dispose
    ref.onDispose(() {
      debugPrint('[LiveTranscriptionsTracker] Disposing subscription');
      _transcriptionSubscription?.cancel();
    });

    return _transcriptions;
  }

  /// Handle transcription update from WebSocket
  void _handleTranscriptionUpdate(TranscriptSegment transcription) {
    // If partial, check if we already have a partial with same ID and update it
    if (!transcription.isFinal) {
      final index = _transcriptions.indexWhere((t) => t.id == transcription.id);
      if (index != -1) {
        _transcriptions[index] = transcription;
      } else {
        _transcriptions.add(transcription);
      }
    } else {
      // Final transcript: replace partial if exists, otherwise add
      final index = _transcriptions.indexWhere((t) => t.id == transcription.id);
      if (index != -1) {
        _transcriptions[index] = transcription;
      } else {
        _transcriptions.add(transcription);
      }
    }

    // Trim old transcriptions (keep last 100)
    if (_transcriptions.length > _maxTranscriptions) {
      _transcriptions.removeRange(0, _transcriptions.length - _maxTranscriptions);
    }

    _updateState();
  }

  /// Update provider state
  void _updateState() {
    state = AsyncValue.data(List.from(_transcriptions));
  }

  /// Clear all transcriptions
  void clearAll() {
    _transcriptions.clear();
    _updateState();
  }

  /// Get latest N transcriptions
  List<TranscriptSegment> getLatest(int count) {
    if (_transcriptions.length <= count) {
      return _transcriptions;
    }
    return _transcriptions.sublist(_transcriptions.length - count);
  }
}

/// Provider for managing Live Insights connection state
/// Connects to WebSocket when session_id is available
@riverpod
class LiveInsightsConnection extends _$LiveInsightsConnection {
  StreamSubscription<bool>? _connectionStateSubscription;

  @override
  Future<bool> build() async {
    final service = ref.watch(liveInsightsWebSocketServiceProvider);

    // Subscribe to connection state
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = service.connectionState.listen(
      (isConnected) {
        state = AsyncValue.data(isConnected);
      },
    );

    ref.onDispose(() {
      _connectionStateSubscription?.cancel();
    });

    return service.isConnected;
  }

  /// Connect to session
  Future<void> connect(String sessionId) async {
    final service = ref.read(liveInsightsWebSocketServiceProvider);
    await service.connect(sessionId);
  }

  /// Disconnect
  Future<void> disconnect() async {
    final service = ref.read(liveInsightsWebSocketServiceProvider);
    await service.dispose();
  }
}

/// Provider for local persistence of dismissed items
/// Stores dismissed question/action IDs to prevent showing them again
@Riverpod(keepAlive: true)
class DismissedInsights extends _$DismissedInsights {
  static const String _questionsKey = 'dismissed_questions';
  static const String _actionsKey = 'dismissed_actions';

  @override
  Future<Map<String, Set<String>>> build() async {
    final prefs = await SharedPreferences.getInstance();

    final dismissedQuestions =
        prefs.getStringList(_questionsKey)?.toSet() ?? <String>{};
    final dismissedActions =
        prefs.getStringList(_actionsKey)?.toSet() ?? <String>{};

    return {
      'questions': dismissedQuestions,
      'actions': dismissedActions,
    };
  }

  /// Add dismissed question
  Future<void> addDismissedQuestion(String questionId) async {
    final current = await future;
    final questions = Set<String>.from(current['questions']!);
    questions.add(questionId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_questionsKey, questions.toList());

    state = AsyncValue.data({
      'questions': questions,
      'actions': current['actions']!,
    });
  }

  /// Add dismissed action
  Future<void> addDismissedAction(String actionId) async {
    final current = await future;
    final actions = Set<String>.from(current['actions']!);
    actions.add(actionId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_actionsKey, actions.toList());

    state = AsyncValue.data({
      'questions': current['questions']!,
      'actions': actions,
    });
  }

  /// Clear all dismissed items (e.g., on new meeting)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_questionsKey);
    await prefs.remove(_actionsKey);

    state = AsyncValue.data({
      'questions': <String>{},
      'actions': <String>{},
    });
  }

  /// Check if question is dismissed
  bool isQuestionDismissed(String questionId) {
    return state.value?['questions']?.contains(questionId) ?? false;
  }

  /// Check if action is dismissed
  bool isActionDismissed(String actionId) {
    return state.value?['actions']?.contains(actionId) ?? false;
  }
}
