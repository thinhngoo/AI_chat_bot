import 'package:intl/intl.dart';
import 'subscription_model.dart';

class PricingPlan {
  final String id;
  final String name;
  final String description;
  final SubscriptionPlan planType;
  final double monthlyPrice;
  final double yearlyPrice;
  final List<String> features;
  
  const PricingPlan({
    required this.id,
    required this.name, 
    required this.description,
    required this.planType,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
  });
  
  // Calculate the effective monthly price when paying yearly
  double get monthlyPriceYearly => yearlyPrice / 12;
  
  // Calculate savings percentage for yearly vs monthly
  double get yearlySavingsPercent => 
      (1 - (yearlyPrice / (monthlyPrice * 12))) * 100;
  
  // Format prices as string with currency symbol
  String get formattedMonthlyPrice => 
      NumberFormat.currency(symbol: '\$').format(monthlyPrice);
      
  String get formattedMonthlyPriceYearly => 
      NumberFormat.currency(symbol: '\$').format(monthlyPriceYearly);
      
  String get formattedAnnualPrice => 
      NumberFormat.currency(symbol: '\$').format(yearlyPrice);
  
  // Get default plans for the app
  static List<PricingPlan> getDefaultPlans() {
    return [
      // Free plan
      PricingPlan(
        id: 'free',
        name: 'Free Plan',
        description: 'Basic access with limited features',
        planType: SubscriptionPlan.free,
        monthlyPrice: 0,
        yearlyPrice: 0,
        features: [
          'Access to GPT-4o Mini model',
          '10,000 tokens per month',
          'Maximum of 3 custom bots',
          'Standard response time',
        ],
      ),
      
      // Pro plan
      PricingPlan(
        id: 'pro',
        name: 'Pro Unlimited',
        description: 'Full access to all premium features',
        planType: SubscriptionPlan.pro,
        monthlyPrice: 9.99,
        yearlyPrice: 99.99, // ~$8.33/month, ~17% discount
        features: [
          'Unlimited tokens',
          'Access to all AI models (GPT-4o, Claude, etc.)',
          'Unlimited custom bots',
          'Priority response time',
          'Advanced model settings',
          'No ads',
          'Email and priority support',
        ],
      ),
    ];
  }
  
  // Convert from JSON
  factory PricingPlan.fromJson(Map<String, dynamic> json) {
    return PricingPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      planType: _parseSubscriptionType(json['planType'] as String),
      monthlyPrice: (json['monthlyPrice'] as num).toDouble(),
      yearlyPrice: (json['yearlyPrice'] as num).toDouble(),
      features: (json['features'] as List).map((e) => e as String).toList(),
    );
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'planType': planType.toString().split('.').last,
      'monthlyPrice': monthlyPrice,
      'yearlyPrice': yearlyPrice,
      'features': features,
    };
  }
  
  // Helper to parse subscription type from string
  static SubscriptionPlan _parseSubscriptionType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'pro':
        return SubscriptionPlan.pro;
      default:
        return SubscriptionPlan.free;
    }
  }
}