import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api_constants.dart';

class JarvisApiService {
  static final JarvisApiService _instance = JarvisApiService._internal();
  factory JarvisApiService() => _instance;

  final Logger _logger = Logger();
  late String _authApiUrl;
  String? _accessToken;
  String? _refreshToken;

  JarvisApiService._internal() {
    _authApiUrl = ApiConstants.authApiUrl;
  }

  Future<void> initialize() async {
    try {
      _logger.i('Initialized Jarvis API service with Auth API URL: $_authApiUrl');
      await _loadAuthToken();
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
        'verification_callback_url': 'https://auth.dev.jarvis.cx/handler/email-verification?after_auth_return_to=%2Fauth%2Fsignin%3Fclient_id%3Djarvis_chat%26redirect%3Dhttps%253A%252F%252Fchat.dev.jarvis.cx%252Fauth%252Foauth%252Fsuccess'
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
        await _saveAuthToken(data['access_token'], data['refresh_token']);
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
        await _saveAuthToken(data['access_token'], data['refresh_token']);
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

  Future<bool> signOut() async {
    try {
      _logger.i('Signing out user');
      await _clearAuthToken();
      return true;
    } catch (e) {
      _logger.e('Sign-out error: $e');
      return false;
    }
  }

  Future<void> _loadAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(ApiConstants.accessTokenKey);
      _refreshToken = prefs.getString(ApiConstants.refreshTokenKey);
      
      if (_accessToken != null) {
        _logger.i('Loaded access token from storage');
      }
    } catch (e) {
      _logger.e('Error loading auth token: $e');
    }
  }

  Future<void> _saveAuthToken(String accessToken, String? refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiConstants.accessTokenKey, accessToken);
      _accessToken = accessToken;
      
      if (refreshToken != null) {
        await prefs.setString(ApiConstants.refreshTokenKey, refreshToken);
        _refreshToken = refreshToken;
      }
      
      _logger.i('Saved auth tokens to storage');
    } catch (e) {
      _logger.e('Error saving auth token: $e');
    }
  }

  Future<void> _clearAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(ApiConstants.accessTokenKey);
      await prefs.remove(ApiConstants.refreshTokenKey);
      _accessToken = null;
      _refreshToken = null;
      _logger.i('Cleared auth tokens from storage');
    } catch (e) {
      _logger.e('Error clearing auth token: $e');
    }
  }
}
