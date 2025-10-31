import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'tier_settings.freezed.dart';
part 'tier_settings.g.dart';

/// Answer discovery tier types
enum AnswerTier {
  @JsonValue('rag')
  rag,
  @JsonValue('meeting_context')
  meetingContext,
  @JsonValue('live_conversation')
  liveConversation,
  @JsonValue('gpt_generated')
  gptGenerated,
}

extension AnswerTierExtension on AnswerTier {
  String get displayName {
    switch (this) {
      case AnswerTier.rag:
        return 'Tier 1: Document Search (RAG)';
      case AnswerTier.meetingContext:
        return 'Tier 2: Meeting Context';
      case AnswerTier.gptGenerated:
        return 'Tier 3: AI-Generated';
      case AnswerTier.liveConversation:
        return 'Tier 4: Live Monitoring';
    }
  }

  String get description {
    switch (this) {
      case AnswerTier.rag:
        return 'Search through uploaded documents and meeting transcripts';
      case AnswerTier.meetingContext:
        return 'Look for answers earlier in the current meeting';
      case AnswerTier.liveConversation:
        return 'Monitor live conversation for answers';
      case AnswerTier.gptGenerated:
        return 'Generate answers using AI when not found elsewhere';
    }
  }

  String get jsonValue {
    switch (this) {
      case AnswerTier.rag:
        return 'rag';
      case AnswerTier.meetingContext:
        return 'meeting_context';
      case AnswerTier.liveConversation:
        return 'live_conversation';
      case AnswerTier.gptGenerated:
        return 'gpt_generated';
    }
  }
}

/// Settings for which answer discovery tiers are enabled and which sections to display
@freezed
class TierSettings with _$TierSettings {
  const factory TierSettings({
    // Tier enablement settings
    @Default(true) bool ragEnabled,
    @Default(true) bool meetingContextEnabled,
    @Default(true) bool liveConversationEnabled,
    @Default(true) bool gptGeneratedEnabled,
    // Section visibility settings
    @Default(true) bool showQuestionsSection,
    @Default(true) bool showActionsSection,
  }) = _TierSettings;

  factory TierSettings.fromJson(Map<String, dynamic> json) =>
      _$TierSettingsFromJson(json);
}

extension TierSettingsExtension on TierSettings {
  /// Get list of enabled tiers in JSON format for backend
  List<String> get enabledTiers {
    final tiers = <String>[];
    if (ragEnabled) tiers.add('rag');
    if (meetingContextEnabled) tiers.add('meeting_context');
    if (liveConversationEnabled) tiers.add('live_conversation');
    if (gptGeneratedEnabled) tiers.add('gpt_generated');
    return tiers;
  }

  /// Check if a specific tier is enabled
  bool isTierEnabled(AnswerTier tier) {
    switch (tier) {
      case AnswerTier.rag:
        return ragEnabled;
      case AnswerTier.meetingContext:
        return meetingContextEnabled;
      case AnswerTier.liveConversation:
        return liveConversationEnabled;
      case AnswerTier.gptGenerated:
        return gptGeneratedEnabled;
    }
  }

  /// Copy with specific tier enabled/disabled
  TierSettings withTierEnabled(AnswerTier tier, bool enabled) {
    switch (tier) {
      case AnswerTier.rag:
        return copyWith(ragEnabled: enabled);
      case AnswerTier.meetingContext:
        return copyWith(meetingContextEnabled: enabled);
      case AnswerTier.liveConversation:
        return copyWith(liveConversationEnabled: enabled);
      case AnswerTier.gptGenerated:
        return copyWith(gptGeneratedEnabled: enabled);
    }
  }
}
