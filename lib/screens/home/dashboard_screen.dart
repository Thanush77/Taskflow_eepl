import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/dashboard_widgets.dart';
import '../../utils/responsive_utils.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(dashboardProvider.notifier).loadDashboardStats();
      },
      child: SingleChildScrollView(
        padding: ResponsiveUtils.getScreenPadding(context),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Overview",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await ref.read(dashboardProvider.notifier).loadDashboardStats();
                  },
                  icon: const Icon(
                    Icons.refresh,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Statistics Cards
            if (dashboardState.isLoading && dashboardState.stats == null)
              const Center(child: LoadingWidget(color: AppColors.white))
            else if (dashboardState.error != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.errorColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: AppColors.errorColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dashboardState.error!,
                        style: const TextStyle(color: AppColors.errorColor),
                      ),
                    ),
                  ],
                ),
              )
            else
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: ResponsiveUtils.getGridCrossAxisCount(context),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: ResponsiveUtils.getCardAspectRatio(context),
                children: [
                  DashboardStatsCard(
                    icon: Icons.task_alt,
                    title: 'Total Tasks',
                    value: dashboardState.stats.totalTasks.toString(),
                    subtitle: '+2 from yesterday',
                    color: AppColors.primaryColor,
                    showTrend: true,
                    trend: 5.2,
                  ),
                  DashboardStatsCard(
                    icon: Icons.check_circle,
                    title: 'Completed',
                    value: dashboardState.stats.completedTasks.toString(),
                    subtitle: '+5 this week',
                    color: AppColors.successColor,
                    showTrend: true,
                    trend: 12.5,
                  ),
                  DashboardStatsCard(
                    icon: Icons.pending_actions,
                    title: 'In Progress',
                    value: dashboardState.stats.inProgressTasks.toString(),
                    subtitle: 'Active tasks',
                    color: AppColors.warningColor,
                  ),
                  DashboardStatsCard(
                    icon: Icons.person,
                    title: 'My Tasks',
                    value: dashboardState.stats.myTasks.toString(),
                    subtitle: 'Assigned to me',
                    color: AppColors.primaryColor,
                  ),
                  DashboardStatsCard(
                    icon: Icons.schedule,
                    title: 'Overdue',
                    value: dashboardState.stats.overdueTasks.toString(),
                    subtitle: 'Need attention',
                    color: AppColors.errorColor,
                    showTrend: true,
                    trend: -15.3,
                  ),
                  DashboardStatsCard(
                    icon: Icons.trending_up,
                    title: 'Completion Rate',
                    value: '${(dashboardState.stats.completionRate * 100).toInt()}%',
                    subtitle: 'Overall progress',
                    color: AppColors.successColor,
                    showTrend: true,
                    trend: 8.7,
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Real-time metrics and productivity
            Row(
              children: [
                Expanded(
                  child: RealTimeMetricsWidget(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ProductivityCircleWidget(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Task distribution and team performance
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TaskDistributionChart(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TeamPerformanceWidget(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick Actions
            QuickActionsWidget(
              onCreateTask: () {
                // Navigate to task creation
                Navigator.of(context).pushNamed('/create-task');
              },
              onViewTasks: () {
                // Navigate to tasks tab
                Navigator.of(context).pushNamed('/tasks');
              },
              onViewReports: () {
                // Navigate to reports
                Navigator.of(context).pushNamed('/reports');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gray200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }
}