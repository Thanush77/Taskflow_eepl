class DashboardStats {
  final int totalTasks;
  final int pendingTasks;
  final int inProgressTasks;
  final int completedTasks;
  final int overdueTasks;
  final int myTasks;
  final double completionRate;
  final double productivityScore;
  final List<TaskTrend> weeklyTrends;
  final List<CategoryStats> categoryBreakdown;
  final List<PriorityStats> priorityDistribution;
  final List<TeamMemberStats> teamPerformance;
  final DateTime lastUpdated;

  DashboardStats({
    this.totalTasks = 0,
    this.pendingTasks = 0,
    this.inProgressTasks = 0,
    this.completedTasks = 0,
    this.overdueTasks = 0,
    this.myTasks = 0,
    this.completionRate = 0.0,
    this.productivityScore = 0.0,
    this.weeklyTrends = const [],
    this.categoryBreakdown = const [],
    this.priorityDistribution = const [],
    this.teamPerformance = const [],
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalTasks: json['totalTasks'] ?? 0,
      pendingTasks: json['pendingTasks'] ?? 0,
      inProgressTasks: json['inProgressTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      overdueTasks: json['overdueTasks'] ?? 0,
      myTasks: json['myTasks'] ?? 0,
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
      productivityScore: (json['productivityScore'] ?? 0.0).toDouble(),
      weeklyTrends: (json['weeklyTrends'] as List<dynamic>?)
          ?.map((item) => TaskTrend.fromJson(item))
          .toList() ?? [],
      categoryBreakdown: (json['categoryBreakdown'] as List<dynamic>?)
          ?.map((item) => CategoryStats.fromJson(item))
          .toList() ?? [],
      priorityDistribution: (json['priorityDistribution'] as List<dynamic>?)
          ?.map((item) => PriorityStats.fromJson(item))
          .toList() ?? [],
      teamPerformance: (json['teamPerformance'] as List<dynamic>?)
          ?.map((item) => TeamMemberStats.fromJson(item))
          .toList() ?? [],
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTasks': totalTasks,
      'pendingTasks': pendingTasks,
      'inProgressTasks': inProgressTasks,
      'completedTasks': completedTasks,
      'overdueTasks': overdueTasks,
      'myTasks': myTasks,
      'completionRate': completionRate,
      'productivityScore': productivityScore,
      'weeklyTrends': weeklyTrends.map((t) => t.toJson()).toList(),
      'categoryBreakdown': categoryBreakdown.map((c) => c.toJson()).toList(),
      'priorityDistribution': priorityDistribution.map((p) => p.toJson()).toList(),
      'teamPerformance': teamPerformance.map((t) => t.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  DashboardStats copyWith({
    int? totalTasks,
    int? pendingTasks,
    int? inProgressTasks,
    int? completedTasks,
    int? overdueTasks,
    int? myTasks,
    double? completionRate,
    double? productivityScore,
    List<TaskTrend>? weeklyTrends,
    List<CategoryStats>? categoryBreakdown,
    List<PriorityStats>? priorityDistribution,
    List<TeamMemberStats>? teamPerformance,
    DateTime? lastUpdated,
  }) {
    return DashboardStats(
      totalTasks: totalTasks ?? this.totalTasks,
      pendingTasks: pendingTasks ?? this.pendingTasks,
      inProgressTasks: inProgressTasks ?? this.inProgressTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      overdueTasks: overdueTasks ?? this.overdueTasks,
      myTasks: myTasks ?? this.myTasks,
      completionRate: completionRate ?? this.completionRate,
      productivityScore: productivityScore ?? this.productivityScore,
      weeklyTrends: weeklyTrends ?? this.weeklyTrends,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      priorityDistribution: priorityDistribution ?? this.priorityDistribution,
      teamPerformance: teamPerformance ?? this.teamPerformance,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class TaskTrend {
  final DateTime date;
  final int completed;
  final int created;
  final int inProgress;

  const TaskTrend({
    required this.date,
    this.completed = 0,
    this.created = 0,
    this.inProgress = 0,
  });

  factory TaskTrend.fromJson(Map<String, dynamic> json) {
    return TaskTrend(
      date: DateTime.parse(json['date']),
      completed: json['completed'] ?? 0,
      created: json['created'] ?? 0,
      inProgress: json['inProgress'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'completed': completed,
      'created': created,
      'inProgress': inProgress,
    };
  }
}

class CategoryStats {
  final String category;
  final int count;
  final double percentage;
  final int completed;
  final double completionRate;

  const CategoryStats({
    required this.category,
    this.count = 0,
    this.percentage = 0.0,
    this.completed = 0,
    this.completionRate = 0.0,
  });

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    return CategoryStats(
      category: json['category'],
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
      completed: json['completed'] ?? 0,
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'count': count,
      'percentage': percentage,
      'completed': completed,
      'completionRate': completionRate,
    };
  }
}

class PriorityStats {
  final String priority;
  final int count;
  final double percentage;
  final int overdue;

  const PriorityStats({
    required this.priority,
    this.count = 0,
    this.percentage = 0.0,
    this.overdue = 0,
  });

  factory PriorityStats.fromJson(Map<String, dynamic> json) {
    return PriorityStats(
      priority: json['priority'],
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
      overdue: json['overdue'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'priority': priority,
      'count': count,
      'percentage': percentage,
      'overdue': overdue,
    };
  }
}

class TeamMemberStats {
  final int userId;
  final String name;
  final int assignedTasks;
  final int completedTasks;
  final double completionRate;
  final double avgTaskTime;
  final bool isOnline;

  const TeamMemberStats({
    required this.userId,
    required this.name,
    this.assignedTasks = 0,
    this.completedTasks = 0,
    this.completionRate = 0.0,
    this.avgTaskTime = 0.0,
    this.isOnline = false,
  });

  factory TeamMemberStats.fromJson(Map<String, dynamic> json) {
    return TeamMemberStats(
      userId: json['userId'],
      name: json['name'],
      assignedTasks: json['assignedTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
      avgTaskTime: (json['avgTaskTime'] ?? 0.0).toDouble(),
      isOnline: json['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'assignedTasks': assignedTasks,
      'completedTasks': completedTasks,
      'completionRate': completionRate,
      'avgTaskTime': avgTaskTime,
      'isOnline': isOnline,
    };
  }
}

class RealTimeMetrics {
  final int activeUsers;
  final int tasksInProgress;
  final int recentUpdates;
  final List<RecentActivity> recentActivities;
  final DateTime timestamp;

  RealTimeMetrics({
    this.activeUsers = 0,
    this.tasksInProgress = 0,
    this.recentUpdates = 0,
    this.recentActivities = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory RealTimeMetrics.fromJson(Map<String, dynamic> json) {
    return RealTimeMetrics(
      activeUsers: json['activeUsers'] ?? 0,
      tasksInProgress: json['tasksInProgress'] ?? 0,
      recentUpdates: json['recentUpdates'] ?? 0,
      recentActivities: (json['recentActivities'] as List<dynamic>?)
          ?.map((item) => RecentActivity.fromJson(item))
          .toList() ?? [],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeUsers': activeUsers,
      'tasksInProgress': tasksInProgress,
      'recentUpdates': recentUpdates,
      'recentActivities': recentActivities.map((a) => a.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class RecentActivity {
  final String type;
  final String description;
  final String userName;
  final DateTime timestamp;
  final int? taskId;
  final String? taskTitle;

  const RecentActivity({
    required this.type,
    required this.description,
    required this.userName,
    required this.timestamp,
    this.taskId,
    this.taskTitle,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      type: json['type'],
      description: json['description'],
      userName: json['userName'],
      timestamp: DateTime.parse(json['timestamp']),
      taskId: json['taskId'],
      taskTitle: json['taskTitle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'userName': userName,
      'timestamp': timestamp.toIso8601String(),
      if (taskId != null) 'taskId': taskId,
      if (taskTitle != null) 'taskTitle': taskTitle,
    };
  }
}