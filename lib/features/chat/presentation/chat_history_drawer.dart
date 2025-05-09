import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/information.dart'
    show
        SnackBarVariant,
        GlobalSnackBar,
        InformationVariant,
        InformationIndicator;
import '../../../widgets/text_field.dart';
import '../services/chat_service.dart';
import '../models/conversation_message.dart';

class ChatHistoryDrawer extends StatelessWidget {
  // ===== STATE VARIABLES =====
  final String selectedAssistantId;
  final String? currentConversationId;
  final Function() onNewChat;
  final Function(String) onConversationSelected;
  final Function(String) onDeleteConversation;
  final bool isDarkMode;

  const ChatHistoryDrawer({
    super.key,
    required this.selectedAssistantId,
    required this.currentConversationId,
    required this.onNewChat,
    required this.onConversationSelected,
    required this.onDeleteConversation,
    required this.isDarkMode,
  });

  /// Fetches conversation history from the server
  static Future<List<ConversationMessage>> fetchConversationHistory(
      String? conversationId, String assistantId,
      {required Logger logger}) async {
    try {
      logger.i('Fetching list of conversations');

      final chatService = ChatService();
      String? finalConversationId = conversationId;

      // If no conversationId provided, get the most recent conversation
      if (finalConversationId == null) {
        final conversations = await chatService.getConversations(
          assistantId: assistantId,
          limit: 20,
        );

        if (conversations.isEmpty) {
          logger.i('No conversations found');
          return [];
        }

        finalConversationId = conversations.first['id'];
        logger.i('Using most recent conversation ID: $finalConversationId');
      }

      if (finalConversationId == null) {
        throw Exception('Unable to determine conversation ID');
      }

      final response = await chatService.getConversationHistory(
        finalConversationId,
        assistantId: assistantId,
      );

      return response.items;
    } catch (e) {
      logger.e('Error fetching conversation history: $e');
      rethrow; // Re-throw to let caller handle it
    }
  }

  void _showDeleteConfirmation(BuildContext context, String conversationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content:
            const Text('Are you sure you want to delete this conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Delete conversation API call would go here
                // await ChatService().deleteConversation(conversationId);

                // For now, just refresh the UI
                if (conversationId == currentConversationId) {
                  onNewChat();
                }

                // Store context in variable to capture when button was pressed
                final BuildContext contextCaptured = context;

                GlobalSnackBar.show(
                  context: context,
                  message: 'Conversation deleted',
                  variant: SnackBarVariant.success,
                );

                // Check if widget is still in tree before navigating
                if (contextCaptured.mounted) {
                  // Close and reopen drawer to refresh
                  Navigator.pop(contextCaptured);
                  Scaffold.of(contextCaptured).openDrawer();
                }
              } catch (e) {
                GlobalSnackBar.show(
                  context: context,
                  message: 'Unable to delete: $e',
                  variant: SnackBarVariant.error,
                  duration: const Duration(seconds: 3),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final colors = isDarkMode ? AppColors.dark : AppColors.light;
    final double screenWidth = MediaQuery.of(context).size.width;
    final TextEditingController searchController = TextEditingController();
    
    return Drawer(
      width: screenWidth, // Make drawer use the full screen width
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero), // Remove default rounded corners
      child: Column(
        children: [
          Container(
            height: 56 +
                MediaQuery.of(context)
                    .padding
                    .top, // Account for status bar height
            padding: EdgeInsets.only(
              top: MediaQuery.of(context)
                  .padding
                  .top, // Safe area padding for status bar
              left: 8,
              right: 8,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colors.border,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Title
                const SizedBox(width: 40),
                const Spacer(),
                Text('Chat History', style: theme.textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.keyboard_double_arrow_right, size: 32),
                  color: colors.foreground.withAlpha(204),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomTextField(
              controller: searchController,
              label: 'Search',
              hintText: 'Search conversations',
              prefixIcon: Icons.search,
              darkMode: isDarkMode,
              onChanged: (value) {
                // This listener will be used by ChatHistoryList
              },
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ChatHistoryList(
              selectedAssistantId: selectedAssistantId,
              currentConversationId: currentConversationId,
              onConversationSelected: onConversationSelected,
              onDeleteConversation: (conversationId) {
                _showDeleteConfirmation(context, conversationId);
              },
              isDarkMode: isDarkMode,
              searchController: searchController,
            ),
          ),
        ],
      ),
    );
  }
}

/// Optimized widget to display chat history with caching support
class ChatHistoryList extends StatefulWidget {
  final String selectedAssistantId;
  final String? currentConversationId;
  final bool isDarkMode;
  final Function(String) onConversationSelected;
  final Function(String) onDeleteConversation;
  final TextEditingController searchController;

  const ChatHistoryList({
    super.key,
    required this.selectedAssistantId,
    required this.currentConversationId,
    required this.onConversationSelected,
    required this.onDeleteConversation,
    required this.isDarkMode,
    required this.searchController,
  });

  @override
  State<ChatHistoryList> createState() => _ChatHistoryListState();
}

class _ChatHistoryListState extends State<ChatHistoryList> {
  final Logger _logger = Logger();
  final ChatService _chatService = ChatService();

  // Local cache for faster UI rendering
  List<Map<String, dynamic>>? _conversations;
  List<Map<String, dynamic>>? _filteredConversations;
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load conversations immediately when the widget is created
    _loadConversations();
    
    // Add listener to the search controller
    widget.searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    // Remove listener when widget is disposed
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = widget.searchController.text.toLowerCase();
      _filterConversations();
    });
  }

  void _filterConversations() {
    if (_conversations == null) return;
    
    if (_searchQuery.isEmpty) {
      _filteredConversations = _conversations;
    } else {
      _filteredConversations = _conversations!.where((conversation) {
        final title = _getConversationTitle(conversation).toLowerCase();
        final firstMessage = (conversation['first_message'] as String? ?? '').toLowerCase();
        
        return title.contains(_searchQuery) || firstMessage.contains(_searchQuery);
      }).toList();
    }
  }

  @override
  void didUpdateWidget(ChatHistoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if the selected assistant changes
    if (oldWidget.selectedAssistantId != widget.selectedAssistantId) {
      _loadConversations();
    }
    
    // Update listener if the controller changed
    if (oldWidget.searchController != widget.searchController) {
      oldWidget.searchController.removeListener(_onSearchChanged);
      widget.searchController.addListener(_onSearchChanged);
    }
  }

  // Load conversations with optimized approach using cache
  Future<void> _loadConversations() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Use the cached data if available
      final conversations = await _chatService.getConversations(
        assistantId: widget.selectedAssistantId,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _conversations = conversations;
          _filterConversations();
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.e('Error loading conversations: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getConversationTitle(dynamic conversation) {
    final title = conversation['title'] as String?;
    if (title != null && title.isNotEmpty) {
      return title.length > 30 ? '${title.substring(0, 27)}...' : title;
    }

    // Use first_message as fallback if available
    final firstMessage = conversation['first_message'] as String? ?? '';
    if (firstMessage.isNotEmpty) {
      return firstMessage.length > 30
          ? '${firstMessage.substring(0, 27)}...'
          : firstMessage;
    }

    // Use created date as fallback
    final createdAtStr = conversation['createdAt'] as String?;
    if (createdAtStr != null) {
      try {
        final date = DateTime.parse(createdAtStr);
        return 'Chat on ${date.day}/${date.month}/${date.year}';
      } catch (e) {
        // Ignore parsing errors
      }
    }

    return 'Untitled Conversation';
  }

  String _getConversationTimestamp(dynamic conversation) {
    final createdAtStr = conversation['createdAt'] as String?;
    if (createdAtStr == null) return '';

    try {
      final date = DateTime.parse(createdAtStr);
      final now = DateTime.now();

      // Get month abbreviation
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final monthAbbr = months[date.month - 1];

      // Get day of week
      final days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      final dayName = days[date.weekday - 1];

      // If today, show "Today"
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return 'Today';
      }

      // If yesterday, show "Yesterday"
      final yesterday = now.subtract(const Duration(days: 1));
      if (date.year == yesterday.year &&
          date.month == yesterday.month &&
          date.day == yesterday.day) {
        return 'Yesterday';
      }

      // If within last 7 days, show day name (e.g., "Tuesday")
      if (now.difference(date).inDays < 7) {
        return dayName;
      }

      // Otherwise show "Apr 29" format
      return '$monthAbbr ${date.day}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colors = isDarkMode ? AppColors.dark : AppColors.light;

    if (_isLoading) {
      return InformationIndicator(
        message: 'Loading conversations...',
        variant: InformationVariant.loading,
      );
    }

    if (_errorMessage != null) {
      return InformationIndicator(
        message: _errorMessage!,
        variant: InformationVariant.error,
        buttonText: 'Retry',
        onButtonPressed: _loadConversations,
      );
    }

    if (_conversations == null || _conversations!.isEmpty) {
      return InformationIndicator(
        message: 'No conversations found',
        variant: InformationVariant.info,
      );
    }
    
    if (_filteredConversations != null && _filteredConversations!.isEmpty && _searchQuery.isNotEmpty) {
      return InformationIndicator(
        message: 'No conversations matching "$_searchQuery"',
        variant: InformationVariant.info,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Clear the cache to force a fresh load
        _chatService.clearCache();
        await _loadConversations();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filteredConversations?.length ?? 0,
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 32.0),
        itemBuilder: (context, index) {
          final conversation = _filteredConversations![index];
          final conversationId = conversation['id'] as String;
          final title = _getConversationTitle(conversation);
          final timestamp = _getConversationTimestamp(conversation);
          final isActive = conversationId == widget.currentConversationId;

          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 16, right: 0),
            tileColor: isActive ? colors.accent : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isActive ? 8 : 0),
              side: isActive
                  ? BorderSide(
                      color: colors.accentForeground.withAlpha(30),
                      width: 1,
                    )
                  : BorderSide.none,
            ),
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isActive ? colors.accentForeground : colors.foreground,
              ),
            ),
            subtitle: Text(
              timestamp,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.muted,
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: colors.muted),
              onPressed: () {
                widget.onDeleteConversation(conversationId);
              },
              padding: EdgeInsets.zero,
            ),
            onTap: () => widget.onConversationSelected(conversationId),
          );
        },
      ),
    );
  }
}
