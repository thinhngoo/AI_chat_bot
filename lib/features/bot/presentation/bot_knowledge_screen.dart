import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/knowledge_data.dart';
import '../services/bot_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/text_field.dart';
import '../../../widgets/information.dart';

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

      // First, get all available knowledge bases
      final allKnowledgeBases = await _botService.getKnowledgeBases();

      // Then, get knowledge bases that are already imported to this bot
      final importedKnowledgeBases = await _botService.getImportedKnowledge(
          botId: widget.botId,
          limit: 50 // Get a reasonable limit of imported knowledge bases
          );

      // Extract IDs of imported knowledge bases
      final importedIds = importedKnowledgeBases.map((kb) => kb.id).toList();

      if (!mounted) return;

      setState(() {
        _allKnowledgeBases = allKnowledgeBases;
        _botKnowledgeBaseIds = importedIds;
        _isLoading = false;
      });

      _logger.i(
          'Fetched ${allKnowledgeBases.length} knowledge bases, ${importedIds.length} are imported to this bot');
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

        // Force UI update by creating a new list
        setState(() {
          _botKnowledgeBaseIds = List.from(_botKnowledgeBaseIds)
            ..remove(knowledge.id);
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

        // Force UI update by creating a new list
        setState(() {
          _botKnowledgeBaseIds = List.from(_botKnowledgeBaseIds)
            ..add(knowledge.id);
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

  // ignore: unused_element
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
                  'To implement this feature, add the dependency to pubspec.yaml:'),
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
          knowledge.description
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      // Filter by knowledge type
      final matchesType =
          _selectedTypeFilter == null || knowledge.type == _selectedTypeFilter;

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
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchKnowledgeBases,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          _buildSearchAndFilterBar(),

          // Results count
          if (!_isLoading &&
              _errorMessage.isEmpty &&
              _allKnowledgeBases.isNotEmpty)
            _buildResultsCount(),

          // Main content
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _uploadFile,
      //   tooltip: 'Upload Document',
      //   icon: const Icon(Icons.upload_file),
      //   label: const Text('Upload'),
      // ),
    );
  }

  // ignore: unused_element
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

  // Build a single knowledge base card
  Widget _buildKnowledgeCard(KnowledgeData knowledge, bool isAdded) {
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
        
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isAdded
              ? BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                  width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _toggleKnowledgeBase(knowledge),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with badges and actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withAlpha(12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(160),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color:
                                Theme.of(context).colorScheme.primary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Active',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Document count
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.green.withAlpha(24),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 16,
                            color: colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${knowledge.documentCount} ${knowledge.documentCount == 1 ? 'document' : 'documents'}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Name and description
                Text(
                  knowledge.name.isNotEmpty
                      ? knowledge.name
                      : 'Untitled',
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                if (knowledge.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 4.0, left: 1.0),
                    child: Text(
                      knowledge.description,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // Bottom row with date and indicator
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Updated: ${_formatDate(knowledge.updatedAt)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    ),
                    const Spacer(),
                    Switch(
                      value: isAdded,
                      onChanged: (value) =>
                          _toggleKnowledgeBase(knowledge),
                      activeColor: Theme.of(context).brightness ==
                              Brightness.dark
                          ? Theme.of(context)
                              .colorScheme
                              .onSurface
                          : Colors.white,
                      activeTrackColor:
                          Theme.of(context).hintColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
      child: Column(
        children: [
          // Search field with filter icon
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _searchController,
                  label: 'Search',
                  hintText: 'Search knowledge bases...',
                  prefixIcon: Icons.search,
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
                  darkMode: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Filter icon button
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceDim,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PopupMenuButton<KnowledgeType?>(
                  initialValue: _selectedTypeFilter,
                  tooltip: 'Filter by type',
                  position: PopupMenuPosition.under,
                  icon: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.filter_list,
                          color: _selectedTypeFilter != null
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).hintColor,
                        ),
                      ),
                      if (_selectedTypeFilter != null)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onSelected: (KnowledgeType? value) {
                    setState(() {
                      _selectedTypeFilter = value;
                    });
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<KnowledgeType?>(
                      value: null,
                      child: Row(
                        children: [
                          const Icon(Icons.all_inclusive, size: 18),
                          const SizedBox(width: 12),
                          const Text('All'),
                          const Spacer(),
                          if (_selectedTypeFilter == null)
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                    PopupMenuItem<KnowledgeType>(
                      value: KnowledgeType.document,
                      child: Row(
                        children: [
                          const Icon(Icons.description, size: 18),
                          const SizedBox(width: 12),
                          Text('Documents (${_getKnowledgeBaseCountByType(KnowledgeType.document)})'),
                          const Spacer(),
                          if (_selectedTypeFilter == KnowledgeType.document)
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                    PopupMenuItem<KnowledgeType>(
                      value: KnowledgeType.website,
                      child: Row(
                        children: [
                          const Icon(Icons.language, size: 18),
                          const SizedBox(width: 12),
                          Text('Websites (${_getKnowledgeBaseCountByType(KnowledgeType.website)})'),
                          const Spacer(),
                          if (_selectedTypeFilter == KnowledgeType.website)
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                    PopupMenuItem<KnowledgeType>(
                      value: KnowledgeType.database,
                      child: Row(
                        children: [
                          const Icon(Icons.storage, size: 18),
                          const SizedBox(width: 12),
                          Text('Databases (${_getKnowledgeBaseCountByType(KnowledgeType.database)})'),
                          const Spacer(),
                          if (_selectedTypeFilter == KnowledgeType.database)
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                    PopupMenuItem<KnowledgeType>(
                      value: KnowledgeType.api,
                      child: Row(
                        children: [
                          const Icon(Icons.api, size: 18),
                          const SizedBox(width: 12),
                          Text('APIs (${_getKnowledgeBaseCountByType(KnowledgeType.api)})'),
                          const Spacer(),
                          if (_selectedTypeFilter == KnowledgeType.api)
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCount() {
    return Padding(
      padding: const EdgeInsets.only(left: 26.0, right: 20.0, bottom: 8.0),
      child: ResultsCountIndicator(
        filteredCount: _filteredKnowledgeBases.length,
        totalCount: _allKnowledgeBases.length,
        itemType: 'knowledge bases',
      ),
    );
  }

  Widget _buildMainContent() {
    return Stack(
      children: [
        _isLoading
            ? InformationIndicator(
                message: 'Loading knowledge bases',
                variant: InformationVariant.loading,
              )
            : _errorMessage.isNotEmpty
                ? InformationIndicator(
                    message: 'Error: $_errorMessage',
                    variant: InformationVariant.error,
                    buttonText: 'Retry',
                    onButtonPressed: _fetchKnowledgeBases,
                  )
                : _allKnowledgeBases.isEmpty
                    ? InformationIndicator(
                        message: 'No knowledge bases found',
                        variant: InformationVariant.info,
                      )
                    : _filteredKnowledgeBases.isEmpty
                        ? InformationIndicator(
                            message: 'No knowledge bases found',
                            variant: InformationVariant.info,
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchKnowledgeBases,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: _filteredKnowledgeBases.length,
                              itemBuilder: (context, index) {
                                final knowledge =
                                    _filteredKnowledgeBases[index];
                                final isAdded = _botKnowledgeBaseIds
                                    .contains(knowledge.id);
                                
                                return _buildKnowledgeCard(knowledge, isAdded);
                              },
                            ),
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
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(
                                  178), // Changed from withOpacity to withAlpha
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
