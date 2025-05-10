import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../../../core/services/auth/auth_service.dart';
import '../models/knowledge_base_model.dart';
import 'package:path/path.dart' as path;
import 'package:logger/logger.dart';

class KnowledgeBaseService {  // Using just the base domain without the path
  final String baseUrl = 'https://knowledge-api.dev.jarvis.cx';
  final String apiPath = '/kb-core/v1/knowledge';
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();
  // Helper method to log messages both to logger and console for visibility
  void _log(String message, {bool isError = false}) {
    // Check if the message contains a boolean status value for extra debugging
    if (message.contains("status") && (message.contains("true") || message.contains("false"))) {
      // Add runtime type info for boolean values in status fields
      message = "$message (Note: Boolean status values are now handled properly)";
    }
    
    if (isError) {
      _logger.e(message);
      debugPrint('🚫 ERROR: $message');
    } else {
      _logger.d(message);
      debugPrint('📘 DEBUG: $message');
    }
  }

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
      _log('Error getting authentication token: $e', isError: true);
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
      
      // Log debugging info
      _log('Creating knowledge base with URL: $baseUrl$apiPath');
      
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

      // Log response status for debugging
      _log('Create knowledge base response status: ${response.statusCode}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _log('Response data: $responseData');
        
        return KnowledgeBase.fromJson(responseData);
      } else {
        _log('Error response body: ${response.body}', isError: true);
        throw Exception('Failed to create knowledge base: ${response.body}');
      }
    } catch (e) {
      _log('Error creating knowledge base: $e', isError: true);
      throw Exception('Error creating knowledge base: $e');
    }
  }

  // Get all knowledge bases with pagination support
  Future<List<KnowledgeBase>> getKnowledgeBases({
    String? search,
    int page = 1,
    int limit = 10,
    bool includeUnits = true, // Thêm tham số để kiểm soát việc lấy thông tin units
  }) async {
    try {
      final token = await _getToken();
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      // Log output
      final requestUrl = Uri.parse('$baseUrl$apiPath').replace(queryParameters: queryParams);
      _log('Fetching knowledge bases from: $requestUrl');
      
      final response = await http.get(
        requestUrl,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      // Log output
      _log('Knowledge bases response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] == null) {
          _log('API returned null data: $data', isError: true);
          return [];
        }
        
        final List<KnowledgeBase> knowledgeBases = (data['data'] as List)
            .map((item) => KnowledgeBase.fromJson(item))
            .toList();
              // Nếu cần lấy thông tin units, lấy thêm cho mỗi knowledge base
        if (includeUnits) {
          _log('Including units - fetching sources for each knowledge base');
          List<KnowledgeBase> result = [];
          for (var kb in knowledgeBases) {
            try {
              _log('Fetching sources for knowledge base ${kb.id} (${kb.knowledgeName})');
              final kbWithSources = await _getKnowledgeBaseWithSources(kb);
              _log('Retrieved ${kbWithSources.sources.length} sources for knowledge base ${kb.id}');
              _log('Units count from getter: ${kbWithSources.unitCount}');
              _log('Total size from getter: ${kbWithSources.totalSize} bytes');
              
              // Log details of each source for debugging
              for (var source in kbWithSources.sources) {
                _log('Source details: id=${source.id}, name=${source.name}, type=${source.type}, fileSize=${source.fileSize}');
              }
              
              result.add(kbWithSources);
            } catch (e) {
              _log('Error fetching sources for knowledge base ${kb.id}: $e', isError: true);
              result.add(kb); // Vẫn thêm kb mà không có sources nếu có lỗi
            }
          }
          return result;
        }
        
        return knowledgeBases;
      } else {
        _log('Error response body: ${response.body}', isError: true);
        throw Exception('Failed to get knowledge bases: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      _log('Exception in getKnowledgeBases: $e', isError: true);
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

      _log('Get knowledge base response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final kb = KnowledgeBase.fromJson(jsonDecode(response.body));
        
        // Get data sources for this knowledge base
        return await _getKnowledgeBaseWithSources(kb);
      } else {
        _log('Error response body: ${response.body}', isError: true);
        throw Exception('Failed to get knowledge base: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      _log('Error fetching knowledge base: $e', isError: true);
      rethrow;
    }
  }
  // Helper method to get sources for a knowledge base
  Future<KnowledgeBase> _getKnowledgeBaseWithSources(KnowledgeBase kb) async {
    try {
      final token = await _getToken();
      
      _log('Fetching datasources for knowledge base ID: ${kb.id}');
      
      // Using the /datasources endpoint according to the API documentation
      final sourcesResponse = await http.get(
        Uri.parse('$baseUrl$apiPath/${kb.id}/datasources'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      _log('Get knowledge sources response status: ${sourcesResponse.statusCode}');
      _log('Response headers: ${sourcesResponse.headers}');
      
      if (sourcesResponse.statusCode == 200) {
        final responseBody = sourcesResponse.body;
        _log('Raw response body: $responseBody');
        
        final sourcesData = jsonDecode(responseBody);
        _log('Decoded sourcesData: $sourcesData');
        
        // Try to extract data from different possible structures
        List<dynamic>? sourcesList;
        
        if (sourcesData is List) {
          // API returns direct list
          sourcesList = sourcesData;
          _log('API returned direct list of datasources');
        } else if (sourcesData is Map) {
          // API returns object with 'data' field or another structure
          if (sourcesData.containsKey('data')) {
            final dataField = sourcesData['data'];
            if (dataField is List) {
              sourcesList = dataField;
              _log('Found datasources in data field as list');
            } else if (dataField is Map && dataField.containsKey('datasources')) {
              sourcesList = dataField['datasources'] as List?;
              _log('Found datasources in data.datasources field');
            }
          } else if (sourcesData.containsKey('datasources')) {
            sourcesList = sourcesData['datasources'] as List?;
            _log('Found datasources directly in datasources field');
          } else if (sourcesData.containsKey('items')) {
            sourcesList = sourcesData['items'] as List?;
            _log('Found datasources in items field');
          } else if (sourcesData.containsKey('sources')) {
            sourcesList = sourcesData['sources'] as List?;
            _log('Found datasources in sources field');
          }
        }
        
        // If we still don't have a sourcesList, try other options
        sourcesList ??= [];
        _log('Final knowledge sources list length: ${sourcesList.length}');
        
        // Log each source with its fileSize for debugging
        for (var source in sourcesList) {
          _log('Source raw data: $source');
          
          if (source is Map) {
            String id = source['id'] ?? source['sourceId'] ?? source['datasourceId'] ?? 'unknown';
            String name = source['name'] ?? source['fileName'] ?? source['title'] ?? 'Unnamed';
            dynamic fileSize = source['fileSize'] ?? source['size'] ?? source['bytes'] ?? null;
            
            _log('Source: id=$id, name=$name, fileSize=$fileSize, type=${fileSize?.runtimeType}');
          }
        }
          // Process the list
        final sources = sourcesList
            .map((source) => KnowledgeSource.fromJson(source))
            .toList();
        
        _log('Successfully parsed ${sources.length} datasources');
        
        // Calculate and log total size with more detail
        int totalCalculatedSize = 0;
        Set<String> processedIds = {};
        
        for (var source in sources) {
          // Skip duplicate sources with the same ID
          if (processedIds.contains(source.id)) {
            _log('Skipping duplicate source ID=${source.id} when calculating total size');
            continue;
          }
          
          processedIds.add(source.id);
          
          if (source.fileSize != null && source.fileSize! > 0) {
            totalCalculatedSize += source.fileSize!;
            _log('  - Source ${source.name} adds ${source.fileSize} bytes to total');
          } else if (source.status == 'active' || source.status == 'indexed') {
            // For active sources without size, assume a minimal size
            _log('  - Source ${source.name} has no size but is active. Assuming 1 byte.');
            totalCalculatedSize += 1;
          }
        }
        
        _log('Total size calculated: $totalCalculatedSize bytes');
            
        // Create and return updated knowledge base with sources
        final updatedKnowledgeBase = KnowledgeBase(
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
        
        // Log the total size from the getter to verify calculation
        _log('Total size from knowledge base getter: ${updatedKnowledgeBase.totalSize} bytes');
        
        return updatedKnowledgeBase;
      } else {
        _log('Error response body: ${sourcesResponse.body}', isError: true);
        // Return the original knowledge base if the API call fails
        return kb;
      }
    } catch (e) {
      _log('Error fetching knowledge sources: $e', isError: true);
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
      
      _log('Updating knowledge base: $baseUrl$apiPath/$id');
      
      final response = await http.patch(
        Uri.parse('$baseUrl$apiPath/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      
      _log('Update knowledge base response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return KnowledgeBase.fromJson(responseData);
      } else {
        _log('Error response body: ${response.body}', isError: true);
        throw Exception('Failed to update knowledge base: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      _log('Error updating knowledge base: $e', isError: true);
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

      _log('Delete knowledge base response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        _log('Error response body: ${response.body}', isError: true);
        throw Exception('Failed to delete knowledge base: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      _log('Error deleting knowledge base: $e', isError: true);
      rethrow;
    }
  }
  // Get units (sources) of a knowledge base - legacy endpoint, might be deprecated
  Future<List<KnowledgeSource>> getKnowledgeUnits(String knowledgeId) async {
    try {
      final token = await _getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl$apiPath/$knowledgeId/units'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      _log('Get knowledge units response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] == null) {
          return [];
        }
        return (data['data'] as List)
            .map((item) => KnowledgeSource.fromJson(item))
            .toList();
      } else {
        _log('Error response body: ${response.body}', isError: true);
        throw Exception('Failed to get knowledge units: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      _log('Error fetching knowledge units: $e', isError: true);
      rethrow;
    }
  }
  
  // Get all datasources for a knowledge base - new method using the correct endpoint
  // https://www.apidog.com/apidoc/shared/f30d2953-f010-4ef7-a360-69f9eaf457f7/get-datasource-from-knowledge-16714988e0
  Future<List<KnowledgeSource>> getDatasources(String knowledgeId) async {
    try {
      final token = await _getToken();
      
      _log('Getting datasources for knowledge base ID: $knowledgeId');
      
      final response = await http.get(
        Uri.parse('$baseUrl$apiPath/$knowledgeId/datasources'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      _log('Get datasources response status: ${response.statusCode}');
      _log('Get datasources response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        final responseBody = response.body;
        _log('Raw response body: $responseBody');
        
        final responseData = jsonDecode(responseBody);
        _log('Decoded response data: $responseData');
        
        // Try to extract datasources from different possible structures
        List<dynamic>? sourcesList;
        
        if (responseData is List) {
          // API returns direct list
          sourcesList = responseData;
          _log('API returned direct list of datasources');
        } else if (responseData is Map) {
          // API returns object with 'data' field or another structure
          if (responseData.containsKey('data')) {
            final dataField = responseData['data'];
            if (dataField is List) {
              sourcesList = dataField;
              _log('Found datasources in data field as list');
            } else if (dataField is Map && dataField.containsKey('datasources')) {
              sourcesList = dataField['datasources'] as List?;
              _log('Found datasources in data.datasources field');
            }
          } else if (responseData.containsKey('datasources')) {
            sourcesList = responseData['datasources'] as List?;
            _log('Found datasources directly in datasources field');
          } else if (responseData.containsKey('items')) {
            sourcesList = responseData['items'] as List?;
            _log('Found datasources in items field');
          } else if (responseData.containsKey('sources')) {
            sourcesList = responseData['sources'] as List?;
            _log('Found datasources in sources field');
          }
        }
        
        // If we still don't have a sourcesList, return empty list
        sourcesList ??= [];
        _log('Final datasources list length: ${sourcesList.length}');
          // Enhanced logging for debugging
        _log('About to process raw datasource JSON objects:');
        for (var source in sourcesList) {
          if (source is Map) {
            final statusValue = source['status'];
            _log('Source status before conversion: ${statusValue} (${statusValue?.runtimeType})');
          }
        }
        
        // Process each source
        final List<KnowledgeSource> sources = sourcesList
            .map((source) => KnowledgeSource.fromJson(source))
            .toList();
        
        // Enhanced post-conversion logging
        _log('Successfully parsed ${sources.length} datasources');
        for (var source in sources) {
          _log('Parsed source: id=${source.id}, name=${source.name}, status=${source.status} (${source.status.runtimeType})');
        }
        
        return sources;
      } else {
        _log('Error response body: ${response.body}', isError: true);
        throw Exception('Failed to get datasources: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      _log('Error fetching datasources: $e', isError: true);
      rethrow;
    }  }
  
  // Upload a local file to a knowledge base
  Future<KnowledgeSource> uploadLocalFile(
    String knowledgeBaseId,
    File file,
  ) async {
    try {
      final token = await _getToken();
      final fileName = path.basename(file.path);
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      
      // Use the correct endpoint path format that matches other API calls
      final endpoint = '$baseUrl$apiPath/$knowledgeBaseId/datasources';
      _log('Uploading file to knowledge base using endpoint: $endpoint');      // Create multipart form data for the file upload with proper metadata
      final fileSize = await file.length();
      _log('Preparing to upload file: $fileName, size: $fileSize bytes, type: $mimeType');      // Create a FormData object manually to ensure proper array formatting
      final formData = FormData();
      
      // Add the file part
      formData.files.add(MapEntry(
        'file',
        await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        )
      ));      // The datasources field needs to be properly formatted as individual fields
      // Use 'datasources[]' notation to ensure it's recognized as an array
      
      formData.fields.add(MapEntry('datasources[0][name]', fileName));
      formData.fields.add(MapEntry('datasources[0][type]', 'file'));
      formData.fields.add(MapEntry('datasources[0][fileType]', mimeType));
      formData.fields.add(MapEntry('datasources[0][fileSize]', fileSize.toString()));
      formData.fields.add(MapEntry('datasources[0][status]', 'active'));// Log the full request details for debugging      _log('Making upload request to: $endpoint');
      _log('File name: $fileName, MIME type: $mimeType, size: $fileSize bytes');
      _log('FormData structure: Using datasources[0][field] notation for array elements');
      _log('Datasources fields: ${formData.fields.toString()}');
      
      // Upload the file using the correct endpoint
      final response = await _dio.post(
        endpoint,
        data: formData,  // Using formData with the file
        options: Options(          headers: {
            'Authorization': 'Bearer $token',
            // Don't explicitly set Content-Type for multipart/form-data
            // Let Dio handle this automatically with the proper boundary
          },
        ),
      );

      _log('Upload file response status: ${response.statusCode}');      if (response.statusCode == 201 || response.statusCode == 200) {
        _log('File uploaded successfully', isError: false);
        return KnowledgeSource.fromJson(response.data);
      } else if (response.statusCode == 401) {
        _log('Authentication error (401): Token might be expired', isError: true);
        // Try to refresh token or prompt for re-authentication
        throw Exception('Authentication error: Please log in again');      } else if (response.statusCode == 404) {
        _log('Endpoint not found (404): API endpoint for file upload is incorrect', isError: true);
        throw Exception('API endpoint not found: The files upload endpoint does not exist');
      } else {
        _log('Error response (${response.statusCode}): ${response.data}', isError: true);
        throw Exception('Failed to upload file (Status ${response.statusCode}): ${response.data}');
      }    } catch (e) {
      if (e is DioException) {
        _log('DioException uploading file: ${e.message}', isError: true);
        if (e.response != null) {
          _log('Response status: ${e.response?.statusCode}', isError: true);
          _log('Response data: ${e.response?.data}', isError: true);
          
          // Enhanced debugging for the "Unexpected field" error
          if (e.response?.statusCode == 400) {
            final data = e.response?.data;
            if (data is Map && data.containsKey('message')) {
              final message = data['message'].toString();
              final details = data['details'];
              
              _log('Bad request (400) details: $details', isError: true);
              
              if (message.contains('Unexpected field')) {
                _log('Received "Unexpected field" error. This usually means the API expects a different form field structure.', isError: true);
                _log('Current form data structure: file field and datasources array with metadata', isError: true);
              } else if (details != null && details.toString().contains('datasources')) {
                _log('Issue with datasources field format. API expects specific structure for datasources array.', isError: true);
                _log('Check if datasources needs to be properly formatted or contains required fields.', isError: true);
              }
            }
          }
          
          // Handle specific status codes with more informative messages
          if (e.response?.statusCode == 404) {
            throw Exception('API endpoint not found (404): The files upload endpoint does not exist');
          } else if (e.response?.statusCode == 401) {
            throw Exception('Authentication error (401): Your session has expired. Please log in again');
          } else if (e.response?.statusCode == 403) {
            throw Exception('Access denied (403): You do not have permission to upload files to this knowledge base');
          } else if (e.response?.statusCode == 413) {
            throw Exception('File too large (413): The selected file exceeds the maximum allowed size');
          } else if (e.response?.statusCode == 400) {
            // Parse error response for more helpful messages
            final data = e.response?.data;
            if (data is Map && data.containsKey('message')) {
              final message = data['message'];
              if (message.toString().contains('Unexpected field')) {
                throw Exception('Bad request (400): API format has changed - check API documentation for correct file upload format');
              } else {
                throw Exception('Bad request (400): ${data['message']}');
              }
            } else {
              throw Exception('Bad request (400): The knowledge base ID may be invalid or missing');
            }
          }
        }
          // Check DioException type for specific error handling
        if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.sendTimeout || e.type == DioExceptionType.receiveTimeout) {
          throw Exception('Connection timeout: The server took too long to respond');
        } else if (e.type == DioExceptionType.badResponse) {
          throw Exception('Error uploading file (${e.response?.statusCode}): ${e.response?.data}');
        } else {
          throw Exception('Network error: ${e.message}');
        }} else {
        _log('Error uploading file: $e', isError: true);
        rethrow;
      }
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

      _log('Upload website response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return KnowledgeSource.fromJson(jsonDecode(response.body));
      } else {
        _log('Error response body: ${response.body}', isError: true);
        throw Exception('Failed to upload website: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      _log('Error uploading website: $e', isError: true);
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

      _log('Connect Google Drive response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return KnowledgeSource.fromJson(jsonDecode(response.body));
      } else {
        _log('Error response body: ${response.body}', isError: true);
        throw Exception('Failed to connect Google Drive: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      _log('Error connecting Google Drive: $e', isError: true);
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

      _log('Connect Slack response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return KnowledgeSource.fromJson(jsonDecode(response.body));
      } else {
        _log('Error response body: ${response.body}', isError: true);
        throw Exception('Failed to connect Slack: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      _log('Error connecting Slack: $e', isError: true);
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

      _log('Connect Confluence response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return KnowledgeSource.fromJson(jsonDecode(response.body));
      } else {
        _log('Error response body: ${response.body}', isError: true);
        throw Exception('Failed to connect Confluence: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      _log('Error connecting Confluence: $e', isError: true);
      rethrow;
    }
  }  // Delete a datasource from a knowledge base
  Future<bool> deleteSource(
    String knowledgeBaseId,
    String sourceId,
  ) async {
    try {
      final token = await _getToken();
      
      _log('Deleting datasource: knowledgeBaseId=$knowledgeBaseId, sourceId=$sourceId');
      
      // Using the correct endpoint according to the API documentation
      // https://www.apidog.com/apidoc/shared/f30d2953-f010-4ef7-a360-69f9eaf457f7/delete-a-datasource-in-knowledge-16714994e0
      final response = await http.delete(
        Uri.parse('$baseUrl$apiPath/$knowledgeBaseId/datasources/$sourceId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _log('Delete datasource response status: ${response.statusCode}');
      _log('Delete datasource response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _log('Successfully deleted datasource');
        return true;
      } else {
        _log('Error response body: ${response.body}', isError: true);
        throw Exception('Failed to delete datasource: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      _log('Error deleting datasource: $e', isError: true);
      rethrow;
    }
  }
  
  // Update a datasource in knowledge base
  // https://www.apidog.com/apidoc/shared/f30d2953-f010-4ef7-a360-69f9eaf457f7/update-datasource-16715065e0
  Future<KnowledgeSource> updateDatasource({
    required String knowledgeBaseId,
    required String sourceId,
    String? name,
    String? status,
  }) async {
    try {
      final token = await _getToken();
      
      _log('Updating datasource: knowledgeBaseId=$knowledgeBaseId, sourceId=$sourceId, name=$name, status=$status');
      
      // Create the update payload
      final Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (status != null) updateData['status'] = status;
      
      final response = await http.patch(
        Uri.parse('$baseUrl$apiPath/$knowledgeBaseId/datasources/$sourceId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updateData),
      );

      _log('Update datasource response status: ${response.statusCode}');
      _log('Update datasource response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _log('Successfully updated datasource: $responseData');
        return KnowledgeSource.fromJson(responseData);
      } else {
        _log('Error response body: ${response.body}', isError: true);
        throw Exception('Failed to update datasource: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      _log('Error updating datasource: $e', isError: true);
      rethrow;
    }
  }

  // Import datasources into a knowledge base
  // Based on the API documentation: https://www.apidog.com/apidoc/shared/f30d2953-f010-4ef7-a360-69f9eaf457f7/import-datasource-into-knowledge-16714610e0
  Future<bool> importDatasources({
    required String knowledgeBaseId,
    required List<Map<String, dynamic>> datasources,
  }) async {
    try {
      final token = await _getToken();
      
      _log('Importing datasources to knowledge base: $knowledgeBaseId, count: ${datasources.length}');      // Use the correct endpoint path format that matches other API calls
      final endpoint = '$baseUrl$apiPath/$knowledgeBaseId/datasources';
      _log('Importing datasources using endpoint: $endpoint');
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'datasources': datasources,
        }),
      );

      _log('Import datasources response status: ${response.statusCode}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        _log('Successfully imported datasources');
        return true;
      } else {
        _log('Error response body: ${response.body}', isError: true);
        throw Exception('Failed to import datasources: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      _log('Error importing datasources: $e', isError: true);
      rethrow;
    }
  }
}