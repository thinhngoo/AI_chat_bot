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
      messages = messages ?? [],
      createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
    };
  }
}
