import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/prompt.dart';
import '../services/prompt_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/text_field.dart';
import '../../../widgets/information.dart';

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

      // Combine and remove duplicates
      final combinedPrompts = [...favorites];
      for (final prompt in allPrompts) {
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
          // Handle bar indicator
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

          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40), // Balance the layout
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

          // Search field
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
          // Content
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
                            separatorBuilder: (context, index) => const SizedBox(
                              height: 1,
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
                                trailing: prompt.isFavorite
                                    ? const Icon(Icons.star,
                                        color: Colors.amber, size: 18)
                                    : null,
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
