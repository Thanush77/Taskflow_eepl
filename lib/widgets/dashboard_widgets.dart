import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../models/dashboard_stats.dart';
import '../providers/dashboard_provider.dart';
import '../providers/websocket_provider.dart';
import 'user_presence_widget.dart';

class DashboardStatsCard extends ConsumerWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool showTrend;
  final double? trend;

  const DashboardStatsCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.color = AppColors.primaryColor,
    this.showTrend = false,
    this.trend,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const Spacer(),
              if (showTrend && trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trend! >= 0 
                        ? AppColors.successColor.withValues(alpha: 0.1)
                        : AppColors.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend! >= 0 ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: trend! >= 0 ? AppColors.successColor : AppColors.errorColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${trend!.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: trend! >= 0 ? AppColors.successColor : AppColors.errorColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width < 400 ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.gray600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.gray500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class RealTimeMetricsWidget extends ConsumerWidget {
  const RealTimeMetricsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realTimeMetrics = ref.watch(realTimeMetricsProvider);
    final isConnected = ref.watch(isConnectedProvider);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isConnected 
                      ? AppColors.successColor.withValues(alpha: 0.1)
                      : AppColors.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isConnected ? Icons.wifi : Icons.wifi_off,
                  color: isConnected ? AppColors.successColor : AppColors.errorColor,
                  size: 10,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Live Metrics',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCompactMetricRow('Active', realTimeMetrics.activeUsers.toString(), Icons.people, AppColors.primaryColor),
              const SizedBox(height: 3),
              _buildCompactMetricRow('Progress', realTimeMetrics.tasksInProgress.toString(), Icons.pending_actions, AppColors.warningColor),
              const SizedBox(height: 3),
              _buildCompactMetricRow('Updates', realTimeMetrics.recentUpdates.toString(), Icons.update, AppColors.successColor),
              const SizedBox(height: 3),
              _buildCompactMetricRow('Last', _formatTimestamp(realTimeMetrics.timestamp), Icons.access_time, AppColors.gray600),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetricRow(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 8, color: color),
        const SizedBox(width: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: AppColors.gray600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: color),
              const SizedBox(width: 1),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 7,
              color: AppColors.gray600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}

class ProductivityCircleWidget extends ConsumerWidget {
  const ProductivityCircleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final completionRate = dashboardState.stats.completionRate;
    final productivityScore = dashboardState.stats.productivityScore;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Productivity Score',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: productivityScore / 100,
                  strokeWidth: 8,
                  backgroundColor: AppColors.gray200,
                  valueColor: AlwaysStoppedAnimation(
                    _getProductivityColor(productivityScore),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${productivityScore.toInt()}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray900,
                        ),
                      ),
                      Text(
                        'SCORE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildScoreIndicator('Completion', '${(completionRate * 100).toInt()}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreIndicator(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
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
        ),
      ],
    );
  }

  Color _getProductivityColor(double score) {
    if (score >= 80) return AppColors.successColor;
    if (score >= 60) return AppColors.warningColor;
    return AppColors.errorColor;
  }
}

class TaskDistributionChart extends ConsumerWidget {
  const TaskDistributionChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryBreakdown = ref.watch(categoryBreakdownProvider);
    final priorityDistribution = ref.watch(priorityDistributionProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          
          // Category breakdown
          if (categoryBreakdown.isNotEmpty) ...[
            const Text(
              'By Category',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(height: 8),
            ...categoryBreakdown.take(5).map((category) => 
              _buildDistributionBar(
                category.category,
                category.count,
                category.percentage / 100,
                _getCategoryColor(category.category),
              ),
            ),
          ],
          
          if (categoryBreakdown.isNotEmpty && priorityDistribution.isNotEmpty)
            const SizedBox(height: 16),
          
          // Priority distribution
          if (priorityDistribution.isNotEmpty) ...[
            const Text(
              'By Priority',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(height: 8),
            ...priorityDistribution.map((priority) => 
              _buildDistributionBar(
                priority.priority,
                priority.count,
                priority.percentage / 100,
                _getPriorityColor(priority.priority),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDistributionBar(String label, int count, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.gray600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'development':
        return AppColors.primaryColor;
      case 'design':
        return Colors.purple;
      case 'marketing':
        return Colors.orange;
      case 'research':
        return Colors.teal;
      case 'planning':
        return Colors.indigo;
      case 'testing':
        return AppColors.warningColor;
      default:
        return AppColors.gray600;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return AppColors.errorColor;
      case 'high':
        return Colors.orange;
      case 'medium':
        return AppColors.warningColor;
      case 'low':
        return AppColors.primaryColor;
      case 'lowest':
        return AppColors.gray600;
      default:
        return AppColors.gray600;
    }
  }
}

class TeamPerformanceWidget extends ConsumerWidget {
  const TeamPerformanceWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamPerformance = ref.watch(teamPerformanceProvider);
    final onlineUsers = ref.watch(onlineUsersProvider);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Team Performance',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: AppColors.successColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${onlineUsers.length} online',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.successColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...teamPerformance.take(5).map((member) => 
            _buildTeamMemberItem(member, onlineUsers.contains(member.userId)),
          ),
          if (teamPerformance.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No team performance data available',
                  style: TextStyle(
                    color: AppColors.gray500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberItem(TeamMemberStats member, bool isOnline) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.gray300,
                child: Text(
                  member.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.successColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
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
                  '${member.completedTasks}/${member.assignedTasks} tasks completed',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: _getCompletionRateColor(member.completionRate).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
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
}

class QuickActionsWidget extends ConsumerWidget {
  final VoidCallback? onCreateTask;
  final VoidCallback? onViewTasks;
  final VoidCallback? onViewReports;

  const QuickActionsWidget({
    this.onCreateTask,
    this.onViewTasks,
    this.onViewReports,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
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
                child: _buildActionButton(
                  'Create Task',
                  Icons.add_circle_outline,
                  AppColors.primaryColor,
                  onCreateTask,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'View Tasks',
                  Icons.list_alt,
                  AppColors.successColor,
                  onViewTasks,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Reports',
                  Icons.analytics_outlined,
                  AppColors.warningColor,
                  onViewReports,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}