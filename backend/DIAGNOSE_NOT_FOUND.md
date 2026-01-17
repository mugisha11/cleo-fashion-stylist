# 🔍 Diagnosing "Exception: Not Found" Error

## What We Know

✅ Server running: `http://localhost:8000`
✅ Endpoint exists: `/tryon` is registered
✅ CORS working: Preflight requests succeed
✅ Health endpoint works: Returns 200 OK
✅ Endpoint responds: Returns 200 (with error message about model)

## The Problem

You're seeing "Exception: Not Found" but the endpoint **does exist and respond**.

## Most Likely Causes

### 1. Health Check Failing (Most Likely)

The Flutter app checks health **before** calling the endpoint. If health check fails, it might show "Not Found".

**Check**: Open browser DevTools (F12) → Console tab → Look for:
- `Backend at http://localhost:8000 is not healthy`
- Any CORS errors
- Network errors

**Fix Applied**: Updated code to skip health check failures and still try the endpoint.

### 2. Browser CORS Issue

Even though CORS headers are present, the browser might be blocking the request.

**Check**: Browser DevTools → Network tab → Find the `/tryon` request:
- Status code?
- Any CORS errors in red?
- Request headers?
- Response?

### 3. Error Message Confusion

The backend returns: `{"status":"failed","message":"Model not found..."}`

Flutter might be displaying this as "Exception: Not Found" even though it's a different error.

## How to Debug

### Step 1: Check Browser Console

1. Open your Flutter web app: `http://localhost:61715/#/tryon`
2. Press **F12** to open DevTools
3. Go to **Console** tab
4. Try the try-on operation
5. Look for errors - copy them here

### Step 2: Check Network Tab

1. In DevTools, go to **Network** tab
2. Try the try-on operation
3. Find the request to `/tryon`
4. Click on it
5. Check:
   - **Status Code**: Should be 200 (not 404)
   - **Request URL**: Should be `http://localhost:8000/tryon`
   - **Response**: What does it say?

### Step 3: Test Directly in Browser

Open browser console on your Flutter web page and run:

```javascript
fetch('http://localhost:8000/tryon', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({
    user_image_url: 'https://example.com/user.jpg',
    garment_image_urls: ['https://example.com/garment.jpg']
  })
})
.then(r => {
  console.log('Status:', r.status);
  return r.json();
})
.then(data => console.log('Response:', data))
.catch(err => console.error('Error:', err));
```

This will show you the **exact error** from the server.

## Quick Fixes Applied

1. ✅ Updated health check to not block requests
2. ✅ Fixed backend URL for Flutter web (uses localhost)
3. ✅ Updated model list to use more reliable models
4. ✅ Improved error handling

## Next Steps

1. **Restart Flutter app** (hot reload might not pick up changes)
2. **Check browser console** for actual error messages
3. **Check server logs** when you make a request
4. **Share the exact error** from browser console

The endpoint is working - we just need to see what error Flutter is actually receiving!
