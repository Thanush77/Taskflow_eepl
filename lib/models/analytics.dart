import 'package:flutter/material.dart';

// Main analytics data model
class AnalyticsData {
  final TaskAnalytics taskAnalytics;
  final ProductivityAnalytics productivityAnalytics;
  final TeamAnalytics teamAnalytics;
  final TimeAnalytics timeAnalytics;
  final ProjectAnalytics projectAnalytics;
  final DateTime generatedAt;

  AnalyticsData({
    required this.taskAnalytics,
    required this.productivityAnalytics,
    required this.teamAnalytics,
    required this.timeAnalytics,
    required this.projectAnalytics,
    required this.generatedAt,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      taskAnalytics: TaskAnalytics.fromJson(json['taskAnalytics'] ?? {}),
      productivityAnalytics: ProductivityAnalytics.fromJson(json['productivityAnalytics'] ?? {}),
      teamAnalytics: TeamAnalytics.fromJson(json['teamAnalytics'] ?? {}),
      timeAnalytics: TimeAnalytics.fromJson(json['timeAnalytics'] ?? {}),
      projectAnalytics: ProjectAnalytics.fromJson(json['projectAnalytics'] ?? {}),
      generatedAt: DateTime.tryParse(json['generatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskAnalytics': taskAnalytics.toJson(),
      'productivityAnalytics': productivityAnalytics.toJson(),
      'teamAnalytics': teamAnalytics.toJson(),
      'timeAnalytics': timeAnalytics.toJson(),
      'projectAnalytics': projectAnalytics.toJson(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}

// Task-specific analytics
class TaskAnalytics {
  final TaskCompletionStats completionStats;
  final TaskDistributionStats distributionStats;
  final TaskTrendStats trendStats;
  final List<TaskMetric> metrics;

  TaskAnalytics({
    required this.completionStats,
    required this.distributionStats,
    required this.trendStats,
    required this.metrics,
  });

  factory TaskAnalytics.fromJson(Map<String, dynamic> json) {
    return TaskAnalytics(
      completionStats: TaskCompletionStats.fromJson(json['completionStats'] ?? {}),
      distributionStats: TaskDistributionStats.fromJson(json['distributionStats'] ?? {}),
      trendStats: TaskTrendStats.fromJson(json['trendStats'] ?? {}),
      metrics: (json['metrics'] as List<dynamic>?)
          ?.map((item) => TaskMetric.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completionStats': completionStats.toJson(),
      'distributionStats': distributionStats.toJson(),
      'trendStats': trendStats.toJson(),
      'metrics': metrics.map((metric) => metric.toJson()).toList(),
    };
  }
}

// Task completion statistics
class TaskCompletionStats {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int inProgressTasks;
  final int overdueTasks;
  final double completionRate;
  final double onTimeCompletionRate;
  final int averageCompletionDays;

  TaskCompletionStats({
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.pendingTasks = 0,
    this.inProgressTasks = 0,
    this.overdueTasks = 0,
    this.completionRate = 0.0,
    this.onTimeCompletionRate = 0.0,
    this.averageCompletionDays = 0,
  });

  factory TaskCompletionStats.fromJson(Map<String, dynamic> json) {
    return TaskCompletionStats(
      totalTasks: json['totalTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      pendingTasks: json['pendingTasks'] ?? 0,
      inProgressTasks: json['inProgressTasks'] ?? 0,
      overdueTasks: json['overdueTasks'] ?? 0,
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
      onTimeCompletionRate: (json['onTimeCompletionRate'] ?? 0.0).toDouble(),
      averageCompletionDays: json['averageCompletionDays'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'pendingTasks': pendingTasks,
      'inProgressTasks': inProgressTasks,
      'overdueTasks': overdueTasks,
      'completionRate': completionRate,
      'onTimeCompletionRate': onTimeCompletionRate,
      'averageCompletionDays': averageCompletionDays,
    };
  }
}

// Task distribution statistics
class TaskDistributionStats {
  final List<CategoryDistribution> byCategory;
  final List<PriorityDistribution> byPriority;
  final List<StatusDistribution> byStatus;
  final List<AssigneeDistribution> byAssignee;

  TaskDistributionStats({
    this.byCategory = const [],
    this.byPriority = const [],
    this.byStatus = const [],
    this.byAssignee = const [],
  });

  factory TaskDistributionStats.fromJson(Map<String, dynamic> json) {
    return TaskDistributionStats(
      byCategory: (json['byCategory'] as List<dynamic>?)
          ?.map((item) => CategoryDistribution.fromJson(item))
          .toList() ?? [],
      byPriority: (json['byPriority'] as List<dynamic>?)
          ?.map((item) => PriorityDistribution.fromJson(item))
          .toList() ?? [],
      byStatus: (json['byStatus'] as List<dynamic>?)
          ?.map((item) => StatusDistribution.fromJson(item))
          .toList() ?? [],
      byAssignee: (json['byAssignee'] as List<dynamic>?)
          ?.map((item) => AssigneeDistribution.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'byCategory': byCategory.map((item) => item.toJson()).toList(),
      'byPriority': byPriority.map((item) => item.toJson()).toList(),
      'byStatus': byStatus.map((item) => item.toJson()).toList(),
      'byAssignee': byAssignee.map((item) => item.toJson()).toList(),
    };
  }
}

// Category distribution model
class CategoryDistribution {
  final String category;
  final int count;
  final double percentage;
  final Color color;

  CategoryDistribution({
    required this.category,
    required this.count,
    required this.percentage,
    this.color = Colors.blue,
  });

  factory CategoryDistribution.fromJson(Map<String, dynamic> json) {
    return CategoryDistribution(
      category: json['category'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
      color: _parseColor(json['color']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'count': count,
      'percentage': percentage,
      'color': color.toARGB32().toRadixString(16),
    };
  }

  static Color _parseColor(dynamic colorValue) {
    if (colorValue is int) return Color(colorValue);
    if (colorValue is String) {
      final intValue = int.tryParse(colorValue, radix: 16) ?? 0xFF2196F3;
      return Color(intValue);
    }
    return Colors.blue;
  }
}

// Priority distribution model
class PriorityDistribution {
  final String priority;
  final int count;
  final double percentage;
  final Color color;

  PriorityDistribution({
    required this.priority,
    required this.count,
    required this.percentage,
    this.color = Colors.orange,
  });

  factory PriorityDistribution.fromJson(Map<String, dynamic> json) {
    return PriorityDistribution(
      priority: json['priority'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
      color: CategoryDistribution._parseColor(json['color']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'priority': priority,
      'count': count,
      'percentage': percentage,
      'color': color.toARGB32().toRadixString(16),
    };
  }
}

// Status distribution model
class StatusDistribution {
  final String status;
  final int count;
  final double percentage;
  final Color color;

  StatusDistribution({
    required this.status,
    required this.count,
    required this.percentage,
    this.color = Colors.green,
  });

  factory StatusDistribution.fromJson(Map<String, dynamic> json) {
    return StatusDistribution(
      status: json['status'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
      color: CategoryDistribution._parseColor(json['color']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'count': count,
      'percentage': percentage,
      'color': color.toARGB32().toRadixString(16),
    };
  }
}

// Assignee distribution model
class AssigneeDistribution {
  final String assigneeName;
  final int assigneeId;
  final int assignedCount;
  final int completedCount;
  final double completionRate;

  AssigneeDistribution({
    required this.assigneeName,
    required this.assigneeId,
    required this.assignedCount,
    required this.completedCount,
    required this.completionRate,
  });

  factory AssigneeDistribution.fromJson(Map<String, dynamic> json) {
    return AssigneeDistribution(
      assigneeName: json['assigneeName'] ?? '',
      assigneeId: json['assigneeId'] ?? 0,
      assignedCount: json['assignedCount'] ?? 0,
      completedCount: json['completedCount'] ?? 0,
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assigneeName': assigneeName,
      'assigneeId': assigneeId,
      'assignedCount': assignedCount,
      'completedCount': completedCount,
      'completionRate': completionRate,
    };
  }
}

// Task trend statistics
class TaskTrendStats {
  final List<DailyTaskTrend> dailyTrends;
  final List<WeeklyTaskTrend> weeklyTrends;
  final List<MonthlyTaskTrend> monthlyTrends;
  final TrendDirection completionTrend;
  final TrendDirection creationTrend;

  TaskTrendStats({
    this.dailyTrends = const [],
    this.weeklyTrends = const [],
    this.monthlyTrends = const [],
    this.completionTrend = TrendDirection.stable,
    this.creationTrend = TrendDirection.stable,
  });

  factory TaskTrendStats.fromJson(Map<String, dynamic> json) {
    return TaskTrendStats(
      dailyTrends: (json['dailyTrends'] as List<dynamic>?)
          ?.map((item) => DailyTaskTrend.fromJson(item))
          .toList() ?? [],
      weeklyTrends: (json['weeklyTrends'] as List<dynamic>?)
          ?.map((item) => WeeklyTaskTrend.fromJson(item))
          .toList() ?? [],
      monthlyTrends: (json['monthlyTrends'] as List<dynamic>?)
          ?.map((item) => MonthlyTaskTrend.fromJson(item))
          .toList() ?? [],
      completionTrend: TrendDirection.values.firstWhere(
        (e) => e.toString().split('.').last == json['completionTrend'],
        orElse: () => TrendDirection.stable,
      ),
      creationTrend: TrendDirection.values.firstWhere(
        (e) => e.toString().split('.').last == json['creationTrend'],
        orElse: () => TrendDirection.stable,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyTrends': dailyTrends.map((trend) => trend.toJson()).toList(),
      'weeklyTrends': weeklyTrends.map((trend) => trend.toJson()).toList(),
      'monthlyTrends': monthlyTrends.map((trend) => trend.toJson()).toList(),
      'completionTrend': completionTrend.toString().split('.').last,
      'creationTrend': creationTrend.toString().split('.').last,
    };
  }
}

// Daily task trend
class DailyTaskTrend {
  final DateTime date;
  final int created;
  final int completed;
  final int inProgress;

  DailyTaskTrend({
    required this.date,
    required this.created,
    required this.completed,
    required this.inProgress,
  });

  factory DailyTaskTrend.fromJson(Map<String, dynamic> json) {
    return DailyTaskTrend(
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      created: json['created'] ?? 0,
      completed: json['completed'] ?? 0,
      inProgress: json['inProgress'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'created': created,
      'completed': completed,
      'inProgress': inProgress,
    };
  }
}

// Weekly task trend
class WeeklyTaskTrend {
  final DateTime weekStartDate;
  final int created;
  final int completed;
  final int inProgress;
  final double completionRate;

  WeeklyTaskTrend({
    required this.weekStartDate,
    required this.created,
    required this.completed,
    required this.inProgress,
    required this.completionRate,
  });

  factory WeeklyTaskTrend.fromJson(Map<String, dynamic> json) {
    return WeeklyTaskTrend(
      weekStartDate: DateTime.tryParse(json['weekStartDate'] ?? '') ?? DateTime.now(),
      created: json['created'] ?? 0,
      completed: json['completed'] ?? 0,
      inProgress: json['inProgress'] ?? 0,
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekStartDate': weekStartDate.toIso8601String(),
      'created': created,
      'completed': completed,
      'inProgress': inProgress,
      'completionRate': completionRate,
    };
  }
}

// Monthly task trend
class MonthlyTaskTrend {
  final DateTime month;
  final int created;
  final int completed;
  final int inProgress;
  final double completionRate;
  final double productivityScore;

  MonthlyTaskTrend({
    required this.month,
    required this.created,
    required this.completed,
    required this.inProgress,
    required this.completionRate,
    required this.productivityScore,
  });

  factory MonthlyTaskTrend.fromJson(Map<String, dynamic> json) {
    return MonthlyTaskTrend(
      month: DateTime.tryParse(json['month'] ?? '') ?? DateTime.now(),
      created: json['created'] ?? 0,
      completed: json['completed'] ?? 0,
      inProgress: json['inProgress'] ?? 0,
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
      productivityScore: (json['productivityScore'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month.toIso8601String(),
      'created': created,
      'completed': completed,
      'inProgress': inProgress,
      'completionRate': completionRate,
      'productivityScore': productivityScore,
    };
  }
}

// Task metric model
class TaskMetric {
  final String name;
  final double value;
  final String unit;
  final MetricType type;
  final TrendDirection trend;
  final double changePercentage;

  TaskMetric({
    required this.name,
    required this.value,
    this.unit = '',
    required this.type,
    this.trend = TrendDirection.stable,
    this.changePercentage = 0.0,
  });

  factory TaskMetric.fromJson(Map<String, dynamic> json) {
    return TaskMetric(
      name: json['name'] ?? '',
      value: (json['value'] ?? 0.0).toDouble(),
      unit: json['unit'] ?? '',
      type: MetricType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => MetricType.count,
      ),
      trend: TrendDirection.values.firstWhere(
        (e) => e.toString().split('.').last == json['trend'],
        orElse: () => TrendDirection.stable,
      ),
      changePercentage: (json['changePercentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'unit': unit,
      'type': type.toString().split('.').last,
      'trend': trend.toString().split('.').last,
      'changePercentage': changePercentage,
    };
  }
}

// Productivity analytics
class ProductivityAnalytics {
  final double overallProductivityScore;
  final List<ProductivityFactor> factors;
  final List<ProductivityTrend> trends;
  final ProductivityInsights insights;

  ProductivityAnalytics({
    this.overallProductivityScore = 0.0,
    this.factors = const [],
    this.trends = const [],
    required this.insights,
  });

  factory ProductivityAnalytics.fromJson(Map<String, dynamic> json) {
    return ProductivityAnalytics(
      overallProductivityScore: (json['overallProductivityScore'] ?? 0.0).toDouble(),
      factors: (json['factors'] as List<dynamic>?)
          ?.map((item) => ProductivityFactor.fromJson(item))
          .toList() ?? [],
      trends: (json['trends'] as List<dynamic>?)
          ?.map((item) => ProductivityTrend.fromJson(item))
          .toList() ?? [],
      insights: ProductivityInsights.fromJson(json['insights'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallProductivityScore': overallProductivityScore,
      'factors': factors.map((factor) => factor.toJson()).toList(),
      'trends': trends.map((trend) => trend.toJson()).toList(),
      'insights': insights.toJson(),
    };
  }
}

// Productivity factor
class ProductivityFactor {
  final String name;
  final double score;
  final double weight;
  final String description;

  ProductivityFactor({
    required this.name,
    required this.score,
    required this.weight,
    required this.description,
  });

  factory ProductivityFactor.fromJson(Map<String, dynamic> json) {
    return ProductivityFactor(
      name: json['name'] ?? '',
      score: (json['score'] ?? 0.0).toDouble(),
      weight: (json['weight'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'score': score,
      'weight': weight,
      'description': description,
    };
  }
}

// Productivity trend
class ProductivityTrend {
  final DateTime date;
  final double score;
  final Map<String, double> factorScores;

  ProductivityTrend({
    required this.date,
    required this.score,
    this.factorScores = const {},
  });

  factory ProductivityTrend.fromJson(Map<String, dynamic> json) {
    return ProductivityTrend(
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      score: (json['score'] ?? 0.0).toDouble(),
      factorScores: Map<String, double>.from(json['factorScores'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'score': score,
      'factorScores': factorScores,
    };
  }
}

// Productivity insights
class ProductivityInsights {
  final List<String> strengths;
  final List<String> improvements;
  final List<String> recommendations;
  final double burnoutRisk;
  final String workloadStatus;

  ProductivityInsights({
    this.strengths = const [],
    this.improvements = const [],
    this.recommendations = const [],
    this.burnoutRisk = 0.0,
    this.workloadStatus = 'balanced',
  });

  factory ProductivityInsights.fromJson(Map<String, dynamic> json) {
    return ProductivityInsights(
      strengths: List<String>.from(json['strengths'] ?? []),
      improvements: List<String>.from(json['improvements'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      burnoutRisk: (json['burnoutRisk'] ?? 0.0).toDouble(),
      workloadStatus: json['workloadStatus'] ?? 'balanced',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'strengths': strengths,
      'improvements': improvements,
      'recommendations': recommendations,
      'burnoutRisk': burnoutRisk,
      'workloadStatus': workloadStatus,
    };
  }
}

// Team analytics
class TeamAnalytics {
  final List<TeamMemberPerformance> memberPerformance;
  final TeamCollaborationStats collaborationStats;
  final TeamProductivityStats productivityStats;

  TeamAnalytics({
    this.memberPerformance = const [],
    required this.collaborationStats,
    required this.productivityStats,
  });

  factory TeamAnalytics.fromJson(Map<String, dynamic> json) {
    return TeamAnalytics(
      memberPerformance: (json['memberPerformance'] as List<dynamic>?)
          ?.map((item) => TeamMemberPerformance.fromJson(item))
          .toList() ?? [],
      collaborationStats: TeamCollaborationStats.fromJson(json['collaborationStats'] ?? {}),
      productivityStats: TeamProductivityStats.fromJson(json['productivityStats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memberPerformance': memberPerformance.map((member) => member.toJson()).toList(),
      'collaborationStats': collaborationStats.toJson(),
      'productivityStats': productivityStats.toJson(),
    };
  }
}

// Team member performance
class TeamMemberPerformance {
  final int userId;
  final String name;
  final int assignedTasks;
  final int completedTasks;
  final double completionRate;
  final double averageTaskDuration;
  final int commentsCount;
  final double collaborationScore;

  TeamMemberPerformance({
    required this.userId,
    required this.name,
    required this.assignedTasks,
    required this.completedTasks,
    required this.completionRate,
    required this.averageTaskDuration,
    required this.commentsCount,
    required this.collaborationScore,
  });

  factory TeamMemberPerformance.fromJson(Map<String, dynamic> json) {
    return TeamMemberPerformance(
      userId: json['userId'] ?? 0,
      name: json['name'] ?? '',
      assignedTasks: json['assignedTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
      averageTaskDuration: (json['averageTaskDuration'] ?? 0.0).toDouble(),
      commentsCount: json['commentsCount'] ?? 0,
      collaborationScore: (json['collaborationScore'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'assignedTasks': assignedTasks,
      'completedTasks': completedTasks,
      'completionRate': completionRate,
      'averageTaskDuration': averageTaskDuration,
      'commentsCount': commentsCount,
      'collaborationScore': collaborationScore,
    };
  }
}

// Team collaboration stats
class TeamCollaborationStats {
  final int totalComments;
  final int totalMentions;
  final int activeCollaborations;
  final double averageResponseTime;

  TeamCollaborationStats({
    this.totalComments = 0,
    this.totalMentions = 0,
    this.activeCollaborations = 0,
    this.averageResponseTime = 0.0,
  });

  factory TeamCollaborationStats.fromJson(Map<String, dynamic> json) {
    return TeamCollaborationStats(
      totalComments: json['totalComments'] ?? 0,
      totalMentions: json['totalMentions'] ?? 0,
      activeCollaborations: json['activeCollaborations'] ?? 0,
      averageResponseTime: (json['averageResponseTime'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalComments': totalComments,
      'totalMentions': totalMentions,
      'activeCollaborations': activeCollaborations,
      'averageResponseTime': averageResponseTime,
    };
  }
}

// Team productivity stats
class TeamProductivityStats {
  final double overallTeamScore;
  final int totalTeamTasks;
  final int completedTeamTasks;
  final double teamCompletionRate;
  final int averageTasksPerMember;

  TeamProductivityStats({
    this.overallTeamScore = 0.0,
    this.totalTeamTasks = 0,
    this.completedTeamTasks = 0,
    this.teamCompletionRate = 0.0,
    this.averageTasksPerMember = 0,
  });

  factory TeamProductivityStats.fromJson(Map<String, dynamic> json) {
    return TeamProductivityStats(
      overallTeamScore: (json['overallTeamScore'] ?? 0.0).toDouble(),
      totalTeamTasks: json['totalTeamTasks'] ?? 0,
      completedTeamTasks: json['completedTeamTasks'] ?? 0,
      teamCompletionRate: (json['teamCompletionRate'] ?? 0.0).toDouble(),
      averageTasksPerMember: json['averageTasksPerMember'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallTeamScore': overallTeamScore,
      'totalTeamTasks': totalTeamTasks,
      'completedTeamTasks': completedTeamTasks,
      'teamCompletionRate': teamCompletionRate,
      'averageTasksPerMember': averageTasksPerMember,
    };
  }
}

// Time analytics
class TimeAnalytics {
  final TimeDistribution timeDistribution;
  final List<TimeTrackingEntry> recentEntries;
  final Map<String, double> categoryTimeBreakdown;
  final double totalTrackedHours;
  final double averageSessionDuration;

  TimeAnalytics({
    required this.timeDistribution,
    this.recentEntries = const [],
    this.categoryTimeBreakdown = const {},
    this.totalTrackedHours = 0.0,
    this.averageSessionDuration = 0.0,
  });

  factory TimeAnalytics.fromJson(Map<String, dynamic> json) {
    return TimeAnalytics(
      timeDistribution: TimeDistribution.fromJson(json['timeDistribution'] ?? {}),
      recentEntries: (json['recentEntries'] as List<dynamic>?)
          ?.map((item) => TimeTrackingEntry.fromJson(item))
          .toList() ?? [],
      categoryTimeBreakdown: Map<String, double>.from(json['categoryTimeBreakdown'] ?? {}),
      totalTrackedHours: (json['totalTrackedHours'] ?? 0.0).toDouble(),
      averageSessionDuration: (json['averageSessionDuration'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeDistribution': timeDistribution.toJson(),
      'recentEntries': recentEntries.map((entry) => entry.toJson()).toList(),
      'categoryTimeBreakdown': categoryTimeBreakdown,
      'totalTrackedHours': totalTrackedHours,
      'averageSessionDuration': averageSessionDuration,
    };
  }
}

// Time distribution
class TimeDistribution {
  final Map<String, double> byDay;
  final Map<String, double> byHour;
  final Map<String, double> byCategory;

  TimeDistribution({
    this.byDay = const {},
    this.byHour = const {},
    this.byCategory = const {},
  });

  factory TimeDistribution.fromJson(Map<String, dynamic> json) {
    return TimeDistribution(
      byDay: Map<String, double>.from(json['byDay'] ?? {}),
      byHour: Map<String, double>.from(json['byHour'] ?? {}),
      byCategory: Map<String, double>.from(json['byCategory'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'byDay': byDay,
      'byHour': byHour,
      'byCategory': byCategory,
    };
  }
}

// Time tracking entry
class TimeTrackingEntry {
  final int taskId;
  final String taskTitle;
  final DateTime startTime;
  final DateTime? endTime;
  final double duration;
  final String category;

  TimeTrackingEntry({
    required this.taskId,
    required this.taskTitle,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.category,
  });

  factory TimeTrackingEntry.fromJson(Map<String, dynamic> json) {
    return TimeTrackingEntry(
      taskId: json['taskId'] ?? 0,
      taskTitle: json['taskTitle'] ?? '',
      startTime: DateTime.tryParse(json['startTime'] ?? '') ?? DateTime.now(),
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime']) : null,
      duration: (json['duration'] ?? 0.0).toDouble(),
      category: json['category'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'taskTitle': taskTitle,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration,
      'category': category,
    };
  }
}

// Project analytics
class ProjectAnalytics {
  final List<ProjectStats> projectStats;
  final ProjectComparison comparison;

  ProjectAnalytics({
    this.projectStats = const [],
    required this.comparison,
  });

  factory ProjectAnalytics.fromJson(Map<String, dynamic> json) {
    return ProjectAnalytics(
      projectStats: (json['projectStats'] as List<dynamic>?)
          ?.map((item) => ProjectStats.fromJson(item))
          .toList() ?? [],
      comparison: ProjectComparison.fromJson(json['comparison'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectStats': projectStats.map((stats) => stats.toJson()).toList(),
      'comparison': comparison.toJson(),
    };
  }
}

// Project stats
class ProjectStats {
  final int projectId;
  final String projectName;
  final int totalTasks;
  final int completedTasks;
  final double completionRate;
  final DateTime startDate;
  final DateTime? endDate;
  final double budgetUtilization;
  final List<String> milestones;

  ProjectStats({
    required this.projectId,
    required this.projectName,
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
    required this.startDate,
    this.endDate,
    this.budgetUtilization = 0.0,
    this.milestones = const [],
  });

  factory ProjectStats.fromJson(Map<String, dynamic> json) {
    return ProjectStats(
      projectId: json['projectId'] ?? 0,
      projectName: json['projectName'] ?? '',
      totalTasks: json['totalTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      budgetUtilization: (json['budgetUtilization'] ?? 0.0).toDouble(),
      milestones: List<String>.from(json['milestones'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'projectName': projectName,
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'completionRate': completionRate,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'budgetUtilization': budgetUtilization,
      'milestones': milestones,
    };
  }
}

// Project comparison
class ProjectComparison {
  final String bestPerformingProject;
  final String worstPerformingProject;
  final double averageCompletionRate;
  final int totalProjects;

  ProjectComparison({
    this.bestPerformingProject = '',
    this.worstPerformingProject = '',
    this.averageCompletionRate = 0.0,
    this.totalProjects = 0,
  });

  factory ProjectComparison.fromJson(Map<String, dynamic> json) {
    return ProjectComparison(
      bestPerformingProject: json['bestPerformingProject'] ?? '',
      worstPerformingProject: json['worstPerformingProject'] ?? '',
      averageCompletionRate: (json['averageCompletionRate'] ?? 0.0).toDouble(),
      totalProjects: json['totalProjects'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bestPerformingProject': bestPerformingProject,
      'worstPerformingProject': worstPerformingProject,
      'averageCompletionRate': averageCompletionRate,
      'totalProjects': totalProjects,
    };
  }
}

// Enums for various types
enum TrendDirection { up, down, stable }
enum MetricType { count, percentage, duration, score }

// Analytics filter for generating custom reports
class AnalyticsFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<int> userIds;
  final List<String> categories;
  final List<String> priorities;
  final List<String> statuses;
  final List<int> projectIds;

  AnalyticsFilter({
    this.startDate,
    this.endDate,
    this.userIds = const [],
    this.categories = const [],
    this.priorities = const [],
    this.statuses = const [],
    this.projectIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'userIds': userIds,
      'categories': categories,
      'priorities': priorities,
      'statuses': statuses,
      'projectIds': projectIds,
    };
  }

  AnalyticsFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<int>? userIds,
    List<String>? categories,
    List<String>? priorities,
    List<String>? statuses,
    List<int>? projectIds,
  }) {
    return AnalyticsFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      userIds: userIds ?? this.userIds,
      categories: categories ?? this.categories,
      priorities: priorities ?? this.priorities,
      statuses: statuses ?? this.statuses,
      projectIds: projectIds ?? this.projectIds,
    );
  }
}

// Export format options
enum ExportFormat { pdf, excel, csv, json }