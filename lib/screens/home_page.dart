import 'package:flutter/material.dart';
import '../models/message.dart';
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
  bool _isTyping = false;

  final List<Message> _messages = [
    Message(
      text: "Xin chào! Tôi là AI của DeepSeek. Bạn khỏe không?",
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

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
    
    final userMessage = _messageController.text;
    setState(() {
      _messages.add(Message(
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
        _messages.add(Message(
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
        _messages.removeWhere((message) => message.isTyping == true);
        _messages.add(Message(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((message) => message.isTyping == true);
        _messages.add(Message(
          text: "Xin lỗi, tôi không thể trả lời lúc này. Lỗi: ${e.toString()}",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
    }
    
    _scrollToBottom();
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa cuộc trò chuyện'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ cuộc trò chuyện?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _messages.add(Message(
                  text: "Xin chào! Tôi là AI của DeepSeek. Bạn khỏe không?",
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
        title: const Text('DeepSeek Chat'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearChat,
            tooltip: 'Xóa cuộc trò chuyện',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'account') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountManagementPage()));
              } else if (value == 'help') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpFeedbackPage()));
              } else if (value == 'logout') {
                _signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'account', child: Text('Quản lý tài khoản')),
              const PopupMenuItem(value: 'help', child: Text('Trợ giúp & Phản hồi')),
              const PopupMenuItem(value: 'logout', child: Text('Đăng xuất')),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.grey[850],
      body: Column(
        children: [
          // Khu vực lịch sử chat
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment:
                      message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? Colors.blue[600] // Tin nhắn người dùng: màu xanh
                          : Colors.grey[700], // Tin nhắn AI: màu xám
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
                            color: Colors.white, // Chữ trắng cho nền tối
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "${message.timestamp.hour}:${message.timestamp.minute}",
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
          // Khu vực nhập tin nhắn
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.grey[900], // Thanh nhập liệu màu tối
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
                    onSubmitted: (_) => _sendMessage(), // Gửi khi nhấn Enter
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