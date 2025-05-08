class Prompt {
  final String id;
  final String title;
  final String content;
  final String description;
  final String category;
  final bool isPublic;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? authorId;
  final String? authorName;

  Prompt({
    required this.id,
    required this.title,
    required this.content,
    required this.description,
    required this.category,
    this.isPublic = false,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
    this.authorId,
    this.authorName,
  });

  factory Prompt.fromJson(Map<String, dynamic> json) {
    // Generate a placeholder ID if ID is missing or empty
    final id = json['id'] ?? '';
    
    return Prompt(
      id: id,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Uncategorized',
      isPublic: json['is_public'] ?? false,
      isFavorite: json['is_favorite'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      authorId: json['author_id'],
      authorName: json['author_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'description': description,
      'category': category,
      'is_public': isPublic,
      'is_favorite': isFavorite,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'author_id': authorId,
      'author_name': authorName,
    };
  }
  
  // Create a copy with updated fields
  Prompt copyWith({
    String? id,
    String? title,
    String? content,
    String? description,
    String? category,
    bool? isPublic,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorId,
    String? authorName,
  }) {
    return Prompt(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      description: description ?? this.description,
      category: category ?? this.category,
      isPublic: isPublic ?? this.isPublic,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
    );
  }
}