import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/auth/auth_service.dart';
import '../models/bot_configuration.dart';
import 'bot_analytics_service.dart';

/// Service for managing bot integrations with external platforms like Slack, Telegram, and Messenger.
/// 
/// This service provides functionality to:
/// - Get configurations for all platforms
/// - Test connections to platforms
/// - Update platform configurations
/// - Get platform-specific settings
class BotIntegrationService {
  static final BotIntegrationService _instance = BotIntegrationService._internal();
  
  factory BotIntegrationService() => _instance;
    final Logger _logger = Logger();
  final AuthService _authService = AuthService();
  final BotAnalyticsService _analyticsService = BotAnalyticsService();
  
  BotIntegrationService._internal();
  
  /// Fetches all configurations for a bot across all platforms
  /// 
  /// Returns a map where keys are platform identifiers and values are configurations
  Future<Map<String, dynamic>> getConfigurations(String assistantId) async {
    try {
      _logger.i('Fetching configurations for bot $assistantId');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-jarvis-guid': _generateGuid(),
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = '/v1/bot-integration/$assistantId/configurations';
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Request URI: $uri');
      
      // Send request
      final response = await http.get(uri, headers: headers);
      
      _logger.i('Get configurations response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Configurations fetched successfully');
        return data;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return getConfigurations(assistantId);
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to fetch configurations: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        throw 'Failed to fetch configurations: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error fetching configurations: $e');
      rethrow;
    }
  }
  
  /// Updates a platform configuration for a bot
  Future<Map<String, dynamic>> updateConfiguration(
    String assistantId,
    String platform,
    Map<String, dynamic> configuration
  ) async {
    try {
      _logger.i('Updating configuration for bot $assistantId on $platform');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'x-jarvis-guid': _generateGuid(),
      };
      
      // Build request body
      final Map<String, dynamic> body = {
        'platform': platform,
        'configuration': configuration,
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = '/v1/bot-integration/$assistantId/configurations';
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      
      // Send request
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      _logger.i('Update configuration response status: ${response.statusCode}');
        if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Configuration updated successfully for $platform');
        
        // Track analytics for configuration update
        _analyticsService.trackEvent(
          botId: assistantId,
          platform: platform,
          eventType: 'configuration_update',
          eventData: {'fields_updated': configuration.keys.toList()},
        );
        
        return data;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return updateConfiguration(assistantId, platform, configuration);
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to update configuration: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        throw 'Failed to update configuration: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error updating configuration: $e');
      rethrow;
    }
  }
  
  /// Tests connection to a specific platform
  Future<Map<String, dynamic>> testConnection(
    String assistantId,
    String platform
  ) async {
    try {
      _logger.i('Testing connection for bot $assistantId on $platform');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-jarvis-guid': _generateGuid(),
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = '/v1/bot-integration/$assistantId/test-connection/$platform';
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      
      // Send request
      final response = await http.get(uri, headers: headers);
      
      _logger.i('Test connection response status: ${response.statusCode}');
        if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Connection test completed for $platform');
        
        // Track analytics for connection test
        _analyticsService.trackEvent(
          botId: assistantId,
          platform: platform,
          eventType: 'connection_test',
          eventData: {'success': true},
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
          return testConnection(assistantId, platform);
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Connection test failed: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        return {
          'success': false,
          'message': 'Connection test failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      _logger.e('Error testing connection: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
  
  /// Get platform-specific settings required for integration
  Map<String, PlatformConfigSettings> getPlatformConfigSettings() {
    return {      'slack': PlatformConfigSettings(
        displayName: 'Slack',
        icon: 'chat_bubble_outline',
        color: 0xFF4A154B,
        requiredFields: [
          ConfigField(name: 'token', label: 'Bot Token', hint: 'xoxb-...', isRequired: true),
          ConfigField(name: 'channel', label: 'Default Channel ID', hint: 'C01234567', isRequired: false),
          ConfigField(name: 'webhookUrl', label: 'Webhook URL', hint: 'https://your-domain.com/webhook/slack', isRequired: false),
        ],
        description: 'Connect your bot to Slack workspaces',
        setupInstructions: '''
1. Go to https://api.slack.com/apps
2. Create a new app or select an existing one
3. Navigate to "OAuth & Permissions" and add these scopes:
   - chat:write
   - chat:write.public
   - channels:history
   - channels:read
   - groups:history
   - groups:read
4. Install the app to your workspace
5. Copy the Bot User OAuth Token that starts with 'xoxb-'
''',
        documentationUrl: 'https://api.slack.com/bot-users',
      ),      'telegram': PlatformConfigSettings(
        displayName: 'Telegram',
        icon: 'send',
        color: 0xFF0088CC,
        requiredFields: [
          ConfigField(name: 'token', label: 'Bot Token', hint: '123456789:AAHn...', isRequired: true),
          ConfigField(name: 'webhookUrl', label: 'Webhook URL', hint: 'https://your-domain.com/webhook/telegram', isRequired: false),
        ],
        description: 'Connect your bot to Telegram',
        setupInstructions: '''
1. Open Telegram and search for @BotFather
2. Send the command /newbot
3. Follow the steps to create a new bot
4. Copy the HTTP API token that looks like '123456789:AAHn...'
''',
        documentationUrl: 'https://core.telegram.org/bots/api',
      ),      'messenger': PlatformConfigSettings(
        displayName: 'Facebook Messenger',
        icon: 'facebook',
        color: 0xFF0084FF,
        requiredFields: [
          ConfigField(name: 'pageAccessToken', label: 'Page Access Token', hint: '', isRequired: true),
          ConfigField(name: 'appSecret', label: 'App Secret', hint: '', isRequired: true),
          ConfigField(name: 'verifyToken', label: 'Verify Token', hint: 'Custom verification token', isRequired: true),
        ],
        description: 'Connect your bot to Facebook Messenger',
        setupInstructions: '''
1. Create a Facebook App at https://developers.facebook.com/apps
2. Add the Messenger product to your app
3. Configure a Facebook Page for your app
4. Generate a Page Access Token
5. In the app settings, find your App Secret
6. Create a custom verification token
7. Configure webhook events to point to your bot URL with the verification token
''',
        documentationUrl: 'https://developers.facebook.com/docs/messenger-platform/getting-started',
      ),
    };
  }
  
  /// Generate a unique identifier for API requests
  String _generateGuid() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = now % 1000000;
    return '$now-$random-bot-integration';
  }
}
