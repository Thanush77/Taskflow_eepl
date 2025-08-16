import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../models/user.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';
import 'user_presence_widget.dart';

class TaskAssignmentDialog extends ConsumerStatefulWidget {
  final Task task;
  final List<User> availableUsers;

  const TaskAssignmentDialog({
    required this.task,
    required this.availableUsers,
    super.key,
  });

  @override
  ConsumerState<TaskAssignmentDialog> createState() => _TaskAssignmentDialogState();
}

class _TaskAssignmentDialogState extends ConsumerState<TaskAssignmentDialog> {
  int? _selectedUserId;
  String _searchQuery = '';
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _selectedUserId = widget.task.assignedTo;
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = widget.availableUsers
        .where((user) => user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_ind, color: AppColors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assign Task',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                        Text(
                          widget.task.title,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.white.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.white),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search team members...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            // Unassign option
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.person_off, color: AppColors.gray600),
              ),
              title: const Text('Unassigned'),
              subtitle: const Text('Remove current assignment'),
              trailing: Radio<int?>(
                value: null,
                groupValue: _selectedUserId,
                onChanged: (value) {
                  setState(() {
                    _selectedUserId = value;
                  });
                },
              ),
              onTap: () {
                setState(() {
                  _selectedUserId = null;
                });
              },
            ),

            const Divider(),

            // User list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  final isSelected = _selectedUserId == user.id;
                  final currentUser = ref.watch(authProvider).user;
                  final isCurrentUser = currentUser?.id == user.id;

                  return ListTile(
                    leading: UserPresenceAvatar(user: user, radius: 20),
                    title: Row(
                      children: [
                        Text(user.fullName),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(user.role ?? 'Team Member'),
                    trailing: Radio<int>(
                      value: user.id,
                      groupValue: _selectedUserId,
                      onChanged: (value) {
                        setState(() {
                          _selectedUserId = value;
                        });
                      },
                    ),
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedUserId = user.id;
                      });
                    },
                  );
                },
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isAssigning ? null : _assignTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.white,
                      ),
                      child: _isAssigning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Text('Assign'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignTask() async {
    setState(() {
      _isAssigning = true;
    });

    try {
      final success = await ref.read(taskProvider.notifier).updateTask(
        widget.task.id!,
        {'assignedTo': _selectedUserId},
      );

      if (success && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedUserId == null
                  ? 'Task unassigned successfully'
                  : 'Task assigned successfully',
            ),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAssigning = false;
        });
      }
    }
  }
}

class TaskAssigneeChip extends ConsumerWidget {
  final Task task;
  final VoidCallback? onTap;
  final bool showLabel;

  const TaskAssigneeChip({
    required this.task,
    this.onTap,
    this.showLabel = true,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamState = ref.watch(teamProvider);
    
    if (task.assignedTo == null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gray300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_add, size: 16, color: AppColors.gray600),
              if (showLabel) ...[
                const SizedBox(width: 4),
                const Text(
                  'Assign',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final assignee = teamState.users
        .where((user) => user.id == task.assignedTo)
        .firstOrNull;

    if (assignee == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Unknown User',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.gray600,
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserPresenceAvatar(user: assignee, radius: 8),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(
                assignee.fullName.split(' ').first,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TeamCollaborationPanel extends ConsumerWidget {
  final Task task;

  const TeamCollaborationPanel({
    required this.task,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamState = ref.watch(teamProvider);
    final currentUser = ref.watch(authProvider).user;

    // Get team members who have interacted with this task
    final taskCollaborators = _getTaskCollaborators(teamState.users);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group, color: AppColors.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Team Collaboration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
              const Spacer(),
              if (taskCollaborators.length > 3)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${taskCollaborators.length - 3} more',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.gray600,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Assignee section
          Row(
            children: [
              const Text(
                'Assignee:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray700,
                ),
              ),
              const SizedBox(width: 8),
              TaskAssigneeChip(
                task: task,
                onTap: () => _showAssignmentDialog(context, ref),
              ),
            ],
          ),
          
          if (taskCollaborators.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Collaborators:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(height: 8),
            TeamPresenceIndicator(
              userIds: taskCollaborators.map((u) => u.id).toList(),
              maxAvatars: 5,
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Quick actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAssignmentDialog(context, ref),
                  icon: const Icon(Icons.assignment_ind, size: 16),
                  label: const Text('Reassign'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareTask(context),
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.successColor,
                  ),
                ),
              ),
            ],
          ),
          
          // Collaboration tools
          if (task.assignedTo != null && task.assignedTo != currentUser?.id) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This task is assigned to another team member. You can collaborate by adding comments.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<User> _getTaskCollaborators(List<User> allUsers) {
    // In a real implementation, this would get users who have commented
    // or interacted with the task. For now, return a subset of users.
    return allUsers.take(3).toList();
  }

  void _showAssignmentDialog(BuildContext context, WidgetRef ref) {
    final teamState = ref.read(teamProvider);
    
    showDialog(
      context: context,
      builder: (context) => TaskAssignmentDialog(
        task: task,
        availableUsers: teamState.users,
      ),
    );
  }

  void _shareTask(BuildContext context) {
    // Implement task sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task sharing functionality coming soon'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }
}

class TaskWatchersWidget extends ConsumerWidget {
  final Task task;
  final List<int> watcherIds;

  const TaskWatchersWidget({
    required this.task,
    required this.watcherIds,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamState = ref.watch(teamProvider);
    final watchers = teamState.users
        .where((user) => watcherIds.contains(user.id))
        .toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility, size: 16, color: AppColors.gray600),
              const SizedBox(width: 6),
              Text(
                'Watchers (${watchers.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _manageWatchers(context, ref),
                child: const Text(
                  'Manage',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          
          if (watchers.isNotEmpty) ...[
            const SizedBox(height: 8),
            TeamPresenceIndicator(
              userIds: watchers.map((u) => u.id).toList(),
              maxAvatars: 4,
              avatarSize: 16,
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No watchers added yet',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.gray500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _manageWatchers(BuildContext context, WidgetRef ref) {
    // Implement watcher management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Watcher management coming soon'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }
}