import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/domain/entities/risk.dart';
import 'aggregated_risks_provider.dart';
import 'risk_preferences_provider.dart';

class RisksFilter {
  final String searchQuery;
  final RiskSeverity? severity;
  final RiskStatus? status;
  final String? assignee;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool showAIGeneratedOnly;
  final RiskSortBy sortBy;
  final bool sortAscending;

  const RisksFilter({
    this.searchQuery = '',
    this.severity,
    this.status,
    this.assignee,
    this.startDate,
    this.endDate,
    this.showAIGeneratedOnly = false,
    this.sortBy = RiskSortBy.severity,
    this.sortAscending = false,
  });

  RisksFilter copyWith({
    String? searchQuery,
    RiskSeverity? Function()? severity,
    RiskStatus? Function()? status,
    String? Function()? assignee,
    DateTime? Function()? startDate,
    DateTime? Function()? endDate,
    bool? showAIGeneratedOnly,
    RiskSortBy? sortBy,
    bool? sortAscending,
  }) {
    return RisksFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      severity: severity != null ? severity() : this.severity,
      status: status != null ? status() : this.status,
      assignee: assignee != null ? assignee() : this.assignee,
      startDate: startDate != null ? startDate() : this.startDate,
      endDate: endDate != null ? endDate() : this.endDate,
      showAIGeneratedOnly: showAIGeneratedOnly ?? this.showAIGeneratedOnly,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  bool get hasActiveFilters {
    return searchQuery.isNotEmpty ||
        severity != null ||
        status != null ||
        assignee != null ||
        startDate != null ||
        endDate != null ||
        showAIGeneratedOnly;
  }

  int get activeFilterCount {
    int count = 0;
    if (searchQuery.isNotEmpty) count++;
    if (severity != null) count++;
    if (status != null) count++;
    if (assignee != null) count++;
    if (startDate != null || endDate != null) count++;
    if (showAIGeneratedOnly) count++;
    return count;
  }
}

enum RiskSortBy {
  severity,
  date,
  project,
  assignee,
  status,
}

class RisksFilterNotifier extends StateNotifier<RisksFilter> {
  final Ref _ref;
  bool _isInitialized = false;
  bool _isLoadingFromPrefs = false;

  RisksFilterNotifier(this._ref, RisksFilter initialFilter) : super(initialFilter) {
    print('🟣 [RisksFilterNotifier] Initializing with filter:');
    print('  Severity: ${initialFilter.severity?.name}');
    print('  Status: ${initialFilter.status?.name}');
    print('  SortBy: ${initialFilter.sortBy.name}');
    print('  SortAscending: ${initialFilter.sortAscending}');

    // Check if we're being initialized with loaded preferences
    _isLoadingFromPrefs = initialFilter.severity != null ||
                          initialFilter.status != null ||
                          initialFilter.assignee != null ||
                          initialFilter.showAIGeneratedOnly ||
                          initialFilter.sortBy != RiskSortBy.severity ||
                          !initialFilter.sortAscending;

    // Mark as initialized after construction
    Future.microtask(() {
      _isInitialized = true;
      _isLoadingFromPrefs = false;
    });
  }

  Future<void> _savePreferences() async {
    // Only save if we're initialized and not loading from preferences
    if (!_isInitialized || _isLoadingFromPrefs) return;

    print('🟣 [RisksFilterNotifier] State changed, saving...');
    final prefsAsync = _ref.read(riskPreferencesServiceProvider);
    if (prefsAsync.hasValue) {
      await prefsAsync.value!.saveFilterPreferences(state);
    } else {
      print('  ⚠️ Preferences service not available, cannot save');
    }
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _savePreferences();
  }

  void setSeverity(RiskSeverity? severity) {
    print('🟣 [RisksFilterNotifier] setSeverity called: ${severity?.name}');
    state = state.copyWith(severity: () => severity);
    _savePreferences();
  }

  void setStatus(RiskStatus? status) {
    print('🟣 [RisksFilterNotifier] setStatus called: ${status?.name}');
    state = state.copyWith(status: () => status);
    _savePreferences();
  }

  void setAssignee(String? assignee) {
    state = state.copyWith(assignee: () => assignee);
    _savePreferences();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: () => start, endDate: () => end);
    _savePreferences();
  }

  void toggleAIGeneratedOnly() {
    state = state.copyWith(showAIGeneratedOnly: !state.showAIGeneratedOnly);
    _savePreferences();
  }

  void setSortBy(RiskSortBy sortBy) {
    state = state.copyWith(sortBy: sortBy);
    _savePreferences();
  }

  void toggleSortDirection() {
    state = state.copyWith(sortAscending: !state.sortAscending);
    _savePreferences();
  }

  void clearAllFilters() {
    state = const RisksFilter();
    _savePreferences();
  }
}

// Provider that loads filter from preferences or returns default
final _initialRisksFilterProvider = Provider<RisksFilter>((ref) {
  final prefsAsync = ref.watch(riskPreferencesServiceProvider);

  return prefsAsync.maybeWhen(
    data: (service) => service.loadFilterPreferences(),
    orElse: () => const RisksFilter(),
  );
});

final risksFilterProvider = StateNotifierProvider<RisksFilterNotifier, RisksFilter>((ref) {
  // Get initial filter from preferences provider
  final initialFilter = ref.watch(_initialRisksFilterProvider);

  return RisksFilterNotifier(ref, initialFilter);
});

final uniqueAssigneesProvider = Provider<List<String>>((ref) {
  final risks = ref.watch(aggregatedRisksProvider).value ?? [];
  final assignees = <String>{};

  for (final risk in risks) {
    if (risk.risk.assignedTo != null) {
      assignees.add(risk.risk.assignedTo!);
    }
  }

  return assignees.toList()..sort();
});

final riskWebSocketProvider = StateNotifierProvider<RiskWebSocketNotifier, void>((ref) {
  return RiskWebSocketNotifier();
});

class RiskWebSocketNotifier extends StateNotifier<void> {
  RiskWebSocketNotifier() : super(null);

  void connect() {
    // WebSocket connection logic
  }

  void disconnect() {
    // WebSocket disconnection logic
  }
}