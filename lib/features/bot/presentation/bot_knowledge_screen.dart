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
  String _searchQuery = '';
  KnowledgeType? _selectedTypeFilter;

  // Controller for search
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _botKnowledgeBaseIds = List.from(widget.knowledgeBaseIds);
    _fetchKnowledgeBases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
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
        
        // Use scaffoldMessenger instead of context
        if (!mounted) return;
        
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Removed "${knowledge.name}" from bot knowledge'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: () {
                _toggleKnowledgeBase(knowledge);
              },
            ),
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
        
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Added "${knowledge.name}" to bot knowledge'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error toggling knowledge base: $e');
      
      if (!mounted) return;
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _uploadFile() async {
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });
      
      // Update progress to simulate activity
      setState(() {
        _uploadProgress = 0.3;
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      
      setState(() {
        _uploadProgress = 0.5;
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      
      setState(() {
        _uploadProgress = 0.8;
      });
      
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      
      setState(() {
        _uploadProgress = 1.0;
      });
      
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.upload_file, color: Colors.blue),
              SizedBox(width: 10),
              Text('File Upload'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'File upload functionality requires the file_picker package.\n\n'
                'To implement this feature, add the dependency to pubspec.yaml:'
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'file_picker: ^5.2.10',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Text('Then run:'),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'flutter pub get',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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

  // Filter knowledge bases based on search query and type
  List<KnowledgeData> get _filteredKnowledgeBases {
    return _allKnowledgeBases.where((knowledge) {
      // Filter by search query
      final matchesSearch = _searchQuery.isEmpty ||
          knowledge.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          knowledge.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Filter by knowledge type
      final matchesType = _selectedTypeFilter == null || 
          knowledge.type == _selectedTypeFilter;
      
      return matchesSearch && matchesType;
    }).toList();
  }
  
  // Get count of knowledge bases by type
  int _getKnowledgeBaseCountByType(KnowledgeType type) {
    return _allKnowledgeBases.where((k) => k.type == type).length;
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
      body: Column(
        children: [
          // Search and filter bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search knowledge bases...',
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
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // Type filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      
                      // All filter
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedTypeFilter == null,
                        onSelected: (_) {
                          setState(() {
                            _selectedTypeFilter = null;
                          });
                        },
                        avatar: const Icon(Icons.all_inclusive, size: 18),
                      ),
                      const SizedBox(width: 8),
                      
                      // Document filter
                      FilterChip(
                        label: Text('Documents (${_getKnowledgeBaseCountByType(KnowledgeType.document)})'),
                        selected: _selectedTypeFilter == KnowledgeType.document,
                        onSelected: (_) {
                          setState(() {
                            _selectedTypeFilter = _selectedTypeFilter == KnowledgeType.document
                                ? null
                                : KnowledgeType.document;
                          });
                        },
                        avatar: const Icon(Icons.description, size: 18),
                      ),
                      const SizedBox(width: 8),
                      
                      // Website filter
                      FilterChip(
                        label: Text('Websites (${_getKnowledgeBaseCountByType(KnowledgeType.website)})'),
                        selected: _selectedTypeFilter == KnowledgeType.website,
                        onSelected: (_) {
                          setState(() {
                            _selectedTypeFilter = _selectedTypeFilter == KnowledgeType.website
                                ? null
                                : KnowledgeType.website;
                          });
                        },
                        avatar: const Icon(Icons.language, size: 18),
                      ),
                      const SizedBox(width: 8),
                      
                      // Database filter
                      FilterChip(
                        label: Text('Databases (${_getKnowledgeBaseCountByType(KnowledgeType.database)})'),
                        selected: _selectedTypeFilter == KnowledgeType.database,
                        onSelected: (_) {
                          setState(() {
                            _selectedTypeFilter = _selectedTypeFilter == KnowledgeType.database
                                ? null
                                : KnowledgeType.database;
                          });
                        },
                        avatar: const Icon(Icons.storage, size: 18),
                      ),
                      const SizedBox(width: 8),
                      
                      // API filter
                      FilterChip(
                        label: Text('APIs (${_getKnowledgeBaseCountByType(KnowledgeType.api)})'),
                        selected: _selectedTypeFilter == KnowledgeType.api,
                        onSelected: (_) {
                          setState(() {
                            _selectedTypeFilter = _selectedTypeFilter == KnowledgeType.api
                                ? null
                                : KnowledgeType.api;
                          });
                        },
                        avatar: const Icon(Icons.api, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Results count
          if (!_isLoading && _errorMessage.isEmpty && _allKnowledgeBases.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${_filteredKnowledgeBases.length} of ${_allKnowledgeBases.length} knowledge bases',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Bot has ${_botKnowledgeBaseIds.length} knowledge bases',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Main content
          Expanded(
            child: Stack(
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
                            : _filteredKnowledgeBases.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.search_off,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'No matching knowledge bases found',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _searchQuery = '';
                                              _selectedTypeFilter = null;
                                            });
                                          },
                                          child: const Text('Clear Filters'),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _filteredKnowledgeBases.length,
                                    itemBuilder: (context, index) {
                                      final knowledge = _filteredKnowledgeBases[index];
                                      final isAdded = _botKnowledgeBaseIds.contains(knowledge.id);
                                      
                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                          vertical: 8.0,
                                        ),
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: isAdded 
                                            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                                            : BorderSide.none,
                                        ),
                                        child: Column(
                                          children: [
                                            ListTile(
                                              title: Text(
                                                knowledge.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              subtitle: Text(knowledge.description),
                                              leading: CircleAvatar(
                                                backgroundColor: isAdded 
                                                  ? Theme.of(context).colorScheme.primary.withAlpha(25)
                                                  : Colors.grey[200],
                                                child: Icon(
                                                  _getKnowledgeTypeIcon(knowledge.type),
                                                  color: isAdded
                                                    ? Theme.of(context).colorScheme.primary
                                                    : Colors.grey[700],
                                                ),
                                              ),
                                              trailing: Switch(
                                                value: isAdded,
                                                onChanged: (value) => _toggleKnowledgeBase(knowledge),
                                                activeColor: Theme.of(context).colorScheme.primary,
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
                                                      color: Theme.of(context).colorScheme.onSurface.withAlpha(178), // Using withAlpha instead of withOpacity
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
                
                // Upload progress indicator - improved UI
                if (_isUploading)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 24),
                              const Text(
                                'Uploading document...',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: 280,
                                child: LinearProgressIndicator(
                                  value: _uploadProgress,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Processing ${(_uploadProgress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface.withAlpha(178), // Changed from withOpacity to withAlpha
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploadFile,
        tooltip: 'Upload Document',
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
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
