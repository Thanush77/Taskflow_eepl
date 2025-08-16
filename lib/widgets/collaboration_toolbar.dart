import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../models/task.dart';
import '../providers/websocket_provider.dart';
import '../providers/auth_provider.dart';
import 'user_presence_widget.dart';
import 'notification_widget.dart';

class CollaborationToolbar extends ConsumerStatefulWidget {
  final Task task;
  final VoidCallback? onShare;
  final VoidCallback? onAssign;
  final VoidCallback? onWatch;

  const CollaborationToolbar({
    required this.task,
    this.onShare,
    this.onAssign,
    this.onWatch,
    super.key,
  });

  @override
  ConsumerState<CollaborationToolbar> createState() => _CollaborationToolbarState();
}

class _CollaborationToolbarState extends ConsumerState<CollaborationToolbar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final onlineUsers = ref.watch(onlineUsersProvider);
    final currentUser = ref.watch(authProvider).user;
    final isConnected = ref.watch(isConnectedProvider);

    // Get collaborators for this task
    final taskCollaborators = _getTaskCollaborators();
    final onlineCollaborators = taskCollaborators
        .where((userId) => onlineUsers.contains(userId))
        .length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isConnected 
              ? AppColors.successColor.withValues(alpha: 0.2)
              : AppColors.gray300,
        ),
      ),
      child: Column(
        children: [
          // Main toolbar
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Connection status indicator
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isConnected ? AppColors.successColor : AppColors.errorColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Team presence
                  TeamPresenceIndicator(
                    userIds: taskCollaborators,
                    avatarSize: 16,
                    maxAvatars: 3,
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Status text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isConnected ? 'Team Active' : 'Offline Mode',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isConnected ? AppColors.gray900 : AppColors.gray600,
                          ),
                        ),
                        Text(
                          '$onlineCollaborators of ${taskCollaborators.length} online',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Typing indicator for this task
                  TypingIndicator(taskId: widget.task.id!),
                  
                  // Expand/collapse icon
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.gray600,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded collaboration tools
          if (_isExpanded) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick actions
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.assignment_ind,
                          label: 'Assign',
                          color: AppColors.primaryColor,
                          onTap: widget.onAssign,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.share,
                          label: 'Share',
                          color: AppColors.successColor,
                          onTap: widget.onShare,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.visibility,
                          label: 'Watch',
                          color: AppColors.warningColor,
                          onTap: widget.onWatch,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Real-time activity feed
                  _buildActivityFeed(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timeline, size: 16, color: AppColors.gray600),
            const SizedBox(width: 6),
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
            const Spacer(),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.successColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Live',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.successColor,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Activity items
        ..._getRecentActivities().map((activity) => _buildActivityItem(activity)),
        
        if (_getRecentActivities().isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.history, size: 16, color: AppColors.gray500),
                const SizedBox(width: 8),
                Text(
                  'No recent activity',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _getActivityColor(activity['type']),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              activity['description'],
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.gray700,
              ),
            ),
          ),
          Text(
            activity['time'],
            style: TextStyle(
              fontSize: 10,
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'comment':
        return AppColors.primaryColor;
      case 'status':
        return AppColors.successColor;
      case 'assignment':
        return AppColors.warningColor;
      default:
        return AppColors.gray500;
    }
  }

  List<int> _getTaskCollaborators() {
    // In a real implementation, this would return actual collaborator IDs
    // For now, return some mock data
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return [];
    
    List<int> collaborators = [currentUser.id];
    if (widget.task.assignedTo != null) {
      collaborators.add(widget.task.assignedTo!);
    }
    
    return collaborators.toSet().toList();
  }

  List<Map<String, dynamic>> _getRecentActivities() {
    // Mock activity data - in real implementation, this would come from WebSocket events
    return [
      {
        'type': 'comment',
        'description': 'John added a comment',
        'time': '2m ago',
      },
      {
        'type': 'status',
        'description': 'Status changed to In Progress',
        'time': '5m ago',
      },
      {
        'type': 'assignment',
        'description': 'Task assigned to Sarah',
        'time': '10m ago',
      },
    ];
  }
}

class LiveCollaborationIndicator extends ConsumerWidget {
  final Task task;

  const LiveCollaborationIndicator({
    required this.task,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typingUsers = ref.watch(typingIndicatorsProvider.select(
      (indicators) => indicators[task.id!] ?? <int>[],
    ));
    final onlineUsers = ref.watch(onlineUsersProvider);
    final isConnected = ref.watch(isConnectedProvider);

    if (!isConnected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.errorColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 12, color: AppColors.errorColor),
            const SizedBox(width: 4),
            Text(
              'Offline',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.errorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (typingUsers.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: TypingAnimation(),
            ),
            const SizedBox(width: 4),
            Text(
              typingUsers.length == 1 ? 'Someone typing...' : '${typingUsers.length} typing...',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Show active collaborators count
    final taskCollaborators = _getTaskCollaborators(task);
    final activeCollaborators = taskCollaborators
        .where((userId) => onlineUsers.contains(userId))
        .length;

    if (activeCollaborators > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.successColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: AppColors.successColor),
            const SizedBox(width: 4),
            Text(
              '$activeCollaborators active',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.successColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  List<int> _getTaskCollaborators(Task task) {
    // Mock implementation - in reality this would come from task data
    List<int> collaborators = [];
    if (task.assignedTo != null) {
      collaborators.add(task.assignedTo!);
    }
    return collaborators;
  }
}

class TaskMentionWidget extends StatefulWidget {
  final Task task;
  final Function(List<int>) onMention;

  const TaskMentionWidget({
    required this.task,
    required this.onMention,
    super.key,
  });

  @override
  State<TaskMentionWidget> createState() => _TaskMentionWidgetState();
}

class _TaskMentionWidgetState extends State<TaskMentionWidget> {
  final TextEditingController _controller = TextEditingController();
  List<int> _mentionedUsers = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.alternate_email, size: 16, color: AppColors.primaryColor),
              const SizedBox(width: 6),
              const Text(
                'Mention Team Members',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Type @ to mention someone...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: _handleTextChange,
          ),
          
          if (_mentionedUsers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: _mentionedUsers.map((userId) => Chip(
                label: Text('User $userId'),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _mentionedUsers.remove(userId);
                  });
                },
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _handleTextChange(String text) {
    // Simple mention detection - in reality this would be more sophisticated
    if (text.contains('@')) {
      // Mock user mention - in reality this would search actual users
      setState(() {
        _mentionedUsers = [1, 2]; // Mock user IDs
      });
      widget.onMention(_mentionedUsers);
    }
  }
}