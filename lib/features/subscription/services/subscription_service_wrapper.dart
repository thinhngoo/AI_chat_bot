import 'dart:async';
import 'package:logger/logger.dart';
import '../../../core/services/auth/auth_service.dart';
import '../models/subscription_model.dart';
import '../models/usage_stats.dart';
import '../models/token_usage_model.dart';
import '../models/subscription_info_model.dart';
import '../models/pricing_model.dart';
import 'subscription_service.dart' as legacy;
import 'subscription_service_fixed.dart' as improved;

/// A wrapper class that provides a smooth transition between old and new SubscriptionService implementations,
/// gradually migrating to the improved version while maintaining fallback capabilities.
class SubscriptionServiceWrapper {
  static final SubscriptionServiceWrapper _instance = SubscriptionServiceWrapper._internal();
  factory SubscriptionServiceWrapper() => _instance;

  final Logger _logger = Logger();
  final AuthService _authService = AuthService();
  
  // Service instances
  late final legacy.SubscriptionService _legacyService;
  late final improved.SubscriptionService _improvedService;
  
  // Feature flag for controlling the usage of improved service
  bool _useImprovedService = true;
  
  // Stream controllers for forwarding refresh status from the improved service
  final StreamController<bool> _subscriptionRefreshingController = StreamController<bool>.broadcast();
  final StreamController<bool> _usageStatsRefreshingController = StreamController<bool>.broadcast();
  final StreamController<bool> _tokenUsageRefreshingController = StreamController<bool>.broadcast();
  final StreamController<bool> _subscriptionInfoRefreshingController = StreamController<bool>.broadcast();
  
  // Stream getters
  Stream<bool> get subscriptionRefreshingStream => _subscriptionRefreshingController.stream;
  Stream<bool> get usageStatsRefreshingStream => _usageStatsRefreshingController.stream;
  Stream<bool> get tokenUsageRefreshingStream => _tokenUsageRefreshingController.stream;
  Stream<bool> get subscriptionInfoRefreshingStream => _subscriptionInfoRefreshingController.stream;
  
  // Constructor
  SubscriptionServiceWrapper._internal() {
    _legacyService = legacy.SubscriptionService(_authService, _logger);
    _improvedService = improved.SubscriptionService(_authService, _logger);
    
    // Forward stream events from improved service
    _improvedService.subscriptionRefreshingStream.listen(_subscriptionRefreshingController.add);
    _improvedService.usageStatsRefreshingStream.listen(_usageStatsRefreshingController.add);
    _improvedService.tokenUsageRefreshingStream.listen(_tokenUsageRefreshingController.add);
    _improvedService.subscriptionInfoRefreshingStream.listen(_subscriptionInfoRefreshingController.add);
  }
  
  // Set whether to use the improved service implementation
  // This can be controlled by a remote config flag in the future
  void setUseImprovedService(bool useImproved) {
    _useImprovedService = useImproved;
    _logger.i('Using ${useImproved ? 'improved' : 'legacy'} subscription service implementation');
  }
  
  // Cleanup resources
  void dispose() {
    _subscriptionRefreshingController.close();
    _usageStatsRefreshingController.close();
    _tokenUsageRefreshingController.close();
    _subscriptionInfoRefreshingController.close();
    _improvedService.dispose();
  }
  // Clear all caches
  void clearCache() {
    try {
      // The legacy service may not have clearCache
      try {
        // Use dynamic to bypass compile-time checking
        (_legacyService as dynamic).clearCache();
        _logger.i('Legacy subscription service cache cleared');
      } catch (e) {
        _logger.w('Legacy subscription service does not support clearCache: $e');
      }
      
      _improvedService.clearCache();
      _logger.i('Subscription service caches cleared');
    } catch (e) {
      _logger.e('Error clearing subscription service caches: $e');
    }
  }
  
  // Get current subscription with fallback mechanism
  Future<Subscription> getCurrentSubscription({bool forceRefresh = false}) async {
    if (_useImprovedService) {
      try {
        return await _improvedService.getCurrentSubscription(forceRefresh: forceRefresh);
      } catch (e) {
        _logger.w('Error using improved getCurrentSubscription, falling back to legacy: $e');
        try {
          return await _legacyService.getCurrentSubscription(forceRefresh: forceRefresh);
        } catch (e2) {
          _logger.e('Both subscription services failed: $e2');
          rethrow;
        }
      }
    } else {
      return _legacyService.getCurrentSubscription(forceRefresh: forceRefresh);
    }
  }
  
  // Get usage stats with fallback mechanism
  Future<UsageStats> getUsageStats({bool forceRefresh = false}) async {
    if (_useImprovedService) {
      try {
        return await _improvedService.getUsageStats(forceRefresh: forceRefresh);
      } catch (e) {
        _logger.w('Error using improved getUsageStats, falling back to legacy: $e');
        try {
          return await _legacyService.getUsageStats(forceRefresh: forceRefresh);
        } catch (e2) {
          _logger.e('Both subscription services failed: $e2');
          rethrow;
        }
      }
    } else {
      return _legacyService.getUsageStats(forceRefresh: forceRefresh);
    }
  }
  
  // Get subscription info with fallback mechanism
  Future<SubscriptionInfoModel> getSubscriptionInfo({bool forceRefresh = false}) async {
    if (_useImprovedService) {
      try {
        return await _improvedService.getSubscriptionInfo(forceRefresh: forceRefresh);
      } catch (e) {
        _logger.w('Error using improved getSubscriptionInfo, falling back to legacy: $e');
        try {
          return await _legacyService.getSubscriptionInfo(forceRefresh: forceRefresh);
        } catch (e2) {
          _logger.e('Both subscription services failed: $e2');
          rethrow;
        }
      }
    } else {
      return _legacyService.getSubscriptionInfo(forceRefresh: forceRefresh);
    }
  }
  
  // Get token usage with fallback mechanism
  Future<TokenUsageModel> getTokenUsage({bool forceRefresh = false}) async {
    if (_useImprovedService) {
      try {
        return await _improvedService.getTokenUsage(forceRefresh: forceRefresh);
      } catch (e) {
        _logger.w('Error using improved getTokenUsage, falling back to legacy: $e');
        try {
          return await _legacyService.getTokenUsage(forceRefresh: forceRefresh);
        } catch (e2) {
          _logger.e('Both subscription services failed: $e2');
          rethrow;
        }
      }
    } else {
      return _legacyService.getTokenUsage(forceRefresh: forceRefresh);
    }
  }
  
  // Get available plans with fallback mechanism
  Future<List<PricingPlan>> getAvailablePlans() async {
    if (_useImprovedService) {
      try {
        return await _improvedService.getAvailablePlans();
      } catch (e) {
        _logger.w('Error using improved getAvailablePlans, falling back to legacy: $e');
        try {
          return await _legacyService.getAvailablePlans();
        } catch (e2) {
          _logger.e('Both subscription services failed: $e2');
          rethrow;
        }
      }
    } else {
      return _legacyService.getAvailablePlans();
    }
  }
  
  // Upgrade to Pro with fallback mechanism
  Future<bool> upgradeToPro({required String paymentMethodId, required bool isYearly}) async {
    if (_useImprovedService) {
      try {
        return await _improvedService.upgradeToPro(
          paymentMethodId: paymentMethodId,
          isYearly: isYearly
        );
      } catch (e) {
        _logger.w('Error using improved upgradeToPro, falling back to legacy: $e');
        try {
          return await _legacyService.upgradeToPro(
            paymentMethodId: paymentMethodId,
            isYearly: isYearly
          );
        } catch (e2) {
          _logger.e('Both subscription services failed: $e2');
          rethrow;
        }
      }
    } else {
      return _legacyService.upgradeToPro(
        paymentMethodId: paymentMethodId,
        isYearly: isYearly
      );
    }
  }
  
  // Toggle auto renewal with fallback mechanism
  Future<bool> toggleAutoRenewal(bool enabled) async {
    if (_useImprovedService) {
      try {
        return await _improvedService.toggleAutoRenewal(enabled);
      } catch (e) {
        _logger.w('Error using improved toggleAutoRenewal, falling back to legacy: $e');
        try {
          return await _legacyService.toggleAutoRenewal(enabled);
        } catch (e2) {
          _logger.e('Both subscription services failed: $e2');
          rethrow;
        }
      }
    } else {
      return _legacyService.toggleAutoRenewal(enabled);
    }
  }
  
  // Cancel subscription with fallback mechanism
  Future<bool> cancelSubscription() async {
    if (_useImprovedService) {
      try {
        return await _improvedService.cancelSubscription();
      } catch (e) {
        _logger.w('Error using improved cancelSubscription, falling back to legacy: $e');
        try {
          return await _legacyService.cancelSubscription();
        } catch (e2) {
          _logger.e('Both subscription services failed: $e2');
          rethrow;
        }
      }
    } else {
      return _legacyService.cancelSubscription();
    }
  }
  
  // Subscribe with fallback mechanism
  Future<bool> subscribe() async {
    if (_useImprovedService) {
      try {
        return await _improvedService.subscribe();
      } catch (e) {
        _logger.w('Error using improved subscribe, falling back to legacy: $e');
        try {
          return await _legacyService.subscribe();
        } catch (e2) {
          _logger.e('Both subscription services failed: $e2');
          rethrow;
        }
      }
    } else {
      return _legacyService.subscribe();
    }
  }
}
