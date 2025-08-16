import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final Task? task;
  final TaskStatus? defaultStatus;

  const TaskFormScreen({this.task, this.defaultStatus, super.key});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedHoursController = TextEditingController();
  final _tagsController = TextEditingController();
  
  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskCategory _selectedCategory = TaskCategory.general;
  TaskStatus _selectedStatus = TaskStatus.pending;
  DateTime? _selectedDueDate;
  int? _selectedAssignee;
  List<String> _tags = [];
  
  bool _isLoading = false;
  bool get _isEditMode => widget.task != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (_isEditMode) {
      final task = widget.task!;
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _estimatedHoursController.text = task.estimatedHours.toString();
      _selectedPriority = task.priority;
      _selectedCategory = task.category;
      _selectedStatus = task.status;
      _selectedDueDate = task.dueDate;
      _selectedAssignee = task.assignedTo;
      _tags = List.from(task.tags);
      _tagsController.text = _tags.join(', ');
    } else {
      _estimatedHoursController.text = '1.0';
      // Set default status if provided
      if (widget.defaultStatus != null) {
        _selectedStatus = widget.defaultStatus!;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedHoursController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamState = ref.watch(teamProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Task' : 'Create Task'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Information Card
              _buildCard(
                title: 'Basic Information',
                icon: Icons.info_outline,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Title *',
                      hintText: 'Enter a descriptive title for your task',
                      prefixIcon: Icon(Icons.title_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a task title';
                      }
                      return null;
                    },
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Provide additional details about the task',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    maxLines: 4,
                    maxLength: 500,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Task Settings Card
              _buildCard(
                title: 'Task Settings',
                icon: Icons.settings_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<TaskPriority>(
                          value: _selectedPriority,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                          items: TaskPriority.values.map((priority) {
                            return DropdownMenuItem(
                              value: priority,
                              child: Row(
                                children: [
                                  Icon(
                                    _getPriorityIcon(priority),
                                    color: _getPriorityColor(priority),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_getPriorityText(priority)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPriority = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<TaskCategory>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: TaskCategory.values.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(_getCategoryText(category)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      if (_isEditMode)
                        Expanded(
                          child: DropdownButtonFormField<TaskStatus>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              prefixIcon: Icon(Icons.track_changes_outlined),
                            ),
                            items: TaskStatus.values.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(_getStatusText(status)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value!;
                              });
                            },
                          ),
                        ),
                      if (_isEditMode) const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _estimatedHoursController,
                          decoration: const InputDecoration(
                            labelText: 'Estimated Hours',
                            prefixIcon: Icon(Icons.access_time_outlined),
                            suffixText: 'hrs',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter estimated hours';
                            }
                            final hours = double.tryParse(value);
                            if (hours == null || hours <= 0) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Assignment & Scheduling Card
              _buildCard(
                title: 'Assignment & Scheduling',
                icon: Icons.schedule_outlined,
                children: [
                  DropdownButtonFormField<int?>(
                    value: _selectedAssignee,
                    decoration: const InputDecoration(
                      labelText: 'Assign to',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      if (authState.user != null)
                        DropdownMenuItem<int?>(
                          value: authState.user!.id,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                                child: Text(
                                  authState.user!.initials,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${authState.user!.fullName} (Me)'),
                            ],
                          ),
                        ),
                      ...teamState.users.where((user) => user.id != authState.user?.id).map((user) {
                        return DropdownMenuItem<int?>(
                          value: user.id,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: AppColors.gray200,
                                child: Text(
                                  user.initials,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gray700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(user.fullName),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedAssignee = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  InkWell(
                    onTap: _selectDueDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                        suffixIcon: Icon(Icons.edit_calendar_outlined),
                      ),
                      child: Text(
                        _selectedDueDate != null
                            ? _formatDate(_selectedDueDate!)
                            : 'No due date set',
                        style: TextStyle(
                          color: _selectedDueDate != null ? null : AppColors.gray500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Tags Card
              _buildCard(
                title: 'Tags',
                icon: Icons.local_offer_outlined,
                children: [
                  TextFormField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags (comma-separated)',
                      hintText: 'e.g., frontend, urgent, bug-fix',
                      prefixIcon: Icon(Icons.tag_outlined),
                    ),
                    onChanged: (value) {
                      _tags = value.split(',')
                          .map((tag) => tag.trim())
                          .where((tag) => tag.isNotEmpty)
                          .toList();
                    },
                  ),
                  
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                          labelStyle: const TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 12,
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() {
                              _tags.remove(tag);
                              _tagsController.text = _tags.join(', ');
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isEditMode ? 'Update Task' : 'Create Task',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDueDate = date;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final task = Task(
        id: _isEditMode ? widget.task!.id : null,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        category: _selectedCategory,
        status: _selectedStatus,
        assignedTo: _selectedAssignee,
        estimatedHours: double.parse(_estimatedHoursController.text),
        dueDate: _selectedDueDate,
        tags: _tags,
        createdAt: _isEditMode ? widget.task!.createdAt : DateTime.now(),
      );

      bool success;
      if (_isEditMode) {
        success = await ref.read(taskProvider.notifier).updateTask(
          task.id!,
          {
            'title': task.title,
            'description': task.description,
            'priority': task.priority.name,
            'category': task.category.name,
            'status': task.status.name,
            'assignedTo': task.assignedTo,
            'estimatedHours': task.estimatedHours,
            'dueDate': task.dueDate?.toIso8601String(),
            'tags': task.tags,
          },
        );
      } else {
        success = await ref.read(taskProvider.notifier).createTask(task);
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? 'Task updated successfully' : 'Task created successfully',
            ),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
}