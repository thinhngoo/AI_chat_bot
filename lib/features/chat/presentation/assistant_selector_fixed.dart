import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/constants/app_colors.dart';
import '../../../features/bot/services/bot_service.dart';
import '../../../features/bot/presentation/bot_list_screen.dart';
import '../../../widgets/button.dart';

class Assistant {
  final String id;
  final String name;
  final String description;
  final bool isCustomBot;

  const Assistant({
    required this.id,
    required this.name,
    required this.description,
    this.isCustomBot = false,
  });
}

class AssistantSelector extends StatefulWidget {
  final String selectedAssistantId;
  final ValueChanged<String> onSelect;

  const AssistantSelector({
    super.key,
    required this.selectedAssistantId,
    required this.onSelect,
  });

  @override
  State<AssistantSelector> createState() => AssistantSelectorState();
}

class AssistantSelectorState extends State<AssistantSelector> with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final Logger _logger = Logger();
  final BotService _botService = BotService();
  
  // Animation controller for refresh indicator - fixed single declaration
  late AnimationController _refreshController;
  bool _isBackgroundRefreshing = false;

  // Base AI models
  final List<Assistant> _baseAssistants = [
    Assistant(
        id: 'gpt-4o',
        name: 'GPT-4o',
        description: 'Advanced intelligence and vision capabilities'),
    Assistant(
        id: 'gpt-4o-mini',
        name: 'GPT-4o Mini',
        description: 'Fast and efficient responses'),
    Assistant(
        id: 'claude-3-haiku-20240307',
        name: 'Claude 3 Haiku',
        description: 'Quick responses with Claude AI'),
    Assistant(
        id: 'claude-3-sonnet-20240229',
        name: 'Claude 3 Sonnet',
        description: 'More powerful Claude model'),
    Assistant(
        id: 'gemini-1.5-pro-latest',
        name: 'Gemini 1.5 Pro',
        description: 'Google\'s advanced AI model'),
    Assistant(
        id: 'deepseek-chat',
        name: 'Deepseek Chat',
        description: 'DeepSeek\'s conversational AI model'),
  ];  // Custom bots from user
  List<Assistant> _customBots = [];
  bool _isLoadingBots = false;
  String? _botsError;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller for refresh indicator only once
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(); // Start repeating animation immediately
    
    _loadCustomBots();
    
    // Set up periodic refresh of bot list every 2 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _refreshBots();
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _refreshController.dispose();
    super.dispose();
  }
  
  // Background refresh without showing loading indicators
  Future<void> _refreshBots() async {
    if (!mounted) return;
    
    setState(() {
      _isBackgroundRefreshing = true;
    });

    try {
      final bots = await _botService.getBots(forceRefresh: true);
      
      if (mounted) {
        setState(() {
          _customBots = bots
              .map((bot) => Assistant(
                    id: bot.id,
                    name: bot.name,
                    description: bot.description,
                    isCustomBot: true,
                  ))
              .toList();
          _botsError = null;
        });
      }
    } catch (e) {
      _logger.e('Error refreshing bots: $e');
      // Don't update the error state to avoid UI flicker
      // But we can log it for debugging purposes
    } finally {
      if (mounted) {
        setState(() {
          _isBackgroundRefreshing = false;
        });
      }
    }
  }
  
  Future<void> _loadCustomBots() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingBots = true;
      _botsError = null;
    });

    try {
      // Try to load from cache first (fast)
      final bots = await _botService.getBots(forceRefresh: false);

      if (mounted) {
        setState(() {
          _customBots = bots
              .map((bot) => Assistant(
                    id: bot.id,
                    name: bot.name,
                    description: bot.description,
                    isCustomBot: true,
                  ))
              .toList();
          _isLoadingBots = false;
        });
        
        // Then refresh in background after a short delay
        Future.delayed(const Duration(milliseconds: 300), () {
          _refreshBots();
        });
      }
    } catch (e) {
      _logger.e('Error loading custom bots: $e');
      if (mounted) {
        setState(() {
          _botsError = e.toString();
          _isLoadingBots = false;
        });
      }
    }
  }

  List<Assistant> get assistants => [..._baseAssistants, ..._customBots];

  void _showMenu() {
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _buildOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colors = isDarkMode ? AppColors.dark : AppColors.light;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _hideMenu,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height + 6,
              width: 280,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(-(280 - size.width) / 2, size.height + 6),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    height: 400, // Fixed height with scrolling
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: isDarkMode
                          ? Border.all(color: theme.dividerColor.withAlpha(120))
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(18),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Base AI Models',
                                style: theme.textTheme.titleMedium,
                              ),
                              // Enhanced background refresh indicator
                              if (_isBackgroundRefreshing)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: RotationTransition(
                                    turns: _refreshController,
                                    child: Icon(
                                      Icons.refresh,
                                      size: 18,
                                      color: colors.muted,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: ListView(
                            shrinkWrap: true,
                            padding: const EdgeInsets.only(top: 0, bottom: 12),
                            children: [
                              // Base AI models
                              ..._baseAssistants
                                  .map((assistant) => _buildMenuOption(
                                        id: assistant.id,
                                        title: assistant.name,
                                        subtitle: assistant.description,
                                        selected: widget.selectedAssistantId ==
                                            assistant.id,
                                        isCustomBot: false,
                                        onTap: () {
                                          widget.onSelect(assistant.id);
                                          _hideMenu();
                                        },
                                      )),

                              // Divider between models and bots
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Divider(
                                      color: colors.border,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Your Bots',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ),

                              // Custom bots section with improved UI feedback
                              if (_isLoadingBots)
                                Padding(
                                  padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
                                  child: Center(
                                      child: CircularProgressIndicator(
                                    color: colors.muted,
                                  )),
                                )
                              else if (_botsError != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 20, top: 8),
                                  child: Text(
                                    'Error loading bots: $_botsError',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                )
                              else if (_customBots.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 20, top: 8),
                                  child: Text(
                                    'No custom bots found',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colors.muted,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              else
                                ..._customBots.map((bot) => _buildMenuOption(
                                      id: bot.id,
                                      title: bot.name,
                                      subtitle: bot.description,
                                      selected:
                                          widget.selectedAssistantId == bot.id,
                                      isCustomBot: true,
                                      onTap: () {
                                        widget.onSelect(bot.id);
                                        _hideMenu();
                                      },
                                    )),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20),
                          child: Center(
                            child: Button(
                              label: 'Manage Bots',
                              icon: Icons.settings,
                              onPressed: () {
                                _hideMenu();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const BotListScreen(),
                                  ),
                                );
                              },
                              color: colors.cardForeground,
                              isDarkMode: theme.brightness == Brightness.dark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required String id,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
    bool isCustomBot = false,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final color = isDarkMode ? AppColors.dark : AppColors.light;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: selected
            ? theme.colorScheme.primary.withAlpha(10)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: selected ? theme.colorScheme.primary : color.muted,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      color: selected
                          ? theme.colorScheme.primary.withAlpha(200)
                          : color.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check, color: theme.colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.brightness == Brightness.dark ? AppColors.dark : AppColors.light;
    String title = 'AI Assistant';
    bool isCustomBot = false;

    // Find the selected assistant to display its name correctly
    for (final assistant in assistants) {
      if (assistant.id == widget.selectedAssistantId) {
        title = assistant.name;
        isCustomBot = assistant.isCustomBot;
        break;
      }
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          if (_overlayEntry == null) {
            _showMenu();
          } else {
            _hideMenu();
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              if (isCustomBot)
                Icon(Icons.smart_toy,
                    size: 24, color: colors.foreground.withAlpha(204)),
              // Show a small refresh indicator in the main selector when background refreshing
              if (_isBackgroundRefreshing)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: RotationTransition(
                      turns: _refreshController,
                      child: Icon(
                        Icons.refresh,
                        size: 12,
                        color: colors.muted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
