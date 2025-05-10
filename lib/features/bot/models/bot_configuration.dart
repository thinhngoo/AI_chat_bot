/// Represents configuration settings required for a specific platform
class PlatformConfigSettings {
  /// Display name of the platform (e.g., "Slack")
  final String displayName;
  
  /// Icon identifier for the platform
  final String icon;
  
  /// Brand color for the platform (in hex format)
  final int color;
  
  /// List of configuration fields required by the platform
  final List<ConfigField> requiredFields;
  
  /// General description of the integration
  final String description;
  
  /// Step-by-step instructions for setting up the integration
  final String setupInstructions;
  
  /// URL to the platform's API documentation
  final String documentationUrl;

  PlatformConfigSettings({
    required this.displayName,
    required this.icon,
    required this.color,
    required this.requiredFields,
    required this.description,
    required this.setupInstructions,
    this.documentationUrl = '',
  });
}

/// Represents a single configuration field for a platform integration
class ConfigField {
  /// API field name
  final String name;
  
  /// Human-readable field label
  final String label;
  
  /// Example or hint text
  final String hint;
  
  /// Whether the field is required
  final bool isRequired;
  
  /// Whether the field should be masked (e.g., for passwords/tokens)
  final bool isMasked;

  ConfigField({
    required this.name,
    required this.label,
    required this.hint,
    required this.isRequired,
    this.isMasked = false,
  });
}

/// Represents a bot configuration for a specific platform
class BotConfiguration {
  /// Platform identifier (e.g., "slack", "telegram")
  final String platform;
  
  /// Whether the configuration has been set up
  final bool isConfigured;
  
  /// Whether the bot is currently published to this platform
  final bool isPublished;
  
  /// Configuration values (tokens, IDs, etc.)
  final Map<String, dynamic> values;
  
  /// Additional platform-specific details
  final Map<String, dynamic> details;
  
  /// Embed code (for web integrations)
  final String? embedCode;

  BotConfiguration({
    required this.platform,
    required this.isConfigured,
    required this.isPublished, 
    required this.values,
    this.details = const {},
    this.embedCode,
  });
  
  factory BotConfiguration.fromJson(Map<String, dynamic> json) {
    return BotConfiguration(
      platform: json['platform'],
      isConfigured: json['configured'] ?? false,
      isPublished: json['published'] ?? false,
      values: json['values'] ?? {},
      details: json['details'] ?? {},
      embedCode: json['embed_code'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'configured': isConfigured,
      'published': isPublished,
      'values': values,
      'details': details,
      if (embedCode != null) 'embed_code': embedCode,
    };
  }
}
