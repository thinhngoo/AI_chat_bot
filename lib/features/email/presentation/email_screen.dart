import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/email_model.dart';
import '../services/email_service.dart';
import '../../../widgets/common/typing_indicator.dart';
import '../../../features/subscription/services/subscription_service.dart';
import '../../../features/subscription/widgets/ad_banner_widget.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import 'email_compose_screen.dart';

class EmailScreen extends StatefulWidget {
  final Function toggleTheme;

  const EmailScreen({
    super.key,
    required this.toggleTheme,
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
    final AppColors colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Composer'),
        centerTitle: true,
        actions: [
          // Pro subscription indicator
          if (_isPro)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(
                Icons.verified,
                color: colors.primary,
              ),
            ),

          // Light/dark mode toggle
          IconButton(
            icon: Icon(
              Icons.dark_mode,
              color: theme.colorScheme.onSurface.withAlpha(200),
            ),
            tooltip: 'Toggle theme',
            onPressed: () => widget.toggleTheme(),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Show ad banner for free users
            if (!_isPro) const AdBannerWidget(),

            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Section title
                  Text(
                    'AI Email Assistant',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get AI help composing professional emails for any situation',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Email input section
                  Text(
                    'Paste the email you received:',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _originalEmailController,
                    focusNode: _emailFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Paste the email you want to respond to...',
                      border: const OutlineInputBorder(),
                      fillColor: theme.inputDecorationTheme.fillColor,
                      filled: true,
                      suffixIcon: _originalEmailController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearEmail,
                              tooltip: 'Clear',
                            )
                          : null,
                    ),
                    maxLines: 6,
                    textInputAction: TextInputAction.newline,
                  ),
                  const SizedBox(height: 8),

                  // Sample emails section
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      const Text('Try with sample: '),
                      ...List.generate(
                        _sampleEmails.length,
                        (index) => ActionChip(
                          label: Text(_sampleEmails[index]['title']!),
                          onPressed: () => _useSampleEmail(index),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Get suggestions button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _getSuggestions,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Get AI Suggestions'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Or select a specific email type to compose:',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withAlpha(153),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error message
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
                  if (_isLoading)
                    Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          TypingIndicator(isTyping: true),
                          const SizedBox(height: 8),
                          const Text('Getting email suggestions...'),
                        ],
                      ),
                    ),

                  // Suggestions
                  if (_suggestions.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Suggested responses:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return _buildSuggestionCard(suggestion);
                      },
                    ),
                  ],

                  const SizedBox(height: 24),

                  // All email actions
                  Text(
                    'Compose a specific type of email:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email action types
                  GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
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
                    'Email formatting options:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Formatting options
                  GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToComposeScreen(suggestion.actionType),
        borderRadius: BorderRadius.circular(12),
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
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    suggestion.actionType.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(),
              // Preview content
              Expanded(
                child: Text(
                  suggestion.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withAlpha(204),
                  ),
                ),
              ),
              // Action button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () =>
                        _navigateToComposeScreen(suggestion.actionType),
                    child: const Text('Use this'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(EmailActionType actionType) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToComposeScreen(actionType),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                actionType.icon,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                actionType.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
