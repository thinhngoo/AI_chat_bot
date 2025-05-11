class TokenUsageModel {
  final int availableTokens;
  final int totalTokens;
  final bool unlimited;
  final DateTime date;
  
  TokenUsageModel({
    required this.availableTokens,
    required this.totalTokens,
    required this.unlimited,
    required this.date,
  });
  
  factory TokenUsageModel.fromJson(Map<String, dynamic> json) {
    return TokenUsageModel(
      availableTokens: json['availableTokens'] ?? 0,
      totalTokens: json['totalTokens'] ?? 0,
      unlimited: json['unlimited'] ?? false,
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'availableTokens': availableTokens,
      'totalTokens': totalTokens,
      'unlimited': unlimited,
      'date': date.toIso8601String(),
    };
  }
}
