import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api_constants.dart';
import '../api/jarvis_api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final Logger _logger = Logger();
  final JarvisApiService _apiService = JarvisApiService();
  
  bool _isInitialized = false;
  String? _accessToken;
  String? _refreshToken;

  AuthService._internal();

  Future<void> initializeService() async {
    if (_isInitialized) return;
    
    _logger.i('Initializing Auth Service');
    await _loadAuthToken();
    await _apiService.initialize(this);
    _isInitialized = true;
  }

  Future<bool> signUpWithEmailAndPassword(
    String email, 
    String password, 
    {String? name}
  ) async {
    try {
      _logger.i('Signing up user with email: $email');
      final response = await _apiService.signUp(email, password);
      
      if (response.containsKey('access_token') && response.containsKey('refresh_token')) {
        await _saveAuthToken(response['access_token'], response['refresh_token']);
        return true;
      }
      
      throw 'Invalid signup response format';
    } catch (e) {
      _logger.e('Error during sign up: $e');
      throw e.toString();
    }
  }

  Future<bool> signInWithEmailAndPassword(
    String email, 
    String password
  ) async {
    try {
      _logger.i('Signing in user with email: $email');
      final response = await _apiService.signIn(email, password);
      
      if (response.containsKey('access_token') && response.containsKey('refresh_token')) {
        await _saveAuthToken(response['access_token'], response['refresh_token']);
        return true;
      }
      
      throw 'Invalid signin response format';
    } catch (e) {
      _logger.e('Error during sign in: $e');
      throw e.toString();

    }
  }

  Future<bool> signOut() async {
    try {
      _logger.i('Signing out user');
      if (_accessToken != null) {
        await _apiService.signOut(_accessToken!, _refreshToken);
      }
      await _clearAuthToken();
      return true;
    } catch (e) {
      _logger.e('Error during sign out: $e');
      // Still clear tokens locally even if API call fails
      await _clearAuthToken();
      return true;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      await _loadAuthToken();
      return _accessToken != null && _accessToken!.isNotEmpty;
    } catch (e) {
      _logger.e('Error checking login status: $e');
      return false;
    }
  }

  Future<bool> forceAuthStateUpdate() async {
    try {
      // Simply check login status again to force update
      return await isLoggedIn();
    } catch (e) {
      _logger.e('Error forcing auth state update: $e');
      return false;
    }
  }

  Future<bool> refreshToken() async {
    try {
      _logger.i('Requesting token refresh');
      if (_refreshToken == null) {
        _logger.w('Cannot refresh token: No refresh token available');
        return false;
      }
      
      final response = await _apiService.refreshToken(_refreshToken!);
      
      if (response.containsKey('access_token')) {
        await _saveAuthToken(response['access_token'], null);
        return true;
      }
      
      return false;
    } catch (e) {
      _logger.e('Error during token refresh: $e');
      return false;
    }
  }

  // Token management methods moved from JarvisApiService
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

  // Getter for access token - for JarvisApiService to use
  String? get accessToken => _accessToken;
}
