import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/services/auth/auth_service.dart';
import '../services/chat_service.dart';
import '../models/conversation_message.dart';
import 'assistant_management_screen.dart';
import '../../auth/presentation/login_page.dart';

class ChatScreen extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;
  
  const ChatScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final Logger _logger = Logger();
  
  bool _isLoading = true;
  String _errorMessage = '';
  List<ConversationMessage> _messages = [];
  String? _currentConversationId;
  
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  
  String _selectedAssistantId = 'gpt-4o-mini';
  
  @override
  void initState() {
    super.initState();
    _fetchConversationHistory();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
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
            _errorMessage = 'No conversations found. Start a new conversation below!';
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
          ),
        );
      }
    }
  }
  
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    setState(() {
      _isSending = true;
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
      
      _logger.i('Sending message with conversation ID: $_currentConversationId');
      
      // Try with retry logic if first attempt fails
      Map<String, dynamic> response;
      try {
        response = await _chatService.sendMessage(
          content: message,
          assistantId: _selectedAssistantId,
          conversationId: _currentConversationId,
        );
      } catch (e) {
        // If error occurs and we have a conversation ID, try creating a new conversation
        if (_currentConversationId != null) {
          _logger.w('Error with existing conversation, trying to create new conversation');
          _currentConversationId = null;
          response = await _chatService.sendMessage(
            content: message,
            assistantId: _selectedAssistantId,
            conversationId: null,
          );
        } else {
          // No retry option, rethrow the error
          rethrow;
        }
      }
      
      // Update conversation ID when needed
      final String conversationId = response['conversationId'];
      if (_currentConversationId == null || _currentConversationId!.isEmpty) {
        _logger.i('New conversation started with ID: $conversationId');
        _currentConversationId = conversationId;
      } else {
        _logger.i('Continued conversation with ID: $conversationId');
      }
      
      setState(() {
        _messages[0] = ConversationMessage(
          query: message,
          answer: response['message'],
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          files: [],
        );
        _isSending = false;
      });
    } catch (e) {
      _logger.e('Error sending message: $e');
      
      String errorMessage = e.toString();
      
      // Check if the error might be related to conversation ID issues
      if (errorMessage.contains('500') || 
          errorMessage.contains('conversation') || 
          errorMessage.contains('context')) {
        // Reset conversation ID to force starting a new conversation next time
        _currentConversationId = null;
        errorMessage = 'Error with conversation. Starting a new chat on next message.';
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
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: _currentConversationId != null ? SnackBarAction(
              label: 'New Chat',
              onPressed: () {
                setState(() {
                  _currentConversationId = null;
                  _messages = [];
                });
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ) : null,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Chat Bot',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Assistant selector dropdown
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedAssistantId,
                isDense: true,
                icon: const Icon(Icons.arrow_drop_down),
                items: const [
                  DropdownMenuItem(
                    value: 'gpt-4o-mini',
                    child: Text('GPT-4o mini'),
                  ),
                  DropdownMenuItem(
                    value: 'gemini-1.5-flash-latest',
                    child: Text('Gemini 1.5 Flash'),
                  ),
                  DropdownMenuItem(
                    value: 'gpt-4o',
                    child: Text('GPT-4o'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedAssistantId = value;
                    });
                  }
                },
              ),
            ),
          ),
          
          // Manage assistants button
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AssistantManagementScreen(),
                ),
              ).then((_) {
                // Refresh data when returning from assistant management
                _fetchConversationHistory();
              });
            },
            icon: const Icon(Icons.smart_toy),
            tooltip: 'Manage Assistants',
          ),
          
          // Bot management button (NEW)
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/bots');
            },
            icon: const Icon(Icons.adb),
            tooltip: 'Manage Bots',
          ),
          
          // Prompt management button (NEW)
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PromptManagementScreen(),
                ),
              );
            },
            icon: const Icon(Icons.list),
            tooltip: 'Manage Prompts',
          ),
          
          // Light/dark mode toggle
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              semanticLabel: isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
            ),
            tooltip: isDarkMode ? 'Light mode' : 'Dark mode',
            onPressed: () => widget.toggleTheme(),
          ),
          
          // Settings/logout menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _authService.signOut().then((_) {
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  }
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Đăng xuất'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Empty conversation state or loading state
            if (_isLoading || (_errorMessage.isNotEmpty && _messages.isEmpty) || _messages.isEmpty)
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty && _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
                                  color: theme.colorScheme.primary.withAlpha(128),
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
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isUserMessage = message.query != null && message.query.isNotEmpty;
                    final messageDate = DateTime.fromMillisecondsSinceEpoch(message.createdAt * 1000);

                    return Column(
                      crossAxisAlignment:
                          isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUserMessage
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isUserMessage ? message.query : message.answer,
                            style: TextStyle(
                              color: isUserMessage
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          '${messageDate.hour}:${messageDate.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            
            // Message input area
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 5,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDarkMode 
                                ? Colors.grey[700]! 
                                : Colors.grey[300]!,
                          ),
                          color: isDarkMode 
                              ? Colors.grey[900] 
                              : Colors.grey[100],
                        ),
                        child: Semantics(
                          label: 'Message input field',
                          child: TextField(
                            controller: _messageController,
                            focusNode: _messageFocusNode,
                            maxLines: null,
                            minLines: 1,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              isDense: true,
                              hintStyle: TextStyle(
                                color: isDarkMode 
                                    ? Colors.grey[400] 
                                    : Colors.grey[600],
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      button: true,
                      enabled: !_isSending,
                      label: 'Send message',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary,
                        ),
                        child: IconButton(
                          icon: _isSending 
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.send, 
                                  color: theme.colorScheme.onPrimary,
                                ),
                          onPressed: _isSending ? null : _sendMessage,
                          tooltip: 'Send message',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Add a New Chat FAB
      floatingActionButton: _messages.isNotEmpty ? FloatingActionButton(
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
        tooltip: 'New chat',
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}

class PromptManagementScreen extends StatefulWidget {
  const PromptManagementScreen({Key? key}) : super(key: key);

  @override
  _PromptManagementScreenState createState() => _PromptManagementScreenState();
}

class _PromptManagementScreenState extends State<PromptManagementScreen> {
  final PromptService _promptService = PromptService();
  final Logger _logger = Logger();
  List<Map<String, dynamic>> _publicPrompts = [];
  List<Map<String, dynamic>> _privatePrompts = [];
  List<Map<String, dynamic>> _favoritePrompts = [];

  @override
  void initState() {
    super.initState();
    _fetchPrompts();
  }

  Future<void> _fetchPrompts() async {
    try {
      final publicPrompts = await _promptService.getPrompts(isPublic: true);
      final privatePrompts = await _promptService.getPrompts(isPublic: false);
      final favoritePrompts = await _promptService.getPrompts(isFavorite: true);
      setState(() {
        _publicPrompts = publicPrompts;
        _privatePrompts = privatePrompts;
        _favoritePrompts = favoritePrompts;
      });
    } catch (e) {
      _logger.e('Error fetching prompts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prompt Management'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Public Prompts'),
            subtitle: Text('Tap to view public prompts'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PromptListScreen(
                    key: UniqueKey(),
                    title: 'Public Prompts',
                    prompts: _publicPrompts,
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: Text('Private Prompts'),
            subtitle: Text('Tap to view private prompts'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PromptListScreen(
                    key: UniqueKey(),
                    title: 'Private Prompts',
                    prompts: _privatePrompts,
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: Text('Favorite Prompts'),
            subtitle: Text('Tap to view favorite prompts'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PromptListScreen(
                    key: UniqueKey(),
                    title: 'Favorite Prompts',
                    prompts: _favoritePrompts,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PromptListScreen extends StatelessWidget {
  PromptListScreen({Key? key, required this.title, required this.prompts}) : super(key: key);

  final String title;
  final List<Map<String, dynamic>> prompts;
  final Logger _logger = Logger();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView.builder(
        itemCount: prompts.length,
        itemBuilder: (context, index) {
          final prompt = prompts[index];
          return ListTile(
            title: Text(prompt['title'] ?? 'Untitled'),
            subtitle: Text(prompt['description'] ?? 'No description'),
            onTap: () {
              // Use the prompt content in chat
              _logger.i('Using prompt: ${prompt['content']}');
            },
          );
        },
      ),
    );
  }
}
