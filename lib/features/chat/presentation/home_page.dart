import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/models/chat/chat_session.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/services/chat/jarvis_chat_service.dart';
import '../../auth/presentation/login_page.dart';
import '../../settings/presentation/settings_page.dart';
import 'chat_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final JarvisChatService _chatService = JarvisChatService();
  final Logger _logger = Logger();
  
  List<ChatSession> _chatSessions = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadChatSessions();
  }
  
  Future<void> _loadChatSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final sessions = await _chatService.getUserChatSessions();
      
      if (!mounted) return;
      
      setState(() {
        _chatSessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading chat sessions: $e');
      
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Không thể tải danh sách trò chuyện.';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _createNewChat() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final newSession = await _chatService.createChatSession('Cuộc trò chuyện mới');
      
      if (!mounted) return;
      
      if (newSession != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatSession: newSession),
          ),
        ).then((_) => _loadChatSessions());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tạo cuộc trò chuyện mới')),
        );
      }
    } catch (e) {
      _logger.e('Error creating new chat session: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _authService.signOut();
      
      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      _logger.e('Error logging out: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng xuất: ${e.toString()}')),
      );
    }
  }
  
  Future<void> _deleteChat(ChatSession session) async {
    try {
      final success = await _chatService.deleteChatSession(session.id);
      
      if (!mounted) return;
      
      if (success) {
        setState(() {
          _chatSessions.removeWhere((s) => s.id == session.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa cuộc trò chuyện')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xóa cuộc trò chuyện')),
        );
      }
    } catch (e) {
      _logger.e('Error deleting chat session: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat Bot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadChatSessions,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _chatSessions.isEmpty
                  ? _buildEmptyState()
                  : _buildChatList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewChat,
        tooltip: 'Trò chuyện mới',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có cuộc trò chuyện nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bắt đầu trò chuyện mới bằng cách nhấn nút "+" bên dưới',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _createNewChat,
            child: const Text('Tạo cuộc trò chuyện mới'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChatList() {
    return ListView.builder(
      itemCount: _chatSessions.length,
      itemBuilder: (context, index) {
        final session = _chatSessions[index];
        return ListTile(
          title: Text(session.title),
          subtitle: Text(
            'Tạo lúc: ${_formatDate(session.createdAt)}',
          ),
          leading: const CircleAvatar(
            child: Icon(Icons.chat),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteChat(session),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(chatSession: session),
              ),
            ).then((_) => _loadChatSessions());
          },
        );
      },
    );
  }
  
  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}