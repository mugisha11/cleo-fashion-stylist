# 🔧 FIX: "Exception: Not Found" Error

## ✅ What's Working

1. **Endpoint is registered**: `/tryon` ✅
2. **Router is loaded**: No import errors ✅
3. **Format matches**: Flutter sends `garment_image_urls`, backend expects it ✅

## ❌ The Actual Problem

**The Flutter app cannot reach the backend server.**

### Why "Not Found" Happens:

1. **Server is not running** - Most common
2. **Wrong URL in Flutter** - `localhost` doesn't work on mobile devices
3. **Network connectivity** - Device can't reach your computer

## 🚀 SOLUTION

### Step 1: Start the Server

```bash
cd backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Important**: Use `--host 0.0.0.0` (not `127.0.0.1`) so it's accessible from other devices!

### Step 2: Fix Flutter Backend URL

The Flutter app uses `http://localhost:8000` by default, which **DOESN'T WORK** on:
- Android Emulator
- Physical Android/iOS devices
- iOS Simulator (sometimes)

#### For Android Emulator:
Change the backend URL to: `http://10.0.2.2:8000`

#### For Physical Device:
1. Find your computer's IP address:
   ```bash
   # Windows
   ipconfig
   # Look for IPv4 Address (e.g., 192.168.1.100)
   
   # Mac/Linux
   ifconfig
   # Look for inet (e.g., 192.168.1.100)
   ```

2. Change Flutter backend URL to: `http://YOUR_IP:8000`
   Example: `http://192.168.1.100:8000`

#### How to Change Backend URL in Flutter:

**Option 1: Update the default in code** (temporary):
```dart
// lib/src/core/services/backend_config_service.dart
static const String _defaultBackendUrl = 'http://10.0.2.2:8000'; // For Android emulator
// OR
static const String _defaultBackendUrl = 'http://192.168.1.100:8000'; // For physical device
```

**Option 2: Set it at runtime** (better):
The app should have a settings screen where you can configure the backend URL.

### Step 3: Verify Server is Accessible

**From your computer:**
```bash
# Test if server is running
curl http://localhost:8000/health

# Should return: {"status":"healthy",...}
```

**From Flutter app:**
The app checks health at startup. If it shows "Not Found", the server isn't reachable.

### Step 4: Check Firewall

Windows Firewall might be blocking port 8000:

1. Open Windows Defender Firewall
2. Allow Python through firewall
3. Or allow port 8000 inbound connections

## 🧪 Quick Test

### Test 1: Is server running?
```bash
netstat -ano | findstr :8000
```
Should show `LISTENING` state.

### Test 2: Can you access from browser?
Open: `http://localhost:8000/docs`
Should show FastAPI documentation.

### Test 3: Test endpoint directly
```python
# Run this in Python
import requests
response = requests.post(
    "http://localhost:8000/tryon",
    json={
        "user_image_url": "https://example.com/user.jpg",
        "garment_image_urls": ["https://example.com/garment.jpg"]
    }
)
print(response.status_code)  # Should NOT be 404
```

## 📱 Platform-Specific URLs

| Platform | Backend URL |
|----------|-------------|
| **Windows/Mac (same machine)** | `http://localhost:8000` |
| **Android Emulator** | `http://10.0.2.2:8000` |
| **iOS Simulator (Mac)** | `http://localhost:8000` |
| **Physical Android Device** | `http://YOUR_COMPUTER_IP:8000` |
| **Physical iOS Device** | `http://YOUR_COMPUTER_IP:8000` |

## 🔍 Debugging Steps

1. **Check server logs** when Flutter makes request:
   - If you see the request in logs → Server is reachable, check endpoint path
   - If you DON'T see request → Network/URL issue

2. **Check Flutter logs**:
   ```dart
   print('Backend URL: ${await BackendConfigService.getBackendUrl()}');
   print('Health check: ${await BackendConfigService.checkBackendHealth()}');
   ```

3. **Test with curl/Postman**:
   ```bash
   curl -X POST http://localhost:8000/tryon \
     -H "Content-Type: application/json" \
     -d '{"user_image_url":"https://example.com/user.jpg","garment_image_urls":["https://example.com/garment.jpg"]}'
   ```

## ✅ Summary

The endpoint `/tryon` exists and works. The "Not Found" error means:

1. **Server not running** → Start it with `uvicorn`
2. **Wrong URL** → Use `10.0.2.2:8000` for Android emulator
3. **Network issue** → Check firewall, use computer's IP for physical devices

**Most likely fix**: Change Flutter backend URL from `localhost:8000` to `10.0.2.2:8000` (Android emulator) or your computer's IP address (physical device).
