import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/services/risk_preferences_service.dart';
import '../screens/risks_aggregation_screen_v2.dart';

// Provider for SharedPreferences instance
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// Provider for RiskPreferencesService
final riskPreferencesServiceProvider = FutureProvider<RiskPreferencesService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return RiskPreferencesService(prefs);
});

// Provider for view mode with persistence
final riskViewModeProvider = StateProvider<RiskViewMode>((ref) {
  print('🟣 [RiskViewModeProvider] Initializing...');

  // Load saved preference on initialization
  final prefsAsync = ref.watch(riskPreferencesServiceProvider);
  final initialMode = prefsAsync.maybeWhen(
    data: (service) {
      final mode = service.loadViewMode();
      print('  ✅ Loaded initial view mode: ${mode.name}');
      return mode;
    },
    orElse: () {
      print('  ⚠️ No saved preferences, using default: compact');
      return RiskViewMode.compact;
    },
  );

  // Auto-save when view mode changes
  ref.listenSelf((previous, next) async {
    print('🟣 [RiskViewModeProvider] View mode changed: ${previous?.name} → ${next.name}');
    if (previous != next && prefsAsync.hasValue) {
      await prefsAsync.value!.saveViewMode(next);
    }
  });

  return initialMode;
});

// Provider for grouping mode with persistence
final riskGroupingModeProvider = StateProvider<GroupingMode>((ref) {
  print('🟣 [RiskGroupingModeProvider] Initializing...');

  // Load saved preference on initialization
  final prefsAsync = ref.watch(riskPreferencesServiceProvider);
  final initialMode = prefsAsync.maybeWhen(
    data: (service) {
      final mode = service.loadGroupingMode();
      print('  ✅ Loaded initial grouping mode: ${mode.name}');
      return mode;
    },
    orElse: () {
      print('  ⚠️ No saved preferences, using default: none');
      return GroupingMode.none;
    },
  );

  // Auto-save when grouping mode changes
  ref.listenSelf((previous, next) async {
    print('🟣 [RiskGroupingModeProvider] Grouping mode changed: ${previous?.name} → ${next.name}');
    if (previous != next && prefsAsync.hasValue) {
      await prefsAsync.value!.saveGroupingMode(next);
    }
  });

  return initialMode;
});

// Provider for selected project with persistence for risks tab
final riskSelectedProjectProvider = StateProvider<String?>((ref) {
  // Load saved preference on initialization
  final prefsAsync = ref.watch(riskPreferencesServiceProvider);
  final initialProject = prefsAsync.maybeWhen(
    data: (service) => service.loadSelectedProject(),
    orElse: () => null,
  );

  // Auto-save when selected project changes
  ref.listenSelf((previous, next) async {
    if (previous != next && prefsAsync.hasValue) {
      await prefsAsync.value!.saveSelectedProject(next);
    }
  });

  return initialProject;
});