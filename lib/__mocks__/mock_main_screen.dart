import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// A mock version of the main screen that doesn't require login
/// Used for UI development and testing - displays only page names
class MockMainScreen extends StatefulWidget {
  const MockMainScreen({super.key});

  @override
  State<MockMainScreen> createState() => _MockMainScreenState();
}

class _MockMainScreenState extends State<MockMainScreen> {
  int _currentIndex = 0;
  bool _isDarkMode = false;
  bool _isDialOpen = false;

  final List<String> _screenNames = [
    'CHAT',
    'BOTS',
    'EMAIL',
    'PROMPTS',
    'PRO',
  ];

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = _isDarkMode ? AppColors.dark : AppColors.light;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.foreground,
        title: const Text('UI Development Mode'),
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleTheme,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForIndex(_currentIndex),
              size: 120,
              color: colors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              _screenNames[_currentIndex],
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This is a placeholder for the ${_screenNames[_currentIndex].toLowerCase()} screen',
              style: TextStyle(
                fontSize: 16,
                color: colors.foreground,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.chat_bubble;
      case 1:
        return Icons.smart_toy;
      case 2:
        return Icons.email;
      case 3:
        return Icons.format_quote;
      case 4:
        return Icons.workspace_premium;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildSpeedDial() {
    final AppColors colors = _isDarkMode ? AppColors.dark : AppColors.light;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isDialOpen) ...[
          _buildDialOption(Icons.workspace_premium, 'Pro', 4),
          const SizedBox(height: 10),
          _buildDialOption(Icons.format_quote, 'Prompts', 3),
          const SizedBox(height: 10),
          _buildDialOption(Icons.email, 'Email', 2),
          const SizedBox(height: 10),
          _buildDialOption(Icons.smart_toy, 'Bots', 1),
          const SizedBox(height: 10),
          _buildDialOption(Icons.chat_bubble, 'Chat', 0),
          const SizedBox(height: 10),
        ],
        FloatingActionButton(
          onPressed: () {
            setState(() {
              _isDialOpen = !_isDialOpen;
            });
          },
          backgroundColor: colors.primary,
          child: Icon(
            _isDialOpen ? Icons.close : Icons.menu,
            color: colors.primaryForeground,
          ),
        ),
      ],
    );
  }

  Widget _buildDialOption(IconData icon, String label, int index) {
    final AppColors colors = _isDarkMode ? AppColors.dark : AppColors.light;
    final isSelected = _currentIndex == index;

    return FloatingActionButton.extended(
      onPressed: () {
        setState(() {
          _currentIndex = index;
          _isDialOpen = false;
        });
      },
      backgroundColor: isSelected ? colors.primary : colors.button,
      foregroundColor:
          isSelected ? colors.primaryForeground : colors.buttonForeground,
      icon: Icon(icon),
      label: Text(label),
      heroTag: 'fab_$index',
    );
  }
}

/// Entry point for using the mock main screen
class MockApp extends StatelessWidget {
  const MockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UI Development',
      home: const MockMainScreen(),
    );
  }
}

/// Main function to run the mock app independently
void main() {
  runApp(const MockApp());
}
