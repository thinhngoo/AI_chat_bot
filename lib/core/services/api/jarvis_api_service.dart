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

      final requestBody = {
        'email': email,
        'password': password,
        'verification_callback_url': _verificationCallbackUrl,
      };

      if (name != null && name.isNotEmpty) {
        _logger.i('Name provided but will be set after sign-up: $name');
      }

      final response = await http.post(
        Uri.parse('$_authApiUrl${ApiConstants.authPasswordSignUp}'),
        headers: _getAuthHeaders(includeAuth: false),
        body: jsonEncode(requestBody),
      );

      _logger.i('Sign-up response status code: ${response.statusCode}');

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        _logger.e('Error parsing response JSON: $e');
        _logger.e('Response body: ${response.body}');
        throw 'Invalid response from server';
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
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw 'Cannot connect to Jarvis API. Please check your internet connection and API configuration.';
      }
      throw e.toString();
    }
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      _logger.i('Attempting sign-in for email: $email');

      final response = await http.post(
        Uri.parse('$_authApiUrl${ApiConstants.authPasswordSignIn}'),
        headers: _getAuthHeaders(includeAuth: false),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      _logger.i('Sign-in response status code: ${response.statusCode}');

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

      _logger.i('Attempting to refresh auth token');

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

      final response = await http.post(
        Uri.parse('$_authApiUrl${ApiConstants.authSessionRefresh}'),
        headers: headers,
      );

      _logger.i('Token refresh response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          if (data['access_token'] != null) {
            await _saveAuthToken(
              data['access_token'],
              _refreshToken,
              _userId,
            );
            _logger.i('Access token refreshed successfully');
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
      final response = await http.get(
        Uri.parse('$_jarvisApiUrl/api/v1/ai-chat/conversations'),
        headers: _getHeaders(),
      );

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

        final refreshSuccess = await refreshToken();
        if (refreshSuccess) {
          _logger.i('Token refreshed successfully, retrying get conversations');

          final retryResponse = await http.get(
            Uri.parse('$_jarvisApiUrl/api/v1/ai-chat/conversations'),
            headers: _getHeaders(),
          );

          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
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

            _logger.i('Successfully retrieved conversations after token refresh');
            return conversations;
          }
        }

        _logger.e('Failed to get conversations: ${response.statusCode}, ${response.reasonPhrase}');
        _logger.e('Response body: ${response.body}');
        throw 'Unauthorized';
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
      final response = await http.get(
        Uri.parse('$_jarvisApiUrl/api/v1/ai-chat/conversations/$conversationId/messages'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Message> messages = [];

        for (var item in data['items'] ?? []) {
          messages.add(Message(
            text: item['query'] ?? item['answer'] ?? '',
            isUser: item.containsKey('query'),
            timestamp: item['createdAt'] != null
                ? DateTime.fromMillisecondsSinceEpoch(item['createdAt'] * 1000)
                : DateTime.now(),
          ));
        }

        return messages;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _logger.w('Authentication error (${response.statusCode}) when getting conversation history, attempting token refresh');

        final refreshSuccess = await refreshToken();
        if (refreshSuccess) {
          _logger.i('Token refreshed successfully, retrying get conversation history');

          final retryResponse = await http.get(
            Uri.parse('$_jarvisApiUrl/api/v1/ai-chat/conversations/$conversationId/messages'),
            headers: _getHeaders(),
          );

          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            List<Message> messages = [];

            for (var item in data['items'] ?? []) {
              messages.add(Message(
                text: item['query'] ?? item['answer'] ?? '',
                isUser: item.containsKey('query'),
                timestamp: item['createdAt'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(item['createdAt'] * 1000)
                    : DateTime.now(),
              ));
            }

            _logger.i('Successfully retrieved conversation history after token refresh');
            return messages;
          }
        }

        _logger.e('Failed to get conversation history: ${response.statusCode}, ${response.reasonPhrase}');
        _logger.e('Response body: ${response.body}');
        throw 'Unauthorized';
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
      final response = await http.post(
        Uri.parse('$_jarvisApiUrl/api/v1/ai-chat/messages'),
        headers: _getHeaders(),
        body: jsonEncode({
          'content': text,
          'files': [],
          'metadata': {
            'conversation': {
              'id': conversationId,
              'messages': []
            }
          },
          'assistant': {
            'id': 'gemini-1.5-flash-latest',
            'model': 'dify',
            'name': 'Gemini 1.5 Flash'
          }
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        return Message(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        );
      } else {
        _logger.e('Failed to send message: ${response.statusCode}, ${response.reasonPhrase}');
        _logger.e('Response body: ${response.body}');
        final errorData = jsonDecode(response.body);
        throw errorData['message'] ?? 'Error sending message';
      }
    } catch (e) {
      _logger.e('Send message error: $e');
      throw e.toString();
    }
  }

  Future<ChatSession> createConversation(String title) async {
    try {
      // Create a new conversation by sending the first message
      const initialMessage = 'Hello'; // Changed 'final' to 'const'
      
      final response = await http.post(
        Uri.parse('$_jarvisApiUrl/api/v1/ai-chat/messages'),
        headers: _getHeaders(),
        body: jsonEncode({
          'content': initialMessage,
          'files': [],
          'metadata': {
            'conversation': {
              'messages': []
            }
          },
          'assistant': {
            'id': 'gemini-1.5-flash-latest',
            'model': 'dify',
            'name': 'Gemini 1.5 Flash'
          }
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body); // Renamed to responseData to avoid confusion
        
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

        return UserModel(
          uid: userData['id'] ?? _userId ?? '',
          email: userData['email'] ?? '',
          name: userData['name'],
          createdAt: userData['created_at'] != null
              ? DateTime.parse(userData['created_at'])
              : DateTime.now(),
          isEmailVerified: userData['email_verified'] ?? true,
          selectedModel: userData['selected_model'] ?? ApiConstants.defaultModel,
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
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
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
      final response = await http.get(
        Uri.parse('$_jarvisApiUrl/status'),
        headers: _getHeaders(includeAuth: false),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
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
}
