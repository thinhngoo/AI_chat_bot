class KnowledgeBase {
  final String id;
  final String name;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<KnowledgeSource> sources;

  KnowledgeBase({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.sources = const [],
  });

  factory KnowledgeBase.fromJson(Map<String, dynamic> json) {
    return KnowledgeBase(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      sources: json['sources'] != null
          ? (json['sources'] as List)
              .map((source) => KnowledgeSource.fromJson(source))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sources': sources.map((source) => source.toJson()).toList(),
    };
  }
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