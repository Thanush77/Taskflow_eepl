import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../constants/app_colors.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../widgets/loading_widget.dart';
import 'task_form_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late final ValueNotifier<List<Task>> _selectedTasks;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  
  final ScrollController _taskListController = ScrollController();
  String _selectedFilter = 'all'; // all, assigned, created, due

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedTasks = ValueNotifier(_getTasksForDay(_selectedDay!));
    
    // Load tasks on init
    Future.microtask(() {
      ref.read(taskProvider.notifier).loadTasks();
      ref.read(teamProvider.notifier).loadUsers();
    });
  }

  @override
  void dispose() {
    _selectedTasks.dispose();
    _taskListController.dispose();
    super.dispose();
  }

  List<Task> _getTasksForDay(DateTime day) {
    final taskState = ref.read(taskProvider);
    print('🔍 Calendar - _getTasksForDay: ${taskState.tasks.length} total tasks for ${day.toIso8601String().split('T')[0]}');
    final filteredTasks = taskState.tasks.where((task) {
      if (_selectedFilter == 'due' && task.dueDate != null) {
        return isSameDay(task.dueDate!, day);
      }
      if (_selectedFilter == 'assigned' && task.assignedAt != null) {
        return isSameDay(task.assignedAt!, day);
      }
      if (_selectedFilter == 'created' && task.createdAt != null) {
        return isSameDay(task.createdAt!, day);
      }
      // For 'all', show tasks that have any date relationship with this day
      return (task.dueDate != null && isSameDay(task.dueDate!, day)) ||
             (task.assignedAt != null && isSameDay(task.assignedAt!, day)) ||
             (task.createdAt != null && isSameDay(task.createdAt!, day)) ||
             (task.startDate != null && isSameDay(task.startDate!, day));
    }).toList();
    
    // Debug logging for calendar filtering
    print('🔍 Calendar - Total tasks: ${taskState.tasks.length}');
    print('🔍 Calendar - Filtered tasks for ${day.day}/${day.month}: ${filteredTasks.length}');
    print('🔍 Calendar - Filter: $_selectedFilter');
    
    return filteredTasks;
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskProvider);

    // Update selected tasks when task state changes
    if (_selectedDay != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final updatedTasks = _getTasksForDay(_selectedDay!);
        if (_selectedTasks.value.length != updatedTasks.length) {
          _selectedTasks.value = updatedTasks;
        }
      });
    }

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
                    const Icon(Icons.calendar_today, color: AppColors.primaryColor, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Calendar',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        // View format toggle
                        IconButton(
                          onPressed: _toggleCalendarFormat,
                          icon: Icon(
                            _calendarFormat == CalendarFormat.month 
                                ? Icons.view_week 
                                : Icons.calendar_view_month,
                            color: AppColors.primaryColor,
                          ),
                          tooltip: _calendarFormat == CalendarFormat.month 
                              ? 'Week View' 
                              : 'Month View',
                        ),
                        // Filter dropdown
                        PopupMenuButton<String>(
                          initialValue: _selectedFilter,
                          onSelected: (value) {
                            setState(() {
                              _selectedFilter = value;
                              if (_selectedDay != null) {
                                _selectedTasks.value = _getTasksForDay(_selectedDay!);
                              }
                            });
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'all',
                              child: Row(
                                children: [
                                  Icon(Icons.all_inclusive, size: 16),
                                  SizedBox(width: 8),
                                  Text('All Tasks'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'due',
                              child: Row(
                                children: [
                                  Icon(Icons.event, size: 16),
                                  SizedBox(width: 8),
                                  Text('Due Date'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'assigned',
                              child: Row(
                                children: [
                                  Icon(Icons.assignment_ind, size: 16),
                                  SizedBox(width: 8),
                                  Text('Assigned Date'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'created',
                              child: Row(
                                children: [
                                  Icon(Icons.add_circle, size: 16),
                                  SizedBox(width: 8),
                                  Text('Created Date'),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getFilterIcon(_selectedFilter),
                                  size: 16,
                                  color: AppColors.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getFilterName(_selectedFilter),
                                  style: const TextStyle(
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  size: 16,
                                  color: AppColors.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Refresh button
                        IconButton(
                          onPressed: () {
                            ref.read(taskProvider.notifier).refresh();
                          },
                          icon: const Icon(Icons.refresh, color: AppColors.primaryColor),
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Calendar legend
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem('Due Today', AppColors.errorColor),
                    _buildLegendItem('Upcoming', AppColors.warningColor),
                    _buildLegendItem('Completed', AppColors.successColor),
                    _buildLegendItem('In Progress', AppColors.primaryColor),
                  ],
                ),
              ],
            ),
          ),
          
          // Calendar and task list
          Expanded(
            child: taskState.isLoading && taskState.tasks.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LoadingWidget(),
                        SizedBox(height: 16),
                        Text('Loading calendar...', style: TextStyle(color: AppColors.gray600)),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      // Calendar
                      Expanded(
                        flex: 2,
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
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
                          child: _buildCalendar(taskState.tasks),
                        ),
                      ),
                      
                      // Task list for selected day
                      Expanded(
                        flex: 1,
                        child: Container(
                          margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
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
                          child: _buildTaskList(),
                        ),
                      ),
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
              builder: (context) => TaskFormScreen(
                defaultStatus: TaskStatus.pending,
              ),
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.gray600,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(List<Task> allTasks) {
    return TableCalendar<Task>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      rangeSelectionMode: _rangeSelectionMode,
      eventLoader: _getTasksForDay,
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: const CalendarStyle(
        outsideDaysVisible: false,
        weekendTextStyle: TextStyle(color: AppColors.errorColor),
        holidayTextStyle: TextStyle(color: AppColors.errorColor),
        markerDecoration: BoxDecoration(
          color: AppColors.primaryColor,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: AppColors.primaryColor,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: AppColors.warningColor,
          shape: BoxShape.circle,
        ),
        markerSize: 6,
        markersMaxCount: 3,
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.gray900,
        ),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: AppColors.primaryColor,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: AppColors.primaryColor,
        ),
      ),
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      rangeStartDay: _rangeStart,
      rangeEndDay: _rangeEnd,
      onDaySelected: _onDaySelected,
      onRangeSelected: _onRangeSelected,
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return const SizedBox.shrink();
          
          return Positioned(
            right: 1,
            bottom: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: events.take(3).map((task) {
                return Container(
                  margin: const EdgeInsets.only(left: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _getTaskColor(task),
                    shape: BoxShape.circle,
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskList() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.gray200),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.event_note,
                color: AppColors.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedDay != null 
                    ? _formatSelectedDate(_selectedDay!)
                    : 'Select a date',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
        ),
        
        // Task list
        Expanded(
          child: ValueListenableBuilder<List<Task>>(
            valueListenable: _selectedTasks,
            builder: (context, tasks, _) {
              if (tasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 48,
                        color: AppColors.gray400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No tasks for this date',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.gray600,
                        ),
                      ),
                      Text(
                        'Create a new task or select a different date',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.gray500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _taskListController,
                padding: const EdgeInsets.all(8),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return _buildTaskItem(tasks[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(Task task) {
    return DragTarget<Task>(
      onAcceptWithDetails: (details) => _moveTaskToDate(details.data, _selectedDay!),
      builder: (context, candidateData, rejectedData) {
        return Draggable<Task>(
          data: task,
          feedback: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                task.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          childWhenDragging: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gray100.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gray300, width: 1),
            ),
            child: const SizedBox(height: 60),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: candidateData.isNotEmpty 
                  ? AppColors.primaryColor.withValues(alpha: 0.1)
                  : AppColors.gray50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: candidateData.isNotEmpty 
                    ? AppColors.primaryColor
                    : AppColors.gray200,
                width: candidateData.isNotEmpty ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task title
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // Task details
                Row(
                  children: [
                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getTaskColor(task).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(task.status),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getTaskColor(task),
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Priority
                    Icon(
                      _getPriorityIcon(task.priority),
                      size: 14,
                      color: _getPriorityColor(task.priority),
                    ),
                  ],
                ),
                
                // Due date indicator
                if (task.dueDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: _isOverdue(task.dueDate!, task.status) 
                            ? AppColors.errorColor 
                            : AppColors.gray500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due ${_formatDueDate(task.dueDate!)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: _isOverdue(task.dueDate!, task.status) 
                              ? AppColors.errorColor 
                              : AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null;
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
        _selectedTasks.value = _getTasksForDay(selectedDay);
      });
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    if (start != null && end != null) {
      // Handle range selection - could show tasks for the entire range
    }
  }

  void _toggleCalendarFormat() {
    setState(() {
      _calendarFormat = _calendarFormat == CalendarFormat.month 
          ? CalendarFormat.twoWeeks 
          : CalendarFormat.month;
    });
  }

  Future<void> _moveTaskToDate(Task task, DateTime newDate) async {
    // Update task due date
    final success = await ref.read(taskProvider.notifier).updateTask(
      task.id!,
      {'dueDate': newDate.toIso8601String()},
    );

    if (success) {
      setState(() {
        _selectedTasks.value = _getTasksForDay(_selectedDay!);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${task.title}" moved to ${_formatSelectedDate(newDate)}'),
            backgroundColor: AppColors.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Color _getTaskColor(Task task) {
    switch (task.status) {
      case TaskStatus.pending:
        return AppColors.warningColor;
      case TaskStatus.inProgress:
        return AppColors.primaryColor;
      case TaskStatus.completed:
        return AppColors.successColor;
      case TaskStatus.cancelled:
        return AppColors.errorColor;
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

  bool _isOverdue(DateTime dueDate, TaskStatus status) {
    return status != TaskStatus.completed && dueDate.isBefore(DateTime.now());
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    
    if (difference.isNegative) {
      return 'overdue';
    } else if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'tomorrow';
    } else {
      return '${dueDate.day}/${dueDate.month}';
    }
  }

  String _formatSelectedDate(DateTime date) {
    final now = DateTime.now();
    if (isSameDay(date, now)) {
      return 'Today';
    } else if (isSameDay(date, now.add(const Duration(days: 1)))) {
      return 'Tomorrow';
    } else if (isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'due':
        return Icons.event;
      case 'assigned':
        return Icons.assignment_ind;
      case 'created':
        return Icons.add_circle;
      default:
        return Icons.all_inclusive;
    }
  }

  String _getFilterName(String filter) {
    switch (filter) {
      case 'due':
        return 'Due';
      case 'assigned':
        return 'Assigned';
      case 'created':
        return 'Created';
      default:
        return 'All';
    }
  }
}