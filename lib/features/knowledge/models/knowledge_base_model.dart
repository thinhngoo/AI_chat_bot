class KnowledgeBase {
  final String id;
  final String knowledgeName;
  final String description;
  final String status;
  final String? userId;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<KnowledgeSource> sources;

  KnowledgeBase({
    required this.id,
    required this.knowledgeName,
    required this.description,
    this.status = 'pending',
    this.userId,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.sources = const [],
  });

  factory KnowledgeBase.fromJson(Map<String, dynamic> json) {
    // The API may return data in a nested 'data' field or directly
    final data = json['data'] ?? json;
    
    return KnowledgeBase(
      id: data['id'] ?? '',
      knowledgeName: data['knowledgeName'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'pending',
      userId: data['userId'],
      createdBy: data['createdBy'],
      updatedBy: data['updatedBy'],
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt']) 
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? DateTime.parse(data['updatedAt']) 
          : DateTime.now(),
      sources: data['sources'] != null
          ? (data['sources'] as List)
              .map((source) => KnowledgeSource.fromJson(source))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'knowledgeName': knowledgeName,
      'description': description,
      'status': status,
      'userId': userId,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sources': sources.map((source) => source.toJson()).toList(),
    };
  }

  // Add getter for name for backward compatibility
  String get name => knowledgeName;
}

class KnowledgeSource {
  final String id;
  final String type; // file, url, google_drive, slack, confluence
  final String name;
  final String status;
  final String? fileType;
  final int? fileSize;
  final String? url;
  final DateTime? processedAt;
  final DateTime createdAt;

  KnowledgeSource({
    required this.id,
    required this.type,
    required this.name,
    required this.status,
    this.fileType,
    this.fileSize,
    this.url,
    this.processedAt,
    required this.createdAt,
  });

  factory KnowledgeSource.fromJson(Map<String, dynamic> json) {
    return KnowledgeSource(
      id: json['id'],
      type: json['type'],
      name: json['name'],
      status: json['status'],
      fileType: json['fileType'],
      fileSize: json['fileSize'],
      url: json['url'],
      processedAt: json['processedAt'] != null 
          ? DateTime.parse(json['processedAt']) 
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'status': status,
      'fileType': fileType,
      'fileSize': fileSize,
      'url': url,
      'processedAt': processedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}