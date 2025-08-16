import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../models/task_template.dart';
import '../providers/template_provider.dart';

class TemplateSelectionDialog extends ConsumerStatefulWidget {
  final Function(TaskTemplate) onTemplateSelected;

  const TemplateSelectionDialog({
    required this.onTemplateSelected,
    super.key,
  });

  @override
  ConsumerState<TemplateSelectionDialog> createState() => _TemplateSelectionDialogState();
}

class _TemplateSelectionDialogState extends ConsumerState<TemplateSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TemplateCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Load templates if not already loaded
    Future.microtask(() {
      final templateState = ref.read(templateProvider);
      if (templateState.templates.isEmpty && !templateState.isLoading) {
        ref.read(templateProvider.notifier).loadTemplates();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TaskTemplate> _getFilteredTemplates() {
    final templateState = ref.watch(templateProvider);
    var templates = templateState.templates.where((t) => t.isActive).toList();

    // Filter by category
    if (_selectedCategory != null) {
      templates = templates.where((t) => t.category == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      templates = templates.where((template) {
        return template.name.toLowerCase().contains(query) ||
               template.description.toLowerCase().contains(query) ||
               template.defaultTags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // Sort by usage count (most popular first)
    templates.sort((a, b) => (b.usageCount ?? 0).compareTo(a.usageCount ?? 0));

    return templates;
  }

  @override
  Widget build(BuildContext context) {
    final templateState = ref.watch(templateProvider);
    final filteredTemplates = _getFilteredTemplates();
    final popularTemplates = ref.watch(popularTemplatesProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, color: AppColors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Choose Template',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.white),
                  ),
                ],
              ),
            ),
            
            // Search and filters
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search templates...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
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
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Category filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('All', null),
                        const SizedBox(width: 8),
                        ...TemplateCategory.values.map((category) =>
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildCategoryChip(
                              category.name.toUpperCase(),
                              category,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Templates list
            Expanded(
              child: templateState.isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.primaryColor),
                          SizedBox(height: 16),
                          Text('Loading templates...', style: TextStyle(color: AppColors.gray600)),
                        ],
                      ),
                    )
                  : filteredTemplates.isEmpty
                      ? Center(
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
                                _searchQuery.isNotEmpty 
                                    ? 'No templates match your search'
                                    : 'No templates available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.gray600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your search or category filter',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.gray500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Create Task Without Template'),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Popular templates (if no search/filter)
                            if (_searchQuery.isEmpty && _selectedCategory == null && popularTemplates.isNotEmpty) ...[ 
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Text(
                                  'Popular Templates',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gray700,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: popularTemplates.take(5).length,
                                  itemBuilder: (context, index) {
                                    final template = popularTemplates[index];
                                    return _buildPopularTemplateCard(template);
                                  },
                                ),
                              ),
                              const Divider(),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Text(
                                  'All Templates',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gray700,
                                  ),
                                ),
                              ),
                            ],
                            
                            // All templates list
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: filteredTemplates.length + 1, // +1 for "No template" option
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return _buildNoTemplateOption();
                                  }
                                  final template = filteredTemplates[index - 1];
                                  return _buildTemplateItem(template);
                                },
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

  Widget _buildCategoryChip(String label, TemplateCategory? category) {
    final isSelected = _selectedCategory == category;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
      },
      backgroundColor: AppColors.gray100,
      selectedColor: AppColors.primaryColor.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryColor : AppColors.gray700,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildPopularTemplateCard(TaskTemplate template) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => _selectTemplate(template),
        borderRadius: BorderRadius.circular(8),
        child: Container(
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
                      template.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(template.category).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      template.categoryDisplayText,
                      style: TextStyle(
                        fontSize: 10,
                        color: _getCategoryColor(template.category),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                template.description,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.gray600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.trending_up, size: 12, color: AppColors.gray500),
                  const SizedBox(width: 4),
                  Text(
                    '${template.usageCount ?? 0}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.gray500,
                    ),
                  ),
                  const Spacer(),
                  if (template.subtaskTemplates.isNotEmpty) ...[ 
                    const Icon(Icons.checklist, size: 12, color: AppColors.gray500),
                    const SizedBox(width: 2),
                    Text(
                      '${template.subtaskTemplates.length}',
                      style: TextStyle(
                        fontSize: 10,
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

  Widget _buildNoTemplateOption() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(), // Close dialog without template
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.note_add_outlined, size: 20, color: AppColors.gray600),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create without template',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.gray900,
                      ),
                    ),
                    Text(
                      'Start with a blank task',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.gray400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateItem(TaskTemplate template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _selectTemplate(template),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getCategoryColor(template.category).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(template.category),
                  size: 20,
                  color: _getCategoryColor(template.category),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            template.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.gray900,
                            ),
                          ),
                        ),
                        if (template.usageCount != null && template.usageCount! > 0) ...[ 
                          const Icon(Icons.trending_up, size: 14, color: AppColors.gray500),
                          const SizedBox(width: 4),
                          Text(
                            '${template.usageCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (template.subtaskTemplates.isNotEmpty || template.defaultTags.isNotEmpty) ...[ 
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (template.subtaskTemplates.isNotEmpty) ...[ 
                            const Icon(Icons.checklist, size: 12, color: AppColors.gray500),
                            const SizedBox(width: 4),
                            Text(
                              '${template.subtaskTemplates.length} subtasks',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.gray500,
                              ),
                            ),
                          ],
                          if (template.subtaskTemplates.isNotEmpty && template.defaultTags.isNotEmpty)
                            const Text(' • ', style: TextStyle(color: AppColors.gray500, fontSize: 10)),
                          if (template.defaultTags.isNotEmpty) ...[ 
                            const Icon(Icons.tag, size: 12, color: AppColors.gray500),
                            const SizedBox(width: 4),
                            Text(
                              '${template.defaultTags.length} tags',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.gray500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.gray400),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTemplate(TaskTemplate template) {
    // Increment usage count
    if (template.id != null) {
      ref.read(templateProvider.notifier).incrementUsageCount(template.id!);
    }
    
    // Return the selected template
    widget.onTemplateSelected(template);
    Navigator.of(context).pop();
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

  IconData _getCategoryIcon(TemplateCategory category) {
    switch (category) {
      case TemplateCategory.general:
        return Icons.task_outlined;
      case TemplateCategory.development:
        return Icons.code_outlined;
      case TemplateCategory.design:
        return Icons.palette_outlined;
      case TemplateCategory.marketing:
        return Icons.campaign_outlined;
      case TemplateCategory.meeting:
        return Icons.meeting_room_outlined;
      case TemplateCategory.project:
        return Icons.folder_outlined;
      case TemplateCategory.maintenance:
        return Icons.build_outlined;
      case TemplateCategory.review:
        return Icons.rate_review_outlined;
    }
  }
}