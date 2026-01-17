# Mobile Phone Setup Guide

## Step 1: Enable Developer Options on Android Phone

1. Open **Settings** on your phone
2. Go to **About phone** (or **About device**)
3. Find **Build number** (usually at the bottom)
4. Tap **Build number** 7 times until you see "You are now a developer!"
5. Go back to Settings → **System** → **Developer options**
6. Enable **USB debugging**
7. Enable **Install via USB** (if available)

## Step 2: Connect Your Phone

1. Connect your phone to your computer via USB cable
2. On your phone, you'll see a popup asking "Allow USB debugging?"
3. Check **"Always allow from this computer"** and tap **Allow**
4. Your phone should now appear in Flutter devices

## Step 3: Verify Connection

Run this command to check if your phone is detected:
```
flutter devices
```

## Step 4: Run the App

Once your phone is detected, run:
```
flutter run
```

Or specify your device:
```
flutter run -d <device-id>
```

## Troubleshooting

### Phone Not Detected?
- Make sure USB debugging is enabled
- Try a different USB cable (some cables are charge-only)
- Try a different USB port
- On Windows: Install phone drivers if prompted
- Run: `adb devices` to check if Android Debug Bridge sees your phone

### Android Licenses Issue?
If you see license errors, you may need to:
1. Open Android Studio
2. Go to **Tools** → **SDK Manager**
3. Install **Android SDK Command-line Tools**
4. Then run: `flutter doctor --android-licenses`

### Wireless Debugging (Alternative)
If USB doesn't work, you can use wireless debugging:
1. Connect phone and computer to same WiFi
2. Enable **Wireless debugging** in Developer options
3. Pair using the IP address shown
