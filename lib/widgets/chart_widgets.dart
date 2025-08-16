import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../constants/app_colors.dart';
import '../providers/analytics_provider.dart';

// Pie Chart Widget for distribution data
class PieChartWidget extends StatelessWidget {
  final List<ChartData> data;
  final String title;
  final double size;
  final bool showLegend;
  final bool showValues;

  const PieChartWidget({
    required this.data,
    required this.title,
    this.size = 200,
    this.showLegend = true,
    this.showValues = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyChart();
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pie chart
              SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: PieChartPainter(data, showValues),
                ),
              ),
              if (showLegend) ...{
                const SizedBox(width: 16),
                // Legend
                Expanded(
                  child: _buildLegend(),
                ),
              },
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray700,
                    ),
                  ),
                  Text(
                    '${item.value.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildEmptyChart() {
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
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 32),
          Icon(
            Icons.pie_chart,
            size: 48,
            color: AppColors.gray400,
          ),
          const SizedBox(height: 8),
          Text(
            'No data available',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for pie chart
class PieChartPainter extends CustomPainter {
  final List<ChartData> data;
  final bool showValues;

  PieChartPainter(this.data, this.showValues);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    
    double startAngle = -math.pi / 2;
    final total = data.fold<double>(0, (sum, item) => sum + item.value);

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final sweepAngle = (item.value / total) * 2 * math.pi;
      
      // Draw pie slice
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      // Draw value text if enabled
      if (showValues && item.value > 5) { // Only show if slice is large enough
        final textAngle = startAngle + sweepAngle / 2;
        final textRadius = radius * 0.7;
        final textCenter = Offset(
          center.dx + textRadius * math.cos(textAngle),
          center.dy + textRadius * math.sin(textAngle),
        );
        
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${item.value.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            textCenter.dx - textPainter.width / 2,
            textCenter.dy - textPainter.height / 2,
          ),
        );
      }
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Bar Chart Widget
class BarChartWidget extends StatelessWidget {
  final List<ChartData> data;
  final String title;
  final double height;
  final bool showValues;
  final String? subtitle;

  const BarChartWidget({
    required this.data,
    required this.title,
    this.height = 200,
    this.showValues = true,
    this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyChart();
    }

    final maxValue = data.map((e) => e.value).reduce(math.max);

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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          if (subtitle != null) ...{
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gray600,
              ),
            ),
          },
          const SizedBox(height: 16),
          SizedBox(
            height: height,
            child: CustomPaint(
              size: Size(double.infinity, height),
              painter: BarChartPainter(data, maxValue, showValues),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      height: height + 80,
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
          const SizedBox(height: 16),
          Icon(
            Icons.bar_chart,
            size: 48,
            color: AppColors.gray400,
          ),
          const SizedBox(height: 8),
          Text(
            'No data available',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for bar chart
class BarChartPainter extends CustomPainter {
  final List<ChartData> data;
  final double maxValue;
  final bool showValues;

  BarChartPainter(this.data, this.maxValue, this.showValues);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxValue == 0) return;

    final barWidth = (size.width - 32) / data.length;
    final chartHeight = size.height - 40;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final barHeight = (item.value / maxValue) * chartHeight;
      final x = 16 + i * barWidth + barWidth * 0.1;
      final barWidthActual = barWidth * 0.8;

      // Draw bar
      final barPaint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - barHeight - 20, barWidthActual, barHeight),
        const Radius.circular(4),
      );
      
      canvas.drawRRect(barRect, barPaint);

      // Draw value text if enabled
      if (showValues) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: item.value.toStringAsFixed(0),
            style: const TextStyle(
              color: AppColors.gray700,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            x + barWidthActual / 2 - textPainter.width / 2,
            size.height - barHeight - 35,
          ),
        );
      }

      // Draw label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: item.label.length > 8 ? '${item.label.substring(0, 8)}...' : item.label,
          style: const TextStyle(
            color: AppColors.gray600,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(
          x + barWidthActual / 2 - labelPainter.width / 2,
          size.height - 15,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Line Chart Widget
class LineChartWidget extends StatelessWidget {
  final List<TimeSeriesData> data;
  final String title;
  final double height;
  final String? subtitle;
  final Color lineColor;

  const LineChartWidget({
    required this.data,
    required this.title,
    this.height = 200,
    this.subtitle,
    this.lineColor = AppColors.primaryColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyChart();
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          if (subtitle != null) ...{
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gray600,
              ),
            ),
          },
          const SizedBox(height: 16),
          SizedBox(
            height: height,
            child: CustomPaint(
              size: Size(double.infinity, height),
              painter: LineChartPainter(data, lineColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      height: height + 80,
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
          const SizedBox(height: 16),
          Icon(
            Icons.show_chart,
            size: 48,
            color: AppColors.gray400,
          ),
          const SizedBox(height: 8),
          Text(
            'No data available',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for line chart
class LineChartPainter extends CustomPainter {
  final List<TimeSeriesData> data;
  final Color lineColor;

  LineChartPainter(this.data, this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final maxValue = data.map((e) => e.value).reduce(math.max);
    final minValue = data.map((e) => e.value).reduce(math.min);
    final valueRange = maxValue - minValue;

    if (valueRange == 0) return;

    final stepX = (size.width - 32) / (data.length - 1);
    final chartHeight = size.height - 40;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = AppColors.gray200
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = 20 + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(16, y),
        Offset(size.width - 16, y),
        gridPaint,
      );
    }

    // Draw line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = 16 + i * stepX;
      final y = size.height - 20 - ((data[i].value - minValue) / valueRange) * chartHeight;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, linePaint);

    // Draw points
    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = 16 + i * stepX;
      final y = size.height - 20 - ((data[i].value - minValue) / valueRange) * chartHeight;
      
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
      
      // Draw point outline
      final outlinePaint = Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 2, outlinePaint);
    }

    // Draw value labels
    for (int i = 0; i < data.length; i++) {
      if (i % math.max(1, data.length ~/ 6) == 0) { // Show labels for every nth point
        final x = 16 + i * stepX;
        final labelPainter = TextPainter(
          text: TextSpan(
            text: _formatDate(data[i].date),
            style: const TextStyle(
              color: AppColors.gray600,
              fontSize: 9,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        
        labelPainter.layout();
        labelPainter.paint(
          canvas,
          Offset(
            x - labelPainter.width / 2,
            size.height - 12,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Progress Ring Widget
class ProgressRingWidget extends StatelessWidget {
  final double value;
  final String title;
  final String? subtitle;
  final Color color;
  final double size;

  const ProgressRingWidget({
    required this.value,
    required this.title,
    this.subtitle,
    this.color = AppColors.primaryColor,
    this.size = 120,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          if (subtitle != null) ...{
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gray600,
              ),
            ),
          },
          const SizedBox(height: 16),
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: ProgressRingPainter(value, color),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(value * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                    Text(
                      'Complete',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for progress ring
class ProgressRingPainter extends CustomPainter {
  final double value;
  final Color color;

  ProgressRingPainter(this.value, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;

    // Draw background ring
    final backgroundPaint = Paint()
      ..color = AppColors.gray200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress ring
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Data classes for charts
class ChartData {
  final String label;
  final double value;
  final Color color;

  ChartData({
    required this.label,
    required this.value,
    required this.color,
  });
}

class TimeSeriesData {
  final DateTime date;
  final double value;

  TimeSeriesData({
    required this.date,
    required this.value,
  });
}

// Analytics Chart Consumer Widgets

// Task Distribution Pie Chart
class TaskDistributionPieChart extends ConsumerWidget {
  final String distributionType; // 'category', 'priority', 'status'

  const TaskDistributionPieChart({
    required this.distributionType,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAnalytics = ref.watch(taskAnalyticsProvider);
    
    if (taskAnalytics == null) {
      return const PieChartWidget(
        data: [],
        title: 'Task Distribution',
      );
    }

    List<ChartData> chartData = [];
    String title = 'Task Distribution';

    switch (distributionType) {
      case 'category':
        title = 'Tasks by Category';
        chartData = taskAnalytics.distributionStats.byCategory
            .map((dist) => ChartData(
                  label: dist.category,
                  value: dist.percentage,
                  color: dist.color,
                ))
            .toList();
        break;
      case 'priority':
        title = 'Tasks by Priority';
        chartData = taskAnalytics.distributionStats.byPriority
            .map((dist) => ChartData(
                  label: dist.priority,
                  value: dist.percentage,
                  color: dist.color,
                ))
            .toList();
        break;
      case 'status':
        title = 'Tasks by Status';
        chartData = taskAnalytics.distributionStats.byStatus
            .map((dist) => ChartData(
                  label: dist.status,
                  value: dist.percentage,
                  color: dist.color,
                ))
            .toList();
        break;
    }

    return PieChartWidget(
      data: chartData,
      title: title,
    );
  }
}

// Task Completion Trend Line Chart
class TaskCompletionTrendChart extends ConsumerWidget {
  const TaskCompletionTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAnalytics = ref.watch(taskAnalyticsProvider);
    
    if (taskAnalytics == null) {
      return const LineChartWidget(
        data: [],
        title: 'Task Completion Trend',
      );
    }

    final chartData = taskAnalytics.trendStats.dailyTrends
        .map((trend) => TimeSeriesData(
              date: trend.date,
              value: trend.completed.toDouble(),
            ))
        .toList();

    return LineChartWidget(
      data: chartData,
      title: 'Task Completion Trend',
      subtitle: 'Daily completed tasks over time',
      lineColor: AppColors.successColor,
    );
  }
}

// Team Performance Bar Chart
class TeamPerformanceBarChart extends ConsumerWidget {
  const TeamPerformanceBarChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAnalytics = ref.watch(teamAnalyticsProvider);
    
    if (teamAnalytics == null) {
      return const BarChartWidget(
        data: [],
        title: 'Team Performance',
      );
    }

    final chartData = teamAnalytics.memberPerformance
        .map((member) => ChartData(
              label: member.name,
              value: member.completionRate * 100,
              color: AppColors.primaryColor,
            ))
        .toList();

    return BarChartWidget(
      data: chartData,
      title: 'Team Performance',
      subtitle: 'Completion rate by team member',
    );
  }
}

// Productivity Score Ring
class ProductivityScoreRing extends ConsumerWidget {
  const ProductivityScoreRing({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productivityAnalytics = ref.watch(productivityAnalyticsProvider);
    
    if (productivityAnalytics == null) {
      return const ProgressRingWidget(
        value: 0.0,
        title: 'Productivity Score',
      );
    }

    return ProgressRingWidget(
      value: productivityAnalytics.overallProductivityScore / 100,
      title: 'Productivity Score',
      subtitle: 'Overall performance metric',
      color: _getProductivityColor(productivityAnalytics.overallProductivityScore),
    );
  }

  Color _getProductivityColor(double score) {
    if (score >= 80) return AppColors.successColor;
    if (score >= 60) return AppColors.warningColor;
    return AppColors.errorColor;
  }
}