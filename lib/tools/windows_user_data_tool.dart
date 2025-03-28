import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Utility for managing user data stored in SharedPreferences
/// Particularly useful for debugging on Windows platform
class WindowsUserDataTool {
  static final Logger _logger = Logger();
  
  /// Get the path where SharedPreferences are stored
  static Future<String?> getSharedPreferencesPath() async {
    try {
      // Get application support directory
      final directory = await getApplicationSupportDirectory();
      return directory.path;
    } catch (e) {
      _logger.e('Error getting SharedPreferences path: $e');
      return null;
    }
  }
  
  /// Get a list of all stored users
  static Future<List<Map<String, dynamic>>> getStoredUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      // Look for keys that appear to be user-related
      final userKeys = allKeys.where((key) => 
        key.contains('user') || 
        key.contains('auth') ||
        key.contains('token') ||
        key.contains('current')
      ).toList();
      
      final users = <Map<String, dynamic>>[];
      
      // Special handling for current users
      final currentUserJson = prefs.getString('currentUser');
      if (currentUserJson != null) {
        try {
          // Add current user
          users.add({
            'type': 'Current User',
            'email': _extractEmailFromJson(currentUserJson),
            'uid': _extractUidFromJson(currentUserJson),
            'source': 'currentUser'
          });
        } catch (e) {
          _logger.e('Error parsing current user: $e');
        }
      }
      
      // Get tokens for diagnostics
      final accessToken = prefs.getString('jarvis_access_token');
      final refreshToken = prefs.getString('jarvis_refresh_token');
      final userId = prefs.getString('jarvis_user_id');
      
      if (accessToken != null && userId != null) {
        users.add({
          'type': 'Active Session',
          'email': 'Unknown',
          'uid': userId,
          'hasAccessToken': accessToken.isNotEmpty,
          'hasRefreshToken': refreshToken != null && refreshToken.isNotEmpty,
          'source': 'jarvis_tokens'
        });
      }
      
      // Get stored users from other sources
      for (final key in userKeys) {
        if (key == 'currentUser' || key.startsWith('jarvis_')) continue; // Skip already handled keys
        
        final value = prefs.getString(key);
        if (value != null) {
          users.add({
            'type': 'Stored Data',
            'key': key,
            'value': value.length > 30 ? '${value.substring(0, 30)}...' : value,
            'source': key
          });
        }
      }
      
      return users;
    } catch (e) {
      _logger.e('Error getting stored users: $e');
      return [];
    }
  }
  
  /// Remove a specific user by email
  static Future<bool> removeUser(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Look for user in currentUser
      final currentUserJson = prefs.getString('currentUser');
      if (currentUserJson != null && _extractEmailFromJson(currentUserJson) == email) {
        await prefs.remove('currentUser');
      }
      
      // Also remove tokens if we're removing the active user
      await prefs.remove('jarvis_access_token');
      await prefs.remove('jarvis_refresh_token');
      await prefs.remove('jarvis_user_id');
      
      _logger.i('Removed user with email: $email');
      return true;
    } catch (e) {
      _logger.e('Error removing user: $e');
      return false;
    }
  }
  
  /// Clear all stored users
  static Future<bool> clearAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove all user-related keys
      await prefs.remove('currentUser');
      await prefs.remove('jarvis_access_token');
      await prefs.remove('jarvis_refresh_token');
      await prefs.remove('jarvis_user_id');
      
      _logger.i('Cleared all users');
      return true;
    } catch (e) {
      _logger.e('Error clearing all users: $e');
      return false;
    }
  }
  
  // Helper methods to extract email and UID from JSON
  static String _extractEmailFromJson(String json) {
    try {
      // Check if json contains email field
      if (json.contains('"email"')) {
        // Extract the email value
        final regExp = RegExp(r'"email"\s*:\s*"([^"]+)"');
        final match = regExp.firstMatch(json);
        if (match != null && match.groupCount >= 1) {
          return match.group(1) ?? 'Unknown';
        }
      }
      return 'Unknown';
    } catch (e) {
      return 'Error extracting email';
    }
  }
  
  static String _extractUidFromJson(String json) {
    try {
      // Check if json contains uid field
      if (json.contains('"uid"')) {
        // Extract the uid value
        final regExp = RegExp(r'"uid"\s*:\s*"([^"]+)"');
        final match = regExp.firstMatch(json);
        if (match != null && match.groupCount >= 1) {
          return match.group(1) ?? 'Unknown';
        }
      }
      return 'Unknown';
    } catch (e) {
      return 'Error extracting UID';
    }
  }
}

/// Tiện ích command line để xem và quản lý dữ liệu người dùng Windows
///
/// Cách sử dụng: chạy script này bằng lệnh:
/// flutter run -t lib/tools/windows_user_data_tool.dart
void main() async {
  final logger = Logger();
  
  logger.i('===== Công cụ quản lý dữ liệu người dùng Windows =====');
  logger.i('Đang tải dữ liệu người dùng...');
  
  try {
    final users = await WindowsUserDataTool.getStoredUsers();
    
    if (users.isEmpty) {
      logger.i('Không tìm thấy dữ liệu người dùng nào.');
      await _showMenu([], logger);
      return;
    }
    
    logger.i('Đã tìm thấy ${users.length} người dùng.');
    
    await _showMenu(users, logger);
  } catch (e) {
    logger.e('Lỗi: $e');
    exit(1);
  }
}

Future<void> _showMenu(List<Map<String, dynamic>> users, Logger logger) async {
  bool running = true;
  
  while (running) {
    logger.i('\nCác tùy chọn:');
    logger.i('1. Hiển thị tất cả người dùng');
    logger.i('2. Xem chi tiết người dùng');
    logger.i('3. Xóa người dùng');
    logger.i('4. Xóa tất cả dữ liệu');
    logger.i('5. Xuất dữ liệu dạng JSON');
    logger.i('0. Thoát');
    
    stdout.write('\nNhập lựa chọn của bạn: ');
    final choice = stdin.readLineSync();
    
    switch (choice) {
      case '1':
        _listUsers(users, logger);
        break;
      case '2':
        await _viewUserDetails(users, logger);
        break;
      case '3':
        await _deleteUser(users, logger);
        break;
      case '4':
        await _clearAllData(logger);
        users = [];
        break;
      case '5':
        _exportData(users, logger);
        break;
      case '0':
        running = false;
        logger.i('Tạm biệt!');
        break;
      default:
        logger.w('Lựa chọn không hợp lệ!');
    }
  }
}

void _listUsers(List<Map<String, dynamic>> users, Logger logger) {
  if (users.isEmpty) {
    logger.i('Không có người dùng nào.');
    return;
  }
  
  logger.i('\nDanh sách người dùng:');
  for (int i = 0; i < users.length; i++) {
    final user = users[i];
    final key = user['key'] ?? 'Không có key';
    final value = user['value'] ?? 'Không có giá trị';
    logger.i('${i + 1}. $key (Giá trị: $value)');
  }
}

Future<void> _viewUserDetails(List<Map<String, dynamic>> users, Logger logger) async {
  if (users.isEmpty) {
    logger.i('Không có người dùng nào để xem.');
    return;
  }
  
  _listUsers(users, logger);
  stdout.write('\nNhập số thứ tự người dùng để xem chi tiết: ');
  final input = stdin.readLineSync();
  
  try {
    final index = int.parse(input!) - 1;
    if (index < 0 || index >= users.length) {
      logger.w('Số thứ tự không hợp lệ!');
      return;
    }
    
    final user = users[index];
    logger.i('\nChi tiết người dùng:');
    logger.i(const JsonEncoder.withIndent('  ').convert(user));
  } catch (e) {
    logger.e('Lỗi: $e');
  }
}

Future<void> _deleteUser(List<Map<String, dynamic>> users, Logger logger) async {
  if (users.isEmpty) {
    logger.i('Không có người dùng nào để xóa.');
    return;
  }
  
  _listUsers(users, logger);
  stdout.write('\nNhập số thứ tự người dùng để xóa: ');
  final input = stdin.readLineSync();
  
  try {
    final index = int.parse(input!) - 1;
    if (index < 0 || index >= users.length) {
      logger.w('Số thứ tự không hợp lệ!');
      return;
    }
    
    final user = users[index];
    final key = user['key'] ?? 'Không có key';
    
    stdout.write('Bạn có chắc chắn muốn xóa người dùng với key "$key"? (y/n): ');
    final confirm = stdin.readLineSync()?.toLowerCase();
    
    if (confirm == 'y' || confirm == 'yes') {
      final success = await WindowsUserDataTool.removeUser(key);
      if (success) {
        users.removeAt(index);
        logger.i('Đã xóa người dùng.');
      } else {
        logger.e('Lỗi khi xóa người dùng.');
      }
    } else {
      logger.i('Hủy xóa.');
    }
  } catch (e) {
    logger.e('Lỗi: $e');
  }
}

Future<void> _clearAllData(Logger logger) async {
  stdout.write('CẢNH BÁO: Bạn có chắc chắn muốn xóa TẤT CẢ dữ liệu người dùng? (y/n): ');
  final confirm = stdin.readLineSync()?.toLowerCase();
  
  if (confirm == 'y' || confirm == 'yes') {
    final success = await WindowsUserDataTool.clearAllUsers();
    if (success) {
      logger.i('Đã xóa tất cả dữ liệu người dùng.');
    } else {
      logger.e('Lỗi khi xóa tất cả dữ liệu người dùng.');
    }
  } else {
    logger.i('Hủy xóa.');
  }
}

void _exportData(List<Map<String, dynamic>> users, Logger logger) {
  final json = const JsonEncoder.withIndent('  ').convert(users);
  logger.i('\nDữ liệu người dùng (JSON):');
  logger.i(json);
  logger.i('\nĐã xuất dữ liệu JSON.');
}
