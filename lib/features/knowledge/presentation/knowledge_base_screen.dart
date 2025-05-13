import 'dart:math';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/knowledge_base_model.dart';
import '../services/knowledge_base_service.dart';
import '../../../widgets/button.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/information.dart';
import '../../../widgets/text_field.dart';
import '../../../core/constants/app_colors.dart';
import 'create_knowledge_base_drawer.dart';
import 'knowledge_base_detail_screen.dart';

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  final KnowledgeBaseService _knowledgeBaseService = KnowledgeBaseService();
  final Logger _logger = Logger();

  int _page = 1;
  String _searchQuery = '';
  String? _error;
  List<KnowledgeBase> _allKnowledgeBases =
      []; // Store all loaded knowledge bases
  List<KnowledgeBase> _filteredKnowledgeBases =
      []; // Store filtered knowledge bases

  bool _isLoading = false;
  bool _hasMoreData = true;

  final int _limit = 10; // Local implementation of formatBytes method
  String _formatBytes(int? bytes) {
    _logger.d('KnowledgeBaseScreen._formatBytes input: $bytes bytes');
    if (bytes == null || bytes <= 0) {
      _logger
          .d('KnowledgeBaseScreen._formatBytes returning: 0 B (null or <= 0)');
      return '0 B';
    }

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    final i = (log(bytes) / log(1024)).floor();
    _logger.d('KnowledgeBaseScreen._formatBytes suffixes index: $i');

    // If less than 1 KB, show in bytes with no decimal places
    if (i == 0) {
      final result = '$bytes ${suffixes[i]}';
      _logger.d('KnowledgeBaseScreen._formatBytes returning: $result (bytes)');
      return result;
    }

    // Otherwise show with the specified number of decimal places
    final result =
        '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
    _logger.d('KnowledgeBaseScreen._formatBytes returning: $result');
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
      _allKnowledgeBases = [];
      _filteredKnowledgeBases = [];
    });

    try {
      _logger.d('Loading knowledge bases');
      final knowledgeBases = await _knowledgeBaseService.getKnowledgeBases(
        page: _page,
        limit: _limit,
        includeUnits:
            true, // Make sure we fetch datasources for each knowledge base
      );

      // Log the datasources count for debugging
      for (var kb in knowledgeBases) {
        _logger.d(
            'Knowledge base ${kb.knowledgeName} has ${kb.sources.length} datasources');
        _logger.d('Unit count (from getter): ${kb.unitCount}');
        _logger.d(
            'Total size: ${kb.totalSize} bytes (${_formatBytes(kb.totalSize)})');
      }

      setState(() {
        _allKnowledgeBases = knowledgeBases;
        _applySearch(); // Apply any current search filter
        _hasMoreData = knowledgeBases.length >= _limit;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading knowledge bases: $e');
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
        page: _page,
        limit: _limit,
      );

      setState(() {
        _allKnowledgeBases.addAll(moreKnowledgeBases);
        _applySearch(); // Apply current search filter to include new data
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

  // Apply search filter to knowledge bases
  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredKnowledgeBases = List.from(_allKnowledgeBases);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredKnowledgeBases = _allKnowledgeBases.where((kb) {
        return kb.name.toLowerCase().contains(query) ||
            kb.description.toLowerCase().contains(query);
      }).toList();
      _logger.d(
          'Filtered knowledge bases: ${_filteredKnowledgeBases.length} found for query "$_searchQuery"');
    }
  }

  Future<void> _deleteKnowledgeBase(KnowledgeBase knowledgeBase) async {
    try {
      await _knowledgeBaseService.deleteKnowledgeBase(knowledgeBase.id);

      setState(() {
        // Remove the knowledge base from all lists
        _allKnowledgeBases.removeWhere((kb) => kb.id == knowledgeBase.id);
        _applySearch(); // Re-apply search to update the filtered list
      });

      if (mounted) {
        GlobalSnackBar.show(
          context: context,
          message:
              'Knowledge base "${knowledgeBase.name}" deleted successfully',
          variant: SnackBarVariant.success,
        );
      }
    } catch (e) {
      _logger.e('Error deleting knowledge base: $e');

      if (mounted) {
        GlobalSnackBar.show(
          context: context,
          message: 'Failed to delete knowledge base: ${e.toString()}',
          variant: SnackBarVariant.error,
        );
      }
    }
  }

  Future<void> _createKnowledgeBase() async {
    await CreateKnowledgeBaseDrawer.show(
      context,
      () {
        // Only reload the entire list when a new knowledge base is created
        _loadKnowledgeBases();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Base'),
        centerTitle: true,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
            ),
            onPressed: _isLoading ? null : _loadKnowledgeBases,
            tooltip: 'Refresh',
          ),
        ),
        actions: [
          // Create knowledge button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
              ),
              tooltip: 'Create new knowledge base',
              onPressed: _createKnowledgeBase,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search section
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
            child: CommonTextField(
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
                          _applySearch();
                        });
                      },
                    )
                  : null,
              darkMode: isDarkMode,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applySearch();
                });
              },
            ),
          ),

          // Stats summary
          if (!_isLoading &&
              _error == null &&
              _filteredKnowledgeBases.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 16.0),
              child: Row(
                children: [
                  ResultsCountIndicator(
                    filteredCount: _filteredKnowledgeBases.length,
                    totalCount: _allKnowledgeBases.length,
                    itemType: 'KBs',
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.storage,
                        size: 20,
                        color: Theme.of(context).hintColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_filteredKnowledgeBases.where((kb) => kb.status.toLowerCase() == 'active').length} active',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // List of knowledge bases
          Expanded(
            child: _isLoading
                ? InformationIndicator(
                    message: 'Loading...',
                    variant: InformationVariant.loading,
                  )
                : _error != null
                    ? InformationIndicator(
                        message: _error,
                        variant: InformationVariant.error,
                        buttonText: 'Retry',
                        onButtonPressed: _loadKnowledgeBases,
                      )
                    : _allKnowledgeBases.isEmpty && !_isLoading
                        ? InformationIndicator(
                            message:
                                'No knowledge bases yet\nCreate one to get started',
                            variant: InformationVariant.info,
                          )
                        : _filteredKnowledgeBases.isEmpty &&
                                _searchQuery.isNotEmpty
                            ? InformationIndicator(
                                message:
                                    'No results match "$_searchQuery"\nTry a different search term',
                                variant: InformationVariant.info,
                                buttonText: 'Clear Search',
                                onButtonPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _applySearch();
                                  });
                                },
                              )
                            : _buildKnowledgeBaseList(),
          ),
        ],
      ),
    );
  }

  Widget _buildKnowledgeBaseList() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _loadKnowledgeBases,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 20.0),
        itemCount: _filteredKnowledgeBases.length,
        itemBuilder: (context, index) {
          final kb = _filteredKnowledgeBases[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: KnowledgeBaseCard(
              knowledgeBase: kb,
              onEdit: () {
                // Handle edit action
              },
              onDelete: () => _showDeleteConfirmation(kb),
              onView: () => _navigateToDetail(kb.id),
              isDarkMode: isDarkMode,
            ),
          );
        },
      ),
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

  void _showDeleteConfirmation(KnowledgeBase knowledgeBase) {
    GlobalDialog.show(
      context: context,
      title: 'Confirm Delete',
      message:
          'Are you sure you want to delete "${knowledgeBase.name}"? This action cannot be undone.',
      variant: DialogVariant.warning,
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      onConfirm: () {
        _deleteKnowledgeBase(knowledgeBase);
      },
    );
  }
}

// Separate card widget for cleaner code
class KnowledgeBaseCard extends StatelessWidget {
  final KnowledgeBase knowledgeBase;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;
  final bool isDarkMode;

  const KnowledgeBaseCard({
    super.key,
    required this.knowledgeBase,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
    required this.isDarkMode,
  });

  String _formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) {
      return '0 B';
    }

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    final i = (log(bytes) / log(1024)).floor();

    // If less than 1 KB, show in bytes with no decimal places
    if (i == 0) {
      return '$bytes ${suffixes[i]}';
    }

    // Otherwise show with the specified number of decimal places
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  Widget _buildStatusBadge(
      BuildContext context, String status, AppColors colors) {
    IconData icon;
    Color color;

    switch (status.toLowerCase()) {
      case 'active':
        color = colors.green;
        icon = Icons.check_circle;
        break;
      case 'processing':
        color = colors.primary;
        icon = Icons.hourglass_top;
        break;
      case 'error':
        color = colors.red;
        icon = Icons.error;
        break;
      default:
        color = colors.cardForeground.withAlpha(120);
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(160)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppColors colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row with icon and action buttons
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.storage,
                        size: 24,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusBadge(context, knowledgeBase.status, colors),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    color: colors.red,
                    tooltip: 'Delete',
                  ),
                ],
              ),

              const SizedBox(height: 12),
              // Knowledge base name and description
              Text(
                knowledgeBase.name,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              if (knowledgeBase.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 1.0),
                  child: Text(
                    knowledgeBase.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Unit count
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
                              '${knowledgeBase.unitCount} ${knowledgeBase.unitCount == 1 ? 'unit' : 'units'}',
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

                      const SizedBox(width: 12),

                      // Size
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.primary.withAlpha(24),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.data_usage,
                              size: 16,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatBytes(knowledgeBase.totalSize),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Button(
                    label: 'Update',
                    icon: Icons.edit,
                    onPressed: onView,
                    variant: ButtonVariant.primary,
                    size: ButtonSize.medium,
                    isDarkMode: isDarkMode,
                    width: 120,
                    fullWidth: false,
                    radius: ButtonRadius.small,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
