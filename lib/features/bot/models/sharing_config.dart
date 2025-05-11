import 'dart:convert';

/// Represents the configuration for sharing a bot across various platforms
class SharingConfig {
  /// ID of the bot being shared
  final String botId;
  
  /// Platform-specific configurations
  final Map<String, PlatformConfig> platforms;
  
  SharingConfig({
    required this.botId,
    required this.platforms,
  });
  
  factory SharingConfig.fromJson(Map<String, dynamic> json) {
    final platformConfigs = <String, PlatformConfig>{};
    
    // Process platform configs
    if (json.containsKey('platforms') && json['platforms'] is Map) {
      (json['platforms'] as Map).forEach((key, value) {
        platformConfigs[key.toString()] = PlatformConfig.fromJson(value);
      });
    }
    
    return SharingConfig(
      botId: json['botId'] ?? '',
      platforms: platformConfigs,
    );
  }
  
  Map<String, dynamic> toJson() {
    final platforms = <String, dynamic>{};
    this.platforms.forEach((key, value) {
      platforms[key] = value.toJson();
    });
    
    return {
      'botId': botId,
      'platforms': platforms,
    };
  }
}

/// Represents the configuration for sharing a bot on a specific platform
class PlatformConfig {
  /// Whether the bot is configured for this platform
  final bool isConfigured;
  
  /// Whether the bot is published on this platform
  final bool isPublished;
  
  /// Verification status of the bot configuration
  final bool isVerified;
  
  /// Configuration details specific to the platform
  final Map<String, dynamic> details;
  
  /// Usage statistics for this platform
  final int usageCount;
  
  /// The embedding code for this platform (if applicable)
  final String? embedCode;
  
  /// The webhook URL for this platform
  final String? webhookUrl;
  
  PlatformConfig({
    required this.isConfigured,
    required this.isPublished,
    required this.isVerified,
    required this.details,
    this.usageCount = 0,
    this.embedCode,
    this.webhookUrl,
  });
  
  factory PlatformConfig.fromJson(Map<String, dynamic> json) {
    return PlatformConfig(
      isConfigured: json['isConfigured'] ?? false,
      isPublished: json['isPublished'] ?? false,
      isVerified: json['isVerified'] ?? false,
      details: json['details'] is Map ? Map<String, dynamic>.from(json['details']) : {},
      usageCount: json['usageCount'] ?? 0,
      embedCode: json['embedCode'],
      webhookUrl: json['webhookUrl'],
    );
  }
  
  Map<String, dynamic> toJson() => {
    'isConfigured': isConfigured,
    'isPublished': isPublished,
    'isVerified': isVerified,
    'details': details,
    'usageCount': usageCount,
    if (embedCode != null) 'embedCode': embedCode,
    if (webhookUrl != null) 'webhookUrl': webhookUrl,
  };
  
  /// Create a copy of this config with updated fields
  PlatformConfig copyWith({
    bool? isConfigured,
    bool? isPublished,
    bool? isVerified,
    Map<String, dynamic>? details,
    int? usageCount,
    String? embedCode,
    String? webhookUrl,
  }) {
    return PlatformConfig(
      isConfigured: isConfigured ?? this.isConfigured,
      isPublished: isPublished ?? this.isPublished,
      isVerified: isVerified ?? this.isVerified,
      details: details ?? Map<String, dynamic>.from(this.details),
      usageCount: usageCount ?? this.usageCount,
      embedCode: embedCode ?? this.embedCode,
      webhookUrl: webhookUrl ?? this.webhookUrl,
    );
  }
}
