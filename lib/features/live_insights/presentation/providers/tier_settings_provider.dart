import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/models/tier_settings.dart';

part 'tier_settings_provider.g.dart';

/// Provider for managing answer discovery tier settings
/// Persists settings to SharedPreferences
@Riverpod(keepAlive: true)
class TierSettingsNotifier extends _$TierSettingsNotifier {
  static const String _storageKey = 'tier_settings';

  @override
  Future<TierSettings> build() async {
    // Load settings from storage
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return TierSettings.fromJson(json);
      } catch (e) {
        // If parsing fails, return default settings
        return const TierSettings();
      }
    }

    // Return default settings (all tiers enabled)
    return const TierSettings();
  }

  /// Update settings and persist to storage
  Future<void> updateSettings(TierSettings settings) async {
    state = AsyncValue.data(settings);

    // Save to storage
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(settings.toJson());
    await prefs.setString(_storageKey, jsonString);
  }

  /// Toggle a specific tier on/off
  Future<void> toggleTier(AnswerTier tier, bool enabled) async {
    final currentSettings = await future;
    final newSettings = currentSettings.withTierEnabled(tier, enabled);
    await updateSettings(newSettings);
  }

  /// Reset to default settings (all tiers enabled)
  Future<void> resetToDefaults() async {
    await updateSettings(const TierSettings());
  }

  /// Get list of enabled tiers for backend API
  Future<List<String>> getEnabledTiers() async {
    final settings = await future;
    return settings.enabledTiers;
  }
}
