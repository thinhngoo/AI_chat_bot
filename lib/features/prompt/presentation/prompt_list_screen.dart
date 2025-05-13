import 'package:flutter/material.dart';
import '../models/prompt.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/category_constants.dart';
import '../../../widgets/information.dart';
import '../../../widgets/text_field.dart';
import 'prompt_drawer.dart';

class PromptListScreen extends StatefulWidget {
  final bool isLoading;
  final bool isEditable;
  final String errorMessage;
  final String emptyMessage;

  final List<Prompt> prompts;
  final List<String> availableCategories;
  final Function()? onRefresh;
  final Function(Prompt prompt)? onDelete;
  final Function(Prompt prompt)? onEdit;
  final Function(Prompt prompt)? onPromptToggleFavorite;
  final Function(Prompt prompt)? onPromptSelected;

  const PromptListScreen({
    super.key,
    required this.prompts,
    this.availableCategories = const [],
    this.isLoading = false,
    this.isEditable = false,
    this.errorMessage = '',
    this.emptyMessage = 'No prompts available',
    this.onRefresh,
    this.onDelete,
    this.onEdit,
    this.onPromptToggleFavorite,
    this.onPromptSelected,
  });

  @override
  State<PromptListScreen> createState() => _PromptListScreenState();
}

class _PromptListScreenState extends State<PromptListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  List<Prompt> get _filteredPrompts {
    if (_searchQuery.isEmpty && _selectedCategory == null) {
      return widget.prompts;
    }

    return widget.prompts.where((prompt) {
      // Filter by category if selected
      if (_selectedCategory != null && prompt.category != _selectedCategory) {
        return false;
      }

      // Filter by search query if not empty
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return prompt.title.toLowerCase().contains(query) ||
            prompt.description.toLowerCase().contains(query) ||
            prompt.content.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: widget.onRefresh != null
          ? () async => await widget.onRefresh!()
          : () async {},
      child: Column(
        children: [
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildSearchBar(isDarkMode),
              ],
            ),
          ),

          // Category chips for horizontal scrolling
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: CategoryConstants.categories.length,
                itemBuilder: (context, index) {
                  final category = CategoryConstants.categories[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(
                        category.substring(0, 1).toUpperCase() +
                            category.substring(1),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _selectedCategory == category
                                  ? Colors.white
                                  : CategoryConstants.getCategoryColor(
                                      category,
                                      darkMode: isDarkMode,
                                    ),
                            ),
                      ),
                      selected: _selectedCategory == category,
                      showCheckmark: false,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                        });
                      },
                      avatar: Icon(
                        CategoryConstants.getCategoryIcon(category),
                        size: 16,
                        color: _selectedCategory == category
                            ? Colors.white
                            : CategoryConstants.getCategoryColor(
                                category,
                                darkMode: isDarkMode,
                              ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: CategoryConstants.getCategoryColor(
                            category,
                            darkMode: isDarkMode,
                          ).withAlpha(40),
                        ),
                      ),
                      backgroundColor: _selectedCategory == category
                          ? CategoryConstants.getCategoryColor(
                              category,
                              darkMode: isDarkMode,
                            )
                          : CategoryConstants.getCategoryColor(
                              category,
                              darkMode: isDarkMode,
                            ).withAlpha(40),
                      selectedColor: CategoryConstants.getCategoryColor(
                        category,
                        darkMode: isDarkMode,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Results count
          if (!widget.isLoading &&
              widget.errorMessage.isEmpty &&
              widget.prompts.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(left: 20.0, top: 8.0, bottom: 12.0),
              child: ResultsCountIndicator(
                filteredCount: _filteredPrompts.length,
                totalCount: widget.prompts.length,
                itemType: 'prompts',
              ),
            ),

          Expanded(
            child: widget.isLoading
                ? InformationIndicator(
                    message: 'Loading...',
                    variant: InformationVariant.loading,
                  )
                : widget.errorMessage.isNotEmpty
                    ? InformationIndicator(
                        message: 'Error: ${widget.errorMessage}',
                        variant: InformationVariant.error,
                        onButtonPressed: widget.onRefresh,
                        buttonText: 'Retry',
                      )
                    : widget.prompts.isEmpty
                        ? InformationIndicator(
                            message: widget.emptyMessage,
                            variant: InformationVariant.info,
                          )
                        : _filteredPrompts.isEmpty
                            ? InformationIndicator(
                                message: 'No prompts match your search',
                                variant: InformationVariant.info,
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 30),
                                itemCount: _filteredPrompts.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final prompt = _filteredPrompts[index];
                                  return _buildPromptCard(prompt);
                                },
                              ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Expanded(
      child: CommonTextField(
        controller: _searchController,
        label: 'Search',
        hintText: 'Search prompts...',
        prefixIcon: Icons.search,
        darkMode: isDarkMode,
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                },
              )
            : null,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildPromptCard(Prompt prompt) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = isDarkMode ? AppColors.dark : AppColors.light;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // If it's a private prompt and edit function is provided, show the edit drawer
          if (!prompt.isPublic && widget.onEdit != null) {
            PromptDrawer.showEdit(
              context,
              prompt,
              (_) {
                // Refresh after edit
                if (widget.onRefresh != null) {
                  widget.onRefresh!();
                }
              },
            );
          }
          // If it's a public prompt, show it in view-only mode
          else if (prompt.isPublic) {
            PromptDrawer.showViewOnly(
              context,
              prompt,
              onFavoriteToggled: (_) {
                // Refresh when favorites are toggled
                if (widget.onRefresh != null) {
                  widget.onRefresh!();
                }
              },
            );
          }
          // Fallback for other cases (directly select the prompt)
          else if (widget.onPromptSelected != null) {
            widget.onPromptSelected!(prompt);
            Navigator.of(context).pop();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row with icon and action buttons
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prompt icon with category color
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: CategoryConstants.getCategoryColor(
                        prompt.category,
                        darkMode: isDarkMode,
                      ).withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        CategoryConstants.getCategoryIcon(prompt.category),
                        size: 24,
                        color: CategoryConstants.getCategoryColor(
                          prompt.category,
                          darkMode: isDarkMode,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Action buttons
                  Row(
                    children: [
                      // Favorite button
                      IconButton(
                        icon: Icon(
                          prompt.isFavorite ? Icons.star : Icons.star_border,
                          color: colors.yellow,
                        ),
                        onPressed: () {
                          if (widget.onPromptToggleFavorite != null) {
                            widget.onPromptToggleFavorite!(prompt);
                          }
                        },
                        tooltip: prompt.isFavorite
                            ? 'Remove from favorites'
                            : 'Add to favorites',
                        visualDensity: VisualDensity.compact,
                      ),

                      if (widget.isEditable && widget.onDelete != null) ...[
                        const SizedBox(width: 4),
                        // Delete button
                        IconButton(
                          icon: Icon(Icons.delete_outline),
                          color: Theme.of(context).colorScheme.error,
                          onPressed: () {
                            if (widget.onDelete != null) {
                              widget.onDelete!(prompt);
                            }
                          },
                          tooltip: 'Delete',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Prompt title and description
              Text(
                prompt.title,
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),

              if (prompt.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 1.0),
                  child: Text(
                    prompt.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              const SizedBox(height: 8),
              Text(
                prompt.content,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (prompt.category.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: [
                      Chip(
                        label: Text(
                          prompt.category.substring(0, 1).toUpperCase() +
                              prompt.category.substring(1),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: CategoryConstants.getCategoryColor(
                                  prompt.category,
                                  darkMode: isDarkMode,
                                ),
                              ),
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(
                          color: CategoryConstants.getCategoryColor(
                            prompt.category,
                            darkMode: isDarkMode,
                          ).withAlpha(100),
                        ),
                        backgroundColor: CategoryConstants.getCategoryColor(
                          prompt.category,
                          darkMode: isDarkMode,
                        ).withAlpha(25),
                        avatar: Icon(
                          CategoryConstants.getCategoryIcon(prompt.category),
                          size: 16,
                          color: CategoryConstants.getCategoryColor(
                            prompt.category,
                            darkMode: isDarkMode,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Display public/private indicator
                      Icon(
                        prompt.isPublic ? Icons.public : Icons.lock,
                        size: 20,
                        color: Theme.of(context).hintColor,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
