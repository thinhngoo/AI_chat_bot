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

  AuthService._internal();

  Future<void> initializeService() async {
    if (_isInitialized) return;
    
    _logger.i('Initializing Auth Service');
    await _apiService.initialize();
    _isInitialized = true;
  }

  Future<bool> signUpWithEmailAndPassword(
    String email, 
    String password, 
    {String? name}
  ) async {
    try {
      _logger.i('Signing up user with email: $email');
      await _apiService.signUp(email, password);
      return true;
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
      await _apiService.signIn(email, password);
      return true;
    } catch (e) {
      _logger.e('Error during sign in: $e');
      throw e.toString();
    }
  }

  Future<bool> signOut() async {
    try {
      _logger.i('Signing out user');
      await _apiService.signOut();
      return true;
    } catch (e) {
      _logger.e('Error during sign out: $e');
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConstants.accessTokenKey);
      return token != null && token.isNotEmpty;
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
      return await _apiService.refreshToken();
    } catch (e) {
      _logger.e('Error during token refresh: $e');
      return false;
    }
  }
}
