# Google OAuth Setup Guide

## Fixing "redirect_uri_mismatch" Error

The "redirect_uri_mismatch" error occurs when the application tries to use a redirect URI that isn't registered in your Google Cloud Console project.

### Solution:

1. **Access Google Cloud Console**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Select your project
   - Navigate to **APIs & Services** > **Credentials**

2. **Update your OAuth Client**:
   - Find and edit your OAuth 2.0 Client ID
   - Look for the section labeled **Authorized redirect URIs**
   - Add **ALL** of the following URIs:
     ```
     http://localhost:8080
     http://localhost:3000
     http://localhost:8090
     http://localhost:5000
     http://localhost:8000
     ```
   - Click **Save**

3. **Verify your Client ID**:
   - Make sure your `.env` file has the correct values:
     ```
     GOOGLE_DESKTOP_CLIENT_ID=784300763720-ii2er5tptdqdg3nn8984rakhh1auiiip.apps.googleusercontent.com
     GOOGLE_CLIENT_SECRET=your_client_secret_here
     ```

4. **Restart the application** after making these changes

## Why multiple redirect URIs?

The application tries different ports in order, starting with 8080. If a port is already in use by another application, it falls back to the next port. By registering all potential URIs, you ensure the authentication will work regardless of which port is available.

## Firebase Configuration

Additionally, ensure the same Client ID is also added to:
1. Firebase Console > Authentication > Sign-in method > Google
2. In the "Web SDK configuration" section

## Common Errors

### Error 400: redirect_uri_mismatch
This means the URI currently being used by the app doesn't match any registered URIs. Follow the steps above to fix it.

### Error: invalid_client
This typically means the client ID or secret is incorrect. Double-check your `.env` file.
