import 'package:flutter/material.dart';
import '../../../core/models/chat/message.dart';
import '../../../core/models/chat/chat_session.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/services/api/api_service.dart';
import '../../../core/services/chat/jarvis_chat_service.dart'; // Updated import
import '../../auth/presentation/login_page.dart';
import '../../account/presentation/account_management_page.dart';
import '../../support/presentation/help_feedback_page.dart';
import '../../settings/presentation/settings_page.dart';
import '../../../widgets/ai/model_selector_widget.dart';
import 'package:logger/logger.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  final JarvisChatService _chatService = JarvisChatService(); // Updated service
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();
  
  // Chat session management
  final List<ChatSession> _chatSessions = [];
  ChatSession? _currentSession;
  bool _isLoading = false;
  String? _currentUserId;
  bool _showedApiError = false;
  String _currentModel = 'gemini-2.0-flash';
  bool _isLoadingModel = false;
  
  // Use these fields consistently throughout the code
  bool _isTyping = false;
  bool _apiServiceAvailable = true;

  @override
  void initState() {
    super.initState();
    // Get current user ID
    _getCurrentUserId();
    // Load chat sessions from API
    _loadChatSessions();
    // Add this to load the user's selected model when the page initializes
    _loadUserModel();
  }

  // Get current user ID
  Future<void> _getCurrentUserId() async {
    final currentUser = _authService.currentUser;
    
    if (currentUser != null) {
      // Handle both UserModel and String types for currentUser
      if (currentUser is String) {
        setState(() {
          _currentUserId = currentUser;
        });
      } else {
        setState(() {
          _currentUserId = currentUser.uid;
        });
      }
    }
  }

  // Load chat sessions from API
  Future<void> _loadChatSessions() async {
    if (_currentUserId == null) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final sessions = await _chatService.getUserChatSessions();
<<<<<<< HEAD
      
      // Process sessions to prevent message duplication
      _processSessions(sessions);
=======
>>>>>>> 6353b9e (Chuyển từ firebase qua jarvis api (mới xong login register))
      
      setState(() {
        _chatSessions.clear();
        _chatSessions.addAll(sessions);
        _isLoading = false;
        
        // Select most recent session if available and none is selected
        if (_currentSession == null && _chatSessions.isNotEmpty) {
          _currentSession = _chatSessions.first;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (_isApiError(e)) {
          _apiServiceAvailable = false;
          if (!_showedApiError) {
            _showApiErrorDialog();
            _showedApiError = true;
          }
        }
      });
      _logger.e('Error loading chat sessions: $e');
<<<<<<< HEAD
    }
  }
  
  // Helper method to process sessions and prevent message duplication
  void _processSessions(List<ChatSession> sessions) {
    for (var session in sessions) {
      // Remove duplicate messages (messages with same text and timestamp)
      final uniqueMessages = <Message>[];
      final messageKeys = <String>{};
      
      for (var message in session.messages) {
        // Create a unique key for each message based on text, isUser flag and timestamp
        final messageKey = '${message.text}_${message.isUser}_${message.timestamp.millisecondsSinceEpoch}';
        
        if (!messageKeys.contains(messageKey)) {
          messageKeys.add(messageKey);
          uniqueMessages.add(message);
        } else {
          _logger.d('Filtered out duplicate message: ${message.text}');
        }
      }
      
      session.messages.clear();
      session.messages.addAll(uniqueMessages);
=======
>>>>>>> 6353b9e (Chuyển từ firebase qua jarvis api (mới xong login register))
    }
  }

  // Method to check for API errors
  bool _isApiError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Check for common API errors
    return errorString.contains('permission-denied') || 
           errorString.contains('unauthorized') ||
           errorString.contains('not found') ||
           errorString.contains('connection refused');
  }

  // Update dialog to show API error information
  void _showApiErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Connection Issues'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('Could not connect to the Jarvis API. This may be due to:'),
              SizedBox(height: 8),
              Text('• Invalid API credentials'),
              Text('• Network connectivity issues'),
              Text('• API server may be down or unavailable'),
              SizedBox(height: 16),
              Text('Please check your connection and API configuration in the .env file.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Method to fix BuildContext usage across async gap
  void _createNewChat() {
    final newChatTitle = 'New Chat';
    
    setState(() {
      _isLoading = true;
    });
    
    _chatService.createChatSession(newChatTitle).then((newSession) {
      if (!mounted) return;
      
      if (newSession != null) {
        setState(() {
          _chatSessions.insert(0, newSession);
          _currentSession = newSession;
          _isLoading = false;
        });
      }
    }).catchError((e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      _logger.e('Error creating new chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create new chat')),
      );
    });
  }

  void _selectChat(ChatSession session) {
    setState(() {
      _currentSession = session;
    });
  }

  void _deleteChat(ChatSession session) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              if (!mounted) return;
              
              setState(() {
                _isLoading = true;
              });
              
              try {
                final success = await _chatService.deleteChatSession(session.id);
                
                if (!mounted) return;
                
                if (success) {
                  setState(() {
                    _chatSessions.remove(session);
                    
                    // If we deleted the current session, select a new one
                    if (_currentSession == session) {
                      _currentSession = _chatSessions.isNotEmpty ? _chatSessions.first : null;
                    }
                    
                    _isLoading = false;
                  });
                } else {
                  throw 'Failed to delete chat';
                }
              } catch (e) {
                if (!mounted) return;
                
                setState(() {
                  _isLoading = false;
                });
                _logger.e('Error deleting chat: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete chat')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getChatTitle(ChatSession session) {
    // If it's still the default title, try to generate a better one from the first user message
    if (session.title == 'New Chat') {
      final userMessages = session.messages.where((msg) => msg.isUser);
      if (userMessages.isNotEmpty) {
        String firstMessage = userMessages.first.text;
        // Truncate and return a reasonable title
        return firstMessage.length > 25 
            ? '${firstMessage.substring(0, 25)}...' 
            : firstMessage;
      }
    }
    return session.title;
  }

  Future<void> _signOut() async {
    try {
      await AuthService().signOut();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng xuất thành công!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      _logger.e('Error signing out: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng xuất: ${e.toString()}')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    // Clear the text field immediately
    _messageController.clear();
    
    if (_currentSession == null) {
      _createNewChat();
    }
    
    // Add user message to the UI immediately
    final userMessage = Message(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _currentSession!.messages.add(userMessage);
      _isTyping = true;
    });
    
    // Scroll to the bottom after adding user message
    _scrollToBottom();
    
    try {
      // Send message to API and get response
      if (_currentSession != null) {
        // Add message to the session
        await _chatService.addMessage(_currentSession!.id, text);
        
        // Get the latest conversation history to update with the bot response
        final updatedMessages = await _chatService.getMessages(_currentSession!.id);
        
        if (mounted) {
          setState(() {
            // Replace the messages with the updated ones from the server
            _currentSession!.messages.clear();
            _currentSession!.messages.addAll(updatedMessages);
            _isTyping = false;
          });
          
          // Scroll to the bottom after adding bot response
          _scrollToBottom();
        }
      }
    } catch (e) {
      // If there's an error, provide a fallback response
      final errorMessage = Message(
        text: 'Sorry, I encountered an error processing your request. Please try again later.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      if (mounted) {
        setState(() {
          _currentSession!.messages.add(errorMessage);
          _isTyping = false;
        });
        
        _scrollToBottom();
      }
      
      _logger.e('Error sending message: $e');
    }
  }

  // Fix the issue with "void value can't be used" by removing conditional return
  void _handleClearChat() {
    if (_currentSession != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear Chat'),
          content: const Text('Are you sure you want to clear this chat history?'),
          actions: [
            TextButton(
              onPressed: () { 
                Navigator.pop(context); 
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _createNewChat();
              },
              child: const Text('Clear'),
            ),
          ],
        ),
      );
    }
  }

  // Load the user's selected model from API
  Future<void> _loadUserModel() async {
    try {
      setState(() {
        _isLoadingModel = true;
      });
      
      final currentUser = await _authService.currentUser;
      if (currentUser != null) {
        final selectedModel = await _chatService.getUserSelectedModel(_currentUserId ?? '');
        
        if (selectedModel != null && mounted) {
          setState(() {
            _currentModel = selectedModel;
            _apiService.setModel(selectedModel);
          });
        }
      }
    } catch (e) {
      _logger.e('Error loading user model: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingModel = false;
        });
      }
    }
  }
  
  // Update the user's selected model
  Future<void> _updateUserModel(String newModel) async {
    try {
      setState(() {
        _isLoadingModel = true;
      });
      
      if (_currentUserId != null) {
        final success = await _chatService.updateUserSelectedModel(_currentUserId!, newModel);
        
        if (success && mounted) {
          setState(() {
            _currentModel = newModel;
            _apiService.setModel(newModel);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI model updated successfully')),
          );
        }
      }
    } catch (e) {
      _logger.e('Error updating user model: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update AI model')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingModel = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat Bot'),
        actions: [
          // Add model selector widget
          if (_isLoadingModel)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            ModelSelectorWidget(
              currentModel: _currentModel,
              onModelChanged: _updateUserModel,
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset_permissions') {
                // Reset API error state
                setState(() {
                  _apiServiceAvailable = true;
                  _showedApiError = false;
                });
                _loadChatSessions();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API connection reset. Retrying operations...'))
                );
              } else if (value == 'clear') {
                // Clear chat
                _handleClearChat();
              } else if (value == 'settings') {
                // Navigate to settings
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Clear Chat'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'reset_permissions',
                child: ListTile(
                  leading: Icon(Icons.security_update_good),
                  title: Text('Reset API Connection'),
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.grey[850],
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.grey[900]),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'AI của Vinh',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Cuộc trò chuyện mới'),
                        onPressed: () {
                          _createNewChat();
                          Navigator.pop(context); // Close drawer
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _chatSessions.length,
                  itemBuilder: (context, index) {
                    final session = _chatSessions[index];
                    final isSelected = _currentSession?.id == session.id;
                    
                    return ListTile(
                      title: Text(
                        _getChatTitle(session),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      leading: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                      selected: isSelected,
                      selectedTileColor: Colors.blue.withAlpha(77), // Use withAlpha instead of withOpacity for better precision
                      onTap: () => _selectChat(session),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteChat(session),
                      ),
                    );
                  },
                ),
              ),
              const Divider(color: Colors.white30),
              ListTile(
                leading: const Icon(Icons.account_circle, color: Colors.white),
                title: const Text('Quản lý tài khoản', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const AccountManagementPage()
                  ));
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline, color: Colors.white),
                title: const Text('Trợ giúp & Phản hồi', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const HelpFeedbackPage()
                  ));
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.white),
                title: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
                onTap: _signOut,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.grey[850],
      body: !_apiServiceAvailable
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('API connection unavailable', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _apiServiceAvailable = true;
                        _showedApiError = false;
                      });
                      _loadChatSessions();
                    },
                    child: const Text('Retry connection'),
                  ),
                ],
              ),
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _currentSession == null
                  ? const Center(child: Text('Không có cuộc trò chuyện'))
                  : Column(
                      children: [
                        // Chat history area
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(10),
                            itemCount: _currentSession!.messages.length,
                            itemBuilder: (context, index) {
                              final message = _currentSession!.messages[index];
                              return Align(
                                alignment:
                                    message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 5),
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                  decoration: BoxDecoration(
                                    color: message.isUser
                                        ? Colors.blue[600] // User message: blue
                                        : Colors.grey[700], // AI message: gray
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: message.isUser
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message.text,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        // Show typing indicator
                        if (_isTyping)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            child: Row(
                              children: const [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('AI is typing...', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                          
                        // Message input area
                        Container(
                          color: Colors.grey[900],
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Nhập tin nhắn...',
                                    hintStyle: const TextStyle(color: Colors.white54),
                                    filled: true,
                                    fillColor: Colors.grey[800],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                onPressed: _sendMessage,
                                icon: Icon(Icons.send, color: Colors.blue[400]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}