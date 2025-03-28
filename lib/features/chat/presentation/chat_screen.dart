import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/models/chat/chat_session.dart';
import '../../../core/models/chat/message.dart';
import '../../../core/services/chat/jarvis_chat_service.dart';
import '../../../widgets/ai/model_selector_widget.dart';

class ChatScreen extends StatefulWidget {
  final ChatSession chatSession;
  
  const ChatScreen({
    super.key, 
    required this.chatSession,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final JarvisChatService _chatService = JarvisChatService();
  final Logger _logger = Logger();
  
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String _currentModel = 'gemini-1.5-flash-latest';
  
  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadModel();
  }
  
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _messages = await _chatService.getMessages(widget.chatSession.id);
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Scroll to bottom after messages load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      _logger.e('Error loading messages: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load messages: $e')),
      );
    }
  }
  
  Future<void> _loadModel() async {
    try {
      final model = await _chatService.getSelectedModel();
      if (model != null && mounted) {
        setState(() {
          _currentModel = model;
        });
      }
    } catch (e) {
      _logger.e('Error loading model: $e');
    }
  }
  
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    _messageController.clear();
    
    // Optimistically add user message to UI
    setState(() {
      _messages.add(Message(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isSending = true;
    });
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    
    try {
      // Add temporary "typing" message
      setState(() {
        _messages.add(Message(
          text: '...',
          isUser: false,
          timestamp: DateTime.now(),
          isTyping: true,
        ));
      });
      
      // Scroll to bottom again
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
      
      // Send message to service - don't store return value since we're not using it
      await _chatService.sendMessage(
        widget.chatSession.id, 
        text,
      );
      
      // Get AI response - we need to wait for it separately
      String aiResponse;
      
      // If using direct Gemini API, generate response directly
      if (_chatService.isUsingDirectGeminiApi()) {
        // Convert message history to format for Gemini API
        final chatHistory = _messages
            .where((m) => !m.isTyping)
            .take(10)
            .map((msg) => {
                'role': msg.isUser ? 'user' : 'assistant',
                'content': msg.text,
              })
            .toList();
        
        // Get response from Gemini directly
        aiResponse = await _chatService.getDirectAIResponse(text, chatHistory);
      } else {
        // For Jarvis API, wait a moment and load new messages
        await Future.delayed(const Duration(milliseconds: 800));
        final freshMessages = await _chatService.getMessages(widget.chatSession.id);
        
        // Find the AI response message (most recent non-user message)
        final aiMessages = freshMessages
            .where((m) => !m.isUser)
            .toList();
        
        if (aiMessages.isNotEmpty) {
          aiResponse = aiMessages.last.text;
        } else {
          aiResponse = "Sorry, I couldn't generate a response at this time.";
        }
      }
      
      if (!mounted) return;
      
      // Remove typing indicator and add real response
      setState(() {
        // Remove typing indicator
        _messages.removeWhere((message) => message.isTyping);
        
        // Add AI response message
        _messages.add(Message(
          text: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        
        _isSending = false;
      });
      
      _scrollToBottom();
    } catch (e) {
      _logger.e('Error sending message: $e');
      
      if (!mounted) return;
      
      // Remove typing indicator
      setState(() {
        _messages.removeWhere((message) => message.isTyping);
        _isSending = false;
      });
      
      // Add error message as bot response
      setState(() {
        _messages.add(Message(
          text: 'Đã xảy ra lỗi: ${e.toString()}',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      
      _scrollToBottom();
    }
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  void _onModelChanged(String model) {
    setState(() {
      _currentModel = model;
    });
    
    // Save selected model
    _chatService.updateSelectedModel(model);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatSession.title),
        actions: [
          ModelSelectorWidget(
            currentModel: _currentModel,
            onModelChanged: _onModelChanged,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text('Bắt đầu cuộc trò chuyện bằng cách gửi tin nhắn.'),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
          ),
          
          // Input box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: const Offset(0, -1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isSending,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(Message message) {
    final isUser = message.isUser;
    
    if (message.isTyping) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
          child: const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
            ),
          ),
        ),
      );
    }
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFFEEEEEE), // Use const Color instead of Colors.grey[300]
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                color: isUser ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
