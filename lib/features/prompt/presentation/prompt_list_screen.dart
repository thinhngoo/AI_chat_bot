import 'package:ai_chat_bot/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../models/prompt.dart';
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
          // Search and filter bar
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildSearchBar(isDarkMode),
                // if (widget.availableCategories.isNotEmpty) ...[
                //   const SizedBox(width: 12),
                //   _buildFilterDropdown(),
                // ],
              ],
            ),
          ),

          // Results count
          if (!widget.isLoading &&
              widget.errorMessage.isEmpty &&
              widget.prompts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 26.0),
              child: ResultsCountIndicator(
                filteredCount: _filteredPrompts.length,
                totalCount: widget.prompts.length,
                itemType: 'prompts',
              ),
            ),
          ],

          // Main content
          const SizedBox(height: 12),

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
      child: CustomTextField(
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

  // ignore: unused_element
  Widget _buildFilterDropdown() {
    return DropdownButton<String?>(
      value: _selectedCategory,
      hint: const Text('Category'),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Categories'),
        ),
        ...widget.availableCategories.map((category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          );
        }),
      ],
    );
  }

  Widget _buildPromptCard(Prompt prompt) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = isDarkMode ? AppColors.dark : AppColors.light;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Main content
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  topRight: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
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
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: ListTile(
                    title: Text(
                      prompt.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 70, // Fixed height for content area
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (prompt.description.isNotEmpty) ...[
                                Text(
                                  prompt.description,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context).hintColor,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: Text(
                                    prompt.content,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ] else
                                Expanded(
                                  child: Text(
                                    prompt.content,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (prompt.category.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                Chip(
                                  label: Text(
                                    prompt.category,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  side: BorderSide(color: colors.border),
                                ),
                                const Spacer(),
                                // Display public/private indicator
                                Icon(
                                  prompt.isPublic ? Icons.public : Icons.lock,
                                  size: 16,
                                  color: Theme.of(context).hintColor,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Favorite button
            ClipRRect(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Material(
                child: InkWell(
                  onTap: () {
                    if (widget.onPromptToggleFavorite != null) {
                      widget.onPromptToggleFavorite!(prompt);
                    }
                  },
                  child: Container(
                    width: 40,
                    decoration: BoxDecoration(
                      color: prompt.isFavorite
                          ? colors.yellow
                          : colors.cardForeground.withAlpha(24),
                    ),
                    child: Center(
                      child: Icon(
                        prompt.isFavorite ? Icons.star : Icons.star_border,
                        color: prompt.isFavorite
                            ? colors.yellowForeground
                            : colors.yellow,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
