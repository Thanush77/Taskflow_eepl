import 'task.dart';

enum FilterOperator {
  equals,
  notEquals,
  contains,
  notContains,
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,
  isNull,
  isNotNull,
  inList,
  notInList,
  between,
}

enum DateRangeType {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  thisYear,
  lastYear,
  custom,
  next7Days,
  next30Days,
  overdue,
}

enum SortBy {
  title,
  createdAt,
  updatedAt,
  dueDate,
  startDate,
  priority,
  status,
  assignedTo,
  estimatedHours,
  actualHours,
  completedAt,
}

enum SortOrder {
  ascending,
  descending,
}

class TaskFilter {
  final int? id;
  final String name;
  final String? description;
  final Map<String, FilterCondition> conditions;
  final SortBy sortBy;
  final SortOrder sortOrder;
  final bool isDefault;
  final bool isShared;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? createdBy;

  const TaskFilter({
    this.id,
    required this.name,
    this.description,
    this.conditions = const {},
    this.sortBy = SortBy.createdAt,
    this.sortOrder = SortOrder.descending,
    this.isDefault = false,
    this.isShared = false,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory TaskFilter.fromJson(Map<String, dynamic> json) {
    return TaskFilter(
      id: json['id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String?,
      conditions: (json['conditions'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(
                key,
                FilterCondition.fromJson(value as Map<String, dynamic>),
              )),
      sortBy: SortBy.values.firstWhere(
        (e) => e.name == json['sort_by'],
        orElse: () => SortBy.createdAt,
      ),
      sortOrder: SortOrder.values.firstWhere(
        (e) => e.name == json['sort_order'],
        orElse: () => SortOrder.descending,
      ),
      isDefault: json['is_default'] ?? false,
      isShared: json['is_shared'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      createdBy: json['created_by'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      'conditions': conditions.map((key, value) => MapEntry(key, value.toJson())),
      'sort_by': sortBy.name,
      'sort_order': sortOrder.name,
      'is_default': isDefault,
      'is_shared': isShared,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
    };
  }

  TaskFilter copyWith({
    int? id,
    String? name,
    String? description,
    Map<String, FilterCondition>? conditions,
    SortBy? sortBy,
    SortOrder? sortOrder,
    bool? isDefault,
    bool? isShared,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? createdBy,
  }) {
    return TaskFilter(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      conditions: conditions ?? this.conditions,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault ?? this.isDefault,
      isShared: isShared ?? this.isShared,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // Apply this filter to a list of tasks
  List<Task> apply(List<Task> tasks) {
    List<Task> filteredTasks = tasks;

    // Apply conditions
    for (final condition in conditions.values) {
      filteredTasks = condition.apply(filteredTasks);
    }

    // Apply sorting
    filteredTasks.sort((a, b) {
      int comparison = 0;
      
      switch (sortBy) {
        case SortBy.title:
          comparison = a.title.compareTo(b.title);
          break;
        case SortBy.createdAt:
          final aCreated = a.createdAt ?? DateTime(1970);
          final bCreated = b.createdAt ?? DateTime(1970);
          comparison = aCreated.compareTo(bCreated);
          break;
        case SortBy.updatedAt:
          final aUpdated = a.updatedAt ?? DateTime(1970);
          final bUpdated = b.updatedAt ?? DateTime(1970);
          comparison = aUpdated.compareTo(bUpdated);
          break;
        case SortBy.dueDate:
          final aDue = a.dueDate ?? DateTime(2100);
          final bDue = b.dueDate ?? DateTime(2100);
          comparison = aDue.compareTo(bDue);
          break;
        case SortBy.startDate:
          final aStart = a.startDate ?? DateTime(2100);
          final bStart = b.startDate ?? DateTime(2100);
          comparison = aStart.compareTo(bStart);
          break;
        case SortBy.priority:
          comparison = a.priority.index.compareTo(b.priority.index);
          break;
        case SortBy.status:
          comparison = a.status.index.compareTo(b.status.index);
          break;
        case SortBy.assignedTo:
          final aAssigned = a.assignedTo ?? 0;
          final bAssigned = b.assignedTo ?? 0;
          comparison = aAssigned.compareTo(bAssigned);
          break;
        case SortBy.estimatedHours:
          final aHours = a.estimatedHours ?? 0;
          final bHours = b.estimatedHours ?? 0;
          comparison = aHours.compareTo(bHours);
          break;
        case SortBy.actualHours:
          final aActual = a.actualHours ?? 0;
          final bActual = b.actualHours ?? 0;
          comparison = aActual.compareTo(bActual);
          break;
        case SortBy.completedAt:
          final aCompleted = a.completedAt ?? DateTime(1970);
          final bCompleted = b.completedAt ?? DateTime(1970);
          comparison = aCompleted.compareTo(bCompleted);
          break;
      }

      return sortOrder == SortOrder.ascending ? comparison : -comparison;
    });

    return filteredTasks;
  }

  // Quick filter constructors
  static TaskFilter myTasks(int userId) {
    return TaskFilter(
      name: 'My Tasks',
      conditions: {
        'assignedTo': FilterCondition(
          field: 'assignedTo',
          operator: FilterOperator.equals,
          value: userId,
        ),
      },
    );
  }

  static TaskFilter overdueTasks() {
    return TaskFilter(
      name: 'Overdue Tasks',
      conditions: {
        'dueDate': FilterCondition(
          field: 'dueDate',
          operator: FilterOperator.lessThan,
          value: DateTime.now(),
        ),
        'status': FilterCondition(
          field: 'status',
          operator: FilterOperator.notEquals,
          value: TaskStatus.completed,
        ),
      },
      sortBy: SortBy.dueDate,
    );
  }

  static TaskFilter thisWeekTasks() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return TaskFilter(
      name: 'This Week',
      conditions: {
        'dueDate': FilterCondition(
          field: 'dueDate',
          operator: FilterOperator.between,
          value: [startOfWeek, endOfWeek],
        ),
      },
      sortBy: SortBy.dueDate,
    );
  }

  static TaskFilter highPriorityTasks() {
    return TaskFilter(
      name: 'High Priority',
      conditions: {
        'priority': FilterCondition(
          field: 'priority',
          operator: FilterOperator.inList,
          value: [TaskPriority.high, TaskPriority.critical],
        ),
      },
      sortBy: SortBy.priority,
    );
  }

  static TaskFilter recentlyCompleted() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    
    return TaskFilter(
      name: 'Recently Completed',
      conditions: {
        'status': FilterCondition(
          field: 'status',
          operator: FilterOperator.equals,
          value: TaskStatus.completed,
        ),
        'completedAt': FilterCondition(
          field: 'completedAt',
          operator: FilterOperator.greaterThan,
          value: sevenDaysAgo,
        ),
      },
      sortBy: SortBy.completedAt,
      sortOrder: SortOrder.descending,
    );
  }
}

class FilterCondition {
  final String field;
  final FilterOperator operator;
  final dynamic value;

  const FilterCondition({
    required this.field,
    required this.operator,
    required this.value,
  });

  factory FilterCondition.fromJson(Map<String, dynamic> json) {
    return FilterCondition(
      field: json['field'] as String,
      operator: FilterOperator.values.firstWhere(
        (e) => e.name == json['operator'],
        orElse: () => FilterOperator.equals,
      ),
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'operator': operator.name,
      'value': value,
    };
  }

  List<Task> apply(List<Task> tasks) {
    return tasks.where((task) {
      final fieldValue = _getFieldValue(task, field);
      return _evaluateCondition(fieldValue, operator, value);
    }).toList();
  }

  dynamic _getFieldValue(Task task, String field) {
    switch (field) {
      case 'title':
        return task.title;
      case 'description':
        return task.description;
      case 'status':
        return task.status;
      case 'priority':
        return task.priority;
      case 'category':
        return task.category;
      case 'assignedTo':
        return task.assignedTo;
      case 'dueDate':
        return task.dueDate;
      case 'startDate':
        return task.startDate;
      case 'createdAt':
        return task.createdAt;
      case 'updatedAt':
        return task.updatedAt;
      case 'completedAt':
        return task.completedAt;
      case 'estimatedHours':
        return task.estimatedHours;
      case 'actualHours':
        return task.actualHours;
      case 'tags':
        return task.tags;
      default:
        return null;
    }
  }

  bool _evaluateCondition(dynamic fieldValue, FilterOperator operator, dynamic value) {
    switch (operator) {
      case FilterOperator.equals:
        return fieldValue == value;
      case FilterOperator.notEquals:
        return fieldValue != value;
      case FilterOperator.contains:
        if (fieldValue is String && value is String) {
          return fieldValue.toLowerCase().contains(value.toLowerCase());
        }
        if (fieldValue is List) {
          return fieldValue.contains(value);
        }
        return false;
      case FilterOperator.notContains:
        if (fieldValue is String && value is String) {
          return !fieldValue.toLowerCase().contains(value.toLowerCase());
        }
        if (fieldValue is List) {
          return !fieldValue.contains(value);
        }
        return true;
      case FilterOperator.greaterThan:
        if (fieldValue is Comparable && value is Comparable) {
          return fieldValue.compareTo(value) > 0;
        }
        return false;
      case FilterOperator.lessThan:
        if (fieldValue is Comparable && value is Comparable) {
          return fieldValue.compareTo(value) < 0;
        }
        return false;
      case FilterOperator.greaterThanOrEqual:
        if (fieldValue is Comparable && value is Comparable) {
          return fieldValue.compareTo(value) >= 0;
        }
        return false;
      case FilterOperator.lessThanOrEqual:
        if (fieldValue is Comparable && value is Comparable) {
          return fieldValue.compareTo(value) <= 0;
        }
        return false;
      case FilterOperator.isNull:
        return fieldValue == null;
      case FilterOperator.isNotNull:
        return fieldValue != null;
      case FilterOperator.inList:
        if (value is List) {
          return value.contains(fieldValue);
        }
        return false;
      case FilterOperator.notInList:
        if (value is List) {
          return !value.contains(fieldValue);
        }
        return true;
      case FilterOperator.between:
        if (value is List && value.length == 2 && fieldValue is Comparable) {
          return fieldValue.compareTo(value[0]) >= 0 && fieldValue.compareTo(value[1]) <= 0;
        }
        return false;
    }
  }
}

class SavedView {
  final int? id;
  final String name;
  final String? description;
  final TaskFilter filter;
  final bool isDefault;
  final bool isShared;
  final int? shareCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? createdBy;

  const SavedView({
    this.id,
    required this.name,
    this.description,
    required this.filter,
    this.isDefault = false,
    this.isShared = false,
    this.shareCount = 0,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory SavedView.fromJson(Map<String, dynamic> json) {
    return SavedView(
      id: json['id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String?,
      filter: TaskFilter.fromJson(json['filter'] as Map<String, dynamic>),
      isDefault: json['is_default'] ?? false,
      isShared: json['is_shared'] ?? false,
      shareCount: json['share_count'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      createdBy: json['created_by'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      'filter': filter.toJson(),
      'is_default': isDefault,
      'is_shared': isShared,
      'share_count': shareCount,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
    };
  }

  SavedView copyWith({
    int? id,
    String? name,
    String? description,
    TaskFilter? filter,
    bool? isDefault,
    bool? isShared,
    int? shareCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? createdBy,
  }) {
    return SavedView(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      filter: filter ?? this.filter,
      isDefault: isDefault ?? this.isDefault,
      isShared: isShared ?? this.isShared,
      shareCount: shareCount ?? this.shareCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // Apply the saved view's filter to tasks
  List<Task> apply(List<Task> tasks) {
    return filter.apply(tasks);
  }
}

// Quick access to predefined filters
class QuickFilters {
  static List<TaskFilter> getDefaultFilters() {
    return [
      TaskFilter(
        name: 'All Tasks',
        description: 'Show all tasks',
        conditions: {},
      ),
      TaskFilter.overdueTasks(),
      TaskFilter.thisWeekTasks(),
      TaskFilter.highPriorityTasks(),
      TaskFilter.recentlyCompleted(),
    ];
  }

  static TaskFilter getDateRangeFilter(DateRangeType rangeType, {DateTime? startDate, DateTime? endDate}) {
    final now = DateTime.now();
    DateTime start, end;

    switch (rangeType) {
      case DateRangeType.today:
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(days: 1));
        break;
      case DateRangeType.yesterday:
        start = DateTime(now.year, now.month, now.day - 1);
        end = start.add(const Duration(days: 1));
        break;
      case DateRangeType.thisWeek:
        start = now.subtract(Duration(days: now.weekday - 1));
        end = start.add(const Duration(days: 7));
        break;
      case DateRangeType.lastWeek:
        start = now.subtract(Duration(days: now.weekday + 6));
        end = start.add(const Duration(days: 7));
        break;
      case DateRangeType.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 1);
        break;
      case DateRangeType.lastMonth:
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 1);
        break;
      case DateRangeType.thisYear:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year + 1, 1, 1);
        break;
      case DateRangeType.lastYear:
        start = DateTime(now.year - 1, 1, 1);
        end = DateTime(now.year, 1, 1);
        break;
      case DateRangeType.next7Days:
        start = now;
        end = now.add(const Duration(days: 7));
        break;
      case DateRangeType.next30Days:
        start = now;
        end = now.add(const Duration(days: 30));
        break;
      case DateRangeType.overdue:
        return TaskFilter.overdueTasks();
      case DateRangeType.custom:
        start = startDate ?? now;
        end = endDate ?? now.add(const Duration(days: 1));
        break;
    }

    return TaskFilter(
      name: rangeType.name.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim(),
      conditions: {
        'dueDate': FilterCondition(
          field: 'dueDate',
          operator: FilterOperator.between,
          value: [start, end],
        ),
      },
      sortBy: SortBy.dueDate,
    );
  }
}