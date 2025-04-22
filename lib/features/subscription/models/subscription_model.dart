import 'package:flutter/material.dart';

enum SubscriptionPlan {
  free,
  pro,
  enterprise,
}

class Subscription {
  final String id;
  final SubscriptionPlan plan;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool autoRenew;
  final Map<String, dynamic> features;

  Subscription({
    required this.id,
    required this.plan,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.autoRenew = false,
    required this.features,
  });

  bool get isPro => plan == SubscriptionPlan.pro || plan == SubscriptionPlan.enterprise;
  bool get isFree => plan == SubscriptionPlan.free;
  bool get isExpired => endDate != null && endDate!.isBefore(DateTime.now());
  bool get isRenewing => autoRenew && isPro;

  // Format subscription plan name for display
  String get planName {
    switch (plan) {
      case SubscriptionPlan.free:
        return 'Free';
      case SubscriptionPlan.pro:
        return 'Pro';
      case SubscriptionPlan.enterprise:
        return 'Enterprise';
      default:
        return 'Unknown';
    }
  }

  // Get token limit for the subscription
  int get tokenLimit {
    final limit = features['tokenLimit'];
    if (limit == null) return 0;
    if (limit is int && limit < 0) return -1; // -1 represents unlimited
    if (limit is int) return limit;
    if (limit is String) return int.tryParse(limit) ?? 0;
    return 0;
  }

  // Check if the subscription has unlimited tokens
  bool get hasUnlimitedTokens => tokenLimit < 0;

  // Calculate days remaining in subscription
  int get daysRemaining {
    if (endDate == null) return 0;
    final difference = endDate!.difference(DateTime.now());
    return difference.inDays > 0 ? difference.inDays : 0;
  }

  // Check if subscription ends soon (within 7 days)
  bool get endsSoon => daysRemaining > 0 && daysRemaining <= 7;

  // Create a Subscription object from JSON data
  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      plan: _planFromString(json['plan']),
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isActive: json['isActive'] ?? false,
      autoRenew: json['autoRenew'] ?? false,
      features: json['features'] ?? {},
    );
  }

  // Convert Subscription object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan': plan.toString().split('.').last,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'autoRenew': autoRenew,
      'features': features,
    };
  }

  // Helper method to parse subscription plan from string
  static SubscriptionPlan _planFromString(String? planString) {
    if (planString == null) return SubscriptionPlan.free;
    
    switch (planString.toLowerCase()) {
      case 'pro':
        return SubscriptionPlan.pro;
      case 'enterprise':
        return SubscriptionPlan.enterprise;
      default:
        return SubscriptionPlan.free;
    }
  }
}