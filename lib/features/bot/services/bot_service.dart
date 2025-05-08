// Add to pubspec.yaml:
// http_parser: ^4.0.0
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:logger/logger.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/auth/auth_service.dart';
import '../models/ai_bot.dart';
import '../models/knowledge_data.dart';

class BotService {
  static final BotService _instance = BotService._internal();
  factory BotService() => _instance;

  final Logger _logger = Logger();
  final AuthService _authService = AuthService();
  
  BotService._internal();

  // Create a new AI Bot
  Future<AIBot> createBot({
    required String name,
    required String description,
    required String model,
    required String prompt,
  }) async {
    try {
      _logger.i('Creating AI Bot: $name');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers - changed from const to final
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json'
      };
      
      // Build request body based on API documentation
      final Map<String, dynamic> body = {
        'name': name,
        'description': description,
        'model': model,
        'instructions': prompt,
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      const endpoint = ApiConstants.botsEndpoint;
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      
      // Send request
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      _logger.i('Create bot response status: ${response.statusCode}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Bot created successfully, ID: ${data['id']}');
        return AIBot.fromJson(data);
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return createBot(
            name: name,
            description: description,
            model: model,
            prompt: prompt,
          );
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to create bot: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        String errorMessage = 'Failed to create bot: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // Ignore JSON parsing errors
        }
        
        throw errorMessage;
      }
    } catch (e) {
      _logger.e('Error creating bot: $e');
      rethrow;
    }
  }
  
  // Get all AI Bots
  Future<List<AIBot>> getBots({String? query}) async {
    try {
      _logger.i('Fetching AI Bots');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers - changed from const to final
      final headers = {
        'Authorization': 'Bearer $accessToken',
      };
      
      // Build URL with query parameters
      const baseUrl = ApiConstants.jarvisApiUrl;
      const endpoint = ApiConstants.botsEndpoint;
      
      // Adding pagination parameters which are required by the API
      var queryParams = <String, String>{
        'page': '1',
        'per_page': '100'
      };
      
      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }
      
      final uri = Uri.parse(baseUrl + endpoint).replace(queryParameters: queryParams);
      
      _logger.i('Request URI: $uri');
      
      // Send request
      final response = await http.get(uri, headers: headers);
      
      _logger.i('Get bots response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check if response format is different than expected
        if (data['assistants'] != null) {
          // Original format with 'assistants' array
          final assistants = data['assistants'] as List<dynamic>;
          return assistants.map((item) => AIBot.fromJson(item)).toList();
        } else if (data['items'] != null) {
          // Alternative format with 'items' array
          final items = data['items'] as List<dynamic>;
          return items.map((item) => AIBot.fromJson(item)).toList();
        } else {
          // Empty list if no recognized format
          _logger.w('Unknown response format: $data');
          return [];
        }
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return getBots(query: query);
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to fetch bots: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        throw 'Failed to fetch bots: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error fetching bots: $e');
      rethrow;
    }
  }
  
  // Get a specific AI Bot by ID
  Future<AIBot> getBotById(String botId) async {
    try {
      _logger.i('Fetching AI Bot with ID: $botId');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers - changed from const to final
      final headers = {
        'Authorization': 'Bearer $accessToken',
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = ApiConstants.botById.replaceAll('{botId}', botId);
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Request URI: $uri');
      
      // Send request
      final response = await http.get(uri, headers: headers);
      
      _logger.i('Get bot response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AIBot.fromJson(data);
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return getBotById(botId);
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else if (response.statusCode == 404) {
        throw 'Bot not found. The ID may be invalid.';
      } else {
        _logger.e('Failed to fetch bot: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        throw 'Failed to fetch bot: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error fetching bot: $e');
      rethrow;
    }
  }
  
  // Update an existing AI Bot
  Future<AIBot> updateBot({
    required String botId,
    String? name,
    String? description,
    String? model,
    String? prompt,
  }) async {
    try {
      _logger.i('Updating AI Bot with ID: $botId');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers - changed from const to final
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json'
      };
      
      // Build request body - only include fields that are provided
      final Map<String, dynamic> body = {};
      
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (model != null) body['model'] = model;
      if (prompt != null) body['instructions'] = prompt; // API expects 'instructions'
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = ApiConstants.botById.replaceAll('{botId}', botId);
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      
      // Send request
      final response = await http.patch(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      _logger.i('Update bot response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Bot updated successfully');
        return AIBot.fromJson(data);
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return updateBot(
            botId: botId,
            name: name,
            description: description,
            model: model,
            prompt: prompt,
          );
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else if (response.statusCode == 404) {
        throw 'Bot not found. The ID may be invalid.';
      } else {
        _logger.e('Failed to update bot: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        throw 'Failed to update bot: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error updating bot: $e');
      rethrow;
    }
  }
  
  // Delete an AI Bot
  Future<bool> deleteBot(String botId) async {
    try {
      _logger.i('Deleting AI Bot with ID: $botId');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers - changed from const to final
      final headers = {
        'Authorization': 'Bearer $accessToken',
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = ApiConstants.botById.replaceAll('{botId}', botId);
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      
      // Send request
      final response = await http.delete(uri, headers: headers);
      
      _logger.i('Delete bot response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        _logger.i('Bot deleted successfully');
        return true;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return deleteBot(botId);
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else if (response.statusCode == 404) {
        throw 'Bot not found. The ID may be invalid.';
      } else {
        _logger.e('Failed to delete bot: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        throw 'Failed to delete bot: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error deleting bot: $e');
      rethrow;
    }
  }
  
  // Import knowledge to an AI Bot
  Future<bool> importKnowledge({
    required String botId, 
    required List<String> knowledgeBaseIds
  }) async {
    try {
      _logger.i('Importing knowledge to bot $botId');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers - changed from const to final
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json'
      };
      
      // Build request body
      final Map<String, dynamic> body = {
        'knowledgeBaseIds': knowledgeBaseIds,
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = ApiConstants.botKnowledge.replaceAll('{botId}', botId);
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      
      // Send request
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      _logger.i('Import knowledge response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.i('Knowledge imported successfully');
        return true;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return importKnowledge(
            botId: botId,
            knowledgeBaseIds: knowledgeBaseIds,
          );
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to import knowledge: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        throw 'Failed to import knowledge: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error importing knowledge: $e');
      rethrow;
    }
  }
  
  // Remove knowledge from an AI Bot
  Future<bool> removeKnowledge({
    required String botId, 
    required String knowledgeBaseId
  }) async {
    try {
      _logger.i('Removing knowledge $knowledgeBaseId from bot $botId');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers - changed from const to final
      final headers = {
        'Authorization': 'Bearer $accessToken',
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = ApiConstants.botKnowledgeById
          .replaceAll('{botId}', botId)
          .replaceAll('{knowledgeBaseId}', knowledgeBaseId);
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      
      // Send request
      final response = await http.delete(uri, headers: headers);
      
      _logger.i('Remove knowledge response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        _logger.i('Knowledge removed successfully');
        return true;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return removeKnowledge(
            botId: botId,
            knowledgeBaseId: knowledgeBaseId,
          );
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to remove knowledge: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        throw 'Failed to remove knowledge: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error removing knowledge: $e');
      rethrow;
    }
  }
  
  // Upload file for knowledge base
  Future<String> uploadKnowledgeFile(File file) async {
    try {
      _logger.i('Uploading knowledge file: ${file.path}');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Determine file type
      final String fileName = file.path.split('/').last;
      final String fileExtension = fileName.split('.').last.toLowerCase();
      String contentType;
      
      switch (fileExtension) {
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'doc':
        case 'docx':
          contentType = 'application/msword';
          break;
        case 'txt':
          contentType = 'text/plain';
          break;
        default:
          contentType = 'application/octet-stream';
      }
      
      // Prepare request
      const baseUrl = ApiConstants.jarvisApiUrl;
      const endpoint = ApiConstants.knowledgeUpload;
      final uri = Uri.parse(baseUrl + endpoint);
      
      // Create multipart request
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Authorization': 'Bearer $accessToken',
        })
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            contentType: MediaType.parse(contentType),
            filename: fileName,
          ),
        );
      
      _logger.i('Sending request to: $uri');
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      _logger.i('Upload file response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final fileId = data['id'];
        _logger.i('File uploaded successfully, ID: $fileId');
        return fileId;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return uploadKnowledgeFile(file);
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to upload file: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        throw 'Failed to upload file: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error uploading file: $e');
      rethrow;
    }
  }
  
  // Ask an AI Bot directly (preview mode)
  Future<String> askBot({
    required String botId,
    required String message,
  }) async {
    try {
      _logger.i('Asking bot $botId: $message');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers - changed from const to final
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json'
      };
      
      // Build request body
      final Map<String, dynamic> body = {
        'query': message,
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = ApiConstants.botAsk.replaceAll('{botId}', botId);
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      
      // Send request
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      _logger.i('Ask bot response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['answer'] ?? 'No response received';
        _logger.i('Bot responded successfully');
        return answer;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return askBot(
            botId: botId,
            message: message,
          );
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to ask bot: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        throw 'Failed to ask bot: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error asking bot: $e');
      rethrow;
    }
  }
  
  // Get all available knowledge bases
  Future<List<KnowledgeData>> getKnowledgeBases({String? query}) async {
    try {
      _logger.i('Fetching knowledge bases${query != null ? ' with query: $query' : ''}');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers - changed from const to final
      final headers = {
        'Authorization': 'Bearer $accessToken',
      };
      
      // Build URL with query parameters
      const baseUrl = ApiConstants.jarvisApiUrl;
      const endpoint = ApiConstants.knowledgeBase;
      
      var queryParams = <String, String>{};
      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }
      
      final uri = Uri.parse(baseUrl + endpoint).replace(queryParameters: queryParams);
      
      _logger.i('Request URI: $uri');
      
      // Send request
      final response = await http.get(uri, headers: headers);
      
      _logger.i('Get knowledge bases response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final knowledgeBases = data['items'] as List<dynamic>;
        
        return knowledgeBases.map((item) => KnowledgeData.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return getKnowledgeBases(query: query);
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to fetch knowledge bases: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        throw 'Failed to fetch knowledge bases: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error fetching knowledge bases: $e');
      rethrow;
    }
  }
  
  // Get publishing configuration for a bot
  Future<Map<String, dynamic>> getPublishingConfigurations(String botId) async {
    try {
      _logger.i('Fetching publishing configurations for bot $botId');
      
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
      final endpoint = ApiConstants.botConfigurations.replaceAll('{botId}', botId);
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Request URI: $uri');
      
      // Send request
      final response = await http.get(uri, headers: headers);
      
      _logger.i('Get publishing configurations response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Publishing configurations fetched successfully');
        return data;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return getPublishingConfigurations(botId);
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to fetch publishing configurations: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        throw 'Failed to fetch publishing configurations: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error fetching publishing configurations: $e');
      rethrow;
    }
  }

  // Get bot publish configurations - alias for getPublishingConfigurations
  Future<Map<String, dynamic>> getBotPublishConfigurations(String botId) async {
    return getPublishingConfigurations(botId);
  }
  
  // Publish bot to a platform (Slack, Telegram, Messenger)
  Future<bool> publishBot({
    required String botId,
    required String platform, // 'slack', 'telegram', 'messenger'
    required Map<String, dynamic> config,
  }) async {
    try {
      _logger.i('Publishing bot $botId to $platform');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers - changed from const to final
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json'
      };
      
      // Build request body
      final Map<String, dynamic> body = {
        'platform': platform,
        'configuration': config,
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = ApiConstants.botPublish.replaceAll('{botId}', botId);
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      
      // Send request
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      _logger.i('Publish bot response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.i('Bot published successfully to $platform');
        return true;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return publishBot(
            botId: botId,
            platform: platform,
            config: config,
          );
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to publish bot: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        throw 'Failed to publish bot: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error publishing bot: $e');
      rethrow;
    }
  }
  
  // Unpublish bot from a platform
  Future<bool> unpublishBot({
    required String botId,
    required String platform, // 'slack', 'telegram', 'messenger'
  }) async {
    try {
      _logger.i('Unpublishing bot $botId from $platform');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers - changed from const to final
      final headers = {
        'Authorization': 'Bearer $accessToken',
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = ApiConstants.botPublishPlatform
          .replaceAll('{botId}', botId)
          .replaceAll('{platform}', platform);
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      
      // Send request
      final response = await http.delete(uri, headers: headers);
      
      _logger.i('Unpublish bot response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        _logger.i('Bot unpublished successfully from $platform');
        return true;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return unpublishBot(
            botId: botId,
            platform: platform,
          );
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to unpublish bot: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        throw 'Failed to unpublish bot: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error unpublishing bot: $e');
      rethrow;
    }
  }
  
  // Test connection to a platform
  Future<Map<String, dynamic>> testBotConnection({
    required String botId,
    required String platform,
  }) async {
    try {
      // In a real implementation, this would make an API call to test the connection
      // For now, we'll simulate a successful response
      await Future.delayed(const Duration(seconds: 1));
      return {
        'status': 'connected',
        'message': 'Connection successful',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _logger.e('Error testing bot connection: $e');
      rethrow;
    }
  }

  // Create a new knowledge base
  Future<KnowledgeData> createKnowledgeBase({
    required String name,
    required String description,
  }) async {
    try {
      _logger.i('Creating knowledge base: $name');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json'
      };
      
      // Build request body
      final Map<String, dynamic> body = {
        'name': name,
        'description': description,
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      const endpoint = ApiConstants.knowledgeBase;
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      
      // Send request
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      _logger.i('Create knowledge base response status: ${response.statusCode}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Knowledge base created successfully');
        return KnowledgeData.fromJson(data);
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return createKnowledgeBase(
            name: name,
            description: description,
          );
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to create knowledge base: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        throw 'Failed to create knowledge base: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error creating knowledge base: $e');
      rethrow;
    }
  }
  
  // Delete a knowledge base
  Future<bool> deleteKnowledgeBase(String knowledgeBaseId) async {
    try {
      _logger.i('Deleting knowledge base with ID: $knowledgeBaseId');
      
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
      final endpoint = ApiConstants.knowledgeById.replaceAll('{knowledgeBaseId}', knowledgeBaseId);
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      
      // Send request
      final response = await http.delete(uri, headers: headers);
      
      _logger.i('Delete knowledge base response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        _logger.i('Knowledge base deleted successfully');
        return true;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return deleteKnowledgeBase(knowledgeBaseId);
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to delete knowledge base: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        throw 'Failed to delete knowledge base: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error deleting knowledge base: $e');
      rethrow;
    }
  }

  // Upload a file to a knowledge base
  Future<bool> uploadFileToKnowledge({
    required String knowledgeBaseId,
    required File file,
  }) async {
    try {
      _logger.i('Uploading file to knowledge base $knowledgeBaseId: ${file.path}');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Determine file type
      final String fileName = file.path.split('/').last;
      final String fileExtension = fileName.split('.').last.toLowerCase();
      String contentType;
      
      switch (fileExtension) {
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'doc':
        case 'docx':
          contentType = 'application/msword';
          break;
        case 'txt':
          contentType = 'text/plain';
          break;
        case 'csv':
          contentType = 'text/csv';
          break;
        case 'json':
          contentType = 'application/json';
          break;
        case 'xlsx':
        case 'xls':
          contentType = 'application/vnd.ms-excel';
          break;
        case 'pptx':
        case 'ppt':
          contentType = 'application/vnd.ms-powerpoint';
          break;
        default:
          contentType = 'application/octet-stream';
      }
      
      // Prepare request
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = ApiConstants.knowledgeUploadFile.replaceAll('{knowledgeBaseId}', knowledgeBaseId);
      final uri = Uri.parse(baseUrl + endpoint);
      
      // Create multipart request
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Authorization': 'Bearer $accessToken',
        })
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            contentType: MediaType.parse(contentType),
            filename: fileName,
          ),
        );
      
      _logger.i('Sending request to: $uri');
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      _logger.i('Upload file response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.i('File uploaded successfully to knowledge base $knowledgeBaseId');
        return true;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return uploadFileToKnowledge(
            knowledgeBaseId: knowledgeBaseId,
            file: file,
          );
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to upload file: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        throw 'Failed to upload file: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error uploading file: $e');
      rethrow;
    }
  }

  // Upload website to knowledge base
  Future<bool> uploadWebsiteToKnowledge({
    required String knowledgeBaseId,
    required String url,
    bool recursive = true,
    int maxPages = 100,
  }) async {
    try {
      _logger.i('Uploading website to knowledge base $knowledgeBaseId: $url');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json'
      };
      
      // Build request body
      final Map<String, dynamic> body = {
        'url': url,
        'recursive': recursive,
        'maxPages': maxPages,
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = ApiConstants.knowledgeUploadWebsite.replaceAll('{knowledgeBaseId}', knowledgeBaseId);
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      
      // Send request
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      _logger.i('Upload website response status: ${response.statusCode}');
      
      if (response.statusCode == 202 || response.statusCode == 200) {
        _logger.i('Website upload initiated for knowledge base $knowledgeBaseId');
        return true;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return uploadWebsiteToKnowledge(
            knowledgeBaseId: knowledgeBaseId,
            url: url,
            recursive: recursive,
            maxPages: maxPages,
          );
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to upload website: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        throw 'Failed to upload website: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error uploading website: $e');
      rethrow;
    }
  }

  // Upload from Google Drive
  Future<bool> uploadGoogleDriveToKnowledge({
    required String knowledgeBaseId,
    required String folderId,
  }) async {
    try {
      _logger.i('Uploading from Google Drive to knowledge base $knowledgeBaseId: $folderId');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json'
      };
      
      // Build request body
      final Map<String, dynamic> body = {
        'folderId': folderId,
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = ApiConstants.knowledgeUploadGoogleDrive.replaceAll('{knowledgeBaseId}', knowledgeBaseId);
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      
      // Send request
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      _logger.i('Google Drive upload response status: ${response.statusCode}');
      
      if (response.statusCode == 202 || response.statusCode == 200) {
        _logger.i('Google Drive upload initiated for knowledge base $knowledgeBaseId');
        return true;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return uploadGoogleDriveToKnowledge(
            knowledgeBaseId: knowledgeBaseId,
            folderId: folderId,
          );
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to upload from Google Drive: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        throw 'Failed to upload from Google Drive: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error uploading from Google Drive: $e');
      rethrow;
    }
  }

  // Upload from Slack
  Future<bool> uploadSlackToKnowledge({
    required String knowledgeBaseId,
    required String slackToken,
  }) async {
    try {
      _logger.i('Uploading from Slack to knowledge base $knowledgeBaseId');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json'
      };
      
      // Build request body
      final Map<String, dynamic> body = {
        'slackToken': slackToken,
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = ApiConstants.knowledgeUploadSlack.replaceAll('{knowledgeBaseId}', knowledgeBaseId);
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      
      // Send request
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      _logger.i('Slack upload response status: ${response.statusCode}');
      
      if (response.statusCode == 202 || response.statusCode == 200) {
        _logger.i('Slack upload initiated for knowledge base $knowledgeBaseId');
        return true;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return uploadSlackToKnowledge(
            knowledgeBaseId: knowledgeBaseId,
            slackToken: slackToken,
          );
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to upload from Slack: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        throw 'Failed to upload from Slack: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error uploading from Slack: $e');
      rethrow;
    }
  }

  // Upload from Confluence
  Future<bool> uploadConfluenceToKnowledge({
    required String knowledgeBaseId,
    required String confluenceUrl,
    required String username,
    required String apiToken,
  }) async {
    try {
      _logger.i('Uploading from Confluence to knowledge base $knowledgeBaseId: $confluenceUrl');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json'
      };
      
      // Build request body
      final Map<String, dynamic> body = {
        'confluenceUrl': confluenceUrl,
        'username': username,
        'apiToken': apiToken,
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = ApiConstants.knowledgeUploadConfluence.replaceAll('{knowledgeBaseId}', knowledgeBaseId);
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      
      // Send request
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      _logger.i('Confluence upload response status: ${response.statusCode}');
      
      if (response.statusCode == 202 || response.statusCode == 200) {
        _logger.i('Confluence upload initiated for knowledge base $knowledgeBaseId');
        return true;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return uploadConfluenceToKnowledge(
            knowledgeBaseId: knowledgeBaseId,
            confluenceUrl: confluenceUrl,
            username: username,
            apiToken: apiToken,
          );
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to upload from Confluence: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        throw 'Failed to upload from Confluence: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error uploading from Confluence: $e');
      rethrow;
    }
  }
}
