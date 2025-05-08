import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../../core/services/auth/auth_service.dart';
import '../models/knowledge_base_model.dart';
import '../../../core/constants/app_config.dart';

class KnowledgeBaseService {
  // Using just the base domain without the path
  final String baseUrl = "https://knowledge-api.dev.jarvis.cx";
  final String apiPath = "/kb-core/v1/knowledge";
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();

  // Get authentication token from auth service
  Future<String> _getToken() async {
    try {
      // Make sure auth service is initialized
      await _authService.initializeService();
      
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication token not available. Please log in again.');
      }
      return token;
    } catch (e) {
      print('Error getting authentication token: $e');
      throw Exception('Authentication failed: $e');
    }
  }

  // Create a new knowledge base
  Future<KnowledgeBase> createKnowledgeBase({
    required String name,
    required String description,
  }) async {
    final token = await _getToken();
    
    // Print debugging info
    print('Creating knowledge base with URL: $baseUrl$apiPath');
    
    final response = await http.post(
      Uri.parse('$baseUrl$apiPath'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
      }),
    );

    // Print response status for debugging
    print('Create knowledge base response status: ${response.statusCode}');
    
    if (response.statusCode == 201) {
      return KnowledgeBase.fromJson(jsonDecode(response.body));
    } else {
      print('Error response body: ${response.body}');
      throw Exception('Failed to create knowledge base: ${response.body}');
    }
  }

  // Get all knowledge bases
  Future<List<KnowledgeBase>> getKnowledgeBases({
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      // Debug output
      final requestUrl = Uri.parse('$baseUrl$apiPath').replace(queryParameters: queryParams);
      print('Fetching knowledge bases from: $requestUrl');
      
      final response = await http.get(
        requestUrl,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      // Debug output
      print('Knowledge bases response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['items'] == null) {
          print('API returned null items: $data');
          return [];
        }
        return (data['items'] as List)
            .map((item) => KnowledgeBase.fromJson(item))
            .toList();
      } else {
        print('Error response body: ${response.body}');
        throw Exception('Failed to get knowledge bases: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Exception in getKnowledgeBases: $e');
      rethrow;
    }
  }

  // Get a single knowledge base by ID
  Future<KnowledgeBase> getKnowledgeBase(String id) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl$apiPath/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final kb = KnowledgeBase.fromJson(jsonDecode(response.body));
      
      // Get sources (datasources) for this knowledge base
      final sourcesResponse = await http.get(
        Uri.parse('$baseUrl$apiPath/$id/datasources'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (sourcesResponse.statusCode == 200) {
        final sourcesData = jsonDecode(sourcesResponse.body);
        final sources = (sourcesData['items'] as List?)
            ?.map((source) => KnowledgeSource.fromJson(source))
            .toList() ?? [];
            
        return KnowledgeBase(
          id: kb.id,
          name: kb.name,
          description: kb.description,
          status: kb.status,
          createdAt: kb.createdAt,
          updatedAt: kb.updatedAt,
          sources: sources,
        );
      }
      
      return kb;
    } else {
      throw Exception('Failed to get knowledge base: ${response.body}');
    }
  }

  // Delete a knowledge base
  Future<void> deleteKnowledgeBase(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl$apiPath/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete knowledge base: ${response.body}');
    }
  }

  // Upload a local file to a knowledge base
  Future<KnowledgeSource> uploadLocalFile(
    String knowledgeBaseId,
    File file,
  ) async {
    final token = await _getToken();
    final fileName = file.path.split('/').last;
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
    });

    final response = await _dio.post(
      '$baseUrl$apiPath/$knowledgeBaseId/datasources/file',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.statusCode == 201) {
      return KnowledgeSource.fromJson(response.data);
    } else {
      throw Exception('Failed to upload file: ${response.data}');
    }
  }

  // Upload website URL to knowledge base
  Future<KnowledgeSource> uploadWebsite(
    String knowledgeBaseId,
    String url,
  ) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl$apiPath/$knowledgeBaseId/datasources/website'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'url': url,
      }),
    );

    if (response.statusCode == 201) {
      return KnowledgeSource.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to upload website: ${response.body}');
    }
  }

  // Connect to Google Drive
  Future<KnowledgeSource> connectGoogleDrive(
    String knowledgeBaseId,
    String googleDriveFileId,
  ) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl$apiPath/$knowledgeBaseId/datasources/google-drive'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'fileId': googleDriveFileId,
      }),
    );

    if (response.statusCode == 201) {
      return KnowledgeSource.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to connect Google Drive: ${response.body}');
    }
  }

  // Connect to Slack
  Future<KnowledgeSource> connectSlack(
    String knowledgeBaseId,
    String channelId,
  ) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl$apiPath/$knowledgeBaseId/datasources/slack'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'channelId': channelId,
      }),
    );

    if (response.statusCode == 201) {
      return KnowledgeSource.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to connect Slack: ${response.body}');
    }
  }

  // Connect to Confluence
  Future<KnowledgeSource> connectConfluence(
    String knowledgeBaseId,
    String spaceKey,
  ) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl$apiPath/$knowledgeBaseId/datasources/confluence'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'spaceKey': spaceKey,
      }),
    );

    if (response.statusCode == 201) {
      return KnowledgeSource.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to connect Confluence: ${response.body}');
    }
  }

  // Delete a source from a knowledge base
  Future<void> deleteSource(
    String knowledgeBaseId,
    String sourceId,
  ) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl$apiPath/$knowledgeBaseId/datasources/$sourceId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete source: ${response.body}');
    }
  }
}