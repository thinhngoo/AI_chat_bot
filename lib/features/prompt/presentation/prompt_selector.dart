import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/prompt.dart';
import '../services/prompt_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/text_field.dart';
import '../../../widgets/information.dart';
import 'prompt_drawer.dart';
import 'prompt_management_screen.dart';

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

      // Fetch user's favorite prompts first with the correct parameter
      final favorites =
          await _promptService.getPrompts(isFavorite: true, limit: 5);

      // Then fetch some general prompts - explicitly NOT filtering for favorites
      final allPrompts = await _promptService.getPrompts(limit: 10);

      // Filter out prompts with empty IDs
      final validFavorites = favorites.where((p) => p.id.isNotEmpty).toList();
      final validAllPrompts = allPrompts.where((p) => p.id.isNotEmpty).toList();

      final emptyIdCount = favorites.length -
          validFavorites.length +
          allPrompts.length -
          validAllPrompts.length;

      if (emptyIdCount > 0) {
        _logger.w(
            'Found $emptyIdCount prompts with empty IDs that were filtered out from prompt selector');
      }

      // Combine and remove duplicates - put favorites first
      final combinedPrompts = [...validFavorites];
      for (final prompt in validAllPrompts) {
        // Only add non-favorite prompts that aren't already in the list
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

        GlobalSnackBar.show(
          context: context,
          message: 'Error: Cannot update favorites for prompt with empty ID',
          variant: SnackBarVariant.error,
        );
        return;
      }

      // Log the ID to help debug
      _logger.i(
          'Toggling favorite for prompt with ID: ${prompt.id}, current state: ${prompt.isFavorite}');

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

        GlobalSnackBar.show(
          context: context,
          message: prompt.isFavorite
              ? 'Removed from favorites'
              : 'Added to favorites',
          variant: SnackBarVariant.success,
        );
      }
    } catch (e) {
      _logger.e('Error toggling favorite status: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      GlobalSnackBar.show(
        context: context,
        message: 'Error: ${e.toString()}',
        variant: SnackBarVariant.error,
      );
    }
  }

  void _editPrompt(Prompt prompt) {
    // Validate that the ID is not empty
    if (prompt.id.isEmpty) {
      _logger.e('Cannot edit prompt: prompt ID is empty');

      if (!mounted) return;

      GlobalSnackBar.show(
        context: context,
        message: 'Cannot edit prompt: ID is empty',
        variant: SnackBarVariant.error,
      );
      return;
    }

    // Check if the prompt is public
    if (prompt.isPublic) {
      _logger.e('Cannot edit prompt: public prompts cannot be edited');

      if (!mounted) return;

      GlobalSnackBar.show(
        context: context,
        message: 'Public prompts cannot be edited',
        variant: SnackBarVariant.error,
      );
      return;
    }

    PromptDrawer.showEdit(
      context,
      prompt,
      (content) {
        // Refresh the list after editing
        _fetchPrompts();
      },
    );
  }

  void _navigateToPromptManagement() {
    Navigator.of(context).pop(); // Close the selector first
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PromptManagementScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = isDarkMode ? AppColors.dark : AppColors.light;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DrawerTopIndicator(),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: Icon(Icons.settings_outlined,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(180)),
                    onPressed: _navigateToPromptManagement,
                    padding: EdgeInsets.zero,
                    iconSize: 24,
                    constraints: const BoxConstraints(),
                    tooltip: 'Manage Prompts',
                  ),
                ),
                Text(
                  'Select a prompt',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
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
            child: CommonTextField(
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
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(
                              16.0,
                              0,
                              16.0,
                              16.0,
                            ),
                            itemCount: _prompts.length,
                            itemBuilder: (context, index) {
                              final prompt = _prompts[index];
                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.fromLTRB(16.0, 0, 4.0, 0),
                                title: Text(
                                  prompt.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                subtitle: Text(
                                  prompt.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: colors.muted,
                                      ),
                                ),
                                trailing: SizedBox(
                                  width: 120,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Show edit button only for private prompts
                                      if (!prompt.isPublic)
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit_outlined,
                                            color: colors.muted,
                                            size: 24,
                                          ),
                                          onPressed: () => _editPrompt(prompt),
                                          tooltip: 'Edit prompt',
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(),
                                        ),

                                      IconButton(
                                        icon: Icon(
                                          prompt.isFavorite
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: prompt.isFavorite
                                              ? colors.yellow
                                              : colors.muted,
                                          size: 28,
                                        ),
                                        onPressed: () =>
                                            _toggleFavorite(prompt),
                                        tooltip: prompt.isFavorite
                                            ? 'Remove from favorites'
                                            : 'Add to favorites',
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  widget.onPromptSelected(prompt.content);
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
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
