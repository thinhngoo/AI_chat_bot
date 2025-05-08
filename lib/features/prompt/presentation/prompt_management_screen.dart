import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/prompt.dart';
import '../services/prompt_service.dart';
import 'prompt_list_screen.dart';
import 'create_edit_prompt_screen.dart';

class PromptManagementScreen extends StatefulWidget {
  const PromptManagementScreen({Key? key}) : super(key: key);

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

      setState(() {
        _publicPrompts = prompts;
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

      setState(() {
        _privatePrompts = prompts;
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

      setState(() {
        _favoritePrompts = prompts;
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditPromptScreen(
          availableCategories: _availableCategories,
        ),
      ),
    ).then((_) => _fetchPrivatePrompts());
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
      bool success;
      if (prompt.isFavorite) {
        success = await _promptService.removePromptFromFavorites(prompt.id);
      } else {
        success = await _promptService.addPromptToFavorites(prompt.id);
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(prompt.isFavorite
                ? 'Removed from favorites'
                : 'Added to favorites'),
            duration: const Duration(seconds: 2),
          ),
        );

        // Refresh lists as needed
        if (_tabController.index == 2) {
          // In favorites tab
          _fetchFavoritePrompts();
        } else if (prompt.isFavorite) {
          _fetchFavoritePrompts(); // Update favorites in background
        }

        // Update the current tab's list in-place
        setState(() {
          if (_tabController.index == 0) {
            final index = _publicPrompts.indexWhere((p) => p.id == prompt.id);
            if (index != -1) {
              _publicPrompts[index] =
                  prompt.copyWith(isFavorite: !prompt.isFavorite);
            }
          } else if (_tabController.index == 1) {
            final index = _privatePrompts.indexWhere((p) => p.id == prompt.id);
            if (index != -1) {
              _privatePrompts[index] =
                  prompt.copyWith(isFavorite: !prompt.isFavorite);
            }
          }
        });
      }
    } catch (e) {
      _logger.e('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDeletePrompt(Prompt prompt) async {
    try {
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
        _fetchPrivatePrompts();
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

  Future<void> _deletePrompt(String promptId) async {
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
