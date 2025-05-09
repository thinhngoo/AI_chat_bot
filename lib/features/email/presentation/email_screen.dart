import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/email_model.dart';
import '../services/email_service.dart';
import '../../../features/subscription/services/subscription_service.dart';
import '../../../features/subscription/widgets/ad_banner_widget.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/text_field.dart';
import '../../../widgets/button.dart';
import '../../../widgets/typing_indicator.dart';
import 'email_compose_screen.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({
    super.key,
  });

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final Logger _logger = Logger();
  final EmailService _emailService = EmailService();
  final SubscriptionService _subscriptionService = SubscriptionService(
    AuthService(),
    Logger(),
  );

  final TextEditingController _originalEmailController =
      TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isPro = false;
  String _errorMessage = '';
  List<EmailSuggestion> _suggestions = [];

  // Sample emails for users to use as examples
  final List<Map<String, String>> _sampleEmails = [
    {
      'title': 'Project Deadline Extension',
      'content':
          'Hi Team,\n\nI\'m writing to inform you that we need to extend the project deadline by two weeks. The client has requested additional features which need time to implement properly.\n\nPlease adjust your schedules accordingly. We can discuss this further in our team meeting tomorrow.\n\nBest regards,\nMike'
    },
    {
      'title': 'Interview Invitation',
      'content':
          'Dear Candidate,\n\nThank you for applying for the Software Developer position at our company. We were impressed with your profile and would like to invite you for an interview.\n\nCould you please let us know your availability next week? We are flexible between 9 AM and 5 PM.\n\nLooking forward to meeting you.\n\nBest regards,\nHR Team'
    },
    {
      'title': 'Customer Complaint',
      'content':
          'Hello,\n\nI\'m very disappointed with the service I received yesterday at your store location. I purchased a product that was defective and when I returned it, your staff was unhelpful and rude.\n\nI\'ve been a loyal customer for years and expect better treatment. I would appreciate if you could look into this matter.\n\nThank you,\nAn Unhappy Customer'
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }

  @override
  void dispose() {
    _originalEmailController.dispose();
    _emailFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      final subscription = await _subscriptionService.getCurrentSubscription();
      if (mounted) {
        setState(() {
          _isPro = subscription.isPro;
        });
      }
    } catch (e) {
      _logger.e('Error checking subscription status: $e');
    }
  }

  Future<void> _getSuggestions() async {
    final originalEmail = _originalEmailController.text.trim();

    if (originalEmail.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an email to get suggestions';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _suggestions = [];
    });

    try {
      final suggestions = await _emailService.getSuggestions(originalEmail);

      if (!mounted) return;

      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });

      // Scroll to suggestions when they're loaded
      if (_suggestions.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            300, // Scroll position to ensure suggestions are visible
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToComposeScreen(EmailActionType actionType) async {
    final originalEmail = _originalEmailController.text.trim();

    if (originalEmail.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an email to compose a response';
      });
      return;
    }

    // Navigate to compose screen with selected action type
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailComposeScreen(
          originalEmail: originalEmail,
          actionType: actionType,
        ),
      ),
    );

    // Handle result if needed (e.g., show a success message)
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email draft saved'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _useSampleEmail(int index) {
    if (index < 0 || index >= _sampleEmails.length) return;

    setState(() {
      _originalEmailController.text = _sampleEmails[index]['content'] ?? '';
      _suggestions = [];
      _errorMessage = '';
    });
  }

  void _clearEmail() {
    setState(() {
      _originalEmailController.text = '';
      _suggestions = [];
      _errorMessage = '';
    });
    _emailFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final AppColors colors = isDarkMode ? AppColors.dark : AppColors.light;

    return Scaffold(
      appBar: AppBar(
        title: Text('Email Composer'),
        centerTitle: true,
        actions: [
          // Pro subscription indicator
          if (_isPro)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(
                Icons.diamond,
                color: isDarkMode ? Colors.amberAccent : Colors.amber,
              ),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            if (!_isPro) const AdBannerWidget(),

            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                children: [
                  Text(
                    'AI Email Assistant',
                    style: theme.textTheme.headlineMedium,
                  ),

                  const SizedBox(height: 8),
                  
                  Text(
                    'Get AI help composing professional emails for any situation',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.muted,
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  Text(
                    'First, paste the email you received:',
                    style: theme.textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 8),
                  
                  CustomTextField(
                    controller: _originalEmailController,
                    label: 'Email Content',
                    hintText: 'Paste the email you want to respond to...',
                    maxLines: 6,
                    darkMode: isDarkMode,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    onChanged: (_) {
                      setState(() {}); // Trigger rebuild to update button state
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  if (_originalEmailController.text.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        MiniGhostButton(
                          label: 'Clear email',
                          icon: Icons.delete_outline,
                          onPressed: _clearEmail,
                          color: colors.delete,
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 12),

                  Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          'Try with sample:',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      ...List.generate(
                        _sampleEmails.length,
                        (index) => InkWell(
                          onTap: () => _useSampleEmail(index),
                          child: Chip(
                            label: Text(_sampleEmails[index]['title']!),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: colors.cardForeground,
                            ),
                            backgroundColor: colors.card,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: colors.border),
                            ),
                            padding: const EdgeInsets.all(0),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  LargeButton(
                    label: 'Get AI Suggestions',
                    icon: Icons.auto_awesome,
                    onPressed:
                        _isLoading || _originalEmailController.text.isEmpty
                            ? null
                            : _getSuggestions,
                    variant: ButtonVariant.primary,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: colors.error.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.error.withAlpha(128)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: colors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(color: colors.error),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Loading indicator
                  if (_isLoading) ...[
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TypingIndicator(isTyping: true),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Getting email suggestions...',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.foreground.withAlpha(128),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Suggestions
                  if (_suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Suggested responses:',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),

                    // Grid of suggestion cards
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return _buildSuggestionCard(suggestion);
                      },
                    ),
                  ],

                  const SizedBox(height: 30),

                  // All email actions
                  Text(
                    'Choose your response type:',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: _originalEmailController.text.isEmpty
                          ? colors.muted
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email action types
                  GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 1,
                    crossAxisSpacing: 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildActionCard(EmailActionType.thanks),
                      _buildActionCard(EmailActionType.sorry),
                      _buildActionCard(EmailActionType.followUp),
                      _buildActionCard(EmailActionType.requestInfo),
                      _buildActionCard(EmailActionType.positive),
                      _buildActionCard(EmailActionType.negative),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Email formatting options
                  Text(
                    'Select tone and style:',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: _originalEmailController.text.isEmpty
                          ? colors.muted
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Formatting options
                  GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 1,
                    crossAxisSpacing: 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildActionCard(EmailActionType.formal),
                      _buildActionCard(EmailActionType.informal),
                      _buildActionCard(EmailActionType.shorter),
                      _buildActionCard(EmailActionType.detailed),
                      _buildActionCard(EmailActionType.urgent),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(EmailSuggestion suggestion) {
    final theme = Theme.of(context);
    final colors =
        theme.brightness == Brightness.dark ? AppColors.dark : AppColors.light;
    final bool isDisabled = _originalEmailController.text.isEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isDisabled
            ? null
            : () => _navigateToComposeScreen(suggestion.actionType),
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and action type
                Row(
                  children: [
                    Icon(
                      suggestion.actionType.icon,
                      color: colors.primary,
                    ),

                    const SizedBox(width: 8),
                    
                    Text(
                      suggestion.actionType.label,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ],
                ),
                Divider(
                  color: colors.border,
                ),
                // Preview content
                Expanded(
                  child: Text(
                    suggestion.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(204),
                    ),
                  ),
                ),
                // Action button
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(EmailActionType actionType) {
    final theme = Theme.of(context);
    final colors =
        theme.brightness == Brightness.dark ? AppColors.dark : AppColors.light;
    final bool isDisabled = _originalEmailController.text.isEmpty;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isDisabled ? null : () => _navigateToComposeScreen(actionType),
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  actionType.icon,
                  size: 32,
                  color: colors.primary,
                ),

                const SizedBox(height: 8),
                
                Text(
                  actionType.label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.cardForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
