import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/task_filter.dart';
import '../../providers/filter_provider.dart';
import '../../widgets/loading_widget.dart';
import 'filter_form_screen.dart';

class SavedViewsScreen extends ConsumerStatefulWidget {
  const SavedViewsScreen({super.key});

  @override
  ConsumerState<SavedViewsScreen> createState() => _SavedViewsScreenState();
}

class _SavedViewsScreenState extends ConsumerState<SavedViewsScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load saved views on init
    Future.microtask(() {
      ref.read(filterProvider.notifier).loadSavedViews();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(filterProvider);
    final defaultViews = ref.watch(defaultViewsProvider);
    final personalViews = ref.watch(personalViewsProvider);
    final sharedViews = ref.watch(sharedViewsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.view_list, color: AppColors.primaryColor, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Saved Views',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            ref.read(filterProvider.notifier).refresh();
                          },
                          icon: const Icon(Icons.refresh, color: AppColors.primaryColor),
                          tooltip: 'Refresh',
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const FilterFormScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, color: AppColors.primaryColor),
                          tooltip: 'Create View',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // View categories tabs
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryColor,
                  unselectedLabelColor: AppColors.gray600,
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
                  ),
                  tabs: [
                    Tab(text: 'Default (${defaultViews.length})'),
                    Tab(text: 'Personal (${personalViews.length})'),
                    Tab(text: 'Shared (${sharedViews.length})'),
                  ],
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: filterState.isLoading && filterState.savedViews.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LoadingWidget(),
                        SizedBox(height: 16),
                        Text('Loading saved views...', style: TextStyle(color: AppColors.gray600)),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildViewsList(defaultViews, isDefault: true),
                      _buildViewsList(personalViews),
                      _buildViewsList(sharedViews, isShared: true),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewsList(List<SavedView> views, {bool isDefault = false, bool isShared = false}) {
    if (views.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDefault ? Icons.dashboard_outlined 
                  : isShared ? Icons.share_outlined 
                      : Icons.view_list_outlined,
              size: 64,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              isDefault ? 'No default views'
                  : isShared ? 'No shared views'
                      : 'No personal views',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.gray600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isDefault ? 'System default views will appear here'
                  : isShared ? 'Views shared by your team will appear here'
                      : 'Create your first custom view to get started',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isDefault && !isShared) ...[ 
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FilterFormScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.white,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Create View'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(filterProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: views.length,
        itemBuilder: (context, index) {
          final view = views[index];
          return _buildViewCard(view, isDefault: isDefault, isShared: isShared);
        },
      ),
    );
  }

  Widget _buildViewCard(SavedView view, {bool isDefault = false, bool isShared = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        border: isDefault 
            ? Border.all(color: AppColors.successColor.withValues(alpha: 0.3), width: 1)
            : isShared 
                ? Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3), width: 1)
                : null,
      ),
      child: InkWell(
        onTap: () => _applyView(view),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Type indicator
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (isDefault ? AppColors.successColor 
                          : isShared ? AppColors.primaryColor 
                              : AppColors.gray600).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      isDefault ? Icons.star_outlined 
                          : isShared ? Icons.share_outlined 
                              : Icons.person_outlined,
                      size: 16,
                      color: isDefault ? AppColors.successColor 
                          : isShared ? AppColors.primaryColor 
                              : AppColors.gray600,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          view.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (view.description?.isNotEmpty == true)
                          Text(
                            view.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  
                  if (!isDefault)
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleMenuAction(view, value),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'apply',
                          child: Row(
                            children: [
                              Icon(Icons.filter_list, size: 16, color: AppColors.primaryColor),
                              SizedBox(width: 8),
                              Text('Apply View', style: TextStyle(color: AppColors.primaryColor)),
                            ],
                          ),
                        ),
                        if (!isShared) ...[ 
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 16),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy_outlined, size: 16),
                                SizedBox(width: 8),
                                Text('Duplicate'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 16, color: AppColors.errorColor),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: AppColors.errorColor)),
                              ],
                            ),
                          ),
                        ],
                      ],
                      child: const Icon(
                        Icons.more_vert,
                        color: AppColors.gray400,
                        size: 20,
                      ),
                    )
                  else 
                    IconButton(
                      onPressed: () => _applyView(view),
                      icon: const Icon(Icons.filter_list, color: AppColors.primaryColor),
                      tooltip: 'Apply View',
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Filter details
              _buildFilterSummary(view.filter),
              
              const SizedBox(height: 12),
              
              // Bottom info row
              Row(
                children: [
                  // Sort info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          view.filter.sortOrder == SortOrder.ascending 
                              ? Icons.arrow_upward 
                              : Icons.arrow_downward,
                          size: 12,
                          color: AppColors.gray600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getSortDisplayText(view.filter.sortBy),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.gray600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Share count for shared views
                  if (isShared && view.shareCount != null && view.shareCount! > 0) ...[ 
                    const Icon(Icons.people, size: 14, color: AppColors.gray500),
                    const SizedBox(width: 4),
                    Text(
                      '${view.shareCount}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                  
                  // Creation date
                  if (view.createdAt != null) ...[ 
                    Text(
                      _formatDate(view.createdAt!),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSummary(TaskFilter filter) {
    if (filter.conditions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'No filters',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.gray600,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: filter.conditions.entries.take(3).map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${entry.key}: ${_getConditionSummary(entry.value)}',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList()
        ..addAll(filter.conditions.length > 3 
            ? [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${filter.conditions.length - 3} more',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.gray600,
                    ),
                  ),
                ),
              ] 
            : []),
    );
  }

  String _getConditionSummary(FilterCondition condition) {
    switch (condition.operator) {
      case FilterOperator.equals:
        return '= ${condition.value}';
      case FilterOperator.notEquals:
        return '≠ ${condition.value}';
      case FilterOperator.contains:
        return 'contains "${condition.value}"';
      case FilterOperator.greaterThan:
        return '> ${condition.value}';
      case FilterOperator.lessThan:
        return '< ${condition.value}';
      case FilterOperator.isNull:
        return 'is empty';
      case FilterOperator.isNotNull:
        return 'is not empty';
      case FilterOperator.inList:
        return 'in [${(condition.value as List).take(2).join(", ")}...]';
      default:
        return condition.operator.name;
    }
  }

  String _getSortDisplayText(SortBy sortBy) {
    switch (sortBy) {
      case SortBy.title:
        return 'Title';
      case SortBy.createdAt:
        return 'Created';
      case SortBy.updatedAt:
        return 'Updated';
      case SortBy.dueDate:
        return 'Due Date';
      case SortBy.priority:
        return 'Priority';
      case SortBy.status:
        return 'Status';
      default:
        return sortBy.name;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${difference}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleMenuAction(SavedView view, String action) {
    switch (action) {
      case 'apply':
        _applyView(view);
        break;
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FilterFormScreen(savedView: view),
          ),
        );
        break;
      case 'duplicate':
        _duplicateView(view);
        break;
      case 'delete':
        _deleteView(view);
        break;
    }
  }

  void _applyView(SavedView view) {
    ref.read(activeSavedViewProvider.notifier).state = view;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied view "${view.name}"'),
        backgroundColor: AppColors.successColor,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Go back to tasks screen
    Navigator.of(context).pop();
  }

  void _duplicateView(SavedView view) {
    final duplicatedView = view.copyWith(
      id: null,
      name: '${view.name} (Copy)',
      createdAt: null,
      updatedAt: null,
      shareCount: 0,
      isShared: false,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FilterFormScreen(savedView: duplicatedView),
      ),
    );
  }

  Future<void> _deleteView(SavedView view) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete View'),
        content: Text('Are you sure you want to delete "${view.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorColor),
            child: const Text('Delete', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && view.id != null) {
      final success = await ref.read(filterProvider.notifier).deleteSavedView(view.id!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('View deleted successfully'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    }
  }
}