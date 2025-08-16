import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/task.dart';
import '../../models/recurring_task.dart';
import '../../providers/recurring_task_provider.dart';
import '../../widgets/loading_widget.dart';
import 'recurring_task_form_screen.dart';

class RecurringTasksScreen extends ConsumerStatefulWidget {
  const RecurringTasksScreen({super.key});

  @override
  ConsumerState<RecurringTasksScreen> createState() => _RecurringTasksScreenState();
}

class _RecurringTasksScreenState extends ConsumerState<RecurringTasksScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load recurring tasks on init
    Future.microtask(() {
      ref.read(recurringTaskProvider.notifier).loadRecurringTasks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recurringTaskState = ref.watch(recurringTaskProvider);

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
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.repeat, color: AppColors.primaryColor, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Recurring Tasks',
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
                          onPressed: () async {
                            await ref.read(recurringTaskProvider.notifier).generateRecurringTasks();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Generated due recurring tasks'),
                                  backgroundColor: AppColors.successColor,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.refresh, color: AppColors.primaryColor),
                          tooltip: 'Generate Due Tasks',
                        ),
                        IconButton(
                          onPressed: () {
                            ref.read(recurringTaskProvider.notifier).refresh();
                          },
                          icon: const Icon(Icons.sync, color: AppColors.primaryColor),
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Status tabs
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryColor,
                  unselectedLabelColor: AppColors.gray600,
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
                  ),
                  tabs: [
                    Tab(text: 'Active (${recurringTaskState.activeRecurringTasks.length})'),
                    Tab(text: 'Due (${recurringTaskState.dueRecurringTasks.length})'),
                    Tab(text: 'Paused (${recurringTaskState.pausedRecurringTasks.length})'),
                    Tab(text: 'Completed (${recurringTaskState.completedRecurringTasks.length})'),
                  ],
                ),
              ],
            ),
          ),
          
          // Task lists
          Expanded(
            child: recurringTaskState.isLoading && recurringTaskState.recurringTasks.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LoadingWidget(),
                        SizedBox(height: 16),
                        Text('Loading recurring tasks...', style: TextStyle(color: AppColors.gray600)),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTaskList(recurringTaskState.activeRecurringTasks, 'active'),
                      _buildTaskList(recurringTaskState.dueRecurringTasks, 'due'),
                      _buildTaskList(recurringTaskState.pausedRecurringTasks, 'paused'),
                      _buildTaskList(recurringTaskState.completedRecurringTasks, 'completed'),
                    ],
                  ),
          ),
        ],
      ),
      
      // Floating action button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const RecurringTaskFormScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Recurring Task'),
      ),
    );
  }

  Widget _buildTaskList(List<RecurringTask> tasks, String type) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyIcon(type),
              size: 64,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyTitle(type),
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.gray600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptySubtitle(type),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(recurringTaskProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final recurringTask = tasks[index];
          return RecurringTaskCard(
            recurringTask: recurringTask,
            onTap: () => _showTaskDetails(recurringTask),
            onEdit: () => _editTask(recurringTask),
            onDelete: () => _deleteTask(recurringTask),
            onToggleStatus: () => _toggleTaskStatus(recurringTask),
            onGenerate: recurringTask.isDue ? () => _generateTasks() : null,
          );
        },
      ),
    );
  }

  IconData _getEmptyIcon(String type) {
    switch (type) {
      case 'active':
        return Icons.repeat_outlined;
      case 'due':
        return Icons.alarm_outlined;
      case 'paused':
        return Icons.pause_circle_outline;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.inbox_outlined;
    }
  }

  String _getEmptyTitle(String type) {
    switch (type) {
      case 'active':
        return 'No active recurring tasks';
      case 'due':
        return 'No tasks due for generation';
      case 'paused':
        return 'No paused recurring tasks';
      case 'completed':
        return 'No completed recurring tasks';
      default:
        return 'No recurring tasks';
    }
  }

  String _getEmptySubtitle(String type) {
    switch (type) {
      case 'active':
        return 'Create a recurring task to get started';
      case 'due':
        return 'Check back later for tasks to generate';
      case 'paused':
        return 'Paused tasks will appear here';
      case 'completed':
        return 'Completed recurring tasks will appear here';
      default:
        return 'Create your first recurring task';
    }
  }

  void _showTaskDetails(RecurringTask recurringTask) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecurringTaskDetailsBottomSheet(recurringTask: recurringTask),
    );
  }

  void _editTask(RecurringTask recurringTask) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecurringTaskFormScreen(recurringTask: recurringTask),
      ),
    );
  }

  Future<void> _deleteTask(RecurringTask recurringTask) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recurring Task'),
        content: Text('Are you sure you want to delete "${recurringTask.title}"? This will also stop all future task generation.'),
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
      final success = await ref.read(recurringTaskProvider.notifier).deleteRecurringTask(recurringTask.id!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recurring task deleted successfully')),
        );
      }
    }
  }

  Future<void> _toggleTaskStatus(RecurringTask recurringTask) async {
    final success = await ref.read(recurringTaskProvider.notifier).toggleRecurringTaskStatus(recurringTask.id!);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            recurringTask.isActive 
                ? 'Recurring task paused' 
                : 'Recurring task activated'
          ),
        ),
      );
    }
  }

  Future<void> _generateTasks() async {
    final success = await ref.read(recurringTaskProvider.notifier).generateRecurringTasks();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generated due recurring tasks'),
          backgroundColor: AppColors.successColor,
        ),
      );
    }
  }
}

class RecurringTaskCard extends StatelessWidget {
  final RecurringTask recurringTask;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;
  final VoidCallback? onGenerate;

  const RecurringTaskCard({
    required this.recurringTask,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    this.onGenerate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        border: Border(
          left: BorderSide(
            color: _getStatusColor(),
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
                      recurringTask.title,
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
                    onSelected: _handleMenuAction,
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
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              recurringTask.isActive ? Icons.pause : Icons.play_arrow,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(recurringTask.isActive ? 'Pause' : 'Activate'),
                          ],
                        ),
                      ),
                      if (onGenerate != null)
                        const PopupMenuItem(
                          value: 'generate',
                          child: Row(
                            children: [
                              Icon(Icons.add_task, size: 16),
                              SizedBox(width: 8),
                              Text('Generate Now'),
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
              if (recurringTask.description?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  recurringTask.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.gray600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Recurrence info
              Row(
                children: [
                  Icon(
                    Icons.repeat,
                    size: 16,
                    color: _getStatusColor(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    recurringTask.recurrencePattern.displayText,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppColors.gray500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    recurringTask.nextDue != null 
                        ? 'Next: ${_formatDate(recurringTask.nextDue!)}'
                        : 'No next date',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Status and stats
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      recurringTask.statusText,
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Text(
                    'Generated: ${recurringTask.generatedCount}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray600,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Priority indicator
                  Icon(
                    _getPriorityIcon(),
                    color: _getPriorityColor(),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        onEdit();
        break;
      case 'toggle':
        onToggleStatus();
        break;
      case 'generate':
        onGenerate?.call();
        break;
      case 'delete':
        onDelete();
        break;
    }
  }

  Color _getStatusColor() {
    if (!recurringTask.isActive) return Colors.orange;
    if (recurringTask.shouldStop) return Colors.grey;
    if (recurringTask.isDue) return Colors.red;
    return Colors.green;
  }

  IconData _getPriorityIcon() {
    switch (recurringTask.priority) {
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

  Color _getPriorityColor() {
    switch (recurringTask.priority) {
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays <= 7) {
      return 'In ${difference.inDays}d';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class RecurringTaskDetailsBottomSheet extends ConsumerWidget {
  final RecurringTask recurringTask;

  const RecurringTaskDetailsBottomSheet({required this.recurringTask, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingInstances = ref.read(recurringTaskProvider.notifier)
        .previewUpcomingInstances(recurringTask, count: 5);

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
                  // Title and status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recurringTask.title,
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
                          color: _getStatusColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          recurringTask.statusText,
                          style: TextStyle(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  if (recurringTask.description?.isNotEmpty == true) ...[
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
                      recurringTask.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gray700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Recurrence details
                  const Text(
                    'Recurrence Pattern',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recurringTask.recurrencePattern.displayText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.gray900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Started: ${_formatDate(recurringTask.startDate)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.gray600,
                          ),
                        ),
                        if (recurringTask.recurrencePattern.endDate != null) ...[
                          Text(
                            'Ends: ${_formatDate(recurringTask.recurrencePattern.endDate!)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                        if (recurringTask.recurrencePattern.maxOccurrences != null) ...[
                          Text(
                            'Max occurrences: ${recurringTask.recurrencePattern.maxOccurrences}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Statistics
                  const Text(
                    'Statistics',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Generated',
                          recurringTask.generatedCount.toString(),
                          Icons.task_alt,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatItem(
                          'Estimated Hours',
                          '${recurringTask.estimatedHours}h',
                          Icons.access_time,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Upcoming instances
                  if (upcomingInstances.isNotEmpty) ...[
                    const Text(
                      'Upcoming Instances',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...upcomingInstances.take(5).map((date) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_outlined,
                            size: 16,
                            color: AppColors.gray600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(date),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.gray700,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.primaryColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (!recurringTask.isActive) return Colors.orange;
    if (recurringTask.shouldStop) return Colors.grey;
    if (recurringTask.isDue) return Colors.red;
    return Colors.green;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}