import 'package:logger/logger.dart';
import '../models/email_model.dart';

class EmailService {
  final Logger _logger = Logger();
  
  // Get email suggestions based on the original email
  Future<List<EmailSuggestion>> getSuggestions(String originalEmail) async {
    _logger.i('Getting email suggestions');
    
    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 2));
      
      // For now, return mock suggestions - would connect to actual API in production
      return [
        EmailSuggestion(
          actionType: EmailActionType.thanks,
          content: 'Thank you for your detailed email. I appreciate the information you provided...',
        ),
        EmailSuggestion(
          actionType: EmailActionType.formal,
          content: 'I hope this message finds you well. In reference to the matter you addressed...',
        ),
        EmailSuggestion(
          actionType: EmailActionType.followUp,
          content: 'I wanted to follow up on our previous conversation regarding the project timeline...',
        ),
        EmailSuggestion(
          actionType: EmailActionType.informal,
          content: 'Thanks for your note! I am happy to help with what you mentioned...',
        ),
      ];
    } catch (e) {
      _logger.e('Error getting email suggestions: $e');
      throw 'Failed to generate email suggestions: $e';
    }
  }
  
  // Compose a new email draft based on the original email and action type
  Future<EmailDraft> composeEmail(String originalEmail, EmailActionType actionType) async {
    _logger.i('Composing email draft of type: ${actionType.label}');
    
    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Create mock email draft based on action type
      final subject = 'Re: ${_generateSubject(originalEmail)}';
      final body = _generateEmailBody(originalEmail, actionType);
      
      return EmailDraft(
        subject: subject,
        body: body,
      );
    } catch (e) {
      _logger.e('Error composing email draft: $e');
      throw 'Failed to compose email draft: $e';
    }
  }
  
  // Improve an existing email draft using AI
  Future<EmailDraft> improveEmailDraft(EmailDraft draft, EmailActionType actionType) async {
    _logger.i('Improving email draft with style: ${actionType.label}');
    
    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));
      
      // For now, return a slightly modified version of the input draft
      final improvedBody = _applyStyleToEmail(draft.body, actionType);
      
      return EmailDraft(
        to: draft.to,
        cc: draft.cc,
        subject: draft.subject,
        body: improvedBody,
      );
    } catch (e) {
      _logger.e('Error improving email draft: $e');
      throw 'Failed to improve email draft: $e';
    }
  }
  
  // Helper method to generate a subject from original email
  String _generateSubject(String originalEmail) {
    // Extract subject from original email if possible
    final lines = originalEmail.split('\n');
    
    for (final line in lines) {
      if (line.toLowerCase().contains('subject:')) {
        return line.replaceFirst(RegExp('subject:', caseSensitive: false), '').trim();
      }
    }
    
    // Default subject if none found
    return 'Your Recent Email';
  }
  
  // Helper method to generate email body based on action type
  String _generateEmailBody(String originalEmail, EmailActionType actionType) {
    // Simplified mock implementation
    switch (actionType) {
      case EmailActionType.thanks:
        return '''
Dear [Recipient],

Thank you for your email regarding ${_extractTopic(originalEmail)}. I really appreciate you taking the time to share this information.

[Additional details based on original email]

Thanks again for reaching out. Please let me know if you need any further information.

Best regards,
[Your Name]
''';
        
      case EmailActionType.followUp:
        return '''
Dear [Recipient],

I'm writing to follow up on ${_extractTopic(originalEmail)} that we discussed previously. I wanted to check on the status and see if there's any progress.

[Additional context based on original email]

Looking forward to your response.

Kind regards,
[Your Name]
''';
        
      case EmailActionType.formal:
        return '''
Dear [Recipient],

I hope this email finds you well.

In reference to your correspondence regarding ${_extractTopic(originalEmail)}, I would like to provide the following response.

[Formal response based on original email]

Should you require any additional information, please do not hesitate to contact me.

Yours sincerely,
[Your Name]
''';
        
      case EmailActionType.informal:
        return '''
Hi there!

Thanks for your note about ${_extractTopic(originalEmail)}. 

[Casual response to the original email]

Let me know if you have any questions!

Cheers,
[Your Name]
''';
        
      case EmailActionType.sorry:
        return '''
Dear [Recipient],

I sincerely apologize regarding the matter of ${_extractTopic(originalEmail)}.

[Apology context based on original email]

I understand this may have caused inconvenience, and I'm committed to resolving this promptly.

Best regards,
[Your Name]
''';
        
      // Add cases for other email types with mock responses
      default:
        return '''
Dear [Recipient],

Thank you for your email about ${_extractTopic(originalEmail)}.

[Response based on original email]

Please let me know if you need anything else.

Best regards,
[Your Name]
''';
    }
  }
  
  // Helper method to extract the main topic from the original email
  String _extractTopic(String originalEmail) {
    // Simple implementation - extract first non-empty line that isn't a greeting
    final lines = originalEmail.split('\n')
        .where((line) => line.trim().isNotEmpty)
        .where((line) => !line.toLowerCase().contains('hi') && 
                        !line.toLowerCase().contains('hello') &&
                        !line.toLowerCase().contains('dear'))
        .toList();
    
    if (lines.isNotEmpty) {
      final firstLine = lines[0].trim();
      if (firstLine.length > 50) {
        return '${firstLine.substring(0, 47)}...';
      }
      return firstLine;
    }
    
    return 'the matter discussed';
  }
  
  // Helper method to apply a specific style to an email
  String _applyStyleToEmail(String originalBody, EmailActionType actionType) {
    switch (actionType) {
      case EmailActionType.formal:
        return originalBody
            .replaceAll('Hi', 'Dear Sir/Madam')
            .replaceAll('Hey', 'Dear Sir/Madam')
            .replaceAll('Thanks', 'Thank you')
            .replaceAll('Cheers', 'Yours sincerely');
        
      case EmailActionType.informal:
        return originalBody
            .replaceAll('Dear Sir/Madam', 'Hi there')
            .replaceAll('To whom it may concern', 'Hi')
            .replaceAll('Yours sincerely', 'Cheers')
            .replaceAll('Best regards', 'All the best');
        
      case EmailActionType.shorter:
        // Simplified implementation - just remove some common phrases
        return originalBody
            .replaceAll('I hope this email finds you well. ', '')
            .replaceAll('I am writing to ', 'I ')
            .replaceAll('Please do not hesitate to ', 'Please ')
            .replaceAll('I would like to ', 'I will ');
        
      case EmailActionType.detailed:
        // Add more context (simplified implementation)
        return '''$originalBody

I've attached additional information for your reference.

Please don't hesitate to reach out if you need any clarification or have follow-up questions about any aspect of this matter.
''';
        
      case EmailActionType.urgent:
        // Add urgency markers
        return '''URGENT: Action Required

$originalBody

I would greatly appreciate your prompt attention to this matter. If possible, please respond by the end of today.

Thank you for your immediate assistance.
''';
        
      default:
        // No changes for other action types
        return originalBody;
    }
  }
}