import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../providers/subtask_provider.dart';
import '../providers/team_provider.dart';
import '../providers/auth_provider.dart';

class SubtaskWidget extends ConsumerStatefulWidget {
  final Task task;
  final bool showCompact;
  final VoidCallback? onSubtasksChanged;

  const SubtaskWidget({
    required this.task,
    this.showCompact = false,
    this.onSubtasksChanged,
    super.key,
  });

  @override
  ConsumerState<SubtaskWidget> createState() => _SubtaskWidgetState();
}

class _SubtaskWidgetState extends ConsumerState<SubtaskWidget> {
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load subtasks when the widget is initialized
    if (widget.task.id != null) {
      Future.microtask(() {
        ref.read(subtaskProvider.notifier).loadTaskSubtasks(widget.task.id!);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtaskState = ref.watch(subtaskProvider);
    final subtasks = subtaskState.subtasks[widget.task.id] ?? [];

    if (widget.showCompact) {
      return _buildCompactView(subtasks);
    } else {
      return _buildExpandedView(subtasks);
    }
  }

  Widget _buildCompactView(List<Subtask> subtasks) {
    if (subtasks.isEmpty) return const SizedBox.shrink();

    final completedCount = subtasks.where((s) => s.isCompleted).length;
    final totalCount = subtasks.length;

    return Row(
      children: [
        Icon(
          Icons.checklist,
          size: 14,
          color: AppColors.gray500,
        ),
        const SizedBox(width: 4),
        Text(
          '$completedCount/$totalCount',
          style: TextStyle(
            fontSize: 12,
            color: completedCount == totalCount ? AppColors.successColor : AppColors.gray600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedView(List<Subtask> subtasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.checklist,
              size: 20,
              color: AppColors.primaryColor,
            ),
            const SizedBox(width: 8),
            const Text(
              'Subtasks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
            const Spacer(),
            if (subtasks.isNotEmpty) ...[
              Text(
                '${subtasks.where((s) => s.isCompleted).length}/${subtasks.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.gray600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
            ],
            IconButton(
              onPressed: () => _showAddSubtaskDialog(),
              icon: const Icon(Icons.add, size: 20),
              color: AppColors.primaryColor,
              tooltip: 'Add subtask',
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Progress bar
        if (subtasks.isNotEmpty) ...[
          _buildProgressBar(subtasks),
          const SizedBox(height: 16),
        ],

        if (subtasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gray300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.task_outlined,
                  color: AppColors.gray400,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No subtasks yet',
                        style: TextStyle(
                          color: AppColors.gray600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Break down this task into smaller steps',
                        style: TextStyle(
                          color: AppColors.gray500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ...subtasks.map((subtask) => _buildSubtaskItem(subtask)),
      ],
    );
  }

  Widget _buildProgressBar(List<Subtask> subtasks) {
    final completedCount = subtasks.where((s) => s.isCompleted).length;
    final progress = completedCount / subtasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray700,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).round()}% complete',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gray600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.gray200,
          valueColor: AlwaysStoppedAnimation<Color>(
            progress == 1.0 ? AppColors.successColor : AppColors.primaryColor,
          ),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildSubtaskItem(Subtask subtask) {
    final teamState = ref.watch(teamProvider);
    final assignedUser = subtask.assignedTo != null
        ? teamState.users.where((user) => user.id == subtask.assignedTo).firstOrNull
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: subtask.isCompleted 
            ? AppColors.successColor.withValues(alpha: 0.05)
            : AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: subtask.isCompleted 
              ? AppColors.successColor.withValues(alpha: 0.3)
              : AppColors.gray200,
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () => _toggleSubtask(subtask),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: subtask.isCompleted ? AppColors.successColor : Colors.transparent,
                border: Border.all(
                  color: subtask.isCompleted ? AppColors.successColor : AppColors.gray400,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: subtask.isCompleted
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtask.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: subtask.isCompleted ? AppColors.gray600 : AppColors.gray900,
                    decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (subtask.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtask.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.gray600,
                      decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
                if (assignedUser != null || subtask.dueDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (assignedUser != null) ...[
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: AppColors.gray200,
                          child: Text(
                            assignedUser.initials,
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          assignedUser.fullName,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                      if (assignedUser != null && subtask.dueDate != null)
                        const SizedBox(width: 12),
                      if (subtask.dueDate != null) ...[
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: subtask.isOverdue ? AppColors.errorColor : AppColors.gray500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(subtask.dueDate!),
                          style: TextStyle(
                            fontSize: 11,
                            color: subtask.isOverdue ? AppColors.errorColor : AppColors.gray600,
                            fontWeight: subtask.isOverdue ? FontWeight.w500 : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Actions
          PopupMenuButton<String>(
            onSelected: (value) => _handleSubtaskAction(subtask, value),
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
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSubtask(Subtask subtask) async {
    final success = await ref.read(subtaskProvider.notifier).toggleSubtask(subtask.id!);
    if (success) {
      widget.onSubtasksChanged?.call();
    }
  }

  void _showAddSubtaskDialog() {
    _titleController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subtask'),
        content: TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Subtask title',
            hintText: 'Enter a brief description',
          ),
          autofocus: true,
          maxLines: 2,
          onSubmitted: (_) => _addSubtask(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addSubtask,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
            child: const Text('Add', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _addSubtask() async {
    if (_titleController.text.trim().isEmpty) return;

    Navigator.pop(context);
    
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    final subtask = Subtask(
      parentTaskId: widget.task.id!,
      title: _titleController.text.trim(),
      createdBy: authState.user!.id,
      createdAt: DateTime.now(),
    );

    final success = await ref.read(subtaskProvider.notifier).createSubtask(subtask);
    if (success) {
      widget.onSubtasksChanged?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subtask added successfully'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    }
  }

  void _handleSubtaskAction(Subtask subtask, String action) {
    switch (action) {
      case 'edit':
        _showEditSubtaskDialog(subtask);
        break;
      case 'delete':
        _deleteSubtask(subtask);
        break;
    }
  }

  void _showEditSubtaskDialog(Subtask subtask) {
    _titleController.text = subtask.title;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Subtask'),
        content: TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Subtask title',
            hintText: 'Enter a brief description',
          ),
          autofocus: true,
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateSubtask(subtask),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
            child: const Text('Update', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSubtask(Subtask subtask) async {
    if (_titleController.text.trim().isEmpty) return;

    Navigator.pop(context);
    
    final updatedSubtask = subtask.copyWith(title: _titleController.text.trim());
    final success = await ref.read(subtaskProvider.notifier).updateSubtask(updatedSubtask);
    if (success) {
      widget.onSubtasksChanged?.call();
    }
  }

  Future<void> _deleteSubtask(Subtask subtask) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subtask'),
        content: Text('Are you sure you want to delete "${subtask.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorColor),
            child: const Text('Delete', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(subtaskProvider.notifier).deleteSubtask(subtask.id!);
      if (success) {
        widget.onSubtasksChanged?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subtask deleted successfully')),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays == 0) {
      return 'Due today';
    } else if (difference.inDays == 1) {
      return 'Due tomorrow';
    } else if (difference.inDays <= 7) {
      return 'Due in ${difference.inDays}d';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}