import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/ai_bot.dart';
import '../services/bot_service.dart';
import 'bot_detail_screen.dart';
import 'create_bot_screen.dart';

class BotListScreen extends StatefulWidget {
  const BotListScreen({super.key});

  @override
  State<BotListScreen> createState() => _BotListScreenState();
}

class _BotListScreenState extends State<BotListScreen> with SingleTickerProviderStateMixin {
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
    _fetchBots();
    
    _refreshIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BotDetailScreen(botId: bot.id),
      ),
    ).then((_) => _fetchBots());
  }
  
  void _createBot() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateBotScreen(),
      ),
    ).then((_) => _fetchBots());
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
        title: const Text('Bot Management'),
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
                      child: const Icon(Icons.public, size: 12, color: Colors.white),
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
                                  color: theme.colorScheme.primary.withOpacity(0.5),
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
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
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
      floatingActionButton: !_isLoading && _errorMessage.isEmpty ? FloatingActionButton.extended(
        onPressed: _createBot,
        icon: const Icon(Icons.add),
        label: const Text('Create Bot'),
        tooltip: 'Create a new bot',
      ) : null,
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
    // Determine model icon and color based on the model name
    IconData modelIcon = Icons.smart_toy;
    Color modelColor = theme.colorScheme.primary;
    
    if (bot.model.contains('gpt')) {
      modelIcon = Icons.psychology;
      modelColor = Colors.green;
    } else if (bot.model.contains('gemini')) {
      modelIcon = Icons.auto_awesome;
      modelColor = Colors.blue;
    } else if (bot.model.contains('claude')) {
      modelIcon = Icons.lightbulb;
      modelColor = Colors.orange;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bot avatar/icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.smart_toy,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Bot info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bot.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bot.description.isNotEmpty ? bot.description : 'No description',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        
                        // Model info and status
                        Row(
                          children: [
                            // Model info
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8, 
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: modelColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    modelIcon,
                                    size: 14,
                                    color: modelColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    bot.model,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: modelColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 8),
                            
                            // Published status
                            if (bot.isPublished)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, 
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.public,
                                      size: 14,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Published',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            const Spacer(),
                            
                            // Knowledge base count
                            if (bot.knowledgeBaseIds.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, 
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.book,
                                      size: 14,
                                      color: theme.colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      bot.knowledgeBaseIds.length.toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.secondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Last updated date
                  Text(
                    'Updated: ${_formatDate(bot.updatedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Edit button
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Delete button
                  OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper method to format dates
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
