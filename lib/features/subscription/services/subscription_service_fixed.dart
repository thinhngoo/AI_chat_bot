import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/constants/api_constants.dart' as core_api;
import 'api_constants.dart' as local_api;
import '../models/subscription_model.dart';
import '../models/usage_stats.dart';
import '../models/pricing_model.dart';
import '../models/token_usage_model.dart';
import '../models/subscription_info_model.dart';

class SubscriptionService {
  final AuthService _authService;
  final Logger _logger;
  
  // Cache-related properties with tiered expiration system
  Subscription? _currentSubscription;
  UsageStats? _usageStats;
  TokenUsageModel? _tokenUsage;
  SubscriptionInfoModel? _subscriptionInfo;
  DateTime? _lastSubscriptionFetchTime;
  DateTime? _lastUsageStatsFetchTime;
  DateTime? _lastTokenUsageFetchTime;
  DateTime? _lastSubscriptionInfoFetchTime;
  
  // Prevent multiple simultaneous refresh requests
  bool _isRefreshingSubscription = false;
  bool _isRefreshingUsageStats = false;
  bool _isRefreshingTokenUsage = false;
  bool _isRefreshingSubscriptionInfo = false;
  
  // Stream controllers for notifying listeners about refresh status
  final StreamController<bool> _subscriptionRefreshingController = StreamController<bool>.broadcast();
  final StreamController<bool> _usageStatsRefreshingController = StreamController<bool>.broadcast();
  final StreamController<bool> _tokenUsageRefreshingController = StreamController<bool>.broadcast();
  final StreamController<bool> _subscriptionInfoRefreshingController = StreamController<bool>.broadcast();
  
  // Getter streams for UI to observe refresh status
  Stream<bool> get subscriptionRefreshingStream => _subscriptionRefreshingController.stream;
  Stream<bool> get usageStatsRefreshingStream => _usageStatsRefreshingController.stream;
  Stream<bool> get tokenUsageRefreshingStream => _tokenUsageRefreshingController.stream;
  Stream<bool> get subscriptionInfoRefreshingStream => _subscriptionInfoRefreshingController.stream;
  
  // Different timeout levels for better performance
  static const Duration _normalTimeoutDuration = Duration(seconds: 8); 
  static const Duration _backgroundTimeoutDuration = Duration(seconds: 15);
  
  // Tiered cache expiration strategies
  static const Duration _cacheStaleThreshold = Duration(minutes: 1);  // Time when cache becomes stale but still usable
  static const Duration _cacheHardExpiration = Duration(minutes: 3);  // Time when cache must be refreshed
  
  // Constructor with dependency injection
  SubscriptionService(this._authService, this._logger);
  
  // Cleanup resources
  void dispose() {
    _subscriptionRefreshingController.close();
    _usageStatsRefreshingController.close();
    _tokenUsageRefreshingController.close();
    _subscriptionInfoRefreshingController.close();
  }
  
  // Clear all caches (useful on logout)
  void clearCache() {
    _currentSubscription = null;
    _usageStats = null;
    _tokenUsage = null;
    _subscriptionInfo = null;
    _lastSubscriptionFetchTime = null;
    _lastUsageStatsFetchTime = null;
    _lastTokenUsageFetchTime = null;
    _lastSubscriptionInfoFetchTime = null;
    _logger.i('All subscription service caches cleared');
  }
  
  // Get the current subscription
  Future<Subscription> getCurrentSubscription({bool forceRefresh = false}) async {
    // If we have a cached subscription and not forcing refresh, do a stale check
    if (_currentSubscription != null && !forceRefresh) {
      if (_isCacheStale(_lastSubscriptionFetchTime)) {
        // Trigger background refresh but still return cached data
        _refreshSubscriptionInBackground();
      }
      return _currentSubscription!;
    }
    
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        _logger.w('User not logged in, returning free subscription');
        return _getDefaultSubscription();
      }
      
      final token = _authService.accessToken;
      if (token == null) {
        _logger.w('No access token available, returning free subscription');
        return _getDefaultSubscription();
      }
      
      final url = Uri.parse('${local_api.ApiConstants.subscriptionBaseUrl}/current');
      final headers = {
        'Authorization': 'Bearer $token',
      };
      
      _logger.i('Getting current subscription from: $url');
      _setRefreshingStatus(_subscriptionRefreshingController, true);
      
      // Set a timeout for the API request with improved error handling
      final response = await http.get(url, headers: headers)
          .timeout(_normalTimeoutDuration, onTimeout: () {
        _logger.w('API request timed out after ${_normalTimeoutDuration.inSeconds}s');
        throw 'Connection timed out';
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final subscription = Subscription.fromJson(data);
        
        // Cache the subscription and update fetch time
        await _cacheSubscriptionData(subscription);
        _lastSubscriptionFetchTime = DateTime.now();
        _currentSubscription = subscription;
        return subscription;
      } else {
        _logger.e('Failed to get subscription: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        // Try to get cached data if available
        final cachedSubscription = await _getCachedSubscription();
        if (cachedSubscription != null) {
          _logger.i('Using cached subscription data');
          _currentSubscription = cachedSubscription;
          return cachedSubscription;
        }
        
        _logger.w('No cached subscription available, returning free subscription');
        return _getDefaultSubscription();
      }
    } catch (e) {
      _logger.e('Error getting subscription: $e');
      
      // Try to get cached data if available
      final cachedSubscription = await _getCachedSubscription();
      if (cachedSubscription != null) {
        _logger.i('Using cached subscription data after error');
        _currentSubscription = cachedSubscription;
        return cachedSubscription;
      }
      
      // Return a default free subscription if all else fails
      _logger.w('Falling back to default free subscription');
      final defaultSubscription = _getDefaultSubscription();
      _currentSubscription = defaultSubscription;
      return defaultSubscription;
    } finally {
      _setRefreshingStatus(_subscriptionRefreshingController, false);
    }
  }

  // Background refresh for subscription data
  Future<void> _refreshSubscriptionInBackground() async {
    if (_isRefreshingSubscription) return; // Prevent multiple simultaneous refreshes
    
    try {
      final token = _authService.accessToken;
      if (token == null) return;
      
      final url = Uri.parse('${local_api.ApiConstants.subscriptionBaseUrl}/current');
      final headers = {
        'Authorization': 'Bearer $token',
      };
      
      _logger.i('Background refreshing subscription data');
      _setRefreshingStatus(_subscriptionRefreshingController, true);
      
      // Use longer timeout for background operations
      final response = await http.get(url, headers: headers)
          .timeout(_backgroundTimeoutDuration, onTimeout: () {
        _logger.w('Background refresh timed out after ${_backgroundTimeoutDuration.inSeconds}s');
        throw 'Background refresh timed out';
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final subscription = Subscription.fromJson(data);
        
        await _cacheSubscriptionData(subscription);
        _lastSubscriptionFetchTime = DateTime.now();
        _currentSubscription = subscription;
        _logger.i('Background subscription refresh completed successfully');
      }
    } catch (e) {
      _logger.w('Background subscription refresh failed: $e');
      // No need to throw, this is a background operation
    } finally {
      _setRefreshingStatus(_subscriptionRefreshingController, false);
    }
  }

  // Get usage statistics
  Future<UsageStats> getUsageStats({bool forceRefresh = false}) async {
    // If we have cached stats and not forcing refresh, do a stale check
    if (_usageStats != null && !forceRefresh) {
      if (_isCacheStale(_lastUsageStatsFetchTime)) {
        // Trigger background refresh but still return cached data
        _refreshUsageStatsInBackground();
      }
      return _usageStats!;
    }
    
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        _logger.w('User not logged in, returning default usage stats');
        return _getDefaultUsageStats();
      }
      
      // Check if the user is a Pro user first
      final subscription = await getCurrentSubscription(forceRefresh: false);
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
        _lastUsageStatsFetchTime = DateTime.now();
        return unlimitedStats;
      }
      
      final token = _authService.accessToken;
      if (token == null) {
        _logger.w('No access token available, returning default usage stats');
        return _getDefaultUsageStats();
      }
      
      final url = Uri.parse('${local_api.ApiConstants.jarvisApiUrl}/api/v1/usage/stats');
      final headers = {
        'Authorization': 'Bearer $token',
      };
      
      _logger.i('Getting usage statistics from: $url');
      _setRefreshingStatus(_usageStatsRefreshingController, true);
      
      // Set a timeout to prevent long waits when API is down
      final response = await http.get(url, headers: headers)
          .timeout(_normalTimeoutDuration, onTimeout: () {
        _logger.w('Usage stats API request timed out after ${_normalTimeoutDuration.inSeconds}s');
        throw 'Connection timed out';
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final usageStats = UsageStats.fromJson(data);
        
        // Cache the usage stats and update fetch time
        await _cacheUsageStats(usageStats);
        _lastUsageStatsFetchTime = DateTime.now();
        _usageStats = usageStats;
        return usageStats;
      } else {
        _logger.e('Failed to get usage statistics: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        // Try to get cached data if available
        final cachedStats = await _getCachedUsageStats();
        if (cachedStats != null) {
          _logger.i('Using cached usage stats');
          _usageStats = cachedStats;
          return cachedStats;
        }
        
        _logger.w('No cached usage stats available, returning default stats');
        final defaultStats = _getDefaultUsageStats();
        _usageStats = defaultStats;
        return defaultStats;
      }
    } catch (e) {
      _logger.e('Error getting usage statistics: $e');
      
      // Try to get cached data if available
      final cachedStats = await _getCachedUsageStats();
      if (cachedStats != null) {
        _logger.i('Using cached usage stats after error');
        _usageStats = cachedStats;
        return cachedStats;
      }
      
      // Return a default UsageStats object if all else fails
      _logger.w('Falling back to default usage stats');
      final defaultStats = _getDefaultUsageStats();
      _usageStats = defaultStats;
      return defaultStats;
    } finally {
      _setRefreshingStatus(_usageStatsRefreshingController, false);
    }
  }

  // Background refresh for usage stats
  Future<void> _refreshUsageStatsInBackground() async {
    if (_isRefreshingUsageStats) return; // Prevent multiple simultaneous refreshes
    
    try {
      final token = _authService.accessToken;
      if (token == null) return;
      
      // We don't need to refresh for Pro users as they have unlimited tokens
      final subscription = await getCurrentSubscription(forceRefresh: false);
      if (subscription.isPro) return;
      
      final url = Uri.parse('${local_api.ApiConstants.jarvisApiUrl}/api/v1/usage/stats');
      final headers = {
        'Authorization': 'Bearer $token',
      };
      
      _logger.i('Background refreshing usage stats');
      _setRefreshingStatus(_usageStatsRefreshingController, true);
      
      // Use longer timeout for background operations
      final response = await http.get(url, headers: headers)
          .timeout(_backgroundTimeoutDuration, onTimeout: () {
        _logger.w('Background usage stats refresh timed out');
        throw 'Background refresh timed out';
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final usageStats = UsageStats.fromJson(data);
        
        await _cacheUsageStats(usageStats);
        _lastUsageStatsFetchTime = DateTime.now();
        _usageStats = usageStats;
        _logger.i('Background usage stats refresh completed successfully');
      }
    } catch (e) {
      _logger.w('Background usage stats refresh failed: $e');
      // No need to throw, this is a background operation
    } finally {
      _setRefreshingStatus(_usageStatsRefreshingController, false);
    }
  }

  // Get subscription info from /v1/subscriptions/me endpoint
  Future<SubscriptionInfoModel> getSubscriptionInfo({bool forceRefresh = false}) async {
    if (_subscriptionInfo != null && !forceRefresh) {
      if (_isCacheStale(_lastSubscriptionInfoFetchTime)) {
        // Trigger background refresh but still return cached data
        _refreshSubscriptionInfoInBackground();
      }
      return _subscriptionInfo!;
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
      
      final url = Uri.parse('${core_api.ApiConstants.jarvisApiUrl}${core_api.ApiConstants.subscriptionMeEndpoint}');
      final headers = {
        'Authorization': 'Bearer $token',
        'x-jarvis-guid': '',
      };
      
      _logger.i('Getting subscription info from: $url');
      _setRefreshingStatus(_subscriptionInfoRefreshingController, true);
      
      final response = await http.get(url, headers: headers)
          .timeout(_normalTimeoutDuration, onTimeout: () {
        _logger.w('Subscription info API request timed out after ${_normalTimeoutDuration.inSeconds}s');
        throw 'Connection timed out';
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final subscriptionInfo = SubscriptionInfoModel.fromJson(data);
        
        // Cache the subscription info and update fetch time
        await _cacheSubscriptionInfoData(subscriptionInfo);
        _lastSubscriptionInfoFetchTime = DateTime.now();
        _subscriptionInfo = subscriptionInfo;
        return subscriptionInfo;
      } else {
        _logger.e('Failed to get subscription info: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        // Try to get cached data if available
        final cachedInfo = await _getCachedSubscriptionInfo();
        if (cachedInfo != null) {
          _logger.i('Using cached subscription info');
          _subscriptionInfo = cachedInfo;
          return cachedInfo;
        }
        
        throw 'Failed to get subscription info: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error getting subscription info: $e');
      
      // Try to get cached data if available
      final cachedInfo = await _getCachedSubscriptionInfo();
      if (cachedInfo != null) {
        _logger.i('Using cached subscription info after error');
        _subscriptionInfo = cachedInfo;
        return cachedInfo;
      }
      
      // Return a default if all else fails
      final defaultInfo = _getDefaultSubscriptionInfo();
      _subscriptionInfo = defaultInfo;
      return defaultInfo;
    } finally {
      _setRefreshingStatus(_subscriptionInfoRefreshingController, false);
    }
  }
  
  // Background refresh for subscription info
  Future<void> _refreshSubscriptionInfoInBackground() async {
    if (_isRefreshingSubscriptionInfo) return; // Prevent multiple simultaneous refreshes
    
    try {
      final token = _authService.accessToken;
      if (token == null) return;
      
      final url = Uri.parse('${core_api.ApiConstants.jarvisApiUrl}${core_api.ApiConstants.subscriptionMeEndpoint}');
      final headers = {
        'Authorization': 'Bearer $token',
        'x-jarvis-guid': '',
      };
      
      _logger.i('Background refreshing subscription info');
      _setRefreshingStatus(_subscriptionInfoRefreshingController, true);
      
      // Use longer timeout for background operations
      final response = await http.get(url, headers: headers)
          .timeout(_backgroundTimeoutDuration, onTimeout: () {
        _logger.w('Background subscription info refresh timed out');
        throw 'Background refresh timed out';
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final subscriptionInfo = SubscriptionInfoModel.fromJson(data);
        
        await _cacheSubscriptionInfoData(subscriptionInfo);
        _lastSubscriptionInfoFetchTime = DateTime.now();
        _subscriptionInfo = subscriptionInfo;
        _logger.i('Background subscription info refresh completed successfully');
      }
    } catch (e) {
      _logger.w('Background subscription info refresh failed: $e');
      // No need to throw, this is a background operation
    } finally {
      _setRefreshingStatus(_subscriptionInfoRefreshingController, false);
    }
  }

  // Get token usage from /v1/tokens/usage endpoint
  Future<TokenUsageModel> getTokenUsage({bool forceRefresh = false}) async {
    if (_tokenUsage != null && !forceRefresh) {
      if (_isCacheStale(_lastTokenUsageFetchTime)) {
        // Trigger background refresh but still return cached data
        _refreshTokenUsageInBackground();
      }
      return _tokenUsage!;
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
      
      final url = Uri.parse('${core_api.ApiConstants.jarvisApiUrl}${core_api.ApiConstants.tokenUsageEndpoint}');
      final headers = {
        'Authorization': 'Bearer $token',
        'x-jarvis-guid': '',
      };
      
      _logger.i('Getting token usage from: $url');
      _setRefreshingStatus(_tokenUsageRefreshingController, true);
      
      final response = await http.get(url, headers: headers)
          .timeout(_normalTimeoutDuration, onTimeout: () {
        _logger.w('Token usage API request timed out after ${_normalTimeoutDuration.inSeconds}s');
        throw 'Connection timed out';
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tokenUsage = TokenUsageModel.fromJson(data);
        
        // Cache the token usage and update fetch time
        await _cacheTokenUsageData(tokenUsage);
        _lastTokenUsageFetchTime = DateTime.now();
        _tokenUsage = tokenUsage;
        return tokenUsage;
      } else {
        _logger.e('Failed to get token usage: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        // Try to get cached data if available
        final cachedUsage = await _getCachedTokenUsage();
        if (cachedUsage != null) {
          _logger.i('Using cached token usage');
          _tokenUsage = cachedUsage;
          return cachedUsage;
        }
        
        throw 'Failed to get token usage: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error getting token usage: $e');
      
      // Try to get cached data if available
      final cachedUsage = await _getCachedTokenUsage();
      if (cachedUsage != null) {
        _logger.i('Using cached token usage after error');
        _tokenUsage = cachedUsage;
        return cachedUsage;
      }
      
      // Return a default if all else fails
      final defaultUsage = _getDefaultTokenUsage();
      _tokenUsage = defaultUsage;
      return defaultUsage;
    } finally {
      _setRefreshingStatus(_tokenUsageRefreshingController, false);
    }
  }
  
  // Background refresh for token usage
  Future<void> _refreshTokenUsageInBackground() async {
    if (_isRefreshingTokenUsage) return; // Prevent multiple simultaneous refreshes
    
    try {
      final token = _authService.accessToken;
      if (token == null) return;
      
      final url = Uri.parse('${core_api.ApiConstants.jarvisApiUrl}${core_api.ApiConstants.tokenUsageEndpoint}');
      final headers = {
        'Authorization': 'Bearer $token',
        'x-jarvis-guid': '',
      };
      
      _logger.i('Background refreshing token usage');
      _setRefreshingStatus(_tokenUsageRefreshingController, true);
      
      // Use longer timeout for background operations
      final response = await http.get(url, headers: headers)
          .timeout(_backgroundTimeoutDuration, onTimeout: () {
        _logger.w('Background token usage refresh timed out');
        throw 'Background refresh timed out';
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tokenUsage = TokenUsageModel.fromJson(data);
        
        await _cacheTokenUsageData(tokenUsage);
        _lastTokenUsageFetchTime = DateTime.now();
        _tokenUsage = tokenUsage;
        _logger.i('Background token usage refresh completed successfully');
      }
    } catch (e) {
      _logger.w('Background token usage refresh failed: $e');
      // No need to throw, this is a background operation
    } finally {
      _setRefreshingStatus(_tokenUsageRefreshingController, false);
    }
  }
  
  // Helper method to set refreshing status
  void _setRefreshingStatus(StreamController<bool> controller, bool isRefreshing) {
    if (controller == _subscriptionRefreshingController) {
      _isRefreshingSubscription = isRefreshing;
    } else if (controller == _usageStatsRefreshingController) {
      _isRefreshingUsageStats = isRefreshing;
    } else if (controller == _tokenUsageRefreshingController) {
      _isRefreshingTokenUsage = isRefreshing;
    } else if (controller == _subscriptionInfoRefreshingController) {
      _isRefreshingSubscriptionInfo = isRefreshing;
    }
    
    controller.add(isRefreshing);
  }
  
  // Helper method to check if cache is stale
  bool _isCacheStale(DateTime? lastFetchTime) {
    if (lastFetchTime == null) return true;
    final currentTime = DateTime.now();
    final difference = currentTime.difference(lastFetchTime);
    return difference >= _cacheStaleThreshold;
  }
  
  // Helper method to check if cache is hard expired
  bool _isCacheExpired(DateTime? lastFetchTime) {
    if (lastFetchTime == null) return true;
    final currentTime = DateTime.now();
    final difference = currentTime.difference(lastFetchTime);
    return difference >= _cacheHardExpiration;
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
      // final response = await http.get(url, headers: headers)
      //     .timeout(_normalTimeoutDuration, onTimeout: () {
      //   throw 'Connection timed out';
      // });
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
      // 
      // final response = await http.post(
      //   url, 
      //   headers: headers,
      //   body: jsonEncode(requestBody),
      // ).timeout(_normalTimeoutDuration, onTimeout: () {
      //   throw 'Connection timed out';
      // });
      
      // For testing, we'll simulate a successful API call
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
      
      // Cache the subscription and update fetch time
      await _cacheSubscriptionData(proSubscription);
      _lastSubscriptionFetchTime = DateTime.now();
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
      // ).timeout(_normalTimeoutDuration, onTimeout: () {
      //   throw 'Connection timed out';
      // });
      
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
      _lastSubscriptionFetchTime = DateTime.now();
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
      // final response = await http.post(url, headers: headers)
      //     .timeout(_normalTimeoutDuration, onTimeout: () {
      //   throw 'Connection timed out';
      // });
      
      // For testing, we'll simulate a successful API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Create a free subscription to replace the pro one
      final freeSubscription = _getDefaultSubscription();
      
      await _cacheSubscriptionData(freeSubscription);
      _lastSubscriptionFetchTime = DateTime.now();
      _currentSubscription = freeSubscription;
      
      _logger.i('Subscription cancelled successfully');
      return true;
    } catch (e) {
      _logger.e('Error cancelling subscription: $e');
      return false;
    }
  }

  // Subscribe to Pro plan
  Future<bool> subscribe() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        throw 'User not logged in';
      }
      
      final token = _authService.accessToken;
      if (token == null) {
        throw 'No access token available';
      }
      
      final url = Uri.parse('${core_api.ApiConstants.jarvisApiUrl}${core_api.ApiConstants.subscriptionSubscribeEndpoint}');
      final headers = {
        'Authorization': 'Bearer $token',
        'x-jarvis-guid': '',
      };
      
      _logger.i('Subscribing user at: $url');
      
      final response = await http.get(url, headers: headers)
          .timeout(_normalTimeoutDuration, onTimeout: () {
        _logger.w('Subscribe API request timed out');
        throw 'Connection timed out';
      });
      
      if (response.statusCode == 200) {
        _logger.i('Subscription successful');
        
        // Refresh subscription info and token usage data
        await getSubscriptionInfo(forceRefresh: true);
        await getTokenUsage(forceRefresh: true);
        
        return true;
      } else {
        _logger.e('Failed to subscribe: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.e('Error subscribing: $e');
      return false;
    }
  }
  
  // Cache subscription to shared preferences
  Future<void> _cacheSubscriptionData(Subscription subscription) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(subscription.toJson());
      await prefs.setString('cached_subscription', jsonData);
      await prefs.setString('subscription_cache_time', DateTime.now().toIso8601String());
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
      final cacheTimeStr = prefs.getString('subscription_cache_time');
      
      if (jsonData == null) {
        return null;
      }
      
      // Check if cache is expired (hard expiration)
      if (cacheTimeStr != null) {
        final cacheTime = DateTime.parse(cacheTimeStr);
        if (_isCacheExpired(cacheTime)) {
          _logger.d('Cached subscription data is hard expired');
          return null;
        }
      }
      
      final data = jsonDecode(jsonData);
      final subscription = Subscription.fromJson(data);
      
      // Update last fetch time from cache
      if (cacheTimeStr != null) {
        _lastSubscriptionFetchTime = DateTime.parse(cacheTimeStr);
      }
      
      return subscription;
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
      await prefs.setString('usage_stats_cache_time', DateTime.now().toIso8601String());
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
      final cacheTimeStr = prefs.getString('usage_stats_cache_time');
      
      if (jsonData == null) {
        return null;
      }
      
      // Check if cache is expired (hard expiration)
      if (cacheTimeStr != null) {
        final cacheTime = DateTime.parse(cacheTimeStr);
        if (_isCacheExpired(cacheTime)) {
          _logger.d('Cached usage stats are hard expired');
          return null;
        }
      }
      
      final data = jsonDecode(jsonData);
      final usageStats = UsageStats.fromJson(data);
      
      // Update last fetch time from cache
      if (cacheTimeStr != null) {
        _lastUsageStatsFetchTime = DateTime.parse(cacheTimeStr);
      }
      
      return usageStats;
    } catch (e) {
      _logger.e('Error getting cached usage stats: $e');
      return null;
    }
  }
  
  // Cache and retrieve subscription info data
  Future<void> _cacheSubscriptionInfoData(SubscriptionInfoModel info) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(info.toJson());
      await prefs.setString('cached_subscription_info', jsonData);
      await prefs.setString('subscription_info_cache_time', DateTime.now().toIso8601String());
      _logger.d('Subscription info cached');
    } catch (e) {
      _logger.e('Error caching subscription info: $e');
    }
  }
  
  Future<SubscriptionInfoModel?> _getCachedSubscriptionInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString('cached_subscription_info');
      final cacheTimeStr = prefs.getString('subscription_info_cache_time');
      
      if (jsonData == null) {
        return null;
      }
      
      // Check if cache is expired (hard expiration)
      if (cacheTimeStr != null) {
        final cacheTime = DateTime.parse(cacheTimeStr);
        if (_isCacheExpired(cacheTime)) {
          _logger.d('Cached subscription info is hard expired');
          return null;
        }
      }
      
      final data = jsonDecode(jsonData);
      final subscriptionInfo = SubscriptionInfoModel.fromJson(data);
      
      // Update last fetch time from cache
      if (cacheTimeStr != null) {
        _lastSubscriptionInfoFetchTime = DateTime.parse(cacheTimeStr);
      }
      
      return subscriptionInfo;
    } catch (e) {
      _logger.e('Error getting cached subscription info: $e');
      return null;
    }
  }
  
  // Cache and retrieve token usage data
  Future<void> _cacheTokenUsageData(TokenUsageModel usage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(usage.toJson());
      await prefs.setString('cached_token_usage', jsonData);
      await prefs.setString('token_usage_cache_time', DateTime.now().toIso8601String());
      _logger.d('Token usage cached');
    } catch (e) {
      _logger.e('Error caching token usage: $e');
    }
  }
  
  Future<TokenUsageModel?> _getCachedTokenUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString('cached_token_usage');
      final cacheTimeStr = prefs.getString('token_usage_cache_time');
      
      if (jsonData == null) {
        return null;
      }
      
      // Check if cache is expired (hard expiration)
      if (cacheTimeStr != null) {
        final cacheTime = DateTime.parse(cacheTimeStr);
        if (_isCacheExpired(cacheTime)) {
          _logger.d('Cached token usage is hard expired');
          return null;
        }
      }
      
      final data = jsonDecode(jsonData);
      final tokenUsage = TokenUsageModel.fromJson(data);
      
      // Update last fetch time from cache
      if (cacheTimeStr != null) {
        _lastTokenUsageFetchTime = DateTime.parse(cacheTimeStr);
      }
      
      return tokenUsage;
    } catch (e) {
      _logger.e('Error getting cached token usage: $e');
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
  
  SubscriptionInfoModel _getDefaultSubscriptionInfo() {
    return SubscriptionInfoModel(
      name: 'Free',
      dailyTokens: 50,
      monthlyTokens: 1500,
      annuallyTokens: 18000,
    );
  }
  
  TokenUsageModel _getDefaultTokenUsage() {
    return TokenUsageModel(
      availableTokens: 50,
      totalTokens: 50,
      unlimited: false,
      date: DateTime.now(),
    );
  }
}
