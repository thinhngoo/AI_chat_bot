import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/ai_bot.dart';
import '../models/knowledge_data.dart';
import '../services/bot_service.dart';
import 'bot_knowledge_screen.dart';
import 'bot_preview_screen.dart';
import 'bot_publish_screen.dart';

class BotDetailScreen extends StatefulWidget {
  final String botId;

  const BotDetailScreen({
    super.key,
    required this.botId,
  });

  @override
  State<BotDetailScreen> createState() => _BotDetailScreenState();
}

class _BotDetailScreenState extends State<BotDetailScreen> with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  final BotService _botService = BotService();

  late TabController _tabController;
  bool _isLoading = true;
  String _errorMessage = '';
  AIBot? _bot;
  List<KnowledgeData> _knowledgeBases = [];
  bool _isLoadingKnowledge = false;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _promptController = TextEditingController();
  String _selectedModel = 'gpt-4o-mini';
  bool _isSaving = false;

  final List<Map<String, String>> _availableModels = [
    {'id': 'gpt-4o-mini', 'name': 'GPT-4o mini'},
    {'id': 'gpt-4o', 'name': 'GPT-4o'},
    {'id': 'gemini-1.5-flash-latest', 'name': 'Gemini 1.5 Flash'},
    {'id': 'gemini-1.5-pro-latest', 'name': 'Gemini 1.5 Pro'},
    {'id': 'claude-3-haiku-20240307', 'name': 'Claude 3 Haiku'},
    {'id': 'claude-3-sonnet-20240229', 'name': 'Claude 3 Sonnet'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchBotDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _fetchBotDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final bot = await _botService.getBotById(widget.botId);

      if (mounted) {
        setState(() {
          _bot = bot;
          _isLoading = false;

          // Set up form controllers
          _nameController.text = bot.name;
          _descriptionController.text = bot.description;
          _promptController.text = bot.prompt;
          _selectedModel = bot.model;
        });

        // Fetch knowledge bases
        _fetchKnowledgeBases();
      }
    } catch (e) {
      _logger.e('Error fetching bot details: $e');

      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchKnowledgeBases() async {
    try {
      setState(() {
        _isLoadingKnowledge = true;
      });

      _logger.i('Fetching knowledge bases for bot ${widget.botId}');

      // Get imported knowledge bases for this specific bot
      final importedKnowledgeBases = await _botService.getImportedKnowledge(
        botId: widget.botId,
        limit: 50 // Get a reasonable limit of imported knowledge bases
      );

      // Extract IDs of imported knowledge bases
      final importedIds = importedKnowledgeBases.map((kb) => kb.id).toList();

      if (mounted && _bot != null) {
        setState(() {
          // Update the bot's knowledge base IDs
          _bot = AIBot(
            id: _bot!.id,
            name: _bot!.name,
            description: _bot!.description,
            model: _bot!.model,
            prompt: _bot!.prompt,
            createdAt: _bot!.createdAt,
            updatedAt: _bot!.updatedAt,
            isPublished: _bot!.isPublished,
            connectedPlatforms: _bot!.connectedPlatforms,
            knowledgeBaseIds: importedIds, // Update with the actual imported knowledge base IDs
          );

          // Store the knowledge bases for display
          _knowledgeBases = importedKnowledgeBases;
          _isLoadingKnowledge = false;
        });

        _logger.i('Bot now has ${importedIds.length} knowledge bases');
      }
    } catch (e) {
      _logger.e('Error fetching knowledge bases: $e');
      if (mounted) {
        setState(() {
          _isLoadingKnowledge = false;
        });
      }
    }
  }

  Future<void> _removeKnowledgeBase(KnowledgeData knowledge) async {
    try {
      setState(() {
        _isLoadingKnowledge = true;
      });      await _botService.removeKnowledge(
        botId: widget.botId,
        knowledgeBaseId: knowledge.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "${knowledge.name}" from bot'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () {
              _addKnowledgeBack(knowledge);
            },
          ),
        ),
      );

      // Refresh knowledge bases
      _fetchKnowledgeBases();
    } catch (e) {
      _logger.e('Error removing knowledge base: $e');

      if (mounted) {
        setState(() {
          _isLoadingKnowledge = false;
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

  Future<void> _addKnowledgeBack(KnowledgeData knowledge) async {
    try {
      await _botService.importKnowledge(
        botId: widget.botId,
        knowledgeBaseIds: [knowledge.id],
      );      // Refresh knowledge bases
      _fetchKnowledgeBases();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${knowledge.name}" back to bot'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {      _logger.e('Error adding knowledge base back: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveChanges() async {
    try {
      setState(() {
        _isSaving = true;
      });

      await _botService.updateBot(
        botId: widget.botId,
        name: _nameController.text,
        description: _descriptionController.text,
        model: _selectedModel,
        prompt: _promptController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bot updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh bot details
      _fetchBotDetails();
    } catch (e) {
      _logger.e('Error saving bot changes: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update bot: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_bot?.name ?? 'Bot Details'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Knowledge'),
            Tab(text: 'Preview'),
            Tab(text: 'Publish'),
          ],
        ),
      ),
      body: _isLoading
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
                        onPressed: _fetchBotDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Details Tab
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Bot Name',
                              border: OutlineInputBorder(),
                            ),
                            enabled: !_isSaving,
                          ),
                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            value: _selectedModel,
                            decoration: const InputDecoration(
                              labelText: 'AI Model',
                              border: OutlineInputBorder(),
                            ),
                            items: _availableModels.map((model) {
                              return DropdownMenuItem<String>(
                                value: model['id'],
                                child: Text(model['name']!),
                              );
                            }).toList(),
                            onChanged: _isSaving
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedModel = value;
                                      });
                                    }
                                  },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                            enabled: !_isSaving,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _promptController,
                            decoration: const InputDecoration(
                              labelText: 'Prompt Instructions',
                              hintText: 'Enter instructions for the bot',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 6,
                            enabled: !_isSaving,
                          ),
                          const SizedBox(height: 32),

                          ElevatedButton(
                            onPressed: _isSaving ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // Knowledge Tab with list of knowledge bases
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Knowledge Base',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Choose a knowledge base below to add knowledge units.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // List of knowledge bases
                        _isLoadingKnowledge
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : _knowledgeBases.isEmpty
                                ? Expanded(
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.book,
                                            size: 64,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'No knowledge bases added yet',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              if (_bot != null) {
                                                _navigateToKnowledgeScreen();
                                              }
                                            },
                                            icon: const Icon(Icons.add),
                                            label: const Text('Add Knowledge'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Expanded(
                                    child: Column(
                                      children: [
                                        // Knowledge list
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: _knowledgeBases.length,
                                            padding: const EdgeInsets.all(8.0),
                                            itemBuilder: (context, index) {
                                              final knowledge = _knowledgeBases[index];
                                              return Card(
                                                margin: const EdgeInsets.symmetric(
                                                  horizontal: 8.0,
                                                  vertical: 6.0,
                                                ),
                                                elevation: 2,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  side: BorderSide(
                                                    color: Theme.of(context).colorScheme.primary,
                                                    width: 1
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    ListTile(
                                                      title: Text(
                                                        knowledge.name,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      subtitle: Text(
                                                        knowledge.description,
                                                        style: TextStyle(
                                                          color: Colors.grey[300],
                                                        ),
                                                      ),
                                                      leading: CircleAvatar(
                                                        backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(25),
                                                        child: Icon(
                                                          _getKnowledgeTypeIcon(knowledge.type),
                                                          color: Theme.of(context).colorScheme.primary,
                                                        ),
                                                      ),
                                                      trailing: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(Icons.delete_outline),
                                                            color: Colors.grey,
                                                            onPressed: () => _removeKnowledgeBase(knowledge),
                                                            tooltip: 'Remove',
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(Icons.arrow_forward),
                                                            color: Colors.blue,
                                                            onPressed: () {
                                                              // Navigate to knowledge detail screen (not implemented in this example)
                                                            },
                                                            tooltip: 'View Details',
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    
                                                    // Additional details
                                                    Padding(
                                                      padding: const EdgeInsets.only(
                                                        left: 16.0, 
                                                        right: 16.0,
                                                        bottom: 12.0,
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          // Document count
                                                          Chip(
                                                            label: Text(
                                                              '${knowledge.documentCount} documents',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Theme.of(context).colorScheme.onSurface,
                                                              ),
                                                            ),
                                                            backgroundColor: Theme.of(context).colorScheme.surface,
                                                          ),
                                                          
                                                          // Last updated
                                                          Text(
                                                            'Updated: ${_formatDate(knowledge.updatedAt)}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),

                                        // Add more knowledge button
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () => _navigateToKnowledgeScreen(),
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(30),
                                                ),
                                                backgroundColor: Colors.blue,
                                              ),
                                              icon: const Icon(Icons.add, color: Colors.white),
                                              label: const Text(
                                                'Add More Knowledge',
                                                style: TextStyle(color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                      ],
                    ),

                    // Preview Tab (Placeholder - will navigate to full screen)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.teal,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Test your bot in preview mode',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (_bot != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BotPreviewScreen(
                                      botId: _bot!.id,
                                      botName: _bot!.name,
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Preview'),
                          ),
                        ],
                      ),
                    ),

                    // Publish Tab (Placeholder - will navigate to full screen)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.public,
                            size: 64,
                            color: Colors.teal,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Connected platforms: ${_bot?.connectedPlatforms.length ?? 0}',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (_bot != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BotPublishScreen(
                                      botId: _bot!.id,
                                      botName: _bot!.name,
                                    ),
                                  ),
                                ).then((_) => _fetchBotDetails());
                              }
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Manage Publishing'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _tabController.index == 0 ? FloatingActionButton(
        onPressed: _saveChanges,
        tooltip: 'Save Changes',
        child: const Icon(Icons.save),
      ) : null,
    );
  }

  void _navigateToKnowledgeScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BotKnowledgeScreen(
          botId: _bot!.id,
          knowledgeBaseIds: _bot!.knowledgeBaseIds,
        ),
      ),
    ).then((_) => _fetchBotDetails());
  }

  IconData _getKnowledgeTypeIcon(KnowledgeType type) {
    switch (type) {
      case KnowledgeType.document:
        return Icons.description;
      case KnowledgeType.website:
        return Icons.language;
      case KnowledgeType.googleDrive:
        return Icons.drive_folder_upload;
      case KnowledgeType.slack:
        return Icons.chat;
      case KnowledgeType.confluence:
        return Icons.article;
      case KnowledgeType.database:
        return Icons.storage;
      case KnowledgeType.api:
        return Icons.api;
    }
  }

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
