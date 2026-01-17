# Quick Setup Instructions

## Firebase Login & Configuration

### Option 1: Interactive Setup (Recommended)

1. **Login to Firebase** (run this in your terminal):
   ```powershell
   firebase login
   ```
   This will open a browser for authentication.

2. **Configure FlutterFire**:
   ```powershell
   $env:PATH += ";C:\Users\PETER\AppData\Local\Pub\Cache\bin"
   flutterfire configure --project=ai-styling-c45cf --platforms=android,ios,web
   ```

3. **Update main.dart** - The generated `firebase_options.dart` will be automatically imported.

### Option 2: Manual Configuration

If you prefer to configure manually:

1. Go to [Firebase Console](https://console.firebase.google.com/project/ai-styling-c45cf/settings/general)

2. **For Android**:
   - Go to Project Settings > Your apps > Add app > Android
   - Package name: `com.example.virtual_twin` (or your package name)
   - Download `google-services.json`
   - Place it in `android/app/google-services.json`

3. **For iOS**:
   - Go to Project Settings > Your apps > Add app > iOS
   - Bundle ID: `com.example.virtualTwin` (or your bundle ID)
   - Download `GoogleService-Info.plist`
   - Place it in `ios/Runner/GoogleService-Info.plist`

4. **Create firebase_options.dart**:
   - Use the template in `lib/firebase_options.dart.template`
   - Get API keys from Firebase Console > Project Settings
   - Replace placeholder values

## Enable Firebase Services

1. **Authentication**:
   - Firebase Console > Authentication > Sign-in method
   - Enable "Email/Password"

2. **Firestore**:
   - Firebase Console > Firestore Database
   - Create database (production mode)
   - Location: Choose closest to your users

3. **Storage**:
   - Firebase Console > Storage
   - Get started (production mode)

4. **Cloud Functions**:
   - Firebase Console > Functions
   - Get started

## Deploy Rules & Functions

```powershell
# Deploy security rules
firebase deploy --only firestore:rules,storage:rules

# Deploy Cloud Functions
cd functions
npm install
cd ..
firebase deploy --only functions
```

## Test the App

```powershell
flutter pub get
flutter run
```

## Troubleshooting

- **"Firebase not initialized"**: Make sure `firebase_options.dart` exists and is imported in `main.dart`
- **"Permission denied"**: Check Firestore and Storage security rules
- **"Function not found"**: Deploy Cloud Functions first

