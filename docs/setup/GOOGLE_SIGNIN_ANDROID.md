# Fix Google Sign-In on Android (DEVELOPER_ERROR / API 10)

The error **"PlatformException(sign_in_failed, com.google.android.gms.common.api.j: 10:, null, null)"** means Google doesn't recognize your app's signing certificate. Add your app's **SHA-1 fingerprint** to Firebase.

The app package name has been aligned with your Firebase Android app: **`com.aistyling.c45cf`**.

## Your app's SHA-1 (current build)

Your release APK is signed with the **debug** keystore. Use this SHA-1 in Firebase:

```
EB:05:BD:EC:45:63:7B:7B:7D:F2:22:0A:55:E8:46:7D:62:0F:D2:38
```

- **Package name:** `com.aistyling.c45cf` (matches Firebase)
- **Firebase project:** ai-styling-c45cf (AI styling)

## Steps (about 2 minutes)

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com/
   - Select project **ai-styling-c45cf** (or your Cleo project).

2. **Add SHA-1 for the Android app**
   - Click the **gear** next to "Project Overview" → **Project settings**.
   - Under **"Your apps"**, find your **Android** app (package name `com.aistyling.c45cf`).
   - In that Android app card, click **"Add fingerprint"**.
   - Paste this SHA-1 and save:
     ```
     EB:05:BD:EC:45:63:7B:7B:7D:F2:22:0A:55:E8:46:7D:62:0F:D2:38
     ```

3. **Wait 1–2 minutes**  
   Google can take a short time to apply the change.

4. **Try again on the phone**  
   Open the app and tap **"Continue with Google"** again.

## If you use a different keystore later (release key)

When you sign the APK with a **release** keystore (e.g. for Play Store), get that keystore’s SHA-1 and add it to the same Android app in Firebase:

```bash
cd android
.\gradlew.bat signingReport
```

Use the **SHA1** value for the `release` variant and add it as another fingerprint in Project settings.

## Summary

| Item        | Value                                                                 |
|------------|-----------------------------------------------------------------------|
| SHA-1      | `EB:05:BD:EC:45:63:7B:7B:7D:F2:22:0A:55:E8:46:7D:62:0F:D2:38`       |
| Package    | `com.aistyling.c45cf`                                                |
| Where      | Firebase Console → Project settings → Your apps → Android app → Add fingerprint |

After adding the fingerprint, Google Sign-In on the phone should work.
