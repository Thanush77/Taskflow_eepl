enum TaskStatus { pending, inProgress, completed, cancelled }

enum TaskPriority { lowest, low, medium, high, critical }

enum TaskCategory { 
  general, 
  development, 
  design, 
  marketing, 
  research, 
  planning, 
  testing 
}

class Task {
  final int? id;
  final String title;
  final String? description;
  final int? assignedTo;
  final String? assignedToName;
  final String? assignedByName;
  final int? createdBy;
  final String? createdByName;
  final TaskStatus status;
  final TaskPriority priority;
  final TaskCategory category;
  final double estimatedHours;
  final double? actualHours;
  final DateTime? startDate;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final DateTime? assignedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> tags;

  Task({
    this.id,
    required this.title,
    this.description,
    this.assignedTo,
    this.assignedToName,
    this.assignedByName,
    this.createdBy,
    this.createdByName,
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.general,
    this.estimatedHours = 1.0,
    this.actualHours,
    this.startDate,
    this.dueDate,
    this.completedAt,
    this.assignedAt,
    this.createdAt,
    this.updatedAt,
    this.tags = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String?,
      // Handle both snake_case and camelCase from backend
      assignedTo: (json['assigned_to'] ?? json['assignedTo']) as int?,
      assignedToName: (json['assigned_to_name'] ?? json['assignedToName']) as String?,
      assignedByName: json['assigned_by_name'] as String?,
      createdBy: (json['created_by'] ?? json['createdBy']) as int?,
      createdByName: (json['created_by_name'] ?? json['createdByName']) as String?,
      status: _parseStatus(json['status'] as String?),
      priority: _parsePriority(json['priority'] as String?),
      category: _parseCategory(json['category'] as String?),
      estimatedHours: _parseDouble(json['estimated_hours'] ?? json['estimatedHours']) ?? 1.0,
      actualHours: _parseDouble(json['actual_hours'] ?? json['actualHours']),
      startDate: (json['start_date'] ?? json['startDate']) != null 
          ? DateTime.parse((json['start_date'] ?? json['startDate']) as String)
          : null,
      dueDate: (json['due_date'] ?? json['dueDate']) != null 
          ? DateTime.parse((json['due_date'] ?? json['dueDate']) as String)
          : null,
      completedAt: (json['completed_at'] ?? json['completedAt']) != null 
          ? DateTime.parse((json['completed_at'] ?? json['completedAt']) as String)
          : null,
      assignedAt: json['assigned_at'] != null 
          ? DateTime.parse(json['assigned_at'] as String)
          : null,
      createdAt: (json['created_at'] ?? json['createdAt']) != null 
          ? DateTime.parse((json['created_at'] ?? json['createdAt']) as String)
          : null,
      updatedAt: (json['updated_at'] ?? json['updatedAt']) != null 
          ? DateTime.parse((json['updated_at'] ?? json['updatedAt']) as String)
          : null,
      tags: json['tags'] != null 
          ? List<String>.from(json['tags'] as List)
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'assigned_to': assignedTo,
      'assigned_to_name': assignedToName,
      'assigned_by_name': assignedByName,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'status': status.name.replaceAll('inProgress', 'in-progress'),
      'priority': priority.name,
      'category': category.name,
      'estimated_hours': estimatedHours,
      'actual_hours': actualHours,
      'start_date': startDate?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'assigned_at': assignedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'tags': tags,
    };
  }

  static TaskStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending': return TaskStatus.pending;
      case 'in-progress': return TaskStatus.inProgress;
      case 'completed': return TaskStatus.completed;
      case 'cancelled': return TaskStatus.cancelled;
      default: return TaskStatus.pending;
    }
  }

  static TaskPriority _parsePriority(String? priority) {
    switch (priority) {
      case 'lowest': return TaskPriority.lowest;
      case 'low': return TaskPriority.low;
      case 'medium': return TaskPriority.medium;
      case 'high': return TaskPriority.high;
      case 'critical': return TaskPriority.critical;
      default: return TaskPriority.medium;
    }
  }

  static TaskCategory _parseCategory(String? category) {
    switch (category) {
      case 'general': return TaskCategory.general;
      case 'development': return TaskCategory.development;
      case 'design': return TaskCategory.design;
      case 'marketing': return TaskCategory.marketing;
      case 'research': return TaskCategory.research;
      case 'planning': return TaskCategory.planning;
      case 'testing': return TaskCategory.testing;
      default: return TaskCategory.general;
    }
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  bool get isOverdue {
    if (dueDate == null || status == TaskStatus.completed) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  bool get isDueSoon {
    if (dueDate == null || status == TaskStatus.completed || isOverdue) return false;
    final now = DateTime.now();
    final difference = dueDate!.difference(now);
    return difference.inDays == 0; // Due within 24 hours
  }

  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate!).inDays;
  }

  int get daysToDue {
    if (dueDate == null) return -1;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    int? assignedTo,
    String? assignedToName,
    String? assignedByName,
    int? createdBy,
    String? createdByName,
    TaskStatus? status,
    TaskPriority? priority,
    TaskCategory? category,
    double? estimatedHours,
    double? actualHours,
    DateTime? startDate,
    DateTime? dueDate,
    DateTime? completedAt,
    DateTime? assignedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedByName: assignedByName ?? this.assignedByName,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      actualHours: actualHours ?? this.actualHours,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      assignedAt: assignedAt ?? this.assignedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
    );
  }
}