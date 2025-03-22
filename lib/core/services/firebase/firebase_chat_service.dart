import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/message.dart';
import '../../models/firebase/firebase_chat_session.dart';
import '../auth/auth_service.dart';

class FirebaseChatService {
  final Logger _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  
  // Collection references
  CollectionReference get _chatSessionsCollection => 
      _firestore.collection('chatSessions');
  
  // Get chat sessions for current user
  Future<List<ChatSession>> getUserChatSessions() async {
    try {
      // Get current user ID
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _logger.w('No user logged in, returning empty chat sessions list');
        return [];
      }
      
      // Get user ID based on auth provider type
      final userId = currentUser is String ? currentUser : currentUser.uid;
      
      // Query Firestore for this user's chat sessions
      final querySnapshot = await _chatSessionsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('lastUpdatedAt', descending: true)
          .get();
      
      // Convert to local models
      List<ChatSession> chatSessions = [];
      for (var doc in querySnapshot.docs) {
        // Fix: Cast the data to Map<String, dynamic> explicitly
        final data = doc.data() as Map<String, dynamic>;
        
        // Create chat session from data
        final chatSession = ChatSession(
          id: doc.id,
          title: data['title'] ?? 'Untitled Chat',
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          messages: [], // Will load messages separately
        );
        
        // Load messages for this session from subcollection
        final messagesSnapshot = await _chatSessionsCollection
            .doc(doc.id)
            .collection('messages')
            .orderBy('timestamp')
            .get();
        
        // Create message list
        final messages = messagesSnapshot.docs.map((msgDoc) => 
          FirebaseMessage.fromMap(
            msgDoc.data(), 
            msgDoc.id
          ).toMessage()
        ).toList();
        
        // Create complete chat session with messages
        chatSessions.add(ChatSession(
          id: chatSession.id,
          title: chatSession.title,
          createdAt: chatSession.createdAt,
          messages: messages,
        ));
      }
      
      return chatSessions;
    } catch (e) {
      _logger.e('Error getting user chat sessions: $e');
      return [];
    }
  }
  
  // Save a chat session to Firestore
  Future<bool> saveChatSession(ChatSession session) async {
    try {
      // Get current user ID
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _logger.w('No user logged in, cannot save chat session');
        return false;
      }
      
      // Get user ID based on auth provider type
      final userId = currentUser is String ? currentUser : currentUser.uid;
      
      // Convert to Firebase model
      final firebaseSession = FirebaseChatSession.fromChatSession(session, userId);
      
      // Save session document (without messages)
      await _chatSessionsCollection.doc(session.id).set(firebaseSession.toMap());
      
      // Save messages to subcollection
      final messagesCollection = _chatSessionsCollection
          .doc(session.id)
          .collection('messages');
      
      // Clear existing messages (optional - you might want different behavior)
      await _deleteAllMessages(session.id);
      
      // Add all messages
      for (var message in firebaseSession.messages) {
        await messagesCollection.add(message.toMap());
      }
      
      return true;
    } catch (e) {
      _logger.e('Error saving chat session: $e');
      return false;
    }
  }
  
  // Delete a chat session
  Future<bool> deleteChatSession(String sessionId) async {
    try {
      // Delete all messages first
      await _deleteAllMessages(sessionId);
      
      // Delete the session document
      await _chatSessionsCollection.doc(sessionId).delete();
      
      return true;
    } catch (e) {
      _logger.e('Error deleting chat session: $e');
      return false;
    }
  }
  
  // Helper to delete all messages in a chat session
  Future<void> _deleteAllMessages(String sessionId) async {
    final messagesCollection = _chatSessionsCollection
        .doc(sessionId)
        .collection('messages');
        
    final messagesSnapshot = await messagesCollection.get();
    
    // Create a batch for efficient deletion
    final batch = _firestore.batch();
    
    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
  
  // Add a single message to an existing chat session
  Future<bool> addMessage(String sessionId, Message message) async {
    try {
      // Update session's lastUpdatedAt timestamp
      await _chatSessionsCollection.doc(sessionId).update({
        'lastUpdatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      // Add the new message
      final firebaseMessage = FirebaseMessage.fromMessage(message);
      
      await _chatSessionsCollection
          .doc(sessionId)
          .collection('messages')
          .add(firebaseMessage.toMap());
      
      return true;
    } catch (e) {
      _logger.e('Error adding message: $e');
      return false;
    }
  }
}

// Move FirebaseMessage class outside of FirebaseChatService class
class FirebaseMessage {
  final String id;
  final String text;
  final bool isUser;
  final Timestamp timestamp;
  
  FirebaseMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp,
    };
  }
  
  static FirebaseMessage fromMap(Map<String, dynamic> map, String docId) {
    return FirebaseMessage(
      id: docId,
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }
  
  Message toMessage() {
    return Message(
      text: text,
      isUser: isUser,
      timestamp: timestamp.toDate(),
    );
  }
  
  static FirebaseMessage fromMessage(Message message) {
    return FirebaseMessage(
      id: '',
      text: message.text,
      isUser: message.isUser,
      timestamp: Timestamp.fromDate(message.timestamp),
    );
  }
}
