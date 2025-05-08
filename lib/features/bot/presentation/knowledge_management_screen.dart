import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:file_picker/file_picker.dart';
import '../models/knowledge_data.dart';
import '../services/bot_service.dart';

class KnowledgeManagementScreen extends StatefulWidget {
  const KnowledgeManagementScreen({super.key});

  @override
  State<KnowledgeManagementScreen> createState() => _KnowledgeManagementScreenState();
}

class _KnowledgeManagementScreenState extends State<KnowledgeManagementScreen>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  final BotService _botService = BotService();
  
  late TabController _tabController;
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Knowledge base lists
  List<KnowledgeData> _knowledgeBases = [];
  String _searchQuery = '';
  KnowledgeType? _selectedTypeFilter;

  // Upload states
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _slackTokenController = TextEditingController();
  final TextEditingController _confluenceUrlController = TextEditingController();
  final TextEditingController _confluenceUsernameController = TextEditingController();
  final TextEditingController _confluenceApiTokenController = TextEditingController();
  final TextEditingController _googleDriveFolderIdController = TextEditingController();
  
  // New dialog for creating knowledge base
  void _showCreateKnowledgeBaseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create a Knowledge Base'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Knowledge Base Name Field
              const Text(
                'Knowledge Base Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter a unique name for your knowledge base',
                  border: OutlineInputBorder(),
                ),
              ),
              const Text(
                '0/50 characters',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.end,
              ),
              const SizedBox(height: 16),
              
              // Description Field
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Briefly describe the purpose of this knowledge base (e.g., Jarvis AI\'s knowledge base,...)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const Text(
                '0/500 characters',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createKnowledgeBase();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchKnowledgeBases();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _slackTokenController.dispose();
    _confluenceUrlController.dispose();
    _confluenceUsernameController.dispose();
    _confluenceApiTokenController.dispose();
    _googleDriveFolderIdController.dispose();
    super.dispose();
  }

  // Fetch all available knowledge bases
  Future<void> _fetchKnowledgeBases() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      final knowledgeBases = await _botService.getKnowledgeBases(query: _searchQuery);
      
      if (!mounted) return;
      
      setState(() {
        _knowledgeBases = knowledgeBases;
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

  // Create a new knowledge base
  Future<void> _createKnowledgeBase() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for the knowledge base'))
      );
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      final newKnowledgeBase = await _botService.createKnowledgeBase(
        name: _nameController.text,
        description: _descriptionController.text,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Knowledge base "${newKnowledgeBase.name}" created successfully'))
      );
      
      // Clear form fields
      _nameController.clear();
      _descriptionController.clear();
      
      // Refresh the list
      _fetchKnowledgeBases();
      
    } catch (e) {
      _logger.e('Error creating knowledge base: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating knowledge base: $e'))
      );
    }
  }

  // Delete a knowledge base
  Future<void> _deleteKnowledgeBase(KnowledgeData knowledge) async {
    // Show confirmation dialog
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Knowledge Base'),
        content: Text('Are you sure you want to delete "${knowledge.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      await _botService.deleteKnowledgeBase(knowledge.id);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Knowledge base "${knowledge.name}" deleted successfully'))
      );
      
      // Refresh the list
      _fetchKnowledgeBases();
      
    } catch (e) {
      _logger.e('Error deleting knowledge base: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting knowledge base: $e'))
      );
    }
  }

  // Upload file to knowledge base
  Future<void> _uploadFile(KnowledgeData knowledgeBase) async {
    try {
      // Use file_picker to select a file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'md', 'csv', 'json', 'xlsx', 'xls', 'pptx', 'ppt'],
      );
      
      if (result == null || result.files.single.path == null) {
        return; // User canceled the picker
      }
      
      final file = File(result.files.single.path!);
      
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.1;
      });
      
      // Update progress to simulate activity
      setState(() {
        _uploadProgress = 0.3;
      });
      
      // Upload the file
      await _botService.uploadFileToKnowledge(
        knowledgeBaseId: knowledgeBase.id,
        file: file,
      );
      
      setState(() {
        _uploadProgress = 0.9;
      });
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) return;
      
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File ${file.path.split('/').last} uploaded successfully'))
      );
      
      // Refresh the list
      _fetchKnowledgeBases();
      
    } catch (e) {
      _logger.e('Error uploading file: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: $e'))
      );
    }
  }

  // Upload website to knowledge base
  Future<void> _uploadWebsite(KnowledgeData knowledgeBase) async {
    if (_urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a URL'))
      );
      return;
    }
    
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.1;
      });
      
      // Upload the website
      await _botService.uploadWebsiteToKnowledge(
        knowledgeBaseId: knowledgeBase.id,
        url: _urlController.text,
        recursive: true,
        maxPages: 100,
      );
      
      setState(() {
        _uploadProgress = 1.0;
      });
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) return;
      
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      
      // Clear the URL field
      _urlController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Website upload initiated for ${knowledgeBase.name}'))
      );
      
      // Refresh the list
      _fetchKnowledgeBases();
      
    } catch (e) {
      _logger.e('Error uploading website: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading website: $e'))
      );
    }
  }

  // Upload from Google Drive
  Future<void> _uploadFromGoogleDrive(KnowledgeData knowledgeBase) async {
    if (_googleDriveFolderIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Google Drive folder ID'))
      );
      return;
    }
    
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.1;
      });
      
      // Upload from Google Drive
      await _botService.uploadGoogleDriveToKnowledge(
        knowledgeBaseId: knowledgeBase.id,
        folderId: _googleDriveFolderIdController.text,
      );
      
      setState(() {
        _uploadProgress = 1.0;
      });
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) return;
      
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      
      // Clear the folder ID field
      _googleDriveFolderIdController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Drive upload initiated for ${knowledgeBase.name}'))
      );
      
      // Refresh the list
      _fetchKnowledgeBases();
      
    } catch (e) {
      _logger.e('Error uploading from Google Drive: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading from Google Drive: $e'))
      );
    }
  }

  // Upload from Slack
  Future<void> _uploadFromSlack(KnowledgeData knowledgeBase) async {
    if (_slackTokenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Slack token'))
      );
      return;
    }
    
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.1;
      });
      
      // Upload from Slack
      await _botService.uploadSlackToKnowledge(
        knowledgeBaseId: knowledgeBase.id,
        slackToken: _slackTokenController.text,
      );
      
      setState(() {
        _uploadProgress = 1.0;
      });
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) return;
      
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      
      // Clear the token field
      _slackTokenController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Slack upload initiated for ${knowledgeBase.name}'))
      );
      
      // Refresh the list
      _fetchKnowledgeBases();
      
    } catch (e) {
      _logger.e('Error uploading from Slack: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading from Slack: $e'))
      );
    }
  }

  // Upload from Confluence
  Future<void> _uploadFromConfluence(KnowledgeData knowledgeBase) async {
    if (_confluenceUrlController.text.isEmpty || 
        _confluenceUsernameController.text.isEmpty || 
        _confluenceApiTokenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all Confluence details'))
      );
      return;
    }
    
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.1;
      });
      
      // Upload from Confluence
      await _botService.uploadConfluenceToKnowledge(
        knowledgeBaseId: knowledgeBase.id,
        confluenceUrl: _confluenceUrlController.text,
        username: _confluenceUsernameController.text,
        apiToken: _confluenceApiTokenController.text,
      );
      
      setState(() {
        _uploadProgress = 1.0;
      });
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) return;
      
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      
      // Clear the fields
      _confluenceUrlController.clear();
      _confluenceUsernameController.clear();
      _confluenceApiTokenController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Confluence upload initiated for ${knowledgeBase.name}'))
      );
      
      // Refresh the list
      _fetchKnowledgeBases();
      
    } catch (e) {
      _logger.e('Error uploading from Confluence: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading from Confluence: $e'))
      );
    }
  }

  // Display dialog to upload data to a knowledge base
  void _showUploadDialog(KnowledgeData knowledgeBase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload to "${knowledgeBase.name}"'),
        content: SizedBox(
          width: 500,
          child: DefaultTabController(
            length: 5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'File'),
                    Tab(text: 'Website'),
                    Tab(text: 'G.Drive'),
                    Tab(text: 'Slack'),
                    Tab(text: 'Confluence'),
                  ],
                  labelColor: Colors.blue,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: TabBarView(
                    children: [
                      // File Upload
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Upload a document file to your knowledge base'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _uploadFile(knowledgeBase);
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Choose File'),
                          ),
                        ],
                      ),
                      
                      // Website Upload
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Upload content from a website'),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _urlController,
                            decoration: const InputDecoration(
                              labelText: 'Website URL',
                              hintText: 'https://example.com',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _uploadWebsite(knowledgeBase);
                            },
                            icon: const Icon(Icons.language),
                            label: const Text('Upload Website'),
                          ),
                        ],
                      ),
                      
                      // Google Drive Upload
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Upload files from Google Drive'),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _googleDriveFolderIdController,
                            decoration: const InputDecoration(
                              labelText: 'Google Drive Folder ID',
                              hintText: '1a2b3c4d5e',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _uploadFromGoogleDrive(knowledgeBase);
                            },
                            icon: const Icon(Icons.drive_folder_upload),
                            label: const Text('Import from Google Drive'),
                          ),
                        ],
                      ),
                      
                      // Slack Upload
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Upload data from Slack workspace'),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _slackTokenController,
                            decoration: const InputDecoration(
                              labelText: 'Slack Auth Token',
                              hintText: 'xoxb-...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _uploadFromSlack(knowledgeBase);
                            },
                            icon: const Icon(Icons.chat),
                            label: const Text('Import from Slack'),
                          ),
                        ],
                      ),
                      
                      // Confluence Upload
                      SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Upload data from Confluence'),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _confluenceUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Confluence URL',
                                hintText: 'https://example.atlassian.net',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _confluenceUsernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                hintText: 'youremail@example.com',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _confluenceApiTokenController,
                              decoration: const InputDecoration(
                                labelText: 'API Token',
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _uploadFromConfluence(knowledgeBase);
                              },
                              icon: const Icon(Icons.article),
                              label: const Text('Import from Confluence'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }

  // Filter knowledge bases based on search query and type
  List<KnowledgeData> get _filteredKnowledgeBases {
    return _knowledgeBases.where((knowledge) {
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
    return _knowledgeBases.where((k) => k.type == type).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Base Management'),
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
          // Create new knowledge base form
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and description fields
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Knowledge Base',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          hintText: 'Enter a name for the knowledge base',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter a description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Create button
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _showCreateKnowledgeBaseDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Create'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Search and filter bar
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Knowledge Bases',
                    hintText: 'Enter search terms...',
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
                    border: const OutlineInputBorder(),
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
                      
                      // Google Drive filter
                      FilterChip(
                        label: Text('Google Drive (${_getKnowledgeBaseCountByType(KnowledgeType.googleDrive)})'),
                        selected: _selectedTypeFilter == KnowledgeType.googleDrive,
                        onSelected: (_) {
                          setState(() {
                            _selectedTypeFilter = _selectedTypeFilter == KnowledgeType.googleDrive
                                ? null
                                : KnowledgeType.googleDrive;
                          });
                        },
                        avatar: const Icon(Icons.drive_folder_upload, size: 18),
                      ),
                      const SizedBox(width: 8),
                      
                      // Slack filter
                      FilterChip(
                        label: Text('Slack (${_getKnowledgeBaseCountByType(KnowledgeType.slack)})'),
                        selected: _selectedTypeFilter == KnowledgeType.slack,
                        onSelected: (_) {
                          setState(() {
                            _selectedTypeFilter = _selectedTypeFilter == KnowledgeType.slack
                                ? null
                                : KnowledgeType.slack;
                          });
                        },
                        avatar: const Icon(Icons.chat, size: 18),
                      ),
                      const SizedBox(width: 8),
                      
                      // Confluence filter
                      FilterChip(
                        label: Text('Confluence (${_getKnowledgeBaseCountByType(KnowledgeType.confluence)})'),
                        selected: _selectedTypeFilter == KnowledgeType.confluence,
                        onSelected: (_) {
                          setState(() {
                            _selectedTypeFilter = _selectedTypeFilter == KnowledgeType.confluence
                                ? null
                                : KnowledgeType.confluence;
                          });
                        },
                        avatar: const Icon(Icons.article, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Results count
          if (!_isLoading && _errorMessage.isEmpty && _knowledgeBases.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${_filteredKnowledgeBases.length} of ${_knowledgeBases.length} knowledge bases',
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Total documents: ${_knowledgeBases.fold(0, (sum, kb) => sum + kb.documentCount)}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
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
                _isLoading && _knowledgeBases.isEmpty
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
                        : _knowledgeBases.isEmpty
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
                                      onPressed: () {
                                        if (_nameController.text.isNotEmpty) {
                                          _createKnowledgeBase();
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Please enter a name for the knowledge base'))
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text('Create Knowledge Base'),
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
                                      
                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                          vertical: 8.0,
                                        ),
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
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
                                                backgroundColor: theme.colorScheme.primary.withAlpha(25),
                                                child: Icon(
                                                  _getKnowledgeTypeIcon(knowledge.type),
                                                  color: theme.colorScheme.primary,
                                                ),
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  TextButton.icon(
                                                    onPressed: () => _showUploadDialog(knowledge),
                                                    icon: const Icon(Icons.upload_file),
                                                    label: const Text('Upload'),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete),
                                                    color: Colors.red,
                                                    onPressed: () => _deleteKnowledgeBase(knowledge),
                                                    tooltip: 'Delete Knowledge Base',
                                                  ),
                                                ],
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
                                                        color: theme.colorScheme.onSurface,
                                                      ),
                                                    ),
                                                    backgroundColor: theme.colorScheme.surface,
                                                  ),
                                                  
                                                  // Type
                                                  Chip(
                                                    label: Text(
                                                      knowledge.typeDisplayName,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: theme.colorScheme.onSurface,
                                                      ),
                                                    ),
                                                    backgroundColor: theme.colorScheme.surface,
                                                    avatar: Icon(
                                                      _getKnowledgeTypeIcon(knowledge.type),
                                                      size: 14,
                                                      color: theme.colorScheme.primary,
                                                    ),
                                                  ),
                                                  
                                                  // Last updated
                                                  Text(
                                                    'Updated: ${_formatDate(knowledge.updatedAt)}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: theme.colorScheme.onSurface.withAlpha(178),
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
                                'Uploading data...',
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
                                    theme.colorScheme.primary,
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
                                  color: theme.colorScheme.onSurface.withAlpha(178),
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
    );
  }
  
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
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}