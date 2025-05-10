import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:data_table_2/data_table_2.dart';
import '../models/knowledge_base_model.dart';
import '../services/knowledge_base_service.dart';
import 'add_website_dialog.dart';
import 'connect_google_drive_dialog.dart';
import 'connect_slack_dialog.dart';
import 'connect_confluence_dialog.dart';

class KnowledgeBaseDetailScreen extends StatefulWidget {
  final String knowledgeBaseId;

  const KnowledgeBaseDetailScreen({
    super.key,
    required this.knowledgeBaseId,
  });

  @override
  State<KnowledgeBaseDetailScreen> createState() => _KnowledgeBaseDetailScreenState();
}

class _KnowledgeBaseDetailScreenState extends State<KnowledgeBaseDetailScreen> {
  final KnowledgeBaseService _knowledgeBaseService = KnowledgeBaseService();
  bool _isLoading = true;
  KnowledgeBase? _knowledgeBase;
  String? _error;

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
      final knowledgeBase =
          await _knowledgeBaseService.getKnowledgeBase(widget.knowledgeBaseId);

      if (!mounted) return;
      setState(() {
        _knowledgeBase = knowledgeBase;
        _isLoading = false;
      });
    } catch (e) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Source "${source.name}" deleted successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      _loadKnowledgeBase();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete source: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        _loadKnowledgeBase();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload file: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_knowledgeBase?.name ?? 'Knowledge Base'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadKnowledgeBase,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
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
                        onPressed: _loadKnowledgeBase,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,                    children: [
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _knowledgeBase!.name,
                                          style: theme.textTheme.headlineMedium,
                                        ),
                                        if (_knowledgeBase!.description.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            _knowledgeBase!.description,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            _buildStatusBadge(_knowledgeBase!.status),
                                            const SizedBox(width: 16),
                                            Text(
                                              'Created: ${_formatDate(_knowledgeBase!.createdAt)}',
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              'Updated: ${_formatDate(_knowledgeBase!.updatedAt)}',
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  _buildAddSourceButton(
                                    'Upload File',
                                    Icons.upload_file,
                                    _uploadFile,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildAddSourceButton(
                                    'Website URL',
                                    Icons.web,
                                    _addWebsiteSource,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildAddSourceButton(
                                    'Google Drive',
                                    Icons.folder_shared,
                                    _connectGoogleDrive,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildAddSourceButton(
                                    'Slack',
                                    Icons.message,
                                    _connectSlack,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildAddSourceButton(
                                    'Confluence',
                                    Icons.article,
                                    _connectConfluence,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),                      Text(
                        'Data Sources',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),                      _knowledgeBase!.sources.isEmpty
                          ? _buildEmptySourcesMessage()
                          : Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: SizedBox(
                                  width: double.infinity,                                child: DataTable2(
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
                                        label: Text('Type'),
                                        size: ColumnSize.S,
                                      ),
                                      DataColumn2(
                                        label: Text('Status'),
                                        size: ColumnSize.S,
                                      ),
                                      DataColumn2(
                                        label: Text('Created'),
                                        size: ColumnSize.M,
                                      ),
                                      DataColumn2(
                                        label: Text('Actions'),
                                        size: ColumnSize.S,
                                      ),
                                    ],
                                    rows: _knowledgeBase!.sources.map((source) {                                      return DataRow2(
                                        cells: [
                                          DataCell(
                                            Container(
                                              constraints: const BoxConstraints(maxWidth: 200),
                                              child: Text(
                                                source.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          DataCell(_buildSourceTypeLabel(source.type)),
                                          DataCell(_buildStatusBadge(source.status)),
                                          DataCell(Text(
                                            _formatDate(source.createdAt),
                                          )),                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                                  onPressed: () {
                                                    // Handle edit source
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
                                                  onPressed: () =>
                                                      _showDeleteConfirmation(source),
                                                  tooltip: 'Delete',
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
                    ],
                  ),
                ),
    );
  }
  Widget _buildEmptySourcesMessage() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.source,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No data sources added yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first data source using the buttons above',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _uploadFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload a File'),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAddSourceButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceTypeLabel(String type) {
    IconData icon;
    String label = type;
    
    switch (type) {
      case 'file':
        icon = Icons.insert_drive_file;
        label = 'File';
        break;
      case 'website':
        icon = Icons.web;
        label = 'Website';
        break;
      case 'google_drive':
        icon = Icons.folder_shared;
        label = 'Google Drive';
        break;
      case 'slack':
        icon = Icons.message;
        label = 'Slack';
        break;
      case 'confluence':
        icon = Icons.article;
        label = 'Confluence';
        break;
      default:
        icon = Icons.source;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
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

  void _showDeleteConfirmation(KnowledgeSource source) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
            'Are you sure you want to delete "${source.name}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSource(source);
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