import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../widgets/typing_indicator.dart';
import '../services/chat_service.dart';
import '../models/conversation_message.dart';
import '../../../features/prompt/presentation/prompt_selector.dart';
import '../../../features/prompt/presentation/prompt_management_screen.dart';
import '../../../features/prompt/services/prompt_service.dart'
    as prompt_service;
import '../../../features/subscription/widgets/ad_banner_widget.dart';
import '../../../features/subscription/services/ad_manager.dart';
import '../../../features/subscription/services/subscription_service.dart';
import 'assistant_management_screen.dart';
import '../../../core/constants/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final Function toggleTheme;

  const ChatScreen({
    super.key,
    required this.toggleTheme,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final prompt_service.PromptService _promptService =
      prompt_service.PromptService();
  final SubscriptionService _subscriptionService = SubscriptionService(
    AuthService(),
    Logger(),
  );
  final AdManager _adManager = AdManager();
  final Logger _logger = Logger();

  bool _isLoading = true;
  bool _isPro = false;
  String _errorMessage = '';
  List<ConversationMessage> _messages = [];
  String? _currentConversationId;

  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _isTyping = false;

  // Animation controllers
  late AnimationController _sendButtonController;

  String _selectedAssistantId = 'gpt-4o';

  // Prompt selector state
  bool _showPromptSelector = false;
  String _promptQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchConversationHistory();
    _checkSubscriptionStatus();

    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Listen for changes in the message text to detect slash commands
    _messageController.addListener(_handleMessageChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleMessageChanged);
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  // Handle message text changes to detect slash commands
  void _handleMessageChanged() {
    final text = _messageController.text;

    // Check if text starts with a slash
    if (text.startsWith('/')) {
      if (!_showPromptSelector) {
        setState(() {
          _showPromptSelector = true;
          _promptQuery = text;
        });
      } else {
        setState(() {
          _promptQuery = text;
        });
      }
    } else {
      if (_showPromptSelector) {
        setState(() {
          _showPromptSelector = false;
        });
      }
    }
  }

  // Handle selection of a prompt from the prompt selector
  void _handlePromptSelected(String content) {
    setState(() {
      _messageController.text = content;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: content.length),
      );
      _showPromptSelector = false;
    });

    // Focus on the text field
    _messageFocusNode.requestFocus();
  }

  Future<void> _fetchConversationHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      _logger.i('Fetching list of conversations');

      try {
        final conversations = await _chatService.getConversations(
          assistantId: _selectedAssistantId,
          limit: 20,
        );

        if (conversations.isEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'No conversations found. Start a new conversation below!';
            _currentConversationId = null;
          });
          return;
        }

        final conversationId = conversations.first['id'];
        _currentConversationId = conversationId;
        _logger.i('Using conversation ID: $conversationId');

        final response = await _chatService.getConversationHistory(
          conversationId,
          assistantId: _selectedAssistantId,
        );

        if (mounted) {
          setState(() {
            _messages = response.items;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });

          _logger.e('Error fetching conversations: $e');
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });

        _logger.e('Error in _fetchConversationHistory: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load conversations: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: _currentConversationId != null
                ? SnackBarAction(
                    label: 'New Chat',
                    onPressed: () {
                      setState(() {
                        _currentConversationId = null;
                        _messages = [];
                      });
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  )
                : null,
          ),
        );
      }
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      final subscription = await _subscriptionService.getCurrentSubscription();
      setState(() {
        _isPro = subscription.isPro;
      });
    } catch (e) {
      _logger.e('Error checking subscription status: $e');
      setState(() {
        _isPro = false; // Default to free user if error
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isSending = true;
      _isTyping = true;
      _sendButtonController.forward();
    });

    try {
      _messageController.clear();

      final userMessage = ConversationMessage(
        query: message,
        answer: 'Thinking...',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        files: [],
      );

      setState(() {
        _messages = [userMessage, ..._messages];
      });

      // Auto-scroll to top when a new message is added
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      _logger
          .i('Sending message with conversation ID: $_currentConversationId');

      // Try with retry logic if first attempt fails
      Map<String, dynamic> response;
      try {
        response = await _chatService.sendMessage(
          content: message,
          assistantId: _selectedAssistantId,
          conversationId: _currentConversationId,
        );

        if (mounted) {
          setState(() {
            if (response.containsKey('answers') &&
                response['answers'] is List &&
                (response['answers'] as List).isNotEmpty) {
              final answer = (response['answers'] as List<dynamic>).first;
              final conversationId =
                  response['conversation_id'] ?? _currentConversationId;

              _currentConversationId ??= conversationId;

              if (_messages.isNotEmpty) {
                _messages[0] = ConversationMessage(
                  query: message,
                  answer: answer,
                  createdAt: _messages[0].createdAt,
                  files: [],
                );
              }
            }
            _isSending = false;
            _isTyping = false;
            _sendButtonController.reverse();
          });

          // Show an ad occasionally for free users
          if (!_isPro) {
            _adManager.maybeShowInterstitialAd(context);
          }
        }
      } catch (e) {
        _logger.e('Error sending message (first attempt): $e');

        // If the message fails, try to create a new conversation
        if (_currentConversationId != null) {
          try {
            _currentConversationId = null;
            response = await _chatService.sendMessage(
              content: message,
              assistantId: _selectedAssistantId,
              conversationId: null, // Force creating a new conversation
            );

            setState(() {
              if (response.containsKey('answers') &&
                  response['answers'] is List &&
                  (response['answers'] as List).isNotEmpty) {
                final answer = (response['answers'] as List<dynamic>).first;
                final conversationId = response['conversation_id'];
                _currentConversationId = conversationId;

                if (_messages.isNotEmpty) {
                  _messages[0] = ConversationMessage(
                    query: message,
                    answer: answer,
                    createdAt: _messages[0].createdAt,
                    files: [],
                  );
                }
              }
              _isSending = false;
              _isTyping = false;
              _sendButtonController.reverse();
            });
          } catch (e2) {
            _logger.e('Error sending message (retry attempt): $e2');

            if (mounted) {
              setState(() {
                if (_messages.isNotEmpty) {
                  _messages[0] = ConversationMessage(
                    query: message,
                    answer: 'Error: ${e2.toString()}',
                    createdAt: _messages[0].createdAt,
                    files: [],
                  );
                }
                _isSending = false;
                _isTyping = false;
                _sendButtonController.reverse();
              });
            }
          }
        }
      }
    } catch (e) {
      _logger.e('Error sending message: $e');

      String errorMessage = e.toString();

      // Check if the error might be related to conversation ID issues
      if (errorMessage.contains('500') ||
          errorMessage.contains('conversation') ||
          errorMessage.contains('context')) {
        // Reset conversation ID to force starting a new conversation next time
        _currentConversationId = null;
        errorMessage =
            'Error with conversation. Starting a new chat on next message.';
        _logger.i('Reset conversation ID due to error');
      }

      setState(() {
        if (_messages.isNotEmpty) {
          _messages[0] = ConversationMessage(
            query: message,
            answer: 'Error: $errorMessage',
            createdAt: _messages[0].createdAt,
            files: [],
          );
        }
        _isSending = false;
        _isTyping = false;
        _sendButtonController.reverse();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: _currentConversationId != null
                ? SnackBarAction(
                    label: 'New Chat',
                    onPressed: () {
                      setState(() {
                        _currentConversationId = null;
                        _messages = [];
                      });
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  )
                : null,
          ),
        );
      }
    }
  }

  Widget _buildChatHistoryDrawer(ThemeData theme, bool isDarkMode) {
    return Drawer(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lịch sử chat',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // New chat button
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentConversationId = null;
                        _messages = [];
                      });
                      Navigator.pop(context); // Close the drawer
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã bắt đầu cuộc trò chuyện mới'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Chat mới'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDarkMode ? Colors.teal.shade700 : Colors.white,
                      foregroundColor:
                          isDarkMode ? Colors.white : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _chatService.getConversations(
                assistantId: _selectedAssistantId,
                limit: 20,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading chat history: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }

                final conversations = snapshot.data ?? [];

                if (conversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: theme.colorScheme.onSurface.withAlpha(102),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có cuộc trò chuyện nào',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withAlpha(153),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    final conversationId = conversation['id'];
                    final title = _getConversationTitle(conversation);
                    final timestamp = _getConversationTimestamp(conversation);
                    final isActive = conversationId == _currentConversationId;

                    return ListTile(
                      title: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        timestamp,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withAlpha(51),
                        child: Icon(
                          Icons.chat,
                          color: isActive
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.primary,
                          size: 18,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          // Delete conversation
                          _showDeleteConfirmation(context, conversationId);
                        },
                      ),
                      onTap: () {
                        // Load the conversation
                        _loadConversation(conversationId);
                        Navigator.pop(context); // Close the drawer
                      },
                      tileColor: isActive
                          ? (isDarkMode
                              ? Colors.teal.shade900.withAlpha(51)
                              : Colors.teal.shade50)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isActive ? 8 : 0),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getConversationTitle(dynamic conversation) {
    // Extract first message as title or use default
    final firstMessage = conversation['first_message'] as String? ?? '';
    if (firstMessage.isNotEmpty) {
      return firstMessage.length > 30
          ? '${firstMessage.substring(0, 27)}...'
          : firstMessage;
    }

    // Use created date as fallback
    final createdAt = conversation['created_at'] ?? 0;
    final date = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return 'Conversation on ${date.day}/${date.month}/${date.year}';
  }

  String _getConversationTimestamp(dynamic conversation) {
    final createdAt = conversation['created_at'] ?? 0;
    final date = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    final now = DateTime.now();

    // If today, show time
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }

    // If this year, show month and day
    if (date.year == now.year) {
      return '${date.day}/${date.month}';
    }

    // Show full date
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteConfirmation(BuildContext context, String conversationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa cuộc trò chuyện'),
        content:
            const Text('Bạn có chắc chắn muốn xóa cuộc trò chuyện này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Delete conversation API call would go here
                // await _chatService.deleteConversation(conversationId);

                // For now, just refresh the UI
                if (conversationId == _currentConversationId) {
                  setState(() {
                    _currentConversationId = null;
                    _messages = [];
                  });
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa cuộc trò chuyện')),
                );

                // Close and reopen drawer to refresh
                Navigator.pop(context);
                Scaffold.of(context).openDrawer();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Không thể xóa: $e')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadConversation(String conversationId) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await _chatService.getConversationHistory(
        conversationId,
        assistantId: _selectedAssistantId,
      );

      if (mounted) {
        setState(() {
          _currentConversationId = conversationId;
          _messages = response.items;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.e('Error loading conversation: $e');

      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load conversation: $e';
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final colors = isDarkMode ? AppColors.dark : AppColors.light;

    return Scaffold(
      drawer: _buildChatHistoryDrawer(theme, isDarkMode),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Chat History',
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ),
        title: AssistantSelector(
          selectedAssistantId: _selectedAssistantId,
          onSelect: (id) {
            setState(() {
              _selectedAssistantId = id;
            });
          },
        ),
        centerTitle: true,
        actions: [
          // Light/dark mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                semanticLabel:
                    isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
              ),
              tooltip: isDarkMode ? 'Light mode' : 'Dark mode',
              onPressed: () => widget.toggleTheme(),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Show ad banner for free users
            if (!_isPro) const AdBannerWidget(),

            // Empty conversation state or loading state
            if (_isLoading ||
                (_errorMessage.isNotEmpty && _messages.isEmpty) ||
                _messages.isEmpty)
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'Loading conversations...',
                              style: TextStyle(
                                color:
                                    theme.colorScheme.onSurface.withAlpha(179),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _errorMessage.isNotEmpty && _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32.0),
                                  child: Text(
                                    _errorMessage,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _fetchConversationHistory,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color:
                                      theme.colorScheme.primary.withAlpha(128),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Send a message to start chatting!',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
              ),

            // Chat messages
            if (!_isLoading && _errorMessage.isEmpty && _messages.isNotEmpty)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF121212)
                        : const Color(0xFFF5F5F5),
                    backgroundBlendMode: BlendMode.multiply,
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUserMessage =
                          message.query != null && message.query.isNotEmpty;
                      final messageText =
                          isUserMessage ? message.query : message.answer;
                      final messageDate = DateTime.fromMillisecondsSinceEpoch(
                          message.createdAt * 1000);
                      final isLastMessage = index == _messages.length - 1;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: isUserMessage
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: isUserMessage
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isUserMessage) ...[
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: theme.colorScheme.primary,
                                    child: Text(
                                      'AI',
                                      style: TextStyle(
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isUserMessage
                                          ? theme.colorScheme.primary
                                          : isDarkMode
                                              ? const Color(0xFF2D2D2D)
                                              : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(20),
                                        topRight: const Radius.circular(20),
                                        bottomLeft: isUserMessage
                                            ? const Radius.circular(20)
                                            : const Radius.circular(4),
                                        bottomRight: isUserMessage
                                            ? const Radius.circular(4)
                                            : const Radius.circular(20),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(13),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: SelectableText(
                                      messageText,
                                      style: TextStyle(
                                        color: isUserMessage
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurface,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                                if (isUserMessage) ...[
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: isDarkMode
                                        ? Colors.grey[700]
                                        : Colors.grey[300],
                                    child: const Icon(
                                      Icons.person,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.only(
                                left: isUserMessage ? 0 : 40,
                                right: isUserMessage ? 40 : 0,
                                top: 4,
                              ),
                              child: Text(
                                '${messageDate.hour}:${messageDate.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(153),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Show typing indicator when AI is thinking
            if (_isTyping)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                  child: TypingIndicator(isTyping: _isTyping),
                ),
              ),

            // Prompt selector
            PromptSelector(
              onPromptSelected: _handlePromptSelected,
              isVisible: _showPromptSelector,
              query: _promptQuery,
            ),

            // Message input area
            Container(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
              margin:
                  const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: colors.input,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.border,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 5,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                child: Column(
                  children: [
                    // Message text field row
                    TextField(
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      maxLines: null,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        fillColor: colors.input,
                        filled: true,
                        hintText: 'Type a message or / for prompts...',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        isDense: true,
                        hintStyle: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      onChanged: (text) {
                        setState(() {
                          // This forces the send button to update
                        });
                      },
                    ),

                    // Buttons row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Voice input button
                            IconButton(
                              icon: Icon(
                                Icons.mic_none,
                                color: colors.muted,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Voice input coming soon')),
                                );
                              },
                            ),

                            // Image upload button
                            IconButton(
                              icon: Icon(
                                Icons.image_outlined,
                                color: colors.muted,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Image upload coming soon')),
                                );
                              },
                            ),
                          ],
                        ),

                        // Send button
                        AnimatedBuilder(
                          animation: _sendButtonController,
                          builder: (context, child) {
                            final bool showLoading =
                                _sendButtonController.status ==
                                        AnimationStatus.forward ||
                                    _sendButtonController.status ==
                                        AnimationStatus.completed;

                            return Material(
                              color: _messageController.text.isNotEmpty
                                  ? colors.inputForeground
                                  : colors.muted.withAlpha(30),
                              borderRadius: BorderRadius.circular(24),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: (_messageController.text
                                            .trim()
                                            .isNotEmpty &&
                                        !_isSending)
                                    ? _sendMessage
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: showLoading
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              colors.muted,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.arrow_upward,
                                          color: _messageController.text
                                                  .trim()
                                                  .isEmpty
                                              ? colors.muted.withAlpha(128)
                                              : colors.input,
                                          size: 24,
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _messages.isNotEmpty
          ? Container(
              margin: const EdgeInsets.only(bottom: 70),
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _currentConversationId = null;
                    _messages = [];
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Started a new conversation'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                mini: true,
                tooltip: 'New chat',
                child: const Icon(Icons.add),
              ),
            )
          : null,
    );
  }
}

class AssistantSelector extends StatefulWidget {
  final String selectedAssistantId;
  final ValueChanged<String> onSelect;

  const AssistantSelector({
    super.key,
    required this.selectedAssistantId,
    required this.onSelect,
  });

  @override
  State<AssistantSelector> createState() => _AssistantSelectorState();
}

class Assistant {
  final String id;
  final String name;
  final String description;

  const Assistant({
    required this.id,
    required this.name,
    required this.description,
  });
}

class _AssistantSelectorState extends State<AssistantSelector> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final assistants = [
    Assistant(
        id: 'gpt-4.1',
        name: 'GPT 4o',
        description: 'Maximum intelligence and context'),
    Assistant(
        id: 'gpt-4o',
        name: 'GPT 4o',
        description: 'Faster, but less than GPT-4.1'),
    Assistant(
        id: 'o4-mini', name: 'GPT 4o mini', description: 'Small and fast'),
    Assistant(
        id: 'grok-3',
        name: 'Grok 3',
        description: 'Maximum intelligence and context'),
    Assistant(
        id: 'grok-2',
        name: 'Grok 2',
        description: 'Faster, but less than Grok 3'),
  ];

  void _showMenu() {
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _buildOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _hideMenu,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height + 6,
              width: 280,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(-(270 - size.width) / 2, size.height + 6),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: isDarkMode
                          ? Border.all(color: theme.dividerColor.withAlpha(120))
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(18),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var assistant in assistants)
                          _buildMenuOption(
                            id: assistant.id,
                            title: assistant.name,
                            subtitle: assistant.description,
                            selected:
                                widget.selectedAssistantId == assistant.id,
                            onTap: () {
                              widget.onSelect(assistant.id);
                              _hideMenu();
                            },
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
    );
  }

  Widget _buildMenuOption({
    required String id,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final color = isDarkMode ? AppColors.dark : AppColors.light;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: selected
            ? theme.colorScheme.primary.withAlpha(10)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: selected ? theme.colorScheme.primary : color.muted,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      color: selected
                          ? theme.colorScheme.primary.withAlpha(200)
                          : color.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check, color: theme.colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String title = assistants
        .firstWhere((element) => element.id == widget.selectedAssistantId)
        .name;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          if (_overlayEntry == null) {
            _showMenu();
          } else {
            _hideMenu();
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
