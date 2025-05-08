import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'chat/presentation/chat_screen.dart';
import 'bot/presentation/bot_list_screen.dart';
import 'email/presentation/email_screen.dart';
import 'prompt/presentation/prompt_management_screen.dart';
import 'subscription/presentation/subscription_info_screen.dart';
import 'knowledge/presentation/knowledge_base_screen.dart';

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
  int _currentIndex = 2;

  // Bottom navigation labels - sử dụng labels ngắn hơn để hiển thị tốt hơn
  final List<String> _shortLabels = ['Email', 'Prompt', 'Chat', 'Bot', 'KB', 'User'];
  final List<String> _fullLabels = ['Email', 'Prompt', 'Chat', 'Bot', 'Knowledge', 'User'];

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
      KnowledgeBaseScreen(toggleTheme: widget.toggleTheme),
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < _shortLabels.length; i++)
              _buildNavItem(
                _getIconForIndex(i), 
                _shortLabels[i],  // Sử dụng nhãn ngắn hơn
                _fullLabels[i],   // Giữ full label để hiển thị trong AppBar
                i
              ),
          ],
        ),
      ),
    );
  }
  
  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0: return Icons.email;
      case 1: return Icons.format_quote;
      case 2: return Icons.chat_bubble;
      case 3: return Icons.android;
      case 4: return Icons.book;
      case 5: return Icons.person;
      default: return Icons.circle;
    }
  }

  Widget _buildNavItem(IconData icon, String shortLabel, String fullLabel, int index) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    final colors = theme.brightness == Brightness.dark ? AppColors.dark : AppColors.light;
    
    Color iconColor = isSelected 
        ? theme.colorScheme.primary
        : colors.muted;
        
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: isSelected
              ? BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(60),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                shortLabel, // Hiển thị nhãn ngắn để vừa không gian
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
