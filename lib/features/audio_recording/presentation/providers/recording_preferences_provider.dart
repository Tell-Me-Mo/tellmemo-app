import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/services/recording_preferences_service.dart';

/// Provider for SharedPreferences instance
final recordingSharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Provider for RecordingPreferencesService
final recordingPreferencesServiceProvider = Provider<AsyncValue<RecordingPreferencesService>>((ref) {
  final prefsAsync = ref.watch(recordingSharedPreferencesProvider);
  return prefsAsync.when(
    data: (prefs) => AsyncValue.data(RecordingPreferencesService(prefs)),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});
