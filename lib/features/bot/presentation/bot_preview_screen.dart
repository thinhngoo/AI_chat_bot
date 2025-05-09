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

class _BotPreviewScreenState extends State<BotPreviewScreen> with TickerProviderStateMixin {
  final Logger _logger = Logger();
  final BotService _botService = BotService();
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  
  // Animation controllers
  late AnimationController _sendButtonController;
  
  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    
    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }
  
  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          message: 'Xin chào! Tôi là ${widget.botName}. Bạn có thể hỏi tôi bất cứ điều gì.',
          isUserMessage: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }
  
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    // Start loading animation
    _sendButtonController.forward();
    
    setState(() {
      _isLoading = true;
      _isTyping = true;
      
      // Insert the user message at the beginning of the list (for reverse ListView)
      _messages.insert(0, 
        ChatMessage(
          message: message,
          isUserMessage: true,
          timestamp: DateTime.now(),
          deliveryStatus: 'sent',
        ),
      );
      
      _messageController.clear();
    });
    
    // No need to scroll to bottom since we're using a reversed list that starts from the bottom
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Call bot service
      final response = await _botService.askBot(
        botId: widget.botId,
        message: message,
      );
      
      if (!mounted) return;
      
      // Update message delivery status
      setState(() {
        final firstUserMessageIndex = _messages.indexWhere((msg) => msg.isUserMessage);
        if (firstUserMessageIndex != -1) {
          _messages[firstUserMessageIndex] = ChatMessage(
            message: _messages[firstUserMessageIndex].message,
            isUserMessage: true,
            timestamp: _messages[firstUserMessageIndex].timestamp,
            deliveryStatus: 'read',
          );
        }
      });
      
      // Add bot response after a small delay to show typing indicator
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      setState(() {
        // Insert the bot response at the beginning of the list (for reverse ListView)
        _messages.insert(0,
          ChatMessage(
            message: response, // Direct use of response as String
            isUserMessage: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
        _isTyping = false;
        _sendButtonController.reverse();
      });
      
      // No need to scroll to bottom since we're using a reversed list that starts from the bottom
    } catch (e) {
      _logger.e('Error sending message: $e');
      
      if (!mounted) return;
      
      setState(() {
        // Insert error message at the beginning of the list (for reverse ListView)
        _messages.insert(0,
          ChatMessage(
            message: 'Xin lỗi, đã xảy ra lỗi: ${e.toString()}',
            isUserMessage: false,
            timestamp: DateTime.now(),
            isError: true,
          ),
        );
        _isLoading = false;
        _isTyping = false;
        _sendButtonController.reverse();
      });
    }
  }

  // Show attachment options
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Gửi tệp đính kèm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.insert_drive_file, color: Colors.red),
                  ),
                  title: const Text('Tài liệu'),
                  subtitle: const Text('PDF, Word, Excel...'),
                  onTap: () {
                    Navigator.pop(context);
                    _showFeatureNotImplemented('Chức năng tải tài liệu lên đang phát triển');
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.link, color: Colors.green),
                  ),
                  title: const Text('Liên kết'),
                  subtitle: const Text('Gửi đường dẫn website'),
                  onTap: () {
                    Navigator.pop(context);
                    _showUrlInputDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show URL input dialog
  void _showUrlInputDialog() {
    final TextEditingController urlController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập URL'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'https://example.com',
            prefixIcon: Icon(Icons.link),
          ),
          keyboardType: TextInputType.url,
          onSubmitted: (_) {
            if (urlController.text.isNotEmpty) {
              Navigator.pop(context);
              
              setState(() {
                _messages.insert(0,
                  ChatMessage(
                    message: urlController.text,
                    isUserMessage: true,
                    timestamp: DateTime.now(),
                    isUrl: true,
                  ),
                );
              });
              
              // Simulate bot response
              _simulateBotResponseWithDelay('Cảm ơn bạn đã chia sẻ liên kết. Tôi đang phân tích nội dung.');
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            onPressed: () {
              if (urlController.text.isNotEmpty) {
                Navigator.pop(context);
                
                setState(() {
                  _messages.insert(0,
                    ChatMessage(
                      message: urlController.text,
                      isUserMessage: true,
                      timestamp: DateTime.now(),
                      isUrl: true,
                    ),
                  );
                });
                
                // Simulate bot response
                _simulateBotResponseWithDelay('Cảm ơn bạn đã chia sẻ liên kết. Tôi đang phân tích nội dung.');
              }
            },
            child: const Text('GỬI'),
          ),
        ],
      ),
    ).then((_) {
      urlController.dispose();
    });
  }
  
  // Simulate bot response with delay
  Future<void> _simulateBotResponseWithDelay(String message) async {
    setState(() {
      _isTyping = true;
    });
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    
    setState(() {
      _messages.insert(0,
        ChatMessage(
          message: message,
          isUserMessage: false,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = false;
    });
    
    // Scroll to bottom again
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Show feature not implemented dialog
  void _showFeatureNotImplemented(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  // Clear chat history
  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Xóa cuộc trò chuyện'),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa tất cả tin nhắn? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HỦY'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('XÓA'),
          ),
        ],
      ),
    );
  }

  // Rate conversation
  void _rateConversation() {
    showDialog(
      context: context,
      builder: (context) => const RatingDialog(),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Group messages by sender with minimal time gap
    final groupedMessages = <List<ChatMessage>>[];
    for (final message in _messages) {
      if (groupedMessages.isEmpty || 
          groupedMessages.last.first.isUserMessage != message.isUserMessage ||
          message.timestamp.difference(groupedMessages.last.last.timestamp).inMinutes > 2) {
        groupedMessages.add([message]);
      } else {
        groupedMessages.last.add(message);
      }
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.botName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              'Bot Preview Mode',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            tooltip: 'Rate Conversation',
            onPressed: _rateConversation,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Chat',
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat header info
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đây là chế độ xem trước của bot. Tin nhắn không được lưu trữ và đây chỉ là môi trường để kiểm tra.',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Chat messages
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? const Color(0xFF121212) 
                    : const Color(0xFFF5F5F5),
                image: DecorationImage(
                  image: const AssetImage('assets/images/chat_background.png'),
                  fit: BoxFit.cover,
                  opacity: 0.05,
                  colorFilter: ColorFilter.mode(
                    theme.colorScheme.primary.withAlpha(25),  // Approximately 0.1 opacity
                    BlendMode.dstATop,
                  ),
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                itemCount: groupedMessages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show typing indicator as the first item when bot is typing
                  if (_isTyping && index == 0) {
                    return _buildTypingIndicator();
                  }
                  
                  final messageGroupIndex = _isTyping ? index - 1 : index;
                  final messageGroup = groupedMessages[messageGroupIndex];
                  final isUserMessage = messageGroup.first.isUserMessage;
                  
                  return _buildMessageGroup(context, messageGroup, isUserMessage);
                },
              ),
            ),
          ),
          
          // Message input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13), // ~0.05 opacity
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachment button
                  IconButton(
                    icon: Icon(
                      Icons.attach_file,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: _showAttachmentOptions,
                    tooltip: 'Add attachment',
                  ),
                  
                  // Message input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDarkMode 
                              ? Colors.grey[700]! 
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                        color: isDarkMode 
                            ? Colors.grey[850] 
                            : Colors.grey[50],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 5,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            hintText: 'Nhập tin nhắn...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            isDense: true,
                            hintStyle: TextStyle(
                              color: isDarkMode 
                                  ? Colors.grey[400] 
                                  : Colors.grey[600],
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          onChanged: (text) {
                            setState(() {
                              // This forces the send button to update
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Send button
                  AnimatedBuilder(
                    animation: _sendButtonController,
                    builder: (context, child) {
                      final bool showLoading = _sendButtonController.status == AnimationStatus.forward ||
                                            _sendButtonController.status == AnimationStatus.completed;
                      
                      return Material(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: (_messageController.text.trim().isNotEmpty && !_isLoading) 
                              ? _sendMessage 
                              : null,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: showLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.send_rounded,
                                    color: _messageController.text.trim().isEmpty
                                        ? theme.colorScheme.onPrimary.withAlpha(128)
                                        : theme.colorScheme.onPrimary,
                                    size: 24,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build a message group from the same sender
  Widget _buildMessageGroup(BuildContext context, List<ChatMessage> messageGroup, bool isUser) {
    final theme = Theme.of(context);
    
    // Create avatar for user or bot
    final avatarWidget = isUser
      ? CircleAvatar(
          backgroundColor: Colors.grey[700],
          radius: 16,
          child: const Icon(
            Icons.person,
            size: 18,
            color: Colors.white,
          ),
        )
      : CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          radius: 16,
          child: Text(
            widget.botName.isNotEmpty ? widget.botName[0].toUpperCase() : 'B',
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        );
    
    final bool alignStart = !isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (alignStart) ...[
            avatarWidget,
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Sender name (only for first message in group)
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
                    child: Text(
                      widget.botName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withAlpha(179),
                      ),
                    ),
                  ),
                
                // Message bubbles
                ...messageGroup.map((message) => _buildMessageBubble(context, message)),
                
                // Timestamp (only for last message in group)
                Padding(
                  padding: EdgeInsets.only(
                    top: 4.0,
                    left: isUser ? 0 : 12.0,
                    right: isUser ? 12.0 : 0,
                  ),
                  child: Text(
                    _formatTime(messageGroup.last.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withAlpha(128),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (isUser && messageGroup.first.deliveryStatus != null) ...[
            const SizedBox(width: 4),
            Icon(
              messageGroup.first.deliveryStatus == 'read' 
                ? Icons.done_all 
                : Icons.done,
              size: 14,
              color: messageGroup.first.deliveryStatus == 'read'
                ? Colors.blue
                : Colors.grey,
            ),
          ],
          
          if (!alignStart) ...[
            const SizedBox(width: 8),
            avatarWidget,
          ],
        ],
      ),
    );
  }

  // Build a message bubble
  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final theme = Theme.of(context);
    final isUserMessage = message.isUserMessage;
    final backgroundColor = isUserMessage
        ? theme.colorScheme.primary
        : message.isError
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surfaceContainerHighest;

    final textColor = isUserMessage
        ? theme.colorScheme.onPrimary
        : message.isError
            ? theme.colorScheme.onErrorContainer
            : theme.colorScheme.onSurfaceVariant;

    // Determine if message appears to be a URL
    final isUrl = message.isUrl || (Uri.tryParse(message.message)?.hasScheme ?? false);

    return Container(
      margin: EdgeInsets.only(
        top: 2.0,
        bottom: 2.0,
        left: isUserMessage ? 64.0 : 0.0,
        right: isUserMessage ? 0.0 : 64.0,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUserMessage 
                ? const Radius.circular(16) 
                : const Radius.circular(4),
            bottomRight: isUserMessage 
                ? const Radius.circular(4) 
                : const Radius.circular(16),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: isUrl 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Mở liên kết'),
                    onPressed: () {
                      _showFeatureNotImplemented('Tính năng mở liên kết đang phát triển');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: textColor.withAlpha(128)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      minimumSize: const Size(0, 28),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              )
            : SelectableText(
                message.message,
                style: TextStyle(color: textColor),
              ),
        ),
      ),
    );
  }
  
  // Build the typing indicator
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              radius: 16,
              child: Text(
                widget.botName.isNotEmpty ? widget.botName[0].toUpperCase() : 'B',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  _buildPulsingDot(),
                  const SizedBox(width: 4),
                  _buildPulsingDot(),
                  const SizedBox(width: 4),
                  _buildPulsingDot(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build a pulsing dot for the typing indicator
  Widget _buildPulsingDot() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Container(
          width: 8 + (value < 0.5 ? value : 1.0 - value) * 4,
          height: 8 + (value < 0.5 ? value : 1.0 - value) * 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha(
              (153 + (value < 0.5 ? value : 1.0 - value) * 102).toInt(),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  // Format time to display in messages
  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}

// Rating dialog for feedback
class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  
  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.star, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Rate Conversation'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How was your experience with the bot?'),
            const SizedBox(height: 16),
            
            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return IconButton(
                  icon: Icon(
                    _rating >= starIndex ? Icons.star : Icons.star_border,
                    color: _rating >= starIndex ? Colors.amber : Colors.grey,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = starIndex;
                    });
                  },
                );
              }),
            ),
            
            const SizedBox(height: 16),
            
            // Feedback text field
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                labelText: 'Additional Comments (optional)',
                hintText: 'Tell us more about your experience...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            // Submit rating and feedback
            if (_rating > 0) {
              // In a real app, you would send this to your backend
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Thanks for your $_rating-star rating!'),
                ),
              );
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select a rating'),
                ),
              );
            }
          },
          child: const Text('SUBMIT'),
        ),
      ],
    );
  }
}

class ChatMessage {
  final String message;
  final bool isUserMessage;
  final DateTime timestamp;
  final String? deliveryStatus; // 'sent', 'delivered', 'read', or null
  final bool isError;
  final bool isUrl;
  
  ChatMessage({
    required this.message,
    required this.isUserMessage,
    required this.timestamp,
    this.deliveryStatus,
    this.isError = false,
    this.isUrl = false,
  });
}
