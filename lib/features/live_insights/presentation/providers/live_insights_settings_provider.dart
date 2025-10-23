import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/live_insights_settings.dart';
import '../../domain/models/proactive_assistance_model.dart';
import '../../domain/services/live_insights_settings_service.dart';

/// Shared preferences provider for live insights
final liveInsightsSharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Live insights settings service provider
final liveInsightsSettingsServiceProvider = Provider<AsyncValue<LiveInsightsSettingsService>>((ref) {
  final prefsAsync = ref.watch(liveInsightsSharedPreferencesProvider);
  return prefsAsync.when(
    data: (prefs) => AsyncValue.data(LiveInsightsSettingsService(prefs)),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Alternative provider using factory constructor
final liveInsightsSettingsServiceFactoryProvider = FutureProvider<LiveInsightsSettingsService>((ref) async {
  return await LiveInsightsSettingsService.create();
});

/// Current live insights settings state notifier
class LiveInsightsSettingsNotifier extends StateNotifier<LiveInsightsSettings> {
  final LiveInsightsSettingsService _service;

  LiveInsightsSettingsNotifier(this._service) : super(const LiveInsightsSettings()) {
    _loadSettings();
  }

  /// Load settings from persistence
  Future<void> _loadSettings() async {
    state = _service.loadSettings();
  }

  /// Update settings
  Future<void> updateSettings(LiveInsightsSettings newSettings) async {
    await _service.saveSettings(newSettings);
    state = newSettings;
  }

  /// Toggle quiet mode
  Future<void> toggleQuietMode() async {
    final newSettings = state.copyWith(quietMode: !state.quietMode);
    await updateSettings(newSettings);
  }

  /// Toggle show collapsed items
  Future<void> toggleShowCollapsedItems() async {
    final newSettings = state.copyWith(showCollapsedItems: !state.showCollapsedItems);
    await updateSettings(newSettings);
  }

  /// Toggle feedback collection
  Future<void> toggleEnableFeedback() async {
    final newSettings = state.copyWith(enableFeedback: !state.enableFeedback);
    await updateSettings(newSettings);
  }

  /// Toggle auto-expand high confidence
  Future<void> toggleAutoExpandHighConfidence() async {
    final newSettings = state.copyWith(
      autoExpandHighConfidence: !state.autoExpandHighConfidence,
    );
    await updateSettings(newSettings);
  }

  /// Toggle a specific phase on/off
  Future<void> togglePhase(ProactiveAssistanceType phase) async {
    final newEnabledPhases = Set<ProactiveAssistanceType>.from(state.enabledPhases);

    if (newEnabledPhases.contains(phase)) {
      newEnabledPhases.remove(phase);
    } else {
      newEnabledPhases.add(phase);
    }

    final newSettings = state.copyWith(enabledPhases: newEnabledPhases);
    await updateSettings(newSettings);
  }

  /// Enable all phases
  Future<void> enableAllPhases() async {
    final newSettings = state.copyWith(enabledPhases: LiveInsightsSettings.allPhases);
    await updateSettings(newSettings);
  }

  /// Disable all phases
  Future<void> disableAllPhases() async {
    final newSettings = state.copyWith(enabledPhases: <ProactiveAssistanceType>{});
    await updateSettings(newSettings);
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    await _service.resetToDefaults();
    state = const LiveInsightsSettings();
  }
}

/// Live insights settings state provider
final liveInsightsSettingsProvider = StateNotifierProvider<LiveInsightsSettingsNotifier, LiveInsightsSettings>((ref) {
  final serviceAsync = ref.watch(liveInsightsSettingsServiceProvider);

  return serviceAsync.maybeWhen(
    data: (service) => LiveInsightsSettingsNotifier(service),
    orElse: () => LiveInsightsSettingsNotifier(
      LiveInsightsSettingsService(
        // Fallback - use empty stub (will be replaced when service loads)
        ref.watch(liveInsightsSharedPreferencesProvider).maybeWhen(
          data: (prefs) => prefs,
          orElse: () => throw StateError('SharedPreferences not yet loaded'),
        ),
      ),
    ),
  );
});
