class Message {
  final String text;
  final bool isUser; // true nếu là tin nhắn của người dùng, false nếu là AI
  final DateTime timestamp;
  final bool isTyping;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isTyping = false,
  });
}