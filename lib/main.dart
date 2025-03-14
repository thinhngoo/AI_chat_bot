import 'package:flutter/material.dart';
import 'screens/ai_chat_page.dart';
// import 'screens/chat_history_page.dart';
// import 'screens/profile_page.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: UniqueKey(), // DEV: Make the app reload
      title: 'Flutter Demo',
      theme: darkTheme,
      home: const AIChatPage(),
      // home: const ChatHistoryPage(),
      // home: const ProfilePage(),
    );
  }
}
