# AI Chat Bot

A Flutter-based multi-platform chat bot application with Firebase backend integration.

## Features

- Cross-platform support: Web, Android, iOS, Windows
- Firebase authentication with multiple login methods
- Gemini AI integration for intelligent responses
- Offline capabilities on Windows with local authentication
- Cloud data synchronization
- Google authentication on desktop platforms

## Getting Started

### Prerequisites

- Flutter SDK 3.29.1 or higher
- Firebase project
- Google Cloud project with OAuth credentials
- Gemini API key

### Environment Setup

1. Copy `.env.example` to `.env` and fill in your API keys:

```bash
GEMINI_API_KEY=your_gemini_api_key_here
GOOGLE_DESKTOP_CLIENT_ID=your_desktop_client_id_here
GOOGLE_CLIENT_SECRET=your_client_secret_here
```

2. Run `flutter pub get` to install dependencies

### Running the Application

```bash
# For Windows
flutter run -d windows

# For Web
flutter run -d chrome

# For Android
flutter run -d android
```

## CI/CD Pipeline

This project uses GitHub Actions for Continuous Integration and Continuous Deployment.

### Workflow Structure

- **Flutter Build & Test**: Runs on every push and pull request
  - Code formatting check
  - Static analysis
  - Unit tests
  - Web build

- **Firebase Functions**: Tests and builds backend functions
  - Linting
  - TypeScript compilation

- **Windows Build**: Creates a Windows executable on pushes to main
  - Uploads build artifacts for release

- **Deployment**:
  - Preview deployments for pull requests
  - Production deployment when merged to main

### Setting Up the Pipeline

1. Configure the following secrets in your GitHub repository:
   - `FIREBASE_SERVICE_ACCOUNT_VINH_AFF13`: Firebase service account JSON

2. Enable GitHub Actions in your repository settings

3. Each push to `main` will automatically:
   - Run tests
   - Build the application
   - Deploy to Firebase Hosting

## Project Directory Structure

- `lib/`: Flutter application code
  - `core/`: Core functionality and models
  - `features/`: Feature-specific code
  - `widgets/`: Reusable UI components

- `functions/`: Firebase Cloud Functions
  - TypeScript backend code

- `windows/`: Windows-specific platform code

## Windows-Specific Features

On Windows, the application provides fallback authentication when Firebase is not available. See `setup_oauth.bat` for configuring Google authentication on Windows.

## Contributing

Please follow the pull request template when contributing. Make sure all tests pass before submitting a PR.
