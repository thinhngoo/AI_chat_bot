import 'package:flutter/material.dart';
import 'chat/presentation/chat_screen.dart';
import 'bot/presentation/bot_list_screen.dart';
import 'email/presentation/email_screen.dart';
import 'prompt/presentation/prompt_management_screen.dart';
import 'subscription/presentation/subscription_info_screen.dart';
import 'knowledge/presentation/knowledge_base_screen.dart';

class MainScreen extends StatefulWidget {
  final Function toggleTheme;
  final Function setThemeMode;
  final String currentThemeMode;

  const MainScreen({
    super.key,
    required this.toggleTheme,
    required this.setThemeMode,
    required this.currentThemeMode,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2;

  // Navigation item labels and tooltips
  final List<String> _labels = ['Email', 'Prompt', 'Chat', 'Bot', 'Knowledge', 'User'];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // Initialize screens - pass parameters where needed
    _screens = [
      const EmailScreen(),
      const PromptManagementScreen(),
      const ChatScreen(),
      const BotListScreen(),
      const KnowledgeBaseScreen(),
      SubscriptionInfoScreen(
        toggleTheme: widget.toggleTheme,
        setThemeMode: widget.setThemeMode,
        currentThemeMode: widget.currentThemeMode,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 65, // Fixed height for the nav bar
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < _labels.length; i++)
              _buildNavItem(
                _getIconForIndex(i), 
                _labels[i],
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

  Widget _buildNavItem(IconData icon, String tooltip, int index) {
    final isSelected = _currentIndex == index;
    
    Color iconColor = isSelected 
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).hintColor;
    
    // Fixed size for square items
    const double itemSize = 42;
        
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentIndex = index;
            });
          },
          child: Center(
            child: Container(
              height: itemSize,
              width: itemSize,
              decoration: isSelected
                  ? BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withAlpha(60),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
