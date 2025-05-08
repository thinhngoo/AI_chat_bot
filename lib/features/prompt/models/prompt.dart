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
    return Prompt(
      id: json['_id'] ?? '', // Changed from 'id' to '_id' to match API response
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Uncategorized',
      isPublic: json['isPublic'] ?? false, // Changed from 'is_public' to 'isPublic'
      isFavorite: json['isFavorite'] ?? false, // Changed from 'is_favorite' to 'isFavorite'
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(), // Changed from 'created_at' to 'createdAt'
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(), // Changed from 'updated_at' to 'updatedAt'
      authorId: json['userId'] ?? json['author_id'], // Try both 'userId' and fallback to 'author_id'
      authorName: json['userName'] ?? json['author_name'], // Try both 'userName' and fallback to 'author_name'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id, // Changed from 'id' to '_id' to match API expectations
      'title': title,
      'content': content,
      'description': description,
      'category': category,
      'isPublic': isPublic, // Changed from 'is_public' to 'isPublic'
      'isFavorite': isFavorite, // Changed from 'is_favorite' to 'isFavorite'
      'createdAt': createdAt.toIso8601String(), // Changed from 'created_at' to 'createdAt'
      'updatedAt': updatedAt.toIso8601String(), // Changed from 'updated_at' to 'updatedAt'
      'userId': authorId, // Changed from 'author_id' to 'userId'
      'userName': authorName, // Changed from 'author_name' to 'userName'
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