import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 Reports & Analytics',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Comprehensive insights into your team\'s productivity',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  // TODO: Refresh reports
                },
                icon: const Icon(
                  Icons.refresh,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filters Section
          Container(
            decoration: AppTheme.cardDecoration,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Reports',
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
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () {
                          // TODO: Show date picker
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () {
                          // TODO: Show date picker
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Apply filters
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Apply Filters'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Reset filters
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gray200,
                        foregroundColor: AppColors.gray700,
                      ),
                      child: const Text('Reset'),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.download),
                      onSelected: (value) {
                        // TODO: Export report
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'csv',
                          child: Row(
                            children: [
                              Icon(Icons.table_chart),
                              SizedBox(width: 8),
                              Text('Export CSV'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'pdf',
                          child: Row(
                            children: [
                              Icon(Icons.picture_as_pdf),
                              SizedBox(width: 8),
                              Text('Export PDF'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'excel',
                          child: Row(
                            children: [
                              Icon(Icons.grid_on),
                              SizedBox(width: 8),
                              Text('Export Excel'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Reports Content
          Expanded(
            child: Container(
              decoration: AppTheme.cardDecoration,
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics,
                      size: 64,
                      color: AppColors.gray300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Reports Coming Soon',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Advanced analytics and reporting features will be available here.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.gray400,
                      ),
                      textAlign: TextAlign.center,
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