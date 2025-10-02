import 'package:shared_preferences/shared_preferences.dart';
import '../../../projects/domain/entities/risk.dart';
import '../../presentation/screens/risks_aggregation_screen_v2.dart';
import '../../presentation/providers/risks_filter_provider.dart';

class RiskPreferencesService {
  final SharedPreferences _prefs;

  RiskPreferencesService(this._prefs);

  static const String _keyPrefix = 'risk_prefs_';

  // Filter keys
  static const String _keySeverity = '${_keyPrefix}severity';
  static const String _keyStatus = '${_keyPrefix}status';
  static const String _keyAssignee = '${_keyPrefix}assignee';
  static const String _keyShowAIGeneratedOnly = '${_keyPrefix}show_ai_generated_only';
  static const String _keyProjectId = '${_keyPrefix}project_id';

  // Sort keys
  static const String _keySortBy = '${_keyPrefix}sort_by';
  static const String _keySortOrder = '${_keyPrefix}sort_order';

  // View keys
  static const String _keyViewMode = '${_keyPrefix}view_mode';
  static const String _keyGroupingMode = '${_keyPrefix}grouping_mode';

  // Date range keys
  static const String _keyStartDate = '${_keyPrefix}start_date';
  static const String _keyEndDate = '${_keyPrefix}end_date';

  // Save filter preferences
  Future<void> saveFilterPreferences(RisksFilter filter) async {
    print('🔵 [RiskPrefs] Saving filter preferences...');
    // Save severity
    if (filter.severity != null) {
      await _prefs.setString(_keySeverity, filter.severity!.name);
      print('  ✅ Saved severity: ${filter.severity!.name}');
    } else {
      await _prefs.remove(_keySeverity);
      print('  ✅ Cleared severity');
    }

    // Save status
    if (filter.status != null) {
      await _prefs.setString(_keyStatus, filter.status!.name);
      print('  ✅ Saved status: ${filter.status!.name}');
    } else {
      await _prefs.remove(_keyStatus);
      print('  ✅ Cleared status');
    }

    // Save assignee
    if (filter.assignee != null && filter.assignee!.isNotEmpty) {
      await _prefs.setString(_keyAssignee, filter.assignee!);
    } else {
      await _prefs.remove(_keyAssignee);
    }

    // Save AI generated only flag
    await _prefs.setBool(_keyShowAIGeneratedOnly, filter.showAIGeneratedOnly);
    print('  ✅ Saved AI generated only: ${filter.showAIGeneratedOnly}');

    // Save sort preferences
    await _prefs.setString(_keySortBy, filter.sortBy.name);
    await _prefs.setBool(_keySortOrder, filter.sortAscending);
    print('  ✅ Saved sort: ${filter.sortBy.name}, ascending: ${filter.sortAscending}');

    // Save date range
    if (filter.startDate != null) {
      await _prefs.setString(_keyStartDate, filter.startDate!.toIso8601String());
    } else {
      await _prefs.remove(_keyStartDate);
    }

    if (filter.endDate != null) {
      await _prefs.setString(_keyEndDate, filter.endDate!.toIso8601String());
    } else {
      await _prefs.remove(_keyEndDate);
    }
  }

  // Load filter preferences
  RisksFilter loadFilterPreferences() {
    print('🔵 [RiskPrefs] Loading filter preferences...');
    // Load severity
    final severityStr = _prefs.getString(_keySeverity);
    print('  📖 Loaded severity string: $severityStr');
    final severity = severityStr != null
        ? RiskSeverity.values.firstWhere(
            (e) => e.name == severityStr,
            orElse: () => RiskSeverity.medium,
          )
        : null;

    // Load status
    final statusStr = _prefs.getString(_keyStatus);
    print('  📖 Loaded status string: $statusStr');
    final status = statusStr != null
        ? RiskStatus.values.firstWhere(
            (e) => e.name == statusStr,
            orElse: () => RiskStatus.identified,
          )
        : null;

    // Load assignee
    final assignee = _prefs.getString(_keyAssignee);

    // Load AI generated only flag
    final showAIGeneratedOnly = _prefs.getBool(_keyShowAIGeneratedOnly) ?? false;
    print('  📖 Loaded AI generated only: $showAIGeneratedOnly');

    // Load sort preferences
    final sortByStr = _prefs.getString(_keySortBy);
    print('  📖 Loaded sort by string: $sortByStr');
    final sortBy = sortByStr != null
        ? RiskSortBy.values.firstWhere(
            (e) => e.name == sortByStr,
            orElse: () => RiskSortBy.severity,
          )
        : RiskSortBy.severity;

    final sortAscending = _prefs.getBool(_keySortOrder) ?? false;
    print('  📖 Loaded sort ascending: $sortAscending');

    // Load date range
    final startDateStr = _prefs.getString(_keyStartDate);
    final startDate = startDateStr != null ? DateTime.tryParse(startDateStr) : null;

    final endDateStr = _prefs.getString(_keyEndDate);
    final endDate = endDateStr != null ? DateTime.tryParse(endDateStr) : null;

    return RisksFilter(
      severity: severity,
      status: status,
      assignee: assignee,
      showAIGeneratedOnly: showAIGeneratedOnly,
      sortBy: sortBy,
      sortAscending: sortAscending,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Save view mode
  Future<void> saveViewMode(RiskViewMode viewMode) async {
    print('🔵 [RiskPrefs] Saving view mode: ${viewMode.name}');
    await _prefs.setString(_keyViewMode, viewMode.name);
    print('  ✅ View mode saved');
  }

  // Load view mode
  RiskViewMode loadViewMode() {
    print('🔵 [RiskPrefs] Loading view mode...');
    final viewModeStr = _prefs.getString(_keyViewMode);
    print('  📖 Loaded view mode string: $viewModeStr');
    if (viewModeStr != null) {
      return RiskViewMode.values.firstWhere(
        (e) => e.name == viewModeStr,
        orElse: () => RiskViewMode.compact,
      );
    }
    return RiskViewMode.compact;
  }

  // Save grouping mode
  Future<void> saveGroupingMode(GroupingMode groupingMode) async {
    print('🔵 [RiskPrefs] Saving grouping mode: ${groupingMode.name}');
    await _prefs.setString(_keyGroupingMode, groupingMode.name);
    print('  ✅ Grouping mode saved');
  }

  // Load grouping mode
  GroupingMode loadGroupingMode() {
    print('🔵 [RiskPrefs] Loading grouping mode...');
    final groupingModeStr = _prefs.getString(_keyGroupingMode);
    print('  📖 Loaded grouping mode string: $groupingModeStr');
    if (groupingModeStr != null) {
      return GroupingMode.values.firstWhere(
        (e) => e.name == groupingModeStr,
        orElse: () => GroupingMode.none,
      );
    }
    return GroupingMode.none;
  }

  // Save selected project
  Future<void> saveSelectedProject(String? projectId) async {
    if (projectId != null && projectId.isNotEmpty) {
      await _prefs.setString(_keyProjectId, projectId);
    } else {
      await _prefs.remove(_keyProjectId);
    }
  }

  // Load selected project
  String? loadSelectedProject() {
    return _prefs.getString(_keyProjectId);
  }

  // Clear all preferences
  Future<void> clearAllPreferences() async {
    final keys = _prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}