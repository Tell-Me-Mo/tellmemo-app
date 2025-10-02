import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/domain/entities/lesson_learned.dart';
import '../widgets/lesson_group_dialog.dart';
import 'lessons_preferences_provider.dart';

class LessonsLearnedFilter {
  final String searchQuery;
  final Set<LessonCategory> selectedCategories;
  final Set<LessonType> selectedTypes;
  final Set<LessonImpact> selectedImpacts;
  final Set<String> selectedProjectIds;
  final bool showOnlyAiGenerated;
  final LessonsSortOption sortBy;

  LessonsLearnedFilter({
    this.searchQuery = '',
    this.selectedCategories = const {},
    this.selectedTypes = const {},
    this.selectedImpacts = const {},
    this.selectedProjectIds = const {},
    this.showOnlyAiGenerated = false,
    this.sortBy = LessonsSortOption.dateDescending,
  });

  LessonsLearnedFilter copyWith({
    String? searchQuery,
    Set<LessonCategory>? selectedCategories,
    Set<LessonType>? selectedTypes,
    Set<LessonImpact>? selectedImpacts,
    Set<String>? selectedProjectIds,
    bool? showOnlyAiGenerated,
    LessonsSortOption? sortBy,
  }) {
    return LessonsLearnedFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      selectedImpacts: selectedImpacts ?? this.selectedImpacts,
      selectedProjectIds: selectedProjectIds ?? this.selectedProjectIds,
      showOnlyAiGenerated: showOnlyAiGenerated ?? this.showOnlyAiGenerated,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasActiveFilters =>
    searchQuery.isNotEmpty ||
    selectedCategories.isNotEmpty ||
    selectedTypes.isNotEmpty ||
    selectedImpacts.isNotEmpty ||
    selectedProjectIds.isNotEmpty ||
    showOnlyAiGenerated;

  int get activeFilterCount {
    int count = 0;
    if (searchQuery.isNotEmpty) count++;
    if (selectedCategories.isNotEmpty) count++;
    if (selectedTypes.isNotEmpty) count++;
    if (selectedImpacts.isNotEmpty) count++;
    if (selectedProjectIds.isNotEmpty) count++;
    if (showOnlyAiGenerated) count++;
    return count;
  }
}

enum LessonsSortOption {
  dateDescending('Most Recent'),
  dateAscending('Oldest First'),
  impactHighToLow('Impact (High to Low)'),
  impactLowToHigh('Impact (Low to High)'),
  titleAZ('Title (A-Z)'),
  titleZA('Title (Z-A)');

  final String label;
  const LessonsSortOption(this.label);
}

// State notifier for managing the filter state
class LessonsLearnedFilterNotifier extends StateNotifier<LessonsLearnedFilter> {
  final Ref _ref;
  bool _isInitialized = false;

  LessonsLearnedFilterNotifier(this._ref) : super(LessonsLearnedFilter()) {
    // Load preferences once they're available
    _initializeFromPreferences();

    // Auto-save preferences when state changes
    addListener((state) async {
      if (!_isInitialized) return; // Don't save until we've loaded
      final prefsAsync = _ref.read(lessonsPreferencesServiceProvider);
      if (prefsAsync.hasValue) {
        await prefsAsync.value!.saveFilterPreferences(state);
      }
    });
  }

  Future<void> _initializeFromPreferences() async {
    try {
      final prefsAsync = await _ref.read(lessonsPreferencesServiceProvider.future);
      final loadedFilter = prefsAsync.loadFilterPreferences();
      state = loadedFilter;
      _isInitialized = true;
    } catch (e) {
      _isInitialized = true; // Still mark as initialized to allow saving
    }
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleCategory(LessonCategory category) {
    final newCategories = Set<LessonCategory>.from(state.selectedCategories);
    if (newCategories.contains(category)) {
      newCategories.remove(category);
    } else {
      newCategories.add(category);
    }
    state = state.copyWith(selectedCategories: newCategories);
  }

  void toggleType(LessonType type) {
    final newTypes = Set<LessonType>.from(state.selectedTypes);
    if (newTypes.contains(type)) {
      newTypes.remove(type);
    } else {
      newTypes.add(type);
    }
    state = state.copyWith(selectedTypes: newTypes);
  }

  void toggleImpact(LessonImpact impact) {
    final newImpacts = Set<LessonImpact>.from(state.selectedImpacts);
    if (newImpacts.contains(impact)) {
      newImpacts.remove(impact);
    } else {
      newImpacts.add(impact);
    }
    state = state.copyWith(selectedImpacts: newImpacts);
  }

  void toggleProject(String projectId) {
    final newProjects = Set<String>.from(state.selectedProjectIds);
    if (newProjects.contains(projectId)) {
      newProjects.remove(projectId);
    } else {
      newProjects.add(projectId);
    }
    state = state.copyWith(selectedProjectIds: newProjects);
  }

  void toggleAiGenerated() {
    state = state.copyWith(showOnlyAiGenerated: !state.showOnlyAiGenerated);
  }

  void setSortOption(LessonsSortOption option) {
    state = state.copyWith(sortBy: option);
  }

  void clearAllFilters() {
    // Keep the sort option when clearing filters
    state = LessonsLearnedFilter(sortBy: state.sortBy);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }

  void clearCategories() {
    state = state.copyWith(selectedCategories: {});
  }

  void clearTypes() {
    state = state.copyWith(selectedTypes: {});
  }

  void clearImpacts() {
    state = state.copyWith(selectedImpacts: {});
  }

  void clearProjects() {
    state = state.copyWith(selectedProjectIds: {});
  }
}

// Provider for the filter state
final lessonsLearnedFilterProvider =
  StateNotifierProvider<LessonsLearnedFilterNotifier, LessonsLearnedFilter>((ref) {
    return LessonsLearnedFilterNotifier(ref);
  });

// Provider for compact view with persistence
final lessonCompactViewProvider = StateNotifierProvider<CompactViewNotifier, bool>((ref) {
  return CompactViewNotifier(ref);
});

class CompactViewNotifier extends StateNotifier<bool> {
  final Ref _ref;
  bool _isInitialized = false;

  CompactViewNotifier(this._ref) : super(true) {
    // Load preference once they're available
    _initializeFromPreferences();

    // Auto-save preferences when state changes
    addListener((state) async {
      if (!_isInitialized) return; // Don't save until we've loaded
      final prefsAsync = _ref.read(lessonsPreferencesServiceProvider);
      if (prefsAsync.hasValue) {
        await prefsAsync.value!.saveCompactView(state);
      }
    });
  }

  Future<void> _initializeFromPreferences() async {
    try {
      final prefsAsync = await _ref.read(lessonsPreferencesServiceProvider.future);
      final isCompact = prefsAsync.loadCompactView();
      state = isCompact;
      _isInitialized = true;
    } catch (e) {
      _isInitialized = true; // Still mark as initialized to allow saving
    }
  }

  void toggle() {
    state = !state;
  }
}

// Provider for grouping mode with persistence
final lessonGroupingModeProvider = StateNotifierProvider<GroupingModeNotifier, LessonGroupingMode>((ref) {
  return GroupingModeNotifier(ref);
});

class GroupingModeNotifier extends StateNotifier<LessonGroupingMode> {
  final Ref _ref;
  bool _isInitialized = false;

  GroupingModeNotifier(this._ref) : super(LessonGroupingMode.none) {
    // Load preference once they're available
    _initializeFromPreferences();

    // Auto-save preferences when state changes
    addListener((state) async {
      if (!_isInitialized) return; // Don't save until we've loaded
      final prefsAsync = _ref.read(lessonsPreferencesServiceProvider);
      if (prefsAsync.hasValue) {
        await prefsAsync.value!.saveGroupingMode(state);
      }
    });
  }

  Future<void> _initializeFromPreferences() async {
    try {
      final prefsAsync = await _ref.read(lessonsPreferencesServiceProvider.future);
      final groupingMode = prefsAsync.loadGroupingMode();
      state = groupingMode;
      _isInitialized = true;
    } catch (e) {
      _isInitialized = true; // Still mark as initialized to allow saving
    }
  }

  void setGroupingMode(LessonGroupingMode mode) {
    state = mode;
  }
}