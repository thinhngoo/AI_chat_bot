import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'screens/chat_screen.dart';

final logger = Logger(); // Khởi tạo logger globally

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
    logger.i('Loaded .env successfully: ${dotenv.env['DEEPSEEK_API_KEY']}');
  } catch (e) {
    logger.e('Error loading .env: $e');
  }
  runApp(ChatBotApp());
}

class ChatBotApp extends StatelessWidget {
  const ChatBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatbot DeepSeek',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ChatScreen(),
    );
  }
}