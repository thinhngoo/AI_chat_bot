# Firebase Data Connect Setup

Firebase Data Connect was initialized during `firebase init` but requires some additional setup to work properly:

1. Make sure you're on the Firebase Blaze plan (pay-as-you-go)

2. Install the required dependency:

```bash
flutter pub add firebase_data_connect
```

3. Configure Data Connect in the Firebase console

## Temporary Workaround

If you're not ready to use Data Connect yet, you can:

1. Add the following to your `.gitignore`:

```gitignore
dataconnect-generated/
```

2. Exclude `dataconnect-generated` files from your build by adding to `analysis_options.yaml`:

```yaml
analyzer:
  exclude:
    - dataconnect-generated/**
```

3. Remove the import statements for Firebase Data Connect until you're ready to use it

The errors coming from `default_connector/default.dart` can be ignored until you configure Data Connect properly.
