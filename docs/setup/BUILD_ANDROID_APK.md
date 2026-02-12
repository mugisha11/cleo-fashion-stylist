# Build Android APK (Virtual Twin / Cleo)

## Prerequisites

1. **Flutter SDK** – installed and on `PATH`  
   - [Install Flutter](https://docs.flutter.dev/get-started/install)

2. **Java (JDK 17 recommended)** – required for Android builds  
   - **Option A – Android Studio**  
     Install [Android Studio](https://developer.android.com/studio).  
     It includes a JDK; `build_apk.bat` will use it automatically if installed in the default location.  
   - **Option B – JDK only (Windows)**  
     ```powershell
     winget install Microsoft.OpenJDK.17
     ```  
     Then set `JAVA_HOME` (e.g. to `C:\Program Files\Microsoft\jdk-17.x.x-hotspot`) and add `%JAVA_HOME%\bin` to `PATH`.  
   - **Option C – Manual**  
     Download [Eclipse Temurin JDK 17](https://adoptium.net/) and set `JAVA_HOME` and `PATH` as above.

3. **Android SDK** – required for Flutter Android builds  
   - Easiest: install Android Studio and open the project once so Flutter can install the Android SDK.  
   - Or install [command-line tools only](https://developer.android.com/studio#command-tools) and set `ANDROID_HOME`.

## Build the APK

### Using the script (Windows)

From the project root (e.g. `Cleo-fashion-main`):

```bat
build_apk.bat
```

The script will:

- Set `JAVA_HOME` if it finds Java (e.g. from Android Studio).
- Run `flutter clean`, `flutter pub get`, then `flutter build apk --release`.
- Print the path of the generated APK on success.

### Manual build

```bash
# Set JAVA_HOME if needed (Windows example)
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr

# Build
flutter clean
flutter pub get
flutter build apk --release
```

## Output

- **Path:** `build/app/outputs/flutter-apk/app-release.apk`  
- Install on a device: copy the APK to the phone and open it (allow “Install from unknown sources” if prompted).

## Troubleshooting

| Issue | What to do |
|-------|------------|
| `JAVA_HOME is not set` | Install JDK 17 or Android Studio and run `build_apk.bat` again, or set `JAVA_HOME` and `PATH` manually. |
| `Gradle build failed` | Run `flutter doctor -v` and fix any Android-related issues. Ensure Android SDK and licenses are installed. |
| `SDK location not found` | Set `ANDROID_HOME` (or `ANDROID_SDK_ROOT`) to your Android SDK path (e.g. under Android Studio). |
| Build very slow | First release build can take several minutes. Later builds are faster. |

## Release signing (optional)

For Play Store or production distribution, configure release signing in `android/app/build.gradle.kts` (keystore, `signingConfigs`, and use it in `buildTypes.release`). The current setup uses the debug keystore so the APK can be installed and tested without extra configuration.
