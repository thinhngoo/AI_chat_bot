import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/auth/auth_service.dart';
import '../models/sharing_config.dart';

/// Service for managing bot sharing functionality with external platforms
class BotSharingService {
  static final BotSharingService _instance = BotSharingService._internal();
  
  factory BotSharingService() => _instance;
    
  final Logger _logger = Logger();
  final AuthService _authService = AuthService();
    BotSharingService._internal() {
    // Add debug initialization log to verify the service is being created correctly
    _logger.d('BotSharingService initialized');
    _logger.d('Using API URL: ${ApiConstants.kbCoreApiUrl}');
    _logger.d('Updated endpoints to match API specification: /kb-core/v1/bot-integration/{platform}/publish');
  }
  
  /// Get all configurations for a bot
  Future<SharingConfig> getConfigurations(String botId) async {
    try {
      _logger.i('Fetching sharing configurations for bot $botId');
      
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
        // Build URL - use knowledge API for bot integration
      const baseUrl = ApiConstants.kbCoreApiUrl;
      final endpoint = '/kb-core/v1/bot-integration/$botId/configurations';
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Request URI: $uri');

      // Add detailed debug log to track exactly what URL we're requesting
      _logger.d('Making GET request to: $uri with headers: ${headers.toString()}');
      
      // Send request
      final response = await http.get(uri, headers: headers);
      
      _logger.i('Get configurations response status: ${response.statusCode}');
        if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Sharing configurations fetched successfully');
        _logger.d('Response data: ${response.body}');
        return SharingConfig.fromJson({
          'botId': botId,
          'platforms': data,
        });
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return getConfigurations(botId);
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to fetch configurations: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        throw 'Failed to fetch configurations: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error fetching sharing configurations: $e');
      rethrow;
    }
  }

  /// Disconnect a bot integration
  Future<bool> disconnectBotIntegration(String botId, String platform) async {
    try {
      _logger.i('Disconnecting bot $botId from $platform integration');
      
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
        // Build URL - use knowledge API for bot integration
      const baseUrl = ApiConstants.kbCoreApiUrl;
      final endpoint = '/kb-core/v1/bot-integration/$platform/disconnect';
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Request URI: $uri');

      // Add detailed debug log to track exactly what URL we're requesting
      _logger.d('Making DELETE request to: $uri with headers: ${headers.toString()}');
        // For DELETE request, we need to include the botId in the request body
      // Use http.Request to be able to include a body with DELETE
      final request = http.Request('DELETE', uri);
      request.headers.addAll(headers);
      request.body = jsonEncode({'botId': botId});
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      _logger.i('Disconnect bot response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        _logger.i('Bot disconnected successfully from $platform');
        return true;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return disconnectBotIntegration(botId, platform);
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to disconnect bot: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        throw 'Failed to disconnect bot: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error disconnecting bot: $e');
      rethrow;
    }
  }

  /// Verify Telegram Bot Configuration
  Future<Map<String, dynamic>> verifyTelegramBotConfig(String botId, Map<String, dynamic> config) async {
    try {
      _logger.i('Verifying Telegram configuration for bot $botId');
      return await _verifyBotConfig(botId, 'telegram', config);
    } catch (e) {
      _logger.e('Error verifying Telegram configuration: $e');
      rethrow;
    }
  }

  /// Publish Telegram Bot
  Future<Map<String, dynamic>> publishTelegramBot(String botId, Map<String, dynamic> config) async {
    try {
      _logger.i('Publishing bot $botId to Telegram');
      return await _publishBot(botId, 'telegram', config);
    } catch (e) {
      _logger.e('Error publishing Telegram bot: $e');
      rethrow;
    }
  }

  /// Verify Slack Bot Configuration
  Future<Map<String, dynamic>> verifySlackBotConfig(String botId, Map<String, dynamic> config) async {
    try {
      _logger.i('Verifying Slack configuration for bot $botId');
      return await _verifyBotConfig(botId, 'slack', config);
    } catch (e) {
      _logger.e('Error verifying Slack configuration: $e');
      rethrow;
    }
  }

  /// Publish Slack Bot
  Future<Map<String, dynamic>> publishSlackBot(String botId, Map<String, dynamic> config) async {
    try {
      _logger.i('Publishing bot $botId to Slack');
      return await _publishBot(botId, 'slack', config);
    } catch (e) {
      _logger.e('Error publishing Slack bot: $e');
      rethrow;
    }
  }

  /// Verify Messenger Bot Configuration
  Future<Map<String, dynamic>> verifyMessengerBotConfig(String botId, Map<String, dynamic> config) async {
    try {
      _logger.i('Verifying Messenger configuration for bot $botId');
      return await _verifyBotConfig(botId, 'messenger', config);
    } catch (e) {
      _logger.e('Error verifying Messenger configuration: $e');
      rethrow;
    }
  }

  /// Publish Messenger Bot
  Future<Map<String, dynamic>> publishMessengerBot(String botId, Map<String, dynamic> config) async {
    try {
      _logger.i('Publishing bot $botId to Messenger');
      return await _publishBot(botId, 'messenger', config);
    } catch (e) {
      _logger.e('Error publishing Messenger bot: $e');
      rethrow;
    }
  }

  // Private helper methods
  
  /// Helper method to verify bot configuration for any platform
  Future<Map<String, dynamic>> _verifyBotConfig(
    String botId, 
    String platform,
    Map<String, dynamic> config
  ) async {
    // Add a diagnostic log to trace execution
    _logger.d('Starting _verifyBotConfig for botId: $botId, platform: $platform');
    
    try {
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
        // Build request body - add botId to the configuration
      final Map<String, dynamic> body = {
        ...config,
        'botId': botId
      };
      
      // Build URL - use knowledge API for bot integration
      const baseUrl = ApiConstants.kbCoreApiUrl;
      final endpoint = '/kb-core/v1/bot-integration/$platform/verify';
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');

      // Add detailed debug log to track exactly what URL we're requesting
      _logger.d('Making POST request to: $uri with headers: ${headers.toString()} and body: ${body.toString()}');
      
      // Send request
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      _logger.i('Verify bot config response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Bot configuration verified successfully for $platform');
        
        return {
          'success': true,
          'verified': true,
          'details': data,
        };
      } else if (response.statusCode == 400) {
        // Invalid configuration but API responded
        final data = jsonDecode(response.body);
        _logger.w('Invalid configuration: ${data['message']}');
        
        return {
          'success': true,
          'verified': false,
          'message': data['message'],
          'details': data,
        };
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return _verifyBotConfig(botId, platform, config);
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to verify configuration: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        return {
          'success': false,
          'verified': false,
          'message': 'Failed to verify configuration: ${response.statusCode}',
        };
      }
    } catch (e) {
      _logger.e('Error verifying bot configuration: $e');
      return {
        'success': false,
        'verified': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Helper method to publish bot to any platform
  Future<Map<String, dynamic>> _publishBot(
    String botId, 
    String platform,
    Map<String, dynamic> config
  ) async {
    try {
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
        // Build request body - add botId to the configuration
      final Map<String, dynamic> body = {
        ...config,
        'botId': botId
      };
      
      // Build URL - use knowledge API for bot integration
      const baseUrl = ApiConstants.kbCoreApiUrl;
      final endpoint = '/kb-core/v1/bot-integration/$platform/publish';
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');

      // Add detailed debug log to track exactly what URL we're requesting
      _logger.d('Making POST request to: $uri with headers: ${headers.toString()} and body: ${body.toString()}');
      
      // Send request
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      _logger.i('Publish bot response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _logger.i('Bot published successfully to $platform');
        
        return {
          'success': true,
          'published': true,
          'details': data,
        };
      } else if (response.statusCode == 400) {
        // Invalid configuration but API responded
        final data = jsonDecode(response.body);
        _logger.w('Invalid configuration for publishing: ${data['message']}');
        
        return {
          'success': true,
          'published': false,
          'message': data['message'],
          'details': data,
        };
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return _publishBot(botId, platform, config);
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to publish bot: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        return {
          'success': false,
          'published': false,
          'message': 'Failed to publish bot: ${response.statusCode}',
        };
      }
    } catch (e) {
      _logger.e('Error publishing bot: $e');
      return {
        'success': false,
        'published': false,
        'message': 'Error: $e',
      };
    }
  }
  
  /// Debug method to validate endpoints - can be removed after fixing the issue
  Future<String> testEndpoints(String botId) async {
    try {
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        return 'No access token available';
      }
      
      final platform = 'messenger'; // Test with messenger platform
      
      final configEndpoint = '/kb-core/v1/bot-integration/$botId/configurations';
      final verifyEndpoint = '/kb-core/v1/bot-integration/$platform/verify';
      final publishEndpoint = '/kb-core/v1/bot-integration/$platform/publish';
      final disconnectEndpoint = '/kb-core/v1/bot-integration/$platform/disconnect';
      
      final baseUrl = ApiConstants.kbCoreApiUrl;
      
      return '''
Endpoints test for botId: $botId
Base URL: $baseUrl
Get Configurations: $baseUrl$configEndpoint
Verify ($platform): $baseUrl$verifyEndpoint
Publish ($platform): $baseUrl$publishEndpoint
Disconnect ($platform): $baseUrl$disconnectEndpoint
''';
    } catch (e) {
      return 'Error testing endpoints: $e';
    }
  }
  
  /// Generate a unique identifier for API requests
  String _generateGuid() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = now % 1000000;
    return '$now-$random-bot-sharing';
  }
}
