import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/analytics.dart';
import '../../models/task.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/team_provider.dart';

class AnalyticsFilterSheet extends ConsumerStatefulWidget {
  const AnalyticsFilterSheet({super.key});

  @override
  ConsumerState<AnalyticsFilterSheet> createState() => _AnalyticsFilterSheetState();
}

class _AnalyticsFilterSheetState extends ConsumerState<AnalyticsFilterSheet> {
  late AnalyticsFilter _currentFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  Set<int> _selectedUserIds = {};
  Set<String> _selectedCategories = {};
  Set<String> _selectedPriorities = {};
  Set<String> _selectedStatuses = {};

  @override
  void initState() {
    super.initState();
    _currentFilter = ref.read(currentAnalyticsFilterProvider);
    _startDate = _currentFilter.startDate;
    _endDate = _currentFilter.endDate;
    _selectedUserIds = Set.from(_currentFilter.userIds);
    _selectedCategories = Set.from(_currentFilter.categories);
    _selectedPriorities = Set.from(_currentFilter.priorities);
    _selectedStatuses = Set.from(_currentFilter.statuses);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.gray200),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Filter Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: AppColors.primaryColor),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Filter Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range
                  _buildDateRangeSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Categories
                  _buildCategorySection(),
                  
                  const SizedBox(height: 24),
                  
                  // Priorities
                  _buildPrioritySection(),
                  
                  const SizedBox(height: 24),
                  
                  // Statuses
                  _buildStatusSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Team Members
                  _buildTeamMembersSection(),
                ],
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.gray200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.gray300),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.gray700),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Quick preset buttons
            Wrap(
              spacing: 8,
              children: [
                _buildDatePresetChip('Last 7 days', 7),
                _buildDatePresetChip('Last 30 days', 30),
                _buildDatePresetChip('Last 90 days', 90),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                'Start Date',
                _startDate,
                (date) => setState(() => _startDate = date),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                'End Date',
                _endDate,
                (date) => setState(() => _endDate = date),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePresetChip(String label, int days) {
    final isSelected = _startDate != null && 
        _endDate != null &&
        _startDate!.difference(DateTime.now()).inDays.abs() == days &&
        _endDate!.isAtSameMomentAs(DateTime.now());

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _startDate = DateTime.now().subtract(Duration(days: days));
            _endDate = DateTime.now();
          });
        }
      },
      selectedColor: AppColors.primaryColor.withValues(alpha: 0.1),
      checkmarkColor: AppColors.primaryColor,
    );
  }

  Widget _buildDateField(String label, DateTime? date, Function(DateTime?) onChanged) {
    return InkWell(
      onTap: () => _selectDate(context, date, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gray300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: AppColors.gray600,
            ),
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
                  const SizedBox(height: 2),
                  Text(
                    date != null 
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 14,
                      color: date != null ? AppColors.gray900 : AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categories',
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
          children: TaskCategory.values.map((category) {
            final categoryName = category.toString().split('.').last;
            final isSelected = _selectedCategories.contains(categoryName);
            
            return FilterChip(
              label: Text(_formatCategoryName(categoryName)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(categoryName);
                  } else {
                    _selectedCategories.remove(categoryName);
                  }
                });
              },
              selectedColor: AppColors.primaryColor.withValues(alpha: 0.1),
              checkmarkColor: AppColors.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrioritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priorities',
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
          children: TaskPriority.values.map((priority) {
            final priorityName = priority.toString().split('.').last;
            final isSelected = _selectedPriorities.contains(priorityName);
            
            return FilterChip(
              label: Text(_formatPriorityName(priorityName)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedPriorities.add(priorityName);
                  } else {
                    _selectedPriorities.remove(priorityName);
                  }
                });
              },
              selectedColor: _getPriorityColor(priority).withValues(alpha: 0.1),
              checkmarkColor: _getPriorityColor(priority),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
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
          children: TaskStatus.values.map((status) {
            final statusName = status.toString().split('.').last;
            final isSelected = _selectedStatuses.contains(statusName);
            
            return FilterChip(
              label: Text(_formatStatusName(statusName)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedStatuses.add(statusName);
                  } else {
                    _selectedStatuses.remove(statusName);
                  }
                });
              },
              selectedColor: _getStatusColor(status).withValues(alpha: 0.1),
              checkmarkColor: _getStatusColor(status),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTeamMembersSection() {
    final teamState = ref.watch(teamProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Team Members',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 12),
        if (teamState.users.isEmpty)
          Text(
            'No team members available',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.gray500,
            ),
          )
        else
          ...teamState.users.map((user) {
            final isSelected = _selectedUserIds.contains(user.id);
            
            return CheckboxListTile(
              title: Text(user.fullName),
              subtitle: Text(user.role ?? 'Team Member'),
              value: isSelected,
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedUserIds.add(user.id);
                  } else {
                    _selectedUserIds.remove(user.id);
                  }
                });
              },
              activeColor: AppColors.primaryColor,
              contentPadding: EdgeInsets.zero,
            );
          }),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, DateTime? initialDate, Function(DateTime?) onChanged) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      onChanged(date);
    }
  }

  void _resetFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedUserIds.clear();
      _selectedCategories.clear();
      _selectedPriorities.clear();
      _selectedStatuses.clear();
    });
  }

  void _applyFilters() {
    final filter = AnalyticsFilter(
      startDate: _startDate,
      endDate: _endDate,
      userIds: _selectedUserIds.toList(),
      categories: _selectedCategories.toList(),
      priorities: _selectedPriorities.toList(),
      statuses: _selectedStatuses.toList(),
    );

    ref.read(analyticsProvider.notifier).updateFilter(filter);
    Navigator.of(context).pop();
  }

  String _formatCategoryName(String name) {
    return name.substring(0, 1).toUpperCase() + name.substring(1);
  }

  String _formatPriorityName(String name) {
    return name.substring(0, 1).toUpperCase() + name.substring(1);
  }

  String _formatStatusName(String name) {
    switch (name) {
      case 'inProgress':
        return 'In Progress';
      default:
        return name.substring(0, 1).toUpperCase() + name.substring(1);
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.critical:
        return AppColors.errorColor;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.medium:
        return AppColors.warningColor;
      case TaskPriority.low:
        return AppColors.primaryColor;
      case TaskPriority.lowest:
        return AppColors.gray600;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return AppColors.gray600;
      case TaskStatus.inProgress:
        return AppColors.warningColor;
      case TaskStatus.completed:
        return AppColors.successColor;
      case TaskStatus.cancelled:
        return AppColors.errorColor;
    }
  }
}