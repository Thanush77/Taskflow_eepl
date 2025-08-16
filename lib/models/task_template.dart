import 'task.dart';

enum TemplateCategory {
  general,
  development,
  design,
  marketing,
  meeting,
  project,
  maintenance,
  review,
}

enum AutomationTrigger {
  onCreate,
  onStatusChange,
  onDueDate,
  onAssignment,
  onCompletion,
  manual,
}

enum AutomationAction {
  createSubtask,
  assignUser,
  setStatus,
  setPriority,
  addTag,
  sendNotification,
  createFollowupTask,
  updateDueDate,
}

class TaskTemplate {
  final int? id;
  final String name;
  final String description;
  final TemplateCategory category;
  final TaskPriority defaultPriority;
  final TaskCategory defaultCategory;
  final int? defaultAssignedTo;
  final double? estimatedHours;
  final List<String> defaultTags;
  final List<SubtaskTemplate> subtaskTemplates;
  final List<AutomationRule> automationRules;
  final Map<String, dynamic>? customFields;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? createdBy;
  final int? usageCount; // Track how often this template is used

  const TaskTemplate({
    this.id,
    required this.name,
    required this.description,
    this.category = TemplateCategory.general,
    this.defaultPriority = TaskPriority.medium,
    this.defaultCategory = TaskCategory.general,
    this.defaultAssignedTo,
    this.estimatedHours,
    this.defaultTags = const [],
    this.subtaskTemplates = const [],
    this.automationRules = const [],
    this.customFields,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.usageCount = 0,
  });

  factory TaskTemplate.fromJson(Map<String, dynamic> json) {
    return TaskTemplate(
      id: json['id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String,
      category: TemplateCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TemplateCategory.general,
      ),
      defaultPriority: TaskPriority.values.firstWhere(
        (e) => e.name == json['default_priority'],
        orElse: () => TaskPriority.medium,
      ),
      defaultCategory: TaskCategory.values.firstWhere(
        (e) => e.name == json['default_category'],
        orElse: () => TaskCategory.general,
      ),
      defaultAssignedTo: json['default_assigned_to'] as int?,
      estimatedHours: json['estimated_hours']?.toDouble(),
      defaultTags: List<String>.from(json['default_tags'] ?? []),
      subtaskTemplates: (json['subtask_templates'] as List<dynamic>? ?? [])
          .map((e) => SubtaskTemplate.fromJson(e as Map<String, dynamic>))
          .toList(),
      automationRules: (json['automation_rules'] as List<dynamic>? ?? [])
          .map((e) => AutomationRule.fromJson(e as Map<String, dynamic>))
          .toList(),
      customFields: json['custom_fields'] as Map<String, dynamic>?,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      createdBy: json['created_by'] as int?,
      usageCount: json['usage_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'default_priority': defaultPriority.name,
      'default_category': defaultCategory.name,
      if (defaultAssignedTo != null) 'default_assigned_to': defaultAssignedTo,
      if (estimatedHours != null) 'estimated_hours': estimatedHours,
      'default_tags': defaultTags,
      'subtask_templates': subtaskTemplates.map((e) => e.toJson()).toList(),
      'automation_rules': automationRules.map((e) => e.toJson()).toList(),
      if (customFields != null) 'custom_fields': customFields,
      'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
      'usage_count': usageCount,
    };
  }

  TaskTemplate copyWith({
    int? id,
    String? name,
    String? description,
    TemplateCategory? category,
    TaskPriority? defaultPriority,
    TaskCategory? defaultCategory,
    int? defaultAssignedTo,
    double? estimatedHours,
    List<String>? defaultTags,
    List<SubtaskTemplate>? subtaskTemplates,
    List<AutomationRule>? automationRules,
    Map<String, dynamic>? customFields,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? createdBy,
    int? usageCount,
  }) {
    return TaskTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      defaultPriority: defaultPriority ?? this.defaultPriority,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      defaultAssignedTo: defaultAssignedTo ?? this.defaultAssignedTo,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      defaultTags: defaultTags ?? this.defaultTags,
      subtaskTemplates: subtaskTemplates ?? this.subtaskTemplates,
      automationRules: automationRules ?? this.automationRules,
      customFields: customFields ?? this.customFields,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  // Create a task from this template
  Task createTask({
    String? customTitle,
    String? customDescription,
    TaskPriority? customPriority,
    TaskCategory? customCategory,
    int? customAssignedTo,
    DateTime? customDueDate,
    DateTime? customStartDate,
    List<String>? additionalTags,
  }) {
    return Task(
      title: customTitle ?? name,
      description: customDescription ?? description,
      priority: customPriority ?? defaultPriority,
      category: customCategory ?? defaultCategory,
      assignedTo: customAssignedTo ?? defaultAssignedTo,
      estimatedHours: estimatedHours ?? 0,
      tags: [...defaultTags, ...(additionalTags ?? [])],
      dueDate: customDueDate,
      startDate: customStartDate,
      status: TaskStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  String get categoryDisplayText {
    switch (category) {
      case TemplateCategory.general:
        return 'General';
      case TemplateCategory.development:
        return 'Development';
      case TemplateCategory.design:
        return 'Design';
      case TemplateCategory.marketing:
        return 'Marketing';
      case TemplateCategory.meeting:
        return 'Meeting';
      case TemplateCategory.project:
        return 'Project';
      case TemplateCategory.maintenance:
        return 'Maintenance';
      case TemplateCategory.review:
        return 'Review';
    }
  }
}

class SubtaskTemplate {
  final int? id;
  final String title;
  final String? description;
  final int order;
  final bool isOptional;
  final int? defaultAssignedTo;
  final int? estimatedMinutes;

  const SubtaskTemplate({
    this.id,
    required this.title,
    this.description,
    this.order = 0,
    this.isOptional = false,
    this.defaultAssignedTo,
    this.estimatedMinutes,
  });

  factory SubtaskTemplate.fromJson(Map<String, dynamic> json) {
    return SubtaskTemplate(
      id: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String?,
      order: json['order'] ?? 0,
      isOptional: json['is_optional'] ?? false,
      defaultAssignedTo: json['default_assigned_to'] as int?,
      estimatedMinutes: json['estimated_minutes'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      if (description != null) 'description': description,
      'order': order,
      'is_optional': isOptional,
      if (defaultAssignedTo != null) 'default_assigned_to': defaultAssignedTo,
      if (estimatedMinutes != null) 'estimated_minutes': estimatedMinutes,
    };
  }
}

class AutomationRule {
  final int? id;
  final String name;
  final AutomationTrigger trigger;
  final AutomationAction action;
  final Map<String, dynamic> triggerConditions;
  final Map<String, dynamic> actionParameters;
  final bool isActive;
  final int? delayMinutes;

  const AutomationRule({
    this.id,
    required this.name,
    required this.trigger,
    required this.action,
    this.triggerConditions = const {},
    this.actionParameters = const {},
    this.isActive = true,
    this.delayMinutes,
  });

  factory AutomationRule.fromJson(Map<String, dynamic> json) {
    return AutomationRule(
      id: json['id'] as int?,
      name: json['name'] as String,
      trigger: AutomationTrigger.values.firstWhere(
        (e) => e.name == json['trigger'],
        orElse: () => AutomationTrigger.manual,
      ),
      action: AutomationAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => AutomationAction.createSubtask,
      ),
      triggerConditions: Map<String, dynamic>.from(json['trigger_conditions'] ?? {}),
      actionParameters: Map<String, dynamic>.from(json['action_parameters'] ?? {}),
      isActive: json['is_active'] ?? true,
      delayMinutes: json['delay_minutes'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'trigger': trigger.name,
      'action': action.name,
      'trigger_conditions': triggerConditions,
      'action_parameters': actionParameters,
      'is_active': isActive,
      if (delayMinutes != null) 'delay_minutes': delayMinutes,
    };
  }

  String get triggerDisplayText {
    switch (trigger) {
      case AutomationTrigger.onCreate:
        return 'When task is created';
      case AutomationTrigger.onStatusChange:
        return 'When status changes';
      case AutomationTrigger.onDueDate:
        return 'On due date';
      case AutomationTrigger.onAssignment:
        return 'When assigned';
      case AutomationTrigger.onCompletion:
        return 'When completed';
      case AutomationTrigger.manual:
        return 'Manual trigger';
    }
  }

  String get actionDisplayText {
    switch (action) {
      case AutomationAction.createSubtask:
        return 'Create subtask';
      case AutomationAction.assignUser:
        return 'Assign to user';
      case AutomationAction.setStatus:
        return 'Update status';
      case AutomationAction.setPriority:
        return 'Set priority';
      case AutomationAction.addTag:
        return 'Add tag';
      case AutomationAction.sendNotification:
        return 'Send notification';
      case AutomationAction.createFollowupTask:
        return 'Create follow-up task';
      case AutomationAction.updateDueDate:
        return 'Update due date';
    }
  }
}