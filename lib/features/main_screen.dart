import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/services/auth/auth_service.dart';
import 'chat/presentation/chat_screen.dart';
import 'bot/presentation/bot_list_screen.dart';
import 'email/presentation/email_screen.dart';
import 'prompt/presentation/prompt_management_screen.dart';
import 'subscription/presentation/subscription_info_screen.dart';
// import 'auth/presentation/login_page.dart';

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
  int _currentIndex = 2;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // Initialize screens - pass parameters where needed
    _screens = [
      EmailScreen(toggleTheme: widget.toggleTheme),
      const PromptManagementScreen(),
      ChatScreen(toggleTheme: widget.toggleTheme),
      const BotListScreen(),
      const SubscriptionInfoScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.onSurface.withAlpha(160),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.email, 'Email', 0),
            _buildNavItem(Icons.format_quote, 'Prompt', 1), 
            _buildNavItem(Icons.chat_bubble, 'Chat', 2),
            _buildNavItem(Icons.android, 'Bot', 3),
            _buildNavItem(Icons.person, 'User', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    final colors = theme.brightness == Brightness.dark ? AppColors.dark : AppColors.light;
    final showLabel = isSelected && label.isNotEmpty;
    
    Color iconColor = isSelected 
        ? theme.colorScheme.primary
        : colors.muted;
        
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        width: showLabel ? 120 : null,
        padding: EdgeInsets.symmetric(horizontal: showLabel ? 16 : 12, vertical: 6),
        decoration: showLabel
            ? BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(60),
                borderRadius: BorderRadius.circular(24),
              )
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
            if (showLabel)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  label,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

}
