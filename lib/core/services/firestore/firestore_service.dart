import 'package:logger/logger.dart';
import '../../models/user_model.dart';
import '../api/jarvis_api_service.dart';

class FirestoreService {
  final Logger _logger = Logger();
  final JarvisApiService _apiService = JarvisApiService();
  
  // Create or update user document
  Future<void> saveUserData(UserModel user) async {
    try {
      await _apiService.updateUserProfile({
        'name': user.name,
        'selectedModel': user.selectedModel,
      });
      _logger.i('User data saved to API: ${user.email}');
    } catch (e) {
      _logger.e('Error saving user data to API: $e');
      throw 'Failed to save user data: $e';
    }
  }
  
  // Update a specific field in a user document
  Future<void> updateUserField(String uid, String field, dynamic value) async {
    try {
      await _apiService.updateUserProfile({field: value});
      _logger.i('Updated user field: $field');
    } catch (e) {
      _logger.e('Error updating user field: $e');
      throw 'Failed to update user data: $e';
    }
  }
  
  // Update email verification status
  Future<void> updateEmailVerificationStatus(String uid, bool isVerified) async {
    // Skip if this feature is not supported by the Jarvis API
    _logger.w('Email verification update is not supported by Jarvis API');
  }
  
  // Get user document by uid
  Future<UserModel?> getUserById(String uid) async {
    try {
      final user = await _apiService.getCurrentUser();
      return user;
    } catch (e) {
      _logger.e('Error getting user by ID: $e');
      return null;
    }
  }
}