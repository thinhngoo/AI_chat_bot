import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/services/auth/auth_service.dart';
import 'chat/presentation/chat_screen.dart';
import 'bot/presentation/bot_list_screen.dart';
import 'email/presentation/email_screen.dart';
import 'prompt/presentation/prompt_management_screen.dart';
import 'subscription/presentation/subscription_info_screen.dart';
import 'auth/presentation/login_page.dart';

class MainScreen extends StatefulWidget {
  final Function toggleTheme;

  const MainScreen({
    super.key,
    required this.toggleTheme,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;
  bool _isDialOpen = false;
  bool _showLabels = false;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // Initialize screens - pass parameters where needed
    _screens = [
      ChatScreen(toggleTheme: widget.toggleTheme),
      const SubscriptionInfoScreen(),
      const BotListScreen(),
      const PromptManagementScreen(),
      EmailScreen(toggleTheme: widget.toggleTheme),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                  color: isDarkMode
                      ? Colors.black.withAlpha(160)
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
                backgroundColor:
                    isDarkMode ? AppColors.dark.button : AppColors.light.button,
                heroTag: 'toggle_labels',
                child: Icon(
                  _showLabels ? Icons.visibility : Icons.visibility_off,
                  color: isDarkMode
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
    final AppColors colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isDialOpen) ...[
          _buildDialOption(Icons.logout, 'Logout', -1),
          const SizedBox(height: 16),
          _buildDialOption(Icons.email, 'Email', 4),
          const SizedBox(height: 16),
          _buildDialOption(Icons.format_quote, 'Prompts', 3),
          const SizedBox(height: 16),
          _buildDialOption(Icons.android, 'Bots', 2),
          const SizedBox(height: 16),
          _buildDialOption(Icons.person, 'Account', 1),
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
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: Theme.of(context).brightness == Brightness.dark
                ? BorderSide(color: colors.border, width: 1)
                : BorderSide.none,
          ),
          child: Icon(
            _isDialOpen ? Icons.close : Icons.menu,
            color: colors.buttonForeground.withAlpha(180),
          ),
        ),
      ],
    );
  }

  Widget _buildDialOption(IconData icon, String label, int index) {
    final AppColors colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final bool isSelected = index >= 0 && _currentIndex == index;

    return SizedBox(
      width: 240,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_showLabels)
            GestureDetector(
              onTap: () {
                if (index >= 0) {
                  setState(() {
                    _currentIndex = index;
                    _isDialOpen = false;
                  });
                } else {
                  _handleLogout();
                }
              },
              child: Container(
                width: 100,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary
                      : index == -1
                          ? Colors.redAccent
                          : colors.button,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? colors.primaryForeground
                        : index == -1
                            ? Colors.white.withAlpha(240)
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
              if (index >= 0) {
                setState(() {
                  _currentIndex = index;
                  _isDialOpen = false;
                });
              } else {
                // Handle logout
                _handleLogout();
              }
            },
            backgroundColor: isSelected
                ? colors.primary
                : index == -1
                    ? Colors.redAccent
                    : colors.button,
            heroTag: 'fab_$index',
            child: Icon(
              icon,
              color: isSelected
                  ? colors.primaryForeground
                  : index == -1
                      ? Colors.white.withAlpha(240)
                      : colors.buttonForeground.withAlpha(200),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    // Close the menu
    setState(() {
      _isDialOpen = false;
    });
    final AppColors colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: colors.muted,
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _authService.signOut().then((_) {
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
