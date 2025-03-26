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

## Google Authentication Troubleshooting

### Why Authentication Flow Differs Between Machines

When logging in with Google, some machines handle the authentication flow automatically (browser redirects back to the app) while others require manual code entry. This difference is caused by:

1. **Port Availability**:
   - The app tries to open a local server on port 8080 (or 3000 as fallback)
   - If these ports are already in use or blocked by firewall, manual code entry is required

2. **Redirect URI Configuration**:
   - Google OAuth requires exact URI matching
   - Each machine must use a URI registered in Google Cloud Console
   - Different machines may use different ports if port 8080 is unavailable

3. **Firewall Settings**:
   - Windows Firewall may block the local server from receiving the OAuth redirect
   - Different security settings across machines can cause this variation

### How to Fix Authentication Issues

1. **Free Up Required Ports**:
   - Check if any applications are using ports 8080 and 3000
   - Use Command Prompt: `netstat -ano | findstr 8080`
   - Close the applications using these ports

2. **Update Redirect URIs in Google Cloud Console**:
   - Go to Google Cloud Console > APIs & Services > Credentials
   - Edit your OAuth 2.0 Client ID
   - Add ALL these redirect URIs:

```text
http://localhost:8080
http://localhost:3000
http://localhost:4200
http://localhost:5000
http://localhost:8000
```

1. **Check Firewall Settings**:
   - Try temporarily disabling the firewall to test
   - Add the application to firewall exceptions
   - Run the application as administrator

## Firestore Security Rules

### "Permission Denied" Error with Chat Messages

This error occurs when Firestore security rules aren't properly configured to allow users to access their chat sessions and messages.

#### Understanding Chat Data Structure

- Chat sessions are stored with user IDs to associate them with specific users
- Messages are stored in subcollections under each chat session
- Security rules need to be configured to ensure only the owner of a chat session can access it

#### Recommended Security Rules

To fix permission issues with chat messages, set up the following security rules in your Firebase project:

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to access their own chat sessions
    match /chatSessions/{sessionId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
      
      // Messages subcollection - allow if parent session is accessible
      match /messages/{messageId} {
        allow read, write: if request.auth != null;
      }
    }
    
    // Allow users to access their own user documents
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

#### How These Rules Protect Your Data

- **Chat Sessions**: Only the user who owns a chat session (matching userId) can read or write to it
- **Messages**: Any authenticated user can read/write messages, but they can only access messages through sessions they own
- **User Data**: Each user can only read and write their own user document

#### How to Configure Rules

1. Go to [Firebase Console](https://console.firebase.google.com/) and select your project
2. Navigate to **Firestore Database** > **Rules** tab
3. Replace the existing rules with the recommended rules above
4. Click **Publish**

Note: Rules can take a few minutes to propagate after publishing.

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

## API Error Handling

### Handling 503 Service Unavailable Errors

The application is designed to handle temporary service outages from the Gemini API. Here's how it works:

1. **Retry Mechanism**: When a 503 error occurs, the application will automatically retry the request up to 2 times with exponential backoff.

2. **Fallback Mode**: After repeated failures, the app switches to fallback mode, providing offline responses.

3. **Auto Recovery**: The application periodically checks if the API service has been restored.

4. **Manual Reset**: You can manually reset the API service from the settings page if you know the service is back online.

### Common API Errors

- **503 Service Unavailable**: The Gemini API service is temporarily down or undergoing maintenance. This is a server-side issue that will resolve on its own.

- **429 Too Many Requests**: You've exceeded the rate limits for the API. Wait a few minutes before trying again.

- **401/403 Authentication Errors**: Your API key may be invalid or expired. Check your `.env` file configuration.

### Checking API Status

If you're experiencing repeated 503 errors, you can check the Google AI Platform status at:
[https://status.cloud.google.com/](https://status.cloud.google.com/)

For more information, visit the Firebase Security Rules documentation at: [https://firebase.google.com/docs/firestore/security/get-started](https://firebase.google.com/docs/firestore/security/get-started)
