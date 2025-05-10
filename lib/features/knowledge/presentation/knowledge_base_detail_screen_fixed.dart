import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/knowledge_base_model.dart';
import '../services/knowledge_base_service.dart';
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
  State<KnowledgeBaseDetailScreen> createState() => _KnowledgeBaseDetailScreenState();
}

class _KnowledgeBaseDetailScreenState extends State<KnowledgeBaseDetailScreen> {
  final KnowledgeBaseService _knowledgeBaseService = KnowledgeBaseService();
  bool _isLoading = true;
  KnowledgeBase? _knowledgeBase;
  String? _error;

  // Phương thức helper để định dạng bytes thành chuỗi đọc được
  String _formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';
    
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    final i = (log(bytes) / log(1024)).floor();
    
    // If less than 1 KB, show in bytes with no decimal places
    if (i == 0) return '$bytes ${suffixes[i]}';
    
    // Otherwise show with the specified number of decimal places
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
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
      final knowledgeBase = await _knowledgeBaseService.getKnowledgeBase(widget.knowledgeBaseId);

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addKnowledgeUnit,
        icon: const Icon(Icons.add),
        label: const Text('Add Knowledge Unit'),
        backgroundColor: const Color(0xFF6366F1), // Indigo color to match the button in the screenshot
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildKnowledgeBaseDetail(),
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
            onPressed: _loadKnowledgeBase,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildKnowledgeBaseDetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Knowledge base header card
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
                // Title and ID
                Text(
                  _knowledgeBase!.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // Description
                if (_knowledgeBase!.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _knowledgeBase!.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Status badge and dates
                Row(
                  children: [
                    _buildStatusBadge(_knowledgeBase!.status),
                    const SizedBox(width: 16),
                    Text(
                      'Created: ${_formatDate(_knowledgeBase!.createdAt)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Updated: ${_formatDate(_knowledgeBase!.updatedAt)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Units count and total size
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_knowledgeBase!.unitCount} ${_knowledgeBase!.unitCount == 1 ? 'unit' : 'units'}',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatBytes(_knowledgeBase!.totalSize),
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildActionButton(
                        'Upload File',
                        Icons.upload_file,
                        _uploadFile,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        'Website URL',
                        Icons.language,
                        _addWebsiteSource,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        'Google Drive',
                        Icons.folder_shared,
                        _connectGoogleDrive,
                      ),
                      // Add more buttons as needed
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Data Sources Header
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Data Sources',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Sources list or empty state
        Expanded(
          child: _knowledgeBase!.sources.isEmpty
              ? _buildEmptySourcesView()
              : _buildSourcesList(),
        ),
      ],
    );
  }

  Widget _buildEmptySourcesView() {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.folder_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No data sources added yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first data source using the buttons above',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _uploadFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload a File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
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
  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        foregroundColor: Colors.black87,
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
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
