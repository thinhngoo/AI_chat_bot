import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// Tiện ích command line để xem và quản lý dữ liệu người dùng Windows
///
/// Cách sử dụng: chạy script này bằng lệnh:
/// flutter run -t lib/tools/windows_user_data_tool.dart
void main() async {
  final logger = Logger();
  
  logger.i('===== Công cụ quản lý dữ liệu người dùng Windows =====');
  logger.i('Đang tải dữ liệu người dùng...');
  
  try {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users');
    
    if (usersJson == null || usersJson.isEmpty) {
      logger.i('Không tìm thấy dữ liệu người dùng nào.');
      await _showMenu(prefs, [], logger);
      return;
    }
    
    final List<dynamic> users = jsonDecode(usersJson);
    logger.i('Đã tìm thấy ${users.length} người dùng.');
    
    await _showMenu(prefs, users, logger);
  } catch (e) {
    logger.e('Lỗi: $e');
    exit(1);
  }
}

Future<void> _showMenu(SharedPreferences prefs, List<dynamic> users, Logger logger) async {
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
        await _deleteUser(prefs, users, logger);
        break;
      case '4':
        await _clearAllData(prefs, logger);
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

void _listUsers(List<dynamic> users, Logger logger) {
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

Future<void> _viewUserDetails(List<dynamic> users, Logger logger) async {
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

Future<void> _deleteUser(SharedPreferences prefs, List<dynamic> users, Logger logger) async {
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
      users.removeAt(index);
      await prefs.setString('users', jsonEncode(users));
      logger.i('Đã xóa người dùng.');
    } else {
      logger.i('Hủy xóa.');
    }
  } catch (e) {
    logger.e('Lỗi: $e');
  }
}

Future<void> _clearAllData(SharedPreferences prefs, Logger logger) async {
  stdout.write('CẢNH BÁO: Bạn có chắc chắn muốn xóa TẤT CẢ dữ liệu người dùng? (y/n): ');
  final confirm = stdin.readLineSync()?.toLowerCase();
  
  if (confirm == 'y' || confirm == 'yes') {
    await prefs.setString('users', '[]');
    logger.i('Đã xóa tất cả dữ liệu người dùng.');
  } else {
    logger.i('Hủy xóa.');
  }
}

void _exportData(List<dynamic> users, Logger logger) {
  final json = const JsonEncoder.withIndent('  ').convert(users);
  logger.i('\nDữ liệu người dùng (JSON):');
  logger.i(json);
  logger.i('\nĐã xuất dữ liệu JSON.');
}
