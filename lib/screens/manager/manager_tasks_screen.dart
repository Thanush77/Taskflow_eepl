import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/manager_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_display.dart';
import '../../utils/responsive_utils.dart';
import '../../constants/app_colors.dart';
import '../../models/manager_models.dart';

class ManagerTasksScreen extends ConsumerStatefulWidget {
  const ManagerTasksScreen({super.key});

  @override
  ConsumerState<ManagerTasksScreen> createState() => _ManagerTasksScreenState();
}

class _ManagerTasksScreenState extends ConsumerState<ManagerTasksScreen> {
  String? _selectedStatus;
  String? _selectedPriority;
  int? _selectedAssignee;
  String _searchQuery = '';
  String _sortBy = 'created_at';
  String _sortOrder = 'DESC';
  int _currentPage = 1;
  final int _pageSize = 20;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadTasks() {
    ref.read(managerTasksProvider.notifier).loadTasks(
      status: _selectedStatus,
      priority: _selectedPriority,
      assignedTo: _selectedAssignee,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      page: _currentPage,
      limit: _pageSize,
      sort: _sortBy,
      order: _sortOrder,
    );
  }

  void _applyFilters() {
    setState(() {
      _currentPage = 1;
    });
    _loadTasks();
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedPriority = null;
      _selectedAssignee = null;
      _searchQuery = '';
      _searchController.clear();
      _currentPage = 1;
    });
    _loadTasks();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildSortBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(managerTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Manage Tasks',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showSortBottomSheet,
            icon: const Icon(Icons.sort, color: AppColors.white),
          ),
          IconButton(
            onPressed: _showFilterBottomSheet,
            icon: const Icon(Icons.filter_list, color: AppColors.white),
          ),
          IconButton(
            onPressed: () => _loadTasks(),
            icon: const Icon(Icons.refresh, color: AppColors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadTasks(),
              child: _buildTasksList(tasksState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
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
                        _applyFilters();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            onSubmitted: (value) => _applyFilters(),
          ),
          const SizedBox(height: 12),
          // Active filters
          if (_hasActiveFilters()) _buildActiveFilters(),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedStatus != null ||
           _selectedPriority != null ||
           _selectedAssignee != null ||
           _searchQuery.isNotEmpty;
  }

  Widget _buildActiveFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Active Filters:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const Spacer(),
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear All', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (_selectedStatus != null)
              _buildFilterChip('Status: $_selectedStatus', () {
                setState(() => _selectedStatus = null);
                _applyFilters();
              }),
            if (_selectedPriority != null)
              _buildFilterChip('Priority: $_selectedPriority', () {
                setState(() => _selectedPriority = null);
                _applyFilters();
              }),
            if (_selectedAssignee != null)
              _buildFilterChip('Assignee: User $_selectedAssignee', () {
                setState(() => _selectedAssignee = null);
                _applyFilters();
              }),
            if (_searchQuery.isNotEmpty)
              _buildFilterChip('Search: "$_searchQuery"', () {
                _searchController.clear();
                setState(() => _searchQuery = '');
                _applyFilters();
              }),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: AppColors.primary.withOpacity(0.1),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildTasksList(dynamic tasksState) {
    if (tasksState.isLoading && tasksState.data == null) {
      return const Center(child: LoadingWidget(color: AppColors.primary));
    }

    if (tasksState.error != null && tasksState.data == null) {
      return ErrorDisplay(
        message: tasksState.error!,
        onRetry: () => _loadTasks(),
      );
    }

    if (tasksState.data == null || tasksState.data!.tasks.isEmpty) {
      return const Center(
        child: Text(
          'No tasks found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final tasks = tasksState.data!.tasks;
    final pagination = tasksState.data!.pagination;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
          ),
        ),
        _buildPagination(pagination),
      ],
    );
  }

  Widget _buildTaskCard(ManagerTaskDetailed task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTaskDetails(task),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _buildPriorityBadge(task.priority),
                ],
              ),
              if (task.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  style: const TextStyle(color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatusBadge(task.status),
                  const SizedBox(width: 12),
                  if (task.assignedToName != null)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              task.assignedToName!,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (task.dueDate != null)
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(task.dueDate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: task.dueDate!.isBefore(DateTime.now()) 
                                ? Colors.red 
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority.toLowerCase()) {
      case 'critical':
        color = Colors.red;
        break;
      case 'high':
        color = Colors.orange;
        break;
      case 'medium':
        color = Colors.blue;
        break;
      case 'low':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'in_progress':
        color = Colors.blue;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPagination(TasksPagination pagination) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${pagination.page} of ${pagination.totalPages}',
            style: const TextStyle(fontSize: 14),
          ),
          Row(
            children: [
              IconButton(
                onPressed: pagination.page > 1 ? () {
                  setState(() => _currentPage = pagination.page - 1);
                  _loadTasks();
                } : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: pagination.page < pagination.totalPages ? () {
                  setState(() => _currentPage = pagination.page + 1);
                  _loadTasks();
                } : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Tasks',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // Status filter
          const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['pending', 'in_progress', 'completed'].map((status) {
              return FilterChip(
                label: Text(status.replaceAll('_', ' ').toUpperCase()),
                selected: _selectedStatus == status,
                onSelected: (selected) {
                  setState(() {
                    _selectedStatus = selected ? status : null;
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Priority filter
          const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['critical', 'high', 'medium', 'low'].map((priority) {
              return FilterChip(
                label: Text(priority.toUpperCase()),
                selected: _selectedPriority == priority,
                onSelected: (selected) {
                  setState(() {
                    _selectedPriority = selected ? priority : null;
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _clearFilters();
                  },
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildSortBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sort Tasks',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          const Text('Sort by', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Column(
            children: [
              RadioListTile<String>(
                title: const Text('Created Date'),
                value: 'created_at',
                groupValue: _sortBy,
                onChanged: (value) => setState(() => _sortBy = value!),
              ),
              RadioListTile<String>(
                title: const Text('Due Date'),
                value: 'due_date',
                groupValue: _sortBy,
                onChanged: (value) => setState(() => _sortBy = value!),
              ),
              RadioListTile<String>(
                title: const Text('Priority'),
                value: 'priority',
                groupValue: _sortBy,
                onChanged: (value) => setState(() => _sortBy = value!),
              ),
              RadioListTile<String>(
                title: const Text('Status'),
                value: 'status',
                groupValue: _sortBy,
                onChanged: (value) => setState(() => _sortBy = value!),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          const Text('Order', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Descending'),
                  value: 'DESC',
                  groupValue: _sortOrder,
                  onChanged: (value) => setState(() => _sortOrder = value!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Ascending'),
                  value: 'ASC',
                  groupValue: _sortOrder,
                  onChanged: (value) => setState(() => _sortOrder = value!),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applyFilters();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskDetails(ManagerTaskDetailed task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null) ...[
              Text(task.description!),
              const SizedBox(height: 16),
            ],
            _buildDetailRow('Status', task.status),
            _buildDetailRow('Priority', task.priority),
            if (task.assignedToName != null)
              _buildDetailRow('Assigned to', task.assignedToName!),
            if (task.createdByName != null)
              _buildDetailRow('Created by', task.createdByName!),
            if (task.dueDate != null)
              _buildDetailRow('Due date', _formatDate(task.dueDate!)),
            if (task.estimatedHours != null)
              _buildDetailRow('Estimated hours', '${task.estimatedHours} hrs'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showAssignDialog(task);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Reassign'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showAssignDialog(ManagerTaskDetailed task) {
    // Implementation for reassigning tasks
    // This would show a dialog with employee selection
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reassign Task'),
        content: const Text('Task reassignment feature would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}