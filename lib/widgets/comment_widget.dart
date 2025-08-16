import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../models/task.dart';
import '../models/comment.dart';
import '../providers/comment_provider.dart';
import '../providers/auth_provider.dart';

class CommentWidget extends ConsumerStatefulWidget {
  final Task task;
  final bool showCompact;
  final VoidCallback? onCommentsChanged;

  const CommentWidget({
    required this.task,
    this.showCompact = false,
    this.onCommentsChanged,
    super.key,
  });

  @override
  ConsumerState<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends ConsumerState<CommentWidget> 
    with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  bool _isAddingComment = false;
  TaskComment? _editingComment;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load comments when the widget is initialized
    if (widget.task.id != null) {
      Future.microtask(() {
        ref.read(commentProvider.notifier).loadTaskComments(widget.task.id!);
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentState = ref.watch(commentProvider);
    final comments = commentState.taskComments[widget.task.id] ?? [];

    if (widget.showCompact) {
      return _buildCompactView(comments);
    } else {
      return _buildExpandedView(comments);
    }
  }

  Widget _buildCompactView(List<TaskComment> comments) {
    final commentCount = comments.where((c) => c.type == CommentType.comment).length;
    final activityCount = comments.where((c) => c.isSystemComment).length;

    if (commentCount == 0 && activityCount == 0) return const SizedBox.shrink();

    return Row(
      children: [
        if (commentCount > 0) ...[
          Icon(
            Icons.comment_outlined,
            size: 14,
            color: AppColors.gray500,
          ),
          const SizedBox(width: 4),
          Text(
            commentCount.toString(),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.gray600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (commentCount > 0 && activityCount > 0)
          const SizedBox(width: 8),
        if (activityCount > 0) ...[
          Icon(
            Icons.history,
            size: 14,
            color: AppColors.gray500,
          ),
          const SizedBox(width: 4),
          Text(
            activityCount.toString(),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.gray600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExpandedView(List<TaskComment> comments) {
    final userComments = comments.where((c) => c.type == CommentType.comment).toList();
    final systemComments = comments.where((c) => c.isSystemComment).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.forum_outlined,
              size: 20,
              color: AppColors.primaryColor,
            ),
            const SizedBox(width: 8),
            const Text(
              'Comments & Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
            const Spacer(),
            if (comments.isNotEmpty)
              Text(
                '${userComments.length + systemComments.length} items',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.gray600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Tabs for comments and activity
        if (comments.isNotEmpty) ...[
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: AppColors.gray600,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            tabs: [
              Tab(text: 'Comments (${userComments.length})'),
              Tab(text: 'Activity (${systemComments.length})'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCommentsList(userComments),
                _buildActivityList(systemComments),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gray300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.comment_outlined,
                  color: AppColors.gray400,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No comments yet',
                        style: TextStyle(
                          color: AppColors.gray600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Start a discussion about this task',
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
          ),
          const SizedBox(height: 16),
        ],

        // Add comment section
        _buildAddCommentSection(),
      ],
    );
  }

  Widget _buildCommentsList(List<TaskComment> comments) {
    if (comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 48,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 12),
            Text(
              'No comments yet',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.gray600,
              ),
            ),
            Text(
              'Be the first to comment on this task',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        return _buildCommentItem(comments[index]);
      },
    );
  }

  Widget _buildActivityList(List<TaskComment> activities) {
    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 12),
            Text(
              'No activity yet',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.gray600,
              ),
            ),
            Text(
              'Task changes will appear here',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        return _buildActivityItem(activities[index]);
      },
    );
  }

  Widget _buildCommentItem(TaskComment comment) {
    final authState = ref.watch(authProvider);
    final isOwner = comment.userId == authState.user?.id;
    final isEditing = _editingComment?.id == comment.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info and timestamp
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                child: Text(
                  comment.displayInitials,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    Text(
                      _formatTimestamp(comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwner && !isEditing)
                PopupMenuButton<String>(
                  onSelected: (value) => _handleCommentAction(comment, value),
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
                  child: Icon(
                    Icons.more_vert,
                    color: AppColors.gray400,
                    size: 16,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Comment content
          if (isEditing) ...[
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Edit your comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _cancelEdit,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _saveEditedComment(comment),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
                  child: const Text('Save', style: TextStyle(color: AppColors.white)),
                ),
              ],
            ),
          ] else ...[
            Text(
              comment.content,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.gray700,
                height: 1.4,
              ),
            ),
            if (comment.isEdited) ...[
              const SizedBox(height: 4),
              Text(
                'Edited ${comment.updatedAt != null ? _formatTimestamp(comment.updatedAt!) : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.gray500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildActivityItem(TaskComment activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getActivityIcon(activity.type),
            size: 16,
            color: _getActivityColor(activity.type),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.gray700,
                    ),
                    children: [
                      TextSpan(
                        text: activity.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' ${activity.typeDisplayText}'),
                    ],
                  ),
                ),
                if (activity.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    activity.content,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.gray600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(activity.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCommentSection() {
    final authState = ref.watch(authProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                child: Text(
                  authState.user?.initials ?? 'U',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  onTap: () {
                    // Auto-expand on focus
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          
          if (_commentController.text.isNotEmpty || _isAddingComment) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _cancelComment,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isAddingComment ? null : _addComment,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
                  child: _isAddingComment
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Comment', style: TextStyle(color: AppColors.white)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _handleCommentAction(TaskComment comment, String action) {
    switch (action) {
      case 'edit':
        _startEditComment(comment);
        break;
      case 'delete':
        _deleteComment(comment);
        break;
    }
  }

  void _startEditComment(TaskComment comment) {
    setState(() {
      _editingComment = comment;
      _commentController.text = comment.content;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingComment = null;
      _commentController.clear();
    });
  }

  Future<void> _saveEditedComment(TaskComment comment) async {
    if (_commentController.text.trim().isEmpty) return;

    final success = await ref.read(commentProvider.notifier).updateComment(
      comment.id!,
      _commentController.text.trim(),
    );

    if (success) {
      _cancelEdit();
      widget.onCommentsChanged?.call();
    }
  }

  Future<void> _deleteComment(TaskComment comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
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
      final success = await ref.read(commentProvider.notifier).deleteComment(comment.id!);
      if (success) {
        widget.onCommentsChanged?.call();
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isAddingComment = true;
    });

    final success = await ref.read(commentProvider.notifier).addComment(
      widget.task.id!,
      _commentController.text.trim(),
    );

    setState(() {
      _isAddingComment = false;
    });

    if (success) {
      _commentController.clear();
      widget.onCommentsChanged?.call();
      
      // Scroll to bottom to show new comment
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _cancelComment() {
    setState(() {
      _commentController.clear();
    });
  }

  IconData _getActivityIcon(CommentType type) {
    switch (type) {
      case CommentType.statusChange:
        return Icons.track_changes;
      case CommentType.assignmentChange:
        return Icons.person_add;
      case CommentType.priorityChange:
        return Icons.flag;
      case CommentType.attachment:
        return Icons.attach_file;
      case CommentType.subtask:
        return Icons.checklist;
      case CommentType.timeTracking:
        return Icons.access_time;
      default:
        return Icons.info_outline;
    }
  }

  Color _getActivityColor(CommentType type) {
    switch (type) {
      case CommentType.statusChange:
        return Colors.blue;
      case CommentType.assignmentChange:
        return Colors.green;
      case CommentType.priorityChange:
        return Colors.orange;
      case CommentType.attachment:
        return Colors.purple;
      case CommentType.subtask:
        return Colors.indigo;
      case CommentType.timeTracking:
        return Colors.teal;
      default:
        return AppColors.gray500;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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
}