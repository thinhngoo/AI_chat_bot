import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'chat/presentation/chat_screen.dart';
import 'bot/presentation/bot_list_screen.dart';
import 'email/presentation/email_screen.dart';
import 'prompt/presentation/prompt_management_screen.dart';
import 'subscription/presentation/subscription_info_screen.dart';

class MainScreen extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;

  const MainScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isDialOpen = false;
  bool _showLabels = true;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // Initialize screens - pass parameters where needed
    _screens = [
      ChatScreen(
          toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode),
      const BotListScreen(),
      EmailScreen(
          toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode),
      const PromptManagementScreen(),
      const SubscriptionInfoScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          IndexedStack(
            index: _currentIndex,
            children: _screens,
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
                  color: widget.isDarkMode
                      ? Colors.white.withAlpha(60)
                      : Colors.black.withAlpha(60),
                ),
              ),
            ),

          // Label visibility toggle button at bottom left when menu is open
          if (_isDialOpen)
            Positioned(
              left: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _showLabels = !_showLabels;
                  });
                },
                backgroundColor: widget.isDarkMode
                    ? AppColors.dark.button
                    : AppColors.light.button,
                heroTag: 'toggle_labels',
                child: Icon(
                  _showLabels ? Icons.visibility : Icons.visibility_off,
                  color: widget.isDarkMode
                      ? AppColors.dark.buttonForeground.withAlpha(180)
                      : AppColors.light.buttonForeground.withAlpha(180),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _buildSpeedDial(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSpeedDial() {
    final AppColors colors =
        widget.isDarkMode ? AppColors.dark : AppColors.light;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isDialOpen) ...[
          _buildDialOption(Icons.paid, 'Pro', 4),
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
    final AppColors colors =
        widget.isDarkMode ? AppColors.dark : AppColors.light;
    final bool isSelected = _currentIndex == index;

    return SizedBox(
      width: 240,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_showLabels)
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = index;
                  _isDialOpen = false;
                });
              },
              child: Container(
                width: 100,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary : colors.button,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? colors.primaryForeground
                        : colors.buttonForeground,
                    fontWeight:
                        isSelected ? FontWeight.w900 : FontWeight.normal,
                    fontSize: isSelected ? 16 : 14,
                  ),
                ),
              ),
            ),
          SizedBox(width: _showLabels ? 12 : 0),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _currentIndex = index;
                _isDialOpen = false;
              });
            },
            backgroundColor: isSelected ? colors.primary : colors.button,
            heroTag: 'fab_$index',
            child: Icon(
              icon,
              color: isSelected
                  ? colors.primaryForeground
                  : colors.buttonForeground.withAlpha(200),
            ),
          ),
        ],
      ),
    );
  }
}
