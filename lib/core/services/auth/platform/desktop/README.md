# Google Authentication for Windows Desktop

## Configuration Guide

To properly configure Google Sign-In for Windows desktop with Firebase authentication, follow these steps:

### Step 1: Create OAuth credentials in Google Cloud Console

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
1. Select your project or create a new one
1. Navigate to "APIs & Services" > "Credentials"
1. Click "Create Credentials" > "OAuth client ID"
1. Select "Desktop app" as the application type
1. Name your client (e.g., "Windows Desktop Client")
1. Click "Create"
1. Note down the Client ID and Client Secret

### Step 2: Configure Firebase Console

1. Go to the [Firebase Console](https://console.firebase.google.com/)
1. Select your project
1. Navigate to "Authentication" > "Sign-in method"
1. Enable Google sign-in
1. **IMPORTANT**: Add your Desktop Client ID in the "Web SDK configuration" section
   - Click the pencil icon next to the first web client item
   - Add your Desktop Client ID from Step 1 in the "Web Client ID" field
   - Save changes

### Step 3: Configure your application

1. Create or update your `.env` file with:

```env
GOOGLE_DESKTOP_CLIENT_ID=your_desktop_client_id_from_step_1
GOOGLE_CLIENT_SECRET=your_client_secret_from_step_1
```

1. Make sure Firebase is properly initialized for Windows

## Troubleshooting

If you encounter the "invalid-credential" error:

1. Verify that the exact same Client ID is configured in both:
   - Your `.env` file
   - Firebase Console > Authentication > Sign-in method > Google > Web SDK configuration
1. Check the application logs for detailed error information
1. Restart the application after making configuration changes
1. Ensure you're not mixing different types of Client IDs
