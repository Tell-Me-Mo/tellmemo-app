import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/activity.dart';
import '../providers/activity_provider.dart';
import 'activity_timeline.dart';

class ActivityFeedCard extends ConsumerStatefulWidget {
  final String projectId;

  const ActivityFeedCard({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<ActivityFeedCard> createState() => _ActivityFeedCardState();
}

class _ActivityFeedCardState extends ConsumerState<ActivityFeedCard> {
  @override
  void initState() {
    super.initState();
    // Load activities for this project when the widget is initialized
    Future.microtask(() {
      ref.read(activityProvider.notifier).loadActivities(widget.projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final activities = ref.watch(filteredActivitiesProvider);
    final recentActivities = activities.take(5).toList();

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    _showActivityMenu(context);
                  },
                ),
              ],
            ),
          ),
          if (recentActivities.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 32,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No recent activity',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentActivities.map((activity) => _buildActivityItem(context, activity)),
          if (activities.length > 5)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    _showFullActivityDialog(context, widget.projectId);
                  },
                  child: Text('View all ${activities.length} activities'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, Activity activity) {
    final color = _getActivityColor(context, activity.type);
    
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: color.withOpacity(0.2),
        child: Text(
          activity.icon,
          style: const TextStyle(fontSize: 18),
        ),
      ),
      title: Text(
        activity.title,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: Text(
        activity.description,
        style: Theme.of(context).textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        activity.formattedTime,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      dense: true,
    );
  }

  Color _getActivityColor(BuildContext context, ActivityType type) {
    switch (type) {
      case ActivityType.projectCreated:
        return Colors.orange;
      case ActivityType.projectUpdated:
        return Theme.of(context).colorScheme.primary;
      case ActivityType.projectDeleted:
        return Theme.of(context).colorScheme.error;
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

  void _showActivityMenu(BuildContext context) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 100,
        100,
        0,
        0,
      ),
      items: [
        const PopupMenuItem(
          value: 'refresh',
          child: Row(
            children: [
              Icon(Icons.refresh, size: 20),
              SizedBox(width: 8),
              Text('Refresh'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'filter',
          child: Row(
            children: [
              Icon(Icons.filter_list, size: 20),
              SizedBox(width: 8),
              Text('Filter'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.download, size: 20),
              SizedBox(width: 8),
              Text('Export'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'refresh') {
        // Trigger refresh
      } else if (value == 'filter') {
        _showFilterDialog(context);
      } else if (value == 'export') {
        // Handle export
      }
    });
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Activities'),
        content: const Text('Filter options coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFullActivityDialog(BuildContext context, String projectId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 600,
          height: 500,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Activities',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ActivityTimeline(
                  projectId: projectId,
                  compact: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}