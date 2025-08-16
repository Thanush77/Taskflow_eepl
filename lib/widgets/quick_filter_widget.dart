import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../models/task_filter.dart';
import '../models/task.dart';
import '../providers/filter_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../screens/home/saved_views_screen.dart';

class QuickFilterWidget extends ConsumerStatefulWidget {
  final Function(List<Task>)? onFilterChanged;
  
  const QuickFilterWidget({
    this.onFilterChanged,
    super.key,
  });

  @override
  ConsumerState<QuickFilterWidget> createState() => _QuickFilterWidgetState();
}

class _QuickFilterWidgetState extends ConsumerState<QuickFilterWidget> {
  bool _isExpanded = false;
  TaskStatus? _selectedStatus;
  TaskPriority? _selectedPriority;
  TaskCategory? _selectedCategory;
  DateRangeType? _selectedDateRange;
  bool _showMyTasksOnly = false;

  @override
  Widget build(BuildContext context) {
    final activeSavedView = ref.watch(activeSavedViewProvider);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Column(
        children: [
          // Header with toggle and active view info
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: AppColors.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray900,
                          ),
                        ),
                        if (activeSavedView != null)
                          Text(
                            'Active: ${activeSavedView.name}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else if (_hasActiveFilters())
                          Text(
                            '${_getActiveFilterCount()} filters active',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          const Text(
                            'No active filters',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_hasActiveFilters() || activeSavedView != null)
                        IconButton(
                          onPressed: _clearAllFilters,
                          icon: const Icon(Icons.clear, size: 18),
                          color: AppColors.gray600,
                          tooltip: 'Clear filters',
                        ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SavedViewsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bookmark_outline, size: 18),
                        color: AppColors.primaryColor,
                        tooltip: 'Saved views',
                      ),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.gray600,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable filter options
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick filter chips
                  _buildQuickFilterChips(),
                  
                  const SizedBox(height: 16),
                  
                  // Detailed filters
                  _buildDetailedFilters(),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetQuickFilters,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Reset'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.gray600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _applyQuickFilters,
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Apply'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickFilterChips() {
    final defaultViews = ref.watch(defaultViewsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Views',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: defaultViews.take(4).map((view) {
            final isActive = ref.watch(activeSavedViewProvider) == view;
            return FilterChip(
              label: Text(view.name),
              selected: isActive,
              onSelected: (selected) {
                if (selected) {
                  ref.read(activeSavedViewProvider.notifier).state = view;
                  _updateFilteredTasks();
                } else {
                  ref.read(activeSavedViewProvider.notifier).state = null;
                  _updateFilteredTasks();
                }
              },
              backgroundColor: AppColors.gray100,
              selectedColor: AppColors.primaryColor.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: isActive ? AppColors.primaryColor : AppColors.gray700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDetailedFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Custom Filters',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 12),
        
        // Status filter
        _buildFilterRow(
          'Status',
          DropdownButton<TaskStatus?>(
            value: _selectedStatus,
            hint: const Text('Any status'),
            isExpanded: true,
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem<TaskStatus?>(
                value: null,
                child: Text('Any status'),
              ),
              ...TaskStatus.values.map((status) => DropdownMenuItem(
                value: status,
                child: Text(_getStatusText(status)),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStatus = value;
              });
            },
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Priority filter
        _buildFilterRow(
          'Priority',
          DropdownButton<TaskPriority?>(
            value: _selectedPriority,
            hint: const Text('Any priority'),
            isExpanded: true,
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem<TaskPriority?>(
                value: null,
                child: Text('Any priority'),
              ),
              ...TaskPriority.values.map((priority) => DropdownMenuItem(
                value: priority,
                child: Text(_getPriorityText(priority)),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedPriority = value;
              });
            },
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Category filter
        _buildFilterRow(
          'Category',
          DropdownButton<TaskCategory?>(
            value: _selectedCategory,
            hint: const Text('Any category'),
            isExpanded: true,
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem<TaskCategory?>(
                value: null,
                child: Text('Any category'),
              ),
              ...TaskCategory.values.map((category) => DropdownMenuItem(
                value: category,
                child: Text(_getCategoryText(category)),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Date range filter
        _buildFilterRow(
          'Due Date',
          DropdownButton<DateRangeType?>(
            value: _selectedDateRange,
            hint: const Text('Any time'),
            isExpanded: true,
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem<DateRangeType?>(
                value: null,
                child: Text('Any time'),
              ),
              ...DateRangeType.values.take(8).map((range) => DropdownMenuItem(
                value: range,
                child: Text(_getDateRangeText(range)),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedDateRange = value;
              });
            },
          ),
        ),
        
        const SizedBox(height: 12),
        
        // My tasks toggle
        CheckboxListTile(
          title: const Text('My tasks only'),
          subtitle: const Text('Show only tasks assigned to me'),
          value: _showMyTasksOnly,
          onChanged: (value) {
            setState(() {
              _showMyTasksOnly = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primaryColor,
        ),
      ],
    );
  }

  Widget _buildFilterRow(String label, Widget control) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.gray600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gray300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: control,
          ),
        ),
      ],
    );
  }

  bool _hasActiveFilters() {
    return _selectedStatus != null ||
           _selectedPriority != null ||
           _selectedCategory != null ||
           _selectedDateRange != null ||
           _showMyTasksOnly;
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedStatus != null) count++;
    if (_selectedPriority != null) count++;
    if (_selectedCategory != null) count++;
    if (_selectedDateRange != null) count++;
    if (_showMyTasksOnly) count++;
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedPriority = null;
      _selectedCategory = null;
      _selectedDateRange = null;
      _showMyTasksOnly = false;
    });
    ref.read(activeSavedViewProvider.notifier).state = null;
    _updateFilteredTasks();
  }

  void _resetQuickFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedPriority = null;
      _selectedCategory = null;
      _selectedDateRange = null;
      _showMyTasksOnly = false;
    });
  }

  void _applyQuickFilters() {
    // Clear any active saved view since we're using custom filters
    ref.read(activeSavedViewProvider.notifier).state = null;
    
    // Create a custom filter based on selections
    final conditions = <String, FilterCondition>{};
    
    if (_selectedStatus != null) {
      conditions['status'] = FilterCondition(
        field: 'status',
        operator: FilterOperator.equals,
        value: _selectedStatus,
      );
    }
    
    if (_selectedPriority != null) {
      conditions['priority'] = FilterCondition(
        field: 'priority',
        operator: FilterOperator.equals,
        value: _selectedPriority,
      );
    }
    
    if (_selectedCategory != null) {
      conditions['category'] = FilterCondition(
        field: 'category',
        operator: FilterOperator.equals,
        value: _selectedCategory,
      );
    }
    
    if (_selectedDateRange != null) {
      final filter = QuickFilters.getDateRangeFilter(_selectedDateRange!);
      if (filter.conditions.isNotEmpty) {
        conditions.addAll(filter.conditions);
      }
    }
    
    if (_showMyTasksOnly) {
      final authState = ref.read(authProvider);
      final userId = authState.user?.id;
      if (userId != null) {
        conditions['assignedTo'] = FilterCondition(
          field: 'assignedTo',
          operator: FilterOperator.equals,
          value: userId,
        );
      }
    }
    
    final customFilter = TaskFilter(
      name: 'Custom Filter',
      conditions: conditions,
    );
    
    ref.read(filterProvider.notifier).setActiveFilter(customFilter);
    _updateFilteredTasks();
  }

  void _updateFilteredTasks() {
    final activeSavedView = ref.read(activeSavedViewProvider);
    final activeFilter = ref.read(filterProvider).activeFilter;
    final allTasks = ref.read(taskProvider).tasks;
    
    List<Task> filteredTasks = allTasks;
    
    if (activeSavedView != null) {
      filteredTasks = activeSavedView.apply(allTasks);
    } else if (activeFilter != null) {
      filteredTasks = activeFilter.apply(allTasks);
    }
    
    widget.onFilterChanged?.call(filteredTasks);
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

  String _getDateRangeText(DateRangeType range) {
    switch (range) {
      case DateRangeType.today:
        return 'Today';
      case DateRangeType.yesterday:
        return 'Yesterday';
      case DateRangeType.thisWeek:
        return 'This Week';
      case DateRangeType.lastWeek:
        return 'Last Week';
      case DateRangeType.thisMonth:
        return 'This Month';
      case DateRangeType.lastMonth:
        return 'Last Month';
      case DateRangeType.next7Days:
        return 'Next 7 Days';
      case DateRangeType.overdue:
        return 'Overdue';
      default:
        return range.name;
    }
  }
}