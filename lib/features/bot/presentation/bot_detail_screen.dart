import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/ai_bot.dart';
import '../models/knowledge_data.dart';
import '../services/bot_service.dart';
import 'bot_knowledge_screen.dart';
import 'bot_publish_screen.dart';
import 'bot_integration_screen.dart';
import '../../../widgets/information.dart';
import '../../../widgets/text_field.dart';
import '../../../widgets/button.dart';
import '../../../widgets/dialog.dart';
import '../../../core/constants/app_colors.dart';

class BotDetailScreen extends StatefulWidget {
  final String botId;

  const BotDetailScreen({
    super.key,
    required this.botId,
  });

  @override
  State<BotDetailScreen> createState() => _BotDetailScreenState();
}

class _BotDetailScreenState extends State<BotDetailScreen>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  final BotService _botService = BotService();

  bool _isLoading = true;
  bool _isLoadingKnowledge = false;
  String _errorMessage = '';
  AIBot? _bot;
  List<KnowledgeData> _knowledgeBases = [];

  late TabController _tabController;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _promptController = TextEditingController();
  String _selectedModel = 'gpt-4o-mini';
  bool _isSaving = false;

  final List<Map<String, String>> _availableModels = [
    {'id': 'gpt-4o-mini', 'name': 'GPT-4o mini'},
    {'id': 'gpt-4o', 'name': 'GPT-4o'},
    {'id': 'gemini-1.5-flash-latest', 'name': 'Gemini 1.5 Flash'},
    {'id': 'gemini-1.5-pro-latest', 'name': 'Gemini 1.5 Pro'},
    {'id': 'claude-3-haiku-20240307', 'name': 'Claude 3 Haiku'},
    {'id': 'claude-3-sonnet-20240229', 'name': 'Claude 3 Sonnet'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchBotDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _fetchBotDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final bot = await _botService.getBotById(widget.botId);

      if (mounted) {
        setState(() {
          _bot = bot;
          _isLoading = false;

          // Set up form controllers
          _nameController.text = bot.name;
          _descriptionController.text = bot.description;
          _promptController.text = bot.prompt;
          _selectedModel = bot.model;
        });

        // Fetch knowledge bases
        _fetchKnowledgeBases();
      }
    } catch (e) {
      _logger.e('Error fetching bot details: $e');

      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchKnowledgeBases() async {
    try {
      setState(() {
        _isLoadingKnowledge = true;
      });

      _logger.i('Fetching knowledge bases for bot ${widget.botId}');

      // Get imported knowledge bases for this specific bot
      final importedKnowledgeBases = await _botService.getImportedKnowledge(
          botId: widget.botId,
          limit: 50 // Get a reasonable limit of imported knowledge bases
          );

      // Extract IDs of imported knowledge bases
      final importedIds = importedKnowledgeBases.map((kb) => kb.id).toList();

      if (mounted && _bot != null) {
        setState(() {
          // Update the bot's knowledge base IDs
          _bot = AIBot(
            id: _bot!.id,
            name: _bot!.name,
            description: _bot!.description,
            model: _bot!.model,
            prompt: _bot!.prompt,
            createdAt: _bot!.createdAt,
            updatedAt: _bot!.updatedAt,
            isPublished: _bot!.isPublished,
            connectedPlatforms: _bot!.connectedPlatforms,
            knowledgeBaseIds:
                importedIds, // Update with the actual imported knowledge base IDs
          );

          // Store the knowledge bases for display
          _knowledgeBases = importedKnowledgeBases;
          _isLoadingKnowledge = false;
        });

        _logger.i('Bot now has ${importedIds.length} knowledge bases');
      }
    } catch (e) {
      _logger.e('Error fetching knowledge bases: $e');
      if (mounted) {
        setState(() {
          _isLoadingKnowledge = false;
        });
      }
    }
  }

  Future<void> _removeKnowledgeBase(KnowledgeData knowledge) async {
    // Show confirmation dialog first
    final confirmed = await GlobalDialog.show(
      context: context,
      title: 'Remove Knowledge',
      message:
          'Are you sure you want to remove "${knowledge.name}" from this bot?\n\nThis will not delete the knowledge base itself.',
      variant: DialogVariant.warning,
      confirmLabel: 'Remove',
      cancelLabel: 'Cancel',
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isLoadingKnowledge = true;
      });
      await _botService.removeKnowledge(
        botId: widget.botId,
        knowledgeBaseId: knowledge.id,
      );

      if (!mounted) return;
      GlobalSnackBar.show(
        context: context,
        message:
            'Removed "${knowledge.name.isNotEmpty ? knowledge.name : 'Untitled'}" from bot',
        variant: SnackBarVariant.info,
        actionLabel: 'Undo',
        onActionPressed: () {
          _addKnowledgeBack(knowledge);
        },
      );

      // Refresh knowledge bases
      _fetchKnowledgeBases();
    } catch (e) {
      _logger.e('Error removing knowledge base: $e');

      if (mounted) {
        setState(() {
          _isLoadingKnowledge = false;
        });

        GlobalSnackBar.show(
          context: context,
          message: 'Error: ${e.toString()}',
          variant: SnackBarVariant.error,
        );
      }
    }
  }

  Future<void> _addKnowledgeBack(KnowledgeData knowledge) async {
    try {
      await _botService.importKnowledge(
        botId: widget.botId,
        knowledgeBaseIds: [knowledge.id],
      );
      // Refresh knowledge bases
      _fetchKnowledgeBases();

      if (!mounted) return;
      GlobalSnackBar.show(
        context: context,
        message:
            'Added "${knowledge.name.isNotEmpty ? knowledge.name : 'Untitled'}" back to bot',
        variant: SnackBarVariant.success,
      );
    } catch (e) {
      _logger.e('Error adding knowledge base back: $e');

      if (!mounted) return;
      GlobalSnackBar.show(
        context: context,
        message: 'Error: ${e.toString()}',
        variant: SnackBarVariant.error,
      );
    }
  }

  Future<void> _saveChanges() async {
    try {
      setState(() {
        _isSaving = true;
      });

      await _botService.updateBot(
        botId: widget.botId,
        name: _nameController.text,
        description: _descriptionController.text,
        model: _selectedModel,
        prompt: _promptController.text,
      );

      if (!mounted) return;

      GlobalSnackBar.show(
        context: context,
        message: 'Bot updated successfully',
        variant: SnackBarVariant.success,
      );

      // Refresh bot details
      _fetchBotDetails();
    } catch (e) {
      _logger.e('Error saving bot changes: $e');

      if (!mounted) return;

      GlobalSnackBar.show(
        context: context,
        message: 'Failed to update bot: ${e.toString()}',
        variant: SnackBarVariant.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = isDarkMode ? AppColors.dark : AppColors.light;

    return Scaffold(
      appBar: AppBar(
        title: Text(_bot?.name ?? 'Bot Details',
            overflow: TextOverflow.ellipsis, maxLines: 1),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.add_link),
              color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
              tooltip: 'Integrations',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BotIntegrationScreen(
                      botId: widget.botId,
                      botName: _bot?.name ?? 'Bot',
                    ),
                  ),
                ).then((_) => _fetchBotDetails());
              },
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 3.0,
              ),
            ),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Theme.of(context).colorScheme.outline.withAlpha(184),
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor:
              Theme.of(context).colorScheme.onSurface.withAlpha(184),
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Knowledge'),
            Tab(text: 'Publish'),
          ],
        ),
      ),
      body: _isLoading
          ? InformationIndicator(
              variant: InformationVariant.loading,
              message: 'Loading bot details...',
            )
          : _errorMessage.isNotEmpty
              ? InformationIndicator(
                  variant: InformationVariant.error,
                  message: 'Error: $_errorMessage',
                  buttonText: 'Retry',
                  onButtonPressed: _fetchBotDetails,
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Details Tab
                    _buildDetailsTab(isDarkMode),

                    // Knowledge Tab with list of knowledge bases
                    _buildKnowledgeTab(isDarkMode),

                    // Publish Tab
                    _buildPublishTab(isDarkMode),
                  ],
                ),
    );
  }

  Widget _buildDetailsTab(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16, 16.0, 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Update Bot Details',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          FloatingLabelTextField(
            controller: _nameController,
            label: 'Bot Name',
            hintText: 'Enter a name for your bot',
            enabled: !_isSaving,
            darkMode: isDarkMode,
          ),
          const SizedBox(height: 16),
          StyledDropdown<String>(
            label: 'AI Model',
            hintText: 'Select an AI model',
            value: _selectedModel,
            darkMode: isDarkMode,
            enabled: !_isSaving,
            prefixIcon: Icons.smart_toy,
            items: _availableModels.map((model) {
              return DropdownMenuItem<String>(
                value: model['id'],
                child: Text(model['name']!),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedModel = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          FloatingLabelTextField(
            controller: _descriptionController,
            label: 'Description',
            hintText: 'Describe what this bot does',
            maxLines: 2,
            enabled: !_isSaving,
            darkMode: isDarkMode,
          ),
          const SizedBox(height: 16),
          FloatingLabelTextField(
            controller: _promptController,
            label: 'Prompt Instructions',
            hintText: 'Enter instructions for the bot',
            maxLines: 6,
            enabled: !_isSaving,
            darkMode: isDarkMode,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Button(
                label: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
                variant: ButtonVariant.ghost,
                isDarkMode: isDarkMode,
                fullWidth: false,
                size: ButtonSize.medium,
                width: 100,
                radius: ButtonRadius.small,
                color: isDarkMode
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withAlpha(204),
              ),
              const SizedBox(width: 8),
              Button(
                label: 'Save',
                icon: Icons.save,
                onPressed: _saveChanges,
                variant: ButtonVariant.primary,
                isDarkMode: isDarkMode,
                fullWidth: false,
                size: ButtonSize.medium,
                fontWeight: FontWeight.bold,
                width: 100,
                radius: ButtonRadius.small,
                isLoading: _isSaving,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKnowledgeTab(bool isDarkMode) {
    final colors = isDarkMode ? AppColors.dark : AppColors.light;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Knowledge Base',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Bot has ${_bot?.knowledgeBaseIds.length ?? 0} knowledge bases',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),

        // List of knowledge bases
        _isLoadingKnowledge
            ? Expanded(
                child: InformationIndicator(
                  variant: InformationVariant.loading,
                  message: 'Loading knowledge bases...',
                ),
              )
            : _knowledgeBases.isEmpty
                ? Expanded(
                    child: InformationIndicator(
                      variant: InformationVariant.info,
                      message: 'No knowledge bases added yet\nAdd knowledge to enhance your bot',
                      buttonText: 'Add Knowledge',
                      onButtonPressed: () {
                        if (_bot != null) {
                          _navigateToKnowledgeScreen();
                        }
                      },
                    ),
                  )
                : Expanded(
                    child: Column(
                      children: [
                        // Knowledge list
                        Expanded(
                          child: ListView.builder(
                            itemCount: _knowledgeBases.length,
                            padding: const EdgeInsets.all(8.0),
                            itemBuilder: (context, index) {
                              final knowledge = _knowledgeBases[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      // Navigate to knowledge detail screen (not implemented in this example)
                                    },
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
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).colorScheme.primary.withAlpha(12),
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: Theme.of(context).colorScheme.primary.withAlpha(160),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.check_circle,
                                                      color: Theme.of(context).colorScheme.primary,
                                                      size: 14,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Active',
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: Theme.of(context).colorScheme.primary,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(width: 12),

                                              // Document count
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withAlpha(24),
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
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: colors.green,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              const Spacer(),

                                              IconButton(
                                                icon: Icon(Icons.delete_outline),
                                                onPressed: () => _removeKnowledgeBase(knowledge),
                                                color: colors.red,
                                                tooltip: 'Remove',
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 12),

                                          // Name and description
                                          Text(
                                            knowledge.name.isNotEmpty ? knowledge.name : 'Untitled',
                                            style: Theme.of(context).textTheme.titleMedium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                          if (knowledge.description.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4.0, left: 1.0),
                                              child: Text(
                                                knowledge.description,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Theme.of(context).hintColor,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),

                                          const SizedBox(height: 20),

                                          // Bottom row with date and actions
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Updated: ${_formatDate(knowledge.updatedAt)}',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context).hintColor,
                                                ),
                                              ),
                                              Button(
                                                label: 'Details',
                                                icon: Icons.arrow_forward,
                                                onPressed: () {
                                                  // Navigate to knowledge detail
                                                },
                                                variant: ButtonVariant.primary,
                                                size: ButtonSize.medium,
                                                isDarkMode: Theme.of(context).brightness == Brightness.dark,
                                                width: 120,
                                                fullWidth: false,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Add more knowledge button
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Button(
                            label: 'Add More Knowledge',
                            onPressed: () => _navigateToKnowledgeScreen(),
                            variant: ButtonVariant.primary,
                            isDarkMode: isDarkMode,
                            icon: Icons.add,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
      ],
    );
  }

  Widget _buildPublishTab(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.public,
            size: 60,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Connected platforms: ${_bot?.connectedPlatforms.length ?? 0}',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          Button(
            label: 'Basic Publishing',
            onPressed: () {
              if (_bot != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BotPublishScreen(
                      botId: _bot!.id,
                      botName: _bot!.name,
                    ),
                  ),
                ).then((_) => _fetchBotDetails());
              }
            },
            variant: ButtonVariant.primary,
            icon: Icons.share,
            isDarkMode: isDarkMode,
            fullWidth: false,
            width: 260,
          ),
          const SizedBox(height: 16),
          Button(
            label: 'Advanced Integrations',
            onPressed: () {
              if (_bot != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BotIntegrationScreen(
                      botId: _bot!.id,
                      botName: _bot!.name,
                    ),
                  ),
                ).then((_) => _fetchBotDetails());
              }
            },
            variant: ButtonVariant.ghost,
            icon: Icons.integration_instructions,
            isDarkMode: isDarkMode,
            fullWidth: false,
            width: 260,
          ),
        ],
      ),
    );
  }

  void _navigateToKnowledgeScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BotKnowledgeScreen(
          botId: _bot!.id,
          knowledgeBaseIds: _bot!.knowledgeBaseIds,
        ),
      ),
    ).then((_) => _fetchBotDetails());
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
