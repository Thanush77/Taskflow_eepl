import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';

class StatCard extends StatefulWidget {
  final String icon;
  final String title;
  final String value;
  final String change;
  final dynamic gradient;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.change,
    required this.gradient,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: AppTheme.cardDecoration.copyWith(
                gradient: widget.gradient is LinearGradient 
                    ? widget.gradient 
                    : LinearGradient(
                        colors: [widget.gradient, widget.gradient],
                      ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top gradient accent
                    Container(
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: widget.gradient is LinearGradient 
                            ? widget.gradient 
                            : LinearGradient(
                                colors: [widget.gradient, widget.gradient],
                              ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Icon
                    Text(
                      widget.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 12),
                    
                    // Value
                    Text(
                      widget.value,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gray900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Title
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Change indicator
                    Text(
                      widget.change,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}