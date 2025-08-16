import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class TimeTrackerWidget extends ConsumerStatefulWidget {
  final Task task;
  final bool showCompact;

  const TimeTrackerWidget({
    required this.task,
    this.showCompact = false,
    super.key,
  });

  @override
  ConsumerState<TimeTrackerWidget> createState() => _TimeTrackerWidgetState();
}

class _TimeTrackerWidgetState extends ConsumerState<TimeTrackerWidget> {
  Timer? _timer;
  Duration _currentDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _checkActiveTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _checkActiveTimer() {
    final timeTrackingNotifier = ref.read(timeTrackingProvider.notifier);
    if (timeTrackingNotifier.isTimerActive(widget.task.id!)) {
      _startLocalTimer();
    }
  }

  void _startLocalTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          final timeTrackingNotifier = ref.read(timeTrackingProvider.notifier);
          _currentDuration = timeTrackingNotifier.getTimerDuration(widget.task.id!);
        });
      }
    });
  }

  void _stopLocalTimer() {
    _timer?.cancel();
    setState(() {
      _currentDuration = Duration.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeTrackingState = ref.watch(timeTrackingProvider);
    final timeTrackingNotifier = ref.read(timeTrackingProvider.notifier);
    final isActive = timeTrackingNotifier.isTimerActive(widget.task.id!);
    final isLoading = timeTrackingState.isLoading;

    if (widget.showCompact) {
      return _buildCompactView(isActive, isLoading);
    }

    return _buildExpandedView(isActive, isLoading);
  }

  Widget _buildCompactView(bool isActive, bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryColor.withOpacity(0.1) : AppColors.gray100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.timer : Icons.timer_outlined,
            size: 16,
            color: isActive ? AppColors.primaryColor : AppColors.gray600,
          ),
          const SizedBox(width: 4),
          Text(
            _formatDuration(isActive ? _currentDuration : Duration(hours: widget.task.actualHours?.toInt() ?? 0)),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.primaryColor : AppColors.gray700,
            ),
          ),
          const SizedBox(width: 8),
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            InkWell(
              onTap: () => _toggleTimer(isActive),
              borderRadius: BorderRadius.circular(12),
              child: Icon(
                isActive ? Icons.pause_circle_filled : Icons.play_circle_filled,
                size: 20,
                color: isActive ? AppColors.errorColor : AppColors.successColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandedView(bool isActive, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.primaryColor : AppColors.gray200,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isActive ? AppColors.primaryColor : Colors.black).withOpacity(0.05),
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
              Icon(
                Icons.timer,
                color: isActive ? AppColors.primaryColor : AppColors.gray600,
              ),
              const SizedBox(width: 8),
              const Text(
                'Time Tracking',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
              const Spacer(),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.successColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.successColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Session',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(isActive ? _currentDuration : Duration.zero),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.task.actualHours?.toStringAsFixed(1) ?? '0.0'}h',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : () => _toggleTimer(isActive),
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? AppColors.errorColor : AppColors.primaryColor,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(
                isActive ? Icons.stop : Icons.play_arrow,
                size: 20,
              ),
              label: Text(
                isActive ? 'Stop Timer' : 'Start Timer',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (widget.task.estimatedHours > 0) ...[
            const SizedBox(height: 12),
            _buildProgressBar(),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final actualHours = widget.task.actualHours ?? 0;
    final estimatedHours = widget.task.estimatedHours;
    final progress = (actualHours / estimatedHours).clamp(0.0, 1.0);
    final isOvertime = actualHours > estimatedHours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gray600,
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isOvertime ? AppColors.errorColor : AppColors.gray700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.gray200,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOvertime ? AppColors.errorColor : AppColors.primaryColor,
          ),
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${actualHours.toStringAsFixed(1)}h',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.gray500,
              ),
            ),
            Text(
              'Est: ${estimatedHours}h',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _toggleTimer(bool isActive) async {
    final taskId = widget.task.id!;
    final timeTrackingNotifier = ref.read(timeTrackingProvider.notifier);

    if (isActive) {
      await timeTrackingNotifier.pauseTimer(taskId);
      _stopLocalTimer();
    } else {
      await timeTrackingNotifier.startTimer(taskId);
      _startLocalTimer();
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}