# Debugging "Exception: Not Found" Error

## Current Status

✅ **Server is running** on `http://localhost:8000`
✅ **Endpoint exists**: `/tryon` is registered
✅ **Health check works**: Returns 200 OK
✅ **Endpoint responds**: Returns 200 (but with error message)

## The Real Issue

The endpoint `/tryon` is **working and responding**, but:

1. **Health check might be failing** due to CORS or network issues
2. **Backend returns error**: `{"status":"failed","message":"Model not found..."}`
3. **Flutter interprets this as "Not Found"** even though it's a different error

## What's Actually Happening

When you test the endpoint:
```bash
POST http://localhost:8000/tryon
Status: 200 ✅
Response: {"status":"failed","message":"Model not found. Please check OpenRouter configuration."}
```

The endpoint **exists and responds**, but the **OpenRouter API call is failing** because:
- The model `google/gemini-2.5-flash-image` might not be available
- Or OpenRouter API key is invalid/expired
- Or the model name is incorrect

## Solutions

### Solution 1: Fix Health Check (Immediate)

The health check might be failing. I've updated the code to skip health check failures and still try the endpoint.

### Solution 2: Check OpenRouter Configuration

The error message says "Model not found". Check:

1. **OpenRouter API Key** is valid:
   ```python
   # In backend/app/core/config.py
   OPENROUTER_API_KEY = "sk-or-v1-..."  # Should be valid
   ```

2. **Model name** is correct:
   - Current: `google/gemini-2.5-flash-image`
   - Try: `google/gemini-2.0-flash-exp` (fallback)

3. **Test OpenRouter directly**:
   ```python
   import requests
   response = requests.post(
       "https://openrouter.ai/api/v1/chat/completions",
       headers={"Authorization": "Bearer YOUR_KEY"},
       json={"model": "google/gemini-2.0-flash-exp", "messages": [...]}
   )
   ```

### Solution 3: Check Browser Console

Since you're using Flutter web (`http://localhost:61715`), check:

1. **Browser DevTools** (F12)
2. **Network tab** - see the actual request/response
3. **Console tab** - see any JavaScript errors
4. **Look for CORS errors** - might show as "CORS policy" errors

### Solution 4: Check Server Logs

When you make a request from Flutter, check the server terminal for:
- Request received: `[trace_id] Processing try-on request...`
- OpenRouter errors: `Model {model} not found (404)`
- Any other errors

## Quick Test

Run this in your browser console (on the Flutter web app page):
```javascript
fetch('http://localhost:8000/tryon', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({
    user_image_url: 'https://example.com/user.jpg',
    garment_image_urls: ['https://example.com/garment.jpg']
  })
})
.then(r => r.json())
.then(console.log)
.catch(console.error)
```

This will show you the **actual error** from the server.

## Most Likely Cause

Based on the test results, the endpoint is working but **OpenRouter is returning 404** for the model. The error message "Model not found" is being displayed as "Exception: Not Found" in Flutter.

**Fix**: Update the model name or check OpenRouter API key.
