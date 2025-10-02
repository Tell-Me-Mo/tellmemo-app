import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/services/task_preferences_service.dart';

// Shared preferences provider
final tasksSharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// Tasks preferences service provider
final tasksPreferencesServiceProvider = Provider<AsyncValue<TaskPreferencesService>>((ref) {
  final prefsAsync = ref.watch(tasksSharedPreferencesProvider);
  return prefsAsync.when(
    data: (prefs) => AsyncValue.data(TaskPreferencesService(prefs)),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Alternative provider using factory constructor (for compatibility)
final taskPreferencesServiceProvider = FutureProvider<TaskPreferencesService>((ref) async {
  return await TaskPreferencesService.create();
});

