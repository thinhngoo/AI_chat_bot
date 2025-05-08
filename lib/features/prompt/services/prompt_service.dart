import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/auth/auth_service.dart';
import '../models/prompt.dart';

class PromptService {
  final Logger _logger = Logger();
  final AuthService _authService = AuthService();
  final String _baseUrl = ApiConstants.jarvisApiUrl;
  
  // Get prompts with filters
  Future<List<Prompt>> getPrompts({
    bool? isPublic,
    bool? isFavorite,
    String? category,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Ensure auth service is initialized
      await _authService.initializeService();
      final token = _authService.accessToken;
      
      if (token == null) {
        throw 'Not authenticated';
      }
      
      // Build query parameters
      final queryParams = <String, String>{};
      if (isPublic != null) queryParams['is_public'] = isPublic.toString();
      if (isFavorite != null) queryParams['is_favorite'] = isFavorite.toString();
      if (category != null && category.isNotEmpty) queryParams['category'] = category;
      if (searchQuery != null && searchQuery.isNotEmpty) queryParams['search'] = searchQuery;
      queryParams['limit'] = limit.toString();
      queryParams['offset'] = offset.toString();
      
      final uri = Uri.parse('$_baseUrl${ApiConstants.promptsEndpoint}').replace(
        queryParameters: queryParams,
      );
      
      _logger.i('Fetching prompts: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      _logger.i('Prompts response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['items'] == null) {
          _logger.w('API returned null items: $data');
          return []; // Return empty list instead of throwing error
        }
        return (data['items'] as List)
            .map((item) => Prompt.fromJson(item))
            .toList();
      } else {
        _logger.e('Failed to fetch prompts: ${response.body}');
        throw 'Failed to fetch prompts: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error fetching prompts: $e');
      throw 'Error fetching prompts: $e';
    }
  }
  
  // Get prompt by ID
  Future<Prompt> getPromptById(String promptId) async {
    try {
      // Ensure auth service is initialized
      await _authService.initializeService();
      final token = _authService.accessToken;
      
      if (token == null) {
        throw 'Not authenticated';
      }
      
      final uri = Uri.parse('$_baseUrl${ApiConstants.promptsEndpoint}/$promptId');
      
      _logger.i('Fetching prompt: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      _logger.i('Prompt response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Prompt.fromJson(data);
      } else {
        _logger.e('Failed to fetch prompt: ${response.body}');
        throw 'Failed to fetch prompt: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error fetching prompt: $e');
      throw 'Error fetching prompt: $e';
    }
  }
  
  // Create a new prompt
  Future<Prompt> createPrompt({
    required String title,
    required String content,
    required String description,
    required String category,
    required bool isPublic,
  }) async {
    try {
      // Ensure auth service is initialized
      await _authService.initializeService();
      final token = _authService.accessToken;
      
      if (token == null) {
        throw 'Not authenticated';
      }
      
      final uri = Uri.parse('$_baseUrl${ApiConstants.promptsEndpoint}');
      
      final body = jsonEncode({
        'title': title,
        'content': content,
        'description': description,
        'category': category,
        'is_public': isPublic,
      });
      
      _logger.i('Creating prompt: $uri');
      
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );
      
      _logger.i('Create prompt response status code: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Prompt.fromJson(data);
      } else {
        _logger.e('Failed to create prompt: ${response.body}');
        throw 'Failed to create prompt: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error creating prompt: $e');
      throw 'Error creating prompt: $e';
    }
  }
  
  // Update an existing prompt
  Future<Prompt> updatePrompt({
    required String promptId,
    required String title,
    required String content,
    required String description,
    required String category,
    required bool isPublic,
  }) async {
    try {
      // Ensure auth service is initialized
      await _authService.initializeService();
      final token = _authService.accessToken;
      
      if (token == null) {
        throw 'Not authenticated';
      }
      
      final uri = Uri.parse('$_baseUrl${ApiConstants.promptsEndpoint}/$promptId');
      
      final body = jsonEncode({
        'title': title,
        'content': content,
        'description': description,
        'category': category,
        'is_public': isPublic,
      });
      
      _logger.i('Updating prompt: $uri');
      
      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );
      
      _logger.i('Update prompt response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Prompt.fromJson(data);
      } else {
        _logger.e('Failed to update prompt: ${response.body}');
        throw 'Failed to update prompt: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error updating prompt: $e');
      throw 'Error updating prompt: $e';
    }
  }
  
  // Delete a prompt
  Future<bool> deletePrompt(String promptId) async {
    try {
      // Ensure auth service is initialized
      await _authService.initializeService();
      final token = _authService.accessToken;
      
      if (token == null) {
        throw 'Not authenticated';
      }
      
      final uri = Uri.parse('$_baseUrl${ApiConstants.promptsEndpoint}/$promptId');
      
      _logger.i('Deleting prompt: $uri');
      
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      _logger.i('Delete prompt response status code: ${response.statusCode}');
      
      if (response.statusCode == 204) {
        return true;
      } else {
        _logger.e('Failed to delete prompt: ${response.body}');
        throw 'Failed to delete prompt: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error deleting prompt: $e');
      throw 'Error deleting prompt: $e';
    }
  }
  
  // Add prompt to favorites
  Future<bool> addPromptToFavorites(String promptId) async {
    try {
      // Ensure auth service is initialized
      await _authService.initializeService();
      final token = _authService.accessToken;
      
      if (token == null) {
        throw 'Not authenticated';
      }
      
      final uri = Uri.parse('$_baseUrl${ApiConstants.promptsEndpoint}/$promptId/favorite');
      
      _logger.i('Adding prompt to favorites: $uri');
      
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      _logger.i('Add to favorites response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return true;
      } else {
        _logger.e('Failed to add prompt to favorites: ${response.body}');
        throw 'Failed to add prompt to favorites: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error adding prompt to favorites: $e');
      throw 'Error adding prompt to favorites: $e';
    }
  }
  
  // Remove prompt from favorites
  Future<bool> removePromptFromFavorites(String promptId) async {
    try {
      // Ensure auth service is initialized
      await _authService.initializeService();
      final token = _authService.accessToken;
      
      if (token == null) {
        throw 'Not authenticated';
      }
      
      final uri = Uri.parse('$_baseUrl${ApiConstants.promptsEndpoint}/$promptId/favorite');
      
      _logger.i('Removing prompt from favorites: $uri');
      
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      _logger.i('Remove from favorites response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return true;
      } else {
        _logger.e('Failed to remove prompt from favorites: ${response.body}');
        throw 'Failed to remove prompt from favorites: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error removing prompt from favorites: $e');
      throw 'Error removing prompt from favorites: $e';
    }
  }
  
  // Get available prompt categories
  Future<List<String>> getPromptCategories() async {
    try {
      // Ensure auth service is initialized
      await _authService.initializeService();
      final token = _authService.accessToken;
      
      if (token == null) {
        throw 'Not authenticated';
      }
      
      final uri = Uri.parse('$_baseUrl${ApiConstants.promptsEndpoint}/categories');
      
      _logger.i('Fetching prompt categories: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      _logger.i('Categories response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['categories']);
      } else {
        _logger.e('Failed to fetch categories: ${response.body}');
        return []; // Return empty list instead of throwing
      }
    } catch (e) {
      _logger.e('Error fetching categories: $e');
      // Return default categories in case of error
      return [
        'General',
        'Programming',
        'Writing',
        'Business',
        'Education',
        'Health',
        'Entertainment',
        'Other',
      ];
    }
  }
  
  // Search prompts by query (optimized for quick search)
  Future<List<Prompt>> searchPrompts(String query) async {
    try {
      return await getPrompts(
        searchQuery: query,
        limit: 10,
      );
    } catch (e) {
      _logger.e('Error searching prompts: $e');
      return [];
    }
  }
}