import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/analytics.dart';
import '../../providers/analytics_provider.dart';
import '../../widgets/chart_widgets.dart';
import '../../widgets/loading_widget.dart';
import 'analytics_filter_sheet.dart';
import 'export_options_sheet.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load analytics data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider.notifier).generateLocalAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsProvider);
    
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showFilterSheet(context),
            icon: const Icon(Icons.filter_list, color: AppColors.white),
          ),
          IconButton(
            onPressed: analyticsState.data != null 
                ? () => _showExportSheet(context)
                : null,
            icon: const Icon(Icons.download, color: AppColors.white),
          ),
          IconButton(
            onPressed: () => ref.read(analyticsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh, color: AppColors.white),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 16)),
            Tab(text: 'Tasks', icon: Icon(Icons.assignment, size: 16)),
            Tab(text: 'Team', icon: Icon(Icons.group, size: 16)),
            Tab(text: 'Time', icon: Icon(Icons.schedule, size: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Current filter display
          _buildFilterDisplay(analyticsState.currentFilter),
          
          // Content
          Expanded(
            child: analyticsState.isLoading && analyticsState.data == null
                ? const Center(child: LoadingWidget())
                : analyticsState.error != null
                    ? _buildErrorState(analyticsState.error!)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildTasksTab(),
                          _buildTeamTab(),
                          _buildTimeTab(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDisplay(AnalyticsFilter filter) {
    final hasFilters = filter.startDate != null ||
        filter.endDate != null ||
        filter.userIds.isNotEmpty ||
        filter.categories.isNotEmpty ||
        filter.priorities.isNotEmpty ||
        filter.statuses.isNotEmpty;

    if (!hasFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.primaryColor,
        border: Border(
          bottom: BorderSide(color: AppColors.gray200, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt, color: AppColors.white, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Active Filters',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _clearFilters(),
                child: const Text(
                  'Clear All',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (filter.startDate != null || filter.endDate != null)
                _buildFilterChip(
                  'Date: ${_formatDateRange(filter.startDate, filter.endDate)}',
                ),
              ...filter.categories.map((cat) => _buildFilterChip('Category: $cat')),
              ...filter.priorities.map((pri) => _buildFilterChip('Priority: $pri')),
              ...filter.statuses.map((status) => _buildFilterChip('Status: $status')),
              if (filter.userIds.isNotEmpty)
                _buildFilterChip('${filter.userIds.length} Users'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.white,
        ),
      ),
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      return '${_formatDate(start)} - ${_formatDate(end)}';
    } else if (start != null) {
      return 'From ${_formatDate(start)}';
    } else if (end != null) {
      return 'Until ${_formatDate(end)}';
    }
    return '';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load analytics',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(analyticsProvider.notifier).refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // Overview Tab
  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: () => ref.read(analyticsProvider.notifier).refresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key Metrics
            _buildKeyMetricsGrid(),
            
            const SizedBox(height: 24),
            
            // Charts Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ProductivityScoreRing(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TaskDistributionPieChart(distributionType: 'status'),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Trend Chart
            TaskCompletionTrendChart(),
            
            const SizedBox(height: 24),
            
            // Insights Section
            _buildInsightsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsGrid() {
    final taskAnalytics = ref.watch(taskAnalyticsProvider);
    
    if (taskAnalytics == null) {
      return const SizedBox.shrink();
    }

    final metrics = taskAnalytics.metrics;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return _buildMetricCard(metric);
      },
    );
  }

  Widget _buildMetricCard(TaskMetric metric) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  metric.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray600,
                  ),
                ),
              ),
              if (metric.trend != TrendDirection.stable)
                _buildTrendIcon(metric.trend, metric.changePercentage),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${metric.value.toStringAsFixed(metric.type == MetricType.percentage ? 0 : 1)}${metric.unit}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          if (metric.changePercentage != 0.0) ...{
            const SizedBox(height: 4),
            Text(
              '${metric.changePercentage > 0 ? '+' : ''}${metric.changePercentage.toStringAsFixed(1)}% vs last period',
              style: TextStyle(
                fontSize: 10,
                color: metric.changePercentage > 0 
                    ? AppColors.successColor 
                    : AppColors.errorColor,
              ),
            ),
          },
        ],
      ),
    );
  }

  Widget _buildTrendIcon(TrendDirection trend, double changePercentage) {
    IconData icon;
    Color color;
    
    switch (trend) {
      case TrendDirection.up:
        icon = Icons.trending_up;
        color = changePercentage > 0 ? AppColors.successColor : AppColors.errorColor;
        break;
      case TrendDirection.down:
        icon = Icons.trending_down;
        color = changePercentage > 0 ? AppColors.successColor : AppColors.errorColor;
        break;
      case TrendDirection.stable:
      default:
        icon = Icons.trending_flat;
        color = AppColors.gray500;
        break;
    }
    
    return Icon(icon, size: 16, color: color);
  }

  Widget _buildInsightsSection() {
    final productivityAnalytics = ref.watch(productivityAnalyticsProvider);
    
    if (productivityAnalytics == null) {
      return const SizedBox.shrink();
    }

    final insights = productivityAnalytics.insights;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Productivity Insights',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 16),
        
        if (insights.strengths.isNotEmpty) ...{
          _buildInsightCard(
            'Strengths',
            insights.strengths,
            Icons.thumb_up,
            AppColors.successColor,
          ),
          const SizedBox(height: 12),
        },
        
        if (insights.improvements.isNotEmpty) ...{
          _buildInsightCard(
            'Areas for Improvement',
            insights.improvements,
            Icons.trending_up,
            AppColors.warningColor,
          ),
          const SizedBox(height: 12),
        },
        
        if (insights.recommendations.isNotEmpty) ...{
          _buildInsightCard(
            'Recommendations',
            insights.recommendations,
            Icons.lightbulb,
            AppColors.primaryColor,
          ),
        },
      ],
    );
  }

  Widget _buildInsightCard(String title, List<String> items, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.gray700,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // Tasks Tab
  Widget _buildTasksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          
          // Distribution Charts
          Row(
            children: [
              Expanded(
                child: TaskDistributionPieChart(distributionType: 'category'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TaskDistributionPieChart(distributionType: 'priority'),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Task Completion Stats
          _buildTaskCompletionStats(),
          
          const SizedBox(height: 24),
          
          // Trend Chart
          TaskCompletionTrendChart(),
        ],
      ),
    );
  }

  Widget _buildTaskCompletionStats() {
    final taskAnalytics = ref.watch(taskAnalyticsProvider);
    
    if (taskAnalytics == null) {
      return const SizedBox.shrink();
    }

    final stats = taskAnalytics.completionStats;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task Completion Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Tasks',
                  stats.totalTasks.toString(),
                  Icons.assignment,
                  AppColors.primaryColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Completed',
                  stats.completedTasks.toString(),
                  Icons.check_circle,
                  AppColors.successColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'In Progress',
                  stats.inProgressTasks.toString(),
                  Icons.pending_actions,
                  AppColors.warningColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Overdue',
                  stats.overdueTasks.toString(),
                  Icons.schedule,
                  AppColors.errorColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Completion Rate',
                  '${(stats.completionRate * 100).toInt()}%',
                  Icons.trending_up,
                  AppColors.successColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'On-Time Rate',
                  '${(stats.onTimeCompletionRate * 100).toInt()}%',
                  Icons.access_time,
                  AppColors.primaryColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Avg. Duration',
                  '${stats.averageCompletionDays} days',
                  Icons.schedule,
                  AppColors.warningColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.gray900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.gray600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Team Tab
  Widget _buildTeamTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Team Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          
          // Team Performance Chart
          TeamPerformanceBarChart(),
          
          const SizedBox(height: 24),
          
          // Team Statistics
          _buildTeamStats(),
        ],
      ),
    );
  }

  Widget _buildTeamStats() {
    final teamAnalytics = ref.watch(teamAnalyticsProvider);
    
    if (teamAnalytics == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Team Performance Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          
          ...teamAnalytics.memberPerformance.map((member) => 
            _buildTeamMemberRow(member),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberRow(TeamMemberPerformance member) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryColor,
            child: Text(
              member.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray900,
                  ),
                ),
                Text(
                  '${member.completedTasks}/${member.assignedTasks} tasks • ${member.commentsCount} comments',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getCompletionRateColor(member.completionRate).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${(member.completionRate * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getCompletionRateColor(member.completionRate),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCompletionRateColor(double rate) {
    if (rate >= 0.8) return AppColors.successColor;
    if (rate >= 0.6) return AppColors.warningColor;
    return AppColors.errorColor;
  }

  // Time Tab
  Widget _buildTimeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          
          // Time Overview
          _buildTimeOverview(),
          
          const SizedBox(height: 24),
          
          // Time Distribution
          _buildTimeDistribution(),
        ],
      ),
    );
  }

  Widget _buildTimeOverview() {
    final timeAnalytics = ref.watch(timeAnalyticsProvider);
    
    if (timeAnalytics == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time Tracking Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Tracked',
                  '${timeAnalytics.totalTrackedHours.toStringAsFixed(1)}h',
                  Icons.timer,
                  AppColors.primaryColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Avg. Session',
                  '${timeAnalytics.averageSessionDuration.toStringAsFixed(1)}h',
                  Icons.schedule,
                  AppColors.successColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Sessions',
                  timeAnalytics.recentEntries.length.toString(),
                  Icons.play_circle,
                  AppColors.warningColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDistribution() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Distribution by Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          SizedBox(height: 32),
          Center(
            child: Text(
              'Time tracking charts coming soon...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray500,
              ),
            ),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  // Helper methods
  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AnalyticsFilterSheet(),
    );
  }

  void _showExportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExportOptionsSheet(),
    );
  }

  void _clearFilters() {
    final emptyFilter = AnalyticsFilter();
    ref.read(analyticsProvider.notifier).updateFilter(emptyFilter);
  }
}