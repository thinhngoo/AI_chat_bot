import 'package:ai_chat_bot/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../models/prompt.dart';
import '../../../widgets/text_field.dart';

class PromptListScreen extends StatefulWidget {
  final List<Prompt> prompts;
  final bool isLoading;
  final String errorMessage;
  final bool isEditable;
  final Function()? onRefresh;
  final Function(Prompt prompt)? onDelete;
  final Function(Prompt prompt)? onEdit;
  final Function(Prompt prompt)? onPromptToggleFavorite;
  final Function(Prompt prompt)? onPromptSelected;
  final String emptyMessage;
  final List<String> availableCategories;

  const PromptListScreen({
    Key? key,
    required this.prompts,
    this.isLoading = false,
    this.errorMessage = '',
    this.isEditable = false,
    this.onRefresh,
    this.onDelete,
    this.onEdit,
    this.onPromptToggleFavorite,
    this.onPromptSelected,
    this.emptyMessage = 'No prompts available',
    this.availableCategories = const [],
  }) : super(key: key);

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

  void _promptTapped(Prompt prompt) {
    if (widget.onPromptSelected != null) {
      widget.onPromptSelected!(prompt);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colors = isDarkMode ? AppColors.dark : AppColors.light;

    return RefreshIndicator(
      onRefresh: widget.onRefresh != null
          ? () async => await widget.onRefresh!()
          : () async {},
      child: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                // Search field
                Expanded(
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
                ),

                // Category filter dropdown
                if (widget.availableCategories.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  DropdownButton<String?>(
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
                      }).toList(),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Results count
          if (!widget.isLoading &&
              widget.errorMessage.isEmpty &&
              widget.prompts.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 26.0, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Showing ${_filteredPrompts.length} of ${widget.prompts.length} prompts',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.muted),
                  ),
                ],
              ),
            ),

          // Main content
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : widget.errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${widget.errorMessage}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: widget.onRefresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : widget.prompts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.note_alt_outlined,
                                  size: 72,
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  widget.emptyMessage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _filteredPrompts.isEmpty
                            ? Center(
                                child: Text(
                                  'No prompts match your search',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: _filteredPrompts.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
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

  Widget _buildPromptCard(Prompt prompt) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colors = isDarkMode ? AppColors.dark : AppColors.light;

    return Card(
      elevation: 2,
      child: ListTile(
        onTap: () {
          if (widget.onPromptSelected != null) {
            widget.onPromptSelected!(prompt);
            Navigator.of(context).pop();
          }
        },
        title: Text(
          prompt.title,
          style: theme.textTheme.headlineLarge,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (prompt.category.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 6.0),
                child: Chip(
                  label: Text(
                    prompt.category,
                    style: theme.textTheme.bodySmall,
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: colors.border),
                ),
              ),
            if (prompt.description.isNotEmpty) ...[
              Text(
                prompt.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.muted,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              padding: const EdgeInsets.all(8.0),
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 48, // Minimum height for approximately 2 lines
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colors.border,
                ),
              ),
              child: Text(
                prompt.content.length > 100
                    ? '${prompt.content.substring(0, 100)}...'
                    : prompt.content,
                style: TextStyle(
                  color: colors.inputForeground,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        trailing: widget.isEditable &&
                (widget.onEdit != null || widget.onDelete != null)
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => widget.onEdit!(prompt),
                    ),
                  if (widget.onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => widget.onDelete!(prompt),
                      color: Colors.red,
                    ),
                ],
              )
            : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
