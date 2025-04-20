import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_service.dart';
import 'subscription_service.dart';
import '../../../core/services/auth/auth_service.dart';
import 'package:logger/logger.dart';

class AdManager {
  // Dependencies
  final AdService _adService;
  final SubscriptionService _subscriptionService;
  final Logger _logger = Logger();
  
  // Constants for ad frequency
  static const int _minMessagesBetweenAds = 5;
  static const double _adProbability = 0.3; // 30% chance
  
  // Track ad statistics
  int _messagesSinceLastAd = 0;
  DateTime _lastAdShownTime = DateTime.now().subtract(const Duration(hours: 1));
  
  // Constructor
  AdManager({
    AdService? adService,
    SubscriptionService? subscriptionService,
    AuthService? authService,
  }) : _adService = adService ?? AdService(),
       _subscriptionService = subscriptionService ?? SubscriptionService(
         authService ?? AuthService(),
         Logger(),
       );
  
  // Initialize ad system
  Future<void> initialize() async {
    // Ad functionality is disabled
    _logger.d('Ad functionality is disabled');
    await _loadAdStats();
  }
  
  // Check if user is eligible to see an ad
  Future<bool> _shouldShowAd() async {
    // Ad functionality is disabled
    return false;
  }
  
  // Maybe show an interstitial ad based on frequency rules
  Future<void> maybeShowInterstitialAd(BuildContext context) async {
    // Ad functionality is disabled
    _logger.d('Ad functionality is disabled');
  }
  
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