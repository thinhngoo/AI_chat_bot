import 'dart:math';
import 'package:flutter/material.dart';
import '../models/knowledge_base_model.dart';
import '../services/knowledge_base_service.dart';
import 'create_knowledge_base_dialog.dart';
import 'knowledge_base_detail_screen.dart';

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  final KnowledgeBaseService _knowledgeBaseService = KnowledgeBaseService();
  bool _isLoading = false;
  String _searchQuery = '';
  List<KnowledgeBase> _knowledgeBases = [];
  String? _error;
  int _page = 1;
  bool _hasMoreData = true;
  final int _limit = 10;  // Local implementation of formatBytes method
  String _formatBytes(int? bytes) {
    print('KnowledgeBaseScreen._formatBytes input: $bytes bytes');
    if (bytes == null || bytes <= 0) {
      print('KnowledgeBaseScreen._formatBytes returning: 0 B (null or <= 0)');
      return '0 B';
    }
    
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    final i = (log(bytes) / log(1024)).floor();
    print('KnowledgeBaseScreen._formatBytes suffixes index: $i');
    
    // If less than 1 KB, show in bytes with no decimal places
    if (i == 0) {
      final result = '$bytes ${suffixes[i]}';
      print('KnowledgeBaseScreen._formatBytes returning: $result (bytes)');
      return result;
    }
    
    // Otherwise show with the specified number of decimal places
    final result = '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
    print('KnowledgeBaseScreen._formatBytes returning: $result');
    return result;
  }

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadKnowledgeBases();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_hasMoreData && !_isLoading) {
        _loadMoreKnowledgeBases();
      }
    }
  }
  Future<void> _loadKnowledgeBases() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _page = 1;
      _knowledgeBases = [];
    });

    try {
      print('Loading knowledge bases with search query: "$_searchQuery"');
      final knowledgeBases = await _knowledgeBaseService.getKnowledgeBases(
        search: _searchQuery,
        page: _page,
        limit: _limit,
        includeUnits: true, // Make sure we fetch datasources for each knowledge base
      );

      // Log the datasources count for debugging
      for (var kb in knowledgeBases) {
        print('Knowledge base ${kb.knowledgeName} has ${kb.sources.length} datasources');
        print('Unit count (from getter): ${kb.unitCount}');
        print('Total size: ${kb.totalSize} bytes (${_formatBytes(kb.totalSize)})');
      }

      setState(() {
        _knowledgeBases = knowledgeBases;
        _hasMoreData = knowledgeBases.length >= _limit;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading knowledge bases: $e');
      setState(() {
        _error = 'Failed to load knowledge bases: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreKnowledgeBases() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _page++;
    });

    try {
      final moreKnowledgeBases = await _knowledgeBaseService.getKnowledgeBases(
        search: _searchQuery,
        page: _page,
        limit: _limit,
      );

      setState(() {
        _knowledgeBases.addAll(moreKnowledgeBases);
        _hasMoreData = moreKnowledgeBases.length >= _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load more knowledge bases: $e';
        _isLoading = false;
        _page--;
      });
    }
  }

  Future<void> _deleteKnowledgeBase(KnowledgeBase knowledgeBase) async {
    try {
      await _knowledgeBaseService.deleteKnowledgeBase(knowledgeBase.id);
      _loadKnowledgeBases();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Knowledge base "${knowledgeBase.name}" deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete knowledge base: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _createKnowledgeBase() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const CreateKnowledgeBaseDialog(),
    );
    
    if (result == true) {
      _loadKnowledgeBases();
    }
  }

  @override
  Widget build(BuildContext context) {    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Base'),
        elevation: 0,
        actions: [
          // Refresh button to reload knowledge bases
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh knowledge bases',
            onPressed: () {
              _loadKnowledgeBases();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing knowledge bases...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [          // Search and create section
          Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Knowledge Base',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Search field
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search knowledge...',
                              prefixIcon: const Icon(Icons.search),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                              _loadKnowledgeBases();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Create knowledge button
                      ElevatedButton(
                        onPressed: _createKnowledgeBase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1), // Indigo color
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Create Knowledge'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Column headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Name/Description',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Created',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          const Divider(height: 1),
          
          // List of knowledge bases
          Expanded(
            child: _error != null
                ? _buildErrorView()
                : _knowledgeBases.isEmpty && !_isLoading
                    ? _buildEmptyView()
                    : _buildKnowledgeBaseList(),
          ),
          
          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadKnowledgeBases,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.source_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No knowledge bases found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _createKnowledgeBase,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create New Knowledge Base'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildKnowledgeBaseList() {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _knowledgeBases.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final kb = _knowledgeBases[index];
        return InkWell(
          onTap: () => _navigateToDetail(kb.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                // Database icon
                const Icon(Icons.storage, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                
                // Name and description
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kb.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (kb.description.isNotEmpty)
                        Text(
                          kb.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(height: 4),
                      // Hiển thị số units và dung lượng
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${kb.unitCount} ${kb.unitCount == 1 ? 'unit' : 'units'}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),                            child: Text(
                              _formatBytes(kb.totalSize),
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Status
                SizedBox(
                  width: 80,
                  child: _buildStatusBadge(kb.status),
                ),
                
                const SizedBox(width: 8),
                
                // Created date
                SizedBox(
                  width: 80,
                  child: Text(
                    _formatDate(kb.createdAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Action buttons
                SizedBox(
                  width: 100,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit button
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                        onPressed: () {
                          // Handle edit
                        },
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      
                      // Delete button
                      IconButton(
                        icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error, size: 18),
                        onPressed: () => _showDeleteConfirmation(kb),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      
                      // Arrow button
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, color: Colors.green, size: 18),
                        onPressed: () => _navigateToDetail(kb.id),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToDetail(String knowledgeBaseId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => KnowledgeBaseDetailScreen(
          knowledgeBaseId: knowledgeBaseId,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'processing':
        color = Colors.blue;
        icon = Icons.hourglass_top;
        break;
      case 'error':
        color = Colors.red;
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          status,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteConfirmation(KnowledgeBase knowledgeBase) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
            'Are you sure you want to delete "${knowledgeBase.name}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteKnowledgeBase(knowledgeBase);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}