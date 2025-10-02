import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/network/api_service.dart';
import '../../domain/entities/activity.dart';
import '../../data/models/activity_model.dart';

part 'activity_provider.freezed.dart';

@freezed
class ActivityState with _$ActivityState {
  const factory ActivityState({
    @Default([]) List<Activity> activities,
    @Default(false) bool isLoading,
    @Default(false) bool isPolling,
    String? error,
    ActivityType? filterType,
    @Default(30) int pollingInterval,
  }) = _ActivityState;
}

class ActivityNotifier extends StateNotifier<ActivityState> {
  final ApiService _apiService;
  Timer? _pollingTimer;
  String? _currentProjectId;

  ActivityNotifier(this._apiService) : super(const ActivityState());

  Future<void> loadActivities(String projectId) async {
    _currentProjectId = projectId;
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.getProjectActivities(projectId);
      if (!mounted) return;
      
      final activities = response
          .map((json) => ActivityModel.fromJson(json).toEntity())
          .toList();
      
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      if (!mounted) return;
      state = state.copyWith(
        activities: activities,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load activities: ${e.toString()}',
      );
    }
  }

  void startPolling(String projectId) {
    if (_pollingTimer != null || !mounted) return;
    
    state = state.copyWith(isPolling: true);
    _currentProjectId = projectId;
    
    _pollingTimer = Timer.periodic(
      Duration(seconds: state.pollingInterval),
      (_) => _pollActivities(),
    );
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    if (mounted) {
      state = state.copyWith(isPolling: false);
    }
  }

  Future<void> _pollActivities() async {
    if (_currentProjectId == null || !mounted) return;
    
    try {
      final response = await _apiService.getProjectActivities(_currentProjectId!);
      if (!mounted) return;
      
      final activities = response
          .map((json) => ActivityModel.fromJson(json).toEntity())
          .toList();
      
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      if (!mounted) return;
      if (!_areActivitiesEqual(activities, state.activities)) {
        state = state.copyWith(activities: activities);
      }
    } catch (e) {
      // Silent fail for polling
    }
  }

  bool _areActivitiesEqual(List<Activity> a, List<Activity> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  void setFilter(ActivityType? type) {
    if (!mounted) return;
    state = state.copyWith(filterType: type);
  }

  List<Activity> get filteredActivities {
    if (state.filterType == null) {
      return state.activities;
    }
    return state.activities
        .where((activity) => activity.type == state.filterType)
        .toList();
  }

  void addActivity(Activity activity) {
    if (!mounted) return;
    final updatedActivities = [activity, ...state.activities];
    updatedActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = state.copyWith(activities: updatedActivities);
  }

  void clearActivities() {
    if (!mounted) return;
    state = state.copyWith(activities: []);
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

final activityProvider = StateNotifierProvider.autoDispose<ActivityNotifier, ActivityState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final notifier = ActivityNotifier(apiService);
  
  ref.onDispose(() {
    notifier.stopPolling();
  });
  
  return notifier;
});

final filteredActivitiesProvider = Provider<List<Activity>>((ref) {
  ref.watch(activityProvider);
  final notifier = ref.read(activityProvider.notifier);
  return notifier.filteredActivities;
});