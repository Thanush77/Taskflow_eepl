class ManagerDashboardData {
  final List<TaskStatusStat> taskStats;
  final List<EmployeeStat> employeeStats;
  final List<OverdueTask> overdueTasks;
  final List<RecentActivity> recentActivity;
  final List<ProductivityMetric> productivityMetrics;

  ManagerDashboardData({
    required this.taskStats,
    required this.employeeStats,
    required this.overdueTasks,
    required this.recentActivity,
    required this.productivityMetrics,
  });

  factory ManagerDashboardData.fromJson(Map<String, dynamic> json) {
    return ManagerDashboardData(
      taskStats: (json['taskStats'] as List?)
          ?.map((item) => TaskStatusStat.fromJson(item))
          .toList() ?? [],
      employeeStats: (json['employeeStats'] as List?)
          ?.map((item) => EmployeeStat.fromJson(item))
          .toList() ?? [],
      overdueTasks: (json['overdueTasks'] as List?)
          ?.map((item) => OverdueTask.fromJson(item))
          .toList() ?? [],
      recentActivity: (json['recentActivity'] as List?)
          ?.map((item) => RecentActivity.fromJson(item))
          .toList() ?? [],
      productivityMetrics: (json['productivityMetrics'] as List?)
          ?.map((item) => ProductivityMetric.fromJson(item))
          .toList() ?? [],
    );
  }
}

class TaskStatusStat {
  final String status;
  final int count;

  TaskStatusStat({
    required this.status,
    required this.count,
  });

  factory TaskStatusStat.fromJson(Map<String, dynamic> json) {
    return TaskStatusStat(
      status: json['status'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class EmployeeStat {
  final int id;
  final String fullName;
  final String email;
  final int totalTasks;
  final int completedTasks;
  final int activeTasks;
  final int pendingTasks;

  EmployeeStat({
    required this.id,
    required this.fullName,
    required this.email,
    required this.totalTasks,
    required this.completedTasks,
    required this.activeTasks,
    required this.pendingTasks,
  });

  double get completionRate {
    return totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;
  }

  factory EmployeeStat.fromJson(Map<String, dynamic> json) {
    return EmployeeStat(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      totalTasks: json['total_tasks'] ?? 0,
      completedTasks: json['completed_tasks'] ?? 0,
      activeTasks: json['active_tasks'] ?? 0,
      pendingTasks: json['pending_tasks'] ?? 0,
    );
  }
}

class OverdueTask {
  final int id;
  final String title;
  final DateTime? dueDate;
  final String priority;
  final String? assignedToName;

  OverdueTask({
    required this.id,
    required this.title,
    this.dueDate,
    required this.priority,
    this.assignedToName,
  });

  factory OverdueTask.fromJson(Map<String, dynamic> json) {
    return OverdueTask(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      priority: json['priority'] ?? 'medium',
      assignedToName: json['assigned_to_name'],
    );
  }
}

class RecentActivity {
  final int id;
  final String title;
  final String status;
  final DateTime updatedAt;
  final String? assignedToName;
  final String? createdByName;

  RecentActivity({
    required this.id,
    required this.title,
    required this.status,
    required this.updatedAt,
    this.assignedToName,
    this.createdByName,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      status: json['status'] ?? '',
      updatedAt: DateTime.parse(json['updated_at']),
      assignedToName: json['assigned_to_name'],
      createdByName: json['created_by_name'],
    );
  }
}

class ProductivityMetric {
  final DateTime date;
  final int completedCount;
  final int totalCount;

  ProductivityMetric({
    required this.date,
    required this.completedCount,
    required this.totalCount,
  });

  double get completionRate {
    return totalCount > 0 ? (completedCount / totalCount) * 100 : 0.0;
  }

  factory ProductivityMetric.fromJson(Map<String, dynamic> json) {
    return ProductivityMetric(
      date: DateTime.parse(json['date']),
      completedCount: json['completed_count'] ?? 0,
      totalCount: json['total_count'] ?? 0,
    );
  }
}

class EmployeePerformance {
  final Employee employee;
  final PerformanceStats taskStats;
  final List<MonthlyPerformance> monthlyPerformance;
  final List<PriorityBreakdown> priorityBreakdown;
  final List<ManagerTask> recentTasks;

  EmployeePerformance({
    required this.employee,
    required this.taskStats,
    required this.monthlyPerformance,
    required this.priorityBreakdown,
    required this.recentTasks,
  });

  factory EmployeePerformance.fromJson(Map<String, dynamic> json) {
    return EmployeePerformance(
      employee: Employee.fromJson(json['employee']),
      taskStats: PerformanceStats.fromJson(json['taskStats']),
      monthlyPerformance: (json['monthlyPerformance'] as List?)
          ?.map((item) => MonthlyPerformance.fromJson(item))
          .toList() ?? [],
      priorityBreakdown: (json['priorityBreakdown'] as List?)
          ?.map((item) => PriorityBreakdown.fromJson(item))
          .toList() ?? [],
      recentTasks: (json['recentTasks'] as List?)
          ?.map((item) => ManagerTask.fromJson(item))
          .toList() ?? [],
    );
  }
}

class Employee {
  final int id;
  final String fullName;
  final String email;
  final DateTime createdAt;

  Employee({
    required this.id,
    required this.fullName,
    required this.email,
    required this.createdAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class PerformanceStats {
  final int totalTasks;
  final int completedTasks;
  final int inProgressTasks;
  final int pendingTasks;
  final int overdueTasks;
  final double? avgCompletionHours;

  PerformanceStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.inProgressTasks,
    required this.pendingTasks,
    required this.overdueTasks,
    this.avgCompletionHours,
  });

  double get completionRate {
    return totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;
  }

  factory PerformanceStats.fromJson(Map<String, dynamic> json) {
    return PerformanceStats(
      totalTasks: json['total_tasks'] ?? 0,
      completedTasks: json['completed_tasks'] ?? 0,
      inProgressTasks: json['in_progress_tasks'] ?? 0,
      pendingTasks: json['pending_tasks'] ?? 0,
      overdueTasks: json['overdue_tasks'] ?? 0,
      avgCompletionHours: json['avg_completion_hours']?.toDouble(),
    );
  }
}

class MonthlyPerformance {
  final DateTime month;
  final int tasksAssigned;
  final int tasksCompleted;

  MonthlyPerformance({
    required this.month,
    required this.tasksAssigned,
    required this.tasksCompleted,
  });

  factory MonthlyPerformance.fromJson(Map<String, dynamic> json) {
    return MonthlyPerformance(
      month: DateTime.parse(json['month']),
      tasksAssigned: json['tasks_assigned'] ?? 0,
      tasksCompleted: json['tasks_completed'] ?? 0,
    );
  }
}

class PriorityBreakdown {
  final String priority;
  final int count;
  final int completedCount;

  PriorityBreakdown({
    required this.priority,
    required this.count,
    required this.completedCount,
  });

  factory PriorityBreakdown.fromJson(Map<String, dynamic> json) {
    return PriorityBreakdown(
      priority: json['priority'] ?? '',
      count: json['count'] ?? 0,
      completedCount: json['completed_count'] ?? 0,
    );
  }
}

class ManagerTask {
  final int id;
  final String title;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  ManagerTask({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ManagerTask.fromJson(Map<String, dynamic> json) {
    return ManagerTask(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      status: json['status'] ?? '',
      priority: json['priority'] ?? 'medium',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class TasksResponse {
  final List<ManagerTaskDetailed> tasks;
  final TasksPagination pagination;

  TasksResponse({
    required this.tasks,
    required this.pagination,
  });

  factory TasksResponse.fromJson(Map<String, dynamic> json) {
    return TasksResponse(
      tasks: (json['tasks'] as List?)
          ?.map((item) => ManagerTaskDetailed.fromJson(item))
          .toList() ?? [],
      pagination: TasksPagination.fromJson(json['pagination']),
    );
  }
}

class ManagerTaskDetailed {
  final int id;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? estimatedHours;
  final String? assignedToName;
  final String? assignedToEmail;
  final String? createdByName;

  ManagerTaskDetailed({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.estimatedHours,
    this.assignedToName,
    this.assignedToEmail,
    this.createdByName,
  });

  factory ManagerTaskDetailed.fromJson(Map<String, dynamic> json) {
    return ManagerTaskDetailed(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? '',
      priority: json['priority'] ?? 'medium',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      estimatedHours: json['estimated_hours']?.toDouble(),
      assignedToName: json['assigned_to_name'],
      assignedToEmail: json['assigned_to_email'],
      createdByName: json['created_by_name'],
    );
  }
}

class TasksPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  TasksPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory TasksPagination.fromJson(Map<String, dynamic> json) {
    return TasksPagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}