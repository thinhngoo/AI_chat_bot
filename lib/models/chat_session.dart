import 'message.dart';

class ChatSession {
  final String id;
  final String title;
  final List<Message> messages;
  final DateTime createdAt;

  ChatSession({
    required this.id,
    required this.title,
    List<Message>? messages,
    DateTime? createdAt,
  }) : 
      this.messages = messages ?? [],
      this.createdAt = createdAt ?? DateTime.now();
}
