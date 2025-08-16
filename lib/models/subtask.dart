class Subtask {
  final int? id;
  final int parentTaskId;
  final String title;
  final String? description;
  final bool isCompleted;
  final int? assignedTo;
  final String? assignedToName;
  final int createdBy;
  final String? createdByName;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final int sortOrder;

  const Subtask({
    this.id,
    required this.parentTaskId,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.assignedTo,
    this.assignedToName,
    required this.createdBy,
    this.createdByName,
    this.dueDate,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.sortOrder = 0,
  });

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'] as int?,
      parentTaskId: json['parent_task_id'] ?? json['parentTaskId'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: json['is_completed'] ?? json['isCompleted'] as bool? ?? false,
      assignedTo: json['assigned_to'] ?? json['assignedTo'] as int?,
      assignedToName: json['assigned_to_name'] ?? json['assignedToName'] as String?,
      createdBy: json['created_by'] ?? json['createdBy'] as int,
      createdByName: json['created_by_name'] ?? json['createdByName'] as String?,
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date'] ?? json['dueDate'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] ?? json['updatedAt'] as String)
          : null,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] ?? json['completedAt'] as String)
          : null,
      sortOrder: json['sort_order'] ?? json['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_task_id': parentTaskId,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'assigned_to': assignedTo,
      'assigned_to_name': assignedToName,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'sort_order': sortOrder,
    };
  }

  Subtask copyWith({
    int? id,
    int? parentTaskId,
    String? title,
    String? description,
    bool? isCompleted,
    int? assignedTo,
    String? assignedToName,
    int? createdBy,
    String? createdByName,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    int? sortOrder,
  }) {
    return Subtask(
      id: id ?? this.id,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  // Computed properties
  bool get hasAssignee => assignedTo != null;
  bool get isOverdue => dueDate != null && !isCompleted && dueDate!.isBefore(DateTime.now());
  String get statusText => isCompleted ? 'Completed' : 'Pending';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subtask &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Subtask{id: $id, parentTaskId: $parentTaskId, title: $title, isCompleted: $isCompleted}';
  }
}

class TaskDependency {
  final int? id;
  final int taskId;
  final int dependsOnTaskId;
  final String dependencyType;
  final DateTime createdAt;
  final String? taskTitle;
  final String? dependsOnTaskTitle;

  const TaskDependency({
    this.id,
    required this.taskId,
    required this.dependsOnTaskId,
    required this.dependencyType,
    required this.createdAt,
    this.taskTitle,
    this.dependsOnTaskTitle,
  });

  factory TaskDependency.fromJson(Map<String, dynamic> json) {
    return TaskDependency(
      id: json['id'] as int?,
      taskId: json['task_id'] ?? json['taskId'] as int,
      dependsOnTaskId: json['depends_on_task_id'] ?? json['dependsOnTaskId'] as int,
      dependencyType: json['dependency_type'] ?? json['dependencyType'] as String,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] as String),
      taskTitle: json['task_title'] ?? json['taskTitle'] as String?,
      dependsOnTaskTitle: json['depends_on_task_title'] ?? json['dependsOnTaskTitle'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'depends_on_task_id': dependsOnTaskId,
      'dependency_type': dependencyType,
      'created_at': createdAt.toIso8601String(),
      'task_title': taskTitle,
      'depends_on_task_title': dependsOnTaskTitle,
    };
  }

  TaskDependency copyWith({
    int? id,
    int? taskId,
    int? dependsOnTaskId,
    String? dependencyType,
    DateTime? createdAt,
    String? taskTitle,
    String? dependsOnTaskTitle,
  }) {
    return TaskDependency(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      dependsOnTaskId: dependsOnTaskId ?? this.dependsOnTaskId,
      dependencyType: dependencyType ?? this.dependencyType,
      createdAt: createdAt ?? this.createdAt,
      taskTitle: taskTitle ?? this.taskTitle,
      dependsOnTaskTitle: dependsOnTaskTitle ?? this.dependsOnTaskTitle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskDependency &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TaskDependency{id: $id, taskId: $taskId, dependsOnTaskId: $dependsOnTaskId, type: $dependencyType}';
  }
}