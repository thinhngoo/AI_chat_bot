import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart'; // Add this import
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService(); // Add ApiService

  final List<Message> _messages = [
    Message(
      text: "Xin chào! Tôi là Jarvis. Bạn khỏe không?",
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    Message(
      text: "Chào Jarvis! Tôi khỏe, cảm ơn bạn. Hôm nay bạn thế nào?",
      isUser: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
    Message(
      text: "Tôi rất tốt, cảm ơn bạn đã hỏi! Bạn muốn trò chuyện về điều gì?",
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
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

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      setState(() {
        _messages.add(Message(
          text: _messageController.text,
          isUser: true,
          timestamp: DateTime.now(),
        ));
      });
      try {
        // Call API from ApiService
        final response = await _apiService.getDeepSeekResponse(_messageController.text);
        if (!mounted) return;
        setState(() {
          _messages.add(Message(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _messageController.clear();
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _messages.add(Message(
            text: "Đã xảy ra lỗi khi gọi API: $e",
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _messageController.clear();
        });
      }
      // Cuộn xuống tin nhắn mới nhất
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jarvis Chat'),
        backgroundColor: Colors.grey[900], // Màu tối giống ChatGPT/Grok
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      backgroundColor: Colors.grey[850], // Nền tối
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