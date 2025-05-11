import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Một ứng dụng đơn giản để kiểm tra Firebase Analytics
class FirebaseTestApp extends StatefulWidget {
  const FirebaseTestApp({Key? key}) : super(key: key);

  @override
  State<FirebaseTestApp> createState() => _FirebaseTestAppState();
}

class _FirebaseTestAppState extends State<FirebaseTestApp> {
  String _message = 'Nhấn nút để kiểm tra Firebase Analytics';

  Future<void> _sendTestEvent() async {
    try {
      // Gửi sự kiện test
      await FirebaseAnalytics.instance.logEvent(
        name: 'test_event',
        parameters: {
          'time': DateTime.now().toString(),
        },
      );
      setState(() {
        _message = 'Đã gửi sự kiện test đến Firebase Analytics vào lúc ${DateTime.now()}';
      });
      debugPrint('Đã gửi sự kiện thành công');
    } catch (e) {
      setState(() {
        _message = 'Lỗi: $e';
      });
      debugPrint('Lỗi khi gửi sự kiện: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm tra Firebase Analytics'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _sendTestEvent,
                child: const Text('Gửi sự kiện test'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Lưu ý: Dữ liệu có thể mất 24-48 giờ để xuất hiện trong Firebase Analytics Console.',
                textAlign: TextAlign.center,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Hàm chính để khởi động ứng dụng test
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FirebaseTestApp(),
    ),
  );
}
