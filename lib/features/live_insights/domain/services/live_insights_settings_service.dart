import 'package:shared_preferences/shared_preferences.dart';
import '../models/live_insights_settings.dart';
import '../models/proactive_assistance_model.dart';

/// Service for persisting Live Insights settings to local storage
class LiveInsightsSettingsService {
  static const String _keyPrefix = 'live_insights_settings_';

  // Keys for different preferences
  static const String _keyEnabledPhases = '${_keyPrefix}enabled_phases';
  static const String _keyQuietMode = '${_keyPrefix}quiet_mode';
  static const String _keyShowCollapsedItems = '${_keyPrefix}show_collapsed_items';
  static const String _keyEnableFeedback = '${_keyPrefix}enable_feedback';
  static const String _keyAutoExpandHighConfidence = '${_keyPrefix}auto_expand_high_confidence';

  final SharedPreferences _prefs;

  LiveInsightsSettingsService(this._prefs);

  /// Factory constructor to create instance
  static Future<LiveInsightsSettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LiveInsightsSettingsService(prefs);
  }

  /// Save settings to local storage
  Future<void> saveSettings(LiveInsightsSettings settings) async {
    // Save enabled phases as list of strings
    await _prefs.setStringList(
      _keyEnabledPhases,
      settings.enabledPhases.map((phase) => _assistanceTypeToString(phase)).toList(),
    );

    await _prefs.setBool(_keyQuietMode, settings.quietMode);
    await _prefs.setBool(_keyShowCollapsedItems, settings.showCollapsedItems);
    await _prefs.setBool(_keyEnableFeedback, settings.enableFeedback);
    await _prefs.setBool(_keyAutoExpandHighConfidence, settings.autoExpandHighConfidence);
  }

  /// Load settings from local storage
  LiveInsightsSettings loadSettings() {
    // Load enabled phases
    final phaseStrings = _prefs.getStringList(_keyEnabledPhases);
    final enabledPhases = phaseStrings != null
        ? phaseStrings
            .map((str) => _stringToAssistanceType(str))
            .whereType<ProactiveAssistanceType>()
            .toSet()
        : LiveInsightsSettings.defaultEnabledPhases;

    return LiveInsightsSettings(
      enabledPhases: enabledPhases,
      quietMode: _prefs.getBool(_keyQuietMode) ?? false,
      showCollapsedItems: _prefs.getBool(_keyShowCollapsedItems) ?? true,
      enableFeedback: _prefs.getBool(_keyEnableFeedback) ?? true,
      autoExpandHighConfidence: _prefs.getBool(_keyAutoExpandHighConfidence) ?? true,
    );
  }

  /// Toggle a specific phase on/off
  Future<void> togglePhase(ProactiveAssistanceType phase) async {
    final currentSettings = loadSettings();
    final newEnabledPhases = Set<ProactiveAssistanceType>.from(currentSettings.enabledPhases);

    if (newEnabledPhases.contains(phase)) {
      newEnabledPhases.remove(phase);
    } else {
      newEnabledPhases.add(phase);
    }

    await saveSettings(currentSettings.copyWith(enabledPhases: newEnabledPhases));
  }

  /// Enable all phases
  Future<void> enableAllPhases() async {
    final currentSettings = loadSettings();
    await saveSettings(
      currentSettings.copyWith(enabledPhases: LiveInsightsSettings.allPhases),
    );
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    await saveSettings(const LiveInsightsSettings());
  }

  /// Clear all settings
  Future<void> clearAllSettings() async {
    final keys = _prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  /// Convert ProactiveAssistanceType to string for storage
  String _assistanceTypeToString(ProactiveAssistanceType type) {
    switch (type) {
      case ProactiveAssistanceType.autoAnswer:
        return 'auto_answer';
      case ProactiveAssistanceType.clarificationNeeded:
        return 'clarification_needed';
      case ProactiveAssistanceType.conflictDetected:
        return 'conflict_detected';
      case ProactiveAssistanceType.incompleteActionItem:
        return 'incomplete_action_item';
      case ProactiveAssistanceType.followUpSuggestion:
        return 'follow_up_suggestion';
      case ProactiveAssistanceType.repetitionDetected:
        return 'repetition_detected';
    }
  }

  /// Convert string to ProactiveAssistanceType
  ProactiveAssistanceType? _stringToAssistanceType(String str) {
    switch (str) {
      case 'auto_answer':
        return ProactiveAssistanceType.autoAnswer;
      case 'clarification_needed':
        return ProactiveAssistanceType.clarificationNeeded;
      case 'conflict_detected':
        return ProactiveAssistanceType.conflictDetected;
      case 'incomplete_action_item':
        return ProactiveAssistanceType.incompleteActionItem;
      case 'follow_up_suggestion':
        return ProactiveAssistanceType.followUpSuggestion;
      case 'repetition_detected':
        return ProactiveAssistanceType.repetitionDetected;
      default:
        return null;
    }
  }
}
