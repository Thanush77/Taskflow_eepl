import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../providers/task_provider.dart';
import '../../widgets/loading_widget.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  @override
  void initState() {
    super.initState();
    // Load team data on initialization
    Future.microtask(() {
      ref.read(teamProvider.notifier).loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final teamState = ref.watch(teamProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Team Members',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${teamState.users.length} members',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  ref.read(teamProvider.notifier).loadUsers();
                },
                icon: const Icon(
                  Icons.refresh,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Team Grid
          Expanded(
            child: Container(
              decoration: AppTheme.cardDecoration,
              padding: const EdgeInsets.all(20),
              child: teamState.isLoading && teamState.users.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LoadingWidget(),
                          SizedBox(height: 16),
                          Text('Loading team members...', style: TextStyle(color: AppColors.gray600)),
                        ],
                      ),
                    )
                  : teamState.users.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.group,
                                size: 64,
                                color: AppColors.gray300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                teamState.error != null ? 'Error loading team members' : 'No Team Members',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gray500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                teamState.error ?? 'Team members will appear here once they join.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.gray400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (teamState.error != null) ...[
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => ref.read(teamProvider.notifier).loadUsers(),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => ref.read(teamProvider.notifier).loadUsers(),
                          child: GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: MediaQuery.of(context).size.width < 400 ? 0.9 : 0.8,
                            ),
                            itemCount: teamState.users.length,
                            itemBuilder: (context, index) {
                              final user = teamState.users[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(MediaQuery.of(context).size.width < 400 ? 12 : 16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: MediaQuery.of(context).size.width < 400 ? 25 : 30,
                                        backgroundColor: AppColors.primaryColor,
                                        child: Text(
                                          user.initials,
                                          style: TextStyle(
                                            color: AppColors.white,
                                            fontSize: MediaQuery.of(context).size.width < 400 ? 16 : 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Flexible(
                                        child: Text(
                                          user.fullName,
                                          style: TextStyle(
                                            fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.gray900,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Flexible(
                                        child: Text(
                                          user.email,
                                          style: TextStyle(
                                            fontSize: MediaQuery.of(context).size.width < 400 ? 12 : 14,
                                            color: AppColors.gray600,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (user.role != null) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: MediaQuery.of(context).size.width < 400 ? 8 : 10, 
                                            vertical: MediaQuery.of(context).size.width < 400 ? 3 : 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            user.role!.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: MediaQuery.of(context).size.width < 400 ? 10 : 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}