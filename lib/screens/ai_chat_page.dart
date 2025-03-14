import 'package:flutter/material.dart';
import 'chat_history_page.dart';
import 'profile_page.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => const ChatBottomModal(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: const ChatHeader(),
      body: Column(
        children: [
          const Expanded(child: ChatBody()),
          ChatInputBar(onAddPress: _showBottomSheet),
        ],
      ),
    );
  }
}

class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  const ChatHeader({super.key});
  final textSize = 16.0;

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
        padding: const EdgeInsets.only(left: 8),
        icon: Icon(
          Icons.arrow_back_ios,
          color: Theme.of(context).colorScheme.primary,
        ),
        onPressed:
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ChatHistoryPage()),
            ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Demo ',
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            '3.7 Sonnet',
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        GestureDetector(
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              ),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: const CircleAvatar(
              backgroundColor: Color(0xFFD5D5D5),
              child: Text(
                'T',
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

class ChatBody extends StatelessWidget {
  const ChatBody({super.key});
  final iconSize = 60.0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: Icon(
              Icons.explore,
              color: Theme.of(context).colorScheme.primary,
              size: iconSize,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tôi có thể giúp gì cho bạn?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ChatInputBar extends StatelessWidget {
  final VoidCallback onAddPress;

  const ChatInputBar({super.key, required this.onAddPress});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceDim,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: onAddPress,
          ),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Hỏi bất kỳ điều gì',
                hintStyle: TextStyle(color: Color(0xFF888888)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              style: TextStyle(color: Colors.white),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.send,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBottomModal extends StatefulWidget {
  const ChatBottomModal({super.key});

  @override
  State<ChatBottomModal> createState() => _ChatBottomModalState();
}

class _ChatBottomModalState extends State<ChatBottomModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  bool _showModelSelection = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleModelSelection() {
    setState(() {
      _showModelSelection = !_showModelSelection;
      if (_showModelSelection) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Widget _buildBottomSheetItem(
    BuildContext context,
    IconData icon,
    String label,
  ) {
    const squareSize = 76.0;

    return Column(
      children: [
        Container(
          width: squareSize,
          height: squareSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 1.0,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Stack(
        children: [
          _buildMainContent(context),

          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  MediaQuery.of(context).size.height *
                      (1 - _animationController.value),
                ),
                child: child,
              );
            },
            child: _buildModelSelectionPanel(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomSheetItem(context, Icons.camera_alt, 'Camera'),
            _buildBottomSheetItem(context, Icons.photo, 'Photos'),
            _buildBottomSheetItem(context, Icons.insert_drive_file, 'Files'),
          ],
        ),
        const SizedBox(height: 36),
        ListTile(
          leading: Icon(
            Icons.model_training,
            size: 36,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          title: Text(
            'Chọn mô hình',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            'Claude 3.7 Sonnet (Preview)',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          onTap: _toggleModelSelection,
        ),
      ],
    );
  }

  Widget _buildModelSelectionPanel(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            leading: IconButton(
              padding: const EdgeInsets.only(left: 8),
              icon: Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: _toggleModelSelection,
            ),
            title: Text(
              'Choose style',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            centerTitle: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change how Claude will write responses',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                _buildModelOption(
                  context,
                  'GPT-4o',
                  'Default responses from GPT-4o',
                ),
                _buildModelOption(
                  context,
                  'Sonnet 3.5',
                  'Shorter responses & more messages',
                ),
                _buildModelOption(
                  context,
                  'Gemini',
                  'Educational responses for learning',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelOption(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () {
          _toggleModelSelection();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
