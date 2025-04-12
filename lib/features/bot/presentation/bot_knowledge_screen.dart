import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/knowledge_data.dart';
import '../services/bot_service.dart';

class BotKnowledgeScreen extends StatefulWidget {
  final String botId;
  final List<String> knowledgeBaseIds;
  
  const BotKnowledgeScreen({
    super.key, 
    required this.botId,
    required this.knowledgeBaseIds,
  });

  @override
  State<BotKnowledgeScreen> createState() => _BotKnowledgeScreenState();
}

class _BotKnowledgeScreenState extends State<BotKnowledgeScreen> {
  final Logger _logger = Logger();
  final BotService _botService = BotService();
  
  bool _isLoading = true;
  String _errorMessage = '';
  List<KnowledgeData> _allKnowledgeBases = [];
  List<String> _botKnowledgeBaseIds = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  
  @override
  void initState() {
    super.initState();
    _botKnowledgeBaseIds = List.from(widget.knowledgeBaseIds);
    _fetchKnowledgeBases();
  }
  
  Future<void> _fetchKnowledgeBases() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      final knowledgeBases = await _botService.getKnowledgeBases();
      
      if (!mounted) return;
      
      setState(() {
        _allKnowledgeBases = knowledgeBases;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error fetching knowledge bases: $e');
      
      if (!mounted) return;
      
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _toggleKnowledgeBase(KnowledgeData knowledge) async {
    final isAdded = _botKnowledgeBaseIds.contains(knowledge.id);
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      if (isAdded) {
        // Remove knowledge base
        await _botService.removeKnowledge(
          botId: widget.botId,
          knowledgeBaseId: knowledge.id,
        );
        
        if (!mounted) return;
        
        setState(() {
          _botKnowledgeBaseIds.remove(knowledge.id);
        });
        
        // Use context after confirming mounted
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${knowledge.name}" from bot knowledge'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // Add knowledge base
        await _botService.importKnowledge(
          botId: widget.botId,
          knowledgeBaseIds: [knowledge.id],
        );
        
        if (!mounted) return;
        
        setState(() {
          _botKnowledgeBaseIds.add(knowledge.id);
        });
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${knowledge.name}" to bot knowledge'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error toggling knowledge base: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _uploadFile() async {
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });
      
      // Simple dialog to explain we don't have file picking implemented
      if (!mounted) return;
      
      // Update progress to simulate activity
      setState(() {
        _uploadProgress = 0.3;
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Store the context and check mounted status
      final currentContext = context;
      if (!mounted) return;
      
      showDialog(
        context: currentContext,
        builder: (context) => AlertDialog(
          title: const Text('File Upload'),
          content: const Text(
            'File upload functionality requires the file_picker package.\n\n'
            'To implement this feature, add the dependency to pubspec.yaml:\n'
            'file_picker: ^5.2.10'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      
      if (!mounted) return;
      
      setState(() {
        _isUploading = false;
      });
    } catch (e) {
      _logger.e('Error with file upload dialog: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isUploading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Knowledge'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchKnowledgeBases,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
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
                            onPressed: _fetchKnowledgeBases,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _allKnowledgeBases.isEmpty
                      ? Center(
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
                                'No knowledge bases found',
                                style: TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _uploadFile,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Upload Document'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _allKnowledgeBases.length,
                          itemBuilder: (context, index) {
                            final knowledge = _allKnowledgeBases[index];
                            final isAdded = _botKnowledgeBaseIds.contains(knowledge.id);
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: ListTile(
                                title: Text(knowledge.name),
                                subtitle: Text(knowledge.description),
                                leading: Icon(
                                  _getKnowledgeTypeIcon(knowledge.type),
                                  color: Theme.of(context).primaryColor,
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    isAdded ? Icons.remove_circle : Icons.add_circle,
                                    color: isAdded ? Colors.red : Colors.green,
                                  ),
                                  onPressed: () => _toggleKnowledgeBase(knowledge),
                                ),
                              ),
                            );
                          },
                        ),
          
          // Upload progress indicator
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Uploading document...',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(value: _uploadProgress),
                        const SizedBox(height: 8),
                        Text('${(_uploadProgress * 100).toInt()}%'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadFile,
        tooltip: 'Upload Document',
        child: const Icon(Icons.upload_file),
      ),
    );
  }
  
  IconData _getKnowledgeTypeIcon(KnowledgeType type) {
    switch (type) {
      case KnowledgeType.document:
        return Icons.description;
      case KnowledgeType.website:
        return Icons.language;
      case KnowledgeType.database:
        return Icons.storage;
      case KnowledgeType.api:
        return Icons.api;
    }
  }
}
