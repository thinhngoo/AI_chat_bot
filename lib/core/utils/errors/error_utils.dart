import 'dart:io';
import 'package:logger/logger.dart';

/// Utility class for handling and formatting errors consistently throughout the app
class ErrorUtils {
  static final Logger _logger = Logger();
  
  /// Format an error message for user-friendly display
  static String formatErrorMessage(dynamic error) {
    // If it's already a string, check for known error patterns
    if (error is String) {
      if (error.contains('token') || 
          error.contains('access') || 
          error.contains('expire') ||
          error.contains('auth')) {
        return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
      }
      
      if (error.contains('connection') || 
          error.contains('network') ||
          error.contains('internet') ||
          error.contains('timeout')) {
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet của bạn.';
      }
      
      if (error.contains('server') || error.contains('500')) {
        return 'Lỗi máy chủ. Vui lòng thử lại sau.';
      }
      
      if (error.contains('not found') || error.contains('404')) {
        return 'Không tìm thấy dữ liệu yêu cầu.';
      }

      // If no pattern matches, return the error string as is
      return error;
    }
    
    // Handle specific error types
    if (error is SocketException) {
      return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối internet của bạn.';
    }
    
    if (error is HttpException) {
      return 'Lỗi kết nối: ${error.message}';
    }
    
    if (error is FormatException) {
      return 'Lỗi định dạng dữ liệu: ${error.message}';
    }
    
    // Generic error handling
    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }
  
  /// Log an error with consistent format
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    _logger.e(
      '[$context] Error: ${error.toString()}',
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Format API errors based on common response patterns
  static String formatApiError(Map<String, dynamic> errorResponse) {
    // Check for standard error message field
    if (errorResponse.containsKey('message')) {
      return errorResponse['message'];
    }
    
    // Check for error code field
    if (errorResponse.containsKey('code')) {
      final code = errorResponse['code'];
      
      // Map known error codes to user-friendly messages
      switch (code) {
        case 'AUTHENTICATION_FAILED':
          return 'Xác thực thất bại. Vui lòng đăng nhập lại.';
        case 'INVALID_REQUEST':
          return 'Yêu cầu không hợp lệ. Vui lòng kiểm tra dữ liệu đầu vào.';
        case 'RATE_LIMIT_EXCEEDED':
          return 'Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau.';
        case 'INTERNAL_SERVER_ERROR':
          return 'Lỗi máy chủ nội bộ. Vui lòng thử lại sau.';
        default:
          return 'Lỗi: $code';
      }
    }
    
    // Check for error field
    if (errorResponse.containsKey('error')) {
      if (errorResponse['error'] is String) {
        return errorResponse['error'];
      } else if (errorResponse['error'] is Map && 
                errorResponse['error'].containsKey('message')) {
        return errorResponse['error']['message'];
      }
    }
    
    // Default message if no known field is found
    return 'Đã xảy ra lỗi không xác định.';
  }
}
