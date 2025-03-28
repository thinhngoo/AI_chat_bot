import 'dart:convert';
import 'message.dart';

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<Message>? messages;
  final String? modelId;
  final Map<String, dynamic>? metadata;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    this.updatedAt,
    this.messages,
    this.modelId,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'messages': messages?.map((x) => x.toMap()).toList(),
      'modelId': modelId,
      'metadata': metadata,
    };
  }

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'] ?? '',
      title: map['title'] ?? 'New Chat',
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
      messages: map['messages'] != null
          ? List<Message>.from(map['messages']?.map((x) => Message.fromMap(x)))
          : null,
      modelId: map['modelId'],
      metadata: map['metadata'],
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatSession.fromJson(String source) => ChatSession.fromMap(json.decode(source));

  ChatSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Message>? messages,
    String? modelId,
    Map<String, dynamic>? metadata,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      modelId: modelId ?? this.modelId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'ChatSession(id: $id, title: $title, createdAt: $createdAt)';
  }
}