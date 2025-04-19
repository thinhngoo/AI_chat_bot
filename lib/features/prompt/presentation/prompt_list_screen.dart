import 'package:flutter/material.dart';
import '../models/prompt.dart';

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
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return RefreshIndicator(
      onRefresh: widget.onRefresh != null 
          ? () async => await widget.onRefresh!() 
          : () async {},
      child: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search prompts...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
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
          if (!widget.isLoading && widget.errorMessage.isEmpty && widget.prompts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    'Showing ${_filteredPrompts.length} of ${widget.prompts.length} prompts',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
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
                                  color: theme.colorScheme.primary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  widget.emptyMessage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredPrompts.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final prompt = _filteredPrompts[index];
                                  return _buildPromptCard(context, prompt);
                                },
                              ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPromptCard(BuildContext context, Prompt prompt) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: widget.onPromptSelected != null 
            ? () => widget.onPromptSelected!(prompt) 
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and favorite action
              Row(
                children: [
                  Expanded(
                    child: Text(
                      prompt.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.onPromptToggleFavorite != null)
                    IconButton(
                      icon: Icon(
                        prompt.isFavorite ? Icons.star : Icons.star_border,
                        color: prompt.isFavorite ? Colors.amber : Colors.grey,
                      ),
                      onPressed: () => widget.onPromptToggleFavorite!(prompt),
                      tooltip: prompt.isFavorite ? 'Remove from favorites' : 'Add to favorites',
                    ),
                ],
              ),
              
              // Category chip
              if (prompt.category.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Chip(
                    label: Text(
                      prompt.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    backgroundColor: theme.colorScheme.primary,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              
              // Description
              Text(
                prompt.description,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Content preview
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  prompt.content.length > 100
                      ? '${prompt.content.substring(0, 100)}...'
                      : prompt.content,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              
              // Actions row (only for editable prompts)
              if (widget.isEditable && (widget.onEdit != null || widget.onDelete != null))
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.onEdit != null)
                        TextButton.icon(
                          onPressed: () => widget.onEdit!(prompt),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                        ),
                      if (widget.onDelete != null) ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => widget.onDelete!(prompt),
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Delete'),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
              
              // Author and date info
              if (prompt.authorName != null || prompt.createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      if (prompt.authorName != null) ...[
                        Icon(
                          Icons.person,
                          size: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          prompt.authorName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(prompt.updatedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
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