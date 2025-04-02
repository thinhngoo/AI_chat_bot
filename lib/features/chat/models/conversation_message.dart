/// Model class for conversation messages
class ConversationMessage {
  final String query;      // User's question
  final String answer;     // AI's response
  final int createdAt;     // Unix timestamp
  final List<dynamic> files; // Optional file attachments
  
  ConversationMessage({
    required this.query,
    required this.answer,
    required this.createdAt,
    required this.files,
  });
  
  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      query: json['query'] ?? '',
      answer: json['answer'] ?? '',
      createdAt: json['created_at'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      files: json['files'] ?? [],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'answer': answer,
      'created_at': createdAt,
      'files': files,
    };
  }
}

/// Response model for conversation messages API
class ConversationMessagesResponse {
  final List<ConversationMessage> items;
  final bool hasMore;
  final String? nextCursor;
  
  ConversationMessagesResponse({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });
  
  factory ConversationMessagesResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> messageData = json['items'] ?? [];
    
    return ConversationMessagesResponse(
      items: messageData
          .map((item) => ConversationMessage.fromJson(item))
          .toList(),
      hasMore: json['has_more'] ?? false,
      nextCursor: json['cursor'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'has_more': hasMore,
      'cursor': nextCursor,
    };
  }
}
