import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/task_filter.dart';
import '../../models/task.dart';
import '../../providers/filter_provider.dart';

class FilterFormScreen extends ConsumerStatefulWidget {
  final SavedView? savedView;

  const FilterFormScreen({
    this.savedView,
    super.key,
  });

  @override
  ConsumerState<FilterFormScreen> createState() => _FilterFormScreenState();
}

class _FilterFormScreenState extends ConsumerState<FilterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  Map<String, FilterCondition> _conditions = {};
  SortBy _sortBy = SortBy.createdAt;
  SortOrder _sortOrder = SortOrder.descending;
  bool _isShared = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.savedView != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final view = widget.savedView!;
    _nameController.text = view.name;
    _descriptionController.text = view.description ?? '';
    _conditions = Map.from(view.filter.conditions);
    _sortBy = view.filter.sortBy;
    _sortOrder = view.filter.sortOrder;
    _isShared = view.isShared;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveView() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final filter = TaskFilter(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      conditions: _conditions,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    );

    final savedView = SavedView(
      id: widget.savedView?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      filter: filter,
      isShared: _isShared,
    );

    bool success;
    if (widget.savedView == null) {
      success = await ref.read(filterProvider.notifier).createSavedView(savedView);
    } else {
      success = await ref.read(filterProvider.notifier).updateSavedView(
        widget.savedView!.id!,
        savedView,
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.savedView == null 
              ? 'Saved view created successfully' 
              : 'Saved view updated successfully'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(filterProvider).error ?? 'Failed to save view'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.savedView == null ? 'Create View' : 'Edit View'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryColor,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveView,
              child: Text(
                widget.savedView == null ? 'Create' : 'Update',
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // View Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'View Name *',
                        hintText: 'Enter view name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'View name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe what this view shows',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    
                    // Shared toggle
                    SwitchListTile(
                      title: const Text('Share with team'),
                      subtitle: const Text('Allow other team members to use this view'),
                      value: _isShared,
                      onChanged: (value) {
                        setState(() {
                          _isShared = value;
                        });
                      },
                      activeColor: AppColors.primaryColor,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Sorting Options
              Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sorting',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<SortBy>(
                            value: _sortBy,
                            decoration: const InputDecoration(
                              labelText: 'Sort by',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.sort),
                            ),
                            items: SortBy.values.map((sortBy) {
                              return DropdownMenuItem(
                                value: sortBy,
                                child: Text(_getSortDisplayText(sortBy)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _sortBy = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<SortOrder>(
                            value: _sortOrder,
                            decoration: const InputDecoration(
                              labelText: 'Order',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.swap_vert),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: SortOrder.ascending,
                                child: Text('Ascending'),
                              ),
                              DropdownMenuItem(
                                value: SortOrder.descending,
                                child: Text('Descending'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _sortOrder = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Filter Conditions
              Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Filter Conditions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray900,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addCondition,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Condition'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    
                    if (_conditions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No filter conditions added yet',
                          style: TextStyle(
                            color: AppColors.gray500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      ...List.generate(_conditions.length, (index) {
                        final entry = _conditions.entries.elementAt(index);
                        return _buildConditionItem(entry.key, entry.value);
                      }),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Preview section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _conditions.isEmpty 
                          ? 'This view will show all tasks sorted by ${_getSortDisplayText(_sortBy)} (${_sortOrder.name})'
                          : 'This view will filter tasks by ${_conditions.length} condition(s) and sort by ${_getSortDisplayText(_sortBy)} (${_sortOrder.name})',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConditionItem(String key, FilterCondition condition) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${condition.field} ${condition.operator.name} ${condition.value}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _getConditionDescription(condition),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _conditions.remove(key);
              });
            },
            icon: const Icon(Icons.delete_outline, size: 16),
            color: AppColors.errorColor,
          ),
        ],
      ),
    );
  }

  void _addCondition() {
    // Simple condition for demonstration
    // In a real app, this would open a detailed condition builder dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Filter Condition'),
        content: const Text(
          'Filter condition builder would be implemented here.\n\n'
          'This would allow users to select:\n'
          '• Field (status, priority, assignee, etc.)\n'
          '• Operator (equals, contains, greater than, etc.)\n'
          '• Value(s)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Add a sample condition for demonstration
              setState(() {
                _conditions['status'] = const FilterCondition(
                  field: 'status',
                  operator: FilterOperator.equals,
                  value: TaskStatus.pending,
                );
              });
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
            child: const Text('Add Sample', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  String _getSortDisplayText(SortBy sortBy) {
    switch (sortBy) {
      case SortBy.title:
        return 'Title';
      case SortBy.createdAt:
        return 'Created Date';
      case SortBy.updatedAt:
        return 'Updated Date';
      case SortBy.dueDate:
        return 'Due Date';
      case SortBy.startDate:
        return 'Start Date';
      case SortBy.priority:
        return 'Priority';
      case SortBy.status:
        return 'Status';
      case SortBy.assignedTo:
        return 'Assignee';
      case SortBy.estimatedHours:
        return 'Estimated Hours';
      case SortBy.actualHours:
        return 'Actual Hours';
      case SortBy.completedAt:
        return 'Completed Date';
    }
  }

  String _getConditionDescription(FilterCondition condition) {
    switch (condition.operator) {
      case FilterOperator.equals:
        return 'Show tasks where ${condition.field} equals ${condition.value}';
      case FilterOperator.contains:
        return 'Show tasks where ${condition.field} contains "${condition.value}"';
      case FilterOperator.greaterThan:
        return 'Show tasks where ${condition.field} is greater than ${condition.value}';
      case FilterOperator.lessThan:
        return 'Show tasks where ${condition.field} is less than ${condition.value}';
      case FilterOperator.isNull:
        return 'Show tasks where ${condition.field} is empty';
      case FilterOperator.isNotNull:
        return 'Show tasks where ${condition.field} is not empty';
      default:
        return 'Filter condition';
    }
  }
}