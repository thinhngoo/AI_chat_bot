class AIBot {
  final String id;
  final String name;
  final String description;
  final String model;
  final String prompt;
  final List<String> knowledgeBaseIds;
  final List<String> connectedPlatforms; // Slack, Telegram, etc.
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublished;

  AIBot({
    required this.id,
    required this.name,
    required this.description,
    required this.model,
    required this.prompt,
    this.knowledgeBaseIds = const [],
    this.connectedPlatforms = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isPublished = false,
  });

  factory AIBot.fromJson(Map<String, dynamic> json) {
    return AIBot(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      model: json['model'] ?? 'gpt-4o-mini',
      prompt: json['prompt'] ?? json['instructions'] ?? '',
      knowledgeBaseIds: List<String>.from(json['knowledgeBaseIds'] ?? []),
      connectedPlatforms: List<String>.from(json['connectedPlatforms'] ?? []),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      isPublished: json['isPublished'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'model': model,
      'instructions': prompt, // API expects 'instructions' for prompt
      'knowledgeBaseIds': knowledgeBaseIds,
      'connectedPlatforms': connectedPlatforms,
      'isPublished': isPublished,
    };
  }

  AIBot copyWith({
    String? id,
    String? name,
    String? description,
    String? model,
    String? prompt,
    List<String>? knowledgeBaseIds,
    List<String>? connectedPlatforms,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublished,
  }) {
    return AIBot(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      model: model ?? this.model,
      prompt: prompt ?? this.prompt,
      knowledgeBaseIds: knowledgeBaseIds ?? this.knowledgeBaseIds,
      connectedPlatforms: connectedPlatforms ?? this.connectedPlatforms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}
