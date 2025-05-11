import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/prompt.dart';
import '../services/prompt_service.dart';
import 'prompt_list_screen.dart';
import 'prompt_drawer.dart';
import '../../../widgets/information.dart';
import '../../../widgets/dialog.dart';

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
  
  bool _publicPromptsLoaded = false;
  bool _privatePromptsLoaded = false;
  bool _favoritePromptsLoaded = false;

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
      // Only fetch data if it hasn't been loaded yet
      switch (_tabController.index) {
        case 0: // Public prompts tab
          if (!_publicPromptsLoaded) {
            _fetchPublicPrompts();
          }
          break;
        case 1: // Private prompts tab
          if (!_privatePromptsLoaded) {
            _fetchPrivatePrompts();
          }
          break;
        case 2: // Favorites tab
          if (!_favoritePromptsLoaded) {
            _fetchFavoritePrompts();
          }
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
        _publicPromptsLoaded = true;
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
        _privatePromptsLoaded = true;
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
        _favoritePromptsLoaded = true;
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
    PromptDrawer.show(
      context,
      (content) {
        // After creating a prompt, refresh the private prompts
        _privatePromptsLoaded = false;
        _fetchPrivatePrompts();
        
        // Also refresh favorites in case the new prompt was marked as favorite
        _favoritePromptsLoaded = false;
        if (_tabController.index == 2) {
          _fetchFavoritePrompts();
        }
      },
    );
  }

  // Method to reset loading flags and force refresh data
  void resetAndRefreshData() {
    _publicPromptsLoaded = false;
    _privatePromptsLoaded = false;
    _favoritePromptsLoaded = false;
    _fetchInitialData();
  }

  // Override didChangeDependencies to detect when screen is entered
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will run when the screen is first built or when dependencies change
    // We could add logic here to detect if we're coming from outside
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prompt Management'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
              ),
              tooltip: 'Create new prompt',
              onPressed: _createPrompt,
            ),
          ),
        ],
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
            onRefresh: () {
              _publicPromptsLoaded = false;
              return _fetchPublicPrompts();
            },
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
            onRefresh: () {
              _privatePromptsLoaded = false;
              return _fetchPrivatePrompts();
            },
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
            isEditable: true,
            onRefresh: () {
              _favoritePromptsLoaded = false;
              return _fetchFavoritePrompts();
            },
            onEdit: _handleEditPrompt,
            emptyMessage:
                'No favorite prompts yet\nAdd some by tapping the star icon',
            availableCategories: _availableCategories,
            onPromptToggleFavorite: _handleToggleFavorite,
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggleFavorite(Prompt prompt) async {
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
      GlobalSnackBar.show(
        context: context,
        message: previousState ? 'Removing from favorites...' : 'Adding to favorites...',
        variant: SnackBarVariant.loading,
        duration: const Duration(seconds: 1),
      );
      
      // Call the appropriate API
      bool success;
      if (previousState) {
        success = await _promptService.removePromptFromFavorites(prompt.id);
      } else {
        success = await _promptService.addPromptToFavorites(prompt.id);
      }
      
      // Close the loading snackbar
      GlobalSnackBar.hideCurrent(context);

      if (success) {
        if (!mounted) return;
        
        GlobalSnackBar.show(
          context: context,
          message: previousState ? 'Removed from favorites' : 'Added to favorites',
          variant: SnackBarVariant.success,
          duration: const Duration(seconds: 2),
        );

        // Mark all tabs as needing refresh to ensure consistent state
        _favoritePromptsLoaded = false;
        _publicPromptsLoaded = false;
        _privatePromptsLoaded = false;
        
        // Refresh current tab immediately
        switch (_tabController.index) {
          case 0:
            _fetchPublicPrompts();
            break;
          case 1:
            _fetchPrivatePrompts();
            break;
          case 2:
            _fetchFavoritePrompts();
            break;
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

        GlobalSnackBar.show(
          context: context,
          message: 'Failed to update favorite status',
          variant: SnackBarVariant.error,
        );
      }
    } catch (e) {
      _logger.e('Error toggling favorite: $e');
      
      if (!mounted) return;
      
      GlobalSnackBar.show(
        context: context,
        message: 'Error: ${e.toString()}',
        variant: SnackBarVariant.error,
      );
      
      // Mark all tabs as needing refresh
      _publicPromptsLoaded = false;
      _privatePromptsLoaded = false;
      _favoritePromptsLoaded = false;
      
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
        
        GlobalSnackBar.show(
          context: context,
          message: 'Error: Cannot delete prompt with empty ID',
          variant: SnackBarVariant.error,
        );
        return;
      }

      // Log the ID to help debug
      _logger.i('Attempting to delete prompt with ID: ${prompt.id}');

      final confirmed = await GlobalDialog.show(
        context: context,
        title: 'Delete Prompt',
        message: 'Are you sure you want to delete "${prompt.title}"?',
        variant: DialogVariant.warning,
        confirmLabel: 'Delete',
        cancelLabel: 'Cancel',
      );

      if (confirmed != true) return;

      final success = await _promptService.deletePrompt(prompt.id);

      if (!mounted) return;

      if (success) {
        // Update the UI by removing the deleted prompt
        setState(() {
          _privatePrompts.removeWhere((p) => p.id == prompt.id);
          // Also remove from favorites list if it exists there
          if (prompt.isFavorite) {
            _favoritePrompts.removeWhere((p) => p.id == prompt.id);
          }
        });
        
        // Mark all tabs as needing refresh
        _privatePromptsLoaded = false;
        _publicPromptsLoaded = false;
        _favoritePromptsLoaded = false;
        
        // Refresh current tab immediately
        _fetchPrivatePrompts();
        
        // If currently on favorites tab and prompt was a favorite, refresh that too
        if (_tabController.index == 2 && prompt.isFavorite) {
          _fetchFavoritePrompts();
        }

        GlobalSnackBar.show(
          context: context,
          message: 'Prompt deleted',
          variant: SnackBarVariant.success,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      _logger.e('Error deleting prompt: $e');

      if (!mounted) return;

      GlobalSnackBar.show(
        context: context,
        message: 'Error: ${e.toString()}',
        variant: SnackBarVariant.error,
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

      GlobalSnackBar.show(
        context: context,
        message: 'Prompt deleted successfully',
        variant: SnackBarVariant.success,
      );
    } catch (e) {
      _logger.e('Error deleting prompt: $e');

      if (!mounted) return; // Added mounted check

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

  void _handleEditPrompt(Prompt prompt) {
    // Validate that the ID is not empty
    if (prompt.id.isEmpty) {
      _logger.e('Cannot edit prompt: ID is empty');
      
      GlobalSnackBar.show(
        context: context,
        message: 'Cannot edit prompt: ID is empty',
        variant: SnackBarVariant.error,
      );
      return;
    }
    
    PromptDrawer.showEdit(
      context,
      prompt,
      (_) {
        // Mark all tabs as needing refresh after editing
        _privatePromptsLoaded = false;
        _publicPromptsLoaded = false;
        _favoritePromptsLoaded = false;
        
        // Refresh current tab immediately
        switch (_tabController.index) {
          case 0:
            _fetchPublicPrompts();
            break;
          case 1:
            _fetchPrivatePrompts();
            break;
          case 2:
            _fetchFavoritePrompts();
            break;
        }
      },
    );
  }
}
