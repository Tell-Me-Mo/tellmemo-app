import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/activity.dart';
import '../providers/activity_provider.dart';

class ActivityTimeline extends ConsumerStatefulWidget {
  final String projectId;
  final bool compact;

  const ActivityTimeline({
    super.key,
    required this.projectId,
    this.compact = false,
  });

  @override
  ConsumerState<ActivityTimeline> createState() => _ActivityTimelineState();
}

class _ActivityTimelineState extends ConsumerState<ActivityTimeline> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(activityProvider.notifier).loadActivities(widget.projectId);
      if (!widget.compact) {
        ref.read(activityProvider.notifier).startPolling(widget.projectId);
      }
    });
  }

  @override
  void dispose() {
    if (!widget.compact) {
      ref.read(activityProvider.notifier).stopPolling();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activityProvider);
    final activities = ref.watch(filteredActivitiesProvider);

    if (state.isLoading && activities.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null && activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load activities',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () {
                ref.read(activityProvider.notifier).loadActivities(widget.projectId);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No activities yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Activities will appear here as you work on the project',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final displayActivities = widget.compact 
        ? activities.take(5).toList() 
        : activities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.compact) _buildFilterChips(context, state),
        if (state.isPolling && !widget.compact)
          LinearProgressIndicator(
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            minHeight: 2,
          ),
        Expanded(
          child: ListView.builder(
            itemCount: displayActivities.length,
            itemBuilder: (context, index) {
              final activity = displayActivities[index];
              final isLast = index == displayActivities.length - 1;
              
              return _buildActivityItem(
                context,
                activity,
                isLast,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context, ActivityState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: state.filterType == null,
            onSelected: (_) {
              ref.read(activityProvider.notifier).setFilter(null);
            },
          ),
          const SizedBox(width: 8),
          ...ActivityType.values.map((type) {
            final activity = Activity(
              id: '',
              projectId: '',
              type: type,
              title: '',
              description: '',
              timestamp: DateTime.now(),
            );
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Text(activity.icon, style: const TextStyle(fontSize: 16)),
                label: Text(_getTypeLabel(type)),
                selected: state.filterType == type,
                onSelected: (_) {
                  ref.read(activityProvider.notifier).setFilter(type);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    Activity activity,
    bool isLast,
  ) {
    final color = _getActivityColor(activity.type);
    
    return IntrinsicHeight(
      child: Row(
        children: [
          // Timeline indicator
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          // Activity content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Text(
                      activity.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  title: Text(
                    activity.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    activity.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    activity.formattedTime,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(ActivityType type) {
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (type) {
      case ActivityType.projectCreated:
        return Colors.orange;
      case ActivityType.projectUpdated:
        return colorScheme.primary;
      case ActivityType.projectDeleted:
        return colorScheme.error;
      case ActivityType.contentUploaded:
        return Colors.blue;
      case ActivityType.summaryGenerated:
        return Colors.green;
      case ActivityType.querySubmitted:
        return Colors.purple;
      case ActivityType.reportGenerated:
        return Colors.teal;
      case ActivityType.memberAdded:
        return Colors.indigo;
      case ActivityType.memberRemoved:
        return Colors.grey;
    }
  }

  String _getTypeLabel(ActivityType type) {
    switch (type) {
      case ActivityType.projectCreated:
        return 'Projects';
      case ActivityType.projectUpdated:
        return 'Updates';
      case ActivityType.projectDeleted:
        return 'Deletions';
      case ActivityType.contentUploaded:
        return 'Uploads';
      case ActivityType.summaryGenerated:
        return 'Summaries';
      case ActivityType.querySubmitted:
        return 'Queries';
      case ActivityType.reportGenerated:
        return 'Reports';
      case ActivityType.memberAdded:
        return 'Members';
      case ActivityType.memberRemoved:
        return 'Removals';
    }
  }
}