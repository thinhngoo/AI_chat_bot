class SubscriptionInfoModel {
  final String name;
  final int dailyTokens;
  final int monthlyTokens;
  final int annuallyTokens;
  
  SubscriptionInfoModel({
    required this.name,
    required this.dailyTokens,
    required this.monthlyTokens,
    required this.annuallyTokens,
  });
  
  factory SubscriptionInfoModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfoModel(
      name: json['name'] ?? '',
      dailyTokens: json['dailyTokens'] ?? 0,
      monthlyTokens: json['monthlyTokens'] ?? 0,
      annuallyTokens: json['annuallyTokens'] ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dailyTokens': dailyTokens,
      'monthlyTokens': monthlyTokens,
      'annuallyTokens': annuallyTokens,
    };
  }
  
  // Check if this is a Pro subscription based on name
  bool get isPro => name.toLowerCase().contains('pro');
  
  // Check if tokens are unlimited
  bool get hasUnlimitedTokens => 
      dailyTokens < 0 || 
      monthlyTokens < 0 || 
      annuallyTokens < 0 || 
      (dailyTokens == 0 && monthlyTokens == 0 && annuallyTokens == 0);
}
