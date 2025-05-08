import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../constants/api_constants.dart';
import '../auth/auth_service.dart';

class JarvisApiService {
  static final JarvisApiService _instance = JarvisApiService._internal();
  factory JarvisApiService() => _instance;

  final Logger _logger = Logger();
  late String _authApiUrl;
  late AuthService _authService;

  JarvisApiService._internal() {
    _authApiUrl = ApiConstants.authApiUrl;
  }

  Future<void> initialize(AuthService authService) async {
    try {
      _authService = authService;
      // Use the _authService at least once to avoid the unused field warning
      _logger.i('Initialized Jarvis API service with Auth API URL: $_authApiUrl for user: ${_authService.getUserId() ?? "unknown"}');
    } catch (e) {
      _logger.e('Error initializing Jarvis API service: $e');
    }
  }

  Future<Map<String, dynamic>> signUp(String email, String password) async {
    try {
      _logger.i('Attempting to sign up user with email: $email');
      final requestBody = {
        'email': email, 
        'password': password,
        'verification_callback_url': ApiConstants.verificationCallbackUrl
      };
      final url = Uri.parse('$_authApiUrl${ApiConstants.authPasswordSignUp}');
      final headers = {
        'Content-Type': 'application/json',
        'X-Stack-Access-Type': 'client',
        'X-Stack-Project-Id': ApiConstants.stackProjectId,
        'X-Stack-Publishable-Client-Key': ApiConstants.stackPublishableClientKey,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      _logger.i('Sign-up response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Sign-up successful');
        return data;
      } else {
        // Parse error response
        final errorBody = response.body;
        _logger.e('Sign-up failed: $errorBody');
        
        try {
          final errorJson = jsonDecode(errorBody);
          if (errorJson.containsKey('code')) {
            final errorCode = errorJson['code'];
            
            if (errorCode == 'USER_EMAIL_ALREADY_EXISTS') {
              throw 'Email đã được sử dụng. Vui lòng sử dụng email khác.';
            }
            
            if (errorJson.containsKey('error')) {
              throw errorJson['error'];
            }
          }
        } catch (e) {
          if (e is String) {
            throw e;
          }
        }
        
        throw 'Sign-up failed: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Sign-up error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      _logger.i('Attempting to sign in user with email: $email');
      final requestBody = {'email': email, 'password': password};
      final url = Uri.parse('$_authApiUrl${ApiConstants.authPasswordSignIn}');
      final headers = {
        'Content-Type': 'application/json',
        'X-Stack-Access-Type': 'client',
        'X-Stack-Project-Id': ApiConstants.stackProjectId,
        'X-Stack-Publishable-Client-Key': ApiConstants.stackPublishableClientKey,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      _logger.i('Sign-in response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Sign-in successful');
        return data;
      } else {
        // Parse error response
        final errorBody = response.body;
        _logger.e('Sign-in failed: $errorBody');
        
        try {
          final errorJson = jsonDecode(errorBody);
          if (errorJson.containsKey('code')) {
            final errorCode = errorJson['code'];
            
            if (errorCode == 'EMAIL_PASSWORD_MISMATCH') {
              throw 'Email hoặc mật khẩu không đúng. Vui lòng thử lại.';
            }
            
            if (errorJson.containsKey('error')) {
              throw errorJson['error'];
            }
          }
        } catch (e) {
          if (e is String) {
            throw e;
          }
        }
        
        throw 'Sign-in failed: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Sign-in error: $e');
      rethrow;
    }
  }

  Future<bool> signOut(String accessToken, String? refreshToken) async {
    try {
      _logger.i('Signing out user');
      
      final url = Uri.parse('$_authApiUrl${ApiConstants.authSessionCurrent}');
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'X-Stack-Access-Type': 'client',
        'X-Stack-Project-Id': ApiConstants.stackProjectId,
        'X-Stack-Publishable-Client-Key': ApiConstants.stackPublishableClientKey,
      };
      
      // Add refresh token if available
      if (refreshToken != null) {
        headers['X-Stack-Refresh-Token'] = refreshToken;
      }
      
      _logger.i('Sending logout request to: $url');
      
      // Send DELETE request to logout endpoint
      final response = await http.delete(
        url,
        headers: headers,
        body: '{}', // Empty JSON body
      );
      
      _logger.i('Logout response status code: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        _logger.i('Logout API call successful');
        return true;
      } else {
        _logger.e('Logout API call failed: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.e('Sign-out error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      _logger.i('Attempting to refresh access token');
      
      final url = Uri.parse('$_authApiUrl${ApiConstants.authSessionRefresh}');
      final headers = {
        'X-Stack-Access-Type': 'client',
        'X-Stack-Project-Id': ApiConstants.stackProjectId,
        'X-Stack-Publishable-Client-Key': ApiConstants.stackPublishableClientKey,
        'X-Stack-Refresh-Token': refreshToken,
      };
      
      final response = await http.post(url, headers: headers);
      
      _logger.i('Refresh token response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Access token refreshed successfully');
        return data;
      } else {
        _logger.e('Failed to refresh token: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        return {};
      }
    } catch (e) {
      _logger.e('Refresh token error: $e');
      return {};
    }
  }
}
