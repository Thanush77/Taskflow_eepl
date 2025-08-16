import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/comment.dart';
import '../../providers/comment_provider.dart';
import '../../widgets/loading_widget.dart';

class ActivityLogScreen extends ConsumerStatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    
    // Load activity log on init
    Future.microtask(() {
      ref.read(commentProvider.notifier).loadActivityLog();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentState = ref.watch(commentProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.history, color: AppColors.primaryColor, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Activity Log',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        ref.read(commentProvider.notifier).refreshActivityLog();
                      },
                      icon: const Icon(Icons.refresh, color: AppColors.primaryColor),
                      tooltip: 'Refresh',
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleFilterAction(value),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'all',
                          child: Row(
                            children: [
                              Icon(Icons.all_inclusive, size: 16),
                              SizedBox(width: 8),
                              Text('All Activity'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'tasks',
                          child: Row(
                            children: [
                              Icon(Icons.task, size: 16),
                              SizedBox(width: 8),
                              Text('Task Changes'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'comments',
                          child: Row(
                            children: [
                              Icon(Icons.comment, size: 16),
                              SizedBox(width: 8),
                              Text('Comments Only'),
                            ],
                          ),
                        ),
                      ],
                      child: const Icon(
                        Icons.filter_list,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Activity list
          Expanded(
            child: commentState.isLoading && commentState.activityLog.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LoadingWidget(),
                        SizedBox(height: 16),
                        Text('Loading activity...', style: TextStyle(color: AppColors.gray600)),
                      ],
                    ),
                  )
                : _buildActivityList(commentState.activityLog),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(List<ActivityLogEntry> activities) {
    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              'No activity yet',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.gray600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Task changes and updates will appear here',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      );
    }

    // Group activities by date
    final groupedActivities = _groupActivitiesByDate(activities);

    return RefreshIndicator(
      onRefresh: () => ref.read(commentProvider.notifier).refreshActivityLog(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: groupedActivities.length,
        itemBuilder: (context, index) {
          final entry = groupedActivities.entries.elementAt(index);
          return _buildDateGroup(entry.key, entry.value);
        },
      ),
    );
  }

  Widget _buildDateGroup(String date, List<ActivityLogEntry> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            date,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
          ),
        ),
        
        // Activities for this date
        ...activities.map((activity) => _buildActivityItem(activity)),
      ],
    );
  }

  Widget _buildActivityItem(ActivityLogEntry activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getActivityColor(activity.action).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getActivityIcon(activity.action),
              size: 20,
              color: _getActivityColor(activity.action),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Activity details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action description
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.gray700,
                      height: 1.4,
                    ),
                    children: _buildDescriptionSpans(activity),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Timestamp and task info
                Row(
                  children: [
                    Text(
                      _formatTime(activity.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                    if (activity.taskId != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray400,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Task #${activity.taskId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                
                // Additional metadata
                if (activity.metadata != null && activity.metadata!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: activity.metadata!.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${entry.key}: ${entry.value}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<ActivityLogEntry>> _groupActivitiesByDate(List<ActivityLogEntry> activities) {
    final grouped = <String, List<ActivityLogEntry>>{};
    final now = DateTime.now();

    for (final activity in activities) {
      final activityDate = activity.createdAt;
      String dateKey;

      if (_isSameDay(activityDate, now)) {
        dateKey = 'Today';
      } else if (_isSameDay(activityDate, now.subtract(const Duration(days: 1)))) {
        dateKey = 'Yesterday';
      } else if (activityDate.isAfter(now.subtract(const Duration(days: 7)))) {
        dateKey = _getDayName(activityDate.weekday);
      } else {
        dateKey = '${activityDate.day}/${activityDate.month}/${activityDate.year}';
      }

      grouped.putIfAbsent(dateKey, () => []).add(activity);
    }

    return grouped;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  List<TextSpan> _buildDescriptionSpans(ActivityLogEntry activity) {
    final spans = <TextSpan>[];
    
    // User name (bold)
    if (activity.userName != null) {
      spans.add(TextSpan(
        text: activity.userName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ));
      spans.add(const TextSpan(text: ' '));
    }
    
    // Description
    spans.add(TextSpan(text: activity.description));
    
    return spans;
  }

  IconData _getActivityIcon(String action) {
    switch (action.toLowerCase()) {
      case 'created':
      case 'create':
        return Icons.add_circle_outline;
      case 'updated':
      case 'update':
        return Icons.edit_outlined;
      case 'deleted':
      case 'delete':
        return Icons.delete_outline;
      case 'assigned':
      case 'assign':
        return Icons.person_add_outlined;
      case 'completed':
      case 'complete':
        return Icons.check_circle_outline;
      case 'commented':
      case 'comment':
        return Icons.comment_outlined;
      case 'uploaded':
      case 'upload':
        return Icons.upload_outlined;
      case 'started':
      case 'start':
        return Icons.play_arrow_outlined;
      case 'paused':
      case 'pause':
        return Icons.pause_outlined;
      case 'stopped':
      case 'stop':
        return Icons.stop_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getActivityColor(String action) {
    switch (action.toLowerCase()) {
      case 'created':
      case 'create':
        return Colors.green;
      case 'updated':
      case 'update':
        return Colors.blue;
      case 'deleted':
      case 'delete':
        return Colors.red;
      case 'assigned':
      case 'assign':
        return Colors.purple;
      case 'completed':
      case 'complete':
        return Colors.green;
      case 'commented':
      case 'comment':
        return Colors.orange;
      case 'uploaded':
      case 'upload':
        return Colors.indigo;
      case 'started':
      case 'start':
        return Colors.green;
      case 'paused':
      case 'pause':
        return Colors.orange;
      case 'stopped':
      case 'stop':
        return Colors.red;
      default:
        return AppColors.gray500;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleFilterAction(String filter) {
    // Implement filtering logic based on the selected filter
    switch (filter) {
      case 'all':
        ref.read(commentProvider.notifier).loadActivityLog();
        break;
      case 'tasks':
        // Filter for task-related activities only
        break;
      case 'comments':
        // Filter for comments only
        break;
    }
  }
}