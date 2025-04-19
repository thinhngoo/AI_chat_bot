import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/prompt.dart';
import '../services/prompt_service.dart';

class PromptSelector extends StatefulWidget {
  final Function(String content) onPromptSelected;
  final bool isVisible;
  final String query;
  
  const PromptSelector({
    Key? key,
    required this.onPromptSelected,
    required this.isVisible,
    required this.query,
  }) : super(key: key);

  @override
  State<PromptSelector> createState() => _PromptSelectorState();
}

class _PromptSelectorState extends State<PromptSelector> {
  final PromptService _promptService = PromptService();
  final Logger _logger = Logger();
  
  List<Prompt> _prompts = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _fetchPrompts();
  }
  
  @override
  void didUpdateWidget(PromptSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query && widget.isVisible) {
      _searchPrompts();
    }
  }
  
  Future<void> _fetchPrompts() async {
    if (!widget.isVisible) return;
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      // Fetch a mixture of user's favorite and frequently used prompts
      final favorites = await _promptService.getPrompts(isFavorite: true, limit: 5);
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
    if (!widget.isVisible || widget.query.isEmpty) return;
    
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
    if (!widget.isVisible) return const SizedBox();
    
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 250,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.format_quote, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Select a prompt',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  'Type to search',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Content
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Error: $_errorMessage',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      )
                    : _prompts.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                widget.query.length > 1
                                    ? 'No prompts match your search'
                                    : 'No prompts available',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _prompts.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final prompt = _prompts[index];
                              return ListTile(
                                title: Text(
                                  prompt.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  prompt.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  child: Icon(
                                    _getCategoryIcon(prompt.category),
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 18,
                                  ),
                                ),
                                trailing: prompt.isFavorite
                                    ? const Icon(Icons.star, color: Colors.amber, size: 18)
                                    : null,
                                dense: true,
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