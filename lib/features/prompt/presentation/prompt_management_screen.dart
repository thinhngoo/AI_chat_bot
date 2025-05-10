import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/prompt.dart';
import '../services/prompt_service.dart';
import 'prompt_list_screen.dart';
import 'create_edit_prompt_screen.dart';
import 'simple_prompt_dialog.dart';

class PromptManagementScreen extends StatefulWidget {
  const PromptManagementScreen({super.key});

  @override
  State<PromptManagementScreen> createState() => _PromptManagementScreenState();
}

class _PromptManagementScreenState extends State<PromptManagementScreen>
    with SingleTickerProviderStateMixin {
  final PromptService _promptService = PromptService();
  final Logger _logger = Logger();

  late TabController _tabController;
  bool _isLoading = false;
  String _errorMessage = '';

  List<Prompt> _publicPrompts = [];
  List<Prompt> _privatePrompts = [];
  List<Prompt> _favoritePrompts = [];
  List<String> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _fetchInitialData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      // Update data when tab changes
      switch (_tabController.index) {
        case 0: // Public prompts tab
          _fetchPublicPrompts();
          break;
        case 1: // Private prompts tab
          _fetchPrivatePrompts();
          break;
        case 2: // Favorites tab
          _fetchFavoritePrompts();
          break;
      }
    }
  }

  Future<void> _fetchInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Fetch categories first
      _availableCategories = await _promptService.getPromptCategories();

      // Fetch prompts based on the active tab
      switch (_tabController.index) {
        case 0:
          await _fetchPublicPrompts();
          break;
        case 1:
          await _fetchPrivatePrompts();
          break;
        case 2:
          await _fetchFavoritePrompts();
          break;
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error fetching initial data: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPublicPrompts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = ''; // Clear previous error messages
      });

      final prompts = await _promptService.getPrompts(isPublic: true);

      if (!mounted) return;

      // Filter out prompts with empty IDs and log them
      final validPrompts = prompts.where((p) => p.id.isNotEmpty).toList();
      final emptyIdPrompts = prompts.where((p) => p.id.isEmpty).toList();
      
      if (emptyIdPrompts.isNotEmpty) {
        _logger.w('Found ${emptyIdPrompts.length} public prompts with empty IDs that were filtered out');
      }

      setState(() {
        _publicPrompts = validPrompts;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error fetching public prompts: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to load public prompts';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPrivatePrompts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final prompts = await _promptService.getPrompts(isPublic: false);

      if (!mounted) return;

      // Filter out prompts with empty IDs and log them
      final validPrompts = prompts.where((p) => p.id.isNotEmpty).toList();
      final emptyIdPrompts = prompts.where((p) => p.id.isEmpty).toList();
      
      if (emptyIdPrompts.isNotEmpty) {
        _logger.w('Found ${emptyIdPrompts.length} private prompts with empty IDs that were filtered out');
      }

      setState(() {
        _privatePrompts = validPrompts;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error fetching private prompts: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to load private prompts';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchFavoritePrompts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final prompts = await _promptService.getPrompts(isFavorite: true);

      if (!mounted) return;

      // Filter out prompts with empty IDs and log them
      final validPrompts = prompts.where((p) => p.id.isNotEmpty).toList();
      final emptyIdPrompts = prompts.where((p) => p.id.isEmpty).toList();
      
      if (emptyIdPrompts.isNotEmpty) {
        _logger.w('Found ${emptyIdPrompts.length} favorite prompts with empty IDs that were filtered out');
      }

      setState(() {
        _favoritePrompts = validPrompts;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error fetching favorite prompts: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to load favorite prompts';
        _isLoading = false;
      });
    }
  }

  void _createPrompt() {
    // Show the simplified prompt dialog instead of navigating to the full screen
    SimplePromptDialog.show(
      context,
      (content) {
        // Refresh the private prompts list after creating a new prompt
        _fetchPrivatePrompts();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prompt Management'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.primary,
                width: 3.0,
              ),
            ),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: theme.colorScheme.outline.withAlpha(184),
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(184),
          tabs: const [
            Tab(text: 'Public'),
            Tab(text: 'Private'),
            Tab(text: 'Favorites'),
          ],
        ),
      ),
      
      body: TabBarView(
        controller: _tabController,
        children: [
          // Public prompts tab
          PromptListScreen(
            prompts: _publicPrompts,
            isLoading: _isLoading,
            errorMessage: _errorMessage,
            isEditable: false,
            onRefresh: _fetchPublicPrompts,
            emptyMessage: 'No public prompts available',
            availableCategories: _availableCategories,
            onPromptToggleFavorite: _handleToggleFavorite,
          ),

          // Private prompts tab
          PromptListScreen(
            prompts: _privatePrompts,
            isLoading: _isLoading,
            errorMessage: _errorMessage,
            isEditable: true,
            onRefresh: _fetchPrivatePrompts,
            onDelete: _handleDeletePrompt,
            onEdit: _handleEditPrompt,
            emptyMessage:
                'No private prompts yet\nCreate one with the + button',
            availableCategories: _availableCategories,
            onPromptToggleFavorite: _handleToggleFavorite,
          ),

          // Favorites tab
          PromptListScreen(
            prompts: _favoritePrompts,
            isLoading: _isLoading,
            errorMessage: _errorMessage,
            isEditable: false,
            onRefresh: _fetchFavoritePrompts,
            emptyMessage:
                'No favorite prompts yet\nAdd some by tapping the star icon',
            availableCategories: _availableCategories,
            onPromptToggleFavorite: _handleToggleFavorite,
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: _createPrompt,
              tooltip: 'Create new prompt',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _handleToggleFavorite(Prompt prompt) async {
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
      
      // Store the previous state for proper error handling
      final previousState = prompt.isFavorite;
      
      // Create a copy with toggled favorite state
      final updatedPrompt = prompt.copyWith(isFavorite: !prompt.isFavorite);
      
      // Update UI immediately for better user experience
      setState(() {
        if (_tabController.index == 0) {
          final index = _publicPrompts.indexWhere((p) => p.id == prompt.id);
          if (index != -1) {
            _publicPrompts[index] = updatedPrompt;
          }
        } else if (_tabController.index == 1) {
          final index = _privatePrompts.indexWhere((p) => p.id == prompt.id);
          if (index != -1) {
            _privatePrompts[index] = updatedPrompt;
          }
        } else if (_tabController.index == 2) {
          final index = _favoritePrompts.indexWhere((p) => p.id == prompt.id);
          if (index != -1) {
            _favoritePrompts[index] = updatedPrompt;
            // In favorites tab, we may need to hide the item if it's being removed from favorites
            if (previousState) {
              _favoritePrompts.removeAt(index);
            }
          }
        }
      });
      
      // Show loading indicator
      final snackBar = ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(previousState 
                  ? 'Removing from favorites...' 
                  : 'Adding to favorites...'),
            ],
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      
      // Call the appropriate API
      bool success;
      if (previousState) {
        success = await _promptService.removePromptFromFavorites(prompt.id);
      } else {
        success = await _promptService.addPromptToFavorites(prompt.id);
      }
      
      // Close the loading snackbar
      snackBar.close();

      if (success) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(previousState
                ? 'Removed from favorites'
                : 'Added to favorites'),
            duration: const Duration(seconds: 2),
          ),
        );

        // Refresh favorites tab if that's where we are
        if (_tabController.index == 2) {
          _fetchFavoritePrompts();
        }
      } else {
        if (!mounted) return;
        
        // Restore original state on failure
        setState(() {
          if (_tabController.index == 0) {
            final index = _publicPrompts.indexWhere((p) => p.id == prompt.id);
            if (index != -1) {
              _publicPrompts[index] = prompt; 
            }
          } else if (_tabController.index == 1) {
            final index = _privatePrompts.indexWhere((p) => p.id == prompt.id);
            if (index != -1) {
              _privatePrompts[index] = prompt; 
            }
          } else if (_tabController.index == 2) {
            _fetchFavoritePrompts(); 
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update favorite status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error toggling favorite: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Refresh all data to ensure UI is consistent with server state
      if (_tabController.index == 0) {
        _fetchPublicPrompts();
      } else if (_tabController.index == 1) {
        _fetchPrivatePrompts();
      } else {
        _fetchFavoritePrompts();
      }
    }
  }

  Future<void> _handleDeletePrompt(Prompt prompt) async {
    try {
      // First verify that the ID is not empty
      if (prompt.id.isEmpty) {
        _logger.e('Cannot delete prompt: ID is empty');
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Cannot delete prompt with empty ID'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Log the ID to help debug
      _logger.i('Attempting to delete prompt with ID: ${prompt.id}');

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

      final success = await _promptService.deletePrompt(prompt.id);

      if (!mounted) return;

      if (success) {
        // Update the UI by removing the deleted prompt
        setState(() {
          _privatePrompts.removeWhere((p) => p.id == prompt.id);
        });
        
        // Also remove from favorites list if present
        if (prompt.isFavorite) {
          _fetchFavoritePrompts();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prompt deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _logger.e('Error deleting prompt: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ignore: unused_element
  Future<void> _deletePrompt(String promptId) async { // Kept for future implementation
    try {
      setState(() {
        _isLoading = true;
      });

      await _promptService.deletePrompt(promptId);

      if (!mounted) return; // Added mounted check

      setState(() {
        _privatePrompts.removeWhere((prompt) => prompt.id == promptId);
        _isLoading = false;
      });

      // Use mounted check before using BuildContext
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prompt deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _logger.e('Error deleting prompt: $e');

      if (!mounted) return; // Added mounted check

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

  void _handleEditPrompt(Prompt prompt) {
    // Validate that the ID is not empty
    if (prompt.id.isEmpty) {
      _logger.e('Cannot edit prompt: ID is empty');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot edit prompt: ID is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditPromptScreen(
          prompt: prompt,
          availableCategories: _availableCategories,
        ),
      ),
    ).then((_) => _fetchPrivatePrompts());
  }
}
