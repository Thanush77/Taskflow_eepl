import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_stats.dart';
import '../models/task.dart';
import '../models/websocket_events.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';
import 'task_provider.dart';
import 'websocket_provider.dart';

// Dashboard State
class DashboardState {
  final DashboardStats stats;
  final RealTimeMetrics realTimeMetrics;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final DateTime? lastUpdated;
  final Map<String, dynamic> productivityInsights;

  DashboardState({
    DashboardStats? stats,
    RealTimeMetrics? realTimeMetrics,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.lastUpdated,
    this.productivityInsights = const {},
  }) : stats = stats ?? DashboardStats(),
       realTimeMetrics = realTimeMetrics ?? RealTimeMetrics();

  DashboardState copyWith({
    DashboardStats? stats,
    RealTimeMetrics? realTimeMetrics,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    DateTime? lastUpdated,
    Map<String, dynamic>? productivityInsights,
    bool clearError = false,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      realTimeMetrics: realTimeMetrics ?? this.realTimeMetrics,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
      lastUpdated: lastUpdated ?? this.lastUpdated,
      productivityInsights: productivityInsights ?? this.productivityInsights,
    );
  }

  bool get hasData => stats.totalTasks > 0 || realTimeMetrics.activeUsers > 0;
  bool get isStale => lastUpdated == null || 
      DateTime.now().difference(lastUpdated!).inMinutes > 5;
}

// Dashboard Notifier
class DashboardNotifier extends StateNotifier<DashboardState> {
  final ApiService _apiService;
  final Ref _ref;
  Timer? _refreshTimer;
  Timer? _realTimeTimer;
  ProviderSubscription? _taskEventSubscription;
  ProviderSubscription? _userEventSubscription;

  DashboardNotifier(this._apiService, this._ref) : super(DashboardState()) {
    _initializeDashboard();
    _setupRealTimeListeners();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _realTimeTimer?.cancel();
    _taskEventSubscription?.close();
    _userEventSubscription?.close();
    super.dispose();
  }

  // Initialize dashboard with initial data load
  Future<void> _initializeDashboard() async {
    await loadDashboardStats();
    _updateRealTimeMetrics();
  }

  // Load dashboard statistics from API
  Future<void> loadDashboardStats({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        state = state.copyWith(isRefreshing: true, clearError: true);
      } else {
        state = state.copyWith(isLoading: true, clearError: true);
      }

      // Get current user
      final authState = _ref.read(authProvider);
      if (authState.user == null) {
        throw Exception('User not authenticated');
      }

      // Fetch dashboard stats from API
      final response = await _apiService.getDashboardStats();
      final stats = DashboardStats.fromJson(response);

      // Calculate productivity insights
      final insights = _calculateProductivityInsights(stats);

      state = state.copyWith(
        stats: stats,
        productivityInsights: insights,
        isLoading: false,
        isRefreshing: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }

  // Update real-time metrics based on current state
  void _updateRealTimeMetrics() {
    try {
      final taskState = _ref.read(taskProvider);
      final onlineUsers = _ref.read(onlineUsersProvider);
      final isConnected = _ref.read(isConnectedProvider);

      if (!isConnected) return;

      // Calculate active tasks in progress
      final tasksInProgress = taskState.tasks
          .where((task) => task.status == TaskStatus.inProgress)
          .length;

      // Get recent activities from task updates
      final recentActivities = _getRecentActivities();

      // Calculate recent updates (tasks modified in last hour)
      final recentUpdates = taskState.tasks
          .where((task) => 
              task.updatedAt != null &&
              DateTime.now().difference(task.updatedAt!).inHours < 1)
          .length;

      final realTimeMetrics = RealTimeMetrics(
        activeUsers: onlineUsers.length,
        tasksInProgress: tasksInProgress,
        recentUpdates: recentUpdates,
        recentActivities: recentActivities,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(realTimeMetrics: realTimeMetrics);
    } catch (e) {
      // Silently handle real-time update errors
      // Consider using a proper logging framework in production
      debugPrint('Error updating real-time metrics: $e');
    }
  }

  // Get recent activities from task state
  List<RecentActivity> _getRecentActivities() {
    final taskState = _ref.read(taskProvider);
    final activities = <RecentActivity>[];

    // Get recently updated tasks
    final recentTasks = taskState.tasks
        .where((task) => 
            task.updatedAt != null &&
            DateTime.now().difference(task.updatedAt!).inHours < 24)
        .toList();

    recentTasks.sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));

    for (final task in recentTasks.take(10)) {
      activities.add(RecentActivity(
        type: 'task_updated',
        description: 'Task "${task.title}" was updated',
        userName: task.assignedTo != null ? 'User ${task.assignedTo}' : 'System',
        timestamp: task.updatedAt!,
        taskId: task.id,
        taskTitle: task.title,
      ));
    }

    return activities;
  }

  // Calculate productivity insights
  Map<String, dynamic> _calculateProductivityInsights(DashboardStats stats) {
    final insights = <String, dynamic>{};

    // Calculate completion rate trend
    if (stats.weeklyTrends.isNotEmpty) {
      final recentTrends = stats.weeklyTrends.take(7).toList();
      final avgCompletion = recentTrends
          .map((t) => t.completed)
          .reduce((a, b) => a + b) / recentTrends.length;
      
      insights['avgWeeklyCompletion'] = avgCompletion.round();
      insights['isImprovingTrend'] = _isImprovingTrend(recentTrends);
    }

    // Calculate workload distribution
    final workloadScore = _calculateWorkloadScore(stats);
    insights['workloadScore'] = workloadScore;
    insights['workloadStatus'] = _getWorkloadStatus(workloadScore);

    // Calculate priority distribution health
    final priorityHealth = _calculatePriorityHealth(stats.priorityDistribution);
    insights['priorityHealth'] = priorityHealth;

    // Calculate team performance insights
    if (stats.teamPerformance.isNotEmpty) {
      final topPerformer = stats.teamPerformance
          .reduce((a, b) => a.completionRate > b.completionRate ? a : b);
      insights['topPerformer'] = topPerformer.name;
      insights['topPerformanceRate'] = topPerformer.completionRate;
    }

    // Calculate overdue risk
    final overdueRisk = stats.overdueTasks > 0 
        ? (stats.overdueTasks / stats.totalTasks * 100).round()
        : 0;
    insights['overdueRisk'] = overdueRisk;
    insights['overdueRiskLevel'] = _getRiskLevel(overdueRisk);

    return insights;
  }

  // Check if completion trend is improving
  bool _isImprovingTrend(List<TaskTrend> trends) {
    if (trends.length < 2) return false;
    
    final recent = trends.take(3).map((t) => t.completed).toList();
    final older = trends.skip(3).take(3).map((t) => t.completed).toList();
    
    if (older.isEmpty) return false;
    
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;
    
    return recentAvg > olderAvg;
  }

  // Calculate workload score (0-100)
  double _calculateWorkloadScore(DashboardStats stats) {
    if (stats.totalTasks == 0) return 0;
    
    final inProgressRatio = stats.inProgressTasks / stats.totalTasks;
    final overdueRatio = stats.overdueTasks / stats.totalTasks;
    
    // Higher score means better workload management
    return ((1 - overdueRatio) * 60 + (1 - inProgressRatio.clamp(0, 0.8)) * 40)
        .clamp(0, 100);
  }

  // Get workload status based on score
  String _getWorkloadStatus(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Attention';
  }

  // Calculate priority distribution health
  double _calculatePriorityHealth(List<PriorityStats> distribution) {
    if (distribution.isEmpty) return 50;
    
    final highPriority = distribution
        .where((p) => p.priority.toLowerCase() == 'high')
        .fold(0, (sum, p) => sum + p.count);
    
    final total = distribution.fold(0, (sum, p) => sum + p.count);
    
    if (total == 0) return 50;
    
    final highPriorityRatio = highPriority / total;
    
    // Ideal ratio is around 20-30% high priority tasks
    if (highPriorityRatio <= 0.3 && highPriorityRatio >= 0.2) {
      return 100;
    } else if (highPriorityRatio < 0.2) {
      return 100 - ((0.2 - highPriorityRatio) * 200);
    } else {
      return 100 - ((highPriorityRatio - 0.3) * 200);
    }
  }

  // Get risk level based on percentage
  String _getRiskLevel(int percentage) {
    if (percentage >= 30) return 'High';
    if (percentage >= 15) return 'Medium';
    if (percentage > 0) return 'Low';
    return 'None';
  }

  // Setup real-time event listeners
  void _setupRealTimeListeners() {
    // Listen to WebSocket task events
    _taskEventSubscription = _ref.listen(webSocketEventsProvider, (previous, next) {
      next.whenData((event) {
        _handleWebSocketEvent(event);
      });
    });

    // Listen to user online/offline events
    _userEventSubscription = _ref.listen(onlineUsersProvider, (previous, next) {
      _updateRealTimeMetrics();
    });

    // Listen to task provider changes
    _ref.listen(taskProvider, (previous, next) {
      if (previous?.tasks.length != next.tasks.length ||
          previous?.tasks.where((t) => t.status == TaskStatus.inProgress).length !=
          next.tasks.where((t) => t.status == TaskStatus.inProgress).length) {
        _updateRealTimeMetrics();
        _incrementalStatsUpdate(previous, next);
      }
    });
  }

  // Handle WebSocket events for real-time updates
  void _handleWebSocketEvent(WebSocketEvent event) {
    switch (event.type) {
      case WebSocketEventType.taskCreated:
      case WebSocketEventType.taskUpdated:
      case WebSocketEventType.taskDeleted:
      case WebSocketEventType.taskStatusChanged:
        _updateRealTimeMetrics();
        break;
      case WebSocketEventType.userOnline:
      case WebSocketEventType.userOffline:
        _updateRealTimeMetrics();
        break;
      case WebSocketEventType.taskAssigned:
      case WebSocketEventType.taskCommentAdded:
      case WebSocketEventType.userTyping:
      case WebSocketEventType.userStoppedTyping:
      case WebSocketEventType.notification:
      case WebSocketEventType.connectionEstablished:
      case WebSocketEventType.heartbeat:
        // Handle other event types if needed
        break;
    }
  }

  // Perform incremental stats update without full API call
  void _incrementalStatsUpdate(TaskState? previous, TaskState next) {
    if (previous == null) return;

    final currentStats = state.stats;
    final currentTaskCount = next.tasks.length;

    // Calculate incremental changes
    final newCompletedCount = next.tasks
        .where((t) => t.status == TaskStatus.completed)
        .length;
    final newInProgressCount = next.tasks
        .where((t) => t.status == TaskStatus.inProgress)
        .length;
    final newPendingCount = next.tasks
        .where((t) => t.status == TaskStatus.pending)
        .length;

    // Update stats incrementally
    final updatedStats = currentStats.copyWith(
      totalTasks: currentTaskCount,
      completedTasks: newCompletedCount,
      inProgressTasks: newInProgressCount,
      pendingTasks: newPendingCount,
      lastUpdated: DateTime.now(),
    );

    state = state.copyWith(stats: updatedStats);
  }

  // Start periodic refresh timer
  void _startPeriodicRefresh() {
    // Refresh dashboard stats every 5 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!state.isLoading) {
        loadDashboardStats(isRefresh: true);
      }
    });

    // Update real-time metrics every 30 seconds
    _realTimeTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateRealTimeMetrics();
    });
  }

  // Force refresh all dashboard data
  Future<void> refresh() async {
    await loadDashboardStats(isRefresh: true);
  }

  // Clear error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Get task distribution by category
  Map<String, int> getTaskDistributionByCategory() {
    return state.stats.categoryBreakdown.fold<Map<String, int>>(
      {},
      (map, category) {
        map[category.category] = category.count;
        return map;
      },
    );
  }

  // Get task distribution by priority
  Map<String, int> getTaskDistributionByPriority() {
    return state.stats.priorityDistribution.fold<Map<String, int>>(
      {},
      (map, priority) {
        map[priority.priority] = priority.count;
        return map;
      },
    );
  }

  // Get weekly completion trend data
  List<Map<String, dynamic>> getWeeklyTrendData() {
    return state.stats.weeklyTrends.map((trend) => {
      'date': trend.date.toIso8601String(),
      'completed': trend.completed,
      'created': trend.created,
      'inProgress': trend.inProgress,
    }).toList();
  }

  // Get team performance data
  List<Map<String, dynamic>> getTeamPerformanceData() {
    return state.stats.teamPerformance.map((member) => {
      'name': member.name,
      'completionRate': member.completionRate,
      'assignedTasks': member.assignedTasks,
      'completedTasks': member.completedTasks,
      'isOnline': member.isOnline,
    }).toList();
  }
}

// Main Dashboard Provider
final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DashboardNotifier(apiService, ref);
});

// Computed providers for different dashboard sections

// Overall task statistics
final taskStatisticsProvider = Provider<Map<String, int>>((ref) {
  final dashboardState = ref.watch(dashboardProvider);
  final stats = dashboardState.stats;
  
  return {
    'total': stats.totalTasks,
    'pending': stats.pendingTasks,
    'inProgress': stats.inProgressTasks,
    'completed': stats.completedTasks,
    'overdue': stats.overdueTasks,
    'myTasks': stats.myTasks,
  };
});

// Real-time metrics provider
final realTimeMetricsProvider = Provider<RealTimeMetrics>((ref) {
  final dashboardState = ref.watch(dashboardProvider);
  return dashboardState.realTimeMetrics;
});

// Productivity insights provider
final productivityInsightsProvider = Provider<Map<String, dynamic>>((ref) {
  final dashboardState = ref.watch(dashboardProvider);
  return dashboardState.productivityInsights;
});

// Task completion rate provider
final taskCompletionRateProvider = Provider<double>((ref) {
  final dashboardState = ref.watch(dashboardProvider);
  return dashboardState.stats.completionRate;
});

// Productivity score provider
final productivityScoreProvider = Provider<double>((ref) {
  final dashboardState = ref.watch(dashboardProvider);
  return dashboardState.stats.productivityScore;
});

// Weekly trends provider
final weeklyTrendsProvider = Provider<List<TaskTrend>>((ref) {
  final dashboardState = ref.watch(dashboardProvider);
  return dashboardState.stats.weeklyTrends;
});

// Category breakdown provider
final categoryBreakdownProvider = Provider<List<CategoryStats>>((ref) {
  final dashboardState = ref.watch(dashboardProvider);
  return dashboardState.stats.categoryBreakdown;
});

// Priority distribution provider
final priorityDistributionProvider = Provider<List<PriorityStats>>((ref) {
  final dashboardState = ref.watch(dashboardProvider);
  return dashboardState.stats.priorityDistribution;
});

// Team performance provider
final teamPerformanceProvider = Provider<List<TeamMemberStats>>((ref) {
  final dashboardState = ref.watch(dashboardProvider);
  return dashboardState.stats.teamPerformance;
});

// Recent activities provider
final recentActivitiesProvider = Provider<List<RecentActivity>>((ref) {
  final dashboardState = ref.watch(dashboardProvider);
  return dashboardState.realTimeMetrics.recentActivities;
});

// Dashboard loading state provider
final dashboardLoadingProvider = Provider<bool>((ref) {
  final dashboardState = ref.watch(dashboardProvider);
  return dashboardState.isLoading;
});

// Dashboard error provider
final dashboardErrorProvider = Provider<String?>((ref) {
  final dashboardState = ref.watch(dashboardProvider);
  return dashboardState.error;
});

// Dashboard data freshness provider
final dashboardFreshnessProvider = Provider<bool>((ref) {
  final dashboardState = ref.watch(dashboardProvider);
  return !dashboardState.isStale;
});

// Online users count provider
final activeUsersCountProvider = Provider<int>((ref) {
  final realTimeMetrics = ref.watch(realTimeMetricsProvider);
  return realTimeMetrics.activeUsers;
});

// Tasks in progress count provider
final tasksInProgressCountProvider = Provider<int>((ref) {
  final realTimeMetrics = ref.watch(realTimeMetricsProvider);
  return realTimeMetrics.tasksInProgress;
});

// Dashboard actions provider for UI interactions
final dashboardActionsProvider = Provider<DashboardActions>((ref) {
  return DashboardActions(ref);
});

// Dashboard actions class for UI interactions
class DashboardActions {
  final Ref _ref;

  DashboardActions(this._ref);

  Future<void> refreshDashboard() async {
    final notifier = _ref.read(dashboardProvider.notifier);
    await notifier.refresh();
  }

  void clearError() {
    final notifier = _ref.read(dashboardProvider.notifier);
    notifier.clearError();
  }

  Map<String, int> getTaskDistributionByCategory() {
    final notifier = _ref.read(dashboardProvider.notifier);
    return notifier.getTaskDistributionByCategory();
  }

  Map<String, int> getTaskDistributionByPriority() {
    final notifier = _ref.read(dashboardProvider.notifier);
    return notifier.getTaskDistributionByPriority();
  }

  List<Map<String, dynamic>> getWeeklyTrendData() {
    final notifier = _ref.read(dashboardProvider.notifier);
    return notifier.getWeeklyTrendData();
  }

  List<Map<String, dynamic>> getTeamPerformanceData() {
    final notifier = _ref.read(dashboardProvider.notifier);
    return notifier.getTeamPerformanceData();
  }
}