import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/task_template.dart';
import '../../models/task.dart';
import '../../providers/template_provider.dart';

class TemplateFormScreen extends ConsumerStatefulWidget {
  final TaskTemplate? template;

  const TemplateFormScreen({
    this.template,
    super.key,
  });

  @override
  ConsumerState<TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _TemplateFormScreenState extends ConsumerState<TemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedHoursController = TextEditingController();
  final _tagsController = TextEditingController();

  TemplateCategory _selectedCategory = TemplateCategory.general;
  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskCategory _selectedTaskCategory = TaskCategory.general;
  
  List<SubtaskTemplate> _subtaskTemplates = [];
  List<AutomationRule> _automationRules = [];
  List<String> _tags = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final template = widget.template!;
    _nameController.text = template.name;
    _descriptionController.text = template.description;
    _selectedCategory = template.category;
    _selectedPriority = template.defaultPriority;
    _selectedTaskCategory = template.defaultCategory;
    _estimatedHoursController.text = template.estimatedHours?.toString() ?? '';
    _tags = List.from(template.defaultTags);
    _subtaskTemplates = List.from(template.subtaskTemplates);
    _automationRules = List.from(template.automationRules);
    _tagsController.text = _tags.join(', ');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _estimatedHoursController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final template = TaskTemplate(
      id: widget.template?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      defaultPriority: _selectedPriority,
      defaultCategory: _selectedTaskCategory,
      estimatedHours: double.tryParse(_estimatedHoursController.text.trim()),
      defaultTags: _tags,
      subtaskTemplates: _subtaskTemplates,
      automationRules: _automationRules,
    );

    bool success;
    if (widget.template == null) {
      success = await ref.read(templateProvider.notifier).createTemplate(template);
    } else {
      success = await ref.read(templateProvider.notifier).updateTemplate(
        widget.template!.id!,
        template,
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.template == null 
              ? 'Template created successfully' 
              : 'Template updated successfully'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(templateProvider).error ?? 'Failed to save template'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  void _updateTags(String value) {
    final tagList = value.split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    setState(() {
      _tags = tagList;
    });
  }

  void _addSubtaskTemplate() {
    showDialog(
      context: context,
      builder: (context) => _SubtaskTemplateDialog(
        onAdd: (subtask) {
          setState(() {
            _subtaskTemplates.add(subtask);
          });
        },
      ),
    );
  }

  void _editSubtaskTemplate(int index) {
    showDialog(
      context: context,
      builder: (context) => _SubtaskTemplateDialog(
        subtask: _subtaskTemplates[index],
        onAdd: (subtask) {
          setState(() {
            _subtaskTemplates[index] = subtask;
          });
        },
      ),
    );
  }

  void _removeSubtaskTemplate(int index) {
    setState(() {
      _subtaskTemplates.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.template == null ? 'Create Template' : 'Edit Template'),
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
              onPressed: _saveTemplate,
              child: Text(
                widget.template == null ? 'Create' : 'Update',
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
                    
                    // Template Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Template Name *',
                        hintText: 'Enter template name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Template name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Describe what this template is for',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Description is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Category Selection
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<TemplateCategory>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Template Category',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.folder_outlined),
                            ),
                            items: TemplateCategory.values.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category.name.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedCategory = value;
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
              
              // Default Task Settings
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
                      'Default Task Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Priority and Category
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<TaskPriority>(
                            value: _selectedPriority,
                            decoration: const InputDecoration(
                              labelText: 'Default Priority',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.flag_outlined),
                            ),
                            items: TaskPriority.values.map((priority) {
                              return DropdownMenuItem(
                                value: priority,
                                child: Text(_getPriorityText(priority)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedPriority = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<TaskCategory>(
                            value: _selectedTaskCategory,
                            decoration: const InputDecoration(
                              labelText: 'Default Category',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: TaskCategory.values.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(_getCategoryText(category)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedTaskCategory = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Estimated Hours
                    TextFormField(
                      controller: _estimatedHoursController,
                      decoration: const InputDecoration(
                        labelText: 'Estimated Hours',
                        hintText: 'e.g., 2.5',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Tags
                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Default Tags',
                        hintText: 'Enter tags separated by commas',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tag_outlined),
                      ),
                      onChanged: _updateTags,
                    ),
                    
                    // Tags preview
                    if (_tags.isNotEmpty) ...[ 
                      const SizedBox(height: 8),
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
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Subtask Templates
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
                          'Subtask Templates',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray900,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addSubtaskTemplate,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Subtask'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    
                    if (_subtaskTemplates.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No subtask templates added yet',
                          style: TextStyle(
                            color: AppColors.gray500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      ...List.generate(_subtaskTemplates.length, (index) {
                        final subtask = _subtaskTemplates[index];
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
                                      subtask.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (subtask.description?.isNotEmpty == true)
                                      Text(
                                        subtask.description!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.gray600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _editSubtaskTemplate(index),
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                color: AppColors.gray600,
                              ),
                              IconButton(
                                onPressed: () => _removeSubtaskTemplate(index),
                                icon: const Icon(Icons.delete_outline, size: 16),
                                color: AppColors.errorColor,
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}

class _SubtaskTemplateDialog extends StatefulWidget {
  final SubtaskTemplate? subtask;
  final Function(SubtaskTemplate) onAdd;

  const _SubtaskTemplateDialog({
    this.subtask,
    required this.onAdd,
  });

  @override
  State<_SubtaskTemplateDialog> createState() => _SubtaskTemplateDialogState();
}

class _SubtaskTemplateDialogState extends State<_SubtaskTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedMinutesController = TextEditingController();
  
  bool _isOptional = false;
  int _order = 0;

  @override
  void initState() {
    super.initState();
    if (widget.subtask != null) {
      _titleController.text = widget.subtask!.title;
      _descriptionController.text = widget.subtask!.description ?? '';
      _isOptional = widget.subtask!.isOptional;
      _order = widget.subtask!.order;
      _estimatedMinutesController.text = widget.subtask!.estimatedMinutes?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedMinutesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final subtask = SubtaskTemplate(
      id: widget.subtask?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      order: _order,
      isOptional: _isOptional,
      estimatedMinutes: int.tryParse(_estimatedMinutesController.text.trim()),
    );

    widget.onAdd(subtask);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.subtask == null ? 'Add Subtask Template' : 'Edit Subtask Template'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Subtask Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _estimatedMinutesController,
                      decoration: const InputDecoration(
                        labelText: 'Estimated Minutes',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (int.tryParse(value) == null) {
                            return 'Enter valid number';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: _order.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Order',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _order = int.tryParse(value) ?? 0;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              CheckboxListTile(
                title: const Text('Optional'),
                value: _isOptional,
                onChanged: (value) {
                  setState(() {
                    _isOptional = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
          ),
          child: Text(
            widget.subtask == null ? 'Add' : 'Update',
            style: const TextStyle(color: AppColors.white),
          ),
        ),
      ],
    );
  }
}