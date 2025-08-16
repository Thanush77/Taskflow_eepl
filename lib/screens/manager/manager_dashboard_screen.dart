import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/manager_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_display.dart';
import '../../utils/responsive_utils.dart';
import '../../constants/app_colors.dart';
// import 'manager_tasks_screen.dart';
// import 'employee_performance_screen.dart';

class ManagerDashboardScreen extends ConsumerStatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  ConsumerState<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends ConsumerState<ManagerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(managerDashboardProvider.notifier).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(managerDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Manager Dashboard',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              ref.read(managerDashboardProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh, color: AppColors.white),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(managerDashboardProvider.notifier).refresh(),
        child: SingleChildScrollView(
          padding: ResponsiveUtils.getScreenPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (dashboardState.isLoading && dashboardState.data == null)
                const Center(child: LoadingWidget(color: AppColors.primary))
              else if (dashboardState.error != null && dashboardState.data == null)
                ErrorDisplay(
                  message: dashboardState.error!,
                  onRetry: () => ref.read(managerDashboardProvider.notifier).refresh(),
                )
              else if (dashboardState.data != null) ...[
                _buildQuickActions(context),
                const SizedBox(height: 24),
                _buildTaskStatusOverview(dashboardState.data!),
                const SizedBox(height: 24),
                _buildEmployeePerformanceSection(context, dashboardState.data!),
                const SizedBox(height: 24),
                _buildOverdueTasksSection(dashboardState.data!),
                const SizedBox(height: 24),
                _buildRecentActivitySection(dashboardState.data!),
                const SizedBox(height: 24),
                _buildProductivityChart(dashboardState.data!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ResponsiveLayout(
              mobile: Column(
                children: [
                  _buildActionButton(
                    'View All Tasks',
                    Icons.assignment,
                    () => _showTasksScreen(context),
                  ),
                  const SizedBox(height: 8),
                  _buildActionButton(
                    'Employee Performance',
                    Icons.people,
                    () => _showEmployeePerformance(context),
                  ),
                ],
              ),
              tablet: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'View All Tasks',
                      Icons.assignment,
                      () => _showTasksScreen(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      'Employee Performance',
                      Icons.people,
                      () => _showEmployeePerformance(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.all(16),
        minimumSize: const Size.fromHeight(50),
      ),
    );
  }

  Widget _buildTaskStatusOverview(data) {
    final taskStats = data.taskStats;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Status Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: taskStats.map<PieChartSectionData>((stat) {
                    Color color;
                    switch (stat.status) {
                      case 'completed':
                        color = Colors.green;
                        break;
                      case 'in_progress':
                        color = Colors.blue;
                        break;
                      case 'pending':
                        color = Colors.orange;
                        break;
                      default:
                        color = Colors.grey;
                    }
                    
                    return PieChartSectionData(
                      color: color,
                      value: stat.count.toDouble(),
                      title: '${stat.count}',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: taskStats.map<Widget>((stat) {
                Color color;
                switch (stat.status) {
                  case 'completed':
                    color = Colors.green;
                    break;
                  case 'in_progress':
                    color = Colors.blue;
                    break;
                  case 'pending':
                    color = Colors.orange;
                    break;
                  default:
                    color = Colors.grey;
                }
                
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${stat.status.replaceAll('_', ' ').toUpperCase()}: ${stat.count}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeePerformanceSection(BuildContext context, data) {
    final employeeStats = data.employeeStats.take(5).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Top Performers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => _showEmployeePerformance(context),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...employeeStats.map((employee) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      employee.fullName.isNotEmpty ? employee.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${employee.completedTasks}/${employee.totalTasks} tasks completed',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: employee.completionRate >= 80 ? Colors.green : 
                             employee.completionRate >= 50 ? Colors.orange : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${employee.completionRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueTasksSection(data) {
    final overdueTasks = data.overdueTasks;
    
    if (overdueTasks.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 48, color: Colors.green),
              const SizedBox(height: 8),
              const Text(
                'No Overdue Tasks!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Great job keeping everything on track.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Overdue Tasks (${overdueTasks.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...overdueTasks.take(5).map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                leading: Icon(
                  Icons.assignment_late,
                  color: task.priority == 'high' ? Colors.red : 
                         task.priority == 'medium' ? Colors.orange : Colors.yellow,
                ),
                title: Text(task.title),
                subtitle: Text(
                  'Assigned to: ${task.assignedToName ?? 'Unassigned'}',
                ),
                trailing: task.dueDate != null 
                  ? Text(
                      '${DateTime.now().difference(task.dueDate!).inDays} days overdue',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    )
                  : null,
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(data) {
    final recentActivity = data.recentActivity.take(5).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...recentActivity.map((activity) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: activity.status == 'completed' ? Colors.green :
                             activity.status == 'in_progress' ? Colors.blue : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Status: ${activity.status.replaceAll('_', ' ')} • ${activity.assignedToName ?? 'Unassigned'}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatTimeAgo(activity.updatedAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductivityChart(data) {
    final metrics = data.productivityMetrics.take(7).toList();
    
    if (metrics.isEmpty) return const SizedBox();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Productivity Trend (Last 7 Days)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < metrics.length) {
                            return Text(
                              '${metrics[index].date.day}/${metrics[index].date.month}',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: metrics.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.completedCount.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showTasksScreen(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tasks screen coming soon!')),
    );
  }

  void _showEmployeePerformance(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Employee performance screen coming soon!')),
    );
  }
}