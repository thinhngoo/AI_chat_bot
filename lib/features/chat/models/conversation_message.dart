class ConversationMessage {
  final String query;
  final String answer;
  final int createdAt;
  final List<String> files;

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
      createdAt: json['createdAt'] ?? 0,
      files: List<String>.from(json['files'] ?? []),
    );
  }
}

class ConversationMessagesResponse {
  final String cursor;
  final bool hasMore;
  final int limit;
  final List<ConversationMessage> items;

  ConversationMessagesResponse({
    required this.cursor,
    required this.hasMore,
    required this.limit,
    required this.items,
  });

  factory ConversationMessagesResponse.fromJson(Map<String, dynamic> json) {
    return ConversationMessagesResponse(
      cursor: json['cursor'] ?? '',
      hasMore: json['has_more'] ?? false,
      limit: json['limit'] ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ConversationMessage.fromJson(item))
              .toList() ??
          [],
    );
  }
}
