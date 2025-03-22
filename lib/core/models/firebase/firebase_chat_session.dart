import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/message.dart';

class FirebaseChatSession {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final List<FirebaseMessage> messages;

  FirebaseChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.lastUpdatedAt,
    required this.messages,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      // Don't include messages in the main document
    };
  }

  static FirebaseChatSession fromMap(Map<String, dynamic> map, String documentId) {
    return FirebaseChatSession(
      id: documentId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'New Chat',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastUpdatedAt: (map['lastUpdatedAt'] as Timestamp).toDate(),
      messages: [], // Messages are stored in a subcollection
    );
  }

  static FirebaseChatSession fromChatSession(ChatSession session, String userId) {
    return FirebaseChatSession(
      id: session.id,
      userId: userId,
      title: session.title,
      createdAt: session.createdAt,
      lastUpdatedAt: DateTime.now(),
      messages: session.messages.map((msg) => FirebaseMessage.fromMessage(msg)).toList(),
    );
  }
}

class FirebaseMessage {
  final String text;
  final bool isUser;
  final Timestamp timestamp;
  final bool isTyping;

  FirebaseMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isTyping = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp,
      'isTyping': isTyping,
    };
  }

  static FirebaseMessage fromMap(Map<String, dynamic> map, String documentId) {
    return FirebaseMessage(
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: map['timestamp'] ?? Timestamp.now(),
      isTyping: map['isTyping'] ?? false,
    );
  }

  Message toMessage() {
    return Message(
      text: text,
      isUser: isUser,
      timestamp: timestamp.toDate(),
      isTyping: isTyping,
    );
  }

  static FirebaseMessage fromMessage(Message message) {
    return FirebaseMessage(
      text: message.text,
      isUser: message.isUser,
      timestamp: Timestamp.fromDate(message.timestamp),
      isTyping: message.isTyping,
    );
  }
}
