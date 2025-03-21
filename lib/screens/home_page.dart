import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/chat_session.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'login_page.dart';
import 'account_management_page.dart';
import 'help_feedback_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  
  // Chat session management
  final List<ChatSession> _chatSessions = [];
  ChatSession? _currentSession;
  bool _isTyping = false;
  final _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    // Create a default chat session
    _createNewChat();
  }

  void _createNewChat() {
    final newSession = ChatSession(
      id: _uuid.v4(),
      title: 'New Chat',
      messages: [
        Message(
          text: "Xin chào! Tôi là AI của Vinh. Bạn khỏe không?",
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
    
    try {
      // Show typing indicator
      setState(() {
        _currentSession!.messages.add(Message(
          text: "...",
          isUser: false,
          timestamp: DateTime.now(),
          isTyping: true,
        ));
      });
      
      _scrollToBottom();
      
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentSession!.messages.removeWhere((message) => message.isTyping == true);
        _currentSession!.messages.add(Message(
          text: "Xin lỗi, tôi không thể trả lời lúc này. Lỗi: ${e.toString()}",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
    }
    
    _scrollToBottom();
  }

  void _clearCurrentChat() {
    if (_currentSession == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa cuộc trò chuyện'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ tin nhắn trong cuộc trò chuyện này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentSession!.messages.clear();
                _currentSession!.messages.add(Message(
                  text: "Xin chào! Tôi là AI của Vinh. Bạn khỏe không?",
                  isUser: false,
                  timestamp: DateTime.now(),
                ));
              });
              _apiService.clearConversationHistory();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentSession != null ? _getChatTitle(_currentSession!) : 'AI của Vinh'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearCurrentChat,
            tooltip: 'Xóa tin nhắn',
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
                      selectedTileColor: Colors.blue.withValues(alpha: 77), // 0.3 * 255 ≈ 77
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
      body: _currentSession == null
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
                                "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}",
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
                  padding: const EdgeInsets.all(10),
                  color: Colors.grey[900],
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
                        icon: Icon(Icons.send, color: Colors.blue[400]),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}