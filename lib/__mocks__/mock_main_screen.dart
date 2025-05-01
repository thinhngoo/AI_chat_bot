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
      body: Stack(
        children: [
          // Main content
          Center(
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

          // Overlay when menu is open
          if (_isDialOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isDialOpen = false;
                  });
                },
                child: Container(
                  color: Colors.black.withAlpha(160),
                ),
              ),
            ),
        ],
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isDialOpen) ...[
          _buildDialOption(Icons.paid, 'Billing', 4),
          const SizedBox(height: 16),
          _buildDialOption(Icons.format_quote, 'Prompts', 3),
          const SizedBox(height: 16),
          _buildDialOption(Icons.email, 'Email', 2),
          const SizedBox(height: 16),
          _buildDialOption(Icons.smart_toy, 'Bots', 1),
          const SizedBox(height: 16),
          _buildDialOption(Icons.chat_bubble, 'Chat', 0),
          const SizedBox(height: 20),
        ],
        FloatingActionButton(
          onPressed: () {
            setState(() {
              _isDialOpen = !_isDialOpen;
            });
          },
          backgroundColor: colors.button,
          child: Icon(
            _isDialOpen ? Icons.close : Icons.menu,
            color: colors.buttonForeground.withAlpha(180),
          ),
        ),
      ],
    );
  }

  Widget _buildDialOption(IconData icon, String label, int index) {
    final AppColors colors = _isDarkMode ? AppColors.dark : AppColors.light;
    final isSelected = _currentIndex == index;

    return SizedBox(
      width: 240,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white.withAlpha(160),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _currentIndex = index;
                _isDialOpen = false;
              });
            },
            backgroundColor: isSelected ? colors.accent : colors.button,
            heroTag: 'fab_$index',
            child: Icon(
              icon,
              color: isSelected
                  ? colors.accentForeground
                  : colors.buttonForeground,
            ),
          ),
        ],
      ),
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
