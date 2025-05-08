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
  String? _userId;
  
  // Thêm biến lưu cache SharedPreferences để giảm thời gian truy cập
  static SharedPreferences? _prefs;

  // Thêm Future để đảm bảo việc khởi tạo chỉ được thực hiện một lần
  static Future<void>? _initFuture;

  AuthService._internal();

  Future<void> initializeService() async {
    if (_isInitialized) return;

    // Khởi tạo một lần và lưu kết quả
    _initFuture ??= _initialize();
    await _initFuture;
    _isInitialized = true;
  }
  
  // Tách logic khởi tạo để dễ quản lý
  Future<void> _initialize() async {
    _logger.i('Initializing Auth Service');
    await _loadAuthToken();
    await _apiService.initialize(this);
  }

  Future<bool> signUpWithEmailAndPassword(
    String email,
    String password, {
    String? name,
  }) async {
    try {
      _logger.i('Signing up user with email: $email');
      final response = await _apiService.signUp(email, password);

      if (response.containsKey('access_token') &&
          response.containsKey('refresh_token')) {
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
    String password,
  ) async {
    try {
      _logger.i('Signing in user with email: $email');
      final response = await _apiService.signIn(email, password);

      if (response.containsKey('access_token') &&
          response.containsKey('refresh_token')) {
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

  // Tối ưu kiểm tra trạng thái đăng nhập
  Future<bool> isLoggedIn() async {
    if (!_isInitialized) {
      await initializeService();
    }
    return _accessToken != null && _accessToken!.isNotEmpty;
  }

  Future<bool> forceAuthStateUpdate() async {
    try {
      _logger.i('Force updating auth state');
      // Xóa cache token và reload
      _accessToken = null;
      _refreshToken = null;
      await _loadAuthToken();
      return _accessToken != null && _accessToken!.isNotEmpty;
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

  // Tối ưu hóa việc đọc token từ SharedPreferences
  Future<void> _loadAuthToken() async {
    try {
      // Sử dụng instance cache nếu có
      _prefs ??= await SharedPreferences.getInstance();
      
      _accessToken = _prefs!.getString(ApiConstants.accessTokenKey);
      _refreshToken = _prefs!.getString(ApiConstants.refreshTokenKey);
      _userId = _prefs!.getString(ApiConstants.userIdKey);

      _logger.i('Loaded tokens from storage: accessToken=${_accessToken != null}, userId=$_userId');
    } catch (e) {
      _logger.e('Error loading auth token: $e');
    }
  }

  Future<void> _saveAuthToken(String accessToken, String? refreshToken) async {
    try {
      // Sử dụng instance cache nếu có
      _prefs ??= await SharedPreferences.getInstance();
      
      await _prefs!.setString(ApiConstants.accessTokenKey, accessToken);
      _accessToken = accessToken;

      if (refreshToken != null) {
        await _prefs!.setString(ApiConstants.refreshTokenKey, refreshToken);
        _refreshToken = refreshToken;
      }

      _logger.i('Saved auth tokens to storage');
    } catch (e) {
      _logger.e('Error saving auth token: $e');
    }
  }

  Future<void> _clearAuthToken() async {
    try {
      // Sử dụng instance cache nếu có
      _prefs ??= await SharedPreferences.getInstance();
      
      await _prefs!.remove(ApiConstants.accessTokenKey);
      await _prefs!.remove(ApiConstants.refreshTokenKey);
      await _prefs!.remove(ApiConstants.userIdKey);
      _accessToken = null;
      _refreshToken = null;
      _userId = null;
      _logger.i('Cleared auth tokens from storage');
    } catch (e) {
      _logger.e('Error clearing auth token: $e');
    }
  }

  // Getter for access token - for JarvisApiService to use
  String? get accessToken => _accessToken;

  // Phương thức tối ưu không cần gọi _loadAuthToken() lại nếu đã khởi tạo
  Future<String?> getToken() async {
    if (!_isInitialized) {
      await initializeService();
    }
    
    // If token appears expired, try refreshing
    if (_accessToken != null && _isTokenExpired(_accessToken!)) {
      await refreshToken();
    }
    
    return _accessToken;
  }
  
  // Helper method to check if token might be expired
  bool _isTokenExpired(String token) {
    try {
      // Basic check - in real app, decode JWT and check expiry
      return false;
    } catch (e) {
      _logger.e('Error checking token expiry: $e');
      return true;
    }
  }

  // Added method to fix JarvisApiService initialization error
  String? getUserId() {
    return _userId;
  }
}
