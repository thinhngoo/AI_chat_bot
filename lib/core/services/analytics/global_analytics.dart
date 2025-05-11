import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';

/// A global utility class for easier access to analytics functions throughout the app
class GlobalAnalytics {
  static final GlobalAnalytics _instance = GlobalAnalytics._internal();

  factory GlobalAnalytics() => _instance;

  final AnalyticsService _analyticsService = AnalyticsService();
  final Logger _logger = Logger();
  static const String ANALYTICS_ENABLED_KEY = 'analytics_enabled';

  GlobalAnalytics._internal();

  /// Initialize the analytics service and check user preferences
  Future<void> initialize() async {
    try {
      // First initialize the AnalyticsService
      await _analyticsService.initialize();
      
      // Then check if the user has opted out
      final prefs = await SharedPreferences.getInstance();
      final analyticsEnabled = prefs.getBool(ANALYTICS_ENABLED_KEY) ?? true;
      
      // Apply user preference
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(analyticsEnabled);
      
      _logger.i('GlobalAnalytics initialized. Analytics enabled: $analyticsEnabled');
    } catch (e) {
      _logger.e('Error initializing GlobalAnalytics: $e');
    }
  }

  /// Track a screen view
  Future<void> trackScreenView(String screenName, {String? screenClass}) async {
    try {
      await _analyticsService.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      _logger.e('Error tracking screen view: $e');
    }
  }

  /// Track a custom event
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    try {
      await _analyticsService.analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
    } catch (e) {
      _logger.e('Error tracking event: $e');
    }
  }

  /// Track an error
  Future<void> trackError(String errorType, String errorMessage, {String? source, Map<String, dynamic>? additionalData}) async {
    try {
      await _analyticsService.logError(
        errorType: errorType,
        errorMessage: errorMessage,
        errorSource: source,
        additionalData: additionalData,
      );
    } catch (e) {
      _logger.e('Error tracking error: $e');
    }
  }

  /// Set a user property
  Future<void> setUserProperty(String name, String? value) async {
    try {
      await _analyticsService.setUserProperty(
        name: name,
        value: value,
      );
    } catch (e) {
      _logger.e('Error setting user property: $e');
    }
  }

  /// Set user ID for analytics
  Future<void> setUserId(String? userId) async {
    try {
      await _analyticsService.setUserId(userId);
    } catch (e) {
      _logger.e('Error setting user ID: $e');
    }
  }

  /// Check if analytics is enabled
  Future<bool> isAnalyticsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(ANALYTICS_ENABLED_KEY) ?? true;
    } catch (e) {
      _logger.e('Error checking if analytics is enabled: $e');
      return false;
    }
  }
}
