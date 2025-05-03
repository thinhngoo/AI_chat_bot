import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../../../core/services/auth/auth_service.dart';
import 'api_constants.dart';
import '../models/subscription_model.dart';
import '../models/usage_stats.dart';
import '../models/pricing_model.dart';

class SubscriptionService {
  final AuthService _authService;
  final Logger _logger;
  
  Subscription? _currentSubscription;
  UsageStats? _usageStats;
  
  // Constructor with dependency injection
  SubscriptionService(this._authService, this._logger);
  
  // Get the current subscription
  Future<Subscription> getCurrentSubscription({bool forceRefresh = false}) async {
    if (_currentSubscription != null && !forceRefresh) {
      return _currentSubscription!;
    }
    
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        throw 'User not logged in';
      }
      
      final token = _authService.accessToken;
      if (token == null) {
        throw 'No access token available';
      }
      
      final url = Uri.parse('${ApiConstants.subscriptionBaseUrl}/current');
      final headers = {
        'Authorization': 'Bearer $token',
      };
      
      _logger.i('Getting current subscription from: $url');
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final subscription = Subscription.fromJson(data);
        
        // Cache the subscription
        await _cacheSubscriptionData(subscription);
        
        _currentSubscription = subscription;
        return subscription;
      } else {
        _logger.e('Failed to get subscription: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        // Try to get cached data if available
        final cachedSubscription = await _getCachedSubscription();
        if (cachedSubscription != null) {
          _currentSubscription = cachedSubscription;
          return cachedSubscription;
        }
        
        throw 'Failed to get subscription';
      }
    } catch (e) {
      _logger.e('Error getting subscription: $e');
      
      // Try to get cached data if available
      final cachedSubscription = await _getCachedSubscription();
      if (cachedSubscription != null) {
        _currentSubscription = cachedSubscription;
        return cachedSubscription;
      }
      
      // Return a default free subscription if all else fails
      return _getDefaultSubscription();
    }
  }

  Future<UsageStats> getUsageStats({bool forceRefresh = false}) async {
    if (_usageStats != null && !forceRefresh) {
      return _usageStats!;
    }
    
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        throw 'User not logged in';
      }
      
      // Check if the user is a Pro user first
      final subscription = await getCurrentSubscription(forceRefresh: forceRefresh);
      if (subscription.isPro) {
        // For Pro users, create a stats object with unlimited tokens
        final unlimitedStats = UsageStats(
          totalTokensUsed: subscription.features['currentUsage'] ?? 0,
          totalTokensLimit: -1, // Unlimited
          currentPeriodTokensUsed: subscription.features['currentPeriodUsage'] ?? 0,
          periodStart: DateTime.now().subtract(const Duration(days: 30)),
          periodEnd: DateTime.now().add(const Duration(days: 30)),
          modelBreakdown: {
            'gpt-4o': (subscription.features['modelUsage']?['gpt-4o'] as num?)?.toInt() ?? 0,
            'gpt-4o-mini': (subscription.features['modelUsage']?['gpt-4o-mini'] as num?)?.toInt() ?? 0,
            'claude-3-haiku': (subscription.features['modelUsage']?['claude-3-haiku'] as num?)?.toInt() ?? 0,
          },
        );
        
        _usageStats = unlimitedStats;
        return unlimitedStats;
      }
      
      // For free users, get actual usage stats from API
      final token = _authService.accessToken;
      if (token == null) {
        throw 'No access token available';
      }
      
      final url = Uri.parse('${ApiConstants.jarvisApiUrl}/api/v1/usage/stats');
      final headers = {
        'Authorization': 'Bearer $token',
      };
      
      _logger.i('Getting usage statistics from: $url');
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final usageStats = UsageStats.fromJson(data);
        
        // Cache the usage stats
        await _cacheUsageStats(usageStats);
        
        _usageStats = usageStats;
        return usageStats;
      } else {
        _logger.e('Failed to get usage statistics: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        // Try to get cached data if available
        final cachedStats = await _getCachedUsageStats();
        if (cachedStats != null) {
          _usageStats = cachedStats;
          return cachedStats;
        }
        
        throw 'Failed to get usage statistics';
      }
    } catch (e) {
      _logger.e('Error getting usage statistics: $e');
      
      // Try to get cached data if available
      final cachedStats = await _getCachedUsageStats();
      if (cachedStats != null) {
        _usageStats = cachedStats;
        return cachedStats;
      }
      
      // Return a default UsageStats object if all else fails
      return _getDefaultUsageStats();
    }
  }
  
  // Get available pricing plans
  Future<List<PricingPlan>> getAvailablePlans() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        throw 'User not logged in';
      }
      
      final token = _authService.accessToken;
      if (token == null) {
        throw 'No access token available';
      }
      
      // In a real implementation, we would fetch this from the API:
      // final url = Uri.parse('${ApiConstants.subscriptionBaseUrl}/plans');
      // final headers = {
      //   'Authorization': 'Bearer $token',
      // };
      // 
      // final response = await http.get(url, headers: headers);
      // 
      // if (response.statusCode == 200) {
      //   final data = jsonDecode(response.body) as List<dynamic>;
      //   return data.map((item) => PricingPlan.fromJson(item)).toList();
      // }
      
      // For demonstration, use default plans
      return PricingPlan.getDefaultPlans();
    } catch (e) {
      _logger.e('Error getting pricing plans: $e');
      
      // Return default plans if there's an error
      return PricingPlan.getDefaultPlans();
    }
  }
  
  // Upgrade to Pro subscription
  Future<bool> upgradeToPro({required String paymentMethodId, required bool isYearly}) async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        throw 'User not logged in';
      }
      
      final token = _authService.accessToken;
      if (token == null) {
        throw 'No access token available';
      }
      
      // For the direct API implementation we would call:
      // final url = Uri.parse('${ApiConstants.subscriptionBaseUrl}/upgrade');
      // final headers = {
      //   'Authorization': 'Bearer $token',
      //   'Content-Type': 'application/json',
      // };
      // 
      // final requestBody = {
      //   'planId': 'pro',
      //   'paymentMethodId': paymentMethodId,
      //   'billingCycle': isYearly ? 'yearly' : 'monthly',
      // };
      
      // For testing, we'll simulate a successful API call
      // This would be replaced by the actual API call in production
      await Future.delayed(const Duration(seconds: 1));
      
      // Create a new Pro subscription object
      final DateTime now = DateTime.now();
      final DateTime endDate = isYearly 
          ? now.add(const Duration(days: 365)) 
          : now.add(const Duration(days: 30));
      
      final proSubscription = Subscription(
        id: 'pro_subscription_${DateTime.now().millisecondsSinceEpoch}',
        plan: SubscriptionPlan.pro,
        startDate: now,
        endDate: endDate,
        isActive: true,
        autoRenew: true,
        features: {
          'tokenLimit': -1, // Unlimited 
          'maxBots': -1,    // Unlimited
          'allowedModels': ['gpt-4o', 'gpt-4o-mini', 'claude-3-haiku', 'claude-3-sonnet', 'gemini-1.5-pro'],
          'currentUsage': 0,
          'currentPeriodUsage': 0,
          'modelUsage': {
            'gpt-4o': 0,
            'gpt-4o-mini': 0,
            'claude-3-haiku': 0,
          },
        },
      );
      
      // Cache the subscription
      await _cacheSubscriptionData(proSubscription);
      _currentSubscription = proSubscription;
      
      _logger.i('Subscription upgrade successful (simulated)');
      return true;
    } catch (e) {
      _logger.e('Error upgrading subscription: $e');
      throw 'Error upgrading subscription: $e';
    }
  }
  
  // Toggle auto-renewal setting
  Future<bool> toggleAutoRenewal(bool enabled) async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        throw 'User not logged in';
      }
      
      final subscription = await getCurrentSubscription();
      if (subscription.isFree) {
        throw 'Free subscription cannot have auto-renewal settings';
      }
      
      final token = _authService.accessToken;
      if (token == null) {
        throw 'No access token available';
      }
      
      // In a real implementation, we would make an API call:
      // final url = Uri.parse('${ApiConstants.subscriptionBaseUrl}/auto-renewal');
      // final headers = {
      //   'Authorization': 'Bearer $token',
      //   'Content-Type': 'application/json',
      // };
      // 
      // final requestBody = {
      //   'enabled': enabled,
      // };
      // 
      // final response = await http.put(
      //   url, 
      //   headers: headers,
      //   body: jsonEncode(requestBody),
      // );
      
      // For testing, we'll simulate a successful API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Update the cached subscription
      final updatedSubscription = Subscription(
        id: subscription.id,
        plan: subscription.plan,
        startDate: subscription.startDate,
        endDate: subscription.endDate,
        isActive: subscription.isActive,
        autoRenew: enabled, // Updated value
        features: subscription.features,
      );
      
      await _cacheSubscriptionData(updatedSubscription);
      _currentSubscription = updatedSubscription;
      
      _logger.i('Auto-renewal setting updated: $enabled');
      return true;
    } catch (e) {
      _logger.e('Error toggling auto-renewal: $e');
      return false;
    }
  }
  
  // Cancel subscription
  Future<bool> cancelSubscription() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        throw 'User not logged in';
      }
      
      final subscription = await getCurrentSubscription();
      if (subscription.isFree) {
        throw 'Free subscription cannot be cancelled';
      }
      
      final token = _authService.accessToken;
      if (token == null) {
        throw 'No access token available';
      }
      
      // In a real implementation, we would make an API call:
      // final url = Uri.parse('${ApiConstants.subscriptionBaseUrl}/cancel');
      // final headers = {
      //   'Authorization': 'Bearer $token',
      // };
      // 
      // final response = await http.post(url, headers: headers);
      
      // For testing, we'll simulate a successful API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Create a free subscription to replace the pro one
      final freeSubscription = _getDefaultSubscription();
      
      await _cacheSubscriptionData(freeSubscription);
      _currentSubscription = freeSubscription;
      
      _logger.i('Subscription cancelled successfully');
      return true;
    } catch (e) {
      _logger.e('Error cancelling subscription: $e');
      return false;
    }
  }

  // Cache subscription to shared preferences
  Future<void> _cacheSubscriptionData(Subscription subscription) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(subscription.toJson());
      await prefs.setString('cached_subscription', jsonData);
      _logger.d('Subscription data cached');
    } catch (e) {
      _logger.e('Error caching subscription data: $e');
    }
  }
  
  // Get cached subscription
  Future<Subscription?> _getCachedSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString('cached_subscription');
      
      if (jsonData == null) {
        return null;
      }
      
      final data = jsonDecode(jsonData);
      return Subscription.fromJson(data);
    } catch (e) {
      _logger.e('Error getting cached subscription: $e');
      return null;
    }
  }
  
  // Cache usage stats to shared preferences
  Future<void> _cacheUsageStats(UsageStats stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(stats.toJson());
      await prefs.setString('cached_usage_stats', jsonData);
      _logger.d('Usage stats cached');
    } catch (e) {
      _logger.e('Error caching usage stats: $e');
    }
  }
  
  // Get cached usage stats
  Future<UsageStats?> _getCachedUsageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString('cached_usage_stats');
      
      if (jsonData == null) {
        return null;
      }
      
      final data = jsonDecode(jsonData);
      return UsageStats.fromJson(data);
    } catch (e) {
      _logger.e('Error getting cached usage stats: $e');
      return null;
    }
  }
  
  // Default objects for fallback
  
  Subscription _getDefaultSubscription() {
    return Subscription(
      id: 'free',
      plan: SubscriptionPlan.free,
      startDate: DateTime.now(),
      isActive: true,
      features: {
        'tokenLimit': 10000,
        'maxBots': 3,
        'allowedModels': ['gpt-4o-mini'],
        'currentUsage': 0,
        'currentPeriodUsage': 0,
        'modelUsage': {
          'gpt-4o-mini': 0,
        },
      },
    );
  }
  
  UsageStats _getDefaultUsageStats() {
    return UsageStats(
      totalTokensUsed: 0,
      totalTokensLimit: 10000,
      currentPeriodTokensUsed: 0,
      periodStart: DateTime.now().subtract(const Duration(days: 30)),
      periodEnd: DateTime.now(),
      modelBreakdown: {
        'gpt-4o-mini': 0,
      },
    );
  }
}