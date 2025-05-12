# Android Signing Configuration for CI/CD

This guide explains how to set up signing for Android app builds in your CI/CD pipeline.

## 1. Generate a signing key

If you don't already have a signing key, create one using the following command:

```bash
keytool -genkey -v -keystore ~/ai_chat_bot.keystore -alias ai_chat_bot -keyalg RSA -keysize 2048 -validity 10000
```

You will be prompted to create a password and provide some information.

## 2. Set up GitHub Secrets

Add the following secrets to your GitHub repository:

1. `KEYSTORE_BASE64`: The base64-encoded keystore file
   ```bash
   base64 -i ~/ai_chat_bot.keystore
   ```
   Copy the output and create a new GitHub secret with it.

2. `KEYSTORE_PASSWORD`: The password you created for the keystore

3. `KEY_ALIAS`: The alias used for the key (e.g., "ai_chat_bot")

4. `KEY_PASSWORD`: The password for the key (usually the same as the keystore password)

## 3. Update Android CI workflow

Update your Android build workflow to include the signing configuration:

```yaml
- name: Decode Keystore
  run: |
    echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/keystore.jks

- name: Create key.properties
  run: |
    echo "storeFile=keystore.jks" > android/key.properties
    echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" >> android/key.properties
    echo "keyAlias=${{ secrets.KEY_ALIAS }}" >> android/key.properties
    echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties

- name: Build Signed APK
  run: flutter build apk --release
```

## 4. Update build.gradle.kts

Update the Android app's build.gradle.kts file to include the signing configuration:

```kotlin
// Load keystore
def keystorePropertiesFile = rootProject.file("key.properties")
def keystoreProperties = new Properties()
def signingReady = false

// Initialize signing config if key.properties exists
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
    signingReady = true
}

android {
    // ... other config ...
    
    signingConfigs {
        if (signingReady) {
            release {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
    }
    
    buildTypes {
        release {
            // ... other config ...
            if (signingReady) {
                signingConfig signingConfigs.release
            }
        }
    }
}
```

## 5. Testing the signing process

To test the signing process locally:

1. Create a `key.properties` file in the android directory with your signing information
2. Run `flutter build apk --release`
3. Verify the APK is correctly signed:
   ```bash
   apksigner verify --verbose build/app/outputs/flutter-apk/app-release.apk
   ```

## 6. Additional security considerations

- Never commit the keystore or key.properties to version control
- Limit access to the GitHub secrets to only trusted team members
- Consider using different keys for debug and release builds
- Regularly rotate keys for production apps
