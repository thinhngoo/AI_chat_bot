import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../constants/api_constants.dart';

/// Service for direct interaction with the Google Gemini API
class GeminiApiService {
  static final GeminiApiService _instance = GeminiApiService._internal();
  factory GeminiApiService() => _instance;
  
  final Logger _logger = Logger();
  final String _apiKey = ApiConstants.geminiApiKey;
  final String _apiUrl = ApiConstants.geminiApiUrl;
  
  GeminiApiService._internal();
  
  /// Generate content using the Gemini API
  Future<String> generateContent(String prompt, {String? model}) async {
    try {
      _logger.i('Generating content with Gemini API');
      
      final modelName = model ?? 'gemini-2.0-flash';
      final endpoint = '/models/$modelName:generateContent';
      final url = '$_apiUrl$endpoint?key=$_apiKey';
      
      _logger.i('Using model: $modelName');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extract text from the response
        final candidates = data['candidates'] as List;
        if (candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List;
          
          if (parts.isNotEmpty) {
            final text = parts[0]['text'];
            return text;
          }
        }
        
        throw 'No text found in response';
      } else {
        _logger.e('Gemini API error: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        try {
          final data = jsonDecode(response.body);
          final errorMessage = data['error']['message'] ?? 'Unknown error';
          throw errorMessage;
        } catch (jsonError) {
          throw 'Error parsing API response: ${response.body}';
        }
      }
    } catch (e) {
      _logger.e('Error generating content with Gemini API: $e');
      throw 'Failed to generate content: $e';
    }
  }
  
  /// Check if the Gemini API is accessible
  Future<bool> checkApiStatus() async {
    try {
      _logger.i('Checking Gemini API status');
      
      // Simple test query to check API status
      final response = await generateContent('Hello, are you available?');
      
      _logger.i('Gemini API check successful');
      return true;
    } catch (e) {
      _logger.e('Gemini API check failed: $e');
      return false;
    }
  }
  
  /// Directly generate a chat response for a message
  Future<String> generateChatResponse(String message, {List<Map<String, String>>? chatHistory}) async {
    try {
      // Build a prompt that includes chat history if provided
      String fullPrompt = '';
      
      if (chatHistory != null && chatHistory.isNotEmpty) {
        // Format chat history as a conversation
        _logger.i('Building prompt with ${chatHistory.length} previous messages');
        
        for (final entry in chatHistory) {
          final role = entry['role'] ?? 'user';
          final content = entry['content'] ?? '';
          fullPrompt += '$role: $content\n';
        }
        
        // Add the current message
        fullPrompt += 'user: $message\n';
        fullPrompt += 'assistant:';
      } else {
        // No history, just use the message directly
        _logger.i('No chat history, using simple prompt');
        fullPrompt = 'user: $message\nassistant:';
      }
      
      _logger.i('Sending prompt to Gemini API');
      
      // Generate a response
      String response = await generateContent(fullPrompt);
      
      // Clean up the response if needed
      if (response.trim().startsWith('assistant:')) {
        response = response.trim().substring('assistant:'.length).trim();
      }
      
      _logger.i('Received response from Gemini API');
      return response;
    } catch (e) {
      _logger.e('Error generating chat response: $e');
      return "I apologize, but I'm having trouble processing your request right now. Please try again later.";
    }
  }
}
