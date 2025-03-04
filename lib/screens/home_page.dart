import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'signup_page.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key}); // Remove const keyword

  final _auth = FirebaseAuth.instance;

  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
    if (!context.mounted) return; // Check if the context is still mounted
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đăng xuất thành công!')), // Add const
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()), // Add const
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'), // Add const
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), // Add const
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Chào mừng đến với Jarvis App!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20), // Add const
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()), // Add const
                );
              },
              child: const Text('Đăng nhập'), // Add const
            ),
            const SizedBox(height: 10), // Add const
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpPage()), // Add const
                );
              },
              child: const Text('Đăng ký'), // Add const
            ),
          ],
        ),
      ),
    );
  }
}