import 'package:flutter/material.dart';

class SelectKnowledgeSourceDialog extends StatelessWidget {
  const SelectKnowledgeSourceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 24, right: 24, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Knowledge Source',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CloseButton(),
                ],
              ),
            ),
            
            // List of source options
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSourceOption(
                      context: context,
                      icon: Icons.insert_drive_file,
                      iconColor: Colors.blue,
                      title: 'Local files',
                      description: 'Upload pdf, docx, ...',
                      value: 'file',
                    ),
                    const Divider(height: 1),
                    
                    _buildSourceOptionWithImage(
                      context: context,
                      imagePath: 'assets/images/slack_logo.png',
                      title: 'Slack',
                      description: 'Connect to Slack workspace',
                      value: 'slack',
                    ),
                    const Divider(height: 1),
                    
                    _buildSourceOptionWithImage(
                      context: context,
                      imagePath: 'assets/images/confluence_logo.png',
                      title: 'Confluence',
                      description: 'Connect to Confluence',
                      value: 'confluence',
                    ),
                    const Divider(height: 1),
                    
                    _buildSourceOptionWithImage(
                      context: context,
                      imagePath: 'assets/images/notion_logo.png',
                      title: 'Notion',
                      description: 'Connect to Notion workspace',
                      value: 'notion',
                    ),
                    const Divider(height: 1),
                    
                    _buildSourceOption(
                      context: context,
                      icon: Icons.discord,
                      iconColor: const Color(0xFF5865F2),
                      title: 'Discord',
                      description: 'Connect to Discord server',
                      value: 'discord',
                    ),
                    const Divider(height: 1),
                    
                    _buildSourceOption(
                      context: context,
                      icon: Icons.language,
                      iconColor: Colors.purple,
                      title: 'Website',
                      description: 'Connect Website to get data',
                      value: 'website',
                      badge: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'Coming soon',
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 10,
                          ),
                        ),
                      ),
                      badgeColor: Colors.grey,
                    ),
                    const Divider(height: 1),
                    
                    _buildSourceOptionWithImage(
                      context: context,
                      imagePath: 'assets/images/google_logo.png',
                      title: 'Google Drive',
                      description: 'Connect to Google Drive',
                      value: 'google_drive',
                      badge: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'Coming soon',
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 10,
                          ),
                        ),
                      ),
                      badgeColor: Colors.grey,
                    ),
                    const Divider(height: 1),
                    
                    _buildSourceOption(
                      context: context,
                      icon: Icons.code,
                      iconColor: const Color(0xFF171515),
                      title: 'GitHub Repository',
                      description: 'Connect to GitHub Repository',
                      value: 'github',
                      badge: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'Coming soon',
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 10,
                          ),
                        ),
                      ),
                      badgeColor: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String value,
    Widget? badge,
    Color? badgeColor,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: badgeColor ?? Colors.grey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: badge,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOptionWithImage({
    required BuildContext context,
    required String imagePath,
    required String title,
    required String description,
    required String value,
    Widget? badge,
    Color? badgeColor,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              width: 40,
              height: 40,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: badgeColor ?? Colors.grey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: badge,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
