# AI Chat Bot Guide

## Authentication Setup

### Google Authentication Issues

#### "redirect_uri_mismatch" Error

This error occurs when the application is using a redirect URI that isn't registered in the Google Cloud Console.

##### Solution

1. Go to [Google Cloud Console > APIs & Services > Credentials](https://console.cloud.google.com/apis/credentials)
1. Find and edit your OAuth 2.0 Client ID
1. Under "Authorized redirect URIs", add:

```text
http://localhost:8080
http://localhost:3000
http://localhost:8090
http://localhost:5000
http://localhost:8000
```

1. Click Save

The application tries these ports in order if the previous one is unavailable. To ensure it works in all cases, add all of them to your Google Cloud Console settings.

#### "invalid_client" Error

This error typically means that the OAuth client ID or client secret is incorrect.

1. Double-check your `.env` file to ensure you have these variables set:

```text
GOOGLE_DESKTOP_CLIENT_ID=your_desktop_client_id
GOOGLE_CLIENT_SECRET=your_client_secret
```

1. Make sure the client ID matches the one in Google Cloud Console
1. For Windows users, ensure you're using a Desktop client, not a Web client

### Firebase Authentication Setup

For Firebase Authentication to work with Google Sign-in on Windows:

1. Go to Firebase Console > Authentication > Sign-in method > Google
1. Enable Google Sign-in
1. In the "Web SDK configuration" section, add the same OAuth Client ID that you're using for Windows authentication
1. Ensure this OAuth Client ID is also registered in the Google Cloud Console with all the redirect URIs listed above

## Security Considerations

### Password Requirements

When users reset their password via email link, the following requirements are enforced:

- At least 8 characters long
- Contains at least one uppercase letter (A-Z)
- Contains at least one lowercase letter (a-z)
- Contains at least one number (0-9)
- Contains at least one special character (!@#$%^&*(),.?":{}|<>)

These requirements help ensure account security and are applied consistently throughout the application.

### Firebase Firestore Security Rules

If you're seeing **"permission-denied"** errors when using the app, you need to configure your Firestore security rules correctly.

#### How to Configure Security Rules

1. Go to [Firebase Console](https://console.firebase.google.com/)
1. Select your project
1. Click on "Firestore Database" in the left sidebar
1. Click on the "Rules" tab
1. Replace the existing rules with the following:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User data - only accessible by the user themselves
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Chat sessions - users can only access their own chats
    match /chatSessions/{sessionId} {
      allow read, write: if request.auth != null && 
                           request.auth.uid == resource.data.userId;
      
      // Messages in chat sessions
      match /messages/{messageId} {
        allow read, write: if request.auth != null && 
                           get(/databases/$(database)/documents/chatSessions/$(sessionId)).data.userId == request.auth.uid;
      }
    }
    
    // Auth events - only allow creation, not reading or modification
    match /authEvents/{eventId} {
      allow create: if request.auth != null && 
                      request.resource.data.userId == request.auth.uid;
      allow read, update, delete: if false;
    }
  }
}
```

1. Click "Publish"

### Troubleshooting Security Rules

If you're still having issues after setting up the rules:

1. Make sure the user is properly authenticated before accessing Firestore
1. Check that you're using the correct userId when querying documents
1. Verify that your chat session documents have a `userId` field that matches the authenticated user's ID

### Testing Security Rules

You can run the diagnostic function to check your permissions:

```dart
final firestoreService = FirestoreDataService();
final report = await firestoreService.runDiagnosticCheck();
print(report);
```

## Best Practices for User Data Storage

### Data Structure

1. **User Collection**: Store user profiles in a `users` collection with documents using the Firebase Authentication UID as the document ID
1. **Auth Events**: Record login/logout events in a separate collection for audit purposes
1. **Chat Sessions**: Store each chat session with a reference to the user ID
