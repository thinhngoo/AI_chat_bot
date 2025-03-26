import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class ApiService {
  final Logger _logger = Logger();
  // Base URLs for different API providers
  final String _geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  final String _grokBaseUrl = 'https://api.xai.com/v1'; 
  final String _openaiBaseUrl = 'https://api.openai.com/v1';
  
  // Default model
  String _currentModel = 'gemini-2.0-flash';
  
  bool _useFallbackResponses = false;
  int _consecutiveFailures = 0;
  final int _maxRetries = 2;
  
  // Message history to maintain context
  final List<Map<String, dynamic>> _conversationHistory = [];
  
  // Define model types for provider-specific handling
  static const String providerGemini = 'gemini';
  static const String providerGrok = 'grok';
  static const String providerOpenai = 'openai';
  
  // Model information - add Grok and ChatGPT models
  static const List<String> availableModels = [
    // Gemini models
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-1.0-pro',
    'gemini-2.0-flash',
    // OpenAI models
    'gpt-3.5-turbo',
    'gpt-4o',
    // Grok models
    'grok-1',
    'grok-2',
  ];
  
  static const Map<String, String> modelNames = {
    // Gemini models
    'gemini-1.5-flash': 'Gemini 1.5 Flash',
    'gemini-1.5-pro': 'Gemini 1.5 Pro',
    'gemini-1.0-pro': 'Gemini 1.0 Pro',
    'gemini-2.0-flash': 'Gemini 2.0 Flash',
    // OpenAI models
    'gpt-3.5-turbo': 'ChatGPT 3.5 Turbo',
    'gpt-4o': 'ChatGPT 4o',
    // Grok models
    'grok-1': 'Grok 1',
    'grok-2': 'Grok 2',
  };
  
  static const Map<String, String> modelDescriptions = {
    // Gemini models
    'gemini-1.5-flash': 'Fast, good for most interactions',
    'gemini-1.5-pro': 'More powerful, better for complex tasks',
    'gemini-1.0-pro': 'Stable, well-tested version',
    'gemini-2.0-flash': 'Latest fast model with improved capabilities',
    // OpenAI models
    'gpt-3.5-turbo': 'Fast and efficient, good for most tasks',
    'gpt-4o': 'Latest and most powerful ChatGPT model',
    // Grok models
    'grok-1': 'Grok\'s baseline model with real-time information',
    'grok-2': 'Grok\'s advanced model for complex reasoning',
  };
  
  // Map models to their providers
  static const Map<String, String> modelProviders = {
    // Gemini models
    'gemini-1.5-flash': providerGemini,
    'gemini-1.5-pro': providerGemini,
    'gemini-1.0-pro': providerGemini,
    'gemini-2.0-flash': providerGemini,
    // OpenAI models
    'gpt-3.5-turbo': providerOpenai,
    'gpt-4o': providerOpenai,
    // Grok models
    'grok-1': providerGrok,
    'grok-2': providerGrok,
  };
  
  // Mock responses for fallback mode
  final List<String> _fallbackResponses = [
    'Xin chào, tôi là trợ lý ảo. Tôi đang chạy ở chế độ ngoại tuyến do API Gemini đang tạm thời không khả dụng.',
    'Dịch vụ API đang gặp vấn đề. Tôi sẽ hoạt động ở chế độ ngoại tuyến cho đến khi dịch vụ được khôi phục.',
    'Rất tiếc, máy chủ API Gemini hiện không khả dụng (lỗi 503). Vui lòng thử lại sau vài phút.',
    'API đang bảo trì hoặc gặp sự cố tạm thời. Tôi đang chạy ở chế độ ngoại tuyến với khả năng giới hạn.',
    'Tôi đang hoạt động ở chế độ hạn chế do máy chủ API đang quá tải. Trạng thái hiện tại: 503 Service Unavailable.',
  ];
  
  // Getter for current model
  String get currentModel => _currentModel;
  
  // Get the provider for the current model
  String get currentProvider => modelProviders[_currentModel] ?? providerGemini;
  
  // Method to set current model
  void setModel(String model) {
    if (availableModels.contains(model)) {
      _logger.i('Changing AI model from $_currentModel to $model');
      _currentModel = model;
    } else {
      _logger.w('Attempted to set invalid model: $model. Using default model.');
      _currentModel = 'gemini-2.0-flash';
    }
  }
  
  Future<String> getDeepSeekResponse(String userMessage) async {
    // Add user message to conversation history
    _addUserMessage(userMessage);
    
    // Check if we're already in fallback mode
    if (_useFallbackResponses) {
      return _getFallbackResponse();
    }
    
    try {
      // Check if .env is loaded at all
      if (!dotenv.isInitialized) {
        _logger.e('.env file is not loaded. Make sure it exists in the project root directory.');
        _useFallbackResponses = true;
        return 'Lỗi: Không thể tải file .env. Vui lòng đảm bảo file .env tồn tại trong thư mục gốc của dự án và chứa các API key cần thiết.';
      }
      
      // Get appropriate API key based on the current model provider
      final apiKey = _getApiKeyForCurrentProvider();
      
      // If API key is missing or using placeholder, switch to fallback mode
      if (apiKey == null || apiKey.isEmpty || apiKey.contains('your_') || apiKey == 'demo_api_key') {
        _logger.w('Valid API key not found for provider $currentProvider, using fallback mode');
        _useFallbackResponses = true;
        return _getFallbackResponse();
      }
      
      // Try up to _maxRetries times for transient errors
      for (int attempt = 0; attempt <= _maxRetries; attempt++) {
        if (attempt > 0) {
          _logger.i('Retry attempt $attempt for API call after transient error');
          // Add exponential backoff delay between retries
          await Future.delayed(Duration(milliseconds: 500 * pow(2, attempt).toInt()));
        }
        
        try {
          // Call appropriate API based on the current model
          String? response;
          
          switch (currentProvider) {
            case providerGemini:
              response = await _callGeminiApi(userMessage, apiKey);
              break;
            case providerOpenai:
              response = await _callOpenAIApi(userMessage, apiKey);
              break;
            case providerGrok:
              response = await _callGrokApi(userMessage, apiKey);
              break;
            default:
              throw 'Unsupported model provider: $currentProvider';
          }
          
          if (response != null) {
            // Reset failure counter on success
            _consecutiveFailures = 0;
            
            // Add assistant response to conversation history
            _addAssistantResponse(response);
            
            return response;
          } else {
            throw 'Received null response from $currentProvider API';
          }
        } catch (e) {
          // Handle specific API errors
          if (e.toString().contains('503') || e.toString().contains('Service Unavailable')) {
            if (attempt < _maxRetries) {
              _logger.w('503 Service Unavailable error, retrying...');
              continue;
            }
            
            // After max retries, track consecutive failures
            _consecutiveFailures++;
            if (_consecutiveFailures >= 2) {
              _useFallbackResponses = true;
              return 'Dịch vụ API ${modelNames[_currentModel]} đang không khả dụng (Lỗi 503). Đã chuyển sang chế độ ngoại tuyến. '
                  'Vui lòng thử lại sau. Lỗi: ${e.toString()}';
            }
          } else if (e.toString().contains('401') || e.toString().contains('403')) {
            _useFallbackResponses = true;
            return 'Lỗi xác thực API ${modelNames[_currentModel]} (401/403). Chuyển sang chế độ ngoại tuyến. '
                'Vui lòng kiểm tra API key của bạn trong file .env và khởi động lại ứng dụng.';
          } else if (e.toString().contains('429')) {
            _consecutiveFailures++;
            return 'Đã vượt quá giới hạn tần suất gọi API ${modelNames[_currentModel]} (429 Too Many Requests). Vui lòng thử lại sau ít phút.';
          } else if (attempt < _maxRetries && (e is http.ClientException || e.toString().contains('timeout'))) {
            _logger.w('Network error during API call, will retry: $e');
            continue;
          }
          
          // Re-throw for the outer catch block to handle
          rethrow;
        }
      }
      
      // If we get here, all retries failed
      throw 'Không thể kết nối đến API ${modelNames[_currentModel]} sau nhiều lần thử. Dịch vụ có thể đang bảo trì.';
    } catch (e) {
      _logger.e('Error calling API: $e');
      
      // Track consecutive failures and potentially switch to fallback mode
      _consecutiveFailures++;
      if (_consecutiveFailures >= 3) {
        _useFallbackResponses = true;
        
        // Create a user-friendly message
        final errorResponse = 'Đã xảy ra lỗi liên tục khi gọi API. Chuyển sang chế độ ngoại tuyến.\n\n'
            'Lỗi: ${e.toString()}\n\n'
            'Các lỗi thường gặp:\n'
            '• 503: Dịch vụ tạm thời không khả dụng (đang bảo trì hoặc quá tải)\n'
            '• Lỗi mạng: Kiểm tra kết nối internet của bạn\n'
            '• Lỗi API key: Đảm bảo API key hợp lệ trong file .env';
        
        _addAssistantResponse(errorResponse);
        return errorResponse;
      }
      
      // General error handling
      final errorResponse = 'Đã xảy ra lỗi khi gọi API ${modelNames[_currentModel]}: ${e.toString()}\n\n'
          'Hướng dẫn khắc phục:\n'
          '1. Kiểm tra kết nối mạng\n'
          '2. Đảm bảo đã thêm API key hợp lệ vào file .env\n'
          '3. Thử chọn mô hình AI khác';
      
      _addAssistantResponse(errorResponse);
      return errorResponse;
    }
  }
  
  // Get API key based on the current provider
  String? _getApiKeyForCurrentProvider() {
    switch (currentProvider) {
      case providerGemini:
        return dotenv.env['GEMINI_API_KEY'];
      case providerOpenai:
        return dotenv.env['OPENAI_API_KEY'];
      case providerGrok:
        return dotenv.env['GROK_API_KEY'];
      default:
        return null;
    }
  }
  
  // Call Gemini API (existing implementation, modified for clarity)
  Future<String?> _callGeminiApi(String userMessage, String apiKey) async {
    _logger.i('Calling Gemini API with model: $_currentModel');
    
    // Create request body for Gemini API
    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': userMessage}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      }
    };
    
    // Generate endpoint URL for the specific model
    final endpoint = '$_geminiBaseUrl/$_currentModel:generateContent';
    
    // Make API call
    final response = await http.post(
      Uri.parse('$endpoint?key=$apiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    ).timeout(const Duration(seconds: 15));
    
    // Process response
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Extract text from Gemini response format
      final assistantResponse = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 
          'Không thể trích xuất phản hồi từ API Gemini.';
      
      return assistantResponse;
    } else {
      _logger.e('Gemini API error: ${response.statusCode}, ${response.body}');
      throw 'Lỗi từ API Gemini: ${response.statusCode} - ${_getErrorMessage(response.body)}';
    }
  }
  
  // Call OpenAI API (ChatGPT)
  Future<String?> _callOpenAIApi(String userMessage, String apiKey) async {
    _logger.i('Calling OpenAI API with model: $_currentModel');
    
    // Create request body for OpenAI API
    final requestBody = {
      'model': _currentModel,
      'messages': [
        {'role': 'system', 'content': 'You are a helpful assistant.'},
        {'role': 'user', 'content': userMessage}
      ],
      'temperature': 0.7,
      'max_tokens': 1024,
    };
    
    // Make API call
    final response = await http.post(
      Uri.parse('$_openaiBaseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(requestBody),
    ).timeout(const Duration(seconds: 20)); // Longer timeout for OpenAI
    
    // Process response
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Extract text from OpenAI response format
      final assistantResponse = data['choices']?[0]?['message']?['content'] ?? 
          'Không thể trích xuất phản hồi từ OpenAI API.';
      
      return assistantResponse;
    } else {
      _logger.e('OpenAI API error: ${response.statusCode}, ${response.body}');
      throw 'Lỗi từ OpenAI API: ${response.statusCode} - ${_getErrorMessage(response.body)}';
    }
  }
  
  // Call Grok API
  Future<String?> _callGrokApi(String userMessage, String apiKey) async {
    _logger.i('Calling Grok API with model: $_currentModel');
    
    // Create request body for Grok API - format based on Grok API documentation
    final requestBody = {
      'model': _currentModel,
      'messages': [
        {'role': 'user', 'content': userMessage}
      ],
      'temperature': 0.7,
      'max_tokens': 1024,
      'stream': false,
    };
    
    // Make API call
    final response = await http.post(
      Uri.parse('$_grokBaseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'X-API-Key': apiKey,
      },
      body: jsonEncode(requestBody),
    ).timeout(const Duration(seconds: 20)); // Longer timeout for Grok
    
    // Process response
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Extract text from Grok response format
      final assistantResponse = data['choices']?[0]?['message']?['content'] ?? 
          'Không thể trích xuất phản hồi từ Grok API.';
      
      return assistantResponse;
    } else {
      _logger.e('Grok API error: ${response.statusCode}, ${response.body}');
      throw 'Lỗi từ Grok API: ${response.statusCode} - ${_getErrorMessage(response.body)}';
    }
  }
  
  // Helper method to extract error message from API response
  String _getErrorMessage(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      return data['error']?['message'] ?? 'Unknown error';
    } catch (e) {
      return 'Unable to parse error message';
    }
  }
  
  // Helper method to add user message to conversation history in Gemini format
  void _addUserMessage(String message) {
    _conversationHistory.add({
      'role': 'user',
      'parts': [{'text': message}]
    });
  }
  
  // Helper method to add assistant response to conversation history in Gemini format
  void _addAssistantResponse(String message) {
    _conversationHistory.add({
      'role': 'model',
      'parts': [{'text': message}]
    });
  }
  
  String _getFallbackResponse() {
    // Get a random response from the fallback list
    final random = Random();
    final response = _fallbackResponses[random.nextInt(_fallbackResponses.length)];
    
    // Add to conversation history
    _addAssistantResponse(response);
    
    return response;
  }
  
  // Method to clear conversation history
  void clearConversationHistory() {
    _conversationHistory.clear();
  }
  
  // Reset fallback mode and failure counter - can be called if user updates API key or service is restored
  void resetFallbackMode() {
    _useFallbackResponses = false;
    _consecutiveFailures = 0;
  }
  
  // Method to manually check if API is available again after being in fallback mode
  Future<bool> checkApiAvailability() async {
    if (!_useFallbackResponses) {
      return true; // Not in fallback mode, so assume API is available
    }
    
    try {
      // Check availability based on current provider
      final apiKey = _getApiKeyForCurrentProvider();
      if (apiKey == null || apiKey.isEmpty || apiKey.contains('your_') || apiKey == 'demo_api_key') {
        return false; // Invalid API key, so API won't be available
      }
      
      switch (currentProvider) {
        case providerGemini:
          final response = await http.get(
            Uri.parse('$_geminiBaseUrl?key=$apiKey'),
          ).timeout(const Duration(seconds: 5));
          return response.statusCode == 200;
          
        case providerOpenai:
          final response = await http.get(
            Uri.parse('$_openaiBaseUrl/models'),
            headers: {'Authorization': 'Bearer $apiKey'},
          ).timeout(const Duration(seconds: 5));
          return response.statusCode == 200;
          
        case providerGrok:
          final response = await http.get(
            Uri.parse('$_grokBaseUrl/models'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'X-API-Key': apiKey,
            },
          ).timeout(const Duration(seconds: 5));
          return response.statusCode == 200;
          
        default:
          return false;
      }
    } catch (e) {
      _logger.w('API still unavailable during availability check: $e');
      return false;
    }
  }
}