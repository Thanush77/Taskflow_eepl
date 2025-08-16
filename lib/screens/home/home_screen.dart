import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'tasks_screen.dart';
import 'team_screen.dart';
import 'reports_screen.dart';
import 'calendar_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showUserMenu(BuildContext context) {
    final user = ref.read(authProvider).user;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryColor,
                child: Text(
                  user?.initials ?? 'U',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(user?.fullName ?? 'User'),
              subtitle: Text(user?.email ?? ''),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to profile
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.errorColor),
              title: const Text(
                'Logout',
                style: TextStyle(color: AppColors.errorColor),
              ),
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      body: Container(
        decoration: AppTheme.primaryGradientDecoration,
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Container(
                decoration: AppTheme.glassDecoration,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TaskFlow',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                          Text(
                            'Welcome back, ${user?.fullName.split(' ').first ?? 'User'}!',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showUserMenu(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  user?.fullName ?? 'User',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const Text(
                                  'Productivity Pro',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            backgroundColor: AppColors.white,
                            child: Text(
                              user?.initials ?? 'U',
                              style: const TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: AppTheme.glassDecoration,
                child: Row(
                  children: [
                    _buildNavTab(0, '📊', 'Dashboard'),
                    _buildNavTab(1, '✅', 'Tasks'),
                    _buildNavTab(2, '📅', 'Calendar'),
                    _buildNavTab(3, '👥', 'Team'),
                    _buildNavTab(4, '📈', 'Reports'),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  children: const [
                    DashboardScreen(),
                    TasksScreen(),
                    CalendarScreen(),
                    TeamScreen(),
                    ReportsScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: (_selectedIndex == 1 || _selectedIndex == 2) // Show on Tasks and Calendar tabs
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Open create task modal
              },
              backgroundColor: AppColors.primaryColor,
              child: const Icon(Icons.add, color: AppColors.white),
            )
          : null,
    );
  }

  Widget _buildNavTab(int index, String emoji, String label) {
    final isSelected = _selectedIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}