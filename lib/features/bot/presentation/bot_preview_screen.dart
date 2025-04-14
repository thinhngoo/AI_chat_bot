import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/bot_service.dart';

class BotPreviewScreen extends StatefulWidget {
  final String botId;
  final String botName;
  
  const BotPreviewScreen({
    super.key,
    required this.botId,
    required this.botName,
  });

  @override
  State<BotPreviewScreen> createState() => _BotPreviewScreenState();
}

class _BotPreviewScreenState extends State<BotPreviewScreen> {
  final Logger _logger = Logger();
  final BotService _botService = BotService();
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    _messageController.clear();
    
    // Add user message to the list
    final userMessage = ChatMessage(
      message: message,
      isUserMessage: true,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(userMessage);
    });
    
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    try {
      // Send message to bot
      final response = await _botService.askBot(
        botId: widget.botId,
        message: message,
      );
      
      // Add bot response to the list
      final botMessage = ChatMessage(
        message: response,
        isUserMessage: false,
        timestamp: DateTime.now(),
      );
      
      if (mounted) {
        setState(() {
          _messages.add(botMessage);
          _isLoading = false;
        });
        
        // Auto-scroll to bottom
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
    } catch (e) {
      _logger.e('Error sending message: $e');
      
      if (mounted) {
        // Add error message
        final errorMessage = ChatMessage(
          message: 'Error: ${e.toString()}',
          isUserMessage: false,
          timestamp: DateTime.now(),
          isError: true,
        );
        
        setState(() {
          _messages.add(errorMessage);
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview: ${widget.botName}'),
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: theme.primaryColor.withAlpha(128),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Send a message to start chatting with "${widget.botName}"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      
                      return Align(
                        alignment: message.isUserMessage
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 10.0,
                          ),
                          decoration: BoxDecoration(
                            color: message.isUserMessage
                                ? theme.primaryColor
                                : message.isError
                                    ? Colors.red.withAlpha(51)
                                    : isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.message,
                                style: TextStyle(
                                  color: message.isUserMessage
                                      ? Colors.white
                                      : message.isError
                                          ? Colors.red
                                          : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: message.isUserMessage
                                      ? Colors.white.withAlpha(178)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLength: 2048, // Add character limit to reduce token usage
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      counterText: '', // Hide the character counter
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Material(
                    color: theme.primaryColor,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: _isLoading ? null : _sendMessage,
                      customBorder: const CircleBorder(),
                      child: _isLoading
                          ? Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : Icon(
                              Icons.send,
                              color: theme.colorScheme.onPrimary,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String message;
  final bool isUserMessage;
  final DateTime timestamp;
  final bool isError;
  
  ChatMessage({
    required this.message,
    required this.isUserMessage,
    required this.timestamp,
    this.isError = false,
  });
}
