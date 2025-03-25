import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/chat/message.dart';
import '../../../core/models/chat/chat_session.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/services/api/api_service.dart';
import '../../../core/services/firestore/firestore_data_service.dart';
import '../../auth/presentation/login_page.dart';
import '../../account/presentation/account_management_page.dart';
import '../../support/presentation/help_feedback_page.dart';
import '../../settings/presentation/settings_page.dart'; // Add this import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  final FirestoreDataService _firestoreService = FirestoreDataService(); // Add Firestore service
  final AuthService _authService = AuthService();
  
  // Chat session management
  final List<ChatSession> _chatSessions = [];
  ChatSession? _currentSession;
  bool _isTyping = false;
  bool _isLoading = false; // This field is now properly used in _loadChatSessions
  final _uuid = Uuid();
  String? _currentUserId;
  bool _firestoreAvailable = true; // Track if Firestore is working properly
  bool _showedFirestoreError = false; // Track if we've already shown the error

  @override
  void initState() {
    super.initState();
    // Get current user ID
    _getCurrentUserId();
    // Load chat sessions from Firestore
    _loadChatSessions();
  }

  // Get current user ID
  Future<void> _getCurrentUserId() async {
    final currentUser = _authService.currentUser;
    
    if (currentUser != null) {
      _currentUserId = currentUser is String ? currentUser : currentUser.uid;
    }
  }

  // Load chat sessions from Firestore
  Future<void> _loadChatSessions() async {
    if (_currentUserId == null) {
      await _getCurrentUserId();
      if (_currentUserId == null) {
        // Still no user ID, create a new chat
        _createNewChat();
        return;
      }
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final sessions = await _firestoreService.getUserChatSessions(_currentUserId!);
      
      setState(() {
        _chatSessions.clear();
        _chatSessions.addAll(sessions);
        _firestoreAvailable = true; // Reset flag if successful
        
        if (_chatSessions.isNotEmpty) {
          _currentSession = _chatSessions.first;
        } else {
          // No saved sessions, create a new one
          _createNewChat();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Create a new chat even if loading fails
        if (_chatSessions.isEmpty) {
          _createNewChat();
        }
        
        // Check for Firestore permission errors
        if (_isFirestorePermissionError(e) && !_showedFirestoreError) {
          _firestoreAvailable = false;
          // Show error dialog after frame is rendered
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showFirestorePermissionErrorDialog();
            _showedFirestoreError = true;
          });
        }
      });
    }
  }

  // Method to check for Firestore errors
  bool _isFirestorePermissionError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Check for permission denied errors
    final isPermissionError = errorString.contains('permission-denied') || 
           errorString.contains('permission denied') ||
           (error is FirebaseException && error.code == 'permission-denied');
           
    // Also check for index-related errors
    final isIndexError = errorString.contains('failed-precondition') && 
           errorString.contains('requires an index') ||
           (error is FirebaseException && error.code == 'failed-precondition' && 
            error.message?.contains('index') == true);
    
    return isPermissionError || isIndexError;
  }

  // Update dialog to include information about both errors
  void _showFirestorePermissionErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firebase Configuration Issues'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your app is experiencing Firebase configuration issues. '
                'Your chats will work locally but won\'t be saved to the cloud until this is fixed.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Security Rules Issue:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Go to Firebase Console'),
              const Text('• Open Firestore Database'),
              const Text('• Go to "Rules" tab'),
              const Text('• Replace rules with:'),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'rules_version = \'2\';\n'
                  'service cloud.firestore {\n'
                  '  match /databases/{database}/documents {\n'
                  '    match /chatSessions/{sessionId} {\n'
                  '      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;\n'
                  '      \n'
                  '      match /messages/{messageId} {\n'
                  '        allow read, write: if request.auth != null;\n'
                  '      }\n'
                  '    }\n'
                  '    match /users/{userId} {\n'
                  '      allow read, write: if request.auth != null && request.auth.uid == userId;\n'
                  '    }\n'
                  '  }\n'
                  '}'
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '2. Missing Index Issue:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Go to Firebase Console'),
              const Text('• Open Firestore Database'),
              const Text('• Go to "Indexes" tab'),
              const Text('• Create a composite index:'),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Collection: chatSessions\n'
                  'Fields to index:\n'
                  '- userId (Ascending)\n'
                  '- lastUpdatedAt (Descending)'
                ),
              ),
              const Text('• Click on the direct link in the error message console'),
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

  void _createNewChat() {
    final newSession = ChatSession(
      id: _uuid.v4(),
      title: 'New Chat',
      messages: [
        Message(
          text: 'Xin chào! Tôi là AI của Vinh. Bạn khỏe không?',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
    );
    
    setState(() {
      _chatSessions.add(newSession);
      _currentSession = newSession;
      _apiService.clearConversationHistory(); // Reset API conversation context
    });
    
    // Save the new session to Firestore
    if (_currentUserId != null && _firestoreAvailable) {
      _firestoreService.saveChatSession(newSession, _currentUserId!)
          .catchError((e) {
        if (_isFirestorePermissionError(e) && !_showedFirestoreError) {
          setState(() {
            _firestoreAvailable = false;
          });
          _showFirestorePermissionErrorDialog();
          _showedFirestoreError = true;
        }
        return null; // Add return value for catchError
      });
    }
  }

  void _selectChat(ChatSession session) {
    if (_currentSession?.id != session.id) {
      setState(() {
        _currentSession = session;
        _apiService.clearConversationHistory(); // Reset API conversation context
      });
      Navigator.pop(context); // Close drawer
    }
  }

  void _deleteChat(ChatSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa cuộc trò chuyện'),
        content: const Text('Bạn có chắc muốn xóa cuộc trò chuyện này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _chatSessions.remove(session);
                if (_currentSession?.id == session.id) {
                  _currentSession = _chatSessions.isNotEmpty ? _chatSessions.last : null;
                  
                  // If we removed all chats, create a new one
                  if (_currentSession == null) {
                    _createNewChat();
                  }
                }
              });
            },
            child: const Text('Xóa'),
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
    await AuthService().signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đăng xuất thành công!')),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
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
    if (_messageController.text.isEmpty) return;
    if (_isTyping) return; // Prevent sending multiple messages while waiting
    if (_currentSession == null) return;
    
    final userMessage = _messageController.text;
    setState(() {
      _currentSession!.messages.add(Message(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isTyping = true;
    });
    
    _scrollToBottom();
    
    // Save user message to Firestore if we have a user ID
    if (_currentUserId != null && _firestoreAvailable) {
      _firestoreService.addMessageToSession(
        _currentSession!.id, 
        _currentSession!.messages.last, 
        _currentUserId!
      ).catchError((e) {
        if (_isFirestorePermissionError(e) && !_showedFirestoreError) {
          setState(() {
            _firestoreAvailable = false;
          });
          _showFirestorePermissionErrorDialog();
          _showedFirestoreError = true;
        }
        return false; // Add return value for catchError
      });
    }
    
    try {
      // Show typing indicator
      setState(() {
        _currentSession!.messages.add(Message(
          text: '...',
          isUser: false,
          timestamp: DateTime.now(),
          isTyping: true,
        ));
      });
      
      _scrollToBottom();
      
      // If API was previously unavailable, try to check if it's back
      final bool shouldCheckAvailability = 
          _apiService.toString().contains('_useFallbackResponses: true');
          
      if (shouldCheckAvailability) {
        // Try to check if API is now available
        await _apiService.checkApiAvailability();
      }
      
      // Call API
      final response = await _apiService.getDeepSeekResponse(userMessage);
      
      if (!mounted) return;
      
      // Remove typing indicator and add actual response
      setState(() {
        _currentSession!.messages.removeWhere((message) => message.isTyping == true);
        _currentSession!.messages.add(Message(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
      
      // Save bot response to Firestore
      if (_currentUserId != null && _firestoreAvailable) {
        _firestoreService.addMessageToSession(
          _currentSession!.id, 
          _currentSession!.messages.last, 
          _currentUserId!
        ).catchError((e) {
          if (_isFirestorePermissionError(e) && !_showedFirestoreError) {
            setState(() {
              _firestoreAvailable = false;
            });
            _showFirestorePermissionErrorDialog();
            _showedFirestoreError = true;
          }
          return false; // Add return value for catchError
        });
        
        // Update session in Firestore to ensure title and other metadata are saved
        _firestoreService.saveChatSession(_currentSession!, _currentUserId!)
          .catchError((e) {
            if (_isFirestorePermissionError(e) && !_showedFirestoreError) {
              setState(() {
                _firestoreAvailable = false;
              });
              _showFirestorePermissionErrorDialog();
              _showedFirestoreError = true;
            }
            return null; // Add return value for catchError
          });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentSession!.messages.removeWhere((message) => message.isTyping == true);
        _currentSession!.messages.add(Message(
          text: 'Xin lỗi, tôi không thể trả lời lúc này. Lỗi: ${e.toString()}',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
      
      // Save error message to Firestore
      if (_currentUserId != null && _firestoreAvailable) {
        _firestoreService.addMessageToSession(
          _currentSession!.id, 
          _currentSession!.messages.last, 
          _currentUserId!
        ).catchError((e) {
          if (_isFirestorePermissionError(e) && !_showedFirestoreError) {
            setState(() {
              _firestoreAvailable = false;
            });
            _showFirestorePermissionErrorDialog();
            _showedFirestoreError = true;
          }
          return false; // Add return value for catchError
        });
      }
    }
    
    _scrollToBottom();
  }

  void _handleClearChat() {
    if (_currentSession == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all messages in this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                // Keep the first bot message as greeting
                final initialMessage = _currentSession!.messages.isNotEmpty && !_currentSession!.messages.first.isUser 
                    ? _currentSession!.messages.first 
                    : Message(
                        text: 'Xin chào! Tôi là AI của Vinh. Bạn khỏe không?',
                        isUser: false,
                        timestamp: DateTime.now(),
                      );
                      
                _currentSession!.messages.clear();
                _currentSession!.messages.add(initialMessage);
              });
              
              // Clear chat history in API service
              _apiService.clearConversationHistory();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat Bot'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset_permissions') {
                // Reset Firestore permission check
                _firestoreService.resetPermissionCheck();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Firestore permissions check reset. Retrying operations...'))
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
                  title: Text('Reset Firebase Permissions'),
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
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) // Use _isLoading in the build method
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