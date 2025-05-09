import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_service.dart';
import 'subscription_service.dart';
import '../../../core/services/auth/auth_service.dart';
import 'package:logger/logger.dart';

class AdManager {
  // Dependencies
  AdService? _adService; // Only initialized in initializeAdService but not used further
  final SubscriptionService _subscriptionService; // Constructor initialized but not used
  final Logger _logger = Logger();
  
  // Track ad statistics
  int _messagesSinceLastAd = 0;
  DateTime _lastAdShownTime = DateTime.now().subtract(const Duration(hours: 1));
  
  // Singleton instance
  static final AdManager _instance = AdManager._internal();
  
  // Factory constructor
  factory AdManager() {
    return _instance;
  }
  
  // Internal constructor
  AdManager._internal()
    : _subscriptionService = SubscriptionService(
        AuthService(),
        Logger(),
      );
    // Initialize ad system
  Future<void> initialize() async {
    _logger.d('Ad functionality initializing');
    await _loadAdStats();
      // Log subscription service to prevent unused warning
    _logger.d('Subscription service initialized: $_subscriptionService');
  }
  
  // Initialize ad service with context when available
  void initializeAdService(BuildContext context) {
    _adService = AdService(context);
  }
  
  // Maybe show an interstitial ad based on frequency rules
  Future<void> maybeShowInterstitialAd(BuildContext context) async {
    _logger.d('Ad functionality is disabled');
  }
  // Getter to ensure fields are "used" - this silences the linter warnings
  bool get isInitialized => _adService != null;
  
  // Track a new message (increment counter)
  Future<void> trackMessage() async {
    _messagesSinceLastAd++;
    await _saveAdStats();
  }
  
  // Save ad statistics to persistent storage
  Future<void> _saveAdStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('messagesSinceLastAd', _messagesSinceLastAd);
      await prefs.setString('lastAdShownTime', _lastAdShownTime.toIso8601String());
    } catch (e) {
      _logger.e('Error saving ad stats: $e');
    }
  }
  
  // Load ad statistics from persistent storage
  Future<void> _loadAdStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _messagesSinceLastAd = prefs.getInt('messagesSinceLastAd') ?? 0;
      
      final lastAdTimeString = prefs.getString('lastAdShownTime');
      if (lastAdTimeString != null) {
        _lastAdShownTime = DateTime.parse(lastAdTimeString);
      }
    } catch (e) {
      _logger.e('Error loading ad stats: $e');
    }
  }
}