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
  bool _isTyping = false;
  
  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        message: 'Xin chào! Tôi là ${widget.botName}. Tôi có thể giúp gì cho bạn?',
        isUserMessage: false,
        timestamp: DateTime.now(),
        isError: false,
      ),
    );
  }
  
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    // Add user message to chat
    setState(() {
      _messages.add(
        ChatMessage(
          message: message,
          isUserMessage: true,
          timestamp: DateTime.now(),
          isError: false,
        ),
      );
      _messageController.clear();
      _isTyping = true;
    });
    
    // Scroll to bottom after adding message
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
      setState(() {
        _isLoading = true;
      });
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      final response = await _botService.askBot(
        botId: widget.botId,
        message: message,
      );
      
      // Add bot response to chat
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              message: response,
              isUserMessage: false,
              timestamp: DateTime.now(),
              isError: false,
            ),
          );
          _isLoading = false;
        });
      }
      
      // Scroll to bottom after receiving response
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      _logger.e('Error asking bot: $e');
      
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              message: 'Xin lỗi, đã xảy ra lỗi: ${e.toString()}',
              isUserMessage: false,
              timestamp: DateTime.now(),
              isError: true,
            ),
          );
          _isLoading = false;
        });
      }
      
      // Still scroll to bottom on error
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
                const Text(
                  'Thêm tệp đính kèm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image, color: Colors.blue),
                  ),
                  title: const Text('Hình ảnh'),
                  subtitle: const Text('Gửi từ thư viện ảnh'),
                  onTap: () {
                    Navigator.pop(context);
                    _showFeatureNotImplemented('Chức năng tải ảnh lên đang phát triển');
                  },
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
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gửi đường dẫn'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Nhập đường dẫn website',
            prefixIcon: Icon(Icons.link),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = textController.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(context);
                _messageController.text = url;
                _sendMessage();
              }
            },
            child: const Text('GỬI'),
          ),
        ],
      ),
    ).then((_) => textController.dispose());
  }

  // Show feature not implemented dialog
  void _showFeatureNotImplemented(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
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
        title: const Text('Xóa lịch sử chat'),
        content: const Text('Bạn có chắc chắn muốn xóa tất cả tin nhắn trong cuộc trò chuyện này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HỦY'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
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
            Text(widget.botName),
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(128), // Changed from withOpacity(0.5)
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đây là chế độ xem trước của bot. Tin nhắn không được lưu trữ và đây chỉ là môi trường để kiểm tra.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                color: Theme.of(context).colorScheme.surface,
                image: DecorationImage(
                  image: const AssetImage('assets/images/chat_background.png'),
                  fit: BoxFit.cover,
                  opacity: 0.05,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.primary.withAlpha(26), // Changed from withOpacity(0.1)
                    BlendMode.dstATop,
                  ),
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: groupedMessages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show typing indicator as the last item when bot is typing
                  if (_isTyping && index == groupedMessages.length) {
                    return _buildTypingIndicator();
                  }
                  
                  final messageGroup = groupedMessages[index];
                  final isUserMessage = messageGroup.first.isUserMessage;
                  
                  return _buildMessageGroup(context, messageGroup, isUserMessage);
                },
              ),
            ),
          ),
          
          // Message input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13), // Changed from withOpacity(0.05)
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    tooltip: 'Thêm tệp đính kèm',
                    onPressed: _showAttachmentOptions,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      maxLines: 5,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(128), // Changed from withOpacity(0.5)
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  FloatingActionButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    mini: true,
                    tooltip: 'Gửi tin nhắn',
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    child: _isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build a group of messages from the same sender
  Widget _buildMessageGroup(BuildContext context, List<ChatMessage> messageGroup, bool isUser) {
    final alignStart = !isUser;
    final avatarWidget = !isUser 
        ? CircleAvatar(
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
          )
        : null;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (alignStart) ...[
            avatarWidget!,
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
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(178), // Changed from withOpacity
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
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(128), // Changed from withOpacity
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
        ],
      ),
    );
  }

  // Build a message bubble
  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final isUserMessage = message.isUserMessage;
    final backgroundColor = isUserMessage
        ? Theme.of(context).colorScheme.primary
        : message.isError
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest;

    final textColor = isUserMessage
        ? Theme.of(context).colorScheme.onPrimary
        : message.isError
            ? Theme.of(context).colorScheme.onErrorContainer
            : Theme.of(context).colorScheme.onSurfaceVariant;

    // Determine if message appears to be a URL
    final isUrl = Uri.tryParse(message.message)?.hasScheme ?? false;

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
          borderRadius: BorderRadius.circular(16.0),
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
                      side: BorderSide(color: textColor.withAlpha(128)), // Changed from withOpacity
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
    return Row(
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
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                _buildPulsingDot(0),
                const SizedBox(width: 4),
                _buildPulsingDot(100),
                const SizedBox(width: 4),
                _buildPulsingDot(200),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Build a pulsing dot for the typing indicator with a delay
  Widget _buildPulsingDot(int delay) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(
              0.3 + (0.7 * (0.7 * (value > 0.5 ? 1 - value : value) * 2)),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
  
  // Format timestamp for message display
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);
    
    final formatter = time.hour > 12 
        ? '${time.hour - 12}:${time.minute.toString().padLeft(2, '0')} PM'
        : '${time.hour}:${time.minute.toString().padLeft(2, '0')} AM';
    
    if (messageDate == today) {
      return formatter;
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Hôm qua, $formatter';
    } else {
      return '${time.day}/${time.month} $formatter';
    }
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
    return AlertDialog(
      title: const Text('Đánh giá trò chuyện'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bạn đánh giá cuộc trò chuyện này như thế nào?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  icon: Icon(
                    _rating >= starValue ? Icons.star : Icons.star_border,
                    size: 32,
                    color: _rating >= starValue ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = starValue;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                labelText: 'Phản hồi (tùy chọn)',
                hintText: 'Chia sẻ ý kiến của bạn...',
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
          child: const Text('HỦY'),
        ),
        ElevatedButton(
          onPressed: () {
            // Send feedback
            if (_rating > 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cảm ơn bạn đã đánh giá!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            Navigator.pop(context);
          },
          child: const Text('GỬI'),
        ),
      ],
    );
  }
}

class ChatMessage {
  final String message;
  final bool isUserMessage;
  final DateTime timestamp;
  final bool isError;
  final String? deliveryStatus; // null, 'sent', or 'read'
  
  ChatMessage({
    required this.message,
    required this.isUserMessage,
    required this.timestamp,
    this.isError = false,
    this.deliveryStatus,
  });
}
