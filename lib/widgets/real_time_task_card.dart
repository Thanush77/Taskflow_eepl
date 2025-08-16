import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../models/task.dart';
import '../providers/websocket_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import 'user_presence_widget.dart';
import 'notification_widget.dart';

class RealTimeTaskCard extends ConsumerStatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RealTimeTaskCard({
    required this.task,
    this.onTap,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  @override
  ConsumerState<RealTimeTaskCard> createState() => _RealTimeTaskCardState();
}

class _RealTimeTaskCardState extends ConsumerState<RealTimeTaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _hasRecentUpdate = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _listenToTaskUpdates();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _listenToTaskUpdates() {
    ref.listen(taskUpdatesProvider, (previous, next) {
      next.whenData((event) {
        if (event.task.id == widget.task.id) {
          _showUpdateAnimation();
        }
      });
    });

    ref.listen(taskStatusChangedProvider, (previous, next) {
      next.whenData((event) {
        if (event.taskId == widget.task.id) {
          _showUpdateAnimation();
        }
      });
    });

    ref.listen(taskAssignedProvider, (previous, next) {
      next.whenData((event) {
        if (event.taskId == widget.task.id) {
          _showUpdateAnimation();
        }
      });
    });
  }

  void _showUpdateAnimation() {
    setState(() {
      _hasRecentUpdate = true;
    });

    _animationController.forward().then((_) {
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _hasRecentUpdate = false;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final isAssignedToMe = widget.task.assignedTo == currentUser?.id;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: _hasRecentUpdate
                  ? Border.all(color: AppColors.primaryColor, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                if (_hasRecentUpdate)
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        // Priority indicator
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(widget.task.priority).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            _getPriorityIcon(widget.task.priority),
                            size: 16,
                            color: _getPriorityColor(widget.task.priority),
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Task title
                        Expanded(
                          child: Text(
                            widget.task.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(widget.task.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(widget.task.status),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _getStatusColor(widget.task.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (widget.task.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.task.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.gray600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    
                    // Footer row
                    Row(
                      children: [
                        // Category chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getCategoryText(widget.task.category),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.gray700,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Due date if exists
                        if (widget.task.dueDate != null) ...[
                          Icon(
                            Icons.schedule,
                            size: 12,
                            color: _isOverdue(widget.task.dueDate!) 
                                ? AppColors.errorColor 
                                : AppColors.gray500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDueDate(widget.task.dueDate!),
                            style: TextStyle(
                              fontSize: 11,
                              color: _isOverdue(widget.task.dueDate!) 
                                  ? AppColors.errorColor 
                                  : AppColors.gray600,
                              fontWeight: _isOverdue(widget.task.dueDate!) 
                                  ? FontWeight.w600 
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                        
                        const Spacer(),
                        
                        // Assignee avatar if assigned to someone else
                        if (widget.task.assignedTo != null && !isAssignedToMe) ...[
                          Consumer(
                            builder: (context, ref, child) {
                              final teamState = ref.watch(teamProvider);
                              final assignee = teamState.users
                                  .where((u) => u.id == widget.task.assignedTo)
                                  .firstOrNull;
                              if (assignee != null) {
                                return UserPresenceAvatar(
                                  user: assignee,
                                  radius: 12,
                                );
                              }
                              return const SizedBox(
                                width: 24,
                                height: 24,
                                child: Icon(Icons.person, size: 16, color: AppColors.gray400),
                              );
                            },
                          ),
                        ],
                        
                        // Typing indicator for this task
                        TypingIndicator(taskId: widget.task.id!),
                        
                        // Connection status for assigned tasks
                        if (isAssignedToMe)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: ConnectionStatusIndicator(),
                          ),
                      ],
                    ),
                    
                    // Real-time update indicator
                    if (_hasRecentUpdate)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sync,
                              size: 12,
                              color: AppColors.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Updated in real-time',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.lowest:
        return AppColors.gray500;
      case TaskPriority.low:
        return AppColors.primaryColor;
      case TaskPriority.medium:
        return AppColors.warningColor;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.critical:
        return AppColors.errorColor;
    }
  }

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.lowest:
      case TaskPriority.low:
        return Icons.keyboard_arrow_down;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.high:
        return Icons.keyboard_arrow_up;
      case TaskPriority.critical:
        return Icons.keyboard_double_arrow_up;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return AppColors.gray500;
      case TaskStatus.inProgress:
        return AppColors.primaryColor;
      case TaskStatus.completed:
        return AppColors.successColor;
      case TaskStatus.cancelled:
        return AppColors.errorColor;
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _getCategoryText(TaskCategory category) {
    switch (category) {
      case TaskCategory.general:
        return 'General';
      case TaskCategory.development:
        return 'Development';
      case TaskCategory.design:
        return 'Design';
      case TaskCategory.marketing:
        return 'Marketing';
      case TaskCategory.research:
        return 'Research';
      case TaskCategory.planning:
        return 'Planning';
      case TaskCategory.testing:
        return 'Testing';
    }
  }

  bool _isOverdue(DateTime dueDate) {
    return dueDate.isBefore(DateTime.now());
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 0) {
      return 'In ${difference}d';
    } else {
      return '${-difference}d ago';
    }
  }
}

// Live task list with real-time updates
class LiveTaskList extends ConsumerWidget {
  final List<Task> tasks;
  final Function(Task)? onTaskTap;
  final Function(Task)? onTaskEdit;
  final Function(Task)? onTaskDelete;

  const LiveTaskList({
    required this.tasks,
    this.onTaskTap,
    this.onTaskEdit,
    this.onTaskDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize real-time sync
    ref.watch(realTimeTaskSyncProvider);
    
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return RealTimeTaskCard(
          key: ValueKey('task_${task.id}'),
          task: task,
          onTap: onTaskTap != null ? () => onTaskTap!(task) : null,
          onEdit: onTaskEdit != null ? () => onTaskEdit!(task) : null,
          onDelete: onTaskDelete != null ? () => onTaskDelete!(task) : null,
        );
      },
    );
  }
}