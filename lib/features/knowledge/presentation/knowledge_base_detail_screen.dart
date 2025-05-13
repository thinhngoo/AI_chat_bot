import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';
import '../models/knowledge_base_model.dart';
import '../services/knowledge_base_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/information.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/button.dart';
import 'add_website_dialog.dart';
import 'connect_google_drive_dialog.dart';
import 'connect_slack_dialog.dart';
import 'connect_confluence_dialog.dart';
import 'select_knowledge_source_dialog.dart';

class KnowledgeBaseDetailScreen extends StatefulWidget {
  final String knowledgeBaseId;

  const KnowledgeBaseDetailScreen({
    super.key,
    required this.knowledgeBaseId,
  });

  @override
  State<KnowledgeBaseDetailScreen> createState() =>
      _KnowledgeBaseDetailScreenState();
}

class _KnowledgeBaseDetailScreenState extends State<KnowledgeBaseDetailScreen> {
  final KnowledgeBaseService _knowledgeBaseService = KnowledgeBaseService();
  final _logger = Logger();

  bool _isLoading = true;
  KnowledgeBase? _knowledgeBase;
  String? _error; // Phương thức helper để định dạng bytes thành chuỗi đọc được
  String _formatBytes(int? bytes) {
    _logger.d('KnowledgeBaseDetailScreen._formatBytes input: $bytes bytes');
    if (bytes == null || bytes <= 0) {
      _logger.d(
          'KnowledgeBaseDetailScreen._formatBytes returning: 0 B (null or <= 0)');
      return '0 B';
    }

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    final i = (log(bytes) / log(1024)).floor();
    _logger.d('KnowledgeBaseDetailScreen._formatBytes suffixes index: $i');

    // If less than 1 KB, show in bytes with no decimal places
    if (i == 0) {
      final result = '$bytes ${suffixes[i]}';
      _logger.d(
          'KnowledgeBaseDetailScreen._formatBytes returning: $result (bytes)');
      return result;
    }

    // Otherwise show with the specified number of decimal places
    final result =
        '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
    _logger.d('KnowledgeBaseDetailScreen._formatBytes returning: $result');
    return result;
  }

  @override
  void initState() {
    super.initState();
    _loadKnowledgeBase();
  }

  Future<void> _loadKnowledgeBase() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First get the basic knowledge base info
      final knowledgeBase =
          await _knowledgeBaseService.getKnowledgeBase(widget.knowledgeBaseId);

      _logger.d('Knowledge Base loaded: ${knowledgeBase.knowledgeName}');
      _logger.d('Initial sources count: ${knowledgeBase.sources.length}');
      _logger.d('Unit count (from getter): ${knowledgeBase.unitCount}');

      // Now explicitly fetch datasources using the new method to ensure we get the latest data
      try {
        final datasources =
            await _knowledgeBaseService.getDatasources(widget.knowledgeBaseId);
        _logger.d('Fetched ${datasources.length} datasources directly');

        // Create an updated knowledge base with the fresh datasources
        final updatedKnowledgeBase = KnowledgeBase(
          id: knowledgeBase.id,
          knowledgeName: knowledgeBase.knowledgeName,
          description: knowledgeBase.description,
          status: knowledgeBase.status,
          userId: knowledgeBase.userId,
          createdBy: knowledgeBase.createdBy,
          updatedBy: knowledgeBase.updatedBy,
          createdAt: knowledgeBase.createdAt,
          updatedAt: knowledgeBase.updatedAt,
          sources: datasources,
        );

        // Debug each source
        for (var source in updatedKnowledgeBase.sources) {
          _logger.d(
              'Source: ${source.name}, fileSize: ${source.fileSize}, type: ${source.type}');
        }

        // Debug the total size
        _logger
            .d('Total size (from getter): ${updatedKnowledgeBase.totalSize}');
        _logger.d(
            'Total size formatted: ${_formatBytes(updatedKnowledgeBase.totalSize)}');

        if (!mounted) return;
        setState(() {
          _knowledgeBase = updatedKnowledgeBase;
          _isLoading = false;
        });
      } catch (datasourceError) {
        _logger.d(
            'Error fetching datasources: $datasourceError, using original knowledge base');

        // Use the original knowledge base if there was an error fetching datasources
        if (!mounted) return;
        setState(() {
          _knowledgeBase = knowledgeBase;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.d('Error loading knowledge base: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load knowledge base: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSource(KnowledgeSource source) async {
    try {
      await _knowledgeBaseService.deleteSource(
        widget.knowledgeBaseId,
        source.id,
      );

      if (!mounted) return;
      GlobalSnackBar.show(
        context: context,
        message: 'Source "${source.name}" deleted successfully',
        variant: SnackBarVariant.success,
      );

      _loadKnowledgeBase();
    } catch (e) {
      if (!mounted) return;
      GlobalSnackBar.show(
        context: context,
        message: 'Failed to delete source: $e',
        variant: SnackBarVariant.error,
      );
    }
  }

  Future<void> _addKnowledgeUnit() async {
    // Show the select knowledge source dialog
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const SelectKnowledgeSourceDialog(),
    );

    if (result == null) return;

    // Handle the selected source type
    switch (result) {
      case 'file':
        _uploadFile();
        break;
      case 'website':
        _addWebsiteSource();
        break;
      case 'google_drive':
        _connectGoogleDrive();
        break;
      case 'slack':
        _connectSlack();
        break;
      case 'confluence':
        _connectConfluence();
        break;
      // Add more cases as needed
    }
  }

  Future<void> _uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        if (!mounted) return;
        setState(() => _isLoading = true);

        await _knowledgeBaseService.uploadLocalFile(
          widget.knowledgeBaseId,
          file,
        );

        if (!mounted) return;
        GlobalSnackBar.show(
          context: context,
          message: 'File uploaded successfully',
          variant: SnackBarVariant.success,
        );

        _loadKnowledgeBase();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      GlobalSnackBar.show(
        context: context,
        message: 'Failed to upload file: $e',
        variant: SnackBarVariant.error,
      );
    }
  }

  Future<void> _addWebsiteSource() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddWebsiteDialog(
        knowledgeBaseId: widget.knowledgeBaseId,
      ),
    );

    if (result == true) {
      _loadKnowledgeBase();
    }
  }

  Future<void> _connectGoogleDrive() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConnectGoogleDriveDialog(
        knowledgeBaseId: widget.knowledgeBaseId,
      ),
    );

    if (result == true) {
      _loadKnowledgeBase();
    }
  }

  Future<void> _connectSlack() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConnectSlackDialog(
        knowledgeBaseId: widget.knowledgeBaseId,
      ),
    );

    if (result == true) {
      _loadKnowledgeBase();
    }
  }

  Future<void> _connectConfluence() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConnectConfluenceDialog(
        knowledgeBaseId: widget.knowledgeBaseId,
      ),
    );

    if (result == true) {
      _loadKnowledgeBase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _knowledgeBase?.name ?? 'Knowledge Base',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadKnowledgeBase,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addKnowledgeUnit,
        tooltip: 'Add Knowledge Unit',
        child: Icon(
          Icons.add,
        ),
      ),
      body: _isLoading
          ? InformationIndicator(
              message: 'Loading...',
              variant: InformationVariant.loading,
            )
          : _error != null
              ? InformationIndicator(
                  message: _error!,
                  variant: InformationVariant.error,
                  buttonText: 'Retry',
                  onButtonPressed: _loadKnowledgeBase,
                )
              : _buildKnowledgeBaseDetail(),
    );
  }

  Widget _buildKnowledgeBaseDetail() {
    AppColors colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    _buildStatusBadge(_knowledgeBase!.status),
                  ],
                ),

                const SizedBox(height: 12),

                // Knowledge base name
                Text(
                  _knowledgeBase!.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Description
                if (_knowledgeBase!.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, left: 1.0),
                    child: Text(
                      _knowledgeBase!.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                const SizedBox(height: 20),

                // Bottom row with dates and action buttons
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
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
                                '${_knowledgeBase!.unitCount} ${_knowledgeBase!.unitCount == 1 ? 'unit' : 'units'}',
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
                                _formatBytes(_knowledgeBase!.totalSize),
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

                    const Spacer(),

                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Created: ${_formatDate(_knowledgeBase!.createdAt)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                        ),
                        Text(
                          'Updated: ${_formatDate(_knowledgeBase!.updatedAt)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                        ),
                      ],
                    ),
                    // Action buttons row
                  ],
                ),
              ],
            ),
          ),
        ),

        // Data Sources Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Data Sources',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),

        const SizedBox(height: 4),

        Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Text(
            'Upload from:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ),

        const SizedBox(height: 4),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionButton(
              'File',
              Icons.upload_file,
              _uploadFile,
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              'URL',
              Icons.language,
              _addWebsiteSource,
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              'Drive',
              Icons.folder_shared,
              _connectGoogleDrive,
            ),
          ],
        ),

        // Sources list or empty state
        Expanded(
          child: _knowledgeBase!.sources.isEmpty
              ? InformationIndicator(
                  message: 'No data sources added yet',
                  variant: InformationVariant.info,
                )
              : _buildSourcesList(),
        ),
      ],
    );
  }

  Widget _buildSourcesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _knowledgeBase!.sources.length,
      itemBuilder: (context, index) {
        final source = _knowledgeBase!.sources[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 1,
          child: ListTile(
            leading: _getSourceIcon(source.type),
            title: Text(
              source.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildStatusBadge(source.status),
                    const SizedBox(width: 8),
                    Text(
                      'Created: ${_formatDate(source.createdAt)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                if (source.fileSize != null && source.fileSize! > 0)
                  Text(
                    _formatBytes(source.fileSize!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
              onPressed: () => _showDeleteConfirmation(source),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, VoidCallback onPressed) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Button(
      onPressed: onPressed,
      icon: icon,
      label: label,
      variant: ButtonVariant.normal,
      isDarkMode: isDarkMode,
      size: ButtonSize.medium,
      fontWeight: FontWeight.bold,
      width: 120,
      fullWidth: false,
      radius: ButtonRadius.small,
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
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

  Icon _getSourceIcon(String sourceType) {
    switch (sourceType) {
      case 'file':
        return const Icon(Icons.insert_drive_file, color: Colors.blue);
      case 'website':
        return const Icon(Icons.language, color: Colors.purple);
      case 'google_drive':
        return const Icon(Icons.folder_shared, color: Colors.green);
      case 'slack':
        return const Icon(Icons.message, color: Colors.orange);
      case 'confluence':
        return const Icon(Icons.article, color: Colors.blue);
      default:
        return const Icon(Icons.source, color: Colors.grey);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteConfirmation(KnowledgeSource source) {
    GlobalDialog.show(
      context: context,
      title: 'Confirm Delete',
      message:
          'Are you sure you want to delete "${source.name}"? This action cannot be undone.',
      variant: DialogVariant.warning,
      cancelLabel: 'Cancel',
      confirmLabel: 'Delete',
      onConfirm: () => _deleteSource(source),
    );
  }
}
