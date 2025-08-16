import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/task_card.dart';
import 'task_form_screen.dart';

class KanbanBoardScreen extends ConsumerStatefulWidget {
  const KanbanBoardScreen({super.key});

  @override
  ConsumerState<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends ConsumerState<KanbanBoardScreen> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    // Load tasks on init
    Future.microtask(() {
      ref.read(taskProvider.notifier).loadTasks();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskProvider);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.white,
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
                const Icon(Icons.view_kanban, color: AppColors.primaryColor, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Kanban Board',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    ref.read(taskProvider.notifier).refresh();
                  },
                  icon: const Icon(Icons.refresh, color: AppColors.primaryColor),
                  tooltip: 'Refresh',
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TaskFormScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Task'),
                ),
              ],
            ),
          ),
          
          // Kanban Board
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
                : _buildKanbanBoard(taskState.tasks),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanBoard(List<Task> tasks) {
    final columns = _getKanbanColumns(tasks);
    
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...columns.map((column) => _buildKanbanColumn(column)),
          _buildAddColumnButton(),
        ],
      ),
    );
  }

  List<KanbanColumn> _getKanbanColumns(List<Task> tasks) {
    return [
      KanbanColumn(
        id: 'pending',
        title: 'To Do',
        status: TaskStatus.pending,
        color: Colors.orange,
        icon: Icons.pending_outlined,
        tasks: tasks.where((t) => t.status == TaskStatus.pending).toList(),
      ),
      KanbanColumn(
        id: 'in-progress',
        title: 'In Progress',
        status: TaskStatus.inProgress,
        color: Colors.blue,
        icon: Icons.work_outline,
        tasks: tasks.where((t) => t.status == TaskStatus.inProgress).toList(),
      ),
      KanbanColumn(
        id: 'review',
        title: 'Review',
        status: TaskStatus.inProgress, // Temporarily use inProgress for review
        color: Colors.purple,
        icon: Icons.rate_review_outlined,
        tasks: [], // We'll implement this later with subtasks
      ),
      KanbanColumn(
        id: 'completed',
        title: 'Done',
        status: TaskStatus.completed,
        color: Colors.green,
        icon: Icons.check_circle_outline,
        tasks: tasks.where((t) => t.status == TaskStatus.completed).toList(),
      ),
    ];
  }

  Widget _buildKanbanColumn(KanbanColumn column) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
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
      ),
      child: Column(
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: column.color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  column.icon,
                  color: column.color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    column.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: column.color,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: column.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    column.tasks.length.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: column.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Column Tasks
          Expanded(
            child: DragTarget<Task>(
              onWillAccept: (task) => task != null && task.status != column.status,
              onAccept: (task) => _moveTask(task, column.status),
              builder: (context, candidateData, rejectedData) {
                return Container(
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty 
                        ? column.color.withOpacity(0.05)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: column.tasks.length + 1,
                    itemBuilder: (context, index) {
                      if (index == column.tasks.length) {
                        return _buildAddTaskButton(column);
                      }
                      
                      final task = column.tasks[index];
                      return _buildDraggableTaskCard(task);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableTaskCard(Task task) {
    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 280,
          child: TaskCard(
            task: task,
            onTap: () {},
            onEdit: () {},
            onDelete: () {},
            onStatusChange: (status) {},
          ),
        ),
      ),
      childWhenDragging: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.gray100.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray300, width: 2),
        ),
        child: const SizedBox(height: 80),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: TaskCard(
          task: task,
          onTap: () => _showTaskDetails(task),
          onEdit: () => _editTask(task),
          onDelete: () => _deleteTask(task),
          onStatusChange: (status) => _moveTask(task, status),
        ),
      ),
    );
  }

  Widget _buildAddTaskButton(KanbanColumn column) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () => _addTaskToColumn(column),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.gray300,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.add,
                color: AppColors.gray500,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Add task',
                style: TextStyle(
                  color: AppColors.gray500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddColumnButton() {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: _addColumn,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.gray300,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: AppColors.gray400,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Add Column',
                style: TextStyle(
                  color: AppColors.gray500,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _moveTask(Task task, TaskStatus newStatus) async {
    if (task.status == newStatus) return;
    
    // Optimistically update the UI
    await ref.read(taskProvider.notifier).updateTask(
      task.id!,
      {'status': newStatus.name.replaceAll('inProgress', 'in-progress')},
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task moved to ${_getStatusDisplayName(newStatus)}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _getStatusDisplayName(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Done';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
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

  void _addTaskToColumn(KanbanColumn column) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(
          defaultStatus: column.status,
        ),
      ),
    );
  }

  void _addColumn() {
    // Future implementation: Allow users to create custom columns
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Custom columns feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// Kanban Column Model
class KanbanColumn {
  final String id;
  final String title;
  final TaskStatus status;
  final Color color;
  final IconData icon;
  final List<Task> tasks;

  KanbanColumn({
    required this.id,
    required this.title,
    required this.status,
    required this.color,
    required this.icon,
    required this.tasks,
  });
}

// Import TaskDetailsBottomSheet from tasks_screen.dart
class TaskDetailsBottomSheet extends StatelessWidget {
  final Task task;

  const TaskDetailsBottomSheet({required this.task, super.key});

  @override
  Widget build(BuildContext context) {
    // This is a placeholder - in a real implementation, you'd import from tasks_screen.dart
    return Container(
      height: 400,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Center(
        child: Text('Task Details: ${task.title}'),
      ),
    );
  }
}