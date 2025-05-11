// Add to pubspec.yaml:
// http_parser: ^4.0.0
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/auth/auth_service.dart';
import '../models/ai_bot.dart';

class BotService {
  static final BotService _instance = BotService._internal();
  factory BotService() => _instance;

  final Logger _logger = Logger();
  final AuthService _authService = AuthService();
  
  // Enhanced caching system with tiered expiration
  List<AIBot>? _cachedBots;
  DateTime? _lastFetchTime;
  String? _cachedUserId; // Track the user ID that owns the cached bots
  bool _isRefreshingCache = false; // Prevent multiple simultaneous refresh requests
  
  // Different timeout levels for better performance
  static const Duration _timeoutDuration = Duration(seconds: 8); 
  static const Duration _backgroundTimeoutDuration = Duration(seconds: 15);
  
  // Tiered cache expiration strategies
  static const Duration _cacheStaleThreshold = Duration(minutes: 1); // Time when cache becomes stale but still usable
  static const Duration _cacheHardExpiration = Duration(minutes: 3); // Time when cache must be refreshed
  
  // Stream controller for notifying listeners about refresh status
  final StreamController<bool> _refreshingStreamController = StreamController<bool>.broadcast();
  Stream<bool> get refreshingStream => _refreshingStreamController.stream;
  
  // Constructor
  BotService._internal() {
    // Listen to auth state changes to clear cache on logout
    _authService.addAuthStateListener(_onAuthStateChanged);
  }
  
  // Method to handle auth state changes
  void _onAuthStateChanged(bool isLoggedIn) {
    if (!isLoggedIn) {
      clearCache();
    }
  }
  
  // Clear cache method
  void clearCache() {
    _logger.i('Clearing BotService cache');
    _cachedBots = null;
    _lastFetchTime = null;
    _cachedUserId = null;
  }
  
  // Check if cache is stale (needs background refresh)
  bool get isCacheStale {
    if (_lastFetchTime == null) return true;
    
    final currentTime = DateTime.now();
    final difference = currentTime.difference(_lastFetchTime!);
    return difference >= _cacheStaleThreshold;
  }

  // Check if cache is expired (must be refreshed)
  bool get isCacheExpired {
    if (_lastFetchTime == null) return true;
    
    final currentTime = DateTime.now();
    final difference = currentTime.difference(_lastFetchTime!);
    return difference >= _cacheHardExpiration;
  }
  
  // Notify refresh status to listeners
  void _setRefreshingStatus(bool isRefreshing) {
    _isRefreshingCache = isRefreshing;
    _refreshingStreamController.add(isRefreshing);
  }
  
  @override
  void dispose() {
    _refreshingStreamController.close();
  }

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
      final accessToken = await _authService.getToken();
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
        'assistantName': name, // Changed from 'name' to 'assistantName' per API spec
        'description': description,
        'instructions': prompt, // Changed from 'prompt' to 'instructions' per API spec
      };
      
      // Build URL
      const baseUrl = ApiConstants.kbCoreApiUrl;
      const endpoint = ApiConstants.assistantsEndpoint;
      final uri = Uri.parse(baseUrl + endpoint);
      
      _logger.i('Sending request to: $uri');
      
      // Send request with timeout
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(_timeoutDuration);
      
      _logger.i('Create bot response status: ${response.statusCode}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Bot created successfully, ID: ${data['id']}');
        
        // Invalidate cache
        clearCache();
        
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

  // Get all AI Bots with improved caching strategy
  Future<List<AIBot>> getBots({String? query, bool forceRefresh = false}) async {
    try {
      // Get current user ID for verification
      final currentUserId = _authService.getUserId();
      
      // User ID mismatch requires a force refresh
      if (_cachedUserId != null && _cachedUserId != currentUserId) {
        _logger.w('User ID mismatch: $_cachedUserId != $currentUserId, clearing cache');
        clearCache();
        forceRefresh = true;
      }
      
      // Check if we can use cache
      if (!forceRefresh && 
          _cachedBots != null && 
          _cachedUserId == currentUserId) {
        
        // If cache isn't completely expired, use it while potentially refreshing in background
        if (!isCacheExpired) {
          _logger.i('Using cached bots list (${_cachedBots!.length} items) for user $_cachedUserId');
          
          // If cache is stale but not expired, refresh in background
          if (isCacheStale && !_isRefreshingCache) {
            _logger.i('Cache is stale, refreshing in background');
            _refreshCacheInBackground(query);
          }
          
          return _cachedBots!;
        }
      }
      
      // If we get here, we need a foreground refresh
      _logger.i('Cache expired or forced refresh, fetching AI Bots');
      return await _fetchBotsFromApi(query, false);
      
    } catch (e) {
      _logger.e('Error in getBots: $e');
      
      // If error is network-related and we have cache, use it regardless of age
      if ((e is SocketException || e is TimeoutException) && _cachedBots != null) {
        _logger.w('Network error, using cached data even though it might be stale');
        return _cachedBots!;
      }
      
      rethrow;
    }
  }
  
  // Background cache refresh
  Future<void> _refreshCacheInBackground(String? query) async {
    if (_isRefreshingCache) return;
    
    _setRefreshingStatus(true);
    
    try {
      await _fetchBotsFromApi(query, true);
    } catch (e) {
      _logger.e('Background refresh failed: $e');
      // Failed background refresh doesn't affect current UI
    } finally {
      _setRefreshingStatus(false);
    }
  }
  
  // Core API fetch method with improved error handling
  Future<List<AIBot>> _fetchBotsFromApi(String? query, bool isBackground) async {
    // Get access token
    final accessToken = await _authService.getToken();
    if (accessToken == null) {
      throw 'No access token available. Please log in again.';
    }
    
    // Prepare headers with required header
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
    
    // Build URL with query parameters
    const baseUrl = ApiConstants.kbCoreApiUrl;
    const endpoint = ApiConstants.assistantsEndpoint;
    
    // Adding pagination parameters using the correct format for this API
    var queryParams = <String, String>{
      'offset': '0',
      'limit': '20',
      'order': 'DESC',
      'order_field': 'createdAt'
    };
    
    if (query != null && query.isNotEmpty) {
      queryParams['q'] = query;
    }
    
    final uri = Uri.parse(baseUrl + endpoint).replace(queryParameters: queryParams);
    
    _logger.i('Request URI: $uri');
    
    // Use longer timeout for background refreshes
    final timeoutDuration = isBackground ? _backgroundTimeoutDuration : _timeoutDuration;
    
    // Send request with timeout
    final response = await http.get(
      uri, 
      headers: headers
    ).timeout(timeoutDuration);
    
    _logger.i('Get bots response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Check if response format matches the API documentation
      if (data['data'] != null) {
        final assistants = data['data'] as List<dynamic>;
        final fetchedBots = assistants.map((item) => AIBot.fromJson(item)).toList();
        
        // Update cache
        _cachedBots = fetchedBots;
        _lastFetchTime = DateTime.now();
        _cachedUserId = _authService.getUserId();
        
        _logger.i('Cached ${_cachedBots!.length} bots for user $_cachedUserId');
        return fetchedBots;
      } else {
        // Log unexpected format
        _logger.w('Unknown response format: $data');
        throw 'Unexpected API response format';
      }
    } else if (response.statusCode == 401) {
      // Token expired, try to refresh
      _logger.w('Token expired, attempting to refresh...');
      final refreshSuccess = await _authService.refreshToken();
      
      if (refreshSuccess) {
        // Retry with new token
        return _fetchBotsFromApi(query, isBackground);
      } else {
        throw 'Authentication expired. Please log in again.';
      }
    } else {
      _logger.e('Failed to fetch bots: ${response.statusCode}');
      _logger.e('Response body: ${response.body}');
      
      throw 'Failed to fetch bots: ${response.statusCode}';
    }
  }
  
  // Get a specific AI Bot by ID - optimized to use cache when possible
  Future<AIBot> getBotById(String botId) async {
    try {
      // Try to find bot in cache first
      if (_cachedBots != null) {
        final cachedBot = _cachedBots!.firstWhere(
          (bot) => bot.id == botId,
          orElse: () => AIBot(
            id: '', 
            name: '', 
            description: '', 
            model: '', 
            prompt: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now()
          ),
        );
        
        if (cachedBot.id.isNotEmpty) {
          _logger.i('Found bot in cache: ${cachedBot.name}');
          
          // If cache is stale, refresh in background but still return cached result
          if (isCacheStale && !_isRefreshingCache) {
            _logger.i('Cache is stale, refreshing single bot in background');
            _refreshSingleBotInBackground(botId);
          }
          
          return cachedBot;
        }
      }
    
      _logger.i('Fetching AI Bot with ID: $botId');
      return await _fetchSingleBotFromApi(botId);
    } catch (e) {
      _logger.e('Error in getBotById: $e');
      rethrow;
    }
  }
  
  // Background refresh for a single bot
  Future<void> _refreshSingleBotInBackground(String botId) async {
    if (_isRefreshingCache) return;
    
    _setRefreshingStatus(true);
    
    try {
      final refreshedBot = await _fetchSingleBotFromApi(botId);
      
      // Update this bot in the cache if cache exists
      if (_cachedBots != null) {
        final index = _cachedBots!.indexWhere((bot) => bot.id == botId);
        if (index >= 0) {
          _cachedBots![index] = refreshedBot;
        }
      }
    } catch (e) {
      _logger.e('Background bot refresh failed: $e');
      // Failed background refresh doesn't affect current UI
    } finally {
      _setRefreshingStatus(false);
    }
  }
  
  // Core API fetch method for a single bot
  Future<AIBot> _fetchSingleBotFromApi(String botId) async {
    // Get access token
    final accessToken = await _authService.getToken();
    if (accessToken == null) {
      throw 'No access token available. Please log in again.';
    }
    
    // Prepare headers
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
    
    // Build URL
    const baseUrl = ApiConstants.kbCoreApiUrl;
    const endpoint = ApiConstants.assistantsEndpoint;
    final uri = Uri.parse('$baseUrl$endpoint/$botId');
    
    _logger.i('Request URI: $uri');
    
    // Send request with timeout
    final response = await http.get(
      uri, 
      headers: headers
    ).timeout(_timeoutDuration);
    
    _logger.i('Get bot response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final bot = AIBot.fromJson(data);
      
      // If we have a full cache, update this bot in the cache
      if (_cachedBots != null) {
        final index = _cachedBots!.indexWhere((b) => b.id == botId);
        if (index >= 0) {
          _cachedBots![index] = bot;
        }
      }
      
      return bot;
    } else if (response.statusCode == 401) {
      // Token expired, try to refresh
      _logger.w('Token expired, attempting to refresh...');
      final refreshSuccess = await _authService.refreshToken();
      
      if (refreshSuccess) {
        // Retry with new token
        return _fetchSingleBotFromApi(botId);
      } else {
        throw 'Authentication expired. Please log in again.';
      }
    } else if (response.statusCode == 404) {
      throw 'Bot not found';
    } else {
      _logger.e('Failed to fetch bot: ${response.statusCode}');
      _logger.e('Response body: ${response.body}');
      
      throw 'Failed to fetch bot: ${response.statusCode}';
    }
  }
}
