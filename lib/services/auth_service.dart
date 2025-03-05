import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _logger.i('Bắt đầu đăng nhập email: $email');
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _logger.i('Đăng nhập email thành công');
    } on FirebaseAuthException catch (e) {
      _logger.e('Lỗi đăng nhập email: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Lỗi không xác định khi đăng nhập email: $e');
      rethrow;
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    try {
      _logger.i('Bắt đầu đăng ký email: $email');
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      _logger.i('Đăng ký email thành công');
    } on FirebaseAuthException catch (e) {
      _logger.e('Lỗi đăng ký: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Lỗi không xác định khi đăng ký: $e');
      rethrow;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      _logger.i('Bắt đầu đăng nhập Google');
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _logger.w('Người dùng hủy đăng nhập Google');
        return null;
      }
      _logger.i('Đã chọn tài khoản Google: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      _logger.i('Lấy token Google thành công');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential result = await _auth.signInWithCredential(credential);
      _logger.i('Đăng nhập Google thành công: ${result.user?.email}');
      return result.user;
    } on FirebaseAuthException catch (e) {
      _logger.e('Lỗi Firebase khi đăng nhập Google: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Lỗi không xác định khi đăng nhập Google: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    _logger.i('Đăng xuất thành công');
  }
}