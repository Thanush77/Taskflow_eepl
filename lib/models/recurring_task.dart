import 'task.dart';

enum RecurrenceType {
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

enum RecurrenceDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

class RecurrencePattern {
  final RecurrenceType type;
  final int interval; // Every X days/weeks/months/years
  final List<RecurrenceDay> daysOfWeek; // For weekly recurrence
  final int? dayOfMonth; // For monthly recurrence (1-31)
  final int? monthOfYear; // For yearly recurrence (1-12)
  final DateTime? endDate; // When recurrence should stop
  final int? maxOccurrences; // Maximum number of occurrences

  const RecurrencePattern({
    required this.type,
    this.interval = 1,
    this.daysOfWeek = const [],
    this.dayOfMonth,
    this.monthOfYear,
    this.endDate,
    this.maxOccurrences,
  });

  factory RecurrencePattern.fromJson(Map<String, dynamic> json) {
    return RecurrencePattern(
      type: RecurrenceType.values.byName(json['type'] as String),
      interval: json['interval'] as int? ?? 1,
      daysOfWeek: (json['days_of_week'] as List<dynamic>?)
          ?.map((day) => RecurrenceDay.values.byName(day as String))
          .toList() ?? [],
      dayOfMonth: json['day_of_month'] as int?,
      monthOfYear: json['month_of_year'] as int?,
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date'] as String)
          : null,
      maxOccurrences: json['max_occurrences'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'interval': interval,
      'days_of_week': daysOfWeek.map((day) => day.name).toList(),
      'day_of_month': dayOfMonth,
      'month_of_year': monthOfYear,
      'end_date': endDate?.toIso8601String(),
      'max_occurrences': maxOccurrences,
    };
  }

  RecurrencePattern copyWith({
    RecurrenceType? type,
    int? interval,
    List<RecurrenceDay>? daysOfWeek,
    int? dayOfMonth,
    int? monthOfYear,
    DateTime? endDate,
    int? maxOccurrences,
  }) {
    return RecurrencePattern(
      type: type ?? this.type,
      interval: interval ?? this.interval,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      monthOfYear: monthOfYear ?? this.monthOfYear,
      endDate: endDate ?? this.endDate,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
    );
  }

  String get displayText {
    switch (type) {
      case RecurrenceType.daily:
        return interval == 1 ? 'Daily' : 'Every $interval days';
      case RecurrenceType.weekly:
        if (interval == 1 && daysOfWeek.length == 1) {
          return 'Weekly on ${_dayName(daysOfWeek.first)}';
        } else if (interval == 1) {
          return 'Weekly on ${daysOfWeek.map(_dayName).join(', ')}';
        }
        return 'Every $interval weeks';
      case RecurrenceType.monthly:
        if (dayOfMonth != null) {
          return interval == 1 
              ? 'Monthly on day $dayOfMonth' 
              : 'Every $interval months on day $dayOfMonth';
        }
        return interval == 1 ? 'Monthly' : 'Every $interval months';
      case RecurrenceType.yearly:
        return interval == 1 ? 'Yearly' : 'Every $interval years';
      case RecurrenceType.custom:
        return 'Custom recurrence';
    }
  }

  String _dayName(RecurrenceDay day) {
    switch (day) {
      case RecurrenceDay.monday:
        return 'Monday';
      case RecurrenceDay.tuesday:
        return 'Tuesday';
      case RecurrenceDay.wednesday:
        return 'Wednesday';
      case RecurrenceDay.thursday:
        return 'Thursday';
      case RecurrenceDay.friday:
        return 'Friday';
      case RecurrenceDay.saturday:
        return 'Saturday';
      case RecurrenceDay.sunday:
        return 'Sunday';
    }
  }
}

class RecurringTask {
  final int? id;
  final String title;
  final String? description;
  final int? assignedTo;
  final String? assignedToName;
  final TaskPriority priority;
  final TaskCategory category;
  final double estimatedHours;
  final RecurrencePattern recurrencePattern;
  final DateTime startDate;
  final DateTime? lastGenerated;
  final DateTime? nextDue;
  final bool isActive;
  final int createdBy;
  final String? createdByName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> tags;
  final int generatedCount;

  const RecurringTask({
    this.id,
    required this.title,
    this.description,
    this.assignedTo,
    this.assignedToName,
    required this.priority,
    required this.category,
    required this.estimatedHours,
    required this.recurrencePattern,
    required this.startDate,
    this.lastGenerated,
    this.nextDue,
    this.isActive = true,
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
    this.updatedAt,
    this.tags = const [],
    this.generatedCount = 0,
  });

  factory RecurringTask.fromJson(Map<String, dynamic> json) {
    return RecurringTask(
      id: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String?,
      assignedTo: json['assigned_to'] ?? json['assignedTo'] as int?,
      assignedToName: json['assigned_to_name'] ?? json['assignedToName'] as String?,
      priority: TaskPriority.values.byName(json['priority'] as String),
      category: TaskCategory.values.byName(json['category'] as String),
      estimatedHours: (json['estimated_hours'] ?? json['estimatedHours'] as num).toDouble(),
      recurrencePattern: RecurrencePattern.fromJson(
        json['recurrence_pattern'] ?? json['recurrencePattern'] as Map<String, dynamic>
      ),
      startDate: DateTime.parse(json['start_date'] ?? json['startDate'] as String),
      lastGenerated: json['last_generated'] != null 
          ? DateTime.parse(json['last_generated'] ?? json['lastGenerated'] as String)
          : null,
      nextDue: json['next_due'] != null 
          ? DateTime.parse(json['next_due'] ?? json['nextDue'] as String)
          : null,
      isActive: json['is_active'] ?? json['isActive'] as bool? ?? true,
      createdBy: json['created_by'] ?? json['createdBy'] as int,
      createdByName: json['created_by_name'] ?? json['createdByName'] as String?,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] ?? json['updatedAt'] as String)
          : null,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      generatedCount: json['generated_count'] ?? json['generatedCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assigned_to': assignedTo,
      'assigned_to_name': assignedToName,
      'priority': priority.name,
      'category': category.name,
      'estimated_hours': estimatedHours,
      'recurrence_pattern': recurrencePattern.toJson(),
      'start_date': startDate.toIso8601String(),
      'last_generated': lastGenerated?.toIso8601String(),
      'next_due': nextDue?.toIso8601String(),
      'is_active': isActive,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'tags': tags,
      'generated_count': generatedCount,
    };
  }

  RecurringTask copyWith({
    int? id,
    String? title,
    String? description,
    int? assignedTo,
    String? assignedToName,
    TaskPriority? priority,
    TaskCategory? category,
    double? estimatedHours,
    RecurrencePattern? recurrencePattern,
    DateTime? startDate,
    DateTime? lastGenerated,
    DateTime? nextDue,
    bool? isActive,
    int? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    int? generatedCount,
  }) {
    return RecurringTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      startDate: startDate ?? this.startDate,
      lastGenerated: lastGenerated ?? this.lastGenerated,
      nextDue: nextDue ?? this.nextDue,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      generatedCount: generatedCount ?? this.generatedCount,
    );
  }

  // Computed properties
  bool get isDue => nextDue != null && nextDue!.isBefore(DateTime.now());
  bool get hasEndDate => recurrencePattern.endDate != null;
  bool get hasMaxOccurrences => recurrencePattern.maxOccurrences != null;
  
  bool get shouldStop {
    if (!isActive) return true;
    if (hasEndDate && DateTime.now().isAfter(recurrencePattern.endDate!)) return true;
    if (hasMaxOccurrences && generatedCount >= recurrencePattern.maxOccurrences!) return true;
    return false;
  }

  String get statusText {
    if (!isActive) return 'Paused';
    if (shouldStop) return 'Completed';
    if (isDue) return 'Due';
    return 'Active';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTask &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RecurringTask{id: $id, title: $title, pattern: ${recurrencePattern.displayText}, isActive: $isActive}';
  }
}