import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/task.dart';
import '../../models/recurring_task.dart';
import '../../providers/recurring_task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/team_provider.dart';

class RecurringTaskFormScreen extends ConsumerStatefulWidget {
  final RecurringTask? recurringTask;

  const RecurringTaskFormScreen({this.recurringTask, super.key});

  @override
  ConsumerState<RecurringTaskFormScreen> createState() => _RecurringTaskFormScreenState();
}

class _RecurringTaskFormScreenState extends ConsumerState<RecurringTaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedHoursController = TextEditingController();
  final _tagsController = TextEditingController();
  
  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskCategory _selectedCategory = TaskCategory.general;
  RecurrenceType _selectedRecurrenceType = RecurrenceType.daily;
  int _recurrenceInterval = 1;
  List<RecurrenceDay> _selectedDaysOfWeek = [];
  int? _selectedDayOfMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _maxOccurrences;
  int? _selectedAssignee;
  List<String> _tags = [];
  
  bool _isLoading = false;
  bool get _isEditMode => widget.recurringTask != null;
  bool _hasEndDate = false;
  bool _hasMaxOccurrences = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (_isEditMode) {
      final rt = widget.recurringTask!;
      _titleController.text = rt.title;
      _descriptionController.text = rt.description ?? '';
      _estimatedHoursController.text = rt.estimatedHours.toString();
      _selectedPriority = rt.priority;
      _selectedCategory = rt.category;
      _selectedRecurrenceType = rt.recurrencePattern.type;
      _recurrenceInterval = rt.recurrencePattern.interval;
      _selectedDaysOfWeek = List.from(rt.recurrencePattern.daysOfWeek);
      _selectedDayOfMonth = rt.recurrencePattern.dayOfMonth;
      _startDate = rt.startDate;
      _endDate = rt.recurrencePattern.endDate;
      _maxOccurrences = rt.recurrencePattern.maxOccurrences;
      _selectedAssignee = rt.assignedTo;
      _tags = List.from(rt.tags);
      _tagsController.text = _tags.join(', ');
      _hasEndDate = _endDate != null;
      _hasMaxOccurrences = _maxOccurrences != null;
    } else {
      _estimatedHoursController.text = '1.0';
      _startDate = DateTime.now().add(const Duration(days: 1));
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
        title: Text(_isEditMode ? 'Edit Recurring Task' : 'Create Recurring Task'),
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
                      hintText: 'Enter a descriptive title',
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
                      hintText: 'Provide additional details',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    maxLines: 3,
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
                              child: Text(_getPriorityText(priority)),
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
                  
                  TextFormField(
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
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Recurrence Settings Card
              _buildCard(
                title: 'Recurrence Settings',
                icon: Icons.repeat_outlined,
                children: [
                  DropdownButtonFormField<RecurrenceType>(
                    value: _selectedRecurrenceType,
                    decoration: const InputDecoration(
                      labelText: 'Recurrence Type',
                      prefixIcon: Icon(Icons.schedule_outlined),
                    ),
                    items: RecurrenceType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getRecurrenceTypeText(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRecurrenceType = value!;
                        _selectedDaysOfWeek.clear();
                        _selectedDayOfMonth = null;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Interval
                  TextFormField(
                    initialValue: _recurrenceInterval.toString(),
                    decoration: InputDecoration(
                      labelText: 'Every ${_getIntervalUnit()}',
                      prefixIcon: const Icon(Icons.numbers_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _recurrenceInterval = int.tryParse(value) ?? 1;
                    },
                    validator: (value) {
                      final interval = int.tryParse(value ?? '');
                      if (interval == null || interval < 1) {
                        return 'Please enter a valid interval (1 or more)';
                      }
                      return null;
                    },
                  ),
                  
                  // Weekly days selection
                  if (_selectedRecurrenceType == RecurrenceType.weekly) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Days of the week:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: RecurrenceDay.values.map((day) {
                        final isSelected = _selectedDaysOfWeek.contains(day);
                        return FilterChip(
                          label: Text(_getDayName(day)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedDaysOfWeek.add(day);
                              } else {
                                _selectedDaysOfWeek.remove(day);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  
                  // Monthly day selection
                  if (_selectedRecurrenceType == RecurrenceType.monthly) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int?>(
                      value: _selectedDayOfMonth,
                      decoration: const InputDecoration(
                        labelText: 'Day of Month',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Same as start date'),
                        ),
                        ...List.generate(31, (index) => index + 1).map((day) {
                          return DropdownMenuItem(
                            value: day,
                            child: Text('Day $day'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDayOfMonth = value;
                        });
                      },
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Schedule Card
              _buildCard(
                title: 'Schedule & Assignment',
                icon: Icons.event_outlined,
                children: [
                  // Start date
                  InkWell(
                    onTap: _selectStartDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date *',
                        prefixIcon: Icon(Icons.play_arrow_outlined),
                      ),
                      child: Text(
                        _startDate != null
                            ? _formatDate(_startDate!)
                            : 'Select start date',
                        style: TextStyle(
                          color: _startDate != null ? null : AppColors.gray500,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // End date option
                  CheckboxListTile(
                    title: const Text('Set end date'),
                    value: _hasEndDate,
                    onChanged: (value) {
                      setState(() {
                        _hasEndDate = value ?? false;
                        if (!_hasEndDate) _endDate = null;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  if (_hasEndDate) ...[
                    InkWell(
                      onTap: _selectEndDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          prefixIcon: Icon(Icons.stop_outlined),
                        ),
                        child: Text(
                          _endDate != null
                              ? _formatDate(_endDate!)
                              : 'Select end date',
                          style: TextStyle(
                            color: _endDate != null ? null : AppColors.gray500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Max occurrences option
                  CheckboxListTile(
                    title: const Text('Limit number of occurrences'),
                    value: _hasMaxOccurrences,
                    onChanged: (value) {
                      setState(() {
                        _hasMaxOccurrences = value ?? false;
                        if (!_hasMaxOccurrences) _maxOccurrences = null;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  if (_hasMaxOccurrences) ...[
                    TextFormField(
                      initialValue: _maxOccurrences?.toString() ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Maximum Occurrences',
                        prefixIcon: Icon(Icons.repeat_one_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _maxOccurrences = int.tryParse(value);
                      },
                      validator: _hasMaxOccurrences ? (value) {
                        final occurrences = int.tryParse(value ?? '');
                        if (occurrences == null || occurrences < 1) {
                          return 'Please enter a valid number of occurrences';
                        }
                        return null;
                      } : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Assignment
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
                          child: Text('${authState.user!.fullName} (Me)'),
                        ),
                      ...teamState.users.where((user) => user.id != authState.user?.id).map((user) {
                        return DropdownMenuItem<int?>(
                          value: user.id,
                          child: Text(user.fullName),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedAssignee = value;
                      });
                    },
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
                      hintText: 'e.g., weekly, maintenance, review',
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
                          backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
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
                  _isEditMode ? 'Update Recurring Task' : 'Create Recurring Task',
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
            color: Colors.black.withValues(alpha: 0.05),
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

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate?.add(const Duration(days: 30)) ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a start date'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    if (_selectedRecurrenceType == RecurrenceType.weekly && _selectedDaysOfWeek.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day of the week'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final recurrencePattern = RecurrencePattern(
        type: _selectedRecurrenceType,
        interval: _recurrenceInterval,
        daysOfWeek: _selectedDaysOfWeek,
        dayOfMonth: _selectedDayOfMonth,
        endDate: _endDate,
        maxOccurrences: _maxOccurrences,
      );

      final recurringTask = RecurringTask(
        id: _isEditMode ? widget.recurringTask!.id : null,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        category: _selectedCategory,
        estimatedHours: double.parse(_estimatedHoursController.text),
        recurrencePattern: recurrencePattern,
        startDate: _startDate!,
        assignedTo: _selectedAssignee,
        tags: _tags,
        createdBy: ref.read(authProvider).user!.id,
        createdAt: _isEditMode ? widget.recurringTask!.createdAt : DateTime.now(),
      );

      bool success;
      if (_isEditMode) {
        success = await ref.read(recurringTaskProvider.notifier).updateRecurringTask(
          recurringTask.id!,
          recurringTask.toJson(),
        );
      } else {
        success = await ref.read(recurringTaskProvider.notifier).createRecurringTask(recurringTask);
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? 'Recurring task updated successfully' : 'Recurring task created successfully',
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

  String _getRecurrenceTypeText(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.yearly:
        return 'Yearly';
      case RecurrenceType.custom:
        return 'Custom';
    }
  }

  String _getIntervalUnit() {
    switch (_selectedRecurrenceType) {
      case RecurrenceType.daily:
        return 'day(s)';
      case RecurrenceType.weekly:
        return 'week(s)';
      case RecurrenceType.monthly:
        return 'month(s)';
      case RecurrenceType.yearly:
        return 'year(s)';
      case RecurrenceType.custom:
        return 'period(s)';
    }
  }

  String _getDayName(RecurrenceDay day) {
    switch (day) {
      case RecurrenceDay.monday:
        return 'Mon';
      case RecurrenceDay.tuesday:
        return 'Tue';
      case RecurrenceDay.wednesday:
        return 'Wed';
      case RecurrenceDay.thursday:
        return 'Thu';
      case RecurrenceDay.friday:
        return 'Fri';
      case RecurrenceDay.saturday:
        return 'Sat';
      case RecurrenceDay.sunday:
        return 'Sun';
    }
  }
}