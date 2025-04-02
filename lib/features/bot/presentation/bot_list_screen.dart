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

class _BotListScreenState extends State<BotListScreen> {
  final Logger _logger = Logger();
  final BotService _botService = BotService();
  
  bool _isLoading = true;
  String _errorMessage = '';
  List<AIBot> _bots = [];
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _fetchBots();
  }
  
  Future<void> _fetchBots() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      final bots = await _botService.getBots(
        query: _searchQuery.isNotEmpty ? _searchQuery : null
      );
      
      if (mounted) {
        setState(() {
          _bots = bots;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.e('Error fetching bots: $e');
      
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _deleteBot(AIBot bot) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete "${bot.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        setState(() => _isLoading = true);
        
        await _botService.deleteBot(bot.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bot deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          _fetchBots();
        }
      }
    } catch (e) {
      _logger.e('Error deleting bot: $e');
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete bot: ${e.toString()}'),
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Bots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBots,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Bots',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _searchQuery = value;
                if (value.isEmpty || value.length > 2) {
                  _fetchBots();
                }
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error: $_errorMessage',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchBots,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _bots.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'No AI Bots found',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _createBot,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create New Bot'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchBots,
                            child: ListView.builder(
                              itemCount: _bots.length,
                              itemBuilder: (context, index) {
                                final bot = _bots[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      bot.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Model: ${bot.model}'),
                                        Text(
                                          bot.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(context).primaryColor.withAlpha(51),
                                      child: const Icon(Icons.smart_toy),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => _editBot(bot),
                                          tooltip: 'Edit',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteBot(bot),
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    ),
                                    onTap: () => _editBot(bot),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createBot,
        tooltip: 'Create New Bot',
        child: const Icon(Icons.add),
      ),
    );
  }
}
