import 'package:shared_preferences/shared_preferences.dart';
import '../../presentation/providers/lessons_learned_filter_provider.dart';
import '../../presentation/widgets/lesson_group_dialog.dart';
import '../../../projects/domain/entities/lesson_learned.dart';

class LessonsPreferencesService {
  static const String _keyPrefix = 'lessons_prefs_';

  // Keys for different preferences
  static const String _keySelectedCategories = '${_keyPrefix}selected_categories';
  static const String _keySelectedTypes = '${_keyPrefix}selected_types';
  static const String _keySelectedImpacts = '${_keyPrefix}selected_impacts';
  static const String _keySelectedProjects = '${_keyPrefix}selected_projects';
  static const String _keyShowOnlyAiGenerated = '${_keyPrefix}show_ai_generated';
  static const String _keySortBy = '${_keyPrefix}sort_by';
  static const String _keyCompactView = '${_keyPrefix}compact_view';
  static const String _keyGroupingMode = '${_keyPrefix}grouping_mode';

  final SharedPreferences _prefs;

  LessonsPreferencesService(this._prefs);

  // Factory constructor to create instance
  static Future<LessonsPreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LessonsPreferencesService(prefs);
  }

  // Save filter preferences
  Future<void> saveFilterPreferences(LessonsLearnedFilter filter) async {
    // Save categories
    await _prefs.setStringList(
      _keySelectedCategories,
      filter.selectedCategories.map((c) => c.name).toList(),
    );

    // Save types
    await _prefs.setStringList(
      _keySelectedTypes,
      filter.selectedTypes.map((t) => t.name).toList(),
    );

    // Save impacts
    await _prefs.setStringList(
      _keySelectedImpacts,
      filter.selectedImpacts.map((i) => i.name).toList(),
    );

    // Save project IDs
    await _prefs.setStringList(
      _keySelectedProjects,
      filter.selectedProjectIds.toList(),
    );

    // Save AI filter
    await _prefs.setBool(_keyShowOnlyAiGenerated, filter.showOnlyAiGenerated);

    // Save sort option
    await _prefs.setString(_keySortBy, filter.sortBy.name);
  }

  // Load filter preferences
  LessonsLearnedFilter loadFilterPreferences() {
    // Load categories
    final categoryStrings = _prefs.getStringList(_keySelectedCategories) ?? [];
    final categories = categoryStrings
        .map((s) => LessonCategory.values.firstWhereOrNull((e) => e.name == s))
        .whereType<LessonCategory>()
        .toSet();

    // Load types
    final typeStrings = _prefs.getStringList(_keySelectedTypes) ?? [];
    final types = typeStrings
        .map((s) => LessonType.values.firstWhereOrNull((e) => e.name == s))
        .whereType<LessonType>()
        .toSet();

    // Load impacts
    final impactStrings = _prefs.getStringList(_keySelectedImpacts) ?? [];
    final impacts = impactStrings
        .map((s) => LessonImpact.values.firstWhereOrNull((e) => e.name == s))
        .whereType<LessonImpact>()
        .toSet();

    // Load project IDs
    final projectIds = _prefs.getStringList(_keySelectedProjects)?.toSet() ?? {};

    // Load AI filter
    final showOnlyAiGenerated = _prefs.getBool(_keyShowOnlyAiGenerated) ?? false;

    // Load sort option
    final sortByStr = _prefs.getString(_keySortBy);
    final sortBy = sortByStr != null
        ? LessonsSortOption.values.firstWhereOrNull((e) => e.name == sortByStr) ??
          LessonsSortOption.dateDescending
        : LessonsSortOption.dateDescending;

    return LessonsLearnedFilter(
      selectedCategories: categories,
      selectedTypes: types,
      selectedImpacts: impacts,
      selectedProjectIds: projectIds,
      showOnlyAiGenerated: showOnlyAiGenerated,
      sortBy: sortBy,
    );
  }

  // Save compact view preference
  Future<void> saveCompactView(bool isCompact) async {
    await _prefs.setBool(_keyCompactView, isCompact);
  }

  // Load compact view preference
  bool loadCompactView() {
    return _prefs.getBool(_keyCompactView) ?? true;
  }

  // Save grouping mode preference
  Future<void> saveGroupingMode(LessonGroupingMode groupingMode) async {
    await _prefs.setString(_keyGroupingMode, groupingMode.name);
  }

  // Load grouping mode preference
  LessonGroupingMode loadGroupingMode() {
    final groupingStr = _prefs.getString(_keyGroupingMode);
    return groupingStr != null
        ? LessonGroupingMode.values.firstWhereOrNull((e) => e.name == groupingStr) ??
          LessonGroupingMode.none
        : LessonGroupingMode.none;
  }

  // Clear all lessons preferences (useful for sign out)
  Future<void> clearAllPreferences() async {
    final keys = _prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}

// Extension to help with null-safe enum lookup
extension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (_) {
      return null;
    }
  }
}