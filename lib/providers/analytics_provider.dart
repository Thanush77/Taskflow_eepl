import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';
import 'task_provider.dart';

// Analytics State
class AnalyticsState {
  final AnalyticsData? data;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final DateTime? lastUpdated;
  final AnalyticsFilter currentFilter;

  AnalyticsState({
    this.data,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.lastUpdated,
    AnalyticsFilter? currentFilter,
  }) : currentFilter = currentFilter ?? AnalyticsFilter();

  AnalyticsState copyWith({
    AnalyticsData? data,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    DateTime? lastUpdated,
    AnalyticsFilter? currentFilter,
    bool clearError = false,
  }) {
    return AnalyticsState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
      lastUpdated: lastUpdated ?? this.lastUpdated,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }

  bool get hasData => data != null;
  bool get isStale => lastUpdated == null || 
      DateTime.now().difference(lastUpdated!).inMinutes > 15;
}

// Analytics Notifier
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final ApiService _apiService;
  final Ref _ref;
  Timer? _refreshTimer;

  AnalyticsNotifier(this._apiService, this._ref) : super(AnalyticsState()) {
    _initializeAnalytics();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Initialize analytics with default filter
  Future<void> _initializeAnalytics() async {
    final defaultFilter = AnalyticsFilter(
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );
    await loadAnalytics(filter: defaultFilter);
  }

  // Load analytics data with filter
  Future<void> loadAnalytics({
    AnalyticsFilter? filter,
    bool isRefresh = false,
  }) async {
    try {
      final filterToUse = filter ?? state.currentFilter;
      
      if (isRefresh) {
        state = state.copyWith(isRefreshing: true, clearError: true);
      } else {
        state = state.copyWith(isLoading: true, clearError: true);
      }

      // Check authentication
      final authState = _ref.read(authProvider);
      if (authState.user == null) {
        throw Exception('User not authenticated');
      }

      // Get analytics data from API (fallback to local generation)
      try {
        final response = await _apiService.getFlutterAnalytics(filterToUse.toJson());
        final analyticsData = AnalyticsData.fromJson(response);
        
        state = state.copyWith(
          data: analyticsData,
          currentFilter: filterToUse,
          isLoading: false,
          isRefreshing: false,
          lastUpdated: DateTime.now(),
          error: null,
        );
        return;
      } catch (e) {
        // Fallback to local analytics generation if API fails
        print('Analytics API failed, falling back to local generation: $e');
      }
      
      // Generate local analytics as fallback
      final taskState = _ref.read(taskProvider);
      final analyticsData = _generateAnalyticsFromTasks(taskState.tasks);

      state = state.copyWith(
        data: analyticsData,
        currentFilter: filterToUse,
        isLoading: false,
        isRefreshing: false,
        lastUpdated: DateTime.now(),
      );

      // Start periodic refresh
      _startPeriodicRefresh();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }

  // Update filter and reload data
  Future<void> updateFilter(AnalyticsFilter filter) async {
    await loadAnalytics(filter: filter);
  }

  // Generate analytics data locally if API is not available
  Future<void> generateLocalAnalytics() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final taskState = _ref.read(taskProvider);
      final tasks = taskState.tasks;

      if (tasks.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'No tasks available for analysis',
        );
        return;
      }

      final analyticsData = _generateAnalyticsFromTasks(tasks);

      state = state.copyWith(
        data: analyticsData,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Generate analytics data from task list
  AnalyticsData _generateAnalyticsFromTasks(List<Task> tasks) {
    final now = DateTime.now();
    final filteredTasks = _filterTasks(tasks, state.currentFilter);

    return AnalyticsData(
      taskAnalytics: _generateTaskAnalytics(filteredTasks),
      productivityAnalytics: _generateProductivityAnalytics(filteredTasks),
      teamAnalytics: _generateTeamAnalytics(filteredTasks),
      timeAnalytics: _generateTimeAnalytics(filteredTasks),
      projectAnalytics: _generateProjectAnalytics(filteredTasks),
      generatedAt: now,
    );
  }

  // Filter tasks based on current filter
  List<Task> _filterTasks(List<Task> tasks, AnalyticsFilter filter) {
    return tasks.where((task) {
      // Date filter
      if (filter.startDate != null && task.createdAt != null && task.createdAt!.isBefore(filter.startDate!)) {
        return false;
      }
      if (filter.endDate != null && task.createdAt != null && task.createdAt!.isAfter(filter.endDate!)) {
        return false;
      }
      
      // User filter
      if (filter.userIds.isNotEmpty && 
          (task.assignedTo == null || !filter.userIds.contains(task.assignedTo))) {
        return false;
      }
      
      // Category filter
      if (filter.categories.isNotEmpty && !filter.categories.contains(task.category.toString().split('.').last)) {
        return false;
      }
      
      // Priority filter
      if (filter.priorities.isNotEmpty && 
          !filter.priorities.contains(task.priority.toString().split('.').last)) {
        return false;
      }
      
      // Status filter
      if (filter.statuses.isNotEmpty && 
          !filter.statuses.contains(task.status.toString().split('.').last)) {
        return false;
      }
      
      return true;
    }).toList();
  }

  // Generate task analytics
  TaskAnalytics _generateTaskAnalytics(List<Task> tasks) {
    final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).length;
    final pendingTasks = tasks.where((t) => t.status == TaskStatus.pending).length;
    final inProgressTasks = tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final overdueTasks = tasks.where((t) => t.dueDate != null && 
        t.dueDate!.isBefore(DateTime.now()) && 
        t.status != TaskStatus.completed).length;

    final completionStats = TaskCompletionStats(
      totalTasks: tasks.length,
      completedTasks: completedTasks,
      pendingTasks: pendingTasks,
      inProgressTasks: inProgressTasks,
      overdueTasks: overdueTasks,
      completionRate: tasks.isEmpty ? 0.0 : completedTasks / tasks.length,
      onTimeCompletionRate: _calculateOnTimeCompletionRate(tasks),
      averageCompletionDays: _calculateAverageCompletionDays(tasks),
    );

    final distributionStats = TaskDistributionStats(
      byCategory: _generateCategoryDistribution(tasks),
      byPriority: _generatePriorityDistribution(tasks),
      byStatus: _generateStatusDistribution(tasks),
      byAssignee: _generateAssigneeDistribution(tasks),
    );

    final trendStats = _generateTaskTrendStats(tasks);

    final metrics = [
      TaskMetric(
        name: 'Total Tasks',
        value: tasks.length.toDouble(),
        type: MetricType.count,
        trend: TrendDirection.stable,
      ),
      TaskMetric(
        name: 'Completion Rate',
        value: completionStats.completionRate * 100,
        unit: '%',
        type: MetricType.percentage,
        trend: TrendDirection.up,
        changePercentage: 5.2,
      ),
      TaskMetric(
        name: 'Average Completion',
        value: completionStats.averageCompletionDays.toDouble(),
        unit: 'days',
        type: MetricType.duration,
        trend: TrendDirection.down,
        changePercentage: -2.1,
      ),
    ];

    return TaskAnalytics(
      completionStats: completionStats,
      distributionStats: distributionStats,
      trendStats: trendStats,
      metrics: metrics,
    );
  }

  // Calculate on-time completion rate
  double _calculateOnTimeCompletionRate(List<Task> tasks) {
    final completedWithDueDate = tasks.where((t) => 
        t.status == TaskStatus.completed && 
        t.dueDate != null &&
        t.completedAt != null).toList();
    
    if (completedWithDueDate.isEmpty) return 0.0;
    
    final onTimeCount = completedWithDueDate.where((t) => 
        t.completedAt!.isBefore(t.dueDate!) || 
        t.completedAt!.isAtSameMomentAs(t.dueDate!)).length;
    
    return onTimeCount / completedWithDueDate.length;
  }

  // Calculate average completion days
  int _calculateAverageCompletionDays(List<Task> tasks) {
    final completedTasks = tasks.where((t) => 
        t.status == TaskStatus.completed && 
        t.completedAt != null).toList();
    
    if (completedTasks.isEmpty) return 0;
    
    final totalDays = completedTasks.fold<int>(0, (sum, task) => 
        sum + task.completedAt!.difference(task.createdAt ?? DateTime.now()).inDays);
    
    return (totalDays / completedTasks.length).round();
  }

  // Generate category distribution
  List<CategoryDistribution> _generateCategoryDistribution(List<Task> tasks) {
    final categoryMap = <String, int>{};
    for (final task in tasks) {
      final categoryName = task.category.toString().split('.').last;
      categoryMap[categoryName] = (categoryMap[categoryName] ?? 0) + 1;
    }

    return categoryMap.entries.map((entry) => CategoryDistribution(
      category: entry.key,
      count: entry.value,
      percentage: tasks.isEmpty ? 0.0 : (entry.value / tasks.length) * 100,
    )).toList();
  }

  // Generate priority distribution
  List<PriorityDistribution> _generatePriorityDistribution(List<Task> tasks) {
    final priorityMap = <String, int>{};
    for (final task in tasks) {
      final priority = task.priority.toString().split('.').last;
      priorityMap[priority] = (priorityMap[priority] ?? 0) + 1;
    }

    return priorityMap.entries.map((entry) => PriorityDistribution(
      priority: entry.key,
      count: entry.value,
      percentage: tasks.isEmpty ? 0.0 : (entry.value / tasks.length) * 100,
    )).toList();
  }

  // Generate status distribution
  List<StatusDistribution> _generateStatusDistribution(List<Task> tasks) {
    final statusMap = <String, int>{};
    for (final task in tasks) {
      final status = task.status.toString().split('.').last;
      statusMap[status] = (statusMap[status] ?? 0) + 1;
    }

    return statusMap.entries.map((entry) => StatusDistribution(
      status: entry.key,
      count: entry.value,
      percentage: tasks.isEmpty ? 0.0 : (entry.value / tasks.length) * 100,
    )).toList();
  }

  // Generate assignee distribution
  List<AssigneeDistribution> _generateAssigneeDistribution(List<Task> tasks) {
    final assigneeMap = <int, Map<String, dynamic>>{};
    
    for (final task in tasks) {
      if (task.assignedTo != null) {
        final assigneeId = task.assignedTo!;
        if (!assigneeMap.containsKey(assigneeId)) {
          assigneeMap[assigneeId] = {
            'name': 'User $assigneeId',
            'assigned': 0,
            'completed': 0,
          };
        }
        assigneeMap[assigneeId]!['assigned'] = 
            (assigneeMap[assigneeId]!['assigned'] as int) + 1;
        
        if (task.status == TaskStatus.completed) {
          assigneeMap[assigneeId]!['completed'] = 
              (assigneeMap[assigneeId]!['completed'] as int) + 1;
        }
      }
    }

    return assigneeMap.entries.map((entry) {
      final assigned = entry.value['assigned'] as int;
      final completed = entry.value['completed'] as int;
      return AssigneeDistribution(
        assigneeId: entry.key,
        assigneeName: entry.value['name'] as String,
        assignedCount: assigned,
        completedCount: completed,
        completionRate: assigned == 0 ? 0.0 : completed / assigned,
      );
    }).toList();
  }

  // Generate task trend stats
  TaskTrendStats _generateTaskTrendStats(List<Task> tasks) {
    final dailyTrends = <DailyTaskTrend>[];
    final weeklyTrends = <WeeklyTaskTrend>[];
    final monthlyTrends = <MonthlyTaskTrend>[];

    // Generate daily trends for the last 30 days
    for (int i = 29; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dayTasks = tasks.where((t) => 
          t.createdAt != null &&
          t.createdAt!.year == date.year &&
          t.createdAt!.month == date.month &&
          t.createdAt!.day == date.day).toList();
      
      dailyTrends.add(DailyTaskTrend(
        date: date,
        created: dayTasks.length,
        completed: dayTasks.where((t) => t.status == TaskStatus.completed).length,
        inProgress: dayTasks.where((t) => t.status == TaskStatus.inProgress).length,
      ));
    }

    return TaskTrendStats(
      dailyTrends: dailyTrends,
      weeklyTrends: weeklyTrends,
      monthlyTrends: monthlyTrends,
      completionTrend: TrendDirection.up,
      creationTrend: TrendDirection.stable,
    );
  }

  // Generate productivity analytics
  ProductivityAnalytics _generateProductivityAnalytics(List<Task> tasks) {
    final factors = [
      ProductivityFactor(
        name: 'Task Completion',
        score: _calculateTaskCompletionScore(tasks),
        weight: 0.4,
        description: 'How well you complete assigned tasks',
      ),
      ProductivityFactor(
        name: 'Timeliness',
        score: _calculateTimelinessScore(tasks),
        weight: 0.3,
        description: 'How often you meet deadlines',
      ),
      ProductivityFactor(
        name: 'Task Quality',
        score: _calculateQualityScore(tasks),
        weight: 0.3,
        description: 'Quality of task execution',
      ),
    ];

    final overallScore = factors.fold<double>(0.0, (sum, factor) => 
        sum + (factor.score * factor.weight));

    final insights = ProductivityInsights(
      strengths: ['Good task completion rate', 'Consistent work pattern'],
      improvements: ['Focus on meeting deadlines', 'Reduce task complexity'],
      recommendations: ['Use time blocking', 'Break down large tasks'],
      burnoutRisk: _calculateBurnoutRisk(tasks),
      workloadStatus: _getWorkloadStatus(tasks),
    );

    return ProductivityAnalytics(
      overallProductivityScore: overallScore,
      factors: factors,
      trends: [],
      insights: insights,
    );
  }

  // Calculate task completion score
  double _calculateTaskCompletionScore(List<Task> tasks) {
    if (tasks.isEmpty) return 0.0;
    final completedCount = tasks.where((t) => t.status == TaskStatus.completed).length;
    return (completedCount / tasks.length) * 100;
  }

  // Calculate timeliness score
  double _calculateTimelinessScore(List<Task> tasks) {
    final tasksWithDueDate = tasks.where((t) => t.dueDate != null).toList();
    if (tasksWithDueDate.isEmpty) return 100.0;
    
    final onTimeCount = tasksWithDueDate.where((t) => 
        t.completedAt != null && 
        t.completedAt!.isBefore(t.dueDate!)).length;
    
    return (onTimeCount / tasksWithDueDate.length) * 100;
  }

  // Calculate quality score
  double _calculateQualityScore(List<Task> tasks) {
    // Mock quality score based on task complexity and completion
    return 85.0;
  }

  // Calculate burnout risk
  double _calculateBurnoutRisk(List<Task> tasks) {
    final recentTasks = tasks.where((t) => 
        t.createdAt != null && t.createdAt!.isAfter(DateTime.now().subtract(const Duration(days: 7)))).length;
    
    if (recentTasks > 20) return 0.8;
    if (recentTasks > 15) return 0.6;
    if (recentTasks > 10) return 0.4;
    return 0.2;
  }

  // Get workload status
  String _getWorkloadStatus(List<Task> tasks) {
    final inProgressCount = tasks.where((t) => t.status == TaskStatus.inProgress).length;
    
    if (inProgressCount > 10) return 'high';
    if (inProgressCount > 5) return 'moderate';
    return 'low';
  }

  // Generate team analytics
  TeamAnalytics _generateTeamAnalytics(List<Task> tasks) {
    final memberPerformance = _generateTeamMemberPerformance(tasks);
    final collaborationStats = TeamCollaborationStats();
    final productivityStats = TeamProductivityStats(
      totalTeamTasks: tasks.length,
      completedTeamTasks: tasks.where((t) => t.status == TaskStatus.completed).length,
      teamCompletionRate: tasks.isEmpty ? 0.0 : 
          tasks.where((t) => t.status == TaskStatus.completed).length / tasks.length,
    );

    return TeamAnalytics(
      memberPerformance: memberPerformance,
      collaborationStats: collaborationStats,
      productivityStats: productivityStats,
    );
  }

  // Generate team member performance
  List<TeamMemberPerformance> _generateTeamMemberPerformance(List<Task> tasks) {
    final memberMap = <int, Map<String, dynamic>>{};
    
    for (final task in tasks) {
      if (task.assignedTo != null) {
        final userId = task.assignedTo!;
        if (!memberMap.containsKey(userId)) {
          memberMap[userId] = {
            'name': 'User $userId',
            'assigned': 0,
            'completed': 0,
            'comments': 0,
          };
        }
        memberMap[userId]!['assigned'] = 
            (memberMap[userId]!['assigned'] as int) + 1;
        
        if (task.status == TaskStatus.completed) {
          memberMap[userId]!['completed'] = 
              (memberMap[userId]!['completed'] as int) + 1;
        }
      }
    }

    return memberMap.entries.map((entry) {
      final assigned = entry.value['assigned'] as int;
      final completed = entry.value['completed'] as int;
      return TeamMemberPerformance(
        userId: entry.key,
        name: entry.value['name'] as String,
        assignedTasks: assigned,
        completedTasks: completed,
        completionRate: assigned == 0 ? 0.0 : completed / assigned,
        averageTaskDuration: 3.5, // Mock data
        commentsCount: entry.value['comments'] as int,
        collaborationScore: 0.8, // Mock data
      );
    }).toList();
  }

  // Generate time analytics
  TimeAnalytics _generateTimeAnalytics(List<Task> tasks) {
    return TimeAnalytics(
      timeDistribution: TimeDistribution(),
      totalTrackedHours: 120.5, // Mock data
      averageSessionDuration: 2.5, // Mock data
    );
  }

  // Generate project analytics
  ProjectAnalytics _generateProjectAnalytics(List<Task> tasks) {
    return ProjectAnalytics(
      comparison: ProjectComparison(
        totalProjects: 3,
        averageCompletionRate: 0.75,
      ),
    );
  }

  // Start periodic refresh
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (!state.isLoading) {
        loadAnalytics(isRefresh: true);
      }
    });
  }

  // Export analytics data
  Future<Map<String, dynamic>> exportAnalytics(ExportFormat format) async {
    if (state.data == null) {
      throw Exception('No analytics data available for export');
    }

    final data = state.data!;
    final exportData = <String, dynamic>{
      'generatedAt': data.generatedAt.toIso8601String(),
      'filter': state.currentFilter.toJson(),
      'taskAnalytics': data.taskAnalytics.toJson(),
      'productivityAnalytics': data.productivityAnalytics.toJson(),
      'teamAnalytics': data.teamAnalytics.toJson(),
      'timeAnalytics': data.timeAnalytics.toJson(),
      'projectAnalytics': data.projectAnalytics.toJson(),
      'format': format.toString().split('.').last,
    };

    return exportData;
  }

  // Refresh analytics
  Future<void> refresh() async {
    await loadAnalytics(isRefresh: true);
  }

  // Clear error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Main Analytics Provider
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AnalyticsNotifier(apiService, ref);
});

// Computed providers for different analytics sections

// Task analytics provider
final taskAnalyticsProvider = Provider<TaskAnalytics?>((ref) {
  final analyticsState = ref.watch(analyticsProvider);
  return analyticsState.data?.taskAnalytics;
});

// Productivity analytics provider
final productivityAnalyticsProvider = Provider<ProductivityAnalytics?>((ref) {
  final analyticsState = ref.watch(analyticsProvider);
  return analyticsState.data?.productivityAnalytics;
});

// Team analytics provider
final teamAnalyticsProvider = Provider<TeamAnalytics?>((ref) {
  final analyticsState = ref.watch(analyticsProvider);
  return analyticsState.data?.teamAnalytics;
});

// Time analytics provider
final timeAnalyticsProvider = Provider<TimeAnalytics?>((ref) {
  final analyticsState = ref.watch(analyticsProvider);
  return analyticsState.data?.timeAnalytics;
});

// Project analytics provider
final projectAnalyticsProvider = Provider<ProjectAnalytics?>((ref) {
  final analyticsState = ref.watch(analyticsProvider);
  return analyticsState.data?.projectAnalytics;
});

// Analytics loading state provider
final analyticsLoadingProvider = Provider<bool>((ref) {
  final analyticsState = ref.watch(analyticsProvider);
  return analyticsState.isLoading;
});

// Analytics error provider
final analyticsErrorProvider = Provider<String?>((ref) {
  final analyticsState = ref.watch(analyticsProvider);
  return analyticsState.error;
});

// Current analytics filter provider
final currentAnalyticsFilterProvider = Provider<AnalyticsFilter>((ref) {
  final analyticsState = ref.watch(analyticsProvider);
  return analyticsState.currentFilter;
});

// Analytics actions provider for UI interactions
final analyticsActionsProvider = Provider<AnalyticsActions>((ref) {
  return AnalyticsActions(ref);
});

// Analytics actions class for UI interactions
class AnalyticsActions {
  final Ref _ref;

  AnalyticsActions(this._ref);

  Future<void> loadAnalytics({AnalyticsFilter? filter}) async {
    final notifier = _ref.read(analyticsProvider.notifier);
    await notifier.loadAnalytics(filter: filter);
  }

  Future<void> updateFilter(AnalyticsFilter filter) async {
    final notifier = _ref.read(analyticsProvider.notifier);
    await notifier.updateFilter(filter);
  }

  Future<void> generateLocalAnalytics() async {
    final notifier = _ref.read(analyticsProvider.notifier);
    await notifier.generateLocalAnalytics();
  }

  Future<void> refresh() async {
    final notifier = _ref.read(analyticsProvider.notifier);
    await notifier.refresh();
  }

  void clearError() {
    final notifier = _ref.read(analyticsProvider.notifier);
    notifier.clearError();
  }

  Future<Map<String, dynamic>> exportAnalytics(ExportFormat format) async {
    final notifier = _ref.read(analyticsProvider.notifier);
    return await notifier.exportAnalytics(format);
  }
}