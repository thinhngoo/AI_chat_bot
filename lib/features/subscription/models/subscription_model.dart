import 'package:intl/intl.dart';

enum SubscriptionPlan {
  free,
  pro,
}

class Subscription {
  final String id;
  final SubscriptionPlan plan;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool autoRenew;
  final Map<String, dynamic> features;

  const Subscription({
    required this.id,
    required this.plan,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.autoRenew = false,
    required this.features,
  });

  // Convert from JSON
  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      plan: _parsePlan(json['plan']),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      isActive: json['isActive'] as bool? ?? true,
      autoRenew: json['autoRenew'] as bool? ?? false,
      features: json['features'] as Map<String, dynamic>? ?? {},
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan': plan.toString().split('.').last,
      'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      'isActive': isActive,
      'autoRenew': autoRenew,
      'features': features,
    };
  }

  // Helper to parse plan type from string
  static SubscriptionPlan _parsePlan(String planStr) {
    switch (planStr.toLowerCase()) {
      case 'pro':
        return SubscriptionPlan.pro;
      default:
        return SubscriptionPlan.free;
    }
  }

  // Helper properties
  bool get isPro => plan == SubscriptionPlan.pro && isActive;
  bool get isFree => plan == SubscriptionPlan.free;
  bool get hasExpired => endDate != null && endDate!.isBefore(DateTime.now());
}