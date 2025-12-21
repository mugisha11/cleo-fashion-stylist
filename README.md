# Virtual Twin – AI Fashion Try-On App

A production-ready, cross-platform Flutter application that creates realistic virtual avatars and enables AI-powered virtual try-on experiences for fashion items.

## 🎯 Features

### Core Features (MVP)

- **Authentication & Onboarding**
  - Email/password authentication via Firebase Auth
  - 6-question fashion onboarding flow
  - Body measurements input (height, gender, body type)
  - Persistent user data in Firestore

- **Virtual Twin / Avatar**
  - Selfie-based 3D avatar generation (Ready Player Me API integration)
  - 2D fallback avatar if 3D generation fails
  - 3D avatar rendering with model_viewer
  - Offline avatar caching
  - Graceful error handling (never hard-fails)

- **Wardrobe Management**
  - Upload clothing items with images
  - Store metadata (category, color tags, brand, notes)
  - View wardrobe in grid layout
  - Delete items
  - Offline wardrobe viewing with Hive caching

- **Virtual Try-On**
  - Select avatar + clothing items
  - Generate composited try-on preview
  - Cache previews locally
  - Save outfits to collection

- **AI Outfit Recommendations**
  - Cloud Function-powered recommendations
  - Based on onboarding data + wardrobe
  - Confidence scores and reasoning
  - Save recommended outfits

### UX/UI Highlights

- **Premium Design**
  - Light mode only, clean and minimalist
  - Copilot-inspired color palette (electric blue, subtle violet)
  - Modern sans-serif typography (Inter)
  - Rounded corners, card-based layouts
  - Large touch targets for accessibility

- **Animations & Transitions**
  - Smooth page transitions (fade + slide)
  - Micro-interactions (button press, avatar rotation)
  - Skeleton/shimmer loading states
  - AI "thinking" animations
  - Never blank screens

- **Error Resilience**
  - Graceful fallbacks for all API calls
  - Offline-first architecture
  - Skeleton screens during loads
  - User-friendly error messages

## 🏗️ Architecture

```
lib/
 ├── main.dart
 ├── src/
 │   ├── app.dart
 │   ├── routes.dart
 │   ├── core/
 │   │   ├── models/          # Data models
 │   │   ├── services/         # Business logic
 │   │   ├── theme/            # App theme
 │   │   └── widgets/          # Reusable widgets
 │   ├── providers/            # Riverpod providers
 │   └── features/
 │       ├── auth/             # Authentication
 │       ├── onboarding/       # Onboarding flow
 │       ├── avatar/           # Avatar creation
 │       ├── wardrobe/         # Wardrobe management
 │       ├── tryon/            # Virtual try-on
 │       ├── recommendations/  # AI recommendations
 │       └── home/             # Home screen
 └── functions/                # Firebase Cloud Functions
```

## 🚀 Setup Instructions

### Prerequisites

- Flutter SDK (stable channel, Dart 3.0+)
- Firebase account
- Node.js 18+ (for Cloud Functions)
- iOS: Xcode 14+
- Android: Android Studio with latest SDK

### 1. Clone and Install Dependencies

```bash
# Install Flutter dependencies
flutter pub get

# Install Cloud Functions dependencies
cd functions
npm install
cd ..
```

### 2. Firebase Setup

#### Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project: "Virtual Twin"
3. Enable the following services:
   - Authentication (Email/Password)
   - Firestore Database
   - Storage
   - Cloud Functions

#### Configure Firebase for Flutter

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Initialize Firebase in your project:
   ```bash
   flutterfire configure
   ```
   Select your Firebase project and platforms (iOS, Android, Web).

4. This will generate:
   - `lib/firebase_options.dart` (auto-generated)
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

#### Firestore Security Rules

Set up Firestore security rules in Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Wardrobe collection
    match /wardrobe/{itemId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.userId;
    }
    
    // Outfits collection
    match /outfits/{outfitId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.userId;
    }
  }
}
```

#### Storage Security Rules

Set up Storage security rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /avatars/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /wardrobe/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 3. Update Firebase Initialization

Update `lib/main.dart` to use the generated Firebase options:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ... rest of initialization
}
```

### 4. Deploy Cloud Functions

```bash
cd functions
firebase deploy --only functions
```

This deploys the `generateOutfitRecommendations` Cloud Function.

### 5. iOS Setup

1. Open `ios/Runner.xcworkspace` in Xcode
2. Ensure `GoogleService-Info.plist` is added to the Runner target
3. Update iOS deployment target to 12.0+ in `ios/Podfile`:
   ```ruby
   platform :ios, '12.0'
   ```
4. Run `pod install` in `ios/` directory

### 6. Android Setup

1. Ensure `google-services.json` is in `android/app/`
2. Update `android/build.gradle`:
   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.4.0'
   }
   ```
3. Update `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   minSdkVersion 21
   ```

### 7. Run the App

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android
```

## 📱 Usage

1. **Sign Up**: Create an account with email/password
2. **Onboarding**: Complete 6 fashion questions + body inputs
3. **Create Avatar**: Upload a selfie to generate your virtual twin
4. **Add Wardrobe**: Upload clothing items with metadata
5. **Try On**: Select items and generate virtual try-on previews
6. **Get Recommendations**: View AI-powered outfit suggestions

## 🔧 Configuration

### Ready Player Me API (Optional)

To use actual Ready Player Me API, update `lib/src/core/services/avatar_service.dart`:

```dart
Future<String?> _callReadyPlayerMeApi(File selfieFile) async {
  // Replace with actual API integration
  final request = http.MultipartRequest('POST', Uri.parse(_readyPlayerMeApiUrl));
  request.files.add(await http.MultipartFile.fromPath('photo', selfieFile.path));
  // ... implement actual API call
}
```

### AI Recommendations

The Cloud Function uses a mock AI engine. To integrate real AI:

1. Update `functions/index.js`
2. Replace `generateMockRecommendations` with actual AI service call
3. Options: OpenAI API, custom ML model, or third-party fashion AI

## 🧪 Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## 📦 Build for Production

### iOS

```bash
flutter build ios --release
```

### Android

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

## 🛠️ Tech Stack

- **Framework**: Flutter 3.0+ (Dart 3.0+)
- **State Management**: Riverpod 2.4+
- **Backend**: Firebase (Auth, Firestore, Storage, Cloud Functions)
- **Caching**: Hive 2.2+
- **3D Rendering**: model_viewer_plus 1.5+
- **Animations**: flutter_animate 4.3+
- **UI**: Material Design 3, Google Fonts (Inter)

## 📝 Notes

- **Offline Support**: Wardrobe and avatars are cached locally for offline viewing
- **Error Handling**: All API calls have fallbacks; the app never hard-fails
- **Performance**: Images are cached with `cached_network_image`
- **Accessibility**: Large touch targets, semantic labels

## 🐛 Troubleshooting

### Firebase not initialized
- Ensure `firebase_options.dart` exists
- Run `flutterfire configure` again

### Cloud Functions not working
- Check Firebase project is linked: `firebase projects:list`
- Verify function is deployed: `firebase functions:list`

### Avatar generation fails
- App will automatically fallback to 2D avatar
- Check Firebase Storage rules allow uploads

## 📄 License

This project is proprietary. All rights reserved.

## 👥 Support

For issues or questions, please contact the development team.

---

**Built with ❤️ using Flutter & Firebase**

