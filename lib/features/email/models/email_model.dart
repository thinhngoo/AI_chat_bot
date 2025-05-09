import 'package:flutter/material.dart';

/// Class representing an email draft
class EmailDraft {
  final String to;
  final String cc;
  final String bcc;
  final String subject;
  final String body;
  
  EmailDraft({
    this.to = '',
    this.cc = '',
    this.bcc = '',
    this.subject = '',
    this.body = '',
  });
  
  /// Create a copy of this draft with some fields replaced
  EmailDraft copyWith({
    String? to,
    String? cc,
    String? bcc,
    String? subject,
    String? body,
  }) {
    return EmailDraft(
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      subject: subject ?? this.subject,
      body: body ?? this.body,
    );
  }
  
  /// Check if the draft has any significant content
  bool get hasContent {
    return to.isNotEmpty || 
           cc.isNotEmpty || 
           bcc.isNotEmpty || 
           subject.isNotEmpty || 
           body.isNotEmpty;
  }
}

/// Types of email actions for composing responses
enum EmailActionType {
  thanks(Icons.sentiment_very_satisfied, 'Thank You'),
  sorry(Icons.sentiment_very_dissatisfied, 'Apology'),
  followUp(Icons.follow_the_signs, 'Follow-up'),
  requestInfo(Icons.help_outline, 'Ask Info'),
  positive(Icons.thumb_up, 'Positive'),
  negative(Icons.thumb_down, 'Negative'),
  formal(Icons.business, 'Formal'),
  informal(Icons.chat_bubble, 'Informal'),
  shorter(Icons.short_text, 'Shorter'),
  detailed(Icons.article, 'Detailed'),
  urgent(Icons.priority_high, 'Urgent');
  
  final IconData icon;
  final String label;
  
  const EmailActionType(this.icon, this.label);
}

/// Suggestion for email response based on original email
class EmailSuggestion {
  final EmailActionType actionType;
  final String content;
  
  EmailSuggestion({
    required this.actionType,
    required this.content,
  });
}