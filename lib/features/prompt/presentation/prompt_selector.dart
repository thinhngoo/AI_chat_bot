import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/prompt.dart';
import '../services/prompt_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/text_field.dart';
import '../../../widgets/information.dart';
import 'simple_prompt_dialog.dart';

class PromptSelector extends StatelessWidget {
  final Function(String content) onPromptSelected;
  final String query;

  const PromptSelector({
    super.key,
    required this.onPromptSelected,
    required this.query,
  });

  static Future<void> show(BuildContext context, String query,
      Function(String content) onPromptSelected) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => PromptSelector(
        onPromptSelected: onPromptSelected,
        query: query,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PromptSelectorContent(
      query: query,
      onPromptSelected: (content) {
        Navigator.of(context).pop();
        onPromptSelected(content);
      },
    );
  }
}

class PromptSelectorContent extends StatefulWidget {
  final Function(String content) onPromptSelected;
  final String query;

  const PromptSelectorContent({
    super.key,
    required this.onPromptSelected,
    required this.query,
  });

  @override
  State<PromptSelectorContent> createState() => _PromptSelectorContentState();
}

class _PromptSelectorContentState extends State<PromptSelectorContent> {
  final PromptService _promptService = PromptService();
  final Logger _logger = Logger();
  final TextEditingController _searchController = TextEditingController();

  List<Prompt> _prompts = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPrompts();

    if (widget.query.isNotEmpty) {
      _searchPrompts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPrompts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Fetch a mixture of user's favorite and frequently used prompts
      final favorites =
          await _promptService.getPrompts(isFavorite: true, limit: 5);
      final allPrompts = await _promptService.getPrompts(limit: 10);

      // Filter out prompts with empty IDs
      final validFavorites = favorites.where((p) => p.id.isNotEmpty).toList();
      final validAllPrompts = allPrompts.where((p) => p.id.isNotEmpty).toList();
      
      final emptyIdCount = favorites.length - validFavorites.length + 
                          allPrompts.length - validAllPrompts.length;
      
      if (emptyIdCount > 0) {
        _logger.w('Found $emptyIdCount prompts with empty IDs that were filtered out from prompt selector');
      }

      // Combine and remove duplicates
      final combinedPrompts = [...validFavorites];
      for (final prompt in validAllPrompts) {
        if (!combinedPrompts.any((p) => p.id == prompt.id)) {
          combinedPrompts.add(prompt);
        }
      }

      if (!mounted) return;

      setState(() {
        _prompts = combinedPrompts;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error fetching prompts for selector: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchPrompts() async {
    if (widget.query.isEmpty) return;

    // Extract search term (remove the slash)
    final searchTerm = widget.query.substring(1).toLowerCase();
    if (searchTerm.isEmpty) {
      _fetchPrompts();
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final results = await _promptService.searchPrompts(searchTerm);

      if (!mounted) return;

      setState(() {
        _prompts = results;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error searching prompts: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(Prompt prompt) async {
    try {
      // Verify that the ID is not empty
      if (prompt.id.isEmpty) {
        _logger.e('Cannot toggle favorite: prompt ID is empty');
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Cannot update favorites for prompt with empty ID'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Log the ID to help debug
      _logger.i('Toggling favorite for prompt with ID: ${prompt.id}, current state: ${prompt.isFavorite}');

      setState(() {
        _isLoading = true;
      });

      bool success;
      if (prompt.isFavorite) {
        success = await _promptService.removePromptFromFavorites(prompt.id);
      } else {
        success = await _promptService.addPromptToFavorites(prompt.id);
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        _fetchPrompts();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(prompt.isFavorite
                ? 'Removed from favorites'
                : 'Added to favorites'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error toggling favorite status: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editPrompt(Prompt prompt) {
    // Validate that the ID is not empty
    if (prompt.id.isEmpty) {
      _logger.e('Cannot edit prompt: prompt ID is empty');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot edit prompt: ID is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    SimplePromptDialog.showEdit(
      context,
      prompt,
      (content) {
        _fetchPrompts();
      },
    );
  }

  Future<void> _deletePrompt(Prompt prompt) async {
    // Validate that the ID is not empty
    if (prompt.id.isEmpty) {
      _logger.e('Cannot delete prompt: prompt ID is empty');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete prompt: ID is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prompt'),
        content: Text('Are you sure you want to delete "${prompt.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final success = await _promptService.deletePrompt(prompt.id);

      if (!mounted) return;

      if (success) {
        _fetchPrompts();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prompt deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error deleting prompt: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colors = isDarkMode ? AppColors.dark : AppColors.light;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Text(
                  'Select a prompt',
                  style: theme.textTheme.headlineMedium,
                ),
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: const EdgeInsets.all(8),
                    iconSize: 24,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: CustomTextField(
              controller: _searchController,
              label: '',
              hintText: 'Search prompts...',
              prefixIcon: Icons.search,
              darkMode: isDarkMode,
              onChanged: (value) {
                if (value.isEmpty) {
                  _fetchPrompts();
                } else {
                  setState(() {
                    _searchPrompts();
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: _isLoading
                ? InformationIndicator(
                    variant: InformationVariant.loading,
                    message: 'Loading prompts...',
                  )
                : _errorMessage.isNotEmpty
                    ? InformationIndicator(
                        variant: InformationVariant.error,
                        message: 'Error: $_errorMessage',
                      )
                    : _prompts.isEmpty
                        ? InformationIndicator(
                            variant: InformationVariant.info,
                            message: 'No prompts available',
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            itemCount: _prompts.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: 1,
                              indent: 70,
                            ),
                            itemBuilder: (context, index) {
                              final prompt = _prompts[index];
                              return ListTile(
                                title: Text(
                                  prompt.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  prompt.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.muted,
                                  ),
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: colors.muted.withAlpha(60),
                                  child: Icon(
                                    _getCategoryIcon(prompt.category),
                                    color: colors.cardForeground,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        prompt.isFavorite
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: prompt.isFavorite
                                            ? Colors.amber
                                            : colors.muted,
                                        size: 22,
                                      ),
                                      onPressed: () => _toggleFavorite(prompt),
                                      tooltip: prompt.isFavorite
                                          ? 'Remove from favorites'
                                          : 'Add to favorites',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        color: colors.muted,
                                        size: 20,
                                      ),
                                      onPressed: () => _editPrompt(prompt),
                                      tooltip: 'Edit prompt',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: colors.muted,
                                        size: 20,
                                      ),
                                      onPressed: () => _deletePrompt(prompt),
                                      tooltip: 'Delete prompt',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  widget.onPromptSelected(prompt.content);
                                },
                              );
                            },
                          ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                SimplePromptDialog.show(context, null);
              },
              icon: const Icon(Icons.add),
              label: const Text('Create New Prompt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'programming':
        return Icons.code;
      case 'writing':
        return Icons.edit_document;
      case 'business':
        return Icons.business;
      case 'education':
        return Icons.school;
      case 'health':
        return Icons.health_and_safety;
      case 'entertainment':
        return Icons.movie;
      default:
        return Icons.article;
    }
  }
}
