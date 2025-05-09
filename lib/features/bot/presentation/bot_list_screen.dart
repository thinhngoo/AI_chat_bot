import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/ai_bot.dart';
import '../services/bot_service.dart';
import 'bot_detail_screen.dart';
import 'create_bot_screen.dart';
import 'bot_preview_screen.dart';

class BotListScreen extends StatefulWidget {
  const BotListScreen({super.key});

  @override
  State<BotListScreen> createState() => _BotListScreenState();
}

class _BotListScreenState extends State<BotListScreen>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  final BotService _botService = BotService();

  bool _isLoading = true;
  String _errorMessage = '';
  List<AIBot> _bots = [];
  String _searchQuery = '';

  // Animation controller for refresh indicator
  late AnimationController _refreshIconController;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Initialize the animation controller properly
    _refreshIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    // Immediately fetch bots when the screen loads
    _fetchBots();
  }

  @override
  void dispose() {
    _refreshIconController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBots() async {
    try {
      setState(() {
        _errorMessage = '';
        _isLoading = true;
        _refreshIconController.repeat();
      });

      final bots = await _botService.getBots();

      if (mounted) {
        setState(() {
          _bots = bots;
          _isLoading = false;
          _refreshIconController.stop();
        });
      }
    } catch (e) {
      _logger.e('Error fetching bots: $e');

      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _refreshIconController.stop();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteBot(AIBot bot) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _botService.deleteBot(bot.id);

      if (mounted) {
        setState(() {
          _bots.removeWhere((b) => b.id == bot.id);
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bot "${bot.name}" deleted successfully'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: () {
                // In a real app, you might want to restore the deleted bot
                _fetchBots();
              },
            ),
          ),
        );
      }
    } catch (e) {
      _logger.e('Error deleting bot: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting bot: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editBot(AIBot bot) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => BotDetailScreen(botId: bot.id),
          ),
        )
        .then((_) => _fetchBots());
  }

  void _createBot() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const CreateBotScreen(),
          ),
        )
        .then((_) => _fetchBots());
  }

  // Get filtered bots based on search query
  List<AIBot> get _filteredBots {
    if (_searchQuery.isEmpty) {
      return _bots;
    }
    return _bots.where((bot) {
      return bot.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          bot.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bot Management'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: RotationTransition(
              turns: _refreshIconController,
              child: const Icon(Icons.refresh),
            ),
            onPressed: _isLoading ? null : _fetchBots,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search bots...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: isDarkMode
                    ? Colors.grey.shade800.withOpacity(0.5)
                    : Colors.grey.shade50,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Stats summary
          if (!_isLoading && _errorMessage.isEmpty && _bots.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    'Showing ${_filteredBots.length} of ${_bots.length} bots',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(
                      '${_bots.where((bot) => bot.isPublished).length} published',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    avatar: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      radius: 10,
                      child: const Icon(Icons.public,
                          size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

          // Main content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
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
                              'Error: $_errorMessage',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _fetchBots,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _bots.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.adb,
                                  size: 72,
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No bots found',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Create your first bot to get started',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _createBot,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Bot'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _filteredBots.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.search_off,
                                      color: Colors.grey,
                                      size: 64,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No matching bots found',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try a different search term',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    OutlinedButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                      child: const Text('Clear Search'),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _fetchBots,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16.0),
                                  itemCount: _filteredBots.length,
                                  itemBuilder: (context, index) {
                                    final bot = _filteredBots[index];

                                    return BotCard(
                                      bot: bot,
                                      onEdit: () => _editBot(bot),
                                      onDelete: () => _confirmDelete(bot),
                                      theme: theme,
                                      isDarkMode: isDarkMode,
                                    );
                                  },
                                ),
                              ),
          ),
        ],
      ),
      floatingActionButton: !_isLoading && _errorMessage.isEmpty
          ? FloatingActionButton.extended(
              onPressed: _createBot,
              icon: const Icon(Icons.add),
              label: const Text('Create Bot'),
              tooltip: 'Create a new bot',
            )
          : null,
    );
  }

  Future<void> _confirmDelete(AIBot bot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete "${bot.name}"?\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteBot(bot);
    }
  }
}

// Separate card widget for cleaner code
class BotCard extends StatelessWidget {
  final AIBot bot;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ThemeData theme;
  final bool isDarkMode;

  const BotCard({
    super.key,
    required this.bot,
    required this.onEdit,
    required this.onDelete,
    required this.theme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with icon and action buttons
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bot icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.smart_toy,
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                
                // Spacer to push actions to the right
                const Spacer(),
                
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Share button
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () {
                        // Implement share functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sharing bot...')),
                        );
                      },
                      tooltip: 'Share',
                      visualDensity: VisualDensity.compact,
                      iconSize: 20,
                    ),
                    
                    // Favorite button
                    IconButton(
                      icon: const Icon(Icons.star_border_outlined),
                      onPressed: () {
                        // Implement favorite functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to favorites')),
                        );
                      },
                      tooltip: 'Add to favorites',
                      visualDensity: VisualDensity.compact,
                      iconSize: 20,
                    ),
                    
                    // Delete button
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                      tooltip: 'Delete',
                      visualDensity: VisualDensity.compact,
                      iconSize: 20,
                    ),
                  ],
                ),
              ],
            ),
            
            // Bot name displayed as a separate row for better visibility
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
              child: Text(
                bot.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            
            // Action buttons row at the bottom
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Edit button
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
                
                // Chat Now button (primary action)
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to bot preview/chat screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BotPreviewScreen(
                          botId: bot.id,
                          botName: bot.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Chat Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
