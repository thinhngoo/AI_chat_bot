import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/auth/auth_service.dart';
import 'bot_analytics_service.dart';

/// Service for managing webhook configurations for bot integrations
/// 
/// This service handles webhook registration, updates, and validation
/// for different messaging platforms like Slack, Telegram, and Facebook Messenger
class BotWebhookService {
  static final BotWebhookService _instance = BotWebhookService._internal();
  
  factory BotWebhookService() => _instance;
    final Logger _logger = Logger();
  final AuthService _authService = AuthService();
  final BotAnalyticsService _analyticsService = BotAnalyticsService();
  
  BotWebhookService._internal();
  
  /// Register a webhook for a specific platform
  Future<Map<String, dynamic>> registerWebhook(
    String botId,
    String platform,
    String webhookUrl, {
    String? verificationToken,
  }) async {
    try {
      _logger.i('Registering webhook for bot $botId on $platform: $webhookUrl');
      
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
        'platform': platform,
        'webhookUrl': webhookUrl,
        if (verificationToken != null) 'verificationToken': verificationToken,
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = '/v1/bot-integration/$botId/webhook';
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending webhook registration request to: $uri');
      
      // Send request
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      _logger.i('Register webhook response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _logger.i('Webhook registered successfully for $platform');
        
        // Track analytics for webhook registration
        _analyticsService.trackEvent(
          botId: botId,
          platform: platform,
          eventType: 'webhook_registration',
          eventData: {'url': webhookUrl},
        );
        
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return registerWebhook(botId, platform, webhookUrl, verificationToken: verificationToken);
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to register webhook: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        return {
          'success': false,
          'error': 'Failed to register webhook: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      _logger.e('Error registering webhook: $e');
      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }
  
  /// Validate a webhook configuration
  Future<Map<String, dynamic>> validateWebhook(
    String botId,
    String platform,
    String webhookUrl,
  ) async {
    try {
      _logger.i('Validating webhook for bot $botId on $platform: $webhookUrl');
      
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
        'webhookUrl': webhookUrl,
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = '/v1/bot-integration/$botId/webhook/validate/$platform';
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending webhook validation request to: $uri');
      
      // Send request
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      _logger.i('Validate webhook response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Webhook validation result for $platform: ${data['valid']}');
        
        return {
          'success': true,
          'valid': data['valid'] ?? false,
          'details': data['details'] ?? '',
        };
      } else {
        _logger.e('Failed to validate webhook: ${response.statusCode}');
        
        return {
          'success': false,
          'valid': false,
          'error': 'Failed to validate webhook: ${response.statusCode}',
        };
      }
    } catch (e) {
      _logger.e('Error validating webhook: $e');
      return {
        'success': false,
        'valid': false,
        'error': 'Error: $e',
      };
    }
  }
  
  /// Delete a webhook
  Future<bool> deleteWebhook(
    String botId,
    String platform,
  ) async {
    try {
      _logger.i('Deleting webhook for bot $botId on $platform');
      
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
      final endpoint = '/v1/bot-integration/$botId/webhook/$platform';
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending webhook deletion request to: $uri');
      
      // Send request
      final response = await http.delete(uri, headers: headers);
      
      _logger.i('Delete webhook response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        _logger.i('Webhook deleted successfully for $platform');
        
        // Track analytics for webhook deletion
        _analyticsService.trackEvent(
          botId: botId,
          platform: platform,
          eventType: 'webhook_deletion',
        );
        
        return true;
      } else {
        _logger.e('Failed to delete webhook: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('Error deleting webhook: $e');
      return false;
    }
  }
  
  /// Get the current webhook URL for a platform
  Future<String?> getWebhookUrl(
    String botId,
    String platform,
  ) async {
    try {
      _logger.i('Getting webhook URL for bot $botId on $platform');
      
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
      final endpoint = '/v1/bot-integration/$botId/webhook/$platform';
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending get webhook request to: $uri');
      
      // Send request
      final response = await http.get(uri, headers: headers);
      
      _logger.i('Get webhook response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final webhookUrl = data['webhookUrl'] as String?;
        _logger.i('Webhook URL for $platform: $webhookUrl');
        return webhookUrl;
      } else {
        _logger.w('Failed to get webhook URL: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting webhook URL: $e');
      return null;
    }
  }
}
