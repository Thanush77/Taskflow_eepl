import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/task_card.dart';
import '../../widgets/time_tracker_widget.dart';
import '../../widgets/file_attachment_widget.dart';
import '../../widgets/subtask_widget.dart';
import '../../widgets/comment_widget.dart';
import 'task_form_screen.dart';
import 'kanban_board_screen.dart';
import 'recurring_tasks_screen.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showKanbanView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Load tasks and team data on init
    Future.microtask(() {
      ref.read(taskProvider.notifier).loadTasks();
      ref.read(teamProvider.notifier).loadUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header with search and filters
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
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.task_alt, color: AppColors.primaryColor, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Tasks',
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
                            setState(() {
                              _showKanbanView = !_showKanbanView;
                            });
                          },
                          icon: Icon(
                            _showKanbanView ? Icons.view_list : Icons.view_kanban,
                            color: AppColors.primaryColor,
                          ),
                          tooltip: _showKanbanView ? 'List View' : 'Kanban View',
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const RecurringTasksScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.repeat, color: AppColors.primaryColor),
                          tooltip: 'Recurring Tasks',
                        ),
                        IconButton(
                          onPressed: () {
                            ref.read(taskProvider.notifier).refresh();
                          },
                          icon: const Icon(Icons.refresh, color: AppColors.primaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.gray100,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Status tabs
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.primaryColor,
                  unselectedLabelColor: AppColors.gray600,
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
                  ),
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Pending'),
                    Tab(text: 'In Progress'),
                    Tab(text: 'Completed'),
                    Tab(text: 'Overdue'),
                  ],
                ),
              ],
            ),
          ),
          
          // Task list or Kanban board
          Expanded(
            child: taskState.isLoading && taskState.tasks.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LoadingWidget(),
                        SizedBox(height: 16),
                        Text('Loading tasks...', style: TextStyle(color: AppColors.gray600)),
                      ],
                    ),
                  )
                : _showKanbanView
                    ? KanbanBoardScreen()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTaskList(_filterTasks(taskState.tasks)),
                          _buildTaskList(_filterTasks(_getTasksByStatus(TaskStatus.pending))),
                          _buildTaskList(_filterTasks(_getTasksByStatus(TaskStatus.inProgress))),
                          _buildTaskList(_filterTasks(_getTasksByStatus(TaskStatus.completed))),
                          _buildTaskList(_filterTasks(ref.watch(overdueTasksProvider))),
                        ],
                      ),
          ),
        ],
      ),
      
      // Floating action button for creating new tasks
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TaskFormScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }

  List<Task> _getTasksByStatus(TaskStatus status) {
    final taskState = ref.read(taskProvider);
    return taskState.tasks.where((task) => task.status == status).toList();
  }

  List<Task> _filterTasks(List<Task> tasks) {
    if (_searchQuery.isEmpty) return tasks;
    
    return tasks.where((task) {
      return task.title.toLowerCase().contains(_searchQuery) ||
             (task.description?.toLowerCase().contains(_searchQuery) ?? false) ||
             task.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
    }).toList();
  }

  Widget _buildTaskList(List<Task> tasks) {
    final taskState = ref.watch(taskProvider);
    
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              taskState.error != null 
                  ? 'Error loading tasks'
                  : _searchQuery.isNotEmpty 
                      ? 'No tasks match your search'
                      : 'No tasks found',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.gray600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              taskState.error ?? (_searchQuery.isNotEmpty 
                  ? 'Try adjusting your search terms'
                  : 'Create your first task to get started'),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray500,
              ),
            ),
            if (taskState.error != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(taskProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(taskProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskCard(
            task: task,
            onTap: () => _showTaskDetails(task),
            onEdit: () => _editTask(task),
            onDelete: () => _deleteTask(task),
            onStatusChange: (status) => _updateTaskStatus(task, status),
          );
        },
      ),
    );
  }

  void _showTaskDetails(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailsBottomSheet(task: task),
    );
  }

  void _editTask(Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: task),
      ),
    );
  }

  Future<void> _deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
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
      final success = await ref.read(taskProvider.notifier).deleteTask(task.id!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted successfully')),
        );
      }
    }
  }

  Future<void> _updateTaskStatus(Task task, TaskStatus status) async {
    await ref.read(taskProvider.notifier).updateTask(
      task.id!,
      {'status': status.name},
    );
  }
}

class TaskDetailsBottomSheet extends ConsumerWidget {
  final Task task;

  const TaskDetailsBottomSheet({required this.task, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamState = ref.watch(teamProvider);
    final assignedUser = teamState.users
        .where((user) => user.id == task.assignedTo)
        .isNotEmpty 
            ? teamState.users.where((user) => user.id == task.assignedTo).first
            : null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task title and status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(task.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getStatusText(task.status),
                          style: TextStyle(
                            color: _getStatusColor(task.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  if (task.description?.isNotEmpty == true) ...[
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      task.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.gray700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Task details grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildDetailItem('Priority', _getPriorityText(task.priority), _getPriorityIcon(task.priority)),
                      _buildDetailItem('Category', _getCategoryText(task.category), Icons.category_outlined),
                      _buildDetailItem('Assigned to', assignedUser?.fullName ?? 'Unassigned', Icons.person_outline),
                      _buildDetailItem('Estimated', '${task.estimatedHours}h', Icons.access_time_outlined),
                      if (task.dueDate != null)
                        _buildDetailItem('Due Date', _formatDate(task.dueDate!), Icons.event_outlined),
                      _buildDetailItem('Created', _formatDate(task.createdAt ?? DateTime.now()), Icons.calendar_today_outlined),
                    ],
                  ),
                  
                  // Time Tracking
                  const SizedBox(height: 24),
                  TimeTrackerWidget(
                    task: task,
                    showCompact: false,
                  ),
                  
                  // File Attachments
                  const SizedBox(height: 24),
                  FileAttachmentWidget(
                    task: task,
                    showCompact: false,
                  ),
                  
                  // Subtasks
                  const SizedBox(height: 24),
                  SubtaskWidget(
                    task: task,
                    showCompact: false,
                  ),
                  
                  // Comments & Activity
                  const SizedBox(height: 24),
                  CommentWidget(
                    task: task,
                    showCompact: false,
                  ),
                  
                  // Tags
                  if (task.tags.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: task.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.gray600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.lowest:
        return 'Lowest';
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.critical:
        return 'Critical';
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

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.lowest:
      case TaskPriority.low:
        return Icons.keyboard_arrow_down;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.high:
      case TaskPriority.critical:
        return Icons.keyboard_arrow_up;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}