import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

/// Helper class for Windows-specific user data operations
class WindowsUserDataTool {
  static final Logger _logger = Logger();
  
  /// Get the path to the SharedPreferences file
  static Future<String?> getSharedPreferencesPath() async {
    try {
      if (!Platform.isWindows) {
        return 'Not running on Windows';
      }
      
      final appDataDir = await getApplicationSupportDirectory();
      return appDataDir.path;
    } catch (e) {
      _logger.e('Error getting SharedPreferences path: $e');
      return null;
    }
  }
  
  /// Get list of stored users
  static Future<List<Map<String, dynamic>>> getStoredUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users');
      
      if (usersJson == null || usersJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> decoded = jsonDecode(usersJson);
      return decoded.map((user) => Map<String, dynamic>.from(user)).toList();
    } catch (e) {
      _logger.e('Error getting stored users: $e');
      return [];
    }
  }
  
  /// Add a user to SharedPreferences
  static Future<bool> addUser(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users');
      
      List<dynamic> users = [];
      if (usersJson != null && usersJson.isNotEmpty) {
        users = jsonDecode(usersJson);
      }
      
      // Check if user already exists
      final existingUserIndex = users.indexWhere((user) => 
        user['email'] == userData['email']);
      
      if (existingUserIndex >= 0) {
        // Update existing user
        users[existingUserIndex] = userData;
      } else {
        // Add new user
        users.add(userData);
      }
      
      // Save updated users list
      await prefs.setString('users', jsonEncode(users));
      return true;
    } catch (e) {
      _logger.e('Error adding user: $e');
      return false;
    }
  }
  
  /// Remove a specific user by email
  static Future<bool> removeUser(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users');
      
      if (usersJson == null || usersJson.isEmpty) {
        return false;
      }
      
      List<dynamic> users = jsonDecode(usersJson);
      users.removeWhere((user) => user['email'] == email);
      
      await prefs.setString('users', jsonEncode(users));
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
      await prefs.setString('users', '[]');
      return true;
    } catch (e) {
      _logger.e('Error clearing all users: $e');
      return false;
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
    final email = user['email'] ?? 'Không có email';
    final name = user['name'] ?? 'Không có tên';
    logger.i('${i + 1}. $email (Tên: $name)');
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
    final email = user['email'] ?? 'Không có email';
    
    stdout.write('Bạn có chắc chắn muốn xóa người dùng "$email"? (y/n): ');
    final confirm = stdin.readLineSync()?.toLowerCase();
    
    if (confirm == 'y' || confirm == 'yes') {
      final success = await WindowsUserDataTool.removeUser(email);
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
