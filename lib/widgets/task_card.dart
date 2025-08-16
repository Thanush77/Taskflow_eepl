import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'time_tracker_widget.dart';
import 'file_attachment_widget.dart';
import 'subtask_widget.dart';
import 'comment_widget.dart';

class TaskCard extends ConsumerWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(TaskStatus) onStatusChange;

  const TaskCard({
    required this.task,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamState = ref.watch(teamProvider);
    final assignedUser = teamState.users
        .where((user) => user.id == task.assignedTo)
        .isNotEmpty 
            ? teamState.users.where((user) => user.id == task.assignedTo).first
            : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          left: BorderSide(
            color: _getPriorityColor(task.priority),
            width: 4,
          ),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(context, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: AppColors.errorColor),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppColors.errorColor)),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(
                      Icons.more_vert,
                      color: AppColors.gray400,
                      size: 20,
                    ),
                  ),
                ],
              ),
              
              // Description
              if (task.description?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.gray600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Status and details row
              Row(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(task.status),
                      style: TextStyle(
                        color: _getStatusColor(task.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Priority indicator
                  Icon(
                    _getPriorityIcon(task.priority),
                    color: _getPriorityColor(task.priority),
                    size: 16,
                  ),
                  
                  const Spacer(),
                  
                  // Due date
                  if (task.dueDate != null) ...[
                    Icon(
                      Icons.event_outlined,
                      color: _isDueToday(task.dueDate!) ? AppColors.warningColor :
                             _isOverdue(task.dueDate!) ? AppColors.errorColor : AppColors.gray500,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDueDate(task.dueDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: _isDueToday(task.dueDate!) ? AppColors.warningColor :
                               _isOverdue(task.dueDate!) ? AppColors.errorColor : AppColors.gray500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Bottom row with assignee and actions
              Row(
                children: [
                  // Assignee
                  if (assignedUser != null) ...[
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                      child: Text(
                        assignedUser.initials,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      assignedUser.fullName,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray600,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppColors.gray400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Unassigned',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // Subtasks (compact)
                  SubtaskWidget(
                    task: task,
                    showCompact: true,
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // File attachments (compact)
                  FileAttachmentWidget(
                    task: task,
                    showCompact: true,
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Comments (compact)
                  CommentWidget(
                    task: task,
                    showCompact: true,
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Time tracker (compact)
                  TimeTrackerWidget(
                    task: task,
                    showCompact: true,
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Quick status change buttons
                  if (task.status != TaskStatus.completed)
                    IconButton(
                      onPressed: () => onStatusChange(TaskStatus.completed),
                      icon: const Icon(Icons.check_circle_outline),
                      iconSize: 20,
                      color: AppColors.successColor,
                      tooltip: 'Mark as completed',
                    ),
                  
                  if (task.status == TaskStatus.pending)
                    IconButton(
                      onPressed: () => onStatusChange(TaskStatus.inProgress),
                      icon: const Icon(Icons.play_circle_outline),
                      iconSize: 20,
                      color: AppColors.primaryColor,
                      tooltip: 'Start working',
                    ),
                ],
              ),
              
              // Tags
              if (task.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: task.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.gray700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        onEdit();
        break;
      case 'delete':
        onDelete();
        break;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.red;
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

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.lowest:
        return Colors.grey;
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.critical:
        return Colors.purple;
    }
  }

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.lowest:
      case TaskPriority.low:
        return Icons.keyboard_double_arrow_down;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.high:
        return Icons.keyboard_double_arrow_up;
      case TaskPriority.critical:
        return Icons.priority_high;
    }
  }

  bool _isOverdue(DateTime dueDate) {
    return dueDate.isBefore(DateTime.now()) && task.status != TaskStatus.completed;
  }

  bool _isDueToday(DateTime dueDate) {
    final now = DateTime.now();
    return dueDate.year == now.year &&
           dueDate.month == now.month &&
           dueDate.day == now.day;
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    
    if (_isOverdue(dueDate)) {
      return 'Overdue';
    } else if (_isDueToday(dueDate)) {
      return 'Due today';
    } else if (difference == 1) {
      return 'Due tomorrow';
    } else if (difference <= 7) {
      return 'Due in ${difference}d';
    } else {
      return '${dueDate.day}/${dueDate.month}';
    }
  }
}