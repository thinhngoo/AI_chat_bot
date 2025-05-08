class KnowledgeData {
  final String id;
  final String name;
  final String description;
  final KnowledgeType type;
  final String source;
  final int documentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  KnowledgeData({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.source,
    this.documentCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  String get typeDisplayName => type.displayName;

  factory KnowledgeData.fromJson(Map<String, dynamic> json) {
    return KnowledgeData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: _parseKnowledgeType(json['type']),
      source: json['source'] ?? '',
      documentCount: json['documentCount'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'source': source,
    };
  }

  static KnowledgeType _parseKnowledgeType(String? type) {
    if (type == null) return KnowledgeType.document;
    
    switch (type.toLowerCase()) {
      case 'website':
        return KnowledgeType.website;
      case 'googledrive':
        return KnowledgeType.googleDrive;
      case 'slack':
        return KnowledgeType.slack;
      case 'confluence':
        return KnowledgeType.confluence;
      case 'database':
        return KnowledgeType.database;
      case 'api':
        return KnowledgeType.api;
      default:
        return KnowledgeType.document;
    }
  }
}

enum KnowledgeType {
  document,
  website,
  googleDrive,
  slack,
  confluence,
  database,
  api
}

extension KnowledgeTypeExtension on KnowledgeType {
  String get displayName {
    switch (this) {
      case KnowledgeType.document:
        return 'Document';
      case KnowledgeType.website:
        return 'Website';
      case KnowledgeType.googleDrive:
        return 'Google Drive';
      case KnowledgeType.slack:
        return 'Slack';
      case KnowledgeType.confluence:
        return 'Confluence';
      case KnowledgeType.database:
        return 'Database';
      case KnowledgeType.api:
        return 'API';
    }
  }
}
