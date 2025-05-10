import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/services/auth/auth_service.dart';

/// A service to track analytics for bot usage across different platforms
class BotAnalyticsService {
  static final BotAnalyticsService _instance = BotAnalyticsService._internal();
  
  factory BotAnalyticsService() => _instance;
  
  final Logger _logger = Logger();
  final AuthService _authService = AuthService();
  
  BotAnalyticsService._internal();
  
  /// Track a usage event for a bot on a specific platform
  Future<bool> trackEvent({
    required String botId,
    required String platform,
    required String eventType,
    Map<String, dynamic>? eventData,
  }) async {
    try {
      _logger.i('Tracking $eventType event for bot $botId on $platform');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };
      
      // Build request body
      final Map<String, dynamic> body = {
        'botId': botId,
        'platform': platform,
        'eventType': eventType,
        'timestamp': DateTime.now().toIso8601String(),
        if (eventData != null) 'data': eventData,
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      const endpoint = '/v1/analytics/bot-usage';
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      
      // Send request
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      _logger.i('Track event response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.i('Event tracked successfully');
        return true;
      } else {
        _logger.w('Failed to track event: ${response.statusCode}');
        // Don't throw an error for analytics failures, just return false
        return false;
      }
    } catch (e) {
      _logger.e('Error tracking event: $e');
      // Don't throw an error for analytics failures, just return false
      return false;
    }
  }
  
  /// Get usage statistics for a bot
  Future<Map<String, dynamic>> getUsageStats(String botId) async {
    try {
      _logger.i('Fetching usage stats for bot $botId');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers
      final headers = {
        'Authorization': 'Bearer $accessToken',
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = '/v1/analytics/bot-usage/$botId';
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      
      // Send request
      final response = await http.get(uri, headers: headers);
      
      _logger.i('Get usage stats response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        _logger.e('Failed to fetch usage stats: ${response.statusCode}');
        throw 'Failed to fetch usage statistics: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error fetching usage stats: $e');
      rethrow;
    }
  }
  
  /// Get platform distribution data for a bot
  Future<Map<String, int>> getPlatformDistribution(String botId) async {
    try {
      final stats = await getUsageStats(botId);
      
      if (stats.containsKey('platformDistribution')) {
        return Map<String, int>.from(stats['platformDistribution']);
      } else {
        return {
          'slack': 0,
          'telegram': 0,
          'messenger': 0,
        };
      }
    } catch (e) {
      _logger.e('Error getting platform distribution: $e');
      // Return empty data on error
      return {
        'slack': 0,
        'telegram': 0,
        'messenger': 0,
      };
    }
  }
}
