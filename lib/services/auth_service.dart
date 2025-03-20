import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final Logger _logger = Logger();

  Future<List<Map<String, String>>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users');
    if (usersJson == null) {
      return [];
    }
    return (jsonDecode(usersJson) as List).map((item) => Map<String, String>.from(item)).toList();
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    final users = await getUsers();
    final user = users.firstWhereOrNull(
      (user) => user['email'] == email && user['password'] == password,
    );
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      _logger.i('Đăng nhập thành công');
    } else {
      _logger.e('Thông tin đăng nhập không hợp lệ');
      throw Exception('Invalid credentials');
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    final users = await getUsers();
    if (users.any((user) => user['email'] == email)) {
      throw Exception('Email already exists');
    }
    users.add({'email': email, 'password': password});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('users', jsonEncode(users));
    _logger.i('Đăng ký thành công');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    _logger.i('Đăng xuất thành công');
  }

  Future<void> signInWithGoogle() async {
    throw Exception('Google sign-in not implemented in local mode');
  }
}