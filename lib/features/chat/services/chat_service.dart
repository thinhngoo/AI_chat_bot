import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/auth/auth_service.dart';
import '../models/conversation_message.dart';

/// A service class for handling chat operations, including fetching
/// conversation history, retrieving a list of conversations, and sending
/// messages to the AI chat service.
///
/// This service requires the user to be authenticated via [AuthService].
/// It uses a singleton pattern to ensure a single instance is used
/// throughout the application.
///
/// To use this service, access the singleton instance via [ChatService()].
class ChatService {
  static final ChatService _instance = ChatService._internal();
  
  /// Returns the singleton instance of [ChatService].
  factory ChatService() => _instance;

  final Logger _logger = Logger();
  final AuthService _authService = AuthService();
  
  // Cache for conversations to improve loading times
  List<Map<String, dynamic>>? _cachedConversations;
  DateTime? _lastCacheTime;
  final Duration _cacheDuration = const Duration(minutes: 5);

  ChatService._internal();

  // Clear the cache when needed (e.g., after creating a new conversation)
  void clearCache() {
    _cachedConversations = null;
    _lastCacheTime = null;
    _logger.i('Conversation cache cleared');
  }

  // Check if cache is still valid
  bool _isCacheValid() {
    if (_cachedConversations == null || _lastCacheTime == null) {
      return false;
    }
    
    final now = DateTime.now();
    return now.difference(_lastCacheTime!) < _cacheDuration;
  }

  /// Fetches the conversation history for a specified conversation.
  ///
  /// Requires a [conversationId] to identify the conversation.
  /// Optionally, you can specify:
  /// - [assistantId]: Filters messages by a specific assistant.
  /// - [cursor]: Used for pagination to fetch the next set of messages.
  /// - [limit]: The maximum number of messages to retrieve (defaults to 20).
  ///
  /// Returns a [Future] that resolves to a [ConversationMessagesResponse]
  /// containing the list of messages in the conversation.
  ///
  /// Throws an exception if:
  /// - No access token is available (authentication required).
  /// - The request fails due to network issues.
  /// - The server returns:
  ///   - 401: Authentication expired (attempts token refresh).
  ///   - 404: Conversation not found (invalid [conversationId]).
  ///   - 500: Server error (returns empty response).
  ///   - Other status codes: Generic failure with status code.
  Future<ConversationMessagesResponse> getConversationHistory(
    String conversationId, {
    String? assistantId,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      _logger.i('Fetching conversation history for ID: $conversationId');
      
      // Build query parameters based on APIdog documentation
      final queryParams = <String, String>{
        'assistantModel': 'dify', // Required parameter per API docs
      };
      
      if (assistantId != null) {
        queryParams['assistantId'] = assistantId;
      }
      
      if (cursor != null) {
        queryParams['cursor'] = cursor;
      }
      
      queryParams['limit'] = limit.toString();
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = '/api/v1/ai-chat/conversations/$conversationId/messages';
      final uri = Uri.parse(baseUrl + endpoint).replace(queryParameters: queryParams);
      
      // Log full request URI for debugging
      _logger.i('Request URI: $uri');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers based on API documentation
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-jarvis-guid': generateGuid(),
      };
      
      // Send request
      final response = await http.get(uri, headers: headers);
      
      _logger.i('Conversation history response status: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Based on API documentation, the response format is:
        // { "cursor": "string", "has_more": boolean, "limit": integer, 
        //   "items": [ { "answer": "string", "createdAt": integer, "files": ["string"], "query": "string" } ] }
        
        return ConversationMessagesResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return getConversationHistory(
            conversationId,
            assistantId: assistantId,
            cursor: cursor,
            limit: limit,
          );
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else if (response.statusCode == 500) {
        // For 500 errors, return empty response instead of throwing
        _logger.w('Server returned 500 error for conversation history - returning empty response');
        _logger.w('Response body: ${response.body}');
        
        String requestId = 'unknown';
        try {
          final errorData = jsonDecode(response.body);
          requestId = errorData['requestId'] ?? 'unknown';
          _logger.w('Request ID: $requestId');
        } catch (e) {
          // Ignore JSON parsing errors for error tracking
        }
        
        // Return empty response
        return ConversationMessagesResponse(
          items: [],
          hasMore: false,
          nextCursor: null,
        );
      } else {
        // Provide more specific error messages based on status code
        _logger.e('Failed to fetch conversation history: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        if (response.statusCode == 404) {
          throw 'Conversation not found. The conversation ID may be invalid.';
        } else {
          throw 'Failed to fetch conversation history: ${response.statusCode}';
        }
      }
    } catch (e) {
      _logger.e('Error fetching conversation history: $e');
      rethrow;
    }
  }
  
  /// Fetches a list of conversations for the current user.
  ///
  /// Optionally, you can specify:
  /// - [cursor]: Used for pagination to fetch the next set of conversations.
  /// - [limit]: The maximum number of conversations to retrieve (defaults to 20).
  /// - [assistantId]: Filters conversations by assistant (defaults to 'gpt-4o-mini').
  ///
  /// Returns a [Future] that resolves to a list of conversation maps.
  /// Each map represents a conversation and contains at least an 'id' key,
  /// along with other metadata provided by the API.
  ///
  /// If the server returns a 500 error, returns an empty list instead of throwing.
  ///
  /// Throws an exception if:
  /// - No access token is available (authentication required).
  /// - The request fails due to network issues.
  /// - The server returns:
  ///   - 401: Authentication expired (attempts token refresh).
  ///   - Other status codes: Generic failure with status code and request ID if available.
  Future<List<Map<String, dynamic>>> getConversations({
    String? cursor,
    int limit = 20,
    String assistantId = 'gpt-4o-mini',
  }) async {
    try {
      if (_isCacheValid()) {
        _logger.i('Returning cached conversations');
        return _cachedConversations!;
      }

      _logger.i('Fetching conversations list');
      
      // Build query parameters according to API documentation
      final queryParams = <String, String>{
        'assistantModel': 'dify', // Required parameter per API docs
      };
      
      // Add optional parameters if provided
      if (cursor != null && cursor.isNotEmpty) {
        queryParams['cursor'] = cursor;
      }
      
      queryParams['limit'] = limit.toString();
      
      if (assistantId.isNotEmpty) {
        queryParams['assistantId'] = assistantId;
      }
      
      // Build URL with query parameters
      const baseUrl = ApiConstants.jarvisApiUrl;
      const endpoint = '/api/v1/ai-chat/conversations';
      final uri = Uri.parse(baseUrl + endpoint).replace(queryParameters: queryParams);
      
      // Log request details for debugging
      _logger.i('Request URI: $uri');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers according to API documentation
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-jarvis-guid': generateGuid(),
      };
      
      // Send request
      final response = await http.get(uri, headers: headers);
      
      _logger.i('Conversations list response status: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Parse response according to documented format from APIdog:
        // { "cursor": "string", "has_more": boolean, "limit": integer, "items": [ { "title": "string", "id": "string", "createdAt": integer } ] }
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
        final hasMore = data['has_more'] ?? false;
        
        _logger.i('Successfully fetched ${items.length} conversations (has_more: $hasMore)');
        if (items.isEmpty) {
          _logger.i('No conversations found for this user');
        }

        // Cache the conversations
        _cachedConversations = items;
        _lastCacheTime = DateTime.now();
        
        return items;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          return getConversations(
            cursor: cursor,
            limit: limit,
            assistantId: assistantId,
          );
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else if (response.statusCode == 500) {
        // Handle server error - Return empty list with detailed logging
        String requestId = 'unknown';
        String errorMessage = 'Server error';
        try {
          final errorData = jsonDecode(response.body);
          requestId = errorData['requestId'] ?? 'unknown';
          errorMessage = errorData['message'] ?? 'Unknown server error';
          _logger.w('Server error details: $errorMessage');
        } catch (e) {
          // Ignore JSON parsing errors for error tracking
          _logger.d('Could not parse error response as JSON: $e');
        }
        
        _logger.w('Server returned 500 error (Request ID: $requestId) - treating as empty conversations list');
        _logger.w('Response body: ${response.body}');
        
        // Return empty list instead of throwing exception
        return [];
      } else {
        // Handle other errors
        _logger.e('Failed to fetch conversations: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        // Extract request ID if available for support
        String requestId = '';
        String errorMessage = 'Failed to fetch conversations';
        try {
          final errorData = jsonDecode(response.body);
          requestId = errorData['requestId'] ?? '';
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // Ignore JSON parsing errors for error tracking
          _logger.d('Could not parse error response for requestId: $e');
        }
        
        throw '$errorMessage: ${response.statusCode}${requestId.isNotEmpty ? ' (Request ID: $requestId)' : ''}';
      }
    } catch (e) {
      _logger.e('Error fetching conversations: $e');
      rethrow;
    }
  }
  
  /// Sends a message to the AI chat service.
  ///
  /// Requires:
  /// - [content]: The message text to send.
  /// - [assistantId]: The ID of the assistant to respond.
  ///
  /// Optionally, you can specify:
  /// - [conversationId]: Continues an existing conversation if provided;
  ///   starts a new conversation if null or empty.
  /// - [files]: A list of file IDs to attach to the message.
  /// - [maxRetries]: Maximum number of retries for 500 errors (default is 1).
  /// - [currentRetry]: Current retry count (default is 0).
  ///
  /// Returns a [Future] that resolves to a [Map<String, dynamic>] containing
  /// the server response, including:
  /// - 'conversationId': The ID of the conversation (new or existing).
  /// - 'message': The AI's response message.
  ///
  /// Throws an exception if:
  /// - No access token is available (authentication required).
  /// - The request fails due to network issues.
  /// - The server returns:
  ///   - 401: Authentication expired (attempts token refresh).
  ///   - 404: Conversation not found (invalid [conversationId]).
  ///   - 500: Server error (suggests starting a new conversation).
  ///   - Other status codes: Generic failure with detailed message if available.
  Future<Map<String, dynamic>> sendMessage({
    required String content,
    required String assistantId,
    String? conversationId,
    List<String>? files,
    int maxRetries = 1,
    int currentRetry = 0,
  }) async {
    try {
      _logger.i('Sending message to AI chat');
      if (conversationId != null && conversationId.isNotEmpty) {
        _logger.i('Using existing conversation ID: $conversationId');
      } else {
        _logger.i('No conversation ID provided - starting new conversation');
      }
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-jarvis-guid': generateGuid(),
        'Content-Type': 'application/json'
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      const endpoint = '/api/v1/ai-chat/messages';
      final uri = Uri.parse(baseUrl + endpoint);
      
      // Prepare request body based on API documentation
      final Map<String, dynamic> body = {
        'content': content,
        'assistant': {
          'id': assistantId,
          'model': 'dify',
          'name': _getAssistantName(assistantId),
        },
        'files': files ?? [],
      };
      
      // Add metadata only if we have a conversation ID
      if (conversationId != null && conversationId.isNotEmpty) {
        body['metadata'] = {
          'conversation': {
            'id': conversationId,
          }
        };
        _logger.i('Including conversation ID in metadata: $conversationId');
      }
      
      _logger.i('Sending message to: $uri');
      _logger.d('Request body: ${jsonEncode(body)}');
      
      // Send request
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      _logger.i('Send message response status: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');
      
      // Check for insufficient tokens error code (403 Forbidden is typically used for quota errors)
      if (response.statusCode == 403) {
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null && 
              (errorData['message'].toString().toLowerCase().contains('insufficient') || 
               errorData['message'].toString().toLowerCase().contains('token') ||
               errorData['message'].toString().toLowerCase().contains('quota') ||
               errorData['message'].toString().toLowerCase().contains('limit'))) {
            
            _logger.w('User has insufficient tokens: ${errorData['message']}');
            throw 'You have insufficient tokens. Please upgrade your subscription to continue chatting.';
          } else {
            throw 'Error: ${errorData['message'] ?? 'Access denied (403)'}';
          }        } catch (e) {
          if (e is String) {
            rethrow;
          }
          throw 'Insufficient tokens or access denied. Please check your subscription.';
        }
      }
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        _logger.d('Response data structure: ${data.keys.join(", ")}');
        
        // According to API documentation, the response contains:
        // - conversationId: Conversation identifier
        // - message: The AI's response text
        // - remainingUsage: Usage counter
        
        String? newConversationId = data['conversationId'];
        String? messageText = data['message'];
        int? remainingUsage = data['remainingUsage'];
        
        // Log remaining usage if available
        if (remainingUsage != null) {
          _logger.i('Remaining usage: $remainingUsage tokens');
          
          // Warn if tokens are running low (less than 10 remaining)
          if (remainingUsage < 10) {
            _logger.w('User is running low on tokens: $remainingUsage remaining');
          }
        }
        
        if (newConversationId != null) {
          _logger.i('Message sent successfully, conversation ID: $newConversationId');
        } else {
          _logger.w('Could not extract conversation ID from response');
        }
        
        if (messageText != null) {
          // Return in standardized format for app usage including remaining tokens
          return {
            'conversation_id': newConversationId,
            'answers': [messageText],
            'remaining_usage': remainingUsage,
          };
        } else {
          // Fallback to searching for answer in other possible fields
          _logger.w('Standard message field not found, checking alternative fields');
          
          // Try other possible response formats
          if (data.containsKey('response') && data['response'] is String) {
            messageText = data['response'];
          } else if (data.containsKey('content') && data['content'] is String) {
            messageText = data['content'];
          } else if (data.containsKey('text') && data['text'] is String) {
            messageText = data['text'];
          } else if (data.containsKey('answer') && data['answer'] is String) {
            messageText = data['answer'];
          }
          
          if (messageText != null) {
            return {
              'conversation_id': newConversationId,
              'answers': [messageText],
              'remaining_usage': remainingUsage,
            };
          }
          
          // If we still couldn't find the answer, log the entire response
          _logger.w('Could not locate message in response. Full response: $data');
          return {
            'conversation_id': newConversationId,
            'answers': ['I received a response but couldn\'t understand it. Please try again.'],
            'original_response': data,
            'remaining_usage': remainingUsage,
          };
        }
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          return sendMessage(
            content: content,
            assistantId: assistantId,
            conversationId: conversationId,
            files: files,
          );
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else if (response.statusCode == 500) {
        _logger.e('Server returned 500 error - might be related to conversation handling');
        _logger.e('Response body: ${response.body}');
        
        // Extract error details and requestId if available
        String errorMsg = 'Failed to send message (Server error 500)';
        String requestId = 'unknown';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMsg = errorData['message'];
          }
          if (errorData['requestId'] != null) {
            requestId = errorData['requestId'];
            _logger.e('Request ID: $requestId');
          }
        } catch (e) {
          // Ignore JSON parsing errors for error responses
          _logger.d('Could not parse error response as JSON: $e');
        }
        
        // If there are retries left and this is a conversation-related error, retry without conversation ID
        if (conversationId != null && currentRetry < maxRetries) {
          _logger.i('Retrying without conversation ID (attempt ${currentRetry + 1} of $maxRetries)');
          // Wait briefly before retrying to avoid overwhelming the server
          await Future.delayed(const Duration(milliseconds: 500));
          return sendMessage(
            content: content,
            assistantId: assistantId,
            conversationId: null, // Force starting a new conversation
            files: files,
            maxRetries: maxRetries,
            currentRetry: currentRetry + 1,
          );
        }
        
        // Out of retries or not a conversation ID issue
        throw 'Error sending message: $errorMsg. Try starting a new conversation. (Request ID: $requestId)';
      } else if (response.statusCode == 402) {
        // Payment required error - typically used for subscription or token errors
        _logger.w('Payment required error (402) - likely insufficient tokens');
        
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg = errorData['message'] ?? 'Insufficient tokens. Please upgrade your subscription.';
          throw errorMsg;        } catch (e) {
          if (e is String) {
            rethrow;
          }
          throw 'Insufficient tokens. Please upgrade your subscription to continue chatting.';
        }
      } else {
        _logger.e('Failed to send message: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        String errorMessage = 'Failed to send message: ${response.statusCode}';
        
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
            
            // Check if the error is related to insufficient tokens
            if (errorMessage.toLowerCase().contains('insufficient') || 
                errorMessage.toLowerCase().contains('token') ||
                errorMessage.toLowerCase().contains('quota') ||
                errorMessage.toLowerCase().contains('limit')) {
              throw 'You have insufficient tokens. Please upgrade your subscription to continue chatting.';
            }
          }
        } catch (e) {          // Ignore JSON parsing errors for error responses
          if (e is String && (e.contains('insufficient') || e.contains('upgrade'))) {
            rethrow;  // Re-throw token error messages
          }
          _logger.d('Could not parse error response as JSON: $e');
        }
        
        throw errorMessage;
      }
    } catch (e) {
      _logger.e('Error sending message: $e');
      rethrow;
    }
  }
  
  /// Retrieves a list of all available assistants.
  ///
  /// Returns a [Future] that resolves to a list of assistant objects.
  /// Each assistant contains details like ID, name, model, and capabilities.
  ///
  /// Throws an exception if:
  /// - No access token is available (authentication required).
  /// - The request fails due to network issues.
  /// - The server returns an error status code.
  Future<List<Map<String, dynamic>>> getAssistants() async {
    try {
      _logger.i('Fetching list of assistants');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-jarvis-guid': generateGuid(),
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      const endpoint = '/api/v1/ai-chat/assistants';
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Request URI: $uri');
      
      // Send request
      final response = await http.get(uri, headers: headers);
      
      _logger.i('Get assistants response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistants = List<Map<String, dynamic>>.from(data['assistants'] ?? []);
        _logger.i('Successfully fetched ${assistants.length} assistants');
        return assistants;
      } else if (response.statusCode == 401) {
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          return getAssistants();
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to fetch assistants: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        String errorMessage = 'Failed to fetch assistants: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // Ignore JSON parsing errors for error responses
          _logger.d('Could not parse error response as JSON: $e');
        }
        
        throw errorMessage;
      }
    } catch (e) {
      _logger.e('Error fetching assistants: $e');
      rethrow;
    }
  }

  /// Creates a new assistant with the specified parameters.
  ///
  /// Required parameters:
  /// - [name]: The display name for the assistant.
  /// - [model]: The AI model to use (e.g., 'gpt-4o', 'gemini-1.5-pro').
  /// - [instructions]: Initial instructions/prompt for the assistant.
  ///
  /// Optional parameters:
  /// - [description]: A description of the assistant's purpose.
  /// - [metadata]: Additional metadata for the assistant.
  /// - [tools]: List of tools the assistant can use.
  ///
  /// Returns a [Future] that resolves to the created assistant object.
  ///
  /// Throws an exception if:
  /// - No access token is available (authentication required).
  /// - The request fails due to network issues.
  /// - The server returns an error status code.
  Future<Map<String, dynamic>> createAssistant({
    required String name,
    required String model,
    required String instructions,
    String? description,
    Map<String, dynamic>? metadata,
    List<Map<String, dynamic>>? tools,
  }) async {
    try {
      _logger.i('Creating new assistant: $name (model: $model)');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-jarvis-guid': generateGuid(),
        'Content-Type': 'application/json'
      };
      
      // Build request body
      final Map<String, dynamic> body = {
        'name': name,
        'model': model,
        'instructions': instructions,
      };
      
      if (description != null) {
        body['description'] = description;
      }
      
      if (metadata != null) {
        body['metadata'] = metadata;
      }
      
      if (tools != null) {
        body['tools'] = tools;
      }
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      const endpoint = '/api/v1/ai-chat/assistants';
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      _logger.d('Request body: ${jsonEncode(body)}');
      
      // Send request
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      _logger.i('Create assistant response status: ${response.statusCode}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Assistant created successfully, ID: ${data['id']}');
        return data;
      } else if (response.statusCode == 401) {
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          return createAssistant(
            name: name,
            model: model,
            instructions: instructions,
            description: description,
            metadata: metadata,
            tools: tools,
          );
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        _logger.e('Failed to create assistant: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        String errorMessage = 'Failed to create assistant: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // Ignore JSON parsing errors for error responses
          _logger.d('Could not parse error response as JSON: $e');
        }
        
        throw errorMessage;
      }
    } catch (e) {
      _logger.e('Error creating assistant: $e');
      rethrow;
    }
  }
  
  /// Updates an existing assistant with new parameters.
  ///
  /// Required parameter:
  /// - [assistantId]: The ID of the assistant to update.
  ///
  /// Optional parameters:
  /// - [name]: New display name for the assistant.
  /// - [model]: New AI model to use.
  /// - [instructions]: New initial instructions/prompt.
  /// - [description]: New description of the assistant's purpose.
  /// - [metadata]: New additional metadata.
  /// - [tools]: New list of tools the assistant can use.
  ///
  /// Returns a [Future] that resolves to the updated assistant object.
  ///
  /// Throws an exception if:
  /// - No access token is available (authentication required).
  /// - The request fails due to network issues.
  /// - The server returns an error status code.
  Future<Map<String, dynamic>> updateAssistant({
    required String assistantId,
    String? name,
    String? model,
    String? instructions,
    String? description,
    Map<String, dynamic>? metadata,
    List<Map<String, dynamic>>? tools,
  }) async {
    try {
      _logger.i('Updating assistant: $assistantId');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-jarvis-guid': generateGuid(),
        'Content-Type': 'application/json'
      };
      
      // Build request body - only include fields that are provided
      final Map<String, dynamic> body = {};
      
      if (name != null) body['name'] = name;
      if (model != null) body['model'] = model;
      if (instructions != null) body['instructions'] = instructions;
      if (description != null) body['description'] = description;
      if (metadata != null) body['metadata'] = metadata;
      if (tools != null) body['tools'] = tools;
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = '/api/v1/ai-chat/assistants/$assistantId';
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      _logger.d('Request body: ${jsonEncode(body)}');
      
      // Send request
      final response = await http.patch(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      _logger.i('Update assistant response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Assistant updated successfully');
        return data;
      } else if (response.statusCode == 401) {
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          return updateAssistant(
            assistantId: assistantId,
            name: name,
            model: model,
            instructions: instructions,
            description: description,
            metadata: metadata,
            tools: tools,
          );
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else if (response.statusCode == 404) {
        throw 'Assistant not found. The assistant ID may be invalid.';
      } else {
        _logger.e('Failed to update assistant: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        String errorMessage = 'Failed to update assistant: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // Ignore JSON parsing errors for error responses
          _logger.d('Could not parse error response as JSON: $e');
        }
        
        throw errorMessage;
      }
    } catch (e) {
      _logger.e('Error updating assistant: $e');
      rethrow;
    }
  }
  
  /// Deletes an assistant by ID.
  ///
  /// Required parameter:
  /// - [assistantId]: The ID of the assistant to delete.
  ///
  /// Returns a [Future] that resolves to true if deletion was successful.
  ///
  /// Throws an exception if:
  /// - No access token is available (authentication required).
  /// - The request fails due to network issues.
  /// - The server returns an error status code.
  Future<bool> deleteAssistant(String assistantId) async {
    try {
      _logger.i('Deleting assistant: $assistantId');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-jarvis-guid': generateGuid(),
      };
      
      // Build URL
      const baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = '/api/v1/ai-chat/assistants/$assistantId';
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      
      // Send request
      final response = await http.delete(
        uri,
        headers: headers,
      );
      
      _logger.i('Delete assistant response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        _logger.i('Assistant deleted successfully');
        return true;
      } else if (response.statusCode == 401) {
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          return deleteAssistant(assistantId);
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else if (response.statusCode == 404) {
        throw 'Assistant not found. The assistant ID may be invalid.';
      } else {
        _logger.e('Failed to delete assistant: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        String errorMessage = 'Failed to delete assistant: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // Ignore JSON parsing errors for error responses
          _logger.d('Could not parse error response as JSON: $e');
        }
        
        throw errorMessage;
      }
    } catch (e) {
      _logger.e('Error deleting assistant: $e');
      rethrow;
    }
  }
  
  /// Returns the display name for a given [assistantId].
  ///
  /// Maps known assistant IDs to human-readable names. If the ID is unknown,
  /// returns the [assistantId] as-is.
  String _getAssistantName(String assistantId) {
    switch (assistantId) {
      case 'gpt-4o':
        return 'GPT-4o';
      case 'gpt-4.1':
        return 'GPT-4.1';
      case 'o4-mini':
      case 'gpt-4o-mini':
        return 'GPT-4o Mini';
      case 'grok-3':
        return 'Grok 3';
      case 'grok-2':
        return 'Grok 2';
      case 'gemini-1.5-flash-latest':
        return 'Gemini 1.5 Flash';
      case 'gemini-1.5-pro-latest':
        return 'Gemini 1.5 Pro';
      case 'claude-3-haiku-20240307':
        return 'Claude 3 Haiku';
      case 'claude-3-sonnet-20240229':
        return 'Claude 3 Sonnet';
      default:
        return assistantId;
    }
  }
  
  /// Generates a simple GUID for request tracking.
  ///
  /// Combines the current timestamp with a random component.
  /// Note: This is a simplified implementation; consider using a UUID library
  /// in production for true uniqueness.
  String generateGuid() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = now % 1000000;
    return '$now-$random-chat-history';
  }
}

class PromptService {
  final String _baseUrl = ApiConstants.jarvisApiUrl;
  final Logger _logger = Logger();
  final AuthService _authService = AuthService();

  Future<List<Map<String, dynamic>>> getPrompts({
    String? query,
    int offset = 0,
    int limit = 20,
    bool isFavorite = false,
    bool isPublic = false,
  }) async {
    try {
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }

      final uri = Uri.parse('$_baseUrl${ApiConstants.promptsEndpoint}')
          .replace(queryParameters: {
        if (query != null) 'query': query,
        'offset': offset.toString(),
        'limit': limit.toString(),
        'isFavorite': isFavorite.toString(),
        'isPublic': isPublic.toString(),
      });

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $accessToken',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['items']);
      } else {
        _logger.e('Failed to fetch prompts: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        throw 'Failed to fetch prompts: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error fetching prompts: $e');
      rethrow;
    }
  }

  Future<void> createPrompt(Map<String, dynamic> promptData) async {
    try {
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }

      final uri = Uri.parse('$_baseUrl${ApiConstants.promptsEndpoint}');

      final response = await http.post(uri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(promptData));

      if (response.statusCode != 201) {
        _logger.e('Failed to create prompt: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        throw 'Failed to create prompt: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error creating prompt: $e');
      rethrow;
    }
  }

  Future<void> updatePrompt(String id, Map<String, dynamic> promptData) async {
    try {
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }

      final uri = Uri.parse('$_baseUrl${ApiConstants.promptsEndpoint}/$id');

      final response = await http.patch(uri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(promptData));

      if (response.statusCode != 200) {
        _logger.e('Failed to update prompt: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        throw 'Failed to update prompt: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error updating prompt: $e');
      rethrow;
    }
  }

  Future<void> deletePrompt(String id) async {
    try {
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }

      final uri = Uri.parse('$_baseUrl${ApiConstants.promptsEndpoint}/$id');

      final response = await http.delete(uri, headers: {
        'Authorization': 'Bearer $accessToken',
      });

      if (response.statusCode != 200) {
        _logger.e('Failed to delete prompt: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        throw 'Failed to delete prompt: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error deleting prompt: $e');
      rethrow;
    }
  }

  Future<void> addPromptToFavorite(String id) async {
    try {
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }

      final uri = Uri.parse('$_baseUrl${ApiConstants.promptsEndpoint}/$id/favorite');

      final response = await http.post(uri, headers: {
        'Authorization': 'Bearer $accessToken',
      });

      if (response.statusCode != 201) {
        _logger.e('Failed to add prompt to favorite: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        throw 'Failed to add prompt to favorite: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error adding prompt to favorite: $e');
      rethrow;
    }
  }

  Future<void> removePromptFromFavorite(String id) async {
    try {
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }

      final uri = Uri.parse('$_baseUrl${ApiConstants.promptsEndpoint}/$id/favorite');

      final response = await http.delete(uri, headers: {
        'Authorization': 'Bearer $accessToken',
      });

      if (response.statusCode != 200) {
        _logger.e('Failed to remove prompt from favorite: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        throw 'Failed to remove prompt from favorite: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error removing prompt from favorite: $e');
      rethrow;
    }
  }
}
