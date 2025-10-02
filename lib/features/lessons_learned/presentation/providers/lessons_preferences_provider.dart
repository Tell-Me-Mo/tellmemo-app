import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/lessons_preferences_service.dart';

// Provider for the preferences service
final lessonsPreferencesServiceProvider = FutureProvider<LessonsPreferencesService>((ref) async {
  return await LessonsPreferencesService.create();
});

// Initialize preferences on app startup
final initializeLessonsPreferencesProvider = Provider<void>((ref) {
  // This provider simply ensures preferences service is loaded
  ref.watch(lessonsPreferencesServiceProvider);
});