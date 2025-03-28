import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/user_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/message.dart';
import '../../constants/api_constants.dart';
import 'api_service.dart';

class JarvisApiService implements ApiService {
  static final JarvisApiService _instance = JarvisApiService._internal();
  factory JarvisApiService() => _instance;

  final Logger _logger = Logger();
  late String _authApiUrl;
  late String _jarvisApiUrl;
  late String _knowledgeApiUrl;
  String? _accessToken;
  String? _refreshToken;
  String? _apiKey;
  String? _userId;
  String? _stackProjectId;
  String? _stackPublishableClientKey;
  String? _verificationCallbackUrl;

  // Add support for selecting a model
  String? _selectedModel;

  JarvisApiService._internal() {
    _authApiUrl = ApiConstants.authApiUrl;
    _jarvisApiUrl = ApiConstants.jarvisApiUrl;
    _knowledgeApiUrl = ApiConstants.knowledgeApiUrl;

    _stackProjectId = ApiConstants.stackProjectId;
    _stackPublishableClientKey = ApiConstants.stackPublishableClientKey;
    _verificationCallbackUrl = ApiConstants.verificationCallbackUrl;
  }

  @override
  Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      _apiKey = dotenv.env['JARVIS_API_KEY'] ?? ApiConstants.defaultApiKey;

      _logger.i('Initialized Jarvis API service with:');
      _logger.i('- Auth API URL: $_authApiUrl');
      _logger.i('- Jarvis API URL: $_jarvisApiUrl');
      _logger.i('- Knowledge API URL: $_knowledgeApiUrl');
      _logger.i('- Stack Project ID: ${_maskString(_stackProjectId ?? "missing")}');
      _logger.i('- Stack Publishable Client Key: ${_maskString(_stackPublishableClientKey ?? "missing")}');

      await _loadAuthToken();
    } catch (e) {
      _logger.e('Error initializing Jarvis API service: $e');
    }
  }

  String _maskString(String value) {
    if (value.length <= 8) return '****';
    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
  }

  Future<Map<String, dynamic>> signUp(String email, String password, {String? name}) async {
    try {
      _logger.i('Attempting sign-up for email: $email');
      
      // Simplify request body to match API specifications exactly
      final requestBody = {
        'email': email,
        'password': password,
        'verification_callback_url': _verificationCallbackUrl,
      };

      // Create the complete URL with no additional path components
      // Auth URL already includes necessary path structure
      final url = Uri.parse('$_authApiUrl${ApiConstants.authPasswordSignUp}');
      _logger.i('Sign-up full URL: $url');
      
      // Log the full request details for debugging
      _logger.i('Sign-up request body: ${jsonEncode(requestBody)}');
      
      // Create headers with all required fields
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Stack-Access-Type': 'client',
        'X-Stack-Project-Id': _stackProjectId ?? ApiConstants.stackProjectId,
        'X-Stack-Publishable-Client-Key': _stackPublishableClientKey ?? ApiConstants.stackPublishableClientKey,
      };

      if (_apiKey != null && _apiKey!.isNotEmpty) {
        headers['X-API-KEY'] = _apiKey!;
      }
      
      _logger.d('Sign-up request headers: $headers');
      _logger.d('Sign-up request body: ${jsonEncode(requestBody)}');

      // Make the request with improved timeout and error handling
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));  // Longer timeout for debugging

      // Log detailed response information
      _logger.i('Sign-up response status code: ${response.statusCode}');
      _logger.i('Sign-up response headers: ${response.headers}');
      _logger.i('Sign-up raw response: ${response.body}');

      // Detect if this is a CORS or preflight issue
      if (response.statusCode == 404 || response.statusCode == 405) {
        _logger.e('Possible API configuration issue: ${response.statusCode}');
        _logger.e('Check if the endpoint exists and accepts POST requests');
        
        // Try fallback direct authentication if possible
        throw 'Endpoint not found. Please contact support with error code: AUTH-404-${DateTime.now().millisecondsSinceEpoch}';
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        _logger.e('Error parsing response JSON: $e');
        _logger.e('Response body: ${response.body}');
        throw 'Invalid response from server: ${response.body}';
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        String? userId;
        if (data['access_token'] != null) {
          userId = data['user_id'];
          await _saveAuthToken(
            data['access_token'],
            data['refresh_token'],
            userId,
          );
          _logger.i('Authentication tokens saved successfully');

          if (name != null && name.isNotEmpty && userId != null) {
            try {
              _logger.i('Updating user profile with name: $name');
              await updateUserProfile({'name': name});
            } catch (profileError) {
              _logger.w('Failed to update user profile with name: $profileError');
            }
          }
        } else {
          _logger.w('No access token in successful response');
        }
        return data;
      } else {
        final errorMessage = data['message'] ?? data['error'] ?? 'Unknown error during sign up';
        final errorDetail = data['details'] ?? data['errors'] ?? '';

        _logger.e('Sign-up error: $errorMessage');
        if (errorDetail != '') {
          _logger.e('Error details: $errorDetail');
        }

        throw errorMessage;
      }
    } catch (e) {
      _logger.e('Sign up error: $e');
      
      // Add more specific error handling
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw 'Cannot connect to Jarvis API. Please check your internet connection and API configuration.';
      } else if (e.toString().contains('404') || 
                e.toString().contains('Cannot POST')) {
        throw 'API endpoint not found. Please verify the API configuration and contact support.';
      }
      
      throw e.toString();
    }
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      _logger.i('Attempting sign-in for email: $email');

      final requestBody = {
        'email': email,
        'password': password,
      };

      final url = Uri.parse('$_authApiUrl${ApiConstants.authPasswordSignIn}');
      _logger.i('Sign-in request URL: $url');
      
      // Use direct headers for authentication
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Stack-Access-Type': 'client',
        'X-Stack-Project-Id': _stackProjectId ?? ApiConstants.stackProjectId,
        'X-Stack-Publishable-Client-Key': _stackPublishableClientKey ?? ApiConstants.stackPublishableClientKey,
      };

      if (_apiKey != null && _apiKey!.isNotEmpty) {
        headers['X-API-KEY'] = _apiKey!;
      }
      
      _logger.d('Sign-in request headers: $headers');
      _logger.d('Sign-in request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      _logger.i('Sign-in response status code: ${response.statusCode}');
      _logger.d('Sign-in raw response: ${response.body}');

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        _logger.e('Error parsing response JSON: $e');
        _logger.e('Response body: ${response.body}');
        throw 'Invalid response from server';
      }

      if (response.statusCode == 200) {
        if (data['access_token'] != null) {
          await _saveAuthToken(
            data['access_token'],
            data['refresh_token'],
            data['user_id'],
          );
          _logger.i('Authentication tokens saved successfully');
          
          // Log token info for debugging
          _logTokenInfo(data['access_token']);
        } else {
          _logger.w('No access token in successful response');
        }
        return data;
      } else {
        final errorMessage = data['message'] ?? data['error'] ?? 'Unknown error during sign in';
        final errorDetail = data['details'] ?? data['errors'] ?? '';

        _logger.e('Sign-in error: $errorMessage');
        if (errorDetail != '') {
          _logger.e('Error details: $errorDetail');
        }

        throw errorMessage;
      }
    } catch (e) {
      _logger.e('Sign in error: $e');
      throw e.toString();
    }
  }

  Future<bool> refreshToken() async {
    try {
      if (_refreshToken == null) {
        _logger.w('Cannot refresh token: No refresh token available');
        return false;
      }

      // Circuit breaker - prevent too many refresh attempts in a short time
      final now = DateTime.now();
      if (_lastRefreshAttempt != null && 
          now.difference(_lastRefreshAttempt!).inSeconds < 10 &&
          _refreshAttempts >= _maxRefreshAttempts) {
        _logger.w('Too many token refresh attempts. Switching to Gemini API fallback mode.');
        // Use JarvisChatService to switch to direct Gemini API
        return false;
      }
      
      _lastRefreshAttempt = now;
      _refreshAttempts++;

      _logger.i('Attempting to refresh auth token (attempt $_refreshAttempts)');
      _logger.d('Using refresh token: ${_maskToken(_refreshToken)}');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Stack-Access-Type': 'client',
        'X-Stack-Project-Id': _stackProjectId ?? ApiConstants.stackProjectId,
        'X-Stack-Publishable-Client-Key': _stackPublishableClientKey ?? ApiConstants.stackPublishableClientKey,
        'X-Stack-Refresh-Token': _refreshToken!,
      };

      if (_apiKey != null && _apiKey!.isNotEmpty) {
        headers['X-API-KEY'] = _apiKey!;
      }

      _logger.d('Refresh token request headers: $headers');

      // Add an empty JSON body to satisfy the API's requirement
      final response = await http.post(
        Uri.parse('$_authApiUrl${ApiConstants.authSessionRefresh}'),
        headers: headers,
        body: '{}', // Empty JSON object
      );

      _logger.i('Token refresh response status code: ${response.statusCode}');
      _logger.d('Token refresh response headers: ${response.headers}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          _logger.d('Token refresh response data: ${_maskAuthData(data)}');

          if (data['access_token'] != null) {
            // Save the new access token but keep the current refresh token
            await _saveAuthToken(
              data['access_token'],
              _refreshToken,
              _userId,
            );
            _logger.i('Access token refreshed successfully');
            
            // Test the new token immediately to ensure it works
            final testResult = await _testRefreshedToken();
            if (!testResult) {
              _logger.w('Refreshed token failed validation test');
            }
            
            // Reset refresh attempts counter on success
            _refreshAttempts = 0;
            
            return true;
          } else {
            _logger.w('No access token in refresh response');
            return false;
          }
        } catch (e) {
          _logger.e('Error parsing refresh token response: $e');
          _logger.e('Response body: ${response.body}');
          return false;
        }
      } else {
        try {
          final responseText = response.body;
          _logger.e('Token refresh failed with status ${response.statusCode}: $responseText');

          try {
            final data = jsonDecode(responseText);
            _logger.e('Token refresh error details: ${data['message'] ?? data['error'] ?? responseText}');
          } catch (_) {}

          if (response.statusCode == 400 || response.statusCode == 401 || response.statusCode == 403) {
            _logger.i('Clearing invalid tokens due to authentication error');
            await _clearAuthToken();
            
            // Try to re-initialize the service for a fresh start
            await _reinitializeAfterAuthFailure();
          }

          return false;
        } catch (e) {
          _logger.e('Error processing token refresh error: $e');
          return false;
        }
      }
    } catch (e) {
      _logger.e('Token refresh error: $e');
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      if (_accessToken == null) {
        _logger.w('No active session to logout from');
        return true;
      }

      _logger.i('Attempting to logout user');

      final headers = _getAuthHeaders(includeAuth: true);
      if (_refreshToken != null) {
        headers['X-Stack-Refresh-Token'] = _refreshToken!;
      }

      final response = await http.delete(
        Uri.parse('$_authApiUrl${ApiConstants.authSessionCurrent}'),
        headers: headers,
      );

      _logger.i('Logout response status code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        await _clearAuthToken();
        _logger.i('Logout successful, tokens cleared');
        return true;
      } else {
        try {
          final data = jsonDecode(response.body);
          _logger.e('Logout failed: ${data['message'] ?? response.reasonPhrase}');
        } catch (e) {
          _logger.e('Error parsing logout response: $e');
        }
        await _clearAuthToken();
        return false;
      }
    } catch (e) {
      _logger.e('Logout error: $e');
      await _clearAuthToken();
      return false;
    }
  }

  Future<List<ChatSession>> getConversations() async {
    try {
      final queryParams = {
        'assistantModel': 'dify',
        'limit': '100',
      };

      // Add assistantId if we have a selected model
      if (_selectedModel != null && _selectedModel!.isNotEmpty) {
        queryParams['assistantId'] = _selectedModel!;
      }

      final uri = Uri.parse('$_jarvisApiUrl/api/v1/ai-chat/conversations')
          .replace(queryParameters: queryParams);

      _logger.i('Getting conversations: $uri');
      _logger.d('Auth token present: ${_accessToken != null}');

      final headers = _getHeaders();
      _logger.d('Request headers: $headers');

      final response = await http.get(
        uri,
        headers: headers,
      );

      _logger.d('Conversations response code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<ChatSession> conversations = [];

        for (var item in data['items'] ?? []) {
          conversations.add(ChatSession(
            id: item['id'] ?? '',
            title: item['title'] ?? 'New Chat',
            createdAt: item['createdAt'] != null
                ? DateTime.fromMillisecondsSinceEpoch(item['createdAt'] * 1000)
                : DateTime.now(),
          ));
        }

        return conversations;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _logger.w('Authentication error (${response.statusCode}) when getting conversations, attempting token refresh');

        // Log the response for debugging
        _logger.d('Auth error response: ${response.body}');

        final refreshSuccess = await refreshToken();
        if (refreshSuccess) {
          _logger.i('Token refreshed successfully, retrying get conversations');
          return await getConversations(); // Recursive call after refresh
        }

        // If token refresh fails, try a second approach with reinitialization
        _logger.w('Token refresh failed, trying reinitialization before giving up');
        await _reinitializeAfterAuthFailure();
        
        // Check if reinitialization restored authentication
        if (_accessToken != null) {
          _logger.i('Reinitialization successful, retrying with new token');
          return await getConversations();
        }

        _logger.e('Failed to get conversations after token refresh and reinitialization');
        throw 'Authentication failed. Please log in again.';
      } else {
        _logger.e('Failed to get conversations: ${response.statusCode}, ${response.reasonPhrase}');
        _logger.e('Response body: ${response.body}');
        final data = jsonDecode(response.body);
        throw data['message'] ?? 'Error fetching conversations';
      }
    } catch (e) {
      _logger.e('Get conversations error: $e');
      throw e.toString();
    }
  }

  Future<List<Message>> getConversationHistory(String conversationId) async {
    try {
      // Validate conversation ID to avoid API errors
      if (conversationId.isEmpty || conversationId.startsWith('local_')) {
        _logger.w('Invalid or local conversation ID: $conversationId');
        return [];
      }

      final queryParams = {
        'assistantModel': 'dify',
        'limit': '100',
      };

      // Add assistantId if we have a selected model
      if (_selectedModel != null && _selectedModel!.isNotEmpty) {
        queryParams['assistantId'] = _selectedModel!;
      }

      final uri = Uri.parse('$_jarvisApiUrl/api/v1/ai-chat/conversations/$conversationId/messages')
          .replace(queryParameters: queryParams);

      _logger.i('Getting conversation history: $uri');

      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );

      // Log detailed response for debugging
      _logger.d('Conversation history response: [${response.statusCode}] ${response.reasonPhrase}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Message> messages = [];

        for (var item in data['items'] ?? []) {
          if (item.containsKey('query')) {
            // This is a user message
            messages.add(Message(
              text: item['query'] ?? '',
              isUser: true,
              timestamp: item['createdAt'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(item['createdAt'] * 1000)
                  : DateTime.now(),
            ));
          }

          if (item.containsKey('answer')) {
            // This is an AI message
            messages.add(Message(
              text: item['answer'] ?? '',
              isUser: false,
              timestamp: item['createdAt'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(item['createdAt'] * 1000)
                  : DateTime.now(),
            ));
          }
        }

        return messages;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _logger.w('Authentication error (${response.statusCode}) when getting conversation history');
        
        // Extract and log WWW-Authenticate header for debugging
        if (response.headers.containsKey('www-authenticate')) {
          _logger.w('WWW-Authenticate: ${response.headers['www-authenticate']}');
        }
        
        // Log detailed error information
        try {
          final errorData = jsonDecode(response.body);
          _logger.w('Error details: $errorData');
          
          // Check for scope-related errors
          if (response.statusCode == 403 && 
              errorData.toString().toLowerCase().contains('scope')) {
            _logger.e('Possible missing required scopes. Token may not have proper permissions.');
          }
        } catch (_) {}

        // Attempt token refresh
        final refreshSuccess = await refreshToken();
        if (refreshSuccess) {
          _logger.i('Token refreshed successfully, retrying get conversation history');
          return await getConversationHistory(conversationId); // Recursive call after refresh
        }

        _logger.e('Failed to get conversation history after token refresh');
        _logger.e('Response body: ${response.body}');
        throw 'Unauthorized: Token may not have proper scopes for accessing conversation history';
      } else {
        _logger.e('Failed to get conversation history: ${response.statusCode}, ${response.reasonPhrase}');
        _logger.e('Response body: ${response.body}');
        final data = jsonDecode(response.body);
        throw data['message'] ?? 'Error fetching conversation history';
      }
    } catch (e) {
      _logger.e('Get conversation history error: $e');
      throw e.toString();
    }
  }

  Future<Message> sendMessage(String conversationId, String text) async {
    try {
      _logger.i('Sending message to conversation: $conversationId');

      // Get selected model, default to Gemini 1.5 Flash
      String modelId = _selectedModel ?? 'gemini-1.5-flash-latest';
      String modelName = ApiConstants.modelNames[modelId] ?? 'Gemini 1.5 Flash';

      // Prepare the request body according to the documentation
      final requestBody = {
        'content': text,
        'files': [],
        'metadata': {
          'conversation': {
            'id': conversationId,
            'messages': []
          }
        },
        'assistant': {
          'id': modelId,
          'model': 'dify',
          'name': modelName
        }
      };

      _logger.i('Message request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_jarvisApiUrl/api/v1/ai-chat/messages'),
        headers: _getHeaders(),
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        _logger.i('Message sent successfully, conversation ID: ${data['conversationId']}');

        return Message(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        );
      } else {
        _logger.e('Failed to send message: ${response.statusCode}, ${response.reasonPhrase}');
        _logger.e('Response body: ${response.body}');

        try {
          final errorData = jsonDecode(response.body);
          throw errorData['message'] ?? 'Error sending message';
        } catch (e) {
          throw 'Error sending message: ${response.reasonPhrase}';
        }
      }
    } catch (e) {
      _logger.e('Send message error: $e');
      throw e.toString();
    }
  }

  Future<ChatSession> createConversation(String title) async {
    try {
      _logger.i('Creating new conversation with title: $title');

      // Get selected model, default to Gemini 1.5 Flash
      String modelId = _selectedModel ?? 'gemini-1.5-flash-latest';
      String modelName = ApiConstants.modelNames[modelId] ?? 'Gemini 1.5 Flash';

      // Create a new conversation by sending the first message
      const initialMessage = 'Hello'; // Initial system message

      final requestBody = {
        'content': initialMessage,
        'files': [],
        'metadata': {
          'conversation': {
            'messages': []
          }
        },
        'assistant': {
          'id': modelId,
          'model': 'dify',
          'name': modelName
        }
      };

      _logger.i('Create conversation request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_jarvisApiUrl/api/v1/ai-chat/messages'),
        headers: _getHeaders(),
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // Extract conversation ID from response
        final String conversationId = responseData['conversationId'] ?? '';

        if (conversationId.isEmpty) {
          throw 'No conversation ID returned from API';
        }

        return ChatSession(
          id: conversationId,
          title: title.isEmpty ? 'New Chat' : title,
          createdAt: DateTime.now(),
        );
      } else {
        _logger.e('Failed to create conversation: ${response.statusCode}, ${response.reasonPhrase}');
        _logger.e('Response body: ${response.body}');
        final errorData = jsonDecode(response.body);
        throw errorData['message'] ?? 'Error creating conversation';
      }
    } catch (e) {
      _logger.e('Create conversation error: $e');
      throw e.toString();
    }
  }

  Future<void> setSelectedModel(String modelId) async {
    _selectedModel = modelId;

    // Store the selection in preferences for persistence
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedModel', modelId);
      _logger.i('Selected model set to: $modelId');
    } catch (e) {
      _logger.e('Error saving selected model: $e');
    }
  }

  Future<String?> getSelectedModel() async {
    if (_selectedModel != null) {
      return _selectedModel;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedModel = prefs.getString('selectedModel') ?? ApiConstants.defaultModel;
      return _selectedModel;
    } catch (e) {
      _logger.e('Error getting selected model: $e');
      return ApiConstants.defaultModel;
    }
  }

  Future<bool> deleteConversation(String conversationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_jarvisApiUrl/api/v1/ai-chat/conversations/$conversationId'),
        headers: _getHeaders(),
      );

      return (response.statusCode == 200 || response.statusCode == 204);
    } catch (e) {
      _logger.e('Delete conversation error: $e');
      return false;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      if (!isAuthenticated()) {
        _logger.w('Cannot get current user: Not authenticated');
        return null;
      }

      _logger.i('Getting current user profile');

      final response = await http.get(
        Uri.parse('$_jarvisApiUrl/user/profile'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = data['data'] ?? data;

        _logger.i('Successfully retrieved user profile');

        // Extract metadata from Stack Auth response
        Map<String, dynamic>? clientMetadata;
        Map<String, dynamic>? clientReadOnlyMetadata;
        Map<String, dynamic>? serverMetadata;
        
        // Check if metadata fields exist in response
        if (userData.containsKey('client_metadata')) {
          clientMetadata = userData['client_metadata'];
          _logger.d('Found client metadata in user profile');
        }
        
        if (userData.containsKey('client_read_only_metadata')) {
          clientReadOnlyMetadata = userData['client_read_only_metadata'];
          _logger.d('Found client read-only metadata in user profile');
        }
        
        if (userData.containsKey('server_metadata')) {
          serverMetadata = userData['server_metadata'];
          _logger.d('Found server metadata in user profile');
        }

        return UserModel(
          uid: userData['id'] ?? _userId ?? '',
          email: userData['email'] ?? '',
          name: userData['name'],
          createdAt: userData['created_at'] != null
              ? DateTime.parse(userData['created_at'])
              : DateTime.now(),
          isEmailVerified: userData['email_verified'] ?? true,
          selectedModel: userData['selected_model'] ?? ApiConstants.defaultModel,
          clientMetadata: clientMetadata,
          clientReadOnlyMetadata: clientReadOnlyMetadata,
          serverMetadata: serverMetadata,
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _logger.w('Authentication error (${response.statusCode}) when getting user profile, attempting token refresh');

        final refreshSuccess = await refreshToken();
        if (refreshSuccess) {
          _logger.i('Token refreshed successfully, retrying get user profile');

          final retryResponse = await http.get(
            Uri.parse('$_jarvisApiUrl/user/profile'),
            headers: _getHeaders(),
          );

          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            final userData = data['data'] ?? data;

            _logger.i('Successfully retrieved user profile after token refresh');

            return UserModel(
              uid: userData['id'] ?? _userId ?? '',
              email: userData['email'] ?? '',
              name: userData['name'],
              createdAt: userData['created_at'] != null
                  ? DateTime.parse(userData['created_at'])
                  : DateTime.now(),
              isEmailVerified: userData['email_verified'] ?? true,
              selectedModel: userData['selected_model'] ?? ApiConstants.defaultModel,
              clientMetadata: userData['client_metadata'],
              clientReadOnlyMetadata: userData['client_read_only_metadata'],
              serverMetadata: userData['server_metadata'],
            );
          }
        }

        _logger.w('Token refresh failed or retry failed, user may need to re-authenticate');
        return null;
      } else {
        _logger.w('Failed to get current user: ${response.statusCode}');

        try {
          final errorData = jsonDecode(response.body);
          _logger.w('Error response: $errorData');
        } catch (e) {
          _logger.w('Could not parse error response: ${response.body}');
        }

        if (_userId != null) {
          _logger.i('Creating fallback user model with stored user ID: $_userId');
          return UserModel(
            uid: _userId!,
            email: '',
            createdAt: DateTime.now(),
            isEmailVerified: true,
          );
        }

        return null;
      }
    } catch (e) {
      _logger.e('Get current user error: $e');
      return null;
    }
  }

  /// Update client metadata for the user
  Future<bool> updateUserClientMetadata(Map<String, dynamic> metadata) async {
    try {
      _logger.i('Updating user client metadata');
      
      final response = await http.patch(
        Uri.parse('$_jarvisApiUrl/user/metadata/client'),
        headers: _getHeaders(),
        body: jsonEncode(metadata),
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        _logger.i('Client metadata updated successfully');
        return true;
      } else {
        _logger.e('Failed to update client metadata: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.e('Error updating client metadata: $e');
      return false;
    }
  }

  /// Update server metadata for the user (requires server key)
  Future<bool> updateUserServerMetadata(Map<String, dynamic> metadata) async {
    try {
      _logger.i('Updating user server metadata');
      
      // This operation can't be performed from client apps as it requires server key
      _logger.w('Server metadata update requires server privileges and cannot be performed from client app');
      return false;
    } catch (e) {
      _logger.e('Error updating server metadata: $e');
      return false;
    }
  }

  /// Update client read-only metadata for the user (requires server key)
  Future<bool> updateUserClientReadOnlyMetadata(Map<String, dynamic> metadata) async {
    try {
      _logger.i('Updating user client read-only metadata');
      
      // This operation can't be performed from client apps as it requires server key
      _logger.w('Client read-only metadata update requires server privileges and cannot be performed from client app');
      return false;
    } catch (e) {
      _logger.e('Error updating client read-only metadata: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> checkEmailVerificationStatus() async {
    try {
      if (_accessToken == null || _userId == null) {
        _logger.w('Cannot check verification status without token and user ID');
        return null;
      }

      _logger.i('Checking email verification status directly');

      final response = await http.get(
        Uri.parse('$_authApiUrl${ApiConstants.authEmailVerificationStatus}'),
        headers: _getAuthHeaders(includeAuth: true),
      );

      _logger.i('Verification status check response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Verification status data: $data');
        return data['data'] ?? data;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final refreshSuccess = await refreshToken();
        if (refreshSuccess) {
          return await checkEmailVerificationStatus();
        }
      }

      _logger.w('Verification status check failed, defaulting to verified');
      return {'is_verified': true, 'email': ''};
    } catch (e) {
      _logger.e('Error checking verification status: $e');
      return {'is_verified': true, 'email': ''};
    }
  }

  Future<bool> forceTokenRefresh() async {
    try {
      _logger.i('Forcing token refresh');

      if (_refreshToken == null) {
        _logger.w('Cannot force refresh without a refresh token');
        return false;
      }

      _accessToken = null;

      return await refreshToken();
    } catch (e) {
      _logger.e('Force token refresh error: $e');
      return false;
    }
  }

  Future<bool> verifyTokenValid() async {
    try {
      if (_accessToken == null) {
        return false;
      }

      final response = await http.get(
        Uri.parse('$_jarvisApiUrl/status'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return await refreshToken();
      } else {
        return false;
      }
    } catch (e) {
      _logger.e('Token verification error: $e');
      return false;
    }
  }

  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final apiData = {};
      data.forEach((key, value) {
        final snakeKey = key.replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        );
        apiData[snakeKey] = value;
      });

      final response = await http.put(
        Uri.parse('$_jarvisApiUrl/user/profile'),
        headers: _getHeaders(),
        body: jsonEncode(apiData),
      );

      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Update user profile error: $e');
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_jarvisApiUrl/user/change-password'),
        headers: _getHeaders(),
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Change password error: $e');
      return false;
    }
  }

  Map<String, String> _getAuthHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Stack-Access-Type': 'client',
      'X-Stack-Project-Id': _stackProjectId ?? ApiConstants.stackProjectId,
      'X-Stack-Publishable-Client-Key': _stackPublishableClientKey ?? ApiConstants.stackPublishableClientKey,
    };

    if (_apiKey != null && _apiKey!.isNotEmpty) {
      headers['X-API-KEY'] = _apiKey!;
    }

    if (includeAuth && _accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_apiKey != null && _apiKey!.isNotEmpty) {
      headers['X-API-KEY'] = _apiKey!;
    }

    if (includeAuth && _accessToken != null && _accessToken!.isNotEmpty) {
      // Ensure token is properly formatted with Bearer prefix
      if (_accessToken!.startsWith('Bearer ')) {
        headers['Authorization'] = _accessToken!;
      } else {
        headers['Authorization'] = 'Bearer $_accessToken';
      }
      
      // Include the stack authentication related headers as well
      headers['X-Stack-Access-Type'] = 'client';
      headers['X-Stack-Project-Id'] = _stackProjectId ?? ApiConstants.stackProjectId;
      headers['X-Stack-Publishable-Client-Key'] = _stackPublishableClientKey ?? ApiConstants.stackPublishableClientKey;
      
      // Add X-Jarvis-GUID for request tracking
      headers['X-Jarvis-GUID'] = _generateRequestId();
    }

    return headers;
  }
  
  // Generate a simple request ID for tracking
  String _generateRequestId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = now % 10000;
    return 'req_$now$random';
  }

  Future<void> _loadAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(ApiConstants.accessTokenKey);
      _refreshToken = prefs.getString(ApiConstants.refreshTokenKey);
      _userId = prefs.getString(ApiConstants.userIdKey);
    } catch (e) {
      _logger.e('Error loading auth token: $e');
    }
  }

  Future<void> _saveAuthToken(String accessToken, String? refreshToken, String? userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiConstants.accessTokenKey, accessToken);
      _accessToken = accessToken;

      if (refreshToken != null) {
        await prefs.setString(ApiConstants.refreshTokenKey, refreshToken);
        _refreshToken = refreshToken;
      }

      if (userId != null) {
        await prefs.setString(ApiConstants.userIdKey, userId);
        _userId = userId;
      }
    } catch (e) {
      _logger.e('Error saving auth token: $e');
    }
  }

  Future<void> _clearAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(ApiConstants.accessTokenKey);
      await prefs.remove(ApiConstants.refreshTokenKey);
      await prefs.remove(ApiConstants.userIdKey);
      _accessToken = null;
      _refreshToken = null;
      _userId = null;
    } catch (e) {
      _logger.e('Error clearing auth token: $e');
    }
  }

  bool isAuthenticated() {
    return _accessToken != null;
  }

  String? getUserId() {
    return _userId;
  }

  @override
  Future<bool> checkApiStatus() async {
    try {
      // Test with conversations endpoint with minimal data
      final response = await http.get(
        Uri.parse('$_jarvisApiUrl/api/v1/ai-chat/conversations?limit=1'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 401; // 401 means API is available but token is invalid
    } catch (e) {
      _logger.e('API status check failed: $e');
      return false;
    }
  }

  @override
  Map<String, String> getApiConfig() {
    return {
      'authApiUrl': _authApiUrl,
      'jarvisApiUrl': _jarvisApiUrl,
      'knowledgeApiUrl': _knowledgeApiUrl,
      'isAuthenticated': _accessToken != null ? 'Yes' : 'No',
      'hasApiKey': _apiKey != null && _apiKey!.isNotEmpty ? 'Yes' : 'No',
      'stackProjectConfigured': _stackProjectId != null ? 'Yes' : 'No',
    };
  }

  Future<List<Map<String, String>>> getAvailableModels() async {
    try {
      final response = await http.get(
        Uri.parse('$_jarvisApiUrl${ApiConstants.models}'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, String>> models = [];

        for (var item in data['data'] ?? []) {
          models.add({
            'id': item['id'] ?? '',
            'name': item['name'] ?? item['id'] ?? 'Unknown Model',
          });
        }

        return models;
      } else {
        return ApiConstants.modelNames.entries.map((entry) => {
          'id': entry.key,
          'name': entry.value,
        }).toList();
      }
    } catch (e) {
      _logger.e('Get available models error: $e');
      return ApiConstants.modelNames.entries.map((entry) => {
        'id': entry.key,
        'name': entry.value,
      }).toList().take(2).toList();
    }
  }

  // Helper to test if the refreshed token works with better diagnostics
  Future<bool> _testRefreshedToken() async {
    try {
      // First check token format to ensure scopes are present
      if (_accessToken != null) {
        _logTokenInfo(_accessToken!);
      }
      
      // Use a more reliable endpoint for testing token validity
      // The conversations endpoint with a small limit is a good test
      final response = await http.get(
        Uri.parse('$_jarvisApiUrl/api/v1/ai-chat/conversations?limit=1'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 3));
      
      _logger.i('Token test response: [${response.statusCode}] ${response.reasonPhrase}');
      
      // Consider these status codes as successful for token validation
      final isValid = response.statusCode == 200 || 
                      response.statusCode == 204 || 
                      response.statusCode == 404; // 404 might mean no conversations yet
      
      if (response.statusCode == 403) {
        _logger.w('Token validation test failed with 403 Forbidden - likely a Stack Auth scopes issue');
        // Extract and log WWW-Authenticate header for debugging if available
        if (response.headers.containsKey('www-authenticate')) {
          _logger.w('WWW-Authenticate: ${response.headers['www-authenticate']}');
        }
        
        // Check for specific scope-related errors in response body
        try {
          final data = jsonDecode(response.body);
          if (data.toString().toLowerCase().contains('scope') || 
              data.toString().toLowerCase().contains('permission')) {
            _logger.e('Stack Auth scope issue detected in response: $data');
            
            // Force token refresh with proper scopes
            _logger.i('Attempting to refresh token with proper scopes');
            await forceTokenRefresh();
          }
        } catch (_) {}
      }
      
      _logger.i('Refreshed token test: ${isValid ? 'Valid' : 'Invalid'} (${response.statusCode})');
      return isValid;
    } catch (e) {
      _logger.w('Error testing refreshed token: $e');
      return false;
    }
  }
  
  // Decode and log token information for debugging
  void _logTokenInfo(String token) {
    try {
      // Extract the payload part of the JWT (second part)
      final parts = token.split('.');
      if (parts.length != 3) {
        _logger.w('Invalid JWT format');
        return;
      }
      
      // Decode the base64 payload
      String payload = parts[1];
      // Add any necessary padding
      payload = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(payload));
      final data = jsonDecode(decoded);
      
      // Log key token information 
      _logger.i('Token info:');
      _logger.i('- Subject: ${data['sub'] ?? 'not found'}');
      _logger.i('- Expiration: ${data['exp'] != null ? DateTime.fromMillisecondsSinceEpoch(data['exp'] * 1000) : 'not found'}');
      
      // Check if token uses Stack Auth format
      if (data.containsKey('iss')) {
        _logger.i('- Issuer: ${data['iss'] ?? 'not found'}');
        
        // Check if issuer is Stack Auth
        if (data['iss'].toString().contains('stack-auth')) {
          _logger.i('Token issued by Stack Auth');
          
          // Stack Auth specific token checks
          if (data.containsKey('client_id')) {
            _logger.i('- Client ID: ${data['client_id']}');
            
            // Verify client ID matches our Stack project ID
            if (data['client_id'] != _stackProjectId) {
              _logger.w('Client ID in token does not match project ID. Expected: $_stackProjectId, Got: ${data['client_id']}');
            }
          }
        }
      }
      
      // Log scopes if available
      if (data.containsKey('scope')) {
        final scopes = data['scope'];
        _logger.i('- Scopes: $scopes');
        
        // Check if all required scopes are present
        final scopesList = scopes is String ? scopes.split(' ') : [];
        final missingScopes = ApiConstants.requiredScopes
            .where((scope) => !scopesList.contains(scope))
            .toList();
            
        if (missingScopes.isNotEmpty) {
          _logger.w('Missing required scopes: $missingScopes');
        }
      } else {
        _logger.w('No scopes found in token');
      }
    } catch (e) {
      _logger.e('Error decoding token: $e');
    }
  }

  // Check if token has all required scopes
  Future<bool> verifyTokenHasScopes(List<String> requiredScopes) async {
    try {
      _logger.i('Checking if token has required scopes: $requiredScopes');
      
      if (_accessToken == null) {
        _logger.w('No access token available to check scopes');
        return false;
      }
      
      // Parse the JWT and check scopes
      final parts = _accessToken!.split('.');
      if (parts.length != 3) {
        _logger.w('Invalid JWT format');
        return false;
      }
      
      String payload = parts[1];
      payload = base64.normalize(payload);
      
      try {
        final decoded = utf8.decode(base64.decode(payload));
        final data = jsonDecode(decoded);
        
        // Check if token has scope claim
        if (!data.containsKey('scope')) {
          _logger.w('Token does not contain scope claim');
          return false;
        }
        
        // Parse scopes from space-delimited string
        final tokenScopes = (data['scope'] as String).split(' ');
        _logger.i('Token has scopes: $tokenScopes');
        
        // Check if all required scopes are present
        final missingScopes = requiredScopes
            .where((scope) => !tokenScopes.contains(scope))
            .toList();
            
        if (missingScopes.isNotEmpty) {
          _logger.w('Token is missing required scopes: $missingScopes');
          return false;
        }
        
        _logger.i('Token has all required scopes');
        return true;
      } catch (e) {
        _logger.e('Error parsing token payload: $e');
        return false;
      }
    } catch (e) {
      _logger.e('Error checking token scopes: $e');
      return false;
    }
  }

  // Circuit breaker to prevent infinite refresh loops
  int _refreshAttempts = 0;
  static const int _maxRefreshAttempts = 2;
  DateTime? _lastRefreshAttempt;

  // Implement a method to switch to fallback mode
  void switchToFallbackMode() {
    _logger.i('Switching to fallback API mode due to persistent authentication issues.');
    // This method will be called by JarvisChatService or auth providers
    _clearAuthToken();
  }

  // Reinitialize after authentication failure
  Future<void> _reinitializeAfterAuthFailure() async {
    try {
      _logger.i('Attempting to reinitialize service after auth failure');
      // Wait a short time before trying again
      await Future.delayed(const Duration(seconds: 1));
      await initialize();
    } catch (e) {
      _logger.e('Failed to reinitialize service: $e');
    }
  }
  
  // Mask sensitive data in logs
  Map<String, dynamic> _maskAuthData(Map<String, dynamic> data) {
    final masked = Map<String, dynamic>.from(data);
    if (masked.containsKey('access_token')) {
      masked['access_token'] = _maskToken(masked['access_token']);
    }
    if (masked.containsKey('refresh_token')) {
      masked['refresh_token'] = _maskToken(masked['refresh_token']);
    }
    return masked;
  }
  
  String _maskToken(String? token) {
    if (token == null || token.isEmpty) return '***null***';
    if (token.length <= 10) return '***short***';
    return '${token.substring(0, 5)}...${token.substring(token.length - 5)}';
  }
}
