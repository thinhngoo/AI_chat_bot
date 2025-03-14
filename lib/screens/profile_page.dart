import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool hapticFeedbackEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const ProfileHeader(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ProfileInfoCard(),
            SettingsSection(
              hapticFeedbackEnabled: hapticFeedbackEnabled,
              onHapticFeedbackChanged: (value) {
                setState(() {
                  hapticFeedbackEnabled = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget implements PreferredSizeWidget {
  const ProfileHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _showInfoMenu(BuildContext context, BuildContext buttonContext) {
    final RenderBox button = buttonContext.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonSize = button.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonPosition.dx,
        buttonPosition.dy + buttonSize.height,
        buttonPosition.dx + buttonSize.width,
        buttonPosition.dy + buttonSize.height,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      items: [
        PopupMenuItem(
          padding: EdgeInsets.zero,
          child: _buildMenuOption(context, Icons.description, 'Consumer Terms'),
        ),
        PopupMenuItem(
          padding: EdgeInsets.zero,
          child: _buildMenuOption(
            context,
            Icons.description,
            'Acceptable Use Policy',
          ),
        ),
        PopupMenuItem(
          padding: EdgeInsets.zero,
          child: _buildMenuOption(context, Icons.privacy_tip, 'Privacy Policy'),
        ),
        PopupMenuItem(
          padding: EdgeInsets.zero,
          child: _buildMenuOption(context, Icons.description, 'Licenses'),
        ),
        PopupMenuItem(
          padding: EdgeInsets.zero,
          child: _buildMenuOption(
            context,
            Icons.help_outline,
            'Help & Support',
          ),
        ),
      ],
    );
  }

  Widget _buildMenuOption(BuildContext context, IconData icon, String title) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        padding: const EdgeInsets.only(left: 8),
        icon: Icon(
          Icons.arrow_back_ios,
          color: Theme.of(context).colorScheme.primary,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Settings',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w400,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: Builder(
            builder:
                (buttonContext) => IconButton(
                  icon: const Icon(Icons.info_outline),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    _showInfoMenu(context, buttonContext);
                  },
                ),
          ),
        ),
      ],
    );
  }
}

class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceDim,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'byronat445@gmail.com',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Free',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  final bool hapticFeedbackEnabled;
  final ValueChanged<bool> onHapticFeedbackChanged;

  const SettingsSection({
    super.key,
    required this.hapticFeedbackEnabled,
    required this.onHapticFeedbackChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDivider(),
        _buildSettingsItem(
          context,
          icon: Icons.language,
          title: 'Speech language',
          subtitle: 'English',
          onTap: () {},
        ),
        _buildSettingsItem(
          context,
          icon: Icons.brightness_6,
          title: 'Appearance',
          subtitle: 'System',
          onTap: () {},
        ),
        _buildDivider(),
        _buildSettingsItem(
          context,
          icon: Icons.logout,
          title: 'Log out',
          titleColor: Theme.of(context).colorScheme.error,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(color: const Color(0xFF2D2D2D), height: 1, thickness: 1);
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: titleColor ?? Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color:
                          titleColor ?? Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
