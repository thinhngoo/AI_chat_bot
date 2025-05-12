import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/ai_bot.dart';
import '../services/bot_service.dart';
import 'bot_detail_screen.dart';
import 'create_bot_screen.dart';
import 'bot_preview_screen.dart';
import 'bot_sharing_screen.dart';
import '../../../widgets/text_field.dart';
import '../../../widgets/information.dart';
import '../../../widgets/button.dart';
import '../../../widgets/dialog.dart';

class BotListScreen extends StatefulWidget {
  const BotListScreen({super.key});

  @override
  State<BotListScreen> createState() => _BotListScreenState();
}

class _BotListScreenState extends State<BotListScreen>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  final BotService _botService = BotService();

  bool _isLoading = true;
  String _errorMessage = '';
  List<AIBot> _bots = [];
  String _searchQuery = '';

  // Animation controller for refresh indicator
  late AnimationController _refreshIconController;

  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();

    // Initialize the animation controller properly
    _refreshIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // First try to fetch from cache (forceRefresh: false), then do a background refresh
    _initialFetch();
  }

  // Two-phase loading strategy: Quick load from cache, then refresh in background
  Future<void> _initialFetch() async {
    try {
      // Phase 1: Load from cache if available (fast)
      final cachedBots = await _botService.getBots(forceRefresh: false);

      if (mounted) {
        setState(() {
          _bots = cachedBots;
          // Keep _isLoading true for the background refresh
        });
      }

      // Phase 2: Then refresh from network in background (accurate)
      _fetchBots(forceRefresh: true);
    } catch (e) {
      _logger.e('Error in initial fetch: $e');
      // If cache fails, just do a normal fetch
      _fetchBots(forceRefresh: true);
    }
  }

  @override
  void dispose() {
    _refreshIconController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBots({bool forceRefresh = true}) async {
    try {
      setState(() {
        _errorMessage = '';
        _isLoading = true;
        _refreshIconController.repeat();
      });

      final bots = await _botService.getBots(forceRefresh: forceRefresh);

      if (mounted) {
        setState(() {
          _bots = bots;
          _isLoading = false;
          _refreshIconController.stop();
        });
      }
    } catch (e) {
      _logger.e('Error fetching bots: $e');

      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _refreshIconController.stop();
        });

        GlobalSnackBar.show(
          context: context,
          message: 'Error: ${e.toString()}',
          variant: SnackBarVariant.error,
        );
      }
    }
  }

  Future<void> _deleteBot(AIBot bot) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _botService.deleteBot(bot.id);

      if (mounted) {
        setState(() {
          _bots.removeWhere((b) => b.id == bot.id);
          _isLoading = false;
        });

        GlobalSnackBar.show(
          context: context,
          message: 'Bot "${bot.name}" deleted successfully',
          variant: SnackBarVariant.success,
          // Add undo action
          // actionLabel: 'Undo',
          // onActionPressed: () {
          //   // In a real app, you might want to restore the deleted bot
          //   _fetchBots();
          // },
        );
      }
    } catch (e) {
      _logger.e('Error deleting bot: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        GlobalSnackBar.show(
          context: context,
          message: 'Error deleting bot: ${e.toString()}',
          variant: SnackBarVariant.error,
        );
      }
    }
  }

  void _editBot(AIBot bot) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => BotDetailScreen(botId: bot.id),
          ),
        )
        .then((_) => _fetchBots());
  }

  void _createBot() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const CreateBotScreen(),
          ),
        )
        .then((_) => _fetchBots());
  }

  // Get filtered bots based on search query
  List<AIBot> get _filteredBots {
    if (_searchQuery.isEmpty) {
      return _bots;
    }
    return _bots.where((bot) {
      return bot.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          bot.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bot Management'),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
            ),
            onPressed: _isLoading ? null : _fetchBots,
            tooltip: 'Refresh',
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
              ),
              tooltip: 'Create new bot',
              onPressed: _createBot,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
            child: CommonTextField(
              controller: _searchController,
              label: 'Search',
              hintText: 'Search bots...',
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
              darkMode: isDarkMode,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Stats summary
          if (!_isLoading && _errorMessage.isEmpty && _bots.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(left: 26.0, right: 20.0, bottom: 8.0),
              child: Row(
                children: [
                  ResultsCountIndicator(
                    filteredCount: _filteredBots.length,
                    totalCount: _bots.length,
                    itemType: 'bots',
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.public,
                        size: 20,
                        color: Theme.of(context).hintColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_bots.where((bot) => bot.isPublished).length} published',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Main content
          Expanded(
            child: _isLoading
                ? InformationIndicator(
                    message: 'Loading...',
                    variant: InformationVariant.loading,
                  )
                : _errorMessage.isNotEmpty
                    ? InformationIndicator(
                        message: _errorMessage,
                        variant: InformationVariant.error,
                      )
                    : _bots.isEmpty
                        ? InformationIndicator(
                            message: 'No bots yet\nCreate one to get started',
                            variant: InformationVariant.info,
                          )
                        : _filteredBots.isEmpty
                            ? InformationIndicator(
                                message: 'No matching bots found',
                                variant: InformationVariant.info,
                              )
                            : RefreshIndicator(
                                onRefresh: _fetchBots,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16.0),
                                  itemCount: _filteredBots.length,
                                  itemBuilder: (context, index) {
                                    final bot = _filteredBots[index];

                                    return BotCard(
                                      bot: bot,
                                      onEdit: () => _editBot(bot),
                                      onDelete: () => _confirmDelete(bot),
                                      isDarkMode: isDarkMode,
                                    );
                                  },
                                ),
                              ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(AIBot bot) async {
    final confirmed = await GlobalDialog.show(
      context: context,
      title: 'Confirm Delete',
      message:
          'Are you sure you want to delete "${bot.name}"?\nThis action cannot be undone.',
      variant: DialogVariant.warning,
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
    );

    if (confirmed == true) {
      _deleteBot(bot);
    }
  }
}

// Separate card widget for cleaner code
class BotCard extends StatelessWidget {
  final AIBot bot;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDarkMode;

  const BotCard({
    super.key,
    required this.bot,
    required this.onEdit,
    required this.onDelete,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with icon and action buttons
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bot icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.smart_toy,
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

                const Spacer(),

                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Preview button
                    IconButton(
                      icon: Icon(Icons.visibility,
                          color: Theme.of(context).hintColor),
                      onPressed: () {
                        // Navigate to bot preview screen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BotPreviewScreen(
                              botId: bot.id,
                              botName: bot.name,
                            ),
                          ),
                        );
                      },
                      tooltip: 'Preview',
                      visualDensity: VisualDensity.compact,
                      iconSize: 24,
                    ),

                    const SizedBox(width: 4),

                    // Share button
                    IconButton(
                      icon: Icon(Icons.share_outlined,
                          color: Theme.of(context).hintColor),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BotSharingScreen(
                              botId: bot.id,
                              botName: bot.name,
                            ),
                          ),
                        );
                      },
                      tooltip: 'Share',
                      visualDensity: VisualDensity.compact,
                      iconSize: 24,
                    ),

                    const SizedBox(width: 4),

                    // Delete button
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error),
                      onPressed: onDelete,
                      tooltip: 'Delete',
                      visualDensity: VisualDensity.compact,
                      iconSize: 24,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Bot name displayed as a separate row for better visibility
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bot.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 1.0),
                  child: Text(
                    bot.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action buttons row at the bottom
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Button(
                    label: 'Edit',
                    icon: Icons.edit,
                    onPressed: onEdit,
                    variant: ButtonVariant.ghost,
                    size: ButtonSize.medium,
                    isDarkMode: isDarkMode,
                    fullWidth: true,
                    color: isDarkMode
                        ? Theme.of(context).colorScheme.onSurface.withAlpha(180)
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(160),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Button(
                    label: 'Chat',
                    icon: Icons.chat_bubble,
                    onPressed: () {
                      // Navigate to bot preview/chat screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BotPreviewScreen(
                            botId: bot.id,
                            botName: bot.name,
                          ),
                        ),
                      );
                    },
                    variant: ButtonVariant.primary,
                    size: ButtonSize.medium,
                    isDarkMode: isDarkMode,
                    fullWidth: true,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
