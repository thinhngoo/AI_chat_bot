import 'package:flutter/material.dart';
import 'ai_chat_page.dart';
import 'profile_page.dart';
import '../__mocks__/chat_data.dart';

class ChatHistoryPage extends StatelessWidget {
  const ChatHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const ChatHistoryHeader(),
      body: const ChatHistoryBody(),
      floatingActionButton: const NewChatButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class ChatHistoryHeader extends StatelessWidget implements PreferredSizeWidget {
  const ChatHistoryHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: Theme.of(context).appBarTheme.elevation,
      scrolledUnderElevation:
          Theme.of(context).appBarTheme.scrolledUnderElevation,
      leading: IconButton(
        icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.onSurface),
        onPressed: () {},
      ),
      title: Text(
        'Chats',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: const CircleAvatar(
              backgroundColor: Color(0xFFD5D5D5),
              child: Text(
                'B',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ChatHistoryBody extends StatelessWidget {
  const ChatHistoryBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...chatHistory.map(
            (section) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, section.title),
                ...section.items.map(
                  (item) => _buildChatItem(context, item.title, item.time),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, String title, String time) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class NewChatButton extends StatelessWidget {
  const NewChatButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        onPressed:
            () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => const AIChatPage())),
        label: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              'New Chat',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
