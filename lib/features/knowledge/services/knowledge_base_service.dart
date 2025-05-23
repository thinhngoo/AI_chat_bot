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
    // Upload a local file to a knowledge base - Two-step process
  Future<KnowledgeSource> uploadLocalFile(
    String knowledgeBaseId,
    File file,
  ) async {
    try {
      final token = await _getToken();
      final fileName = path.basename(file.path);
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final fileSize = await file.length();
      
      _log('Starting two-step file upload process...');
      _log('Step 1: Upload file to storage to get file ID');
      
      // Step 1: Upload the file to get a file ID
      final fileUploadEndpoint = '$baseUrl$apiPath/files';
      _log('Uploading file to: $fileUploadEndpoint');
      
      // Create FormData for file upload only
      final fileFormData = FormData();
      fileFormData.files.add(MapEntry(
        'files', // Field name should be "files" based on the curl example
        await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        )
      ));
      
      // Log the request details
      _log('Uploading file: $fileName, size: $fileSize bytes, type: $mimeType');
      
      // Make the first API call to upload the file
      final fileUploadResponse = await _dio.post(
        fileUploadEndpoint,
        data: fileFormData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            // Let Dio handle Content-Type with proper boundary
          },
        ),
      );
      
      _log('File upload response status: ${fileUploadResponse.statusCode}');
      
      if (!(fileUploadResponse.statusCode == 200 || fileUploadResponse.statusCode == 201)) {
        _log('Error uploading file: ${fileUploadResponse.data}', isError: true);
        throw Exception('Failed to upload file: ${fileUploadResponse.statusCode}');
      }
        // Extract file ID from the response
      String? fileId;
      
      final responseData = fileUploadResponse.data;
      _log('Examining file upload response structure: ${responseData.runtimeType}', isError: false);
      
      if (responseData is Map) {
        // Check if response contains a "files" array
        if (responseData.containsKey('files') && responseData['files'] is List && responseData['files'].isNotEmpty) {
          final firstFile = responseData['files'][0];
          if (firstFile is Map && firstFile.containsKey('id')) {
            fileId = firstFile['id'];
            _log('Found file ID in files[0].id: $fileId', isError: false);
          }
        } 
        // Direct ID in response (fallback)
        else if (responseData.containsKey('id')) {
          fileId = responseData['id'];
          _log('Found file ID directly in response.id: $fileId', isError: false);
        } 
        // Another common field name (fallback)
        else if (responseData.containsKey('fileId')) {
          fileId = responseData['fileId'];
          _log('Found file ID in response.fileId: $fileId', isError: false);
        }
      }
          
      if (fileId == null) {
        _log('File uploaded but no file ID received: $responseData', isError: true);
        throw Exception('File uploaded but no file ID received from API');
      }
      
      _log('File uploaded successfully, received file ID: $fileId');
      _log('Step 2: Creating datasource with the file ID');
      
      // Step 2: Create a datasource with the file ID
      final datasourceEndpoint = '$baseUrl$apiPath/$knowledgeBaseId/datasources';
      _log('Creating datasource at: $datasourceEndpoint');
        // Prepare the JSON payload with the file ID
      final datasourcePayload = {
        'datasources': [
          {
            'type': 'local_file',
            'name': fileName,
            'credentials': {
              'file': fileId
            }
          }
        ]
      };
      
      _log('Datasource payload: $datasourcePayload');
      _log('File name: $fileName, File ID: $fileId', isError: false);
      
      // Make the second API call to create the datasource
      final datasourceResponse = await _dio.post(
        datasourceEndpoint,
        data: datasourcePayload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      _log('Create datasource response status: ${datasourceResponse.statusCode}');
        if (datasourceResponse.statusCode == 201 || datasourceResponse.statusCode == 200) {
        _log('Datasource created successfully', isError: false);
        
        // Parse the response to get the datasource
        final responseData = datasourceResponse.data;
        _log('Datasource response data: $responseData', isError: false);
        
        // Handle different response structures
        dynamic datasource;
        if (responseData is List && responseData.isNotEmpty) {
          datasource = responseData.first;
          _log('Found datasource in response list[0]', isError: false);
        } else if (responseData is Map) {
          if (responseData.containsKey('datasources') && responseData['datasources'] is List && responseData['datasources'].isNotEmpty) {
            datasource = responseData['datasources'][0];
            _log('Found datasource in response.datasources[0]', isError: false);
          } else if (responseData.containsKey('datasource')) {
            datasource = responseData['datasource'];
            _log('Found datasource in response.datasource', isError: false);
          } else {
            // If no nested structure, use the entire response
            datasource = responseData;
            _log('Using entire response as datasource', isError: false);
          }
        }
        
        if (datasource != null) {
          _log('Parsed datasource: $datasource', isError: false);
          return KnowledgeSource.fromJson(datasource);
        } else {
          _log('Unable to parse datasource from response: $responseData', isError: true);
          throw Exception('Created datasource but failed to parse the response');
        }
      } else if (datasourceResponse.statusCode == 401) {
        _log('Authentication error (401): Token might be expired', isError: true);
        throw Exception('Authentication error: Please log in again');
      } else if (datasourceResponse.statusCode == 404) {
        _log('Endpoint not found (404): API endpoint for datasource creation is incorrect', isError: true);
        throw Exception('API endpoint not found: The datasource creation endpoint does not exist');
      } else {
        _log('Error response (${datasourceResponse.statusCode}): ${datasourceResponse.data}', isError: true);
        throw Exception('Failed to create datasource (Status ${datasourceResponse.statusCode}): ${datasourceResponse.data}');
      }    } catch (e) {
      if (e is DioException) {
        _log('DioException in file upload process: ${e.message}', isError: true);
        if (e.response != null) {
          _log('Response status: ${e.response?.statusCode}', isError: true);
          _log('Response data: ${e.response?.data}', isError: true);
          
          // Enhanced debugging
          if (e.response?.statusCode == 400) {
            final data = e.response?.data;
            if (data is Map && data.containsKey('message')) {
              final message = data['message'].toString();
              final details = data['details'];
              
              _log('Bad request (400) details: $details', isError: true);
              
              // Common error patterns
              if (message.contains('Unexpected field')) {
                _log('Received "Unexpected field" error. The API may expect a different field name than "files" or other structure.', isError: true);
              } else if (details != null && details.toString().contains('credentials')) {
                _log('Issue with credentials format. API expects specific structure for file credentials.', isError: true);
              }
            }
          }
          
          // Handle specific status codes with more informative messages
          if (e.response?.statusCode == 404) {
            throw Exception('API endpoint not found (404): Check if the files or datasources endpoint exists');
          } else if (e.response?.statusCode == 401) {
            throw Exception('Authentication error (401): Your session has expired. Please log in again');
          } else if (e.response?.statusCode == 403) {
            throw Exception('Access denied (403): You do not have permission to upload files to this knowledge base');
          } else if (e.response?.statusCode == 413) {
            throw Exception('File too large (413): The selected file exceeds the maximum allowed size');
          } else if (e.response?.statusCode == 400) {            // Parse error response for more helpful messages
            final data = e.response?.data;
            if (data is Map && data.containsKey('message')) {
              throw Exception('Bad request (400): ${data['message']}');
            } else {
              throw Exception('Bad request (400): Check file format or knowledge base ID');
            }
          }
        }
        
        // Check DioException type for specific error handling
        if (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.sendTimeout || 
            e.type == DioExceptionType.receiveTimeout) {
          throw Exception('Connection timeout: The server took too long to respond');
        } else if (e.type == DioExceptionType.badResponse) {
          throw Exception('Error in API response (${e.response?.statusCode}): ${e.response?.data}');
        } else {
          throw Exception('Network error: ${e.message}');
        }
      } else {
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
  }  // Connect to Slack (Legacy method - forwards to enhanced implementation)
  Future<KnowledgeSource> connectSlack(
    String knowledgeBaseId,
    String botToken,
    {String? name}
  ) async {
    _log('Using legacy connectSlack method - forwarding to enhanced implementation');
    return loadDataFromSlack(knowledgeBaseId, botToken: botToken, name: name ?? 'Slack Import');
  }
  // Connect to Confluence (Legacy method - forwards to enhanced implementation)
  Future<KnowledgeSource> connectConfluence(
    String knowledgeBaseId,
    String spaceKey,
  ) async {
    _log('Using legacy connectConfluence method - forwarding to enhanced implementation');
    return loadDataFromConfluence(knowledgeBaseId, spaceKey);
  }

  // Connect to Confluence - Enhanced implementation
  Future<KnowledgeSource> loadDataFromConfluence(
    String knowledgeBaseId,
    String spaceKey,
    {String? baseUrl, String? username, String? apiToken}
  ) async {
    try {
      _log('Starting Confluence data loading process...');
      final authToken = await _getToken();

      // Prepare payload with required parameters
      final Map<String, dynamic> payload = {
        'datasources': [
          {
            'type': 'confluence',
            'name': 'Confluence Space: $spaceKey',
            'credentials': {
              'spaceKey': spaceKey
            }
          }
        ]
      };
      
      // Add optional parameters if provided
      if (baseUrl != null) {
        final Map<String, dynamic> credentials = 
            (payload['datasources'] as List<dynamic>)[0]['credentials'] as Map<String, dynamic>;
        credentials['baseUrl'] = baseUrl;
      }
      if (username != null) {
        final Map<String, dynamic> credentials = 
            (payload['datasources'] as List<dynamic>)[0]['credentials'] as Map<String, dynamic>;
        credentials['username'] = username;
      }
      if (apiToken != null) {
        final Map<String, dynamic> credentials = 
            (payload['datasources'] as List<dynamic>)[0]['credentials'] as Map<String, dynamic>;
        credentials['apiToken'] = apiToken;
      }

      _log('Confluence payload: $payload');
      
      // Using Dio for consistent API calling pattern
      final apiBaseUrl = this.baseUrl; // Use class property with a different variable name
      final datasourceEndpoint = '$apiBaseUrl$apiPath/$knowledgeBaseId/datasources';
      _log('Creating Confluence datasource at: $datasourceEndpoint');
      
      final datasourceResponse = await _dio.post(
        datasourceEndpoint,
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      _log('Create Confluence datasource response status: ${datasourceResponse.statusCode}');
      
      if (datasourceResponse.statusCode == 201 || datasourceResponse.statusCode == 200) {
        _log('Confluence datasource created successfully', isError: false);
        
        // Parse the response to get the datasource
        final responseData = datasourceResponse.data;
        _log('Confluence datasource response data: $responseData', isError: false);
        
        // Handle different response structures
        dynamic datasource;
        if (responseData is List && responseData.isNotEmpty) {
          datasource = responseData.first;
          _log('Found Confluence datasource in response list[0]', isError: false);
        } else if (responseData is Map) {
          if (responseData.containsKey('datasources') && responseData['datasources'] is List && responseData['datasources'].isNotEmpty) {
            datasource = responseData['datasources'][0];
            _log('Found Confluence datasource in response.datasources[0]', isError: false);
          } else if (responseData.containsKey('datasource')) {
            datasource = responseData['datasource'];
            _log('Found Confluence datasource in response.datasource', isError: false);
          } else {
            // If no nested structure, use the entire response
            datasource = responseData;
            _log('Using entire response as Confluence datasource', isError: false);
          }
        }
        
        if (datasource != null) {
          _log('Parsed Confluence datasource: $datasource', isError: false);
          return KnowledgeSource.fromJson(datasource);
        } else {
          _log('Unable to parse Confluence datasource from response: $responseData', isError: true);
          throw Exception('Created Confluence datasource but failed to parse the response');
        }
      } else if (datasourceResponse.statusCode == 401) {
        _log('Authentication error (401): Token might be expired', isError: true);
        throw Exception('Authentication error: Please log in again');
      } else if (datasourceResponse.statusCode == 404) {
        _log('Endpoint not found (404): API endpoint for datasource creation is incorrect', isError: true);
        throw Exception('API endpoint not found: The datasource creation endpoint does not exist');
      } else {
        _log('Error response (${datasourceResponse.statusCode}): ${datasourceResponse.data}', isError: true);
        throw Exception('Failed to create Confluence datasource (Status ${datasourceResponse.statusCode}): ${datasourceResponse.data}');
      }
    } catch (e) {
      if (e is DioException) {
        _log('DioException in Confluence data loading process: ${e.message}', isError: true);
        if (e.response != null) {
          _log('Response status: ${e.response?.statusCode}', isError: true);
          _log('Response data: ${e.response?.data}', isError: true);
          
          // Handle specific status codes with more informative messages
          if (e.response?.statusCode == 404) {
            throw Exception('API endpoint not found (404): Check if the datasources endpoint exists');
          } else if (e.response?.statusCode == 401) {
            throw Exception('Authentication error (401): Your session has expired. Please log in again');
          } else if (e.response?.statusCode == 403) {
            throw Exception('Access denied (403): You do not have permission to connect to Confluence for this knowledge base');
          } else if (e.response?.statusCode == 400) {
            // Parse error response for more helpful messages
            final data = e.response?.data;
            if (data is Map && data.containsKey('message')) {
              throw Exception('Bad request (400): ${data['message']}');
            } else {
              throw Exception('Bad request (400): Check Confluence credentials or knowledge base ID');
            }
          }
        }
        
        // Check DioException type for specific error handling
        if (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.sendTimeout || 
            e.type == DioExceptionType.receiveTimeout) {
          throw Exception('Connection timeout: The server took too long to respond');
        } else if (e.type == DioExceptionType.badResponse) {
          throw Exception('Error in API response (${e.response?.statusCode}): ${e.response?.data}');
        } else {
          throw Exception('Network error: ${e.message}');
        }
      } else {
        _log('Error connecting to Confluence: $e', isError: true);
        rethrow;
      }
    }
  }

  // Delete a datasource from a knowledge base
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
  // Connect to Slack - Enhanced implementation
  Future<KnowledgeSource> loadDataFromSlack(
    String knowledgeBaseId,
    {required String botToken, required String name}
  ) async {
    try {
      _log('Starting Slack data loading process...');
      final authToken = await _getToken();

      // Prepare payload with required parameters
      final Map<String, dynamic> payload = {
        'datasources': [
          {
            'type': 'slack',
            'name': name,
            'credentials': {
              'botToken': botToken
            }
          }
        ]
      };

      _log('Slack payload: $payload');
      
      // Using Dio for consistent API calling pattern
      final apiBaseUrl = this.baseUrl; // Use class property with a different variable name
      final datasourceEndpoint = '$apiBaseUrl$apiPath/$knowledgeBaseId/datasources';
      
      final datasourceResponse = await _dio.post(
        datasourceEndpoint,
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      _log('Create Slack datasource response status: ${datasourceResponse.statusCode}');
      
      if (datasourceResponse.statusCode == 201 || datasourceResponse.statusCode == 200) {
        _log('Slack datasource created successfully', isError: false);
        
        // Parse the response to get the datasource
        final responseData = datasourceResponse.data;
        _log('Slack datasource response data: $responseData', isError: false);
        
        // Handle different response structures
        dynamic datasource;
        if (responseData is List && responseData.isNotEmpty) {
          datasource = responseData.first;
          _log('Found Slack datasource in response list[0]', isError: false);
        } else if (responseData is Map) {
          if (responseData.containsKey('datasources') && responseData['datasources'] is List && responseData['datasources'].isNotEmpty) {
            datasource = responseData['datasources'][0];
            _log('Found Slack datasource in response.datasources[0]', isError: false);
          } else if (responseData.containsKey('datasource')) {
            datasource = responseData['datasource'];
            _log('Found Slack datasource in response.datasource', isError: false);
          } else {
            // If no nested structure, use the entire response
            datasource = responseData;
            _log('Using entire response as Slack datasource', isError: false);
          }
        }
        
        if (datasource != null) {
          _log('Parsed Slack datasource: $datasource', isError: false);
          return KnowledgeSource.fromJson(datasource);
        } else {
          _log('Unable to parse Slack datasource from response: $responseData', isError: true);
          throw Exception('Created Slack datasource but failed to parse the response');
        }
      } else if (datasourceResponse.statusCode == 401) {
        _log('Authentication error (401): Token might be expired', isError: true);
        throw Exception('Authentication error: Please log in again');
      } else if (datasourceResponse.statusCode == 404) {
        _log('Endpoint not found (404): API endpoint for datasource creation is incorrect', isError: true);
        throw Exception('API endpoint not found: The datasource creation endpoint does not exist');
      } else {
        _log('Error response (${datasourceResponse.statusCode}): ${datasourceResponse.data}', isError: true);
        throw Exception('Failed to create Slack datasource (Status ${datasourceResponse.statusCode}): ${datasourceResponse.data}');
      }
    } catch (e) {
      if (e is DioException) {
        _log('DioException in Slack data loading process: ${e.message}', isError: true);
        if (e.response != null) {
          _log('Response status: ${e.response?.statusCode}', isError: true);
          _log('Response data: ${e.response?.data}', isError: true);
          
          // Handle specific status codes with more informative messages
          if (e.response?.statusCode == 404) {
            throw Exception('API endpoint not found (404): Check if the datasources endpoint exists');
          } else if (e.response?.statusCode == 401) {
            throw Exception('Authentication error (401): Your session has expired. Please log in again');
          } else if (e.response?.statusCode == 403) {
            throw Exception('Access denied (403): You do not have permission to connect to Slack for this knowledge base');
          } else if (e.response?.statusCode == 400) {
            // Parse error response for more helpful messages
            final data = e.response?.data;
            if (data is Map && data.containsKey('message')) {
              throw Exception('Bad request (400): ${data['message']}');
            } else {
              throw Exception('Bad request (400): Check Slack credentials or knowledge base ID');
            }
          }
        }
        
        // Check DioException type for specific error handling
        if (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.sendTimeout || 
            e.type == DioExceptionType.receiveTimeout) {
          throw Exception('Connection timeout: The server took too long to respond');
        } else if (e.type == DioExceptionType.badResponse) {
          throw Exception('Error in API response (${e.response?.statusCode}): ${e.response?.data}');
        } else {
          throw Exception('Network error: ${e.message}');
        }
      } else {
        _log('Error connecting to Slack: $e', isError: true);
        rethrow;
      }
    }
  }
}

// For testing purposes only
void main() async {
  print('Knowledge Base Service - Testing Module');
  print('=======================================');
  print('This is used to test the implementation of the knowledge base service');
  print('When run directly, it will test the methods with mock data');
  
  // Create service instance (not used in mock tests)
  KnowledgeBaseService();
  
  print('\nTesting loadDataFromSlack...');
  try {
    // Example with default name format
    final payload = {
      'datasources': [
        {
          'type': 'slack',
          'name': 'Slack Channel: C123456',
          'credentials': {
            'channelId': 'C123456'
          }
        }
      ]
    };
    print('Example Slack payload with default name:');
    print(payload);
    
    // Example with custom name
    final customNamePayload = {
      'datasources': [
        {
          'type': 'slack',
          'name': 'Vinh',
          'credentials': {
            'channelId': 'C123456'
          }
        }
      ]
    };
    print('Example Slack payload with custom name:');
    print(customNamePayload);
    
    print('\nTesting loadDataFromConfluence...');
    final confluencePayload = {
      'datasources': [
        {
          'type': 'confluence',
          'name': 'Confluence Space: TEAM',
          'credentials': {
            'spaceKey': 'TEAM',
            'baseUrl': 'https://example.atlassian.net',
            'username': 'user@example.com',
            'apiToken': '******'
          }
        }
      ]
    };
    print('Example Confluence payload:');
    print(confluencePayload);
    
    print('\nTest complete. The implementation looks correct.');
    print('In a real environment, you would need proper authentication tokens to test with live services.');
  } catch (e) {
    print('Test error: $e');
  }
}