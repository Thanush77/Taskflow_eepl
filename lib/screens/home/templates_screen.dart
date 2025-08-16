import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/task_template.dart';
import '../../models/task.dart';
import '../../providers/template_provider.dart';
import '../../widgets/loading_widget.dart';
import 'template_form_screen.dart';

class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: TemplateCategory.values.length + 1, vsync: this);
    
    // Load templates on init
    Future.microtask(() {
      ref.read(templateProvider.notifier).loadTemplates();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templateState = ref.watch(templateProvider);
    final searchQuery = ref.watch(templateSearchProvider);
    final filteredTemplates = ref.watch(filteredTemplatesProvider);

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
                    const Icon(Icons.description_outlined, color: AppColors.primaryColor, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Templates',
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
                            ref.read(templateProvider.notifier).refresh();
                          },
                          icon: const Icon(Icons.refresh, color: AppColors.primaryColor),
                          tooltip: 'Refresh',
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const TemplateFormScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, color: AppColors.primaryColor),
                          tooltip: 'Create Template',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search templates...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              ref.read(templateSearchProvider.notifier).state = '';
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.gray100,
                  ),
                  onChanged: (value) {
                    ref.read(templateSearchProvider.notifier).state = value;
                  },
                ),
                const SizedBox(height: 16),
                
                // Category tabs
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.primaryColor,
                  unselectedLabelColor: AppColors.gray600,
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
                  ),
                  tabs: [
                    const Tab(text: 'All'),
                    ...TemplateCategory.values.map((category) => 
                      Tab(text: category.name.toUpperCase())
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: templateState.isLoading && templateState.templates.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LoadingWidget(),
                        SizedBox(height: 16),
                        Text('Loading templates...', style: TextStyle(color: AppColors.gray600)),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTemplateList(searchQuery.isNotEmpty 
                          ? filteredTemplates 
                          : templateState.templates.where((t) => t.isActive).toList()),
                      ...TemplateCategory.values.map((category) =>
                        _buildTemplateList(searchQuery.isNotEmpty
                            ? filteredTemplates.where((t) => t.category == category).toList()
                            : ref.watch(templatesByCategoryProvider(category))),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateList(List<TaskTemplate> templates) {
    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              ref.watch(templateSearchProvider).isNotEmpty
                  ? 'No templates match your search'
                  : 'No templates found',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.gray600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ref.watch(templateSearchProvider).isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'Create your first template to get started',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(templateProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          return _buildTemplateCard(template);
        },
      ),
    );
  }

  Widget _buildTemplateCard(TaskTemplate template) {
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
        border: Border(
          left: BorderSide(
            color: _getCategoryColor(template.category),
            width: 4,
          ),
        ),
      ),
      child: InkWell(
        onTap: () => _showTemplateDetails(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      template.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(template, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'use',
                        child: Row(
                          children: [
                            Icon(Icons.add_task, size: 16, color: AppColors.primaryColor),
                            SizedBox(width: 8),
                            Text('Use Template', style: TextStyle(color: AppColors.primaryColor)),
                          ],
                        ),
                      ),
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
                    child: const Icon(
                      Icons.more_vert,
                      color: AppColors.gray400,
                      size: 20,
                    ),
                  ),
                ],
              ),
              
              // Description
              if (template.description.isNotEmpty) ...[ 
                const SizedBox(height: 8),
                Text(
                  template.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.gray600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Details row
              Row(
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(template.category).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      template.categoryDisplayText,
                      style: TextStyle(
                        color: _getCategoryColor(template.category),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Priority indicator
                  Icon(
                    _getPriorityIcon(template.defaultPriority),
                    color: _getPriorityColor(template.defaultPriority),
                    size: 16,
                  ),
                  
                  const Spacer(),
                  
                  // Usage count
                  Row(
                    children: [
                      const Icon(Icons.trending_up, size: 16, color: AppColors.gray500),
                      const SizedBox(width: 4),
                      Text(
                        '${template.usageCount ?? 0} uses',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Bottom row with stats
              Row(
                children: [
                  // Subtasks count
                  if (template.subtaskTemplates.isNotEmpty) ...[ 
                    Icon(
                      Icons.checklist,
                      size: 14,
                      color: AppColors.gray500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${template.subtaskTemplates.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  
                  // Automation rules count
                  if (template.automationRules.isNotEmpty) ...[ 
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: AppColors.gray500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${template.automationRules.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  
                  const Spacer(),
                  
                  // Tags (first 2)
                  if (template.defaultTags.isNotEmpty)
                    ...template.defaultTags.take(2).map((tag) {
                      return Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.gray700,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(TaskTemplate template, String action) {
    switch (action) {
      case 'use':
        _useTemplate(template);
        break;
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TemplateFormScreen(template: template),
          ),
        );
        break;
      case 'duplicate':
        _duplicateTemplate(template);
        break;
      case 'delete':
        _deleteTemplate(template);
        break;
    }
  }

  void _useTemplate(TaskTemplate template) {
    // TODO: Implement template usage - create task from template
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Using template "${template.name}" - Task creation will be implemented'),
        backgroundColor: AppColors.successColor,
      ),
    );
  }

  void _duplicateTemplate(TaskTemplate template) {
    final duplicatedTemplate = template.copyWith(
      id: null,
      name: '${template.name} (Copy)',
      createdAt: null,
      updatedAt: null,
      usageCount: 0,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TemplateFormScreen(template: duplicatedTemplate),
      ),
    );
  }

  Future<void> _deleteTemplate(TaskTemplate template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "${template.name}"? This action cannot be undone.'),
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

    if (confirm == true && template.id != null) {
      final success = await ref.read(templateProvider.notifier).deleteTemplate(template.id!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template deleted successfully'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    }
  }

  void _showTemplateDetails(TaskTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TemplateDetailsBottomSheet(template: template),
    );
  }

  Color _getCategoryColor(TemplateCategory category) {
    switch (category) {
      case TemplateCategory.general:
        return Colors.blue;
      case TemplateCategory.development:
        return Colors.green;
      case TemplateCategory.design:
        return Colors.purple;
      case TemplateCategory.marketing:
        return Colors.orange;
      case TemplateCategory.meeting:
        return Colors.teal;
      case TemplateCategory.project:
        return Colors.indigo;
      case TemplateCategory.maintenance:
        return Colors.brown;
      case TemplateCategory.review:
        return Colors.pink;
    }
  }

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.lowest:
      case TaskPriority.low:
        return Icons.keyboard_arrow_down;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.high:
      case TaskPriority.critical:
        return Icons.keyboard_arrow_up;
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.lowest:
        return Colors.grey;
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.critical:
        return Colors.purple;
    }
  }
}

class _TemplateDetailsBottomSheet extends StatelessWidget {
  final TaskTemplate template;

  const _TemplateDetailsBottomSheet({required this.template});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Template name and category
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(template.category).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          template.categoryDisplayText,
                          style: TextStyle(
                            color: _getCategoryColor(template.category),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  if (template.description.isNotEmpty) ...[ 
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      template.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.gray700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Subtasks
                  if (template.subtaskTemplates.isNotEmpty) ...[ 
                    const Text(
                      'Subtask Templates',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...template.subtaskTemplates.map((subtask) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    subtask.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (subtask.isOptional)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Optional',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (subtask.description?.isNotEmpty == true) ...[ 
                              const SizedBox(height: 4),
                              Text(
                                subtask.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.gray600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                  
                  // Tags
                  if (template.defaultTags.isNotEmpty) ...[ 
                    const Text(
                      'Default Tags',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: template.defaultTags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(TemplateCategory category) {
    switch (category) {
      case TemplateCategory.general:
        return Colors.blue;
      case TemplateCategory.development:
        return Colors.green;
      case TemplateCategory.design:
        return Colors.purple;
      case TemplateCategory.marketing:
        return Colors.orange;
      case TemplateCategory.meeting:
        return Colors.teal;
      case TemplateCategory.project:
        return Colors.indigo;
      case TemplateCategory.maintenance:
        return Colors.brown;
      case TemplateCategory.review:
        return Colors.pink;
    }
  }
}