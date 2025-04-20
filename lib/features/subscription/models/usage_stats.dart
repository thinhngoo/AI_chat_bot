import 'package:intl/intl.dart';

class ModelUsage {
  final String modelName;
  final int tokensUsed;
  final int tokenLimit;
  
  ModelUsage({
    required this.modelName,
    required this.tokensUsed,
    required this.tokenLimit,
  });
  
  // Helper for creating a model usage with unlimited tokens
  factory ModelUsage.unlimited(String modelName, int tokensUsed) {
    return ModelUsage(
      modelName: modelName,
      tokensUsed: tokensUsed,
      tokenLimit: -1, // -1 indicates unlimited
    );
  }
  
  // Percentage of token limit used
  double get usagePercentage {
    if (tokenLimit < 0) return 0.0; // Unlimited
    if (tokenLimit == 0) return 0.0; // Avoid division by zero
    return tokensUsed / tokenLimit;
  }
  
  // Format remaining tokens as a readable string
  String get remainingTokensFormatted {
    if (tokenLimit < 0) {
      return 'Unlimited';
    }
    
    final remaining = tokenLimit - tokensUsed;
    return NumberFormat.compact().format(remaining);
  }
}

class UsageStats {
  final int totalTokensUsed;
  final int totalTokensLimit;
  final int currentPeriodTokensUsed;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, int> modelBreakdown;
  
  UsageStats({
    required this.totalTokensUsed,
    required this.totalTokensLimit,
    required this.currentPeriodTokensUsed, 
    required this.periodStart,
    required this.periodEnd,
    required this.modelBreakdown,
  });
  
  // Create from JSON data
  factory UsageStats.fromJson(Map<String, dynamic> json) {
    return UsageStats(
      totalTokensUsed: json['totalTokensUsed'] ?? 0,
      totalTokensLimit: json['totalTokensLimit'] ?? 10000,
      currentPeriodTokensUsed: json['currentPeriodTokensUsed'] ?? 0,
      periodStart: json['periodStart'] != null 
          ? DateTime.parse(json['periodStart']) 
          : DateTime.now().subtract(const Duration(days: 30)),
      periodEnd: json['periodEnd'] != null 
          ? DateTime.parse(json['periodEnd']) 
          : DateTime.now().add(const Duration(days: 30)),
      modelBreakdown: (json['modelBreakdown'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, (value as num).toInt()))
          ?? {},
    );
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalTokensUsed': totalTokensUsed,
      'totalTokensLimit': totalTokensLimit,
      'currentPeriodTokensUsed': currentPeriodTokensUsed,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'modelBreakdown': modelBreakdown,
    };
  }
  
  // Calculate percentage of token limit used
  double get usagePercentage {
    if (totalTokensLimit < 0) return 0.0; // Unlimited
    if (totalTokensLimit == 0) return 0.0; // Avoid division by zero
    return totalTokensUsed / totalTokensLimit;
  }
  
  // Format total tokens used
  String get formattedTotalTokensUsed {
    return NumberFormat.compact().format(totalTokensUsed);
  }
  
  // Format token limit
  String get formattedTotalTokensLimit {
    if (totalTokensLimit < 0) {
      return 'Unlimited';
    }
    return NumberFormat.compact().format(totalTokensLimit);
  }
  
  // Format period dates
  String get formattedPeriod {
    final dateFormat = DateFormat('MMM d');
    return '${dateFormat.format(periodStart)} - ${dateFormat.format(periodEnd)}';
  }
  
  // Get list of model usage objects
  List<ModelUsage> get modelUsage {
    return modelBreakdown.entries.map((entry) {
      // For unlimited subscriptions, use -1 as token limit
      final isUnlimited = totalTokensLimit < 0;
      
      return ModelUsage(
        modelName: _formatModelName(entry.key),
        tokensUsed: entry.value,
        tokenLimit: isUnlimited ? -1 : _getModelTokenLimit(entry.key),
      );
    }).toList();
  }
  
  // Format model name for better display
  String _formatModelName(String modelId) {
    switch (modelId) {
      case 'gpt-4o':
        return 'GPT-4o';
      case 'gpt-4o-mini':
        return 'GPT-4o Mini';
      case 'claude-3-haiku':
        return 'Claude 3 Haiku';
      case 'claude-3-sonnet':
        return 'Claude 3 Sonnet';
      case 'gemini-1.5-pro':
        return 'Gemini 1.5 Pro';
      default:
        // Capitalize and replace hyphens with spaces
        return modelId
            .split('-')
            .map((word) => word.isEmpty 
                ? '' 
                : word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }
  
  // Get estimated token limit for each model
  // This would typically come from the backend
  int _getModelTokenLimit(String modelId) {
    if (totalTokensLimit < 0) return -1; // Unlimited
    
    // These are just example allocations
    switch (modelId) {
      case 'gpt-4o':
        return (totalTokensLimit * 0.2).round();
      case 'gpt-4o-mini':
        return (totalTokensLimit * 0.4).round();
      case 'claude-3-haiku':
        return (totalTokensLimit * 0.3).round();
      default:
        return (totalTokensLimit * 0.1).round();
    }
  }
  
  // Check if we're using unlimited tokens
  bool get isUnlimited => totalTokensLimit < 0;
  
  // Tokens remaining
  int get tokensRemaining {
    if (totalTokensLimit < 0) return -1; // Unlimited
    return totalTokensLimit - totalTokensUsed;
  }
  
  // Format tokens remaining as a readable string
  String get tokensRemainingFormatted {
    if (totalTokensLimit < 0) {
      return 'Unlimited';
    }
    
    return NumberFormat.compact().format(tokensRemaining);
  }
}