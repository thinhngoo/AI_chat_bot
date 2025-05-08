import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../../core/services/auth/auth_service.dart';
import '../models/knowledge_base_model.dart';
import '../../../core/constants/app_config.dart';
import 'package:path/path.dart' as path;

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
    try {
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
          'knowledgeName': name,
          'description': description,
        }),
      );

      // Print response status for debugging
      print('Create knowledge base response status: ${response.statusCode}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Response data: $responseData');
        
        return KnowledgeBase.fromJson(responseData);
      } else {
        print('Error response body: ${response.body}');
        throw Exception('Failed to create knowledge base: ${response.body}');
      }
    } catch (e) {
      print('Error creating knowledge base: $e');
      throw Exception('Error creating knowledge base: $e');
    }
  }

  // Get all knowledge bases with pagination support
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
        if (data['data'] == null) {
          print('API returned null data: $data');
          return [];
        }
        return (data['data'] as List)
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
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl$apiPath/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Get knowledge base response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final kb = KnowledgeBase.fromJson(jsonDecode(response.body));
        
        // Get data sources for this knowledge base
        return await _getKnowledgeBaseWithSources(kb);
      } else {
        print('Error response body: ${response.body}');
        throw Exception('Failed to get knowledge base: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching knowledge base: $e');
      rethrow;
    }
  }

  // Helper method to get sources for a knowledge base
  Future<KnowledgeBase> _getKnowledgeBaseWithSources(KnowledgeBase kb) async {
    try {
      final token = await _getToken();
      final sourcesResponse = await http.get(
        Uri.parse('$baseUrl$apiPath/${kb.id}/units'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('Get knowledge sources response status: ${sourcesResponse.statusCode}');
      
      if (sourcesResponse.statusCode == 200) {
        final sourcesData = jsonDecode(sourcesResponse.body);
        final sources = (sourcesData['data'] as List?)
            ?.map((source) => KnowledgeSource.fromJson(source))
            .toList() ?? [];
            
        return KnowledgeBase(
          id: kb.id,
          knowledgeName: kb.knowledgeName,
          description: kb.description,
          status: kb.status,
          userId: kb.userId,
          createdBy: kb.createdBy,
          updatedBy: kb.updatedBy,
          createdAt: kb.createdAt,
          updatedAt: kb.updatedAt,
          sources: sources,
        );
      }
      
      return kb;
    } catch (e) {
      print('Error fetching knowledge sources: $e');
      return kb;  // Return original knowledge base without sources
    }
  }

  // Update a knowledge base
  Future<KnowledgeBase> updateKnowledgeBase({
    required String id,
    String? name,
    String? description,
  }) async {
    try {
      final token = await _getToken();
      
      final Map<String, dynamic> body = {};
      if (name != null) body['knowledgeName'] = name;
      if (description != null) body['description'] = description;
      
      print('Updating knowledge base: $baseUrl$apiPath/$id');
      
      final response = await http.patch(
        Uri.parse('$baseUrl$apiPath/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      
      print('Update knowledge base response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return KnowledgeBase.fromJson(responseData);
      } else {
        print('Error response body: ${response.body}');
        throw Exception('Failed to update knowledge base: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error updating knowledge base: $e');
      rethrow;
    }
  }

  // Delete a knowledge base
  Future<bool> deleteKnowledgeBase(String id) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl$apiPath/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete knowledge base response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('Error response body: ${response.body}');
        throw Exception('Failed to delete knowledge base: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error deleting knowledge base: $e');
      rethrow;
    }
  }

  // Get units (sources) of a knowledge base
  Future<List<KnowledgeSource>> getKnowledgeUnits(String knowledgeId) async {
    try {
      final token = await _getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl$apiPath/$knowledgeId/units'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('Get knowledge units response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] == null) {
          return [];
        }
        return (data['data'] as List)
            .map((item) => KnowledgeSource.fromJson(item))
            .toList();
      } else {
        print('Error response body: ${response.body}');
        throw Exception('Failed to get knowledge units: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching knowledge units: $e');
      rethrow;
    }
  }

  // Upload a local file to a knowledge base
  Future<KnowledgeSource> uploadLocalFile(
    String knowledgeBaseId,
    File file,
  ) async {
    try {
      final token = await _getToken();
      final fileName = path.basename(file.path);
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      
      print('Uploading file to knowledge base: $baseUrl$apiPath/$knowledgeBaseId/upload');
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      });

      final response = await _dio.post(
        '$baseUrl$apiPath/$knowledgeBaseId/upload',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('Upload file response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return KnowledgeSource.fromJson(response.data);
      } else {
        print('Error response: ${response.data}');
        throw Exception('Failed to upload file: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  // Upload website URL to knowledge base
  Future<KnowledgeSource> uploadWebsite(
    String knowledgeBaseId,
    String url,
    {bool recursive = true}
  ) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl$apiPath/$knowledgeBaseId/upload/website'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'url': url,
          'recursive': recursive,
        }),
      );

      print('Upload website response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return KnowledgeSource.fromJson(jsonDecode(response.body));
      } else {
        print('Error response body: ${response.body}');
        throw Exception('Failed to upload website: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error uploading website: $e');
      rethrow;
    }
  }

  // Connect to Google Drive
  Future<KnowledgeSource> connectGoogleDrive(
    String knowledgeBaseId,
    String googleDriveFileId,
  ) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl$apiPath/$knowledgeBaseId/upload/google-drive'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fileId': googleDriveFileId,
        }),
      );

      print('Connect Google Drive response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return KnowledgeSource.fromJson(jsonDecode(response.body));
      } else {
        print('Error response body: ${response.body}');
        throw Exception('Failed to connect Google Drive: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error connecting Google Drive: $e');
      rethrow;
    }
  }

  // Connect to Slack
  Future<KnowledgeSource> connectSlack(
    String knowledgeBaseId,
    String channelId,
  ) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl$apiPath/$knowledgeBaseId/upload/slack'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'channelId': channelId,
        }),
      );

      print('Connect Slack response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return KnowledgeSource.fromJson(jsonDecode(response.body));
      } else {
        print('Error response body: ${response.body}');
        throw Exception('Failed to connect Slack: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error connecting Slack: $e');
      rethrow;
    }
  }

  // Connect to Confluence
  Future<KnowledgeSource> connectConfluence(
    String knowledgeBaseId,
    String spaceKey,
  ) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl$apiPath/$knowledgeBaseId/upload/confluence'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'spaceKey': spaceKey,
        }),
      );

      print('Connect Confluence response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return KnowledgeSource.fromJson(jsonDecode(response.body));
      } else {
        print('Error response body: ${response.body}');
        throw Exception('Failed to connect Confluence: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error connecting Confluence: $e');
      rethrow;
    }
  }

  // Delete a source from a knowledge base
  Future<bool> deleteSource(
    String knowledgeBaseId,
    String sourceId,
  ) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl$apiPath/$knowledgeBaseId/units/$sourceId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete knowledge source response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('Error response body: ${response.body}');
        throw Exception('Failed to delete source: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error deleting source: $e');
      rethrow;
    }
  }
}