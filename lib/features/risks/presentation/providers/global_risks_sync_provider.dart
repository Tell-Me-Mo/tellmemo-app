import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/presentation/providers/risks_tasks_provider.dart';
import 'aggregated_risks_provider.dart';
import 'enhanced_risks_provider.dart';

class GlobalRisksSyncNotifier extends StateNotifier<int> {
  final Ref _ref;

  GlobalRisksSyncNotifier(this._ref) : super(0);

  void invalidateAllRiskProviders() {
    try {
      // Invalidate aggregated risks providers
      _ref.invalidate(aggregatedRisksProvider);
      _ref.invalidate(riskStatisticsProvider);
      _ref.invalidate(filteredRisksBySeverityProvider);
      _ref.invalidate(filteredRisksByStatusProvider);

      // Invalidate enhanced risks providers if they exist
      _ref.invalidate(enhancedRiskStatisticsProvider);
      _ref.invalidate(riskTrendsProvider);

      // Increment counter to notify listeners
      state = state + 1;
    } catch (e) {
      // Silently handle invalidation errors to prevent crashes
    }
  }
}

final globalRisksSyncProvider = StateNotifierProvider<GlobalRisksSyncNotifier, int>((ref) {
  return GlobalRisksSyncNotifier(ref);
});

// Helper function to trigger global risk sync
void triggerGlobalRisksSync(Ref ref) {
  ref.read(globalRisksSyncProvider.notifier).invalidateAllRiskProviders();
}