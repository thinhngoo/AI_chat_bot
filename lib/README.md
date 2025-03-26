# Jarvis AI Chat Bot

## API Configuration

This application uses the following Jarvis API endpoints:

- **Authentication API**: https://auth-api.dev.jarvis.cx
  - User registration, login, and session management

- **Jarvis API**: https://api.dev.jarvis.cx
  - Chat conversations, messages, and model selection

- **Knowledge Base API**: https://knowledge-api.dev.jarvis.cx
  - Document storage and retrieval for AI context

## Setup Instructions

1. Clone the repository
2. Create a `.env` file in the project root based on `.env.example`
3. Add your API keys and configuration
4. Run `flutter pub get` to install dependencies
5. Launch the application with `flutter run`

## Features

- Multi-platform support (Android, iOS, Windows)
- Multiple AI model options (Gemini, Claude, GPT)
- User authentication
- Chat history management

## Setup

1. Clone the repository
2. Install dependencies with `flutter pub get`
3. Create a `.env` file in the project root (copy from .env.example)

```bash
# Example .env file contents
JARVIS_API_URL=https://api.example.com/v1
JARVIS_API_KEY=your_jarvis_api_key_here
GOOGLE_DESKTOP_CLIENT_ID=your_desktop_client_id
GOOGLE_CLIENT_SECRET=your_client_secret
```

## Authentication

Authentication is handled through the Jarvis API service.

- Email/password authentication
- Google Sign-In (requires configuration)

## API Configuration

The application uses the Jarvis API for all backend operations:

- Chat history management
- User authentication
- AI model configuration

## Development Guidelines

- Follow Flutter best practices
- Use the provided service interfaces
- Add tests for new features

## Overview
This AI Chat Bot application now integrates with the Jarvis API service for authentication, chat messaging, and user management, replacing the previous Firebase backend.

## Key Features
- Email/password authentication through Jarvis API
- Chat history management
- User profile and settings management
- Multiple AI model selection

## Configuration
1. Create a `.env` file based on `.env.example`
2. Add your Jarvis API credentials:
   ```
   JARVIS_API_URL=https://api.example.com/v1
   JARVIS_API_KEY=your_jarvis_api_key_here
   ```

## Architecture
The application follows a clean architecture approach:
- Core services for API communication and authentication
- Feature-based modules for UI components
- Models for data representation

## Services
- `JarvisApiService`: Handles all API communication with the Jarvis backend
- `JarvisAuthProvider`: Implements authentication operations using Jarvis API
- `JarvisChatService`: Manages chat session operations

## Migration from Firebase
The application has been fully migrated from Firebase to the Jarvis API. The code maintains compatibility with existing components through adapter classes that abstract the backend implementation details.

## Authentication Setup

### Google Authentication Issues

#### "redirect_uri_mismatch" Error

This error occurs when the application is using a redirect URI that isn't registered in the Google Cloud Console.

##### Solution

1. Go to [Google Cloud Console > APIs & Services > Credentials](https://console.cloud.google.com/apis/credentials)
2. Find and edit your OAuth 2.0 Client ID
3. Under "Authorized redirect URIs", add:

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
2. For Windows users, ensure you're using a Desktop client, not a Web client

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

### Password Requirements

When users reset their password via email link, the following requirements are enforced:

- At least 8 characters long
- Contains at least one uppercase letter (A-Z)
- Contains at least one lowercase letter (a-z)
- Contains at least one number (0-9)
- Contains at least one special character (!@#$%^&*(),.?":{}|<>)

These requirements help ensure account security and are applied consistently throughout the application.

### Troubleshooting Security Rules

If you're still having issues after setting up the rules:

1. Make sure the user is properly authenticated before accessing Firestore
2. Check that you're using the correct userId when querying documents
3. Verify that your chat session documents have a `userId` field that matches the authenticated user's ID

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
2. **Auth Events**: Record login/logout events in a separate collection for audit purposes
3. **Chat Sessions**: Store each chat session with a reference to the user ID

## AI Model Selection

The application supports multiple AI models from different providers:

### Gemini Models (Google)

- **Gemini 2.0 Flash**: Latest fast model with improved capabilities (default)
- **Gemini 1.5 Flash**: Fast, good for most interactions
- **Gemini 1.5 Pro**: More powerful, better for complex tasks
- **Gemini 1.0 Pro**: Stable, well-tested version

### ChatGPT Models (OpenAI)

- **ChatGPT 3.5 Turbo**: Fast and efficient model, good for most tasks
- **ChatGPT 4o**: Latest and most powerful ChatGPT model with improved capabilities

### Grok Models (xAI)

- **Grok 1**: Baseline model with real-time information access
- **Grok 2**: Advanced model with improved reasoning and problem-solving

### How to Configure API Keys

To use different AI models, you need to provide the appropriate API keys:

#### Gemini API Key

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key
3. Add to your `.env` file as `GEMINI_API_KEY=your_key_here`

#### OpenAI API Key

1. Visit [OpenAI Platform](https://platform.openai.com/api-keys)
2. Create a new API key
3. Add to your `.env` file as `OPENAI_API_KEY=your_key_here`

#### Grok API Key

1. Visit [xAI Developer Portal](https://developer.xai.com/)
2. Create a new API key
3. Add to your `.env` file as `GROK_API_KEY=your_key_here`

### Usage Considerations

Different models have different pricing structures:

- Gemini offers free tiers with limits
- OpenAI charges per token used (both input and output)
- Grok may require a subscription

Choose the appropriate model based on your needs and budget constraints.

## API Error Handling

The application is designed to handle temporary service outages from any of the AI API providers. Here's how it works:

1. **Retry Mechanism**: When a 503 error occurs, the application will automatically retry the request up to 2 times with exponential backoff.

2. **Fallback Mode**: After repeated failures, the app switches to fallback mode, providing offline responses.

3. **Auto Recovery**: The application periodically checks if the API service has been restored.

4. **Manual Reset**: You can manually reset the API service from the settings page if you know the service is back online.

5. **AI Model Selection**: You can choose between different AI models from multiple providers:
   - Google Gemini models
   - OpenAI ChatGPT models
   - xAI Grok models

### Common API Errors

#### Gemini API Errors

- **503 Service Unavailable**: The Gemini API service is temporarily down or undergoing maintenance. This is a server-side issue that will resolve on its own. Wait a few minutes and try again.

- **429 Too Many Requests**: You've exceeded the rate limits for the API. This happens when too many requests are made in a short period. Wait a few minutes before trying again.

- **401/403 Authentication Errors**: Your API key may be invalid or expired. Check your `.env` file configuration and ensure the key is correctly formatted. The 401 error indicates unauthorized access, while 403 indicates the key doesn't have permission for the requested operation.

- **400 Bad Request**: The request format is incorrect. This may happen if the prompt is malformed or too long. Try simplifying your prompts.

- **404 Not Found**: The requested endpoint doesn't exist. This could happen if you're using an incorrect model name.

#### OpenAI API Errors

- **429 insufficient_quota**: You've exceeded your current quota for OpenAI API. This typically means:
  - You're using a free tier account which has run out of credits
  - Your billing details need to be updated
  - You've hit your defined spending limits
  
  To fix this, visit [OpenAI Billing Dashboard](https://platform.openai.com/account/billing) to check your usage and update payment information if needed.

- **429 rate_limit_exceeded**: You're making too many requests to the OpenAI API in a short period. Implement exponential backoff strategies in your code or reduce the frequency of requests.

- **401 invalid_api_key**: Your OpenAI API key is invalid or has been rotated. Check your `.env` file and ensure the OPENAI_API_KEY is correctly set.

- **500/503 Server Errors**: OpenAI's servers are experiencing issues. These are temporary and should resolve on their own.

### Checking API Status

If you're experiencing repeated 503 errors, you can check the Google AI Platform status at:
[https://status.cloud.google.com/](https://status.cloud.google.com/)

For OpenAI service status, check:
[https://status.openai.com/](https://status.openai.com/)

For more information, visit the Firebase Security Rules documentation at: [https://firebase.google.com/docs/firestore/security/get-started](https://firebase.google.com/docs/firestore/security/get-started)

## Jarvis API Configuration Guide

To configure the Jarvis API for your project:

1. Create a `.env` file in the project root directory (copy from `.env.example`)
2. Set the following variables:
   ```
   JARVIS_API_URL=https://api.jarvis.ai/v1
   JARVIS_API_KEY=your_api_key_here
   ```
3. Replace the values with your actual API credentials
4. Restart the application to apply changes

### Obtaining API Credentials

1. Sign up for a Jarvis API account at [https://jarvis.ai/signup](https://jarvis.ai/signup)
2. Navigate to API Settings in your account dashboard
3. Create a new API key
4. Copy the API key to your `.env` file

### Testing API Connectivity

To test if your API configuration is working:

1. Run the application in debug mode
2. Check the console logs for successful API initialization 
3. If you see "Initialized Jarvis API with base URL: ..." the configuration is correct
4. If you encounter connection errors, verify your API URL and credentials

## Jarvis API Integration

This application integrates with the Jarvis API documented at:
https://www.apidog.com/apidoc/shared/f30d2953-f010-4ef7-a360-69f9eaf457f7

### API Configuration

To configure the Jarvis API integration:

1. **Create Environment File**:
   - Copy `.env.example` to `.env` in the project root
   - Update the values with your specific API credentials

2. **Required Environment Variables**:
   ```
   JARVIS_API_URL=https://your-api-endpoint.example.com/api/v1
   JARVIS_API_KEY=your_api_key_here
   ```

3. **API Authentication Methods**:
   - The app uses JWT Bearer token authentication for most requests
   - API Key authentication is used as a fallback or for initial requests
   - Tokens are automatically managed and stored securely

### API Endpoints Used

The application interacts with these primary Jarvis API endpoints:

#### Authentication
- `POST /auth/login`: User login
- `POST /auth/register`: User registration
- `POST /auth/logout`: User logout

#### Conversations
- `GET /conversations`: List all conversations
- `POST /conversations`: Create a new conversation
- `DELETE /conversations/{id}`: Delete a conversation
- `GET /conversations/{id}/messages`: Get messages for a conversation
- `POST /conversations/{id}/messages`: Send a message in a conversation

#### User Profile
- `GET /user/profile`: Get current user profile
- `PUT /user/profile`: Update user profile
- `POST /user/change-password`: Change user password

#### Models
- `GET /models`: Get available AI models

### Troubleshooting API Issues

If you experience issues with the Jarvis API integration:

1. **Check Connection**:
   - Use the "Test API Connection" button in Settings
   - Verify the API URL in your `.env` file

2. **Authentication Errors**:
   - Ensure your API key is correct
   - Try logging out and logging back in to refresh tokens

3. **Common Error Codes**:
   - `401 Unauthorized`: Invalid or expired token
   - `403 Forbidden`: Missing permissions or invalid API key
   - `429 Too Many Requests`: Rate limiting applied

4. **Reset API Connection**:
   - If persistent issues occur, use the "Reset API Connection" option in Settings

## Common API Errors and Solutions

When integrating with the Jarvis API, you might encounter these common errors:

- **API Connection Errors**: When your app cannot communicate with the Jarvis API servers

  Possible reasons:
  - You haven't configured the API URL correctly
  - You're using a free tier account which has run out of credits
  - You've hit your defined spending limits
  
  To fix this, visit [OpenAI Billing Dashboard](https://platform.openai.com/account/billing) to check your usage and update payment information if needed.

- **429 rate_limit_exceeded**: You're making too many requests to the OpenAI API in a short period. Implement exponential backoff strategies in your code or reduce the frequency of requests.

- **401 invalid_api_key**: Your OpenAI API key is invalid or has been rotated. Check your `.env` file and ensure the OPENAI_API_KEY is correctly set.

- **500/503 Server Errors**: OpenAI's servers are experiencing issues. These are temporary and should resolve on their own.

### Checking API Status

If you're experiencing repeated 503 errors, you can check the Google AI Platform status at:
[https://status.cloud.google.com/](https://status.cloud.google.com/)

For OpenAI service status, check:
[https://status.openai.com/](https://status.openai.com/)

For more information, visit the Firebase Security Rules documentation at: [https://firebase.google.com/docs/firestore/security/get-started](https://firebase.google.com/docs/firestore/security/get-started)

# Jarvis API Integration

This application integrates with the Jarvis API for authentication and chat functionality.

## API Endpoints

### Authentication
- **Sign Up**: POST `/api/v1/auth/password/sign-up`
- **Sign In**: POST `/api/v1/auth/password/sign-in`
- **Refresh Token**: POST `/api/v1/auth/refresh-token`
- **Logout**: DELETE `/api/v1/auth/logout`

### Required Headers
For authentication endpoints, these headers are required:
```
