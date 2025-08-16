enum CommentType {
  comment,
  systemUpdate,
  statusChange,
  assignmentChange,
  priorityChange,
  attachment,
  subtask,
  timeTracking,
}

class TaskComment {
  final int? id;
  final int taskId;
  final int? userId;
  final String? userName;
  final String? userInitials;
  final String content;
  final CommentType type;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
  final Map<String, dynamic>? metadata; // For storing additional data like old/new values

  const TaskComment({
    this.id,
    required this.taskId,
    this.userId,
    this.userName,
    this.userInitials,
    required this.content,
    this.type = CommentType.comment,
    required this.createdAt,
    this.updatedAt,
    this.isEdited = false,
    this.metadata,
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    return TaskComment(
      id: json['id'] as int?,
      taskId: json['task_id'] ?? json['taskId'] as int,
      userId: json['user_id'] ?? json['userId'] as int?,
      userName: json['user_name'] ?? json['userName'] as String?,
      userInitials: json['user_initials'] ?? json['userInitials'] as String?,
      content: json['content'] as String,
      type: CommentType.values.byName(json['type'] as String? ?? 'comment'),
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] ?? json['updatedAt'] as String)
          : null,
      isEdited: json['is_edited'] ?? json['isEdited'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'user_name': userName,
      'user_initials': userInitials,
      'content': content,
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_edited': isEdited,
      'metadata': metadata,
    };
  }

  TaskComment copyWith({
    int? id,
    int? taskId,
    int? userId,
    String? userName,
    String? userInitials,
    String? content,
    CommentType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    Map<String, dynamic>? metadata,
  }) {
    return TaskComment(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userInitials: userInitials ?? this.userInitials,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper getters
  bool get isSystemComment => type != CommentType.comment;
  bool get isUserComment => type == CommentType.comment && userId != null;
  bool get canEdit => isUserComment && !isEdited;
  
  String get displayName => userName ?? 'Unknown User';
  String get displayInitials => userInitials ?? userName?.substring(0, 1).toUpperCase() ?? 'U';

  String get typeDisplayText {
    switch (type) {
      case CommentType.comment:
        return 'commented';
      case CommentType.systemUpdate:
        return 'system update';
      case CommentType.statusChange:
        return 'changed status';
      case CommentType.assignmentChange:
        return 'changed assignment';
      case CommentType.priorityChange:
        return 'changed priority';
      case CommentType.attachment:
        return 'added attachment';
      case CommentType.subtask:
        return 'updated subtask';
      case CommentType.timeTracking:
        return 'logged time';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskComment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TaskComment{id: $id, taskId: $taskId, type: $type, content: $content}';
  }
}

// Activity log entry for broader system events
class ActivityLogEntry {
  final int? id;
  final int? taskId;
  final int? userId;
  final String? userName;
  final String action;
  final String description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const ActivityLogEntry({
    this.id,
    this.taskId,
    this.userId,
    this.userName,
    required this.action,
    required this.description,
    this.metadata,
    required this.createdAt,
  });

  factory ActivityLogEntry.fromJson(Map<String, dynamic> json) {
    return ActivityLogEntry(
      id: json['id'] as int?,
      taskId: json['task_id'] ?? json['taskId'] as int?,
      userId: json['user_id'] ?? json['userId'] as int?,
      userName: json['user_name'] ?? json['userName'] as String?,
      action: json['action'] as String,
      description: json['description'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'user_name': userName,
      'action': action,
      'description': description,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ActivityLogEntry copyWith({
    int? id,
    int? taskId,
    int? userId,
    String? userName,
    String? action,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return ActivityLogEntry(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      action: action ?? this.action,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLogEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ActivityLogEntry{id: $id, action: $action, description: $description}';
  }
}