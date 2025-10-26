// lib/features/live_insights/data/models/live_insight_model.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pm_master_v2/core/converters/date_time_converter.dart';

part 'live_insight_model.freezed.dart';
part 'live_insight_model.g.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Status of a live insight (question or action)
@JsonEnum(fieldRename: FieldRename.snake)
enum InsightStatus {
  /// Actively searching for answers (questions only)
  searching,

  /// Answer found from RAG or meeting context (questions only)
  found,

  /// Monitoring live conversation for answer (questions only)
  monitoring,

  /// Question was answered (questions only)
  answered,

  /// Question remains unanswered after all tiers (questions only)
  unanswered,

  /// Action is being tracked (actions only)
  tracked,

  /// Action is complete with all details (actions only)
  complete,
}

/// Type of answer discovery tier
@JsonEnum(fieldRename: FieldRename.snake)
enum TierType {
  /// Tier 1: Found in document repository (RAG search)
  rag,

  /// Tier 2: Found earlier in current meeting transcript
  meetingContext,

  /// Tier 3: Answered in live conversation (monitoring)
  liveConversation,

  /// Tier 4: AI-generated answer based on general knowledge
  gptGenerated,
}

/// Source of answer for questions
@JsonEnum(fieldRename: FieldRename.snake)
enum AnswerSource {
  /// From RAG document search (Tier 1)
  rag,

  /// From earlier in meeting transcript (Tier 2)
  meetingContext,

  /// From live conversation monitoring (Tier 3)
  liveConversation,

  /// AI-generated from GPT knowledge (Tier 4)
  gptGenerated,

  /// User manually marked as answered
  userProvided,

  /// No answer found
  unanswered,
}

/// Completeness level for action items
enum ActionCompleteness {
  /// Only description available (40% complete)
  descriptionOnly,

  /// Description + owner OR deadline (70% complete)
  partial,

  /// Description + owner + deadline (100% complete)
  complete,
}

// ============================================================================
// TIER RESULT MODEL
// ============================================================================

/// Result from a single answer discovery tier
@freezed
class TierResult with _$TierResult {
  const factory TierResult({
    /// Which tier this result is from
    required TierType tierType,

    /// The answer or document content
    required String content,

    /// Confidence score (0.0 - 1.0)
    required double confidence,

    /// Additional metadata (document URL, timestamp, etc.)
    @Default({}) Map<String, dynamic> metadata,

    /// Source identifier (document name, timestamp, etc.)
    String? source,

    /// Timestamp when this result was found
    @DateTimeConverter() required DateTime foundAt,
  }) = _TierResult;

  factory TierResult.fromJson(Map<String, dynamic> json) =>
      _$TierResultFromJson(json);
}

// ============================================================================
// LIVE QUESTION MODEL
// ============================================================================

/// Real-time question detected during live meeting
@freezed
class LiveQuestion with _$LiveQuestion {
  const LiveQuestion._();

  const factory LiveQuestion({
    /// Unique identifier for this question
    required String id,

    /// The question text as spoken
    required String text,

    /// Speaker who asked the question
    String? speaker,

    /// Timestamp when question was detected
    @DateTimeConverter() required DateTime timestamp,

    /// Current status of the question
    required InsightStatus status,

    /// Results from all four answer discovery tiers
    @Default([]) List<TierResult> tierResults,

    /// Primary answer source (if answered)
    AnswerSource? answerSource,

    /// Question category
    @Default('factual') String category,

    /// Confidence score of question detection (0.0 - 1.0)
    @Default(0.0) double confidence,

    /// Additional metadata (context, related questions, etc.)
    @Default({}) Map<String, dynamic> metadata,

    /// Timestamp when question was answered (if applicable)
    @DateTimeConverterNullable() DateTime? answeredAt,
  }) = _LiveQuestion;

  factory LiveQuestion.fromJson(Map<String, dynamic> json) =>
      _$LiveQuestionFromJson(json);

  /// Check if question is currently searching for answers
  bool get isSearching => status == InsightStatus.searching;

  /// Check if answer was found
  bool get isAnswered => status == InsightStatus.answered;

  /// Check if question is still being monitored
  bool get isMonitoring => status == InsightStatus.monitoring;

  /// Check if question remains unanswered
  bool get isUnanswered => status == InsightStatus.unanswered;

  /// Get display-friendly speaker label
  String get displaySpeaker => speaker ?? 'Unknown Speaker';

  /// Get RAG tier results only
  List<TierResult> get ragResults =>
      tierResults.where((r) => r.tierType == TierType.rag).toList();

  /// Get meeting context tier results only
  List<TierResult> get meetingContextResults =>
      tierResults.where((r) => r.tierType == TierType.meetingContext).toList();

  /// Get live conversation tier results only
  List<TierResult> get liveConversationResults =>
      tierResults.where((r) => r.tierType == TierType.liveConversation).toList();

  /// Get GPT-generated tier results only
  List<TierResult> get gptGeneratedResults =>
      tierResults.where((r) => r.tierType == TierType.gptGenerated).toList();

  /// Check if this question has any results from a specific tier
  bool hasTierResults(TierType tier) =>
      tierResults.any((r) => r.tierType == tier);

  /// Get the best (highest confidence) result from all tiers
  TierResult? get bestResult {
    if (tierResults.isEmpty) return null;
    return tierResults.reduce(
      (a, b) => a.confidence > b.confidence ? a : b,
    );
  }
}

// ============================================================================
// LIVE ACTION MODEL
// ============================================================================

/// Real-time action item detected during live meeting
@freezed
class LiveAction with _$LiveAction {
  const LiveAction._();

  const factory LiveAction({
    /// Unique identifier for this action
    required String id,

    /// Action description
    required String description,

    /// Assigned owner (if specified)
    String? owner,

    /// Deadline (if specified)
    @DateTimeConverterNullable() DateTime? deadline,

    /// Completeness score (0.0 - 1.0)
    @Default(0.4) double completenessScore,

    /// Current status of the action
    @Default(InsightStatus.tracked) InsightStatus status,

    /// Speaker who mentioned the action
    String? speaker,

    /// Timestamp when action was detected
    @DateTimeConverter() required DateTime timestamp,

    /// Confidence score of action detection (0.0 - 1.0)
    @Default(0.0) double confidence,

    /// Additional metadata (dependencies, context, etc.)
    @Default({}) Map<String, dynamic> metadata,

    /// Timestamp when action was marked complete (if applicable)
    @DateTimeConverterNullable() DateTime? completedAt,
  }) = _LiveAction;

  factory LiveAction.fromJson(Map<String, dynamic> json) =>
      _$LiveActionFromJson(json);

  /// Calculate completeness level based on available information
  ActionCompleteness get completenessLevel {
    final hasDescription = description.isNotEmpty;
    final hasOwner = owner != null && owner!.isNotEmpty;
    final hasDeadline = deadline != null;

    if (hasDescription && hasOwner && hasDeadline) {
      return ActionCompleteness.complete;
    } else if (hasDescription && (hasOwner || hasDeadline)) {
      return ActionCompleteness.partial;
    } else {
      return ActionCompleteness.descriptionOnly;
    }
  }

  /// Check if action is being tracked
  bool get isTracked => status == InsightStatus.tracked;

  /// Check if action is complete
  bool get isComplete => status == InsightStatus.complete;

  /// Get display-friendly speaker label
  String get displaySpeaker => speaker ?? 'Unknown Speaker';

  /// Get badge color based on completeness
  String get badgeColor {
    switch (completenessLevel) {
      case ActionCompleteness.complete:
        return 'green';
      case ActionCompleteness.partial:
        return 'yellow';
      case ActionCompleteness.descriptionOnly:
        return 'gray';
    }
  }

  /// Check if owner is assigned
  bool get hasOwner => owner != null && owner!.isNotEmpty;

  /// Check if deadline is set
  bool get hasDeadline => deadline != null;

  /// Get missing information list
  List<String> get missingInformation {
    final missing = <String>[];
    if (!hasOwner) missing.add('owner');
    if (!hasDeadline) missing.add('deadline');
    return missing;
  }

  /// Get completeness percentage for UI display
  int get completenessPercentage => (completenessScore * 100).round();

  /// Get display-friendly deadline text
  String get deadlineDisplay {
    if (deadline == null) return 'No deadline';

    final now = DateTime.now();
    final difference = deadline!.difference(now);

    if (difference.inDays < 0) {
      return 'Overdue';
    } else if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays < 7) {
      return 'In ${difference.inDays} days';
    } else {
      return deadline!.toLocal().toString().split(' ')[0]; // YYYY-MM-DD
    }
  }
}

// ============================================================================
// EXTENSION METHODS
// ============================================================================

/// Extension methods for TierType enum
extension TierTypeX on TierType {
  /// Get display label for UI
  String get displayLabel {
    switch (this) {
      case TierType.rag:
        return 'From Documents';
      case TierType.meetingContext:
        return 'Earlier in Meeting';
      case TierType.liveConversation:
        return 'Answered Live';
      case TierType.gptGenerated:
        return 'AI Answer';
    }
  }

  /// Get icon emoji for UI
  String get icon {
    switch (this) {
      case TierType.rag:
        return '📚';
      case TierType.meetingContext:
        return '💬';
      case TierType.liveConversation:
        return '👂';
      case TierType.gptGenerated:
        return '🤖';
    }
  }

  /// Get display color for UI
  String get displayColor {
    switch (this) {
      case TierType.rag:
        return 'blue';
      case TierType.meetingContext:
        return 'purple';
      case TierType.liveConversation:
        return 'green';
      case TierType.gptGenerated:
        return 'orange';
    }
  }
}

/// Extension methods for InsightStatus enum
extension InsightStatusX on InsightStatus {
  /// Get display label for UI
  String get displayLabel {
    switch (this) {
      case InsightStatus.searching:
        return 'Searching';
      case InsightStatus.found:
        return 'Found';
      case InsightStatus.monitoring:
        return 'Monitoring';
      case InsightStatus.answered:
        return 'Answered';
      case InsightStatus.unanswered:
        return 'Unanswered';
      case InsightStatus.tracked:
        return 'Tracked';
      case InsightStatus.complete:
        return 'Complete';
    }
  }

  /// Get icon for UI
  String get icon {
    switch (this) {
      case InsightStatus.searching:
        return '🔍';
      case InsightStatus.found:
        return '✓';
      case InsightStatus.monitoring:
        return '👀';
      case InsightStatus.answered:
        return '✅';
      case InsightStatus.unanswered:
        return '❓';
      case InsightStatus.tracked:
        return '📌';
      case InsightStatus.complete:
        return '✅';
    }
  }
}

/// Extension methods for ActionCompleteness enum
extension ActionCompletenessX on ActionCompleteness {
  /// Get numeric score (0.0 - 1.0)
  double get score {
    switch (this) {
      case ActionCompleteness.descriptionOnly:
        return 0.4;
      case ActionCompleteness.partial:
        return 0.7;
      case ActionCompleteness.complete:
        return 1.0;
    }
  }

  /// Get display label for UI
  String get displayLabel {
    switch (this) {
      case ActionCompleteness.descriptionOnly:
        return 'Description Only';
      case ActionCompleteness.partial:
        return 'Partially Complete';
      case ActionCompleteness.complete:
        return 'Complete';
    }
  }
}
