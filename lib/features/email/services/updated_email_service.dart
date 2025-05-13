import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/email_model.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/auth/auth_service.dart';

class EmailService {
  final Logger _logger = Logger();
  final AuthService _authService = AuthService();
  
  // Get email suggestions based on the original email
  Future<List<EmailSuggestion>> getSuggestions(String originalEmail) async {
    _logger.i('Getting email suggestions');
    
    try {
      // Generate API URL
      final url = Uri.parse('${ApiConstants.jarvisApiUrl}${ApiConstants.aiEmailReplyIdeas}');
      
      // Get user token
      final token = await _authService.getToken();
      
      // Set up headers
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
      };
      
      // Prepare request data
      final requestData = {
        'action': 'Suggest 3 ideas for this email',
        'email': originalEmail,
        'metadata': {
          'context': [],
          'subject': _extractSubject(originalEmail),
          'sender': 'Unknown Sender',
          'receiver': 'me@example.com',
          'language': 'english'
        }
      };
      
      // Make API call
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestData),
      );
      
      _logger.i('API Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ideas = data['ideas'] as List<dynamic>;
        
        // Convert API response to app model
        final suggestions = ideas.asMap().entries.map((entry) {
          final index = entry.key;
          final content = entry.value as String;
          
          // Assign different action types based on index
          EmailActionType actionType;
          switch (index % 4) {
            case 0:
              actionType = EmailActionType.thanks;
              break;
            case 1:
              actionType = EmailActionType.formal;
              break;
            case 2:
              actionType = EmailActionType.followUp;
              break;
            case 3:
            default:
              actionType = EmailActionType.informal;
              break;
          }
          
          return EmailSuggestion(
            actionType: actionType,
            content: content,
          );
        }).toList();
        
        return suggestions;
      } else {
        _logger.e('API error: ${response.body}');
        throw 'Failed to get suggestions: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error getting email suggestions: $e');
      
      // Return mock data as fallback in case of API failure
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
    }
  }
  
  // Compose a new email draft based on the original email and action type
  Future<EmailDraft> composeEmail(String originalEmail, EmailActionType actionType) async {
    _logger.i('Composing email draft of type: ${actionType.label}');
    
    try {
      // Generate API URL
      final url = Uri.parse('${ApiConstants.jarvisApiUrl}${ApiConstants.aiEmail}');
      
      // Get user token
      final token = await _authService.getToken();
      
      // Set up headers
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
      };
      
      // Map action type to main idea and style
      String mainIdea;
      Map<String, String> style = {
        'length': 'long',
        'formality': 'neutral',
        'tone': 'friendly'
      };
      
      switch (actionType) {
        case EmailActionType.thanks:
          mainIdea = 'Express gratitude and appreciation for the information';
          style['tone'] = 'grateful';
          break;
        case EmailActionType.sorry:
          mainIdea = 'Apologize sincerely for the inconvenience';
          style['tone'] = 'apologetic';
          break;
        case EmailActionType.followUp:
          mainIdea = 'Follow up on the previous conversation';
          break;
        case EmailActionType.requestInfo:
          mainIdea = 'Request more information about the topic';
          break;
        case EmailActionType.positive:
          mainIdea = 'Express a positive response to the email';
          style['tone'] = 'positive';
          break;
        case EmailActionType.negative:
          mainIdea = 'Express a negative response to the email';
          style['tone'] = 'serious';
          break;
        case EmailActionType.formal:
          mainIdea = 'Respond in a formal and professional manner';
          style['formality'] = 'formal';
          break;
        case EmailActionType.informal:
          mainIdea = 'Respond in a casual and friendly manner';
          style['formality'] = 'informal';
          break;
        case EmailActionType.shorter:
          mainIdea = 'Provide a concise response';
          style['length'] = 'short';
          break;
        case EmailActionType.detailed:
          mainIdea = 'Provide a detailed and comprehensive response';
          style['length'] = 'very long';
          break;
        case EmailActionType.urgent:
          mainIdea = 'Respond with urgency to the email';
          style['tone'] = 'urgent';
          break;
      }
      
      // Prepare request data
      final requestData = {
        'mainIdea': mainIdea,
        'action': 'Reply to this email',
        'email': originalEmail,
        'metadata': {
          'context': [],
          'subject': 'Re: ${_extractSubject(originalEmail)}',
          'sender': 'User',
          'receiver': _extractEmailAddress(originalEmail),
          'style': style,
          'language': 'english'
        }
      };
      
      // Make API call
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestData),
      );
      
      _logger.i('API Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final emailContent = data['email'] as String;
        
        // Extract subject from response if possible
        final subject = 'Re: ${_extractSubject(originalEmail)}';
        
        return EmailDraft(
          subject: subject,
          body: emailContent,
        );
      } else {
        _logger.e('API error: ${response.body}');
        throw 'Failed to compose email: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error composing email draft: $e');
      
      // Fallback to mock implementation if API fails
      final subject = 'Re: ${_extractSubject(originalEmail)}';
      final body = _generateEmailBody(originalEmail, actionType);
      
      return EmailDraft(
        subject: subject,
        body: body,
      );
    }
  }
  
  // Improve an existing email draft using AI
  Future<EmailDraft> improveEmailDraft(EmailDraft draft, EmailActionType actionType) async {
    _logger.i('Improving email draft with style: ${actionType.label}');
    
    try {
      // Generate API URL
      final url = Uri.parse('${ApiConstants.jarvisApiUrl}${ApiConstants.aiEmail}');
      
      // Get user token
      final token = await _authService.getToken();
      
      // Set up headers
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
      };
      
      // Map action type to style
      Map<String, String> style = {
        'length': 'long',
        'formality': 'neutral',
        'tone': 'friendly'
      };
      
      String mainIdea;
      
      switch (actionType) {
        case EmailActionType.formal:
          mainIdea = 'Make this email more formal and professional';
          style['formality'] = 'formal';
          break;
        case EmailActionType.informal:
          mainIdea = 'Make this email more casual and friendly';
          style['formality'] = 'informal';
          break;
        case EmailActionType.shorter:
          mainIdea = 'Make this email more concise';
          style['length'] = 'short';
          break;
        case EmailActionType.detailed:
          mainIdea = 'Make this email more detailed and comprehensive';
          style['length'] = 'very long';
          break;
        case EmailActionType.positive:
          mainIdea = 'Make this email more positive and upbeat';
          style['tone'] = 'positive';
          break;
        default:
          mainIdea = 'Improve this email';
          break;
      }
      
      // Prepare request data
      final requestData = {
        'mainIdea': mainIdea,
        'action': 'Improve this email',
        'email': draft.body,
        'metadata': {
          'context': [],
          'subject': draft.subject,
          'sender': 'User',
          'receiver': draft.to.isNotEmpty ? draft.to : 'recipient@example.com',
          'style': style,
          'language': 'english'
        }
      };
      
      // Make API call
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestData),
      );
      
      _logger.i('API Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final improvedEmail = data['email'] as String;
        
        return EmailDraft(
          to: draft.to,
          cc: draft.cc,
          bcc: draft.bcc,
          subject: draft.subject,
          body: improvedEmail,
        );
      } else {
        _logger.e('API error: ${response.body}');
        throw 'Failed to improve email: ${response.statusCode}';
      }
    } catch (e) {
      _logger.e('Error improving email draft: $e');
      
      // Fallback to original implementation
      final improvedBody = _applyStyleToEmail(draft.body, actionType);
      
      return EmailDraft(
        to: draft.to,
        cc: draft.cc,
        bcc: draft.bcc,
        subject: draft.subject,
        body: improvedBody,
      );
    }
  }
  
  // Helper method to extract subject from original email
  String _extractSubject(String originalEmail) {
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
  
  // Helper method to extract email address from original email
  String _extractEmailAddress(String originalEmail) {
    final emailRegex = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    final match = emailRegex.firstMatch(originalEmail);
    return match?.group(0) ?? 'recipient@example.com';
  }
  
  // Helper method to generate email body based on action type (fallback method)
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
        return originalBody;
    }
  }
}
