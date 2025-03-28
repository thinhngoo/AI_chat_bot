import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/models/chat/chat_session.dart';
import '../../../core/services/chat/jarvis_chat_service.dart';
import '../../../widgets/ai/model_selector_widget.dart';
import '../../settings/presentation/settings_page.dart';
import 'chat_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Logger _logger = Logger();
  final JarvisChatService _chatService = JarvisChatService();
  
  List<ChatSession> _chatSessions = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _selectedModel = 'gemini-1.5-flash-latest';
  
  @override
  void initState() {
    super.initState();
    _loadChatSessions();
    _loadSelectedModel();
  }
  
  Future<void> _loadChatSessions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      // Check if using direct Gemini API
      final isUsingGemini = _chatService.isUsingDirectGeminiApi();
      
      final sessions = await _chatService.getUserChatSessions();
      
      if (!mounted) return;
      
      setState(() {
        _chatSessions = sessions;
        _isLoading = false;
        // Show info message if using Gemini API directly
        if (isUsingGemini) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Using Gemini API directly due to Jarvis API authentication issues'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    } catch (e) {
      _logger.e('Error loading chat sessions: $e');
      
      if (!mounted) return;
      
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      
      // Check if it's an auth error and show appropriate message
      if (e.toString().contains('Unauthorized') || 
          e.toString().contains('Authentication failed') ||
          e.toString().contains('401')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Authentication error. Please log in again.'),
            action: SnackBarAction(
              label: 'Login',
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chats: $e')),
        );
      }
    }
  }
  
  Future<void> _loadSelectedModel() async {
    try {
      final model = await _chatService.getSelectedModel();
      if (model != null && mounted) {
        setState(() {
          _selectedModel = model;
        });
      }
    } catch (e) {
      _logger.e('Error loading selected model: $e');
    }
  }
  
  Future<void> _createNewChat() async {
    try {
      final newChat = await _chatService.createChatSession('New Chat');
      
      if (newChat != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatSession: newChat),
          ),
        ).then((_) => _loadChatSessions());
      }
    } catch (e) {
      _logger.e('Error creating new chat: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create new chat: $e')),
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
          const SnackBar(content: Text('Chat deleted')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete chat')),
        );
      }
    } catch (e) {
      _logger.e('Error deleting chat: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  Future<void> _updateSelectedModel(String model) async {
    try {
      setState(() {
        _selectedModel = model;
      });
      
      await _chatService.updateSelectedModel(model);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Model updated to $model')),
      );
    } catch (e) {
      _logger.e('Error updating model: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update model: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat Bot'),
        actions: [
          ModelSelectorWidget(
            currentModel: _selectedModel,
            onModelChanged: _updateSelectedModel,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              ).then((_) => _loadChatSessions());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorView()
              : _chatSessions.isEmpty
                  ? _buildEmptyView()
                  : _buildChatList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewChat,
        tooltip: 'New Chat',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Đã xảy ra lỗi khi tải danh sách trò chuyện',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Vui lòng kiểm tra kết nối mạng và thử lại',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadChatSessions,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyView() {
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