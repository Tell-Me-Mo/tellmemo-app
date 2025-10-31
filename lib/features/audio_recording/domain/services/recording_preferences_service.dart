import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting recording-related user preferences
class RecordingPreferencesService {
  static const String _keyAiAssistantEnabled = 'recording_prefs_ai_assistant_enabled';

  final SharedPreferences _prefs;

  RecordingPreferencesService(this._prefs);

  /// Factory constructor to create service with SharedPreferences
  static Future<RecordingPreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return RecordingPreferencesService(prefs);
  }

  /// Save AI Assistant enabled preference
  Future<void> setAiAssistantEnabled(bool enabled) async {
    await _prefs.setBool(_keyAiAssistantEnabled, enabled);
  }

  /// Load AI Assistant enabled preference (default: false)
  bool getAiAssistantEnabled() {
    return _prefs.getBool(_keyAiAssistantEnabled) ?? false;
  }

  /// Clear all recording preferences
  Future<void> clearAll() async {
    await _prefs.remove(_keyAiAssistantEnabled);
  }
}
