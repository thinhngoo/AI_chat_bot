import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../models/knowledge_base_model.dart';
import '../services/knowledge_base_service.dart';
import 'create_knowledge_base_dialog.dart';
import 'knowledge_base_detail_screen.dart';

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({
    super.key,
  });

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
  final int _limit = 10;

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
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
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
      final knowledgeBases = await _knowledgeBaseService.getKnowledgeBases(
        search: _searchQuery,
        page: _page,
        limit: _limit,
      );

      setState(() {
        _knowledgeBases = knowledgeBases;
        _hasMoreData = knowledgeBases.length >= _limit;
        _isLoading = false;
      });
    } catch (e) {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Base'),
      ),
      body: Column(
        children: [          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Knowledge Base',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search knowledge bases...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                              _loadKnowledgeBases();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _createKnowledgeBase,
                          style: ElevatedButton.styleFrom(
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
          ),
          Expanded(
            child: _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadKnowledgeBases,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _knowledgeBases.isEmpty && !_isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'No knowledge bases found',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _createKnowledgeBase,
                              child: const Text('Create New Knowledge Base'),
                            ),
                          ],
                        ),
                      )                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: DataTable2(
                              headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                              columnSpacing: 12,
                              horizontalMargin: 12,
                              minWidth: 600,
                              dividerThickness: 1,
                              dataRowHeight: 64,
                              headingRowHeight: 56,
                              columns: const [
                                DataColumn2(
                                  label: Text('Name'),
                                  size: ColumnSize.L,
                                ),
                                DataColumn2(
                                  label: Text('Description'),
                                  size: ColumnSize.L,
                                ),
                                DataColumn2(
                                  label: Text('Status'),
                                  size: ColumnSize.S,
                                ),
                                DataColumn2(
                                  label: Text('Created'),
                                  size: ColumnSize.S,
                                ),
                                DataColumn2(
                                  label: Text('Actions'),
                                  size: ColumnSize.M,
                                ),
                              ],
                              rows: _knowledgeBases.map((kb) {
                                return DataRow2(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => KnowledgeBaseDetailScreen(
                                          knowledgeBaseId: kb.id,
                                        ),
                                      ),
                                    );
                                  },
                                  cells: [
                                    DataCell(
                                      Container(
                                        constraints: const BoxConstraints(maxWidth: 200),
                                        child: Text(
                                          kb.name,
                                          overflow: TextOverflow.ellipsis, 
                                          maxLines: 1,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    ),
                                    DataCell(
                                      Container(
                                        constraints: const BoxConstraints(maxWidth: 250),
                                        child: Text(
                                          kb.description.isEmpty ? 'No description' : kb.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    ),
                                    DataCell(_buildStatusBadge(kb.status)),
                                    DataCell(Text(
                                      _formatDate(kb.createdAt),
                                    )),
                                    DataCell(
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () {
                                              // Handle edit
                                            },
                                            tooltip: 'Edit',
                                            iconSize: 20,
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: theme.colorScheme.error,
                                            ),
                                            onPressed: () => _showDeleteConfirmation(kb),
                                            tooltip: 'Delete',
                                            iconSize: 20,
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.arrow_forward,
                                              color: Colors.green,
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) => KnowledgeBaseDetailScreen(
                                                    knowledgeBaseId: kb.id,
                                                  ),
                                                ),
                                              );
                                            },
                                            tooltip: 'Add Knowledge Unit',
                                            iconSize: 20,
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
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