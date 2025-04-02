import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/ai_bot.dart';
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
      await _botService.getKnowledgeBases();
    } catch (e) {
      _logger.e('Error fetching knowledge bases: $e');
      // Don't set error state since this is secondary data
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
                    
                    // Knowledge Tab (Placeholder - will navigate to full screen)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Knowledge Bases: ${_bot?.knowledgeBaseIds.length ?? 0}',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (_bot != null) {
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
                            },
                            icon: const Icon(Icons.book),
                            label: const Text('Manage Knowledge'),
                          ),
                        ],
                      ),
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
}
